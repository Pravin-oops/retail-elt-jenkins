--------------------------------------------------------
-- 1. CLEANUP (Optional: Drop tables if they exist to start fresh)
--------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE fact_sales CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE dim_customer CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE dim_product CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE dim_time CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE ext_sales_data';
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_cust_id';
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_prod_id';
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_sales_id';
EXCEPTION
    WHEN OTHERS THEN NULL; -- Ignore errors if tables don't exist yet
END;
/

--------------------------------------------------------
-- 2. SEQUENCES (For generating unique Surrogate Keys)
--------------------------------------------------------
CREATE SEQUENCE seq_cust_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_prod_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_sales_id START WITH 1 INCREMENT BY 1;

--------------------------------------------------------
-- 3. EXTERNAL TABLE (The Interface to your CSV)
-- MUST match the Python CSV columns exactly
--------------------------------------------------------
CREATE TABLE ext_sales_data (
    trans_id    VARCHAR2(50),
    cust_id     VARCHAR2(50),
    cust_name   VARCHAR2(100),
    prod_id     VARCHAR2(50),
    prod_name   VARCHAR2(100),
    category    VARCHAR2(50),
    price       VARCHAR2(50),  -- Incoming CSV data is always text initially
    quantity    VARCHAR2(50),
    txn_date    VARCHAR2(50)
)
ORGANIZATION EXTERNAL (
    TYPE ORACLE_LOADER
    DEFAULT DIRECTORY source_data_dir
    ACCESS PARAMETERS (
        RECORDS DELIMITED BY NEWLINE
        SKIP 1 -- Skip the CSV Header row
        FIELDS TERMINATED BY ','
        OPTIONALLY ENCLOSED BY '"'
        MISSING FIELD VALUES ARE NULL
    )
    LOCATION ('sales_data_placeholder.csv') -- This file must exist in your 'data' folder
)
REJECT LIMIT UNLIMITED;

--------------------------------------------------------
-- 4. DIMENSION TABLES (The Context)
--------------------------------------------------------
CREATE TABLE dim_customer (
    cust_surrogate_key NUMBER PRIMARY KEY,
    cust_original_id   VARCHAR2(20),
    cust_name          VARCHAR2(100),
    start_date         DATE DEFAULT SYSDATE
);

CREATE TABLE dim_product (
    prod_surrogate_key NUMBER PRIMARY KEY,
    prod_original_id   VARCHAR2(20),
    prod_name          VARCHAR2(100),
    category           VARCHAR2(50)
);

CREATE TABLE dim_time (
    time_id    DATE PRIMARY KEY,
    day_name   VARCHAR2(20),
    month_name VARCHAR2(20),
    year_num   NUMBER,
    quarter    NUMBER
);

--------------------------------------------------------
-- 5. FACT TABLE (The Transactions)
--------------------------------------------------------
CREATE TABLE fact_sales (
    sales_id           NUMBER PRIMARY KEY,
    cust_surrogate_key NUMBER,
    prod_surrogate_key NUMBER,
    time_id            DATE,
    quantity           NUMBER,
    amount             NUMBER, -- We will calculate this (Price * Qty)
    txn_date           DATE,
    
    -- Foreign Key Constraints
    CONSTRAINT fk_fact_cust FOREIGN KEY (cust_surrogate_key) REFERENCES dim_customer(cust_surrogate_key),
    CONSTRAINT fk_fact_prod FOREIGN KEY (prod_surrogate_key) REFERENCES dim_product(prod_surrogate_key),
    CONSTRAINT fk_fact_time FOREIGN KEY (time_id) REFERENCES dim_time(time_id)
);