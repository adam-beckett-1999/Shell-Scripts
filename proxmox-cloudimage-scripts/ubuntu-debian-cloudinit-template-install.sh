#!/bin/bash

set -e
set -o pipefail

# Default values for parameters
VMID="5000"
VM_NAME="linux-cloudinit-template"
MEMORY="2048"
CORES="4"
SOCKETS="1"
CPU_TYPE="x86-64-v2-AES"
BRIDGE="vmbr0"
STORAGE="local-lvm"
OS_TYPE=""
OS_VERSION=""
DISK_IMAGE=""
IMAGE_URL=""

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
    echo "  -o OS_TYPE       OS type (ubuntu or debian)"
    echo "  -v OS_VERSION    OS version (bionic, focal, jammy, noble for Ubuntu. buster, bullseye, bookworm for Debian.)"
    echo "  -h               Display this help message"
    exit 1
}

# Parse command-line arguments
while getopts "i:n:m:c:s:t:b:d:o:v:h" opt; do
    case ${opt} in
        i) VMID="$OPTARG" ;;
        n) VM_NAME="$OPTARG" ;;
        m) MEMORY="$OPTARG" ;;
        c) CORES="$OPTARG" ;;
        s) SOCKETS="$OPTARG" ;;
        t) CPU_TYPE="$OPTARG" ;;
        b) BRIDGE="$OPTARG" ;;
        d) STORAGE="$OPTARG" ;;
        o) OS_TYPE="$OPTARG" ;;
        v) OS_VERSION="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Set the correct DISK_IMAGE and IMAGE_URL based on OS type and version
case $OS_TYPE in
    "ubuntu")
        case $OS_VERSION in
            "focal") DISK_IMAGE="focal-server-cloudimg-amd64.img" ;;
            "bionic") DISK_IMAGE="bionic-server-cloudimg-amd64.img" ;;
            "jammy") DISK_IMAGE="jammy-server-cloudimg-amd64.img" ;;
            "noble") DISK_IMAGE="noble-server-cloudimg-amd64.img" ;;
            *) echo "Unsupported Ubuntu version. Please use 'focal', 'bionic', 'jammy', or 'noble'."; exit 1 ;;
        esac
        IMAGE_URL="https://cloud-images.ubuntu.com/$OS_VERSION/current/$DISK_IMAGE"
        ;;
    "debian")
        case $OS_VERSION in
            "bullseye") DISK_IMAGE="debian-11-generic-amd64.qcow2" ;;
            "bookworm") DISK_IMAGE="debian-12-generic-amd64.qcow2" ;;
            "buster") DISK_IMAGE="debian-10-generic-amd64.qcow2" ;;
            *) echo "Unsupported Debian version. Please use 'buster', 'bullseye', or 'bookworm'."; exit 1 ;;
        esac
        IMAGE_URL="https://cloud.debian.org/images/cloud/$OS_VERSION/latest/$DISK_IMAGE"
        ;;
    *)
        echo "Unsupported OS type. Please use 'ubuntu' or 'debian'."
        exit 1
        ;;
esac

command -v virt-customize >/dev/null 2>&1 || { echo "virt-customize is required but not installed. Install with 'apt install libguestfs-tools'." >&2; exit 1; }

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
    qm set "$VMID" --tags $OS_TYPE-$OS_VERSION,cloud-init || { echo "Failed to set tags. Aborting." >&2; exit 1; }
    qm template "$VMID" || { echo "Failed to convert VM to template. Aborting." >&2; exit 1; }
}

download_image
customize_image
destroy_existing_vm
create_vm_template

echo "Your template for $OS_TYPE $OS_VERSION with VM ID $VMID and name $VM_NAME has been created successfully."
