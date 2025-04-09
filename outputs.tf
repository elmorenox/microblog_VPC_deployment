# outputs.tf
output "jenkins_public_ip" {
  description = "The public IP address of the Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "web_server_public_ip" {
  description = "The public IP address of the Web Server"
  value       = aws_instance.web_server.public_ip
}

output "app_server_private_ip" {
  description = "The private IP address of the Application Server (only accessible from within the VPC)"
  value       = aws_instance.app_server.private_ip
}

output "monitoring_public_ip" {
  description = "The public IP address of the Monitoring server"
  value       = aws_instance.monitoring.public_ip
}

output "ssh_key_path" {
  description = "Path to the SSH private key"
  value       = local_file.private_key.filename
}

output "jenkins_initial_password_cmd" {
  description = "Command to get Jenkins initial admin password"
  value       = "SSH to the Jenkins server and run: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
}

output "web_app_url" {
  description = "URL to access the web application (through the Web Server)"
  value       = "http://${aws_instance.web_server.public_ip}"
}

output "monitoring_grafana_url" {
  description = "URL to access Grafana monitoring dashboard"
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "monitoring_prometheus_url" {
  description = "URL to access Prometheus monitoring"
  value       = "http://${aws_instance.monitoring.public_ip}:9090"
}

output "jenkins_url" {
  description = "URL to access Jenkins"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}