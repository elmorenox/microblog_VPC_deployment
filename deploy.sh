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

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Terraform is not installed. Please install Terraform and try again."
    exit 1
fi

# Create terraform.tfvars if it doesn't exist
if [ ! -f "$ROOT_DIR/terraform.tfvars.example" ] && [ ! -f "$ROOT_DIR/terraform.tfvars" ]; then
    echo "Creating terraform.tfvars file..."
    cat > "$ROOT_DIR/terraform.tfvars" << EOL
region              = "us-east-1"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
availability_zone   = "us-east-1a"
ssh_key_name        = "deployment-key"
ec2_ami             = "ami-053b0d53c279acc90"
github_repo         = "https://github.com/YOUR_USERNAME/microblog_VPC_deployment.git"
aws_access_key      = ""
aws_secret_key      = ""
EOL
fi

if [ -f "$ROOT_DIR/terraform.tfvars.example" ] && [ ! -f "$ROOT_DIR/terraform.tfvars" ]; then
    cp "$ROOT_DIR/terraform.tfvars.example" "$ROOT_DIR/terraform.tfvars"
    echo "Created terraform.tfvars from example file. Please edit it with your credentials."
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

# Create aws_credentials.tf if it doesn't exist
if [ ! -f "$ROOT_DIR/aws_credentials.tf" ]; then
    echo "Creating aws_credentials.tf file..."
    cat > "$ROOT_DIR/aws_credentials.tf" << EOL
variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}
EOL
fi

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