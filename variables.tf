variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "us-east-1a"
}

variable "ssh_key_name" {
  description = "SSH key name"
  type        = string
  default     = "deployment-key"
}

variable "ec2_ami" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-053b0d53c279acc90" # Ubuntu 22.04 LTS
}

variable "github_repo" {
  description = "GitHub repository URL"
  type        = string
  default     = "https://github.com/elmoreno_X/microblog_VPC_deployment.git"
}

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