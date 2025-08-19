# VM Automation Scripts for Debian on macOS aarch64

This repository contains two scripts to automate the creation and management of Debian virtual machines (VMs) on a macOS host system with an aarch64 architecture (e.g., Apple Silicon Macs).

## Prepare host macOS
- Install 7z: `brew install p7zip`
- Install QEMU: `brew install qemu` (may need some extra steps)

## Prepare Debian ISO
- Download Debian ARM64 netinst ISO from https://cdimage.debian.org/debian-cd/current/arm64/iso-cd/ and place in $BASEDIR.
- Extract ISO: `7z x $BASEDIR/debian-13.0.0-arm64-netinst.iso -o$BASEDIR/debian-extracted`
- Copy files: `cp $BASEDIR/debian-extracted/install.a64/{vmlinuz,initrd.gz} $BASEDIR/`
- Remove extracted: `rm -rf $BASEDIR/debian-extracted`

## `make-seed.sh`
- **Purpose**: Generates custom initialization images (initrd) for Debian VMs with preconfigured settings.
- **Functionality**: 
  - Creates a directory structure for each VM.
  - Generates a `preseed.cfg` file with static IP, hostname, user setup, and SSH key configuration.
  - Embeds the SSH public key for the `ubuntu` user.
  - Builds a custom initrd image by unpacking the base initrd, adding the preseed file, and repacking it.
  - Initializes OVMF and EDK2 firmware files for VM booting.
- **Usage**: Run `./make-seed.sh VM_NUMBER [VM_NUMBER ...]` (e.g., `./make-seed.sh 201 202`) to create seed images for specified VM numbers.

## `run-vm.sh`
- **Purpose**: Automates the installation and normal booting of Debian VMs.
- **Functionality**:
  - Creates a 20GB qcow2 disk image if it doesn’t exist.
  - Launches QEMU with the custom initrd for automated Debian installation using preseed configuration.
  - Includes a 3 minute timeout to kill the QEMU process if installation hangs.
  - Boots the VM normally after installation or if the disk already exists, mapping SSH port (e.g., 22201 for VM 201).
- **Usage**: Run `./run-vm.sh VM_NUMBER` (e.g., `./run-vm.sh 201`) to start the VM installation or normal boot.

## Host System Compatibility
- **Supported**: macOS on aarch64 architecture (e.g., Apple Silicon M1/M2/M3/M4 Macs).
- **Requirements**: QEMU with HVF acceleration, `p7zip` and Debian ARM64 netinst ISO.
- **Setup**: Ensure `$BASEDIR` (e.g., `$HOME/VMs/k8sdeb`) contains `vmlinuz`, `initrd.gz`, `TMPL-edk2-arm.fd`, and the Debian ISO.

## Workflow
1. Run `make-seed.sh` to prepare VM seed images.
2. Run `run-vm.sh` to install Debian on a new VM or boot an existing one.
3. After installation, the script automatically proceeds to normal boot mode.

## Notes
- Adjust `sleep 180` in `run-vm.sh` if installation takes longer.
- SSH access is enabled with the embedded public key on port `22000 + VM_NUMBER`.

## Example
- `./make-seed.sh 201` creates a directory `./vm201` with all install files.
- `./run-vm.sh 201` installs/boots the VM.
- VM's IP: `10.0.2.201`
- VM's SSH port: `localhost:22201`
- VM's hostname: `vm201`
