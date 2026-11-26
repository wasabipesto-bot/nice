# Source after env.sh to make Vulkan (wgpu) see the NVIDIA cards. Debian's libegl-nvidia0 is not installed on this
# box, and without a display the NVIDIA Vulkan driver initialises through its EGL library; found 2026-11-26.
# The package is unpacked under $R/vk (apt download libegl-nvidia0; dpkg-deb -x) with a hand-written glvnd
# vendor file. The unpacked library must match the installed driver: this refuses to load on a mismatch.
V=$(sed -n "s/.*Kernel Module  *\([0-9.]*\).*/\1/p" /proc/driver/nvidia/version | head -1)
if [ -e "$R/vk/root/usr/lib/x86_64-linux-gnu/nvidia/current/libEGL_nvidia.so.$V" ]; then
  export __EGL_VENDOR_LIBRARY_FILENAMES=$R/vk/10_nvidia.json
else
  echo "env_vulkan.sh: the unpacked libEGL_nvidia does not match driver $V: refresh $R/vk (see the header)" >&2
fi
