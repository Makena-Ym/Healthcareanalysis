-- =========================================================================
-- STEP 1: INITIAL DATABASE & SCHEMA CREATION
-- =========================================================================
CREATE DATABASE HealthcareAnalytics;
GO

USE HealthcareAnalytics;
GO

-- Establish clean separation of layers using schemas
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO

-- =========================================================================
-- STEP 2: BRONZE LAYER (Raw Ingestion)
-- =========================================================================
DROP TABLE IF EXISTS bronze.raw_patient_segmentation;
GO

CREATE TABLE bronze.raw_patient_segmentation (
    PatientID VARCHAR(50),
    Age VARCHAR(50),
    Gender VARCHAR(50),
    State VARCHAR(50),
    City VARCHAR(100),
    Height_cm VARCHAR(50),
    Weight_kg VARCHAR(50),
    BMI VARCHAR(50),
    Insurance_Type VARCHAR(100),
    Primary_Condition VARCHAR(150),
    Num_Chronic_Conditions VARCHAR(50),
    Annual_Visits VARCHAR(50),
    Avg_Billing_Amount VARCHAR(50),
    Last_Visit_Date VARCHAR(50),
    Days_Since_Last_Visit VARCHAR(50),
    Preventive_Care_Flag VARCHAR(50)
    -- Ingestion_Timestamp removed from here!
);
GO

TRUNCATE TABLE bronze.raw_patient_segmentation;
GO

BULK INSERT bronze.raw_patient_segmentation
FROM 'C:\HealthcareAnalytics\patient_segmentation_dataset.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a', 
    CODEPAGE = '65001',
    TABLOCK
);
GO
-----------------------------------------------------------
-----------------------------------------------------------
STEP 3: SILVER LAYER (Data Cleaning & Transformation)
-----------------------------------------------------------
-----------------------------------------------------------
DROP TABLE IF EXISTS silver.cleaned_patient_segmentation;
GO

CREATE TABLE silver.cleaned_patient_segmentation (
    PatientID              VARCHAR(20) PRIMARY KEY,
    Age                    INT NOT NULL,
    Gender                 VARCHAR(20) NOT NULL,
    State                  CHAR(2) NOT NULL,
    City                   VARCHAR(100) NULL, -- 'Unknown' text converted to database NULL
    Height_cm              INT NOT NULL,
    Weight_kg              INT NOT NULL,
    BMI                    DECIMAL(4,1) NOT NULL,
    Insurance_Type         VARCHAR(50) NOT NULL,
    Primary_Condition      VARCHAR(100) NOT NULL, -- Blanks mapped to 'None/Healthy'
    Num_Chronic_Conditions INT NOT NULL,
    Annual_Visits          INT NOT NULL,
    Avg_Billing_Amount     DECIMAL(10,2) NOT NULL,
    Estimated_Annual_Spend AS (Annual_Visits * Avg_Billing_Amount), -- Engineered operational feature
    Last_Visit_Date        DATE NOT NULL,
    Days_Since_Last_Visit  INT NOT NULL,
    Preventive_Care_Flag   BIT NOT NULL, -- Clean bit mapping (0 = No, 1 = Yes)
    Ingestion_Timestamp    DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- Execute the transformation and loading process
INSERT INTO silver.cleaned_patient_segmentation (
    PatientID, Age, Gender, State, City, Height_cm, Weight_kg, BMI, 
    Insurance_Type, Primary_Condition, Num_Chronic_Conditions, 
    Annual_Visits, Avg_Billing_Amount, Last_Visit_Date, 
    Days_Since_Last_Visit, Preventive_Care_Flag, Ingestion_Timestamp
)
SELECT 
    TRIM(PatientID),
    CAST(Age AS INT),
    TRIM(Gender),
    TRIM(State),
    CASE WHEN TRIM(City) = 'Unknown' THEN NULL ELSE TRIM(City) END, 
    CAST(Height_cm AS INT),
    CAST(Weight_kg AS INT),
    CAST(BMI AS DECIMAL(4,1)),
    TRIM(Insurance_Type),
    CASE 
        WHEN TRIM(Primary_Condition) IS NULL OR TRIM(Primary_Condition) = '' THEN 'None/Healthy'
        ELSE TRIM(Primary_Condition)
    END,
    CAST(Num_Chronic_Conditions AS INT),
    CAST(Annual_Visits AS INT),
    CAST(Avg_Billing_Amount AS DECIMAL(10,2)),
    CAST(Last_Visit_Date AS DATE),
    CAST(Days_Since_Last_Visit AS INT),
    CAST(Preventive_Care_Flag AS BIT),
    GETDATE()
FROM bronze.raw_patient_segmentation
WHERE PatientID IS NOT NULL;
GO


------------------------------------------------------------
TRUNCATE TABLE silver.cleaned_patient_segmentation;
GO

-- 2. Run the corrected column-matching mapping script
INSERT INTO silver.cleaned_patient_segmentation (
    PatientID, Age, Gender, State, City, Height_cm, Weight_kg, BMI, 
    Insurance_Type, Primary_Condition, Num_Chronic_Conditions, 
    Annual_Visits, Avg_Billing_Amount, Last_Visit_Date, 
    Days_Since_Last_Visit, Preventive_Care_Flag
)
SELECT 
    TRIM(PatientID),
    CAST(Age AS INT),
    TRIM(Gender),
    TRIM(State),
    CASE WHEN TRIM(City) = 'Unknown' THEN NULL ELSE TRIM(City) END, 
    CAST(Height_cm AS INT),
    CAST(Weight_kg AS INT),
    CAST(BMI AS DECIMAL(4,1)),
    TRIM(Insurance_Type),         -- Match position #9 exactly
    CASE 
        WHEN TRIM(Primary_Condition) IS NULL OR TRIM(Primary_Condition) = '' OR TRIM(Primary_Condition) = 'None' THEN 'None/Healthy'
        ELSE TRIM(Primary_Condition)
    END,                          -- Match position #10 exactly
    CAST(Num_Chronic_Conditions AS INT),
    CAST(Annual_Visits AS INT),
    CAST(Avg_Billing_Amount AS DECIMAL(10,2)),
    CAST(Last_Visit_Date AS DATE), 
    CAST(Days_Since_Last_Visit AS INT),
    CAST(Preventive_Care_Flag AS BIT)
FROM bronze.raw_patient_segmentation;
GO
--VERIFY THE DATA IN SILVER LAYER
SELECT TOP (1000) *
FROM silver.cleaned_patient_segmentation;

-----------------------------------------------------------
-----------------------------------------------------------
STEP 4: GOLD LAYER (Aggregated Insights & Reporting)
-----------------------------------------------------------
/*this view aggregates patient data into meaningful segments for analytics and reporting. It includes core demographics, clinical metrics, and utilization/financial insights. The view is designed to support downstream analytics, dashboards, and reporting needs.
*/




DROP VIEW IF EXISTS [gold vw_master_patient_analytics];
GO

CREATE OR ALTER VIEW [gold vw_master_patient_analytics] AS
SELECT 
    -- 1. Demographics & Spatial Features
    PatientID,
    Age,
    CASE 
        WHEN Age < 30 THEN 'Young Adult (Under 30)'
        WHEN Age BETWEEN 30 AND 49 THEN 'Adult (30-49)'
        WHEN Age BETWEEN 50 AND 64 THEN 'Pre-Senior (50-64)'
        ELSE 'Senior (65+)'
    END AS Age_Segment,
    Gender,
    State,
    COALESCE(City, 'Unknown / Direct') AS Cleaned_City,
    
    -- 2. Clinical Metrics & Engineered Risk Tiers
    Height_cm,
    Weight_kg,
    BMI,
    CASE 
        WHEN BMI < 18.5 THEN 'Underweight'
        WHEN BMI BETWEEN 18.5 AND 24.9 THEN 'Normal Weight'
        WHEN BMI BETWEEN 25.0 AND 29.9 THEN 'Overweight'
        ELSE 'Obese'
    END AS BMI_Category,
    Primary_Condition,
    Num_Chronic_Conditions,
    CASE 
        WHEN Num_Chronic_Conditions = 0 THEN 'Low Risk'
        WHEN Num_Chronic_Conditions BETWEEN 1 AND 2 THEN 'Moderate Risk'
        ELSE 'High Risk / Comorbid'
    END AS Clinical_Risk_Tier,
    
    -- 3. Utilization, Financials & Time Matrix Tracking
    Insurance_Type,
    Annual_Visits,
    Avg_Billing_Amount,
    Estimated_Annual_Spend,
    Last_Visit_Date,         -- Included explicitly for your calendar connection
    Days_Since_Last_Visit,    -- Main metric for engagement
    Preventive_Care_Flag
FROM silver.cleaned_patient_segmentation;
GO

/*
📅 Updated Date Table Connection for Power BI (DAX)
Since we kept Last_Visit_Date as a true date type, your Date table can now connect to a real timeline calendar instead of a number column. This is exactly what hiring managers look for.*/

---view the data in the gold layer

SELECT TOP (10) *
FROM [gold vw_master_patient_analytics];


EXEC sp_refreshview '[gold vw_master_patient_analytics]';
GO

