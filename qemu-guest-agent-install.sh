#!/bin/bash

# Function to check the status of the last executed command
check_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Update repositories
echo "Updating package repositories..."
sudo apt update
check_status "Failed to update package repositories."

# Install qemu-guest-agent
echo "Installing qemu-guest-agent..."
sudo apt install qemu-guest-agent -y
check_status "Failed to install qemu-guest-agent."

# Enable the guest agent service
echo "Enabling qemu-guest-agent service..."
sudo systemctl enable qemu-guest-agent
check_status "Failed to enable qemu-guest-agent service."

# Start the guest agent service
echo "Starting qemu-guest-agent service..."
sudo systemctl start qemu-guest-agent
check_status "Failed to start qemu-guest-agent service."

echo "qemu-guest-agent installation and configuration completed successfully."