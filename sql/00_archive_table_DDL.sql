--------------------------------------------------------
-- PERMANENT ARCHIVE SETUP (Run Once)
-- Purpose: Creates the "Forever Storage" for raw data.
-- WARNING: Do not drop these objects in daily scripts!
--------------------------------------------------------

-- 1. Batch ID Sequence (Tracks loads over time)
-- We check if it exists to avoid errors, or just run this script once.
DECLARE
    v_count NUMBER;
BEGIN
    SELECT count(*) INTO v_count FROM user_sequences WHERE sequence_name = 'SEQ_BATCH_ID';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_batch_id START WITH 1000 INCREMENT BY 1';
    END IF;
END;
/

-- 2. The Archive Table (The Raw Vault)
-- Holds every row ever received. never deleted.
DECLARE
    v_count NUMBER;
BEGIN
    SELECT count(*) INTO v_count FROM user_tables WHERE table_name = 'RAW_SALES_ARCHIVE';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE raw_sales_archive (
                trans_id    VARCHAR2(50),
                cust_id     VARCHAR2(50),
                cust_name   VARCHAR2(100),
                prod_id     VARCHAR2(50),
                prod_name   VARCHAR2(100),
                category    VARCHAR2(50),
                price       VARCHAR2(50),
                quantity    VARCHAR2(50),
                txn_date    VARCHAR2(50),
                -- Audit Columns
                batch_id    NUMBER,
                archived_at TIMESTAMP DEFAULT SYSTIMESTAMP,
                source_file VARCHAR2(100)
            )';
        EXECUTE IMMEDIATE 'CREATE INDEX idx_archive_batch ON raw_sales_archive(batch_id)';
    END IF;
END;
/

