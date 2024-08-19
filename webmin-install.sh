#!/bin/bash

set -e
set -o pipefail

# Function to check the status of the last executed command
check_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1" >&2
        exit 1
    fi
}

# Function to download a file with curl
download_file() {
    local url="$1"
    local output="$2"
    echo "Downloading $output from $url..."
    sudo curl -o "$output" "$url"
    check_status "Failed to download $output."
}

# Function to make a file executable
make_executable() {
    local file="$1"
    echo "Making $file executable..."
    sudo chmod +x "$file"
    check_status "Failed to make $file executable."
}

# Function to execute a script
execute_script() {
    local script="$1"
    echo "Executing $script..."
    sudo bash "$script"
    check_status "Failed to execute $script."
}

# Function to install a package
install_package() {
    local package="$1"
    echo "Updating repositories and installing $package..."
    sudo apt update
    sudo apt install --install-recommends "$package" -y
    check_status "Failed to install $package."
}

# Function to enable and start a service
manage_service() {
    local service="$1"
    echo "Enabling and starting $service..."
    sudo systemctl enable "$service"
    sudo systemctl start "$service"
    check_status "Failed to enable/start $service."
}

# Function to clean up
cleanup() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "Removing $file..."
        sudo rm "$file"
        check_status "Failed to remove $file."
    else
        echo "$file does not exist, skipping removal."
    fi
}

# Main execution
SCRIPT_URL="https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh"
SCRIPT_NAME="setup-repos.sh"
PACKAGE="webmin"
SERVICE="webmin"

download_file "$SCRIPT_URL" "$SCRIPT_NAME"
make_executable "$SCRIPT_NAME"
execute_script "$SCRIPT_NAME"
install_package "$PACKAGE"
manage_service "$SERVICE"
cleanup "$SCRIPT_NAME"

echo "Webmin installation and setup completed successfully."