#!/bin/bash
# chroot_setup2.sh (box): /srv/r26 (Ubuntu 26.04 "resolute", debootstrap minbase) gets CI's lavapipe packages.
# No bind mounts (the container may not mount); test binaries are built on the host and run inside the chroot.
C=/srv/r26
cp /etc/resolv.conf $C/etc/resolv.conf
cat > $C/etc/apt/sources.list <<SRC
deb http://archive.ubuntu.com/ubuntu resolute main universe
deb http://archive.ubuntu.com/ubuntu resolute-updates main universe
deb http://security.ubuntu.com/ubuntu resolute-security main universe
SRC
chroot $C /bin/bash -c 'export DEBIAN_FRONTEND=noninteractive; apt-get update -qq && apt-get install -y -qq mesa-vulkan-drivers libvulkan1 vulkan-tools ca-certificates > /root/apt.log 2>&1; echo apt rc=$?; apt-cache policy mesa-vulkan-drivers | head -3; VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) vulkaninfo --summary 2>&1 | grep -i "deviceName\|driverInfo\|apiVersion\|error"'
echo CHROOT_OK
