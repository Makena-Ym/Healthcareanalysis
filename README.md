# Healthcare Patient Segmentation & Operational Insights Pipeline

## 📌 Project Overview
As an aspiring data analyst, I built this end-to-end data pipeline and interactive business intelligence dashboard to solve core operational and clinical problems for a healthcare provider. 

This project transitions raw, unorganized patient records into structured, high-impact clinical insights. By implementing a professional data warehousing architecture and building a clean, modern dashboard, this project provides hospital leaders with the exact metrics needed to improve patient care and optimize resources.

---

## 🏥 Business Problems Solved
This project addresses five critical use cases in healthcare management:
1. **Patient Segmentation Analysis:** Identifying distinct patient groups (e.g., "High-risk seniors", "Young healthy adults") to tailor care delivery.
2. **Targeted Marketing Campaigns:** Developing proactive outreach strategies for wellness programs and annual check-ups.
3. **Resource Optimization:** Helping clinic managers allocate hospital resources and staffing based on chronic illness trends.
4. **Preventive Care Strategies:** Flagging patient cohorts skipping annual check-ups to minimize care gaps.
5. **Insurance & Revenue Analytics:** Uncovering trends in billing amounts and clinical engagement across different insurance plans.

---

## 🛠️ Tech Stack & Tools Used
* **Database Engine:** Microsoft SQL Server (SSMS)
* **Data Engineering Framework:** Medallion Architecture (Bronze $\rightarrow$ Silver $\rightarrow$ Gold)
* **Business Intelligence:** Power BI Desktop
* **Query Language:** T-SQL (Transact-SQL)
* **Modeling & Metrics:** DAX (Data Analysis Expressions)

---

## 🗄️ SQL Data Warehouse Architecture (The Medallion Framework)

To ensure high data quality, I organized the SQL database into three distinct structural layers:

### 1. Bronze Layer (Raw Ingestion)
* **Purpose:** Acts as a landing zone for raw data files exactly as they arrive.
* **Engineering Choice:** I used the **`BULK INSERT`** command to pull the source CSV directly into a staging table. I chose `BULK INSERT` because it is highly efficient, processes thousands of rows instantly, reduces server load, and avoids row-by-row insertion bottlenecks.

### 2. Silver Layer (Data Cleaning & Transformation)
* **Purpose:** Cleans, formats, and standardizes data to make it reliable.
* **Transformations Performed:**
  * Cleaned text fields using `TRIM()` to remove accidental spacing.
  * Converted blank strings and placeholder values into standard database `NULL` markers.
  * Standardized column types (converting dates to true `DATE` types, numbers to `INT`, and flags to a binary `BIT`).
  * Engineered a custom column: `Estimated_Annual_Spend` ($Annual\_Visits \times Avg\_Billing\_Amount$).

### 3. Gold Layer (Aggregated Insights & Reporting View)
* **Purpose:** Exposes clean business logic to downstream reporting tools.
* **Engineering Choice:** I created the view `[gold vw_master_patient_analytics]`. It groups patients into clinical categories on the database level (such as `Age_Segment`, `BMI_Category`, and `Clinical_Risk_Tier`). This keeps the backend tidy and optimizes performance.

> **💡 Professional Connection Method:** I connected Power BI to the Gold view using **DirectQuery**. Because I was actively updating columns and refining data types within the Gold view, DirectQuery allowed Power BI to read the database schema in real-time, completely bypassing data import delays.

---

## 📊 Power BI Visualization Architecture

The dashboard is split into distinct focus areas to help hospital managers drill down into specific problems without visual clutter.

### Page 1: Executive Summary
* **Goal:** A clean, high-level overview of the whole patient population.
* **Key Visuals:**
  * **Top KPI Row:** Total Patient Volume, Average Billing Footprint, Preventive Care Rate, and Average Days Since Last Visit.
  * **Patient Volume Chart:** A clustered column chart displaying the volume of cases across main health conditions.
  * **Financial Matrix:** A scatter plot pairing financial spend against patient engagement across different insurance types.
* **Pro Features:** Built a native **Visual Tooltip Page** acting as an active "About/Project Scope" window when hovering over the header information icon.

### Page 2: Patient Health & Risk Profiles
* **Goal:** Shifts focus away from costs to analyze clinical factors and regional distribution.
* **Key Visuals:**
  * **Age Segment Breakdown:** A donut chart showing percentages across age categories.
  * **Risk Cross-Analysis:** A stacked bar chart cross-referencing BMI levels against clinical risk tiers.
  * **Geographic Map:** A sorted chart highlighting patient concentration across states.
  * **Patient Registry:** A detailed data table with soft red conditional formatting highlights to track overdue patients.

---

## 🚀 Key Analyst Best Practices Implemented
* **No Default Visual Clutter:** Removed redundant axis titles, gridlines, and default shapes to maximize readability.
* **Explicit DAX Metrics:** Wrote dedicated DAX formulas (such as dynamic counts, conditional counts, and custom averages) instead of using raw columns.
* **Clean Side Navigation:** Built an integrated vertical Page Navigator sidebar frame on the left panel to allow frictionless switching between sheets.
* **Proper Calendar Modeling:** Generated a dynamic DAX `DateTable` calendar dimension and connected it via a proper relationship to the Gold view's tracking timeline.
