CREATE OR REPLACE PACKAGE pkg_etl_retail AS
    -- This is the public procedure Jenkins will call in future
    PROCEDURE load_daily_sales;
END pkg_etl_retail;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_retail AS

    PROCEDURE load_daily_sales IS
        -- 1. DEFINE IN-MEMORY STRUCTURE
        -- This record matches your External Table (CSV) structure exactly
        TYPE t_sales_row IS RECORD (
            trans_id   ext_sales_data.trans_id%TYPE,
            cust_id    ext_sales_data.cust_id%TYPE,
            cust_name  ext_sales_data.cust_name%TYPE,
            prod_id    ext_sales_data.prod_id%TYPE,
            prod_name  ext_sales_data.prod_name%TYPE,
            category   ext_sales_data.category%TYPE,
            price      NUMBER, -- Converted type
            quantity   NUMBER, -- Converted type
            txn_date   DATE    -- Converted type
        );
        
        -- Collection to hold the batch of data
        TYPE t_sales_tab IS TABLE OF t_sales_row;
        v_sales_data t_sales_tab;
        
        -- Variables for Surrogate Keys (The "ID" mapping)
        v_cust_key  NUMBER;
        v_prod_key  NUMBER;
        v_time_id   DATE;
        v_errors    NUMBER := 0;

    BEGIN
        DBMS_OUTPUT.PUT_LINE('--- ETL Job Started: ' || SYSTIMESTAMP || ' ---');

        -- 2. EXTRACT (Bulk Collect)
        -- We read from the CSV (External Table) into Memory
        BEGIN
            SELECT trans_id, cust_id, cust_name, prod_id, prod_name, category, 
                   TO_NUMBER(price), TO_NUMBER(quantity), TO_DATE(txn_date, 'YYYY-MM-DD')
            BULK COLLECT INTO v_sales_data
            FROM ext_sales_data
            WHERE category IS NOT NULL; -- DATA CLEANING: Skip rows with missing category
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Fatal Error reading External Table. Check CSV format.');
                RAISE;
        END;

        DBMS_OUTPUT.PUT_LINE('Extracted ' || v_sales_data.COUNT || ' valid rows.');

        -- 3. TRANSFORM & LOAD (Loop through memory)
        FOR i IN 1 .. v_sales_data.COUNT LOOP
            BEGIN
                -- A. CUSTOMER DIMENSION
                -- Logic: Check if customer exists. If not, create new.
                BEGIN
                    SELECT cust_surrogate_key INTO v_cust_key
                    FROM dim_customer
                    WHERE cust_original_id = v_sales_data(i).cust_id;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_cust_key := seq_cust_id.NEXTVAL;
                        INSERT INTO dim_customer (cust_surrogate_key, cust_original_id, cust_name)
                        VALUES (v_cust_key, v_sales_data(i).cust_id, v_sales_data(i).cust_name);
                END;

                -- B. PRODUCT DIMENSION
                BEGIN
                    SELECT prod_surrogate_key INTO v_prod_key
                    FROM dim_product
                    WHERE prod_original_id = v_sales_data(i).prod_id;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_prod_key := seq_prod_id.NEXTVAL;
                        INSERT INTO dim_product (prod_surrogate_key, prod_original_id, prod_name, category)
                        VALUES (v_prod_key, v_sales_data(i).prod_id, v_sales_data(i).prod_name, v_sales_data(i).category);
                END;

                -- C. TIME DIMENSION (Ensure the date exists in our calendar)
                v_time_id := v_sales_data(i).txn_date;
                MERGE INTO dim_time d
                USING (SELECT v_time_id AS t_date FROM dual) s
                ON (d.time_id = s.t_date)
                WHEN NOT MATCHED THEN
                    INSERT (time_id, day_name, month_name, year_num, quarter)
                    VALUES (v_time_id, TO_CHAR(v_time_id, 'DAY'), TO_CHAR(v_time_id, 'MONTH'), 
                            TO_NUMBER(TO_CHAR(v_time_id, 'YYYY')), TO_NUMBER(TO_CHAR(v_time_id, 'Q')));

                -- D. FACT TABLE (The Transaction)
                -- We calculate "Amount" (Price * Qty) on the fly
                INSERT INTO fact_sales (
                    sales_id, cust_surrogate_key, prod_surrogate_key, time_id, quantity, amount, txn_date
                ) VALUES (
                    seq_sales_id.NEXTVAL,
                    v_cust_key,
                    v_prod_key,
                    v_time_id,
                    v_sales_data(i).quantity,
                    (v_sales_data(i).price * v_sales_data(i).quantity),
                    v_sales_data(i).txn_date
                );

            EXCEPTION
                WHEN OTHERS THEN
                    -- Error Handling: Log the error but keep processing other rows
                    v_errors := v_errors + 1;
                    DBMS_OUTPUT.PUT_LINE('Error on Row ' || i || ': ' || SQLERRM);
            END;
        END LOOP;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('--- ETL Completed. Loaded: ' || (v_sales_data.COUNT - v_errors) || '. Errors: ' || v_errors || ' ---');

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END load_daily_sales;
END pkg_etl_retail;
/