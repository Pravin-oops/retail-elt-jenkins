# 🛒 Retail ETL Project (v1.0)

A containerized ETL (Extract, Transform, Load) solution designed to simulate a retail data pipeline. This project serves as a foundational exercise to demonstrate and refine Data Engineering skills using Oracle 19c and Docker, independent of enterprise infrastructure.

## 🎯 Project Objective
The primary goal of this initiative is to architect a "ground-up" data solution that handles messy, real-world data scenarios. It focuses on the mechanics of building a robust Star Schema and writing performant PL/SQL logic to enforce data quality standards.

## 🚀 Key Features
* **Automated Data Generation:** A Python-based engine (`Faker`) that creates realistic "dirty" sales datasets (including missing categories and invalid dates) to test pipeline resilience.
* **External Tables:** Implementation of Oracle `ORGANIZATION EXTERNAL` to interface directly with raw CSV files from the operating system, bridging the gap between file storage and database storage.
* **Star Schema Architecture:** Transformation of flat, raw transactional data into a structured dimensional model (`FACT_SALES`, `DIM_CUSTOMER`, `DIM_PRODUCT`, `DIM_TIME`) optimized for analytics.
* **Data Quality Logic:** A dedicated PL/SQL package (`pkg_etl_retail`) that acts as a gatekeeper, filtering invalid records and achieving a ~94% yield on high-volume inputs.

## 🛠 Tech Stack
* **Database:** Oracle Database 19c (Containerized via Docker)
* **Scripting:** PL/SQL, Python 3.9
* **Infrastructure:** Docker Compose
* **Tools:** VS Code, SQL Developer, Git

## 🔮 Future Roadmap (v2.0 & Beyond)
This project is an evolving proof-of-concept. Planned improvements include:
* **Data Archival Strategy:** Moving away from the current "truncate and load" pattern to a robust archiving system that backs up previous daily loads before processing new data.
* **CI/CD Automation:** Integrating a Jenkins pipeline to automate the end-to-end workflow—triggering the Python generation script and PL/SQL package execution upon code commits.
* **Advanced Error Logging:** Implementing a dedicated logging table to capture and audit specific row-level failures for better debugging.

## ⚡ Quick Start

### 1. Prerequisite
Ensure Docker and Git are installed.

### 2. Environment Setup
Clone the repository and spin up the infrastructure:
```bash
git clone [https://github.com/Pravin-oops/retail-etl-project.git](https://github.com/Pravin-oops/retail-etl-project.git)
cd retail-etl-project
docker-compose up -d
```

### 3. Database Initialization

Connect to the database (User: `SYSTEM`) and execute the user setup script:

```sql
@sql/01_setup_users.sql

```

### 4. Run the Pipeline

Connect as `RETAIL_DW` and execute the following steps:

1. **Build Schema:** Run the DDL script.
```sql
@sql/02_ddl_tables.sql

```


2. **Generate Data:** Run the Python generator.
```bash
python scripts/generate_data.py

```


3. **Run ETL:** Execute the PL/SQL package.
```sql
SET SERVEROUTPUT ON;
BEGIN
    pkg_etl_retail.load_daily_sales;
END;
/

```



## 📊 Results

* **Input:** Raw CSV containing simulated transactional noise (approx 1000+ rows).
* **Process:** Validation of business rules and calculation of derived metrics (Revenue).
* **Output:** Clean, referentially intact data loaded into `FACT_SALES`.
* **Efficiency:** Initial benchmarks show a **94% data yield**, successfully filtering invalid category data while preserving valid transactions.

```

```