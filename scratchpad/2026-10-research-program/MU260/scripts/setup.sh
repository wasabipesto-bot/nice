#!/bin/bash
# setup.sh (box): worktree /root/mu/m at the merge (from mu260.bundle), main at 0711b163, int at 8bcee21f;
# Ubuntu 26.04 chroot /srv/r26 with CI's lavapipe (as T26B chroot_setup.sh + chroot_setup2.sh, no bind mounts).
W=/root/mu; mkdir -p $W/bin $W/logs $W/out $W/dump
. /root/.cargo/env
cd /root/nice
git fetch -q upstream main
git fetch -q origin exp/integration-1114 pr/top-slot-any-plane
git fetch -q /root/mu/mu260.bundle t26/top-slot:mu260
git log --oneline -1 mu260
[ -d $W/m ] || git worktree add -q --detach $W/m mu260
[ -d $W/main ] || git worktree add -q --detach $W/main 0711b163
cd $W/m && rustup show active-toolchain && rustup component add clippy rustfmt > $W/out/rustup-comp.log 2>&1
echo SETUP_GIT_DONE $(date -u +%T) $(rustc --version) $(git -C $W/m rev-parse HEAD)
C=/srv/r26
if [ ! -x $C/bin/bash ]; then
  mkdir -p $C
  code=resolute
  [ -e /usr/share/debootstrap/scripts/$code ] || ln -s gutsy /usr/share/debootstrap/scripts/$code
  debootstrap --variant=minbase --components=main,universe $code $C http://archive.ubuntu.com/ubuntu > $W/out/debootstrap.log 2>&1
  echo debootstrap rc=$?
fi
cp /etc/resolv.conf $C/etc/resolv.conf
cat > $C/etc/apt/sources.list <<SRC
deb http://archive.ubuntu.com/ubuntu resolute main universe
deb http://archive.ubuntu.com/ubuntu resolute-updates main universe
deb http://security.ubuntu.com/ubuntu resolute-security main universe
SRC
chroot $C /bin/bash -c 'export DEBIAN_FRONTEND=noninteractive; apt-get update -qq && apt-get install -y -qq mesa-vulkan-drivers libvulkan1 vulkan-tools ca-certificates > /root/apt.log 2>&1; echo apt rc=$?; apt-cache policy mesa-vulkan-drivers | head -3; VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) vulkaninfo --summary 2>&1 | grep -i "deviceName\|driverInfo\|apiVersion\|error"'
mkdir -p $C/root/bin
echo CHROOT_OK $(date -u +%T)
