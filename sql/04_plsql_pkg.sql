--------------------------------------------------------
-- PACKAGE SPECIFICATION (The Public Interface)
-- Defines what can be called from outside.
--------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_etl_retail AS
    PROCEDURE load_daily_sales;
END pkg_etl_retail;
/

--------------------------------------------------------
-- PACKAGE BODY (The Implementation)
-- Contains the actual logic and private helper functions.
--------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY pkg_etl_retail AS

    -- ===============================================================
    -- PRIVATE HELPER: ARCHIVE STEP (The "Vault" Logic)
    -- Purpose: 1. Point to today's file. 2. Copy raw data to Archive.
    -- Returns: The new Batch ID generated for this run.
    -- Note: Not declared in Spec, so it's hidden from outside users.
    -- ===============================================================
    FUNCTION archive_raw_data RETURN NUMBER IS
        v_batch_id     NUMBER;
        v_dynamic_file VARCHAR2(100);
        v_count        NUMBER;
    BEGIN
        -- 1. Generate New Batch ID
        v_batch_id := seq_batch_id.NEXTVAL;
        
        -- 2. Calculate Filename (e.g., sales_data_01012026.csv)
        v_dynamic_file := 'sales_data_' || TO_CHAR(SYSDATE, 'DDMMYYYY') || '.csv';
        
        DBMS_OUTPUT.PUT_LINE('--- STEP 1: ARCHIVING (Batch ' || v_batch_id || ') ---');
        DBMS_OUTPUT.PUT_LINE('Target File: ' || v_dynamic_file);

        -- 3. Point External Table to File
        BEGIN
            EXECUTE IMMEDIATE 'ALTER TABLE ext_sales_data LOCATION (''' || v_dynamic_file || ''')';
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error: Could not find file ' || v_dynamic_file);
                RAISE;
        END;

        -- 4. "Blind Copy" to Archive (The Backup)
        INSERT INTO raw_sales_archive (
            trans_id, cust_id, cust_name, prod_id, prod_name, 
            category, price, quantity, txn_date, 
            batch_id, archived_at, source_file
        )
        SELECT 
            trans_id, cust_id, cust_name, prod_id, prod_name, 
            category, price, quantity, txn_date,
            v_batch_id, SYSTIMESTAMP, v_dynamic_file
        FROM ext_sales_data;
        
        v_count := SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE('✅ Archived ' || v_count || ' rows safely.');
        COMMIT;
        
        RETURN v_batch_id;
    END archive_raw_data;


    -- ===============================================================
    -- PRIVATE HELPER: ETL STEP (The "Star Schema" Logic)
    -- Purpose: Read from Archive (NOT file) and load Dimensions/Facts.
    -- Input:   The Batch ID to process.
    -- ===============================================================
    PROCEDURE load_star_schema(p_batch_id NUMBER) IS
        -- We fetch from ARCHIVE now, not External Table
        CURSOR c_raw_data IS
            SELECT trans_id, cust_id, cust_name, prod_id, prod_name, category, 
                   TO_NUMBER(price) as price, 
                   TO_NUMBER(quantity) as quantity, 
                   TO_DATE(txn_date, 'YYYY-MM-DD') as txn_date
            FROM raw_sales_archive
            WHERE batch_id = p_batch_id
              AND category IS NOT NULL; -- Transformation Rule: Filter bad data
              
        v_cust_key NUMBER;
        v_prod_key NUMBER;
        v_time_id  DATE;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('--- STEP 2: TRANSFORM and LOAD ---');
        
        FOR r IN c_raw_data LOOP
            BEGIN
                -- (A) Dimension: Customer
                BEGIN
                    SELECT cust_surrogate_key INTO v_cust_key FROM dim_customer
                    WHERE cust_original_id = r.cust_id;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_cust_key := seq_cust_id.NEXTVAL;
                        INSERT INTO dim_customer (cust_surrogate_key, cust_original_id, cust_name)
                        VALUES (v_cust_key, r.cust_id, r.cust_name);
                END;

                -- (B) Dimension: Product
                BEGIN
                    SELECT prod_surrogate_key INTO v_prod_key FROM dim_product
                    WHERE prod_original_id = r.prod_id;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_prod_key := seq_prod_id.NEXTVAL;
                        INSERT INTO dim_product (prod_surrogate_key, prod_original_id, prod_name, category)
                        VALUES (v_prod_key, r.prod_id, r.prod_name, r.category);
                END;

                -- (C) Dimension: Time
                v_time_id := r.txn_date;
                MERGE INTO dim_time d USING (SELECT v_time_id AS t_date FROM dual) s
                ON (d.time_id = s.t_date)
                WHEN NOT MATCHED THEN
                    INSERT (time_id, day_name, month_name, year_num, quarter)
                    VALUES (v_time_id, TO_CHAR(v_time_id, 'DAY'), TO_CHAR(v_time_id, 'MONTH'), 
                            TO_NUMBER(TO_CHAR(v_time_id, 'YYYY')), TO_NUMBER(TO_CHAR(v_time_id, 'Q')));

                -- (D) Fact Table
                INSERT INTO fact_sales (
                    sales_id, cust_surrogate_key, prod_surrogate_key, time_id, quantity, amount, txn_date
                ) VALUES (
                    seq_sales_id.NEXTVAL, v_cust_key, v_prod_key, v_time_id, 
                    r.quantity, (r.price * r.quantity), r.txn_date
                );
            EXCEPTION
                WHEN OTHERS THEN
                    NULL; -- Logic for error logging (V3) goes here
            END;
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('✅ Star Schema Loaded for Batch ' || p_batch_id);
        COMMIT;
    END load_star_schema;


    -- ===============================================================
    -- PUBLIC MAIN: THE ORCHESTRATOR
    -- Purpose: Runs the full pipeline in order.
    -- ===============================================================
    PROCEDURE load_daily_sales IS
        v_current_batch NUMBER;
    BEGIN
        -- 1. Run Backup Logic
        v_current_batch := archive_raw_data();
        
        -- 2. Run ETL Logic (Using the data we just backed up)
        load_star_schema(v_current_batch);
        
        DBMS_OUTPUT.PUT_LINE('--- JOB COMPLETE ---');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Job Failed: ' || SQLERRM);
            ROLLBACK;
            RAISE;
    END load_daily_sales;

END pkg_etl_retail;
/