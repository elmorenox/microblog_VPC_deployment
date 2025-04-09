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

# Save the private key for connecting to app server
mkdir -p /home/ubuntu/.ssh
echo "${private_key_content}" > /home/ubuntu/.ssh/id_rsa
chmod 600 /home/ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa

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

# Copy setup.sh and start_app.sh templates
cp /tmp/setup.sh /home/ubuntu/setup.sh
cp /tmp/start_app.sh /home/ubuntu/start_app.sh

# Make scripts executable
chmod +x /home/ubuntu/setup.sh
chmod +x /home/ubuntu/start_app.sh

# Restart Nginx
sudo systemctl restart nginx

# Test Nginx configuration
sudo nginx -t

echo "Web server setup completed"