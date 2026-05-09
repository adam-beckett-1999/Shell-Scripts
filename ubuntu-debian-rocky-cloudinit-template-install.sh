#!/bin/bash
# This script is designed to be run on a proxmox host.

set -e
set -o pipefail


# Default values for parameters
VMID="1000"
VM_NAME="linux-cloudinit-template"
MEMORY="2048"
CORES="2"
SOCKETS="1"
CPU_TYPE="x86-64-v2-AES"
BRIDGE="vmbr0"
STORAGE="local-lvm"
OS_TYPE=""
OS_VERSION=""
DISK_IMAGE=""
IMAGE_URL=""

# Interactive menu using whiptail if no arguments are provided
if [ $# -eq 0 ]; then
    if ! command -v whiptail >/dev/null 2>&1; then
        echo "whiptail is required for the interactive menu. Install it with: apt install whiptail" >&2
        exit 1
    fi

    # Check for virt-customize and offer to install if missing
    if ! command -v virt-customize >/dev/null 2>&1; then
        whiptail --title "Missing Dependency" --msgbox "virt-customize is required to customize images. You will be prompted to install it." 10 60
        if whiptail --title "Install virt-customize" --yesno "Do you want to install virt-customize (libguestfs-tools) now?" 10 60; then
            apt update && apt install -y libguestfs-tools || {
                whiptail --title "Install Failed" --msgbox "Failed to install virt-customize. Exiting." 10 60
                exit 1
            }
        else
            whiptail --title "Dependency Required" --msgbox "virt-customize is required. Exiting." 10 60
            exit 1
        fi
    fi

    VMID=$(whiptail --inputbox "Enter VM ID" 8 60 "$VMID" --title "VM ID" 3>&1 1>&2 2>&3)
    VM_NAME=$(whiptail --inputbox "Enter VM Name" 8 60 "$VM_NAME" --title "VM Name" 3>&1 1>&2 2>&3)
    MEMORY=$(whiptail --inputbox "Enter Memory (MB)" 8 60 "$MEMORY" --title "Memory" 3>&1 1>&2 2>&3)
    CORES=$(whiptail --inputbox "Enter Number of CPU Cores" 8 60 "$CORES" --title "CPU Cores" 3>&1 1>&2 2>&3)
    SOCKETS=$(whiptail --inputbox "Enter Number of CPU Sockets" 8 60 "$SOCKETS" --title "CPU Sockets" 3>&1 1>&2 2>&3)
    CPU_TYPE=$(whiptail --inputbox "Enter CPU Type" 8 60 "$CPU_TYPE" --title "CPU Type" 3>&1 1>&2 2>&3)
    BRIDGE=$(whiptail --inputbox "Enter Network Bridge" 8 60 "$BRIDGE" --title "Network Bridge" 3>&1 1>&2 2>&3)
    STORAGE=$(whiptail --inputbox "Enter Storage Location" 8 60 "$STORAGE" --title "Storage" 3>&1 1>&2 2>&3)

    OS_TYPE=$(whiptail --title "Select OS Type" --menu "Choose the OS type:" 15 60 4 \
        "ubuntu" "Ubuntu" \
        "debian" "Debian" \
        "rocky" "Rocky Linux" \
        3>&1 1>&2 2>&3)

    case $OS_TYPE in
        ubuntu)
            OS_VERSION=$(whiptail --title "Select Ubuntu Version" --menu "Choose Ubuntu version:" 20 60 8 \
                "18.04" "Bionic Beaver (LTS)" \
                "18.10" "Cosmic Cuttlefish" \
                "20.04" "Focal Fossa (LTS)" \
                "20.10" "Groovy Gorilla" \
                "22.04" "Jammy Jellyfish (LTS)" \
                "22.10" "Kinetic Kudu" \
                "23.04" "Lunar Lobster" \
                "23.10" "Mantic Minotaur" \
                "24.04" "Noble Numbat (LTS)" \
                "24.10" "Oracular Oriole" \
                "25.04" "Plucky Puffin" \
                "25.10" "Questing Quokka" \
                "26.04" "Resolute Raccoon (LTS)" \
                3>&1 1>&2 2>&3)
            ;;
        debian)
            OS_VERSION=$(whiptail --title "Select Debian Version" --menu "Choose Debian version:" 15 60 4 \
                "10" "Buster" \
                "11" "Bullseye" \
                "12" "Bookworm" \
                "13" "Trixie" \
                3>&1 1>&2 2>&3)
            ;;
        rocky)
            OS_VERSION=$(whiptail --title "Select Rocky Linux Version" --menu "Choose Rocky Linux version:" 12 60 3 \
                "8" "Rocky Linux 8" \
                "9" "Rocky Linux 9" \
                "10" "Rocky Linux 10" \
                3>&1 1>&2 2>&3)
            ;;
    esac
fi

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
    echo "  -o OS_TYPE       OS type (ubuntu, debian, rocky)"
    echo "  -v OS_VERSION    OS version (Ubuntu: 18.04, 18.10, 20.04, 20.10, 22.04, 22.10, 23.04, 23.10, 24.04, 24.10, 25.04, 25.10, 26.04. Debian: 10, 11, 12, 13. Rocky Linux: 8, 9, 10)"
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
        # Map Ubuntu version to codename and image
        case $OS_VERSION in
            "18.04") CODENAME="bionic"; DISK_IMAGE="bionic-server-cloudimg-amd64.img" ;;
            "18.10") CODENAME="cosmic"; DISK_IMAGE="cosmic-server-cloudimg-amd64.img" ;;
            "20.04") CODENAME="focal"; DISK_IMAGE="focal-server-cloudimg-amd64.img" ;;
            "20.10") CODENAME="groovy"; DISK_IMAGE="groovy-server-cloudimg-amd64.img" ;;
            "22.04") CODENAME="jammy"; DISK_IMAGE="jammy-server-cloudimg-amd64.img" ;;
            "22.10") CODENAME="kinetic"; DISK_IMAGE="kinetic-server-cloudimg-amd64.img" ;;
            "23.04") CODENAME="lunar"; DISK_IMAGE="lunar-server-cloudimg-amd64.img" ;;
            "23.10") CODENAME="mantic"; DISK_IMAGE="mantic-server-cloudimg-amd64.img" ;;
            "24.04") CODENAME="noble"; DISK_IMAGE="noble-server-cloudimg-amd64.img" ;;
            "24.10") CODENAME="oracular"; DISK_IMAGE="oracular-server-cloudimg-amd64.img" ;;
            "25.04") CODENAME="plucky"; DISK_IMAGE="plucky-server-cloudimg-amd64.img" ;;
            "25.10") CODENAME="questing"; DISK_IMAGE="questing-server-cloudimg-amd64.img" ;;
            "26.04") CODENAME="resolute"; DISK_IMAGE="resolute-server-cloudimg-amd64.img" ;;
            *) echo "Unsupported Ubuntu version. Please use one of: 18.04, 18.10, 20.04, 20.10, 22.04, 22.10, 23.04, 23.10, 24.04, 24.10, 25.04, 25.10, 26.04."; exit 1 ;;
        esac
        IMAGE_URL="https://cloud-images.ubuntu.com/$CODENAME/current/$DISK_IMAGE"
        ;;
    "debian")
        # Map Debian major version to codename and image
        case $OS_VERSION in
            "10") CODENAME="buster"; DISK_IMAGE="debian-10-generic-amd64.qcow2" ;;
            "11") CODENAME="bullseye"; DISK_IMAGE="debian-11-generic-amd64.qcow2" ;;
            "12") CODENAME="bookworm"; DISK_IMAGE="debian-12-generic-amd64.qcow2" ;;
            "13") CODENAME="trixie"; DISK_IMAGE="debian-13-generic-amd64.qcow2" ;;
            *) echo "Unsupported Debian version. Please use '10', '11', '12', or '13'."; exit 1 ;;
        esac
        IMAGE_URL="https://cloud.debian.org/images/cloud/$CODENAME/latest/$DISK_IMAGE"
        ;;
    "rocky")
        case $OS_VERSION in
            "8") DISK_IMAGE="Rocky-8-GenericCloud.latest.x86_64.qcow2" ;;
            "9") DISK_IMAGE="Rocky-9-GenericCloud.latest.x86_64.qcow2" ;;
            "10") DISK_IMAGE="Rocky-10-GenericCloud-Base.latest.x86_64.qcow2" ;;
            *) echo "Unsupported Rocky Linux version. Please use '8', '9', or '10'."; exit 1 ;;
        esac
        IMAGE_URL="https://dl.rockylinux.org/pub/rocky/$OS_VERSION/images/x86_64/$DISK_IMAGE"
        ;;
    *)
        echo "Unsupported OS type. Please use 'ubuntu', 'debian', or 'rocky'."
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
    echo "Checking if $DISK_IMAGE needs to be downloaded..."
    if should_download_image "$DISK_IMAGE"; then
        echo "Downloading $DISK_IMAGE from $IMAGE_URL..."
        rm -f "$DISK_IMAGE"
        wget -q "$IMAGE_URL" || { echo "Failed to download $DISK_IMAGE. Aborting." >&2; exit 1; }
    else
        echo "$DISK_IMAGE is up to date. No need to download."
    fi
}

customize_image() {
    echo "Customizing the disk image $DISK_IMAGE by installing qemu-guest-agent..."
    virt-customize -a "$DISK_IMAGE" --install qemu-guest-agent || { echo "Failed to customize the disk image. Aborting." >&2; exit 1; }
}

destroy_existing_vm() {
    echo "Checking if a VM with ID $VMID already exists..."
    if qm list | grep -qw "$VMID"; then
        echo "Destroying existing VM with ID $VMID..."
        qm destroy "$VMID" || { echo "Failed to destroy existing VM with ID $VMID. Aborting." >&2; exit 1; }
    else
        echo "No existing VM with ID $VMID found."
    fi
}

create_vm_template() {
    echo "Creating VM template with ID $VMID and name $VM_NAME..."
    qm create "$VMID" --name "$VM_NAME" --memory "$MEMORY" --cores "$CORES" --sockets "$SOCKETS" --cpu cputype="$CPU_TYPE" --net0 virtio,bridge="$BRIDGE",firewall=0 || { echo "Failed to create VM. Aborting." >&2; exit 1; }
    
    echo "Importing disk image $DISK_IMAGE to storage $STORAGE..."
    qm importdisk "$VMID" "$DISK_IMAGE" "$STORAGE" || { echo "Failed to import disk. Aborting." >&2; exit 1; }
    
    echo "Configuring VM disk and boot options..."
    qm set "$VMID" --scsihw virtio-scsi-pci --scsi0 "$STORAGE":vm-"$VMID"-disk-0 || { echo "Failed to set disk. Aborting." >&2; exit 1; }
    qm set "$VMID" --boot c --bootdisk scsi0 || { echo "Failed to set boot options. Aborting." >&2; exit 1; }
    qm set "$VMID" --ide2 "$STORAGE":cloudinit || { echo "Failed to set IDE options. Aborting." >&2; exit 1; }
    qm set "$VMID" --serial0 socket --vga serial0 || { echo "Failed to set serial0. Aborting." >&2; exit 1; }
    qm set "$VMID" --onboot 1 || { echo "Failed to set onboot option. Aborting." >&2; exit 1; }
    qm set "$VMID" --agent enabled=1 || { echo "Failed to enable agent. Aborting." >&2; exit 1; }
    qm set "$VMID" --tags $OS_TYPE-$OS_VERSION,cloud-init || { echo "Failed to set tags. Aborting." >&2; exit 1; }
    
    echo "Converting VM with ID $VMID to a template..."
    qm template "$VMID" || { echo "Failed to convert VM to template. Aborting." >&2; exit 1; }
}

# Execution starts here
echo "Starting the process to create a cloud-init VM template for $OS_TYPE $OS_VERSION..."

download_image
customize_image
destroy_existing_vm
create_vm_template

echo "Your template for $OS_TYPE $OS_VERSION with VM ID $VMID and name $VM_NAME has been created successfully."
