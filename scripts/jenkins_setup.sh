#!/bin/bash
# scripts/jenkins_setup.sh
sudo apt update
sudo apt upgrade -y
sudo apt install -y openjdk-17-jdk

# Add the Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update and install Jenkins
sudo apt update
sudo apt install -y jenkins

# Start Jenkins service
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Install Git and Python tools
sudo apt install -y git python3 python3-pip python3-venv pytest
sudo pip3 install virtualenv

# Generate SSH key for Jenkins
sudo mkdir -p /var/lib/jenkins/.ssh
sudo ssh-keygen -t rsa -N "" -f /var/lib/jenkins/.ssh/id_rsa
sudo chown -R jenkins:jenkins /var/lib/jenkins/.ssh
sudo chmod 700 /var/lib/jenkins/.ssh
sudo chmod 600 /var/lib/jenkins/.ssh/id_rsa

# Print the public key for reference
echo "Jenkins SSH public key:"
sudo cat /var/lib/jenkins/.ssh/id_rsa.pub

# Install OWASP Dependency Check properly
sudo mkdir -p /opt/dependency-check
cd /opt/dependency-check
sudo wget https://github.com/jeremylong/DependencyCheck/releases/download/v6.5.3/dependency-check-6.5.3-release.zip
sudo apt install -y unzip
sudo unzip dependency-check-6.5.3-release.zip
sudo rm dependency-check-6.5.3-release.zip
sudo chmod -R 755 /opt/dependency-check
sudo chown -R jenkins:jenkins /opt/dependency-check

# Add dependency-check to PATH
echo 'export PATH=$PATH:/opt/dependency-check/bin' | sudo tee -a /etc/profile.d/dependency-check.sh
sudo chmod +x /etc/profile.d/dependency-check.sh

# Print Jenkins initial admin password
echo "Jenkins initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword