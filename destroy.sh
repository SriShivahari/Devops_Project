#!/bin/bash
set -e

echo "=========================================="
echo "Destroying DevOps Infrastructure"
echo "=========================================="

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd terraform

echo -e "\n${YELLOW}This will destroy all AWS resources created by Terraform.${NC}"
echo -e "${RED}This action cannot be undone!${NC}"
echo -e "\n${YELLOW}Are you sure you want to continue? (yes/no)${NC}"
read -r response

if [[ "$response" != "yes" ]]; then
    echo "Destruction cancelled"
    exit 0
fi

echo -e "\n${YELLOW}Destroying infrastructure...${NC}"
terraform destroy -auto-approve

echo -e "\n${YELLOW}Cleaning up local files...${NC}"
rm -f ../jenkins-nlp-key.pem ../jenkins-nlp-key.pub
rm -f ../ansible/inventory.ini

echo -e "\n✓ Infrastructure destroyed successfully"
