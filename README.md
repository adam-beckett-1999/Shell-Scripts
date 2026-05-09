# Shell Scripts

This repository contains a collection of shell scripts i've thrown together. Feel free to use them and adapt to your needs.

---

- qemu-guest-agent-install.sh
- ubuntu-debian-cloudinit-template-install.sh

---

## CloudImage Template Install Scripts

These shell scripts are designed to automate the creation and management of cloud-init enabled virtual machine templates. These scripts are intended for use with Proxmox VE (PVE) and are highly customizable.

## How to Use the CloudImage Template Install Script

### Prerequisites

- **Proxmox VE (PVE)**: This script is designed for use in a Proxmox VE environment, specifically to be run on a Proxmox host.
- **virt-customize**: Part of the `libguestfs` package, used to customize virtual machine images. You can install this with the following command: `apt install libguestfs-tools`. You'll be prompted to install when the script is run in Interactive mode.
- **whiptail**: Used for the interactive menu. Install with `apt install whiptail` if not already present.

### Interactive Menu & Workflow

If you run the script with no arguments, an interactive menu will guide you through all configuration options:

1. **VM Settings**: Set VM ID, memory, CPU, sockets, CPU type, network bridge, and storage.
2. **OS Selection**: Choose the OS type and version (Ubuntu, Debian, Rocky Linux).
3. **Template Name**: The script auto-generates a default template name in the format `DISTRO-VERSION-TEMPLATE` (e.g., `UBUNTU-24.04-TEMPLATE`). You can accept or override this.
4. **Cloud-Init User Options**: Optionally set a default username, password, and SSH key for the template. You can skip the SSH key if desired.
5. **Cloud-Init Network Options**: Optionally set DNS search domain and DNS servers.
6. The script downloads the correct cloud image, customizes it, and creates the Proxmox template with your settings.

### Command-Line Flags

You can use the following flags to customize the template creation process via command-line:

- `-i VMID`: The unique ID for the virtual machine. Default is `1000`.
- `-n NAME`: The name of the virtual machine template. Default is auto-generated (e.g., `UBUNTU-24.04-TEMPLATE`).
- `-m MEMORY`: The amount of memory (in MB) allocated to the virtual machine. Default is `2048`.
- `-c CORES`: The number of CPU cores. Default is `2`.
- `-s SOCKETS`: The number of CPU sockets. Default is `1`.
- `-t CPU_TYPE`: The CPU type. Default is `x86-64-v2-AES`.
- `-b BRIDGE`: The network bridge to be used. Default is `vmbr0`.
- `-d STORAGE`: The storage location for the virtual machine disk. Default is `local-lvm`.
- `-o OS_TYPE`: The operating system type (`ubuntu`, `debian`, or `rocky`).
- `-v OS_VERSION`: The version of the operating system (e.g., `24.04` for Ubuntu 24.04, `12` for Debian 12).
- `-h`: Display the help message.

### Example Usage (Interactive)

```bash
./ubuntu-debian-rocky-cloudinit-template-install.sh
```

### Example Usage (Command-Line)

```bash
./ubuntu-debian-rocky-cloudinit-template-install.sh -o ubuntu -v 24.04 -i 6000 -n UBUNTU-24.04-TEMPLATE -m 4096 -c 4 -t host
```

### Cloud-Init Options

After template creation, you will be prompted to optionally set:

- **Username** (default: root)
- **Password** (optional)
- **SSH Key** (optional, can be skipped)
- **DNS Search Domain** (optional)
- **DNS Servers** (optional, comma-separated)

All these settings are applied to the template using Proxmox's `qm set` and are available to VMs cloned from the template.

## Contributing

Contributions are welcome! If you have ideas for improving the scripts or adding new features, feel free to open an issue or submit a pull request.
