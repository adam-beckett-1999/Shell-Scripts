#!/bin/bash

set -e
set -o pipefail

# Default values for parameters
VMID="5000"
VM_NAME="ubuntu-2004-cloudinit-template"
MEMORY="2048"
CORES="2"
SOCKETS="2"
CPU_TYPE="x86-64-v2-AES"
BRIDGE="vmbr0"
STORAGE="storage-01-zfs-iscsi"
DISK_IMAGE="focal-server-cloudimg-amd64.img"
IMAGE_URL="https://cloud-images.ubuntu.com/focal/current/$DISK_IMAGE"

# Function to display usage
usage() {
    echo "Usage: $0 [options]"
    echo "  -i VMID          VM ID (default: $VMID)"
    echo "  -n NAME          VM name (default: $VM_NAME)"
    echo "  -m MEMORY        Memory in MB (default: $MEMORY)"
    echo "  -c CORES         Number of CPU cores (default: $CORES)"
    echo "  -s SOCKETS       Number of CPU sockets (default: $SOCKETS)"
    echo "  -t CPU_TYPE      CPU type (default: $CPU_TYPE)"
    echo "  -b BRIDGE        Network bridge (default: $BRIDGE)"
    echo "  -d STORAGE       Storage location (default: $STORAGE)"
    echo "  -h               Display this help message"
    exit 1
}

# Parse command-line arguments
while getopts "i:n:m:c:s:t:b:d:h" opt; do
    case ${opt} in
        i) VMID="$OPTARG" ;;
        n) VM_NAME="$OPTARG" ;;
        m) MEMORY="$OPTARG" ;;
        c) CORES="$OPTARG" ;;
        s) SOCKETS="$OPTARG" ;;
        t) CPU_TYPE="$OPTARG" ;;
        b) BRIDGE="$OPTARG" ;;
        d) STORAGE="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

command -v virt-customize >/dev/null 2>&1 || { echo "virt-customize is required but not installed. Aborting." >&2; exit 1; }

should_download_image() {
    local file="$1"
    [[ ! -f "$file" ]] && return 0
    local current_time=$(date +%s)
    local file_mod_time=$(stat --format="%Y" "$file")
    local difference=$(( current_time - file_mod_time ))
    (( difference >= 86400 ))
}

download_image() {
    if should_download_image "$DISK_IMAGE"; then
        rm -f "$DISK_IMAGE"
        wget -q "$IMAGE_URL" || { echo "Failed to download $DISK_IMAGE. Aborting." >&2; exit 1; }
    fi
}

customize_image() {
    virt-customize -a "$DISK_IMAGE" --install qemu-guest-agent || { echo "Failed to customize the disk image. Aborting." >&2; exit 1; }
}

destroy_existing_vm() {
    if qm list | grep -qw "$VMID"; then
        qm destroy "$VMID" || { echo "Failed to destroy existing VM with ID $VMID. Aborting." >&2; exit 1; }
    fi
}

create_vm_template() {
    qm create "$VMID" --name "$VM_NAME" --memory "$MEMORY" --cores "$CORES" --sockets "$SOCKETS" --cpu cputype="$CPU_TYPE" --net0 virtio,bridge="$BRIDGE",firewall=0 || { echo "Failed to create VM. Aborting." >&2; exit 1; }
    qm importdisk "$VMID" "$DISK_IMAGE" "$STORAGE" || { echo "Failed to import disk. Aborting." >&2; exit 1; }
    qm set "$VMID" --scsihw virtio-scsi-pci --scsi0 "$STORAGE":vm-"$VMID"-disk-0 || { echo "Failed to set disk. Aborting." >&2; exit 1; }
    qm set "$VMID" --boot c --bootdisk scsi0 || { echo "Failed to set boot options. Aborting." >&2; exit 1; }
    qm set "$VMID" --ide2 "$STORAGE":cloudinit || { echo "Failed to set IDE options. Aborting." >&2; exit 1; }
    qm set "$VMID" --serial0 socket --vga serial0 || { echo "Failed to set serial0. Aborting." >&2; exit 1; }
    qm set "$VMID" --onboot 1 || { echo "Failed to set onboot option. Aborting." >&2; exit 1; }
    qm set "$VMID" --agent enabled=1 || { echo "Failed to enable agent. Aborting." >&2; exit 1; }
    qm set "$VMID" --tags ubuntu-20.04,cloud-init || { echo "Failed to set tags. Aborting." >&2; exit 1; }
    qm template "$VMID" || { echo "Failed to convert VM to template. Aborting." >&2; exit 1; }
}

download_image
customize_image
destroy_existing_vm
create_vm_template

echo "Your template with VM ID $VMID and name $VM_NAME has been created successfully."

