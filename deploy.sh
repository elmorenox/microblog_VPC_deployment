#!/bin/bash

# This script sets up the directory structure and files for the deployment
# Run this script first to prepare everything

# Ensure we're in the root directory (containing main.tf, variables.tf, etc.)
ROOT_DIR=$(pwd)
echo "Running from directory: $ROOT_DIR"

# Check if Terraform files exist
if [ ! -f "$ROOT_DIR/main.tf" ] || [ ! -f "$ROOT_DIR/variables.tf" ]; then
    echo "ERROR: main.tf or variables.tf not found in $ROOT_DIR."
    echo "Please make sure you're running this script from the root directory containing your Terraform files."
    exit 1
fi

# Ask for AWS credentials
read -p "Enter your AWS Access Key (leave blank to skip): " AWS_ACCESS_KEY
read -p "Enter your AWS Secret Key (leave blank to skip): " AWS_SECRET_KEY

# Update AWS credentials in terraform.tfvars if provided
if [ -n "$AWS_ACCESS_KEY" ] && [ -n "$AWS_SECRET_KEY" ]; then
    sed -i "s|aws_access_key.*|aws_access_key      = \"$AWS_ACCESS_KEY\"|" "$ROOT_DIR/terraform.tfvars"
    sed -i "s|aws_secret_key.*|aws_secret_key      = \"$AWS_SECRET_KEY\"|" "$ROOT_DIR/terraform.tfvars"
    echo "AWS credentials updated in terraform.tfvars"
fi

# Update GitHub repository URL in terraform.tfvars
read -p "Enter your GitHub repository URL (e.g., https://github.com/YOUR_USERNAME/microblog_VPC_deployment.git): " GITHUB_REPO
if [ -n "$GITHUB_REPO" ]; then
    sed -i "s|github_repo.*|github_repo         = \"$GITHUB_REPO\"|" "$ROOT_DIR/terraform.tfvars"
fi

# List Terraform files for debugging
echo "Checking Terraform files in current directory:"
ls -la $ROOT_DIR/*.tf


# Check if provider block needs to be updated in main.tf
if ! grep -q "access_key" "$ROOT_DIR/main.tf"; then
    echo "Updating AWS provider in main.tf..."
    # Create a temporary file
    TEMP_FILE=$(mktemp)
    
    # Replace the provider block
    sed 's/provider "aws" {/provider "aws" {\n  access_key = var.aws_access_key\n  secret_key = var.aws_secret_key/g' "$ROOT_DIR/main.tf" > "$TEMP_FILE"
    
    # Move the temporary file back to main.tf
    mv "$TEMP_FILE" "$ROOT_DIR/main.tf"
fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform -chdir="$ROOT_DIR" init

# Validate Terraform configuration
echo "Validating Terraform configuration..."
terraform -chdir="$ROOT_DIR" validate

if [ $? -eq 0 ]; then
    # Generate a plan
    echo "Generating Terraform plan..."
    terraform -chdir="$ROOT_DIR" plan -out=tfplan
    
    echo "Deployment setup complete!"
    echo "To deploy the infrastructure, run: terraform apply tfplan"
    echo "Once deployed, connect to the Jenkins server and run: scripts/jenkins_config.sh"
else
    echo "Terraform validation failed. Please fix the issues and try again."
    exit 1
fi