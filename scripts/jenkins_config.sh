#!/bin/bash

# This script configures Jenkins with the necessary plugins and the Multibranch Pipeline job
# It should be run on the Jenkins server after it's fully initialized

# Set the admin password
ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# Download Jenkins CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# Install necessary plugins
echo "Installing necessary plugins..."
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$ADMIN_PASSWORD install-plugin workflow-aggregator git junit dependency-check-jenkins-plugin pipeline-stage-view blueocean docker-workflow pipeline-github-lib pipeline-rest-api ssh-agent -deploy

# Restart Jenkins
echo "Restarting Jenkins..."
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$ADMIN_PASSWORD safe-restart

# Wait for Jenkins to restart
echo "Waiting for Jenkins to restart..."
sleep 60

# Create Multibranch Pipeline job
echo "Creating Multibranch Pipeline job..."
cat > job_config.xml << EOL
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
  <sources class="jenkins.branch.MultiBranchProject\$BranchSourceList" plugin="branch-api@2.7.0">
    <data>
      <jenkins.branch.BranchSource>
        <source class="jenkins.plugins.git.GitSCMSource" plugin="git@4.11.0">
          <id>1234567890</id>
          <remote>https://github.com/YOUR_USERNAME/microblog_VPC_deployment.git</remote>
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

# Create Jenkins job
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$ADMIN_PASSWORD create-job workload_4 < job_config.xml

# Set up Dependency Check plugin
echo "Setting up Dependency Check plugin..."
cat > dependency_check_config.xml << EOL
<?xml version='1.1' encoding='UTF-8'?>
<org.jenkinsci.plugins.DependencyCheck.DependencyCheckDescriptor plugin="dependency-check-jenkins-plugin@5.1.1">
  <globalSuppressionFile></globalSuppressionFile>
  <suppressionFilePath></suppressionFilePath>
  <hintsFilePath></hintsFilePath>
  <zipExtensions></zipExtensions>
  <scanAll>false</scanAll>
  <scanOnlyInChanges>false</scanOnlyInChanges>
  <jarPath></jarPath>
  <isAutoupdateDisabled>false</isAutoupdateDisabled>
  <vulnDbDir></vulnDbDir>
  <dataMirrorPlus>false</dataMirrorPlus>
  <dataMirrorPlusUrl></dataMirrorPlusUrl>
  <dataMirrorPlusCredentialsId></dataMirrorPlusCredentialsId>
  <dataMirror>false</dataMirror>
  <dataMirrorUrl></dataMirrorUrl>
  <dataMirrorCredentialsId></dataMirrorCredentialsId>
  <installations>
    <org.jenkinsci.plugins.DependencyCheck.DependencyCheckInstallation>
      <name>DP-Check</name>
      <home>/opt/dependency-check</home>
      <properties />
    </org.jenkinsci.plugins.DependencyCheck.DependencyCheckInstallation>
  </installations>
</org.jenkinsci.plugins.DependencyCheck.DependencyCheckDescriptor>
EOL

# Configure Dependency Check plugin
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$ADMIN_PASSWORD groovy = < dependency_check_config.xml

echo "Jenkins configuration complete!"