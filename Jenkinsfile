pipeline {
  agent any
  environment {
    WEB_SERVER_IP = sh(script: 'curl -s http://169.254.169.254/latest/meta-data/public-ipv4', returnStdout: true).trim()
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
                sh '''#!/bin/bash
                # Copy deployment scripts to the Web Server
                scp -o StrictHostKeyChecking=no -i /var/lib/jenkins/.ssh/id_rsa scripts/setup.sh ec2-user@${WEB_SERVER_IP}:/home/ec2-user/
                scp -o StrictHostKeyChecking=no -i /var/lib/jenkins/.ssh/id_rsa scripts/start_app.sh ec2-user@${WEB_SERVER_IP}:/home/ec2-user/
                
                # Execute setup script on Web Server
                ssh -o StrictHostKeyChecking=no -i /var/lib/jenkins/.ssh/id_rsa ec2-user@${WEB_SERVER_IP} 'chmod +x /home/ec2-user/setup.sh && /home/ec2-user/setup.sh'
                
                # Verify deployment
                echo "Verifying deployment..."
                curl -s http://${WEB_SERVER_IP}
                
                if [ $? -eq 0 ]; then
                    echo "Deployment successful!"
                else
                    echo "Deployment verification failed"
                    exit 1
                fi
                '''
            }
        }
    }
}