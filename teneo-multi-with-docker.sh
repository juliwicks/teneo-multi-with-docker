#!/bin/bash

# Define color codes
INFO='\033[0;36m'  # Cyan
BANNER='\033[0;35m' # Magenta
WARNING='\033[0;33m'
ERROR='\033[0;31m'
SUCCESS='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${BANNER}=============================${NC}"
echo -e "${BANNER}Teneo Farm Bot Runner 24/7${NC}"
echo -e "${BANNER}Script by Nodebot (Juliwicks)${NC}"
echo -e "${BANNER}=============================${NC}"

# Step 1: Ask for the Docker container name
echo -e "${INFO}Please enter the Docker container name:${NC}"
read container_name

# Step 2: Generate a random UUID and MAC address
uuid=$(uuidgen)
mac_address=$(printf '00:50:56:%02x:%02x:%02x' $(($RANDOM%256)) $(($RANDOM%256)) $(($RANDOM%256)))

# Step 3: Ask user if they want to use a proxy
echo -e "${INFO}Do you want to use a proxy? (yes/no)${NC}"
read use_proxy

proxy_url=""
proxy_type=""
if [[ "$use_proxy" == "yes" ]]; then
  echo -e "${INFO}Choose the proxy type (http/socks5):${NC}"
  read proxy_type
  
  if [[ "$proxy_type" == "http" || "$proxy_type" == "socks5" ]]; then
    echo -e "${INFO}Please enter the proxy in the format protocol://user:pass@ip:port${NC}"
    read proxy_url
    echo -e "${INFO}Using $proxy_type Proxy: $proxy_url${NC}"
  else
    echo -e "${ERROR}Invalid proxy type. Exiting.${NC}"
    exit 1
  fi
fi

# Step 4: Change Docker socket permissions to allow interaction
echo -e "${INFO}Changing Docker socket permissions...${NC}"
sudo chmod 666 /var/run/docker.sock

# Step 5: Create Dockerfile
echo -e "${INFO}Creating Dockerfile...${NC}"
cat <<EOF > Dockerfile
# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory inside the container
WORKDIR /app

# Install necessary dependencies
RUN apt update && \\
    apt install -y git && \\
    pip install --upgrade pip

# Clone the teneo-cli repository
RUN git clone https://github.com/juliwicks/teneo-cli

# Set the working directory to the cloned repository
WORKDIR /app/teneo-cli

# Install each Python package one by one
RUN pip install aiohttp
RUN pip install asyncio
RUN pip install colorama

# Command to run the teneo-cli.py script
CMD ["python3", "teneo-cli.py"]
EOF

# Step 6: Build the Docker image
echo -e "${INFO}Building Docker image...${NC}"
docker build -t teneo-cli-runner .

# Step 7: Create environment variables file
echo -e "${INFO}Creating .env file for environment variables...${NC}"
cat <<EOF > .env
UUID=$uuid
http_proxy=$proxy_url
https_proxy=$proxy_url
ALL_PROXY=$proxy_url
EOF

# Step 8: Create Docker Compose file
echo -e "${INFO}Creating docker-compose.yml file...${NC}"
cat <<EOF > docker-compose.yml
version: "3.8"
services:
  teneo-cli:
    image: teneo-cli-runner
    container_name: $container_name
    mac_address: $mac_address
    env_file:
      - .env
    restart: no
EOF

# Step 9: Enable auto-start for the container
echo -e "${INFO}Enabling auto-start for Docker container on system boot...${NC}"
docker-compose up -d
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# Step 10: Confirm the container is running
if [[ $? -eq 0 ]]; then
  echo -e "${SUCCESS}Docker container '$container_name' is running and set to auto-start on boot.${NC}"
else
  echo -e "${ERROR}Failed to start the Docker container. Check for errors above.${NC}"
fi
