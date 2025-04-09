#!/bin/bash
# scripts/setup.sh
# Get Application Server IP (stored in a file by Terraform)
APP_SERVER_IP=$(cat /home/ubuntu/app_server_ip.txt)

# Check if the app_server_ip file exists
if [ ! -f /home/ubuntu/app_server_ip.txt ]; then
  echo "Application server IP file not found!"
  exit 1
fi

# SSH into the Application Server and run start_app.sh
# -o StrictHostKeyChecking=no to automatically accept the host key
ssh -i /home/ubuntu/app_server_key.pem -o StrictHostKeyChecking=no ubuntu@$APP_SERVER_IP "bash -s" < /home/ubuntu/start_app.sh

# Check if the application is running
echo "Checking if the application is running..."
sleep 10
response=$(curl -s http://$APP_SERVER_IP:5000)

if [ $? -eq 0 ]; then
  echo "Application is running successfully!"
else
  echo "Failed to connect to the application. Please check the logs."
  exit 1
fi