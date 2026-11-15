#!/bin/bash
# chroot_setup.sh (box): Ubuntu 26.04 "resolute" minbase at /srv/r26 with CI's lavapipe (mesa-vulkan-drivers 26.0.8).
# Test binaries are built on the host and run inside the chroot (from T26B/raw/ci/chroot_setup*.sh).
C=/srv/r26
if [ ! -x $C/bin/bash ]; then
  mkdir -p $C
  code=resolute
  [ -e /usr/share/debootstrap/scripts/$code ] || ln -s gutsy /usr/share/debootstrap/scripts/$code
  debootstrap --variant=minbase --components=main,universe $code $C http://archive.ubuntu.com/ubuntu > /root/n22/out/debootstrap.log 2>&1 || { echo DEBOOTSTRAP_FAIL; tail -5 /root/n22/out/debootstrap.log; }
fi
cp /etc/resolv.conf $C/etc/resolv.conf
cat > $C/etc/apt/sources.list <<SRC
deb http://archive.ubuntu.com/ubuntu resolute main universe
deb http://archive.ubuntu.com/ubuntu resolute-updates main universe
deb http://security.ubuntu.com/ubuntu resolute-security main universe
SRC
chroot $C /bin/bash -c 'export DEBIAN_FRONTEND=noninteractive; apt-get update -qq && apt-get install -y -qq mesa-vulkan-drivers libvulkan1 vulkan-tools ca-certificates > /root/apt.log 2>&1; echo apt rc=$?; apt-cache policy mesa-vulkan-drivers | head -3; VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) vulkaninfo --summary 2>&1 | grep -i "deviceName\|driverInfo\|apiVersion\|error"'
echo CHROOT_OK
