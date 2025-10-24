#!/bin/bash

echo "==========================================="
echo "GitHub Authentication Setup"
echo "==========================================="
echo ""
echo "You are currently authenticated as a different GitHub user."
echo "To push to SriShivahari/Devops_Project, choose one option:"
echo ""
echo "1. Use Personal Access Token (Recommended)"
echo "2. Use SSH Key"
echo ""
read -p "Enter your choice (1 or 2): " choice

if [ "$choice" == "1" ]; then
    echo ""
    echo "📋 Steps to create a Personal Access Token:"
    echo "1. Go to: https://github.com/settings/tokens"
    echo "2. Click 'Generate new token' → 'Generate new token (classic)'"
    echo "3. Give it a name: 'DevOps Project'"
    echo "4. Select scopes: ✓ repo (full control of private repositories)"
    echo "5. Click 'Generate token'"
    echo "6. COPY the token (you won't see it again!)"
    echo ""
    read -p "Press Enter when you have your token ready..."
    
    echo ""
    echo "Now pushing to GitHub..."
    echo "When prompted:"
    echo "  Username: SriShivahari"
    echo "  Password: <paste your token>"
    echo ""
    
    git config credential.helper store
    git push -u origin main
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Successfully pushed to GitHub!"
    else
        echo ""
        echo "❌ Push failed. Please check your credentials."
    fi

elif [ "$choice" == "2" ]; then
    echo ""
    echo "📋 Setting up SSH authentication:"
    
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        echo "Generating SSH key..."
        ssh-keygen -t ed25519 -C "shivahari.kannan@gmail.com" -f ~/.ssh/id_ed25519 -N ""
    fi
    
    echo ""
    echo "📝 Copy this public key and add it to GitHub:"
    echo "   Go to: https://github.com/settings/keys"
    echo "   Click: 'New SSH key'"
    echo "   Title: 'DevOps Project'"
    echo "   Key type: 'Authentication Key'"
    echo ""
    cat ~/.ssh/id_ed25519.pub
    echo ""
    read -p "Press Enter after adding the key to GitHub..."
    
    echo ""
    echo "Changing remote to SSH..."
    git remote set-url origin git@github.com:SriShivahari/Devops_Project.git
    
    echo "Testing SSH connection..."
    ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"
    
    echo "Pushing to GitHub..."
    git push -u origin main
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Successfully pushed to GitHub!"
    else
        echo ""
        echo "❌ Push failed. Please verify your SSH key is added correctly."
    fi

else
    echo "Invalid choice. Exiting."
    exit 1
fi
