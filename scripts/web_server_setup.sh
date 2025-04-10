#!/bin/bash
# scripts/web_server_setup.sh
# Update system packages
sudo apt update
sudo apt upgrade -y

# Install Nginx
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Save the private key for connecting to app server
mkdir -p /home/ubuntu/.ssh
echo "${private_key_content}" > /home/ubuntu/.ssh/id_rsa
chmod 600 /home/ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu /home/ubuntu/.ssh

# Configure Nginx
cat > /tmp/nginx.conf << EOL
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://10.0.2.100:5000;
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

# Download setup.sh from GitHub
wget -O /home/ubuntu/setup.sh https://raw.githubusercontent.com/elmorenox/microblog_VPC_deployment/main/scripts/setup.sh
chmod +x /home/ubuntu/setup.sh
chown ubuntu:ubuntu /home/ubuntu/setup.sh

# Restart Nginx
sudo systemctl restart nginx

# Test Nginx configuration
sudo nginx -t

echo "Web server setup completed"