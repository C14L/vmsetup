# Create the Base Autoinstall ISO on macOS

Install and download

    brew install cdrtools
    brew install p7zip

    curl -O https://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-arm64.iso

Extract ISO content to a directory

    7z x ./ubuntu-24.04.3-live-server-arm64.iso -o./ubuntu-iso

Modify boot parameters. We tell the installer to look for cloud-init (nocloud) on the CDROM.

1. Edit the boot config:

File for UEFI: `./ubuntu-iso/boot/grub/grub.cfg` or for BIOS: `./ubuntu-iso/isolinux/txt.cfg`.

Find the kernel line starting with:

    linux   /casper/vmlinuz  quiet ---

Change that line to:

    linux /casper/vmlinuz autoinstall ds=nocloud\;seedfrom=/cdrom/nocloud/ quiet ---

2. Inside the ISO root and add placeholders. The real configs will come from your per-VM seed ISO:

    mkdir -p ./ubuntu-iso/nocloud
    touch ./ubuntu-iso/nocloud/meta-data
    touch ./ubuntu-iso/nocloud/user-data

3. Rebuild the ISO:

    cd ./ubuntu-iso
    xorriso -as mkisofs -o ../ubuntu-autoinstall.iso \
        -J -joliet-long -r \
        -V "Ubuntu-Autoinstall" \
        -b efi/boot/bootaa64.efi \
        -c boot.catalog \
        -no-emul-boot \
        -e efi/boot/bootaa64.efi \
        .
    cd -

This creates a file `ubuntu-autoinstall.iso`.

<!-- xorriso -as mkisofs -r -V "Ubuntu-Autoinstall" -o ../ubuntu-autoinstall.iso -J -joliet-long . -->
