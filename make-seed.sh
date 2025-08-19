#!/bin/bash
# Generate custom initrd for Debian VMs with static IPs

BASEDIR=$HOME/VMs/k8sdeb
NETWORK_GATEWAY=10.0.2.2
NETWORK_MASK=255.255.255.0
DNS="8.8.8.8 8.8.4.4"

for NAME in "$@"; do
    VMIP="10.0.2.$NAME"
    VMDIR="$BASEDIR/vm$NAME"
    mkdir -p "$VMDIR"

    # Create preseed.cfg
    cat > "$VMDIR/preseed.cfg" <<EOF
d-i debian-installer/locale string en_US
d-i console-setup/ask_detect boolean false
d-i keyboard-configuration/xkb-keymap select us

d-i netcfg/choose_interface select auto
d-i netcfg/disable_autoconfig boolean true
d-i netcfg/get_ipaddress string $VMIP
d-i netcfg/get_netmask string $NETWORK_MASK
d-i netcfg/get_gateway string $NETWORK_GATEWAY
d-i netcfg/get_nameservers string $DNS
d-i netcfg/confirm_static boolean true
d-i netcfg/get_hostname string vm$NAME
d-i netcfg/get_domain string

d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

d-i clock-setup/utc boolean true
d-i time/zone string UTC

d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/default_filesystem string ext4
d-i partman/choose_partition select finish
d-i partman/confirm_write_new_label boolean true
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

d-i passwd/root-login boolean false
d-i passwd/make-user boolean true
d-i passwd/user-fullname string Ubuntu User
d-i passwd/username string ubuntu
d-i passwd/user-password-crypted password \$6\$o4yVbzd0qRG8mbej\$aLwFboNSAdObQ2dz78VywMJnsDFDWCxYl5IQNpxLseO/JhUPTalpZA5xbjYw072.LtRf4SB3gogNY5VTR7eIT1
d-i user-setup/allow-password-weak boolean true

tasksel tasksel/first multiselect ssh-server

d-i grub-installer/only_debian boolean true
d-i pkgsel/upgrade select none

d-i preseed/late_command string \
    in-target mkdir -p /home/ubuntu/.ssh; \
    in-target sh -c "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCaosjt+gQGHQaSoI6Y6Ly5tx4bC3GJ1jzhK/MTisf2tBqICfEJVC4x8xLqso6t6ifmDNo3iNKLOVN7kG51tvERvP+y5cRklS8lAciiavenS0ByKMNSnfcyn71mDZ2UO/Kdu/8B1tEOKWpxDLtEdboKUS2ezhDUPKHp1zNcrFIf0rRb8/mwBrvfTOmraXXlXBI1M1nxh/sLHNWnyN/rIuJnykqMCwE8vO3dMU7JyxU4wrxF3ZqhMF7lUvBMH6z8ZtmpQzeTzh+zAHkMXaNeApH81sCPitsw0qDxxfHPd3QVGqXVoQWzs3KpxpryHmRhVCu84EjerknuAjdkMtvgKNcXG6I66ltCD6KyeQm4Cnf1o63YoMbKAByK1lBXem1wEOUIemvW4fdPEcZOjhWU033Rjr+687oV+/YND0JK/Fei1ObeMKyxn90eUwQPKGviW1MGAp4t0O+y1OCNH+mmUfSclG/dTTMcdLw4HtXcmko9SCxw/47/6VZ/a+/pwzQeO7Teh+DawF2ARrghFTY+geV+J4K2Xmz4FZQXs0f3EDdJSFFYfXl4Xhh8/aGFPsgr2KkCy7+o6qhJrDrtmxixHK5sB+tjoN5xMvIXXUPZW/X0e1g76sq3W2lJoMTP3fx2ECvIZRec0ZqqmKNtEdXqD9V1Vy/e7WQAvTqNbWE2bVVHBQ==' > /home/ubuntu/.ssh/authorized_keys"; \
    in-target chown -R ubuntu:ubuntu /home/ubuntu/.ssh; \
    in-target chmod 700 /home/ubuntu/.ssh; \
    in-target chmod 600 /home/ubuntu/.ssh/authorized_keys \
    in-target poweroff
EOF

    # Create custom initrd
    INITRD_DIR="$VMDIR/initrd-temp"
    mkdir -p "$INITRD_DIR"
    cd "$INITRD_DIR"
    gunzip < "$BASEDIR/initrd.gz" | cpio -id
    cp "$VMDIR/preseed.cfg" .
    find . | cpio -o -H newc | gzip > "$VMDIR/custom-initrd.gz"
    cd "$BASEDIR"
    rm -rf "$INITRD_DIR"
    echo "✅ Created custom initrd for VM $NAME ($VMIP)"

    F="$VMDIR/ovmf-arm.fd"
    dd if=/dev/zero conv=sync bs=1m count=64 of="$F"
    echo "✅ Created OVMF file for VM $NAME ($VMIP): $F"

    F="$VMDIR/edk2-arm.fd"
    cp "$BASEDIR/TMPL-edk2-arm.fd" "$F"
    echo "✅ Copied EDK2 file for VM $NAME ($VMIP): $F"
done
