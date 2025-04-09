#!/bin/bash

# This script sets up the directory structure and files for the deployment
# Run this script first to prepare everything

# Create the scripts directory if it doesn't exist
mkdir -p scripts

# Copy all script files to the scripts directory
echo "Copying scripts to scripts directory..."
cp scripts/* scripts/ 2>/dev/null || echo "Scripts directory already contains files"

# Make all scripts executable
chmod +x scripts/*.sh

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Terraform is not installed. Please install Terraform and try again."
    exit 1
fi

# Create terraform.tfvars from example if it doesn't exist
if [ ! -f terraform.tfvars ]; then
    if [ -f terraform.tfvars.example ]; then
        cp terraform.tfvars.example terraform.tfvars
        echo "Created terraform.tfvars from example file. Please edit it with your credentials."
    else
        echo "terraform.tfvars.example not found. Please create terraform.tfvars manually."
    fi
fi

# Ask for AWS credentials
read -p "Enter your AWS Access Key (leave blank to skip): " AWS_ACCESS_KEY
read -p "Enter your AWS Secret Key (leave blank to skip): " AWS_SECRET_KEY

# Update AWS credentials in terraform.tfvars if provided
if [ -n "$AWS_ACCESS_KEY" ] && [ -n "$AWS_SECRET_KEY" ]; then
    sed -i "s|aws_access_key.*|aws_access_key      = \"$AWS_ACCESS_KEY\"|" terraform.tfvars
    sed -i "s|aws_secret_key.*|aws_secret_key      = \"$AWS_SECRET_KEY\"|" terraform.tfvars
    echo "AWS credentials updated in terraform.tfvars"
fi

# Update GitHub repository URL in terraform.tfvars
read -p "Enter your GitHub repository URL (e.g., https://github.com/YOUR_USERNAME/microblog_VPC_deployment.git): " GITHUB_REPO
if [ -n "$GITHUB_REPO" ]; then
    sed -i "s|github_repo.*|github_repo         = \"$GITHUB_REPO\"|" terraform.tfvars
fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Validate Terraform configuration
echo "Validating Terraform configuration..."
terraform validate

# Generate a plan
echo "Generating Terraform plan..."
terraform plan -out=tfplan

echo "Deployment setup complete!"
echo "To deploy the infrastructure, run: terraform apply tfplan"
echo "Once deployed, connect to the Jenkins server and run: scripts/jenkins_config.sh"