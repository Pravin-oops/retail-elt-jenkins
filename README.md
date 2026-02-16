# 🛒 Retail ELT Pipeline (Jenkins Edition)

**Version:** 4.0 (Self-Bootstrapping Infrastructure)
**Architecture:** Jenkins CI/CD + Oracle XE + Docker
**Methodology:** ELT (Extract, Load, Transform) with Zero Data Loss

## 🚀 Overview

This project implements a production-grade **Retail Data Warehouse** pipeline orchestrated by **Jenkins**. It features a **"Zero-Touch" Initialization** workflow, where the entire database infrastructure is provisioned automatically via code.

The system uses **Docker** to spin up Jenkins and Oracle XE, and employs a custom Python wrapper (`sql_runner.py`) to manage complex database deployments, switching dynamically between Admin (`SYSTEM`) and Application (`RETAIL_DW`) users.

---

## 📋 Prerequisites

* **Docker Desktop** (Running and configured)
* **Git** (To clone the repository)
* **Java Options:** The `docker-compose.yml` is configured to allow local Git checkouts.

---

## 🛠️ Installation & Setup

### 1. Project Structure

Ensure your repository matches this structure. This is critical for the Jenkins pipelines to find the scripts.

```text
retail-elt-jenkins/
├── script/
│   ├── generate_data.py         # Data Generator (Python)
│   ├── trigger_etl.py           # ETL Trigger (Python)
│   └── sql_runner.py            # Universal SQL Executor (Renamed from data_truncate.py)
├── sql/
│   ├── 01_setup_users.sql       # [Admin] Create User
│   ├── 02_directory_creation.sql# [App] Create Directory
│   ├── 03_grant_to_dir_sys.sql  # [Admin] Grant Permissions
│   ├── 04_archive_table_DDL.sql # [App] Create Archive/Error Tables
│   ├── 05_ddl_tables.sql        # [App] Reset Fact/Dim Tables
│   └── 06_plsql_pkg.sql         # [App] ETL Logic Package
├── Jenkinsfile                  # [Daily] Main ETL Pipeline
├── project_start_jenkinsfile    # [Run Once] Infrastructure Setup Pipeline
├── docker-compose.yml           # Infrastructure Config
└── Dockerfile                   # Custom Jenkins Agent

```

### 2. Build and Launch

Run the following command to build the custom Jenkins image (with Python & Oracle drivers) and start the database.

```bash
docker-compose up -d --build

```

*Wait about 2-3 minutes for Jenkins to start and the Oracle Database to initialize.*

### 3. Unlock Jenkins

1. Access Jenkins at [http://localhost:8080](https://www.google.com/search?q=http://localhost:8080).
2. Retrieve the initial admin password:
```bash
docker exec retail_jenkins cat /var/jenkins_home/secrets/initialAdminPassword

```


3. Install "Suggested Plugins" and create your Admin user.

---

## 🤖 Pipeline Configuration

This project requires **two separate Jenkins Jobs** to manage the lifecycle.

### Job 1: Infrastructure Initialization (Run Once)

**Job Name:** `Retail-Project-Initialize`
**Type:** Pipeline

This job bootstraps the database from scratch. It creates the user, maps the Docker volume to an Oracle Directory, and deploys the schema.

* **Definition:** Pipeline script from SCM
* **SCM:** Git
* **Repository URL:** `file:///project`
* **Script Path:** `project_start_jenkinsfile`
* **Action:** Click **Build Now**.
* *Result:* All stages (User, Directory, Grants, Schema) should pass successfully.



### Job 2: Daily ETL Run (Recurring)

**Job Name:** `Retail-ETL-Daily`
**Type:** Pipeline

This is the standard recurring data pipeline.

* **Definition:** Pipeline script from SCM
* **SCM:** Git
* **Repository URL:** `file:///project`
* **Script Path:** `Jenkinsfile`
* **Action:** Click **Build Now**.
* **Reset:** Truncates analysis tables (Fact/Dim) via `sql_runner.py`.
* **Generate:** Python script creates `sales_data.csv` with 1000 rows (5% invalid).
* **Load:** Triggers `pkg_etl_retail.load_daily_sales` to Archive, Validate, and Load data.



---

## 📊 Verification

Connect to the Oracle Database to verify the data load.

**Connection Details:**

* **Host:** `localhost`
* **Port:** `1521`
* **Service Name:** `xepdb1`
* **User:** `RETAIL_DW`
* **Password:** `RetailPass123`

**Validation Queries:**

```sql
-- 1. Check Valid Sales (The Star Schema)
SELECT * FROM FACT_SALES;

-- 2. Check Rejected Data (The Audit Trail)
-- You should see rows with "Data Quality: Missing Category"
SELECT * FROM ERR_SALES_REJECTS;

-- 3. Check Raw History (The Zero Data Loss Vault)
-- Contains 100% of the generated data
SELECT * FROM RAW_SALES_ARCHIVE;

```

---

## 🔧 Key Technical Features

### 1. Universal SQL Runner (`script/sql_runner.py`)

A custom Python utility that replaces manual SQL*Plus interaction. It:

* Parses complex SQL files and PL/SQL blocks.
* Handles delimiters (`/`) automatically.
* **Environment Aware:** Uses `DB_USER` env var to switch between `SYSTEM` and `RETAIL_DW` credentials dynamically during the pipeline execution.

### 2. Zero Data Loss Architecture

Every single row generated is first copied to `RAW_SALES_ARCHIVE` before any transformation occurs. This allows for full replayability and auditing.

### 3. In-Database Transformation

We use **PL/SQL Stored Procedures** (`pkg_etl_retail`) to handle business logic. This is highly efficient as data never leaves the database engine during transformation.

---

**Author:** Pravin