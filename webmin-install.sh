#!/bin/bash

# Download the setup-repos.sh script
sudo curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh

# Make script executable
sudo chmod +x setup-repos.sh

# Execute the setup-repos.sh script
sudo bash setup-repos.sh

# Install Webmin with recommended packages
sudo apt install --install-recommends webmin -y

# Enable and start the webmin service
sudo systemctl enable webmin
sudo systemctl start webmin

# Check the status of the Webmin service
sudo systemctl status webmin

# Remove the script
sudo rm setup-repos.sh