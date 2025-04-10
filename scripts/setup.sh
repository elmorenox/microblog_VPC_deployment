#!/bin/bash
# setup.sh - Runs on web server to deploy app to app server

# Get Application Server IP
APP_SERVER_IP=$(cat /home/ubuntu/app_server_ip.txt)

# SSH into the Application Server and run start_app.sh
ssh -i /home/ubuntu/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@$APP_SERVER_IP "bash /home/ubuntu/start_app.sh"

# Check if the application is running
echo "Checking if the application is running..."
sleep 10
curl -s http://$APP_SERVER_IP:5000

if [ $? -eq 0 ]; then
  echo "Application is running successfully!"
else
  echo "Failed to connect to the application. Please check the logs."
  exit 1
fi