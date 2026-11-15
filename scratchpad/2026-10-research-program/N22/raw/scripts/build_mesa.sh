#!/bin/sh
# build_mesa.sh: RADV (ACO only, no LLVM, no gallium) from Mesa $MESA (default 26.0.8, what CI's lavapipe is) into
# $W/mesa-inst-$MESA, for the null-winsys GFX1201 compile (pipec). Box only. From N21's taskC_build_mesa.sh.
set -e
W=${W:-/root/n22}; V=${MESA:-26.0.8}
mkdir -p $W/mesa && cd $W/mesa
apt-get install -y -q bison flex python3-mako python3-yaml python3-ply libdrm-dev libexpat1-dev zlib1g-dev pkg-config \
  libx11-dev libxext-dev libxrandr-dev libx11-xcb-dev libxcb1-dev libxcb-dri3-dev libxcb-present-dev libxshmfence-dev \
  libxcb-randr0-dev libxcb-shm0-dev libxcb-sync-dev libxcb-xfixes0-dev libwayland-dev wayland-protocols glslang-tools \
  libudev-dev libelf-dev ninja-build python3-pip > apt-$V.log 2>&1 || true
pip install -q --break-system-packages 'meson>=1.4' packaging pyyaml mako > pip-$V.log 2>&1 || true
[ -d mesa-$V ] || { curl -sSfL https://archive.mesa3d.org/mesa-$V.tar.xz | tar xJ; }
cd mesa-$V
meson setup build --prefix=$W/mesa-inst-$V -Dbuildtype=release -Dvulkan-drivers=amd -Dgallium-drivers= -Dllvm=disabled \
  -Dplatforms= -Dglx=disabled -Degl=disabled -Dgbm=disabled -Dopengl=false -Dgles1=disabled -Dgles2=disabled \
  -Dvideo-codecs= -Dvalgrind=disabled -Dlibunwind=disabled -Dzstd=disabled > $W/mesa/meson-$V.log 2>&1 || { tail -40 $W/mesa/meson-$V.log; exit 1; }
ninja -C build -j ${JOBS:-8} > $W/mesa/ninja-$V.log 2>&1 || { tail -40 $W/mesa/ninja-$V.log; exit 1; }
ninja -C build install > $W/mesa/install-$V.log 2>&1
ls $W/mesa-inst-$V/share/vulkan/icd.d/
echo MESA_BUILT $V
