#!/bin/bash
# scripts/jenkins_config.sh
# This script configures Jenkins with the necessary plugins and the Multibranch Pipeline job
# It should be run on the Jenkins server after it's fully initialized

# Store original directory
ORIGINAL_DIR=$(pwd)

# Install required packages for Python testing
echo "Installing Python dependencies..."
sudo apt update
sudo apt install -y python3-venv python3-pip unzip
sudo pip3 install pytest

# Install OWASP Dependency Check
echo "Installing OWASP Dependency Check..."
sudo rm -r /opt
sudo mkdir /opt
cd /opt/
sudo wget https://github.com/jeremylong/DependencyCheck/releases/download/v6.5.3/dependency-check-6.5.3-release.zip
sudo unzip dependency-check-6.5.3-release.zip
sudo chmod -R 755 /opt/dependency-check
sudo chown -R jenkins:jenkins /opt/dependency-check

# Configure Dependency Check Tool in Jenkins
echo "Configuring Dependency Check Tool in Jenkins..."
sudo tee /var/lib/jenkins/org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstallation.xml > /dev/null << 'EOL'
<?xml version='1.1' encoding='UTF-8'?>
<org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstallation_-DescriptorImpl plugin="dependency-check-jenkins-plugin@5.6.0">
  <installations class="org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstallation-array">
    <org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstallation>
      <name>DP-Check</name>
      <home>/opt/dependency-check</home>
      <properties/>
    </org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstallation>
  </installations>
</org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstallation_-DescriptorImpl>
EOL

# Set proper permissions for the configuration file
sudo chown jenkins:jenkins /var/lib/jenkins/org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstallation.xml


# Return to original directory
cd $ORIGINAL_DIR

# Set the admin password
ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
echo "Jenkins initial admin password: $ADMIN_PASSWORD"

# Download Jenkins CLI
wget -q -O jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar
sudo chmod +x jenkins-cli.jar

# Wait for Jenkins to be fully up
echo "Waiting for Jenkins to be fully up..."
sleep 10  # Additional wait to ensure Jenkins is ready

# Install necessary plugins
echo "Installing necessary plugins..."
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$ADMIN_PASSWORD install-plugin workflow-aggregator git junit dependency-check-jenkins-plugin pipeline-stage-view blueocean docker-workflow pipeline-github-lib pipeline-rest-api ssh-agent -deploy

# Restart Jenkins
echo "Restarting Jenkins..."
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$ADMIN_PASSWORD safe-restart

# Wait for Jenkins to restart
echo "Waiting for Jenkins to restart..."
sleep 20  # Additional wait to ensure Jenkins is ready

# Get GitHub repository URL
read -p "Enter your GitHub repository URL (e.g., https://github.com/YOUR_USERNAME/microblog_VPC_deployment.git): " GITHUB_REPO
if [ -z "$GITHUB_REPO" ]; then
    GITHUB_REPO="https://github.com/YOUR_USERNAME/microblog_VPC_deployment.git"
fi

# Create Multibranch Pipeline job
echo "Creating Multibranch Pipeline job..."
sed "s|https://github.com/YOUR_USERNAME/microblog_VPC_deployment.git|$GITHUB_REPO|g" > job_config.xml << 'EOL'
<?xml version='1.1' encoding='UTF-8'?>
<org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject plugin="workflow-multibranch@2.26">
  <actions/>
  <description></description>
  <properties>
    <org.jenkinsci.plugins.pipeline.modeldefinition.config.FolderConfig plugin="pipeline-model-definition@1.9.3">
      <dockerLabel></dockerLabel>
      <registry plugin="docker-commons@1.19"/>
    </org.jenkinsci.plugins.pipeline.modeldefinition.config.FolderConfig>
  </properties>
  <folderViews class="jenkins.branch.MultiBranchProjectViewHolder" plugin="branch-api@2.7.0">
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
  </folderViews>
  <healthMetrics>
    <com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric plugin="cloudbees-folder@6.16">
      <nonRecursive>false</nonRecursive>
    </com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric>
  </healthMetrics>
  <icon class="jenkins.branch.MetadataActionFolderIcon" plugin="branch-api@2.7.0">
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
  </icon>
  <orphanedItemStrategy class="com.cloudbees.hudson.plugins.folder.computed.DefaultOrphanedItemStrategy" plugin="cloudbees-folder@6.16">
    <pruneDeadBranches>true</pruneDeadBranches>
    <daysToKeep>-1</daysToKeep>
    <numToKeep>-1</numToKeep>
  </orphanedItemStrategy>
  <triggers>
    <com.cloudbees.hudson.plugins.folder.computed.PeriodicFolderTrigger plugin="cloudbees-folder@6.16">
      <spec>H/5 * * * *</spec>
      <interval>300000</interval>
    </com.cloudbees.hudson.plugins.folder.computed.PeriodicFolderTrigger>
  </triggers>
  <disabled>false</disabled>
  <sources class="jenkins.branch.MultiBranchProject$BranchSourceList" plugin="branch-api@2.7.0">
    <data>
      <jenkins.branch.BranchSource>
        <source class="jenkins.plugins.git.GitSCMSource" plugin="git@4.11.0">
          <id>1234567890</id>
          <remote>https://github.com/elmorenox/microblog_VPC_deployment.git</remote>
          <credentialsId></credentialsId>
          <traits>
            <jenkins.plugins.git.traits.BranchDiscoveryTrait/>
          </traits>
        </source>
        <strategy class="jenkins.branch.DefaultBranchPropertyStrategy">
          <properties class="empty-list"/>
        </strategy>
      </jenkins.branch.BranchSource>
    </data>
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
  </sources>
  <factory class="org.jenkinsci.plugins.workflow.multibranch.WorkflowBranchProjectFactory">
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
    <scriptPath>Jenkinsfile</scriptPath>
  </factory>
</org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject>
EOL

echo "Creating job 'workload_4'..."
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$ADMIN_PASSWORD create-job workload_4 < job_config.xml


echo "Jenkins configuration complete!"
echo "Your Multibranch Pipeline 'workload_4' has been created with the following repository: $GITHUB_REPO"
echo "Initial admin password: $ADMIN_PASSWORD"
echo ""
echo "Make sure your Jenkinsfile has the correct configurations for Python virtual environment and testing!"