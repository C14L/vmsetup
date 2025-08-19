#!/bin/bash
# run-vm.sh
# Usage: ./run-vm.sh 201

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <VM_NUMBER>"
    exit 1
fi

NAME="$1"

HOSTFWD_PORT=$((22000 + NAME))
echo "HOSTFWD_PORT: $HOSTFWD_PORT"

IP="10.0.2.$NAME"
echo "IP: $IP"

BASEDIR="$HOME/VMs/k8sdeb"
VMDIR="$BASEDIR/vm$NAME"

HDA="$VMDIR/disk.qcow2"
EDK2_FD="$VMDIR/edk2-arm.fd"
OVMF_FD="$VMDIR/ovmf-arm.fd"
ISO="$BASEDIR/debian-13.0.0-arm64-netinst.iso"

if [ ! -f "$HDA" ]; then
    read -p "Press RETURN to boot VM and install Debian on vm$IP automatically..."

    qemu-img create -f qcow2 "$HDA" 20G
    echo "✅ Created QCOW2 disk for VM $NAME ($IP): $HDA"
    qemu-system-aarch64 -M virt -accel hvf -smp 2 -m 2G -cpu cortex-a72 -nographic \
        -kernel "$BASEDIR/vmlinuz" -initrd "$VMDIR/custom-initrd.gz" \
        -append "auto=true priority=critical preseed/file=/preseed.cfg" \
        -device virtio-scsi-pci,id=scsi -drive file=$HDA,if=none,id=hda-drive,format=qcow2 \
        -device scsi-hd,bus=scsi.0,drive=hda-drive -drive file=$ISO,if=none,id=cdrom-drive,media=cdrom \
        -device scsi-cd,bus=scsi.0,drive=cdrom-drive \
        -drive "format=raw,file=$EDK2_FD,if=pflash,readonly=on" \
        -drive "format=raw,file=$OVMF_FD,if=pflash" \
        -device e1000,netdev=usernet -netdev "user,id=usernet,hostfwd=tcp::${HOSTFWD_PORT}-:22" \
        -device virtio-gpu-pci
    exit 0
fi

read -p "Press RETURN to boot vm$IP normally..."
qemu-system-aarch64 -M virt -accel hvf -smp 2 -m 2G -cpu cortex-a72 -nographic \
    -device virtio-scsi-pci,id=scsi -drive file=$HDA,if=none,id=hda-drive,format=qcow2 \
    -device scsi-hd,bus=scsi.0,drive=hda-drive \
    -drive "format=raw,file=$EDK2_FD,if=pflash,readonly=on" \
    -drive "format=raw,file=$OVMF_FD,if=pflash" \
    -device e1000,netdev=usernet -netdev "user,id=usernet,hostfwd=tcp::${HOSTFWD_PORT}-:22" \
    -device virtio-gpu-pci
