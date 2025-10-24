variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = "462645401353"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "devops-nlp-api"
}

variable "instance_type" {
  description = "EC2 instance type (Free tier: t3.micro)"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "jenkins-nlp-key"
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "flask-nlp-api"
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this to your IP in production
}
