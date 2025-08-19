#!/bin/bash

set -e

echo "Staring VMs..."
# echo "Use ssh -p 2101 ubuntu@localhost to get a shell on the Control Plane"


# dd if=/dev/zero conv=sync bs=1m count=64 of=$HOME/VMs/ovmf_vars_save.fd

NAME=201
BASEDIR=$HOME/VMs/k8scluster
HOSTFWD="hostfwd=tcp:0.0.0.0:22$NAME-:22"

qemu-system-aarch64 -M virt -accel hvf -smp 2 -m 2G -cpu cortex-a72 \
    -boot d -cdrom $BASEDIR/ubuntu-24.04.3-live-server-arm64.iso \
    -hda $BASEDIR/vm$NAME.qcow2 \
    -drive "format=raw,file=$BASEDIR/vm$NAME-edk2-arm.fd,if=pflash,readonly=on" \
    -drive "format=raw,file=$BASEDIR/vm$NAME-ovmf-arm.fd,if=pflash" \
    -device e1000,netdev=usernet -netdev "user,id=usernet,$HOSTFWD" \
    -device virtio-gpu-pci \
    -nographic

    # -device virtio-9p-pci,fsdev=fsdev0,mount_tag=host_repos -fsdev local,id=fsdev0,path=$BASEDIR/share,security_model=mapped-file \

# # vm101: Control Plane
# qemu-system-aarch64 \
#   -M virt -accel hvf -smp 2 -m 2G -cpu cortex-a72 \
#   -drive file=vm101-disk.qcow2,format=qcow2 \
#   -drive file=vm101-cidata.dmg,format=raw,if=virtio \
#   -drive format=raw,file=vm101-edk2-arm.fd,if=pflash,readonly=on \
#   -drive format=raw,file=vm101-ovmf-arm.fd,if=pflash \
#   -cdrom ubuntu-24.04.3-live-server-arm64.iso \
#   -device e1000,netdev=net101 -netdev "user,id=net101,hostfwd=tcp:0.0.0.0:2101-:22" \
#   -device virtio-gpu-pci \
#   -nographic


# -kernel vmlinuz -initrd initrd -append "ds=nocloud;s=/cidata/ console=ttyAMA0" \

# qemu-system-aarch64 -M virt -accel hvf -smp 2 -m 2G -cpu cortex-a72 \
#     -drive file=disk-vm101.qcow2,format=qcow2 \
#     -drive file=cidata-vm101.iso,format=raw \
#     -drive format=raw,file=vm101-edk2-arm.fd,if=pflash,readonly=on \
#     -drive format=raw,file=vm101-ovmf-arm.fd,if=pflash \
#     -kernel vmlinuz -initrd initrd -append "autoinstall ds=nocloud;s=/cidata/ console=ttyAMA0"
#     -device e1000,netdev=net101 -netdev "user,id=net101,hostfwd=tcp:0.0.0.0:2101-:22" \
#     -device virtio-gpu-pci \
#     -nographic

    # -hda disk-vm101.qcow2 \
    # -device virtio-9p-pci,fsdev=fsdev0,mount_tag=host_repos -fsdev local,id=fsdev0,path=$SHARED_PATH,security_model=mapped-file \


# qemu-system-aarch64 \
#   -machine virt -accel hvf -smp 2 -m 2G -cpu cortex-a72 \
#   -monitor stdio \
#   -drive file=disk-vm101.qcow2,format=qcow2 \
#   -drive file=cidata-vm101.iso,format=raw \
#   -cdrom ubuntu-24.04.3-live-server-arm64.iso \
#   -netdev user,id=net0,hostfwd=tcp::2101-:22 \
#   -device virtio-net-pci,netdev=net0 \
#   -nographic 

# # vm102: Worker
# qemu-system-aarch64 \
#   -machine virt,accel=hvf \
#   -m 2048 \
#   -cpu cortex-a72 \
#   -smp 2 \
#   -drive file=disk-vm102.qcow2,format=qcow2 \
#   -cdrom ubuntu-24.04.3-live-server-arm64.iso \
#   -drive file=cidata-vm102.iso,format=raw \
#   -netdev user,id=net1,hostfwd=tcp::2102-:22 \
#   -device virtio-net-pci,netdev=net1 \
#   -nographic &

# # vm103: Worker
# qemu-system-aarch64 \
#   -machine virt,accel=hvf \
#   -m 2048 \
#   -cpu cortex-a72 \
#   -smp 2 \
#   -drive file=disk-vm103.qcow2,format=qcow2 \
#   -cdrom ubuntu-24.04.3-live-server-arm64.iso \
#   -drive file=cidata-vm103.iso,format=raw \
#   -netdev user,id=net2,hostfwd=tcp::2103-:22 \
#   -device virtio-net-pci,netdev=net2 \
#   -nographic &

# # vm104: Worker
# qemu-system-aarch64 \
#   -machine virt,accel=hvf \
#   -m 2048 \
#   -cpu cortex-a72 \
#   -smp 2 \
#   -drive file=disk-vm104.qcow2,format=qcow2 \
#   -cdrom ubuntu-24.04.3-live-server-arm64.iso \
#   -drive file=cidata-vm104.iso,format=raw \
#   -netdev user,id=net2,hostfwd=tcp::2104-:22 \
#   -device virtio-net-pci,netdev=net2 \
#   -nographic &
