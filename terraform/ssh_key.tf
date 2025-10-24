# Generate SSH key pair
resource "tls_private_key" "jenkins_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair
resource "aws_key_pair" "jenkins_key" {
  key_name   = var.key_name
  public_key = tls_private_key.jenkins_key.public_key_openssh

  tags = {
    Name = "${var.project_name}-key"
  }
}

# Save private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.jenkins_key.private_key_pem
  filename        = "${path.module}/../${var.key_name}.pem"
  file_permission = "0400"
}

# Save public key locally
resource "local_file" "public_key" {
  content         = tls_private_key.jenkins_key.public_key_openssh
  filename        = "${path.module}/../${var.key_name}.pub"
  file_permission = "0644"
}
