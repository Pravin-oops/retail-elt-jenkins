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

    # 3. Robust Splitting
    # Regex: Look for a slash '/' that is on a line by itself
    commands = re.split(r'^\s*/\s*$', full_sql, flags=re.MULTILINE)

    # 4. Execute
    for cmd in commands:
        clean_cmd = cmd.strip()
        if not clean_cmd: continue 

        # --- LOGIC FIX: Ignore comments when detecting PL/SQL ---
        lines = clean_cmd.splitlines()
        first_token = ""
        for line in lines:
            s_line = line.strip()
            # Skip empty lines or comment lines to find the real code
            if not s_line or s_line.startswith('--'):
                continue
            first_token = s_line.split()[0].upper()
            break
            
        # Check for PL/SQL keywords
        is_plsql = first_token in ['DECLARE', 'BEGIN']
        
        # Check for CREATE PACKAGE / PROCEDURE / FUNCTION / TRIGGER
        if first_token == 'CREATE':
             upper_cmd = clean_cmd.upper()
             if 'PROCEDURE' in upper_cmd or 'PACKAGE' in upper_cmd or 'FUNCTION' in upper_cmd or 'TRIGGER' in upper_cmd:
                 is_plsql = True

        # --- Handle Semicolons ---
        if is_plsql:
             # PL/SQL MUST end with semicolon
             if not clean_cmd.endswith(';'): 
                 clean_cmd += ';'
        else:
             # Standard SQL (INSERT, CREATE, etc) must NOT have semicolon
             if clean_cmd.endswith(';'): 
                 clean_cmd = clean_cmd[:-1]

        try:
            cursor.execute(clean_cmd)
        except oracledb.Error as e:
            error_str = str(e)
            # Safe Errors (Ignore "Not Exists" or "Already Exists" for cleanup scripts)
            if 'ORA-00942' in error_str or 'ORA-02289' in error_str or 'ORA-04043' in error_str or 'ORA-00955' in error_str:
                pass 
            else:
                print(f"❌ Error executing command:\n{clean_cmd[:50]}...")
                print(f"   Reason: {e}")
                has_error = True

    if has_error:
        print("🚨 Script finished with errors.")
        exit(1)
    else:
        print("✅ SQL Script Executed Successfully.")

except Exception as e:
    print(f"❌ Fatal Error: {e}")
    exit(1)

finally:
    if 'connection' in locals(): connection.close()