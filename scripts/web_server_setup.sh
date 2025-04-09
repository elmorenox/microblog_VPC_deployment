#!/bin/bash

# Update system packages
sudo apt update
sudo apt upgrade -y

# Install Nginx
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Install Git
sudo apt install -y git

# Install required packages
sudo apt install -y python3 python3-pip python3-venv

# Save Application Server IP to a file (will be replaced with actual IP by Terraform)
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

# Create .ssh directory
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh

# Create authorized_keys file for Jenkins user
cat > /tmp/jenkins_public_key << EOL
# This will be replaced with Jenkins public key
# For now, we put a placeholder here
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0WGP1EZykEtv5YGC9nMiykFAEklhMW+0+7bUwkUeUnMyYIZy74cMV/Df8+Zi1A8MWt5CS/6S9Y/vFJnCLem0XCpQMmY17wt2ujIsN0lFqnrqEioF8T1me0hRxSrvw7EthBzlrNh0Rwsu78RQVgc+6wWlq0SCM4TKCbrQnZQwoLbLULzk87gCDFgAzaUwQCDJyzCUFLuR8d3+l4vp9jNPJMwbL74tKnCWdmFcOkJ9mgXzbjVWcFNtKlgIQOFfYYBj8xlp/DvJ1YQldZpHU2AYe4IwlNCNIXrEJmDEhxcJEQRKIyPZCGGMEVI/jg8PDuLyZ7ZP8CO7G5KWa++SQRWqP jenkins
EOL

# Append Jenkins public key to authorized_keys
cat /tmp/jenkins_public_key >> /home/ubuntu/.ssh/authorized_keys

# Create the application server private key file
cat > /home/ubuntu/app_server_key.pem << EOL
${app_server_key}
EOL
chmod 600 /home/ubuntu/app_server_key.pem

# Create setup.sh and start_app.sh scripts
cat > /home/ubuntu/setup.sh << 'EOL'
#!/bin/bash

# Get Application Server IP
APP_SERVER_IP=$(cat /home/ubuntu/app_server_ip.txt)

# SSH into the Application Server and run start_app.sh
ssh -i /home/ubuntu/app_server_key.pem -o StrictHostKeyChecking=no ubuntu@$APP_SERVER_IP "bash -s" < /home/ubuntu/start_app.sh

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

cat > /home/ubuntu/start_app.sh << 'EOL'
#!/bin/bash

# Update system packages
sudo apt update
sudo apt upgrade -y

# Install necessary packages
sudo apt install -y git python3 python3-pip python3-venv

# Create app directory if not exists
mkdir -p /home/ubuntu/microblog

# Get GitHub repository URL from file
GITHUB_REPO=$(cat /home/ubuntu/github_repo.txt)

# Clone the repository
if [ -d "/home/ubuntu/microblog/.git" ]; then
  echo "Git repository already exists, pulling latest changes"
  cd /home/ubuntu/microblog
  git pull
else
  echo "Cloning repository from $GITHUB_REPO"
  git clone $GITHUB_REPO /home/ubuntu/microblog
  cd /home/ubuntu/microblog
fi

# Create and activate virtual environment
if [ ! -d "venv" ]; then
  python3 -m venv venv
fi
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install gunicorn pymysql cryptography python-dotenv

# Create logs directory
mkdir -p logs

# Create .env file with necessary environment variables
cat > /home/ubuntu/microblog/.env << INNEREOF
SECRET_KEY=your-secret-key-$(date +%s)
DATABASE_URL=sqlite:///app.db
LOG_TO_STDOUT=1
MAIL_SERVER=localhost
MAIL_PORT=25
MAIL_USE_TLS=
MAIL_USERNAME=
MAIL_PASSWORD=
ADMINS=your-email@example.com
LANGUAGES=en,es
MS_TRANSLATOR_KEY=
ELASTICSEARCH_URL=
REDIS_URL=redis://
INNEREOF

# Initialize database
export FLASK_APP=microblog.py
flask db upgrade || flask db init && flask db migrate -m "initial migration" && flask db upgrade

# Kill any existing gunicorn processes
pkill -f gunicorn || echo "No gunicorn processes running"

# Start the application with gunicorn in the background
gunicorn -b 0.0.0.0:5000 --access-logfile - --error-logfile - microblog:app &

# Check if the application is running
sleep 5
if pgrep -f gunicorn > /dev/null; then
  echo "Application started successfully"
else
  echo "Failed to start the application"
  exit 1
fi
EOL
chmod +x /home/ubuntu/start_app.sh

# Restart Nginx
sudo systemctl restart nginx

# Test Nginx configuration
sudo nginx -t

echo "Web server setup completed"