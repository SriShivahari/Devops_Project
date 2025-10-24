output "jenkins_server_public_ip" {
  description = "Public IP address of Jenkins server"
  value       = aws_eip.jenkins_eip.public_ip
}

output "jenkins_server_id" {
  description = "EC2 instance ID"
  value       = aws_instance.jenkins_server.id
}

output "jenkins_web_url" {
  description = "Jenkins web interface URL"
  value       = "http://${aws_eip.jenkins_eip.public_ip}:8080"
}

output "flask_api_url" {
  description = "Flask API URL"
  value       = "http://${aws_eip.jenkins_eip.public_ip}:5000"
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.flask_nlp_api.repository_url
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_eip.jenkins_eip.public_ip}"
}

output "private_key_path" {
  description = "Path to the private SSH key"
  value       = "${path.module}/../${var.key_name}.pem"
}

output "iam_role_name" {
  description = "IAM role name for Jenkins EC2"
  value       = aws_iam_role.jenkins_ec2_role.name
}
