#!/bin/bash
# chroot_setup.sh (box): an Ubuntu 26.04 userland with CI's lavapipe (mesa-vulkan-drivers from the 26.04 archive),
# build tools and rustup, at /srv/r26; the repo at /srv/r26/root/nice (fork pr/stride-queue-any-plane).
set -e
C=/srv/r26
if [ ! -x $C/bin/bash ]; then
  mkdir -p $C
  code=resolute
  [ -e /usr/share/debootstrap/scripts/$code ] || ln -s gutsy /usr/share/debootstrap/scripts/$code
  debootstrap --variant=minbase --components=main,universe $code $C http://archive.ubuntu.com/ubuntu > /root/debootstrap.log 2>&1
fi
for m in proc sys dev dev/pts; do mountpoint -q $C/$m || mount --bind /$m $C/$m; done
cp /etc/resolv.conf $C/etc/resolv.conf
cat > $C/etc/apt/sources.list <<SRC
deb http://archive.ubuntu.com/ubuntu resolute main universe
deb http://archive.ubuntu.com/ubuntu resolute-updates main universe
deb http://security.ubuntu.com/ubuntu resolute-security main universe
SRC
chroot $C /bin/bash -c 'export DEBIAN_FRONTEND=noninteractive; apt-get update -qq && apt-get install -y -qq mesa-vulkan-drivers libvulkan1 vulkan-tools git curl ca-certificates build-essential pkg-config libssl-dev clang python3 > /root/apt.log 2>&1; apt-cache policy mesa-vulkan-drivers | head -3; VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) vulkaninfo --summary 2>/dev/null | grep -i "deviceName\|driverInfo\|apiVersion"'
chroot $C /bin/bash -c '[ -x /root/.cargo/bin/cargo ] || (curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal > /root/rustup.log 2>&1); [ -d /root/nice ] || git clone -q https://github.com/wasabipesto-bot/nice.git /root/nice; cd /root/nice; git fetch -q origin pr/stride-queue-any-plane; git checkout -q -B t26b origin/pr/stride-queue-any-plane; git log --oneline -1; . /root/.cargo/env; rustup show active-toolchain'
echo CHROOT_OK
