#!/bin/bash

##############################################################################
# things to double-check:
# 1. user directory
# 2. vm-id of created template (in this script id 5000 is used)
# 3. which bridge you assign with the create line (currently set to vmbr0)
# 4. which storage is being utilized (script uses my storage on truenas)
##############################################################################

DISK_IMAGE="focal-server-cloudimg-amd64.img"
IMAGE_URL="https://cloud-images.ubuntu.com/focal/current/$DISK_IMAGE"

# Function to check if a file was modified in the last 24 hours or doesn't exist
should_download_image() {
    local file="$1"
    # If file doesn't exist, return true (i.e., should download)
    [[ ! -f "$file" ]] && return 0
    local current_time=$(date +%s)
    local file_mod_time=$(stat --format="%Y" "$file")
    local difference=$(( current_time - file_mod_time ))
    # If older than 24 hours, return true
    (( difference >= 86400 ))
}

# Download the disk image if it doesn't exist or if it was modified more than 24 hours ago
if should_download_image "$DISK_IMAGE"; then
    rm -f "$DISK_IMAGE"
    wget -q "$IMAGE_URL"
fi

# Add your virt-customize commands here
sudo virt-customize -a "$DISK_IMAGE" --install qemu-guest-agent

if sudo qm list | grep -qw "5000"; then
    sudo qm destroy 5000
fi

sudo qm create 5000 --name "ubuntu-2004-cloudinit-template" --memory 2048 --cores 2 --sockets 2 --cpu cputype=x86-64-v2-AES --net0 virtio,bridge=vmbr0,firewall=0
sudo qm importdisk 5000 "$DISK_IMAGE" storage-01-zfs-iscsi
sudo qm set 5000 --scsihw virtio-scsi-pci --scsi0 storage-01-zfs-iscsi:vm-5000-disk-0
sudo qm set 5000 --boot c --bootdisk scsi0
sudo qm set 5000 --ide2 storage-01-zfs-iscsi:cloudinit
sudo qm set 5000 --serial0 socket --vga serial0
sudo qm set 5000 --onboot 1
sudo qm set 5000 --ostype 126
sudo qm set 5000 --agent enabled=1
sudo qm set 5000 --tags ubuntu-22.04,cloud-init,template
sudo qm template 5000

echo "Your template has been created. You should now be able to clone this however many times you need. Use the cloud-init tab under the template to add in your username/password, SSH key, and network/DNS details."