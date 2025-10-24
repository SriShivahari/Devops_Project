#!/bin/bash
set -e

echo "=========================================="
echo "DevOps NLP API - Infrastructure Deployment"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

command -v terraform >/dev/null 2>&1 || { echo -e "${RED}Error: Terraform is not installed${NC}" >&2; exit 1; }
command -v ansible >/dev/null 2>&1 || { echo -e "${RED}Error: Ansible is not installed${NC}" >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo -e "${RED}Error: AWS CLI is not installed${NC}" >&2; exit 1; }

echo -e "${GREEN}✓ All prerequisites installed${NC}"

# Verify AWS credentials
echo -e "\n${YELLOW}Verifying AWS credentials...${NC}"
aws sts get-caller-identity > /dev/null 2>&1 || { echo -e "${RED}Error: AWS credentials not configured${NC}" >&2; exit 1; }
echo -e "${GREEN}✓ AWS credentials verified${NC}"

# Navigate to terraform directory
cd terraform

# Initialize Terraform
echo -e "\n${YELLOW}Initializing Terraform...${NC}"
terraform init

# Plan infrastructure
echo -e "\n${YELLOW}Planning infrastructure changes...${NC}"
terraform plan -out=tfplan

# Ask for confirmation
echo -e "\n${YELLOW}Do you want to apply these changes? (yes/no)${NC}"
read -r response
if [[ "$response" != "yes" ]]; then
    echo -e "${RED}Deployment cancelled${NC}"
    exit 0
fi

# Apply Terraform
echo -e "\n${YELLOW}Creating AWS infrastructure...${NC}"
terraform apply tfplan

# Get outputs
echo -e "\n${YELLOW}Retrieving infrastructure details...${NC}"
JENKINS_IP=$(terraform output -raw jenkins_server_public_ip)
SSH_COMMAND=$(terraform output -raw ssh_command)

echo -e "${GREEN}✓ Infrastructure created successfully${NC}"
echo -e "\nJenkins Server IP: ${GREEN}${JENKINS_IP}${NC}"

# Update Ansible inventory
cd ../ansible
echo -e "\n${YELLOW}Updating Ansible inventory...${NC}"
cat > inventory.ini << EOF
[jenkins_server]
${JENKINS_IP} ansible_user=ec2-user ansible_ssh_private_key_file=../jenkins-nlp-key.pem
EOF

echo -e "${GREEN}✓ Inventory updated${NC}"

# Wait for instance to be accessible
echo -e "\n${YELLOW}Waiting for EC2 instance to be ready (this may take 2-3 minutes)...${NC}"
sleep 60

# Test SSH connection
echo -e "\n${YELLOW}Testing SSH connection...${NC}"
max_attempts=10
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i ../jenkins-nlp-key.pem ec2-user@${JENKINS_IP} "echo 'SSH connection successful'" 2>/dev/null; then
        echo -e "${GREEN}✓ SSH connection established${NC}"
        break
    fi
    attempt=$((attempt + 1))
    echo "Attempt $attempt/$max_attempts failed, retrying in 10 seconds..."
    sleep 10
done

if [ $attempt -eq $max_attempts ]; then
    echo -e "${RED}Error: Could not establish SSH connection${NC}"
    exit 1
fi

# Run Ansible playbook
echo -e "\n${YELLOW}Configuring server with Ansible...${NC}"
ansible-playbook -i inventory.ini playbook.yml

echo -e "\n${GREEN}=========================================="
echo -e "✓ Deployment Complete!"
echo -e "==========================================${NC}"

cd ../terraform
echo -e "\n${YELLOW}Access Information:${NC}"
terraform output -raw jenkins_web_url && echo ""
echo -e "\nSSH Command:"
echo -e "${GREEN}${SSH_COMMAND}${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Access Jenkins and complete the setup"
echo "2. Install required plugins: Amazon ECR, Docker Pipeline"
echo "3. Create a pipeline job connected to GitHub"
echo "4. Configure GitHub webhook"
echo ""
echo "For detailed instructions, check: /home/ec2-user/setup-info.txt on the server"
