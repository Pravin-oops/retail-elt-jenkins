pipeline {
    agent any

    // SCHEDULE: 03:30 AM UTC = 09:00 AM IST
    triggers {
        cron('30 3 * * *') 
    }

    stages {
        stage('0. Sync Local Code') {
            steps {
                script {
                    echo "--- Syncing files from Local Laptop (/project) ---"
                    cleanWs()
                    
                    // FIX: Use 'cp' instead of 'rsync'
                    // We explicitly copy the folders we need to avoid errors
                    sh 'cp -r /project/script .'
                    sh 'cp -r /project/sql .'
                    
                    // Verify files arrived
                    sh 'ls -R' 
                }
            }
        }

        stage('1. Generate Data') {
            steps {
                script {
                    echo "--- Generating Data ---"
                    // Use Absolute Path to Python
                    sh '/opt/venv/bin/python3 script/generate_data.py'
                }
            }
        }

        stage('2. Run ETL') {
            steps {
                script {
                    echo "--- Triggering Oracle PL/SQL ---"
                    // Use Absolute Path to Python
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
            echo '❌ Pipeline Failed. Check logs.'
        }
    }
}