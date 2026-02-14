pipeline {
    agent any

    // Manual Trigger Only (No Schedule)

    stages {
        stage('0. Sync Local Code') {
            steps {
                script {
                    echo "--- Syncing files from Local Laptop ---"
                    cleanWs()
                    sh 'cp -r /project/script .'
                    sh 'cp -r /project/sql .'
                }
            }
        }

        stage('1. Reset Schema') {
            steps {
                script {
                    echo "--- 🧹 Wiping Analysis Layer (Avoiding Duplicates) ---"
                    // RUNS THE NEW SCRIPT to execute 05_ddl_tables.sql
                    sh '/opt/venv/bin/python3 script/sql_runner.py sql/05_ddl_tables.sql'
                }
            }
        }

        stage('2. Generate Data') {
            steps {
                script {
                    echo "--- 🎲 Generating New Data ---"
                    sh '/opt/venv/bin/python3 script/generate_data.py'
                }
            }
        }

        stage('3. Run ETL') {
            steps {
                script {
                    echo "--- 🚀 Loading Data to Oracle ---"
                    sh '/opt/venv/bin/python3 script/trigger_etl.py'
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline Succeeded!'
        }
        failure {
            echo '❌ Pipeline Failed.'
        }
    }
}