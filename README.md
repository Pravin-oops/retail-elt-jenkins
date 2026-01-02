# 🛒 Retail ETL Project (v2.0)

**Version:** 2.0 (Stable)
**Release Date:** January 2026
**Architecture:** Decoupled ELT (Extract-Load-Transform) with Raw Vault

## 🚀 Overview

This project is a robust data pipeline that generates synthetic retail sales data, securely archives it into a **Raw Vault** (history tracking), and transforms it into a **Star Schema** for analytics.

**Version 2.0 Major Upgrade:**
Unlike V1 (which overwrote data daily), **V2.0 preserves history**. It uses a "Time Machine" architecture where every single record ever generated is saved in the vault, while the reporting tables are reset daily for fresh analysis.

---

## 🌟 Key Features (New in v2.0)

### 1. 🛡️ Raw Vault Architecture

* **Permanent History:** New `raw_sales_archive` table acts as a data lake, storing every row forever.
* **Auditability:** Every row is tagged with a `batch_id`, `source_filename`, and `archived_at` timestamp.
* **Safe Failures:** If the ETL logic crashes, the raw data is already safely secured in the Vault.

### 2. 📅 Dynamic Date Targeting

* **Smart Handshake:**
* **Python** generates files with today's date: `sales_data_DDMMYYYY.csv`.
* **Oracle PL/SQL** dynamically calculates `SYSDATE` to find and load that specific file.


* **Conflict Prevention:** Oracle ignores old files (e.g., yesterday's data) residing in the same folder.

### 3. 🔌 Environment Portability

* **Write Once, Run Anywhere:** The Python generator now auto-detects if it is running on **Local Windows** or **Jenkins Docker**.
* *Windows:* Uses local project path.
* *Docker:* Uses `/data` volume mapping.



---

## 📂 Project Structure

```text
retail-etl-project/
├── data/                        # CSV files (gitignored)
├── script/
│   └── generate_data.py         # Generates dated files (e.g., sales_data_02012026.csv)
├── sql/
│   ├── 00_archive_table_DDL.sql # [Run Once] Creates the Permanent Vault & Sequences
│   ├── 01_setup_users.sql       # [Run Once] Creates RETAIL_DW user
│   ├── 02_directory_creation.sql# [Run Once] Maps Oracle Directory to /data
│   ├── 03_ddl_tables.sql        # [Daily] Resets Analysis Layer (Keeps Vault Safe)
│   └── 04_plsql_pkg.sql         # [Logic] The Decoupled ETL Package
├── docker-compose.yml           # Infrastructure definition
├── dockerfile                   # Jenkins image customization
└── README.md

```

---

## ⚙️ Setup Instructions

### 1. Initial Setup (Run Once)

**A. Start Infrastructure**

```bash
docker-compose up -d

```

**B. Initialize Database (as SYSTEM)**

```sql
@sql/01_setup_users.sql
@sql/02_directory_creation.sql

```

**C. Initialize Storage (as RETAIL_DW)**
Create the permanent storage (Raw Vault).

```sql
@sql/00_archive_table_DDL.sql

```

### 2. Daily Workflow (Simulation)

To simulate a daily run, follow these steps in order:

**Step A: Reset the Analysis Layer**
Wipes the dashboard tables (Fact/Dim) but **keeps the history safe**.

```sql
@sql/03_ddl_tables.sql

```

**Step B: Generate Today's Data**

```bash
# Creates sales_data_DDMMYYYY.csv in the data/ folder
python script/generate_data.py

```

**Step C: Run the Pipeline**
Executes the `load_daily_sales` procedure (Archive -> Transform -> Load).

```sql
SET SERVEROUTPUT ON;
BEGIN
    pkg_etl_retail.load_daily_sales;
END;
/

```

---

## 📊 Verification

Run these queries to verify V2 logic:

```sql
-- 1. Check the Vault (Should grow every day)
SELECT batch_id, source_file, count(*) FROM raw_sales_archive GROUP BY batch_id, source_file;

-- 2. Check the Report (Should only show today's data)
SELECT count(*) FROM fact_sales;

```

---

## 🔮 Roadmap (v3.0)

* [ ] **CI/CD Automation:** Jenkins Pipeline to automate the daily run.
* [ ] **Airflow Orchestration:** Migrating workflow to Apache Airflow DAGs.
* [ ] **Advanced Error Logging:** Capture rejected rows in an `ERROR_LOG` table instead of skipping them.

---

**Author:** Pravin