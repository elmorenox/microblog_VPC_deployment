#!/bin/bash
# scripts/start_app.sh
# Update system packages
sudo apt update
sudo apt upgrade -y

# Install necessary packages
sudo apt install -y git python3 python3-pip python3-venv

# Create app directory if not exists
mkdir -p /home/ubuntu/microblog

# Get GitHub repository URL from file (created during instance setup)
GITHUB_REPO='https://github.com/elmorenox/microblog_VPC_deployment.git'

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
cat > /home/ubuntu/microblog/.env << EOL
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
EOL

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