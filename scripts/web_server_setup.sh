#!/bin/bash
# scripts/web_server_setup.sh
# Update system packages
sudo apt update
sudo apt upgrade -y

# Install Nginx
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Install Git and other packages
sudo apt install -y git python3 python3-pip python3-venv

# Save Application Server IP to a file
echo "${app_server_ip}" > /home/ubuntu/app_server_ip.txt

# Configure Nginx
cat > /tmp/nginx.conf << EOL
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://${app_server_ip}:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOL

# Copy the configuration to Nginx directory
sudo mkdir -p /etc/nginx/sites-available
sudo mkdir -p /etc/nginx/sites-enabled
sudo cp /tmp/nginx.conf /etc/nginx/sites-available/default
sudo ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Create setup.sh script that uses the EC2 key
cat > /home/ubuntu/setup.sh << 'EOL'
#!/bin/bash

# Get Application Server IP
APP_SERVER_IP=$(cat /home/ubuntu/app_server_ip.txt)

# SSH into the Application Server using the EC2 key
ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@$APP_SERVER_IP "bash -s" < /home/ubuntu/start_app.sh

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
EOL
chmod +x /home/ubuntu/setup.sh

# Create start_app.sh file (contents remain the same as original)
cat > /home/ubuntu/start_app.sh << 'EOL'
#!/bin/bash
# Original contents here...
EOL
chmod +x /home/ubuntu/start_app.sh

# Restart Nginx
sudo systemctl restart nginx

# Test Nginx configuration
sudo nginx -t

echo "Web server setup completed"