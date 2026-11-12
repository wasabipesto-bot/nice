#!/bin/sh
# taskC_build_mesa.sh: build RADV (ACO only, no LLVM, no gallium) from a Mesa release that knows GFX12 (the RX 9070 XT,
# navi48), into $W/mesa-inst, for the null-winsys shader dump (taskC_dump.sh). Box only.
set -e
W=${W:-/root/n16}; V=${MESA:-25.2.7}
mkdir -p $W/mesa && cd $W/mesa
apt-get install -y -q bison flex python3-mako python3-yaml python3-ply libdrm-dev libexpat1-dev zlib1g-dev pkg-config \
  libx11-dev libxext-dev libxrandr-dev libx11-xcb-dev libxcb1-dev libxcb-dri3-dev libxcb-present-dev libxshmfence-dev \
  libxcb-randr0-dev libxcb-shm0-dev libxcb-sync-dev libxcb-xfixes0-dev libwayland-dev wayland-protocols glslang-tools \
  libudev-dev libelf-dev ninja-build python3-pip > apt.log 2>&1 || true
pip install -q --break-system-packages 'meson>=1.4' packaging > pip.log 2>&1 || true
[ -d mesa-$V ] || { curl -sSfL https://archive.mesa3d.org/mesa-$V.tar.xz | tar xJ; }
cd mesa-$V
meson setup build --prefix=$W/mesa-inst -Dbuildtype=release -Dvulkan-drivers=amd -Dgallium-drivers= -Dllvm=disabled \
  -Dplatforms= -Dglx=disabled -Degl=disabled -Dgbm=disabled -Dopengl=false -Dgles1=disabled -Dgles2=disabled \
  -Dvideo-codecs= -Dvalgrind=disabled -Dlibunwind=disabled -Dzstd=disabled > $W/mesa/meson.log 2>&1 || { tail -40 $W/mesa/meson.log; exit 1; }
ninja -C build -j ${JOBS:-8} > $W/mesa/ninja.log 2>&1 || { tail -40 $W/mesa/ninja.log; exit 1; }
ninja -C build install > $W/mesa/install.log 2>&1
ls $W/mesa-inst/share/vulkan/icd.d/
echo MESA_BUILT $V
