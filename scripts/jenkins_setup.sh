#!/bin/bash

# Update system packages
sudo apt update
sudo apt upgrade -y

# Install Java (required for Jenkins)
sudo apt install -y openjdk-11-jdk

# Add Jenkins repository
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update

# Install Jenkins
sudo apt install -y jenkins

# Start Jenkins service
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Install Git
sudo apt install -y git

# Install Python and virtualenv
sudo apt install -y python3 python3-pip
sudo pip3 install virtualenv

# Generate SSH key
mkdir -p /var/lib/jenkins/.ssh
ssh-keygen -t rsa -N "" -f /var/lib/jenkins/.ssh/id_rsa
sudo chown -R jenkins:jenkins /var/lib/jenkins/.ssh
sudo chmod 700 /var/lib/jenkins/.ssh
sudo chmod 600 /var/lib/jenkins/.ssh/id_rsa

# Print the public key for later use
echo "Jenkins SSH public key:"
cat /var/lib/jenkins/.ssh/id_rsa.pub

# Install OWASP Dependency Check
sudo mkdir -p /opt/dependency-check
cd /opt/dependency-check
sudo wget https://github.com/jeremylong/DependencyCheck/releases/download/v6.5.3/dependency-check-6.5.3-release.zip
sudo unzip dependency-check-6.5.3-release.zip
sudo rm dependency-check-6.5.3-release.zip
sudo chmod -R 755 /opt/dependency-check

# Install Recommended Jenkins plugins using jenkins-cli
wget http://localhost:8080/jnlpJars/jenkins-cli.jar
JENKINSPWD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# Wait for Jenkins to start
echo "Waiting for Jenkins to start..."
until $(curl --output /dev/null --silent --head --fail http://localhost:8080); do
    printf '.'
    sleep 5
done

# Install required plugins
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$JENKINSPWD install-plugin workflow-aggregator git junit dependency-check-jenkins-plugin

# Restart Jenkins
sudo systemctl restart jenkins

# Print Jenkins initial admin password
echo "Jenkins initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword