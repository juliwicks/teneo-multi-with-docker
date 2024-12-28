#!/bin/bash

# Define color codes
INFO='\033[0;36m'  # Cyan
BANNER='\033[0;35m' # Magenta
WARNING='\033[0;33m'
ERROR='\033[0;31m'
SUCCESS='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${BANNER}=============================${NC}"
echo -e "${BANNER}Teneo Bot Runner 24/7${NC}"
echo -e "${BANNER}Supports multiaccount${NC}"
echo -e "${BANNER}Script by Nodebot (Juliwicks)${NC}"
echo -e "${BANNER}=============================${NC}"

# Step 1: Ask for the Docker container name
echo -e "${INFO}Please enter the Docker container name:${NC}"
read container_name

# Step 2: Generate a random UUID and MAC address
uuid=$(uuidgen)
mac_address=$(printf '00:50:56:%02x:%02x:%02x' $(($RANDOM%256)) $(($RANDOM%256)) $(($RANDOM%256)))

# Step 3: Show generated values
echo -e "${INFO}Generated UUID: $uuid${NC}"
echo -e "${INFO}Generated MAC address: $mac_address${NC}"

# Step 4: Change Docker socket permissions to allow interaction
echo -e "${INFO}Changing Docker socket permissions...${NC}"
sudo chmod 666 /var/run/docker.sock

# Step 5: Create a Dockerfile for the Node.js project
echo -e "${INFO}Creating Dockerfile for Node.js project...${NC}"
cat <<EOF > Dockerfile
# Use an official Node.js runtime as a parent image
FROM node:16-slim

# Set the working directory inside the container
WORKDIR /app

# Install necessary dependencies
RUN apt update && \
    apt install -y git nano

# Clone the teneo-node-bot repository
RUN git clone https://github.com/Widiskel/teneo-node-bot.git

# Set the working directory to the cloned repository
WORKDIR /app/teneo-node-bot

# Install project dependencies
RUN npm install

# Configure proxy list and accounts (optional - assumes user edits manually)
# RUN nano accounts/accounts.js
# RUN nano config/proxy_list.js

# Command to start the application
CMD ["npm", "run", "start"]
EOF

# Step 6: Build the Docker image
echo -e "${INFO}Building Docker image...${NC}"
docker build -t teneo-node-bot .

# Step 7: Run the Docker container interactively
echo -e "${INFO}Running Docker container interactively with name: $container_name${NC}"
docker run -it --name "$container_name" --mac-address "$mac_address" --env UUID="$uuid" teneo-node-bot

# Step 8: Confirm the container is running
echo -e "${SUCCESS}Docker container is running interactively. You can now interact with it.${NC}"
