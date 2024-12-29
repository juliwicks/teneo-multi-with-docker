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
if [[ "$use_proxy" == "yes" ]]; then
  echo -e "${INFO}Please enter the proxy in the format protocol://user:pass@ip:port${NC}"
  read proxy_url
  echo -e "${INFO}Using Proxy: $proxy_url${NC}"

  # Step 4: Auto-detect proxy type based on the protocol
  if [[ "$proxy_url" =~ ^http:// ]]; then
    proxy_type="http"
  elif [[ "$proxy_url" =~ ^socks5:// ]]; then
    proxy_type="socks5"
  else
    echo -e "${ERROR}Unsupported proxy type. Only http and socks5 are supported.${NC}"
    exit 1
  fi
else
  echo -e "${INFO}No proxy selected.${NC}"
fi

# Step 5: Change Docker socket permissions to allow interaction
echo -e "${INFO}Changing Docker socket permissions...${NC}"
sudo chmod 666 /var/run/docker.sock

# Step 6: Create Dockerfile
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

# Step 7: Build the Docker image
echo -e "${INFO}Building Docker image...${NC}"
docker build -t teneo-cli-runner .

# Step 8: Create environment variables file
echo -e "${INFO}Creating .env file for environment variables...${NC}"
cat <<EOF > .env
UUID=$uuid
http_proxy=$proxy_url
https_proxy=$proxy_url
ALL_PROXY=$proxy_url
EOF

# Step 9: Create Docker Compose file (removed version to avoid warning)
echo -e "${INFO}Creating docker-compose.yml file...${NC}"
cat <<EOF > docker-compose.yml
services:
  teneo-cli:
    image: teneo-cli-runner
    container_name: $container_name
    mac_address: $mac_address
    env_file:
      - .env
    restart: always
EOF

# Step 10: Enable auto-start for the container and run it interactively
echo -e "${INFO}Running Docker container interactively with name: $container_name${NC}"
docker run -it --name "$container_name" --mac-address "$mac_address" --env UUID="$uuid" teneo-cli-runner /bin/bash

# Step 11: Enable Docker to auto-start on boot
echo -e "${INFO}Enabling auto-start for Docker service...${NC}"
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# Step 12: Check if the container is running
echo -e "${INFO}Checking Docker container status...${NC}"
docker ps | grep "$container_name" > /dev/null
if [[ $? -eq 0 ]]; then
  echo -e "${SUCCESS}Docker container '$container_name' is running.${NC}"
else
  echo -e "${ERROR}Failed to start the Docker container. Check for errors above.${NC}"
fi
