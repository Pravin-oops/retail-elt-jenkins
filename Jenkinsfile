pipeline {
    agent any

    // --------------------------------------------------------
    // SCHEDULE REMOVED
    // This pipeline is now "On-Demand" only.
    // --------------------------------------------------------

    stages {
        stage('0. Sync Local Code') {
            steps {
                script {
                    echo "--- Syncing files from Local Laptop (/project) ---"
                    cleanWs()
                    
                    // Copy folders from mounted drive to workspace
                    sh 'cp -r /project/script .'
                    sh 'cp -r /project/sql .'
                    
                    // Verify files
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