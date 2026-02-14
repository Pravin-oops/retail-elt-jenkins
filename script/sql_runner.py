import oracledb
import os
import sys
import re

# --- CONFIGURATION ---
DB_USER = os.getenv('DB_USER', 'RETAIL_DW')
DB_PASS = os.getenv('DB_PASS', 'RetailPass123')
DB_DSN  = os.getenv('ORACLE_DSN', 'oracle-db:1521/xepdb1') 

if len(sys.argv) < 2:
    print("❌ Usage: python sql_runner.py <path_to_sql_file>")
    exit(1)

sql_file_path = sys.argv[1]
print(f"--- Running SQL Script: {sql_file_path} ---")

has_error = False

try:
    # 1. Connect
    connection = oracledb.connect(user=DB_USER, password=DB_PASS, dsn=DB_DSN)
    cursor = connection.cursor()

    # 2. Read File
    with open(sql_file_path, 'r') as f:
        full_sql = f.read()

    # 3. Robust Splitting (Fix for DPY-2041)
    # Regex: Look for a slash '/' that is on a line by itself
    # This prevents splitting paths like '/data'
    commands = re.split(r'^\s*/\s*$', full_sql, flags=re.MULTILINE)

    # 4. Execute
    for cmd in commands:
        clean_cmd = cmd.strip()
        if not clean_cmd: continue # Skip empty blocks

        # PL/SQL Detection (Add semicolon if missing)
        first_word = clean_cmd.split()[0].upper() if clean_cmd.split() else ""
        is_plsql = first_word in ['BEGIN', 'DECLARE', 'CREATE'] and ('PROCEDURE' in clean_cmd.upper() or 'PACKAGE' in clean_cmd.upper() or 'FUNCTION' in clean_cmd.upper())
        
        # Standardize Semicolons
        if clean_cmd.upper().startswith('BEGIN') or clean_cmd.upper().startswith('DECLARE'):
             if not clean_cmd.endswith(';'): clean_cmd += ';'
        elif clean_cmd.endswith(';'):
             # Standard SQL (CREATE USER, TABLE, etc) should NOT have semicolon for oracledb
             # BUT PL/SQL blocks inside CREATE PACKAGE need them. 
             # Simplest Rule: Strip semicolon for single-line SQL
             if not is_plsql: 
                 clean_cmd = clean_cmd[:-1]

        try:
            cursor.execute(clean_cmd)
        except oracledb.Error as e:
            error_str = str(e)
            # Safe Errors (Ignore "Not Exists" for cleanup scripts)
            if 'ORA-00942' in error_str or 'ORA-02289' in error_str or 'ORA-04043' in error_str:
                pass 
            else:
                print(f"❌ Error executing command:\n{clean_cmd[:50]}...")
                print(f"   Reason: {e}")
                has_error = True

    if has_error:
        print("🚨 Script finished with errors.")
        exit(1) # Fail the pipeline
    else:
        print("✅ SQL Script Executed Successfully.")

except Exception as e:
    print(f"❌ Fatal Error: {e}")
    exit(1)

finally:
    if 'connection' in locals(): connection.close()