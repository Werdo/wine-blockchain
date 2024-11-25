#!/bin/bash

echo "==================================================="
echo "       Wine Blockchain Dependencies Installer        "
echo "==================================================="

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        echo "✔️ $1"
    else
        echo "❌ Error: $1 failed"
        exit 1
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y
check_status "System update"

# Install basic requirements
echo "Installing basic dependencies..."
sudo apt install -y git wget curl build-essential cmake libssl-dev libgmp-dev python3 python3-pip
check_status "Basic dependencies"

# Install Docker if not present
if ! command_exists docker; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    check_status "Docker installation"
fi

# Install Docker Compose if not present
if ! command_exists docker-compose; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    check_status "Docker Compose installation"
fi

# Install EOSIO
echo "Installing EOSIO..."
wget https://github.com/EOSIO/eos/releases/download/v2.1.0/eosio_2.1.0-1-ubuntu-20.04_amd64.deb
sudo apt install -y ./eosio_2.1.0-1-ubuntu-20.04_amd64.deb
rm eosio_2.1.0-1-ubuntu-20.04_amd64.deb
check_status "EOSIO installation"

# Install EOSIO CDT
echo "Installing EOSIO CDT..."
wget https://github.com/EOSIO/eosio.cdt/releases/download/v1.8.1/eosio.cdt_1.8.1-1-ubuntu-20.04_amd64.deb
sudo apt install -y ./eosio.cdt_1.8.1-1-ubuntu-20.04_amd64.deb
rm eosio.cdt_1.8.1-1-ubuntu-20.04_amd64.deb
check_status "EOSIO CDT installation"

# Install Java for Elasticsearch
echo "Installing Java..."
sudo apt install -y openjdk-11-jdk
check_status "Java installation"

# Install Elasticsearch
echo "Installing Elasticsearch..."
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update && sudo apt install -y elasticsearch
check_status "Elasticsearch installation"

# Install Kibana
echo "Installing Kibana..."
sudo apt install -y kibana
check_status "Kibana installation"

# Configure Elasticsearch service
echo "Configuring Elasticsearch..."
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
check_status "Elasticsearch configuration"

# Configure Kibana service
echo "Configuring Kibana..."
sudo systemctl enable kibana
sudo systemctl start kibana
check_status "Kibana configuration"

echo "==================================================="
echo "            Installation Complete! 🚀               "
echo "==================================================="
echo
echo "Please run 'newgrp docker' or log out and back in"
echo "to start using Docker without sudo."
echo
