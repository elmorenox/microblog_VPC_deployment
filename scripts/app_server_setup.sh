#!/bin/bash
# scripts/app_server_setup.sh
# Update system packages
sudo apt update
sudo apt upgrade -y

# Install necessary packages
sudo apt install -y git python3 python3-pip python3-venv

# Create a directory for the application
mkdir -p /home/ubuntu/microblog

# Create .ssh directory
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh

# Save the GitHub repository URL (will be replaced by Terraform)
echo "${github_repo}" > /home/ubuntu/github_repo.txt

# Basic server preparation complete
echo "Application server is ready for application deployment"