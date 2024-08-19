# Shell Scripts

This repository contains a collection of shell scripts i've thrown together. Feel free to use them and adapt to your needs.

---

## CloudImage Template Install Scripts

These shell scripts are designed to automate the creation and management of cloud-init enabled virtual machine templates. These scripts are intended for use with Proxmox VE (PVE) and are highly customizable.

## How to Use the CloudImage Template Install Script

### Prerequisites

- **Proxmox VE (PVE)**: This script is designed for use in a Proxmox VE environment, specifically to be run on a Proxmox host.
- **virt-customize**: Part of the `libguestfs` package, used to customize virtual machine images. You can install this with the following command: 'apt install libguestfs-tools'.

### Script Parameters

The script accepts several command-line arguments, allowing you to customize the virtual machine template creation process. Below are the available options:

- `-i VMID`: The unique ID for the virtual machine. Default is `5000`.
- `-n NAME`: The name of the virtual machine template. Default is `linux-cloudinit-template`.
- `-m MEMORY`: The amount of memory (in MB) allocated to the virtual machine. Default is `2048`.
- `-c CORES`: The number of CPU cores. Default is `4`.
- `-s SOCKETS`: The number of CPU sockets. Default is `1`.
- `-t CPU_TYPE`: The CPU type. Default is `x86-64-v2-AES`.
- `-b BRIDGE`: The network bridge to be used. Default is `vmbr0`.
- `-d STORAGE`: The storage location for the virtual machine disk. Default is `local-lvm`.
- `-o OS_TYPE`: The operating system type (`ubuntu` or `debian`).
- `-v OS_VERSION`: The version of the operating system (e.g., `focal` for Ubuntu 20.04, `bullseye` for Debian 11).

### Example Usage

Here are a few examples of how to use the script:

1. **Create a template for Ubuntu Focal (20.04) with default settings:**

```bash
   ./ubuntu-debian-cloudinit-template-install.sh -o ubuntu -v focal
```

2. **Create a template for Ubuntu Jammy (22.04) with custom VM ID and name:**

```bash
   ./ubuntu-debian-cloudinit-template-install.sh -o ubuntu -v jammy -i 6000 -n ubuntu-jammy-template
```

3. **Create a template for Debian Bullseye (11) with custom memory and CPU settings:**

```bash
   ./ubuntu-debian-cloudinit-template-install.sh -o debian -v bullseye -i 6100 -n debian-bullseye-template -m 4096 -c 4 -t host
```

## Contributing

Contributions are welcome! If you have ideas for improving the scripts or adding new features, feel free to open an issue or submit a pull request.
