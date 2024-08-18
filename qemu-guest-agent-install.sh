#!/bin/bash

# Update repositories and install qemu-guest-agent
sudo apt update
sudo apt install qemu-guest-agent -y

# Enable and start the guest agent service
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent