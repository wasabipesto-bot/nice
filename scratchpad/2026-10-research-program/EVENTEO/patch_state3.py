#!/usr/bin/env python3
import os, re
p = os.path.expanduser("~/SYSTEM_STATE.md"); s = open(p).read()
# the GPU table row about wgpu/Vulkan
i = s.index("| `--gpu-backend cubecl` (wgpu/Vulkan) |"); j = s.index("\n", i)
s = s[:i] + ("| `--gpu-backend cubecl` (wgpu/Vulkan) | **Works with a per-user workaround (2026-11-26); without it wgpu falls "
  "back to llvmpipe.** Cause: with no display attached, NVIDIA's Vulkan driver (`libGLX_nvidia.so.0`) initialises "
  "through EGL, and Debian's `libegl-nvidia0` (libEGL_nvidia.so.0) and its glvnd vendor file are not installed, so "
  "glvnd finds only Mesa's EGL and the driver returns NULL for `vkCreateInstance` (strace: it reads "
  "`/usr/share/glvnd/egl_vendor.d`, loads Mesa, never opens `/dev/nvidia*`). Workaround, no root: the package is "
  "unpacked under `~/research/vk` (`apt download libegl-nvidia0 && dpkg-deb -x`) with a hand-written vendor file; "
  "`. ~/research/scripts/env_vulkan.sh` sets `__EGL_VENDOR_LIBRARY_FILENAMES` to it (and refuses if the unpacked "
  "library's version differs from the loaded driver's: then download and unpack again). With it `vulkaninfo "
  "--summary` lists both cards (Vulkan 1.3.277) and wgpu adapters are `DiscreteGpu(0)` = GTX 1060, `DiscreteGpu(1)` "
  "= RTX 3060 (`CUBECL_WGPU_DEFAULT_DEVICE` or the client's `--gpu-wgpu-device`). System-wide fix, if the owner "
  "prefers it: `apt install libegl-nvidia0 nvidia-egl-common` (not done: it could change which EGL the GNOME "
  "session uses). |") + s[j:]
a = "- **Missing**: `cmake`, `clang`, `sqlite3`, `psql`, `strace`, `vulkaninfo` (`vulkan-tools`). They need the owner or a container."
if a in s:
    s = s.replace(a, "- `strace` and `vulkan-tools` (`vulkaninfo`): installed by the owner 2026-11-26.\n- **Missing**: `cmake`, `clang`, `sqlite3`, `psql`. They need the owner or a container.")
a = "│   ├── bin/TAG/          # built binaries by tag"
if "vk/" not in s and a in s:
    s = s.replace(a, "│   ├── vk/               # unpacked libegl-nvidia0 + 10_nvidia.json: the Vulkan workaround (see the GPU table)\n" + a)
s = s.replace("build_mo.sh BRANCH TAG, run_mo.sh TAG GPU RUN PHASES, off_if_idle.sh, vkprobe.py", "build_mo.sh BRANCH TAG, run_mo.sh TAG GPU RUN PHASES, off_if_idle.sh, env_vulkan.sh, vkprobe.py")
if "Vulkan on the NVIDIA cards diagnosed" not in s:
    s = s.rstrip("\n") + "\n- 2026-11-26: The owner installed `strace` and `vulkan-tools`. Vulkan on the NVIDIA cards diagnosed (missing `libegl-nvidia0`; see the GPU table) and made to work per user from `~/research/vk`; the middle-out join's device tests pass through Vulkan on the RTX 3060 (`NVIDIA GeForce RTX 3060 (Vulkan, wgpu<wgsl>)`), whole base-64 fields at 3.30 fs per admissible n against 3.23 through CUDA.\n"
open(p, "w").write(s); print("ok")
