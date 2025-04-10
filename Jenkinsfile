pipeline {
  agent any
  environment {
    WEB_SERVER_IP = '54.145.48.96'
  }
  stages {
        stage ('Build') {
            steps {
                sh '''#!/bin/bash
                # Create a Python virtual environment
                python3 -m venv venv
                
                # Activate the virtual environment
                source venv/bin/activate
                
                # Install dependencies
                pip install -r requirements.txt
                pip install gunicorn pymysql cryptography python-dotenv
                
                # Validate app installation
                if [ -f "microblog.py" ]; then
                    echo "Build completed successfully"
                else
                    echo "Error: microblog.py not found"
                    exit 1
                fi
                '''
            }
        }
        stage ('Test') {
            steps {
                sh '''#!/bin/bash
                source venv/bin/activate
                pip install pytest
                py.test tests.py --verbose --junit-xml test-reports/results.xml
                '''
            }
            post {
                always {
                    junit 'test-reports/results.xml'
                }
            }
        }
      stage ('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        stage ('Deploy') {
            steps {
                sh """#!/bin/bash
                ssh -o StrictHostKeyChecking=no -i /var/lib/jenkins/.ssh/id_rsa ubuntu@${WEB_SERVER_IP} \
                '/home/ubuntu/setup.sh'
                """
            }
        }
    }
}