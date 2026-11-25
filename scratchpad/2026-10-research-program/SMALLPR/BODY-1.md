**Before.** Under `--gpu-backend auto`, when CubeCL's CUDA runtime could not start, the client took whatever wgpu adapter came up next. On an NVIDIA machine whose CUDA context creation fails and that has Mesa installed, that is llvmpipe: correct results at a small fraction of the speed, with a warning about CUDA and an info line naming the device. `--gpu-backend cubecl` on a machine with no GPU driver did the same with only the info line.

**Now.** A software renderer (lavapipe, llvmpipe, SwiftShader: the name test the kernels already use) is refused. Named with `--gpu-backend cubecl`, that is an error and exit 1. Under `auto` it counts as a failed backend and is logged as a warning with the reason: the chain goes on to hand-CUDA, and if nothing is left the final error lists why each backend was passed over. A hardware wgpu device used because CUDA failed on a machine with an NVIDIA driver gets a second warning, after the existing one about CUDA, that names the device and the CUDA error.

**Unchanged.** A machine with a real Vulkan or Metal GPU and no CUDA (an AMD card, an Apple M-series) gets the same device and the same log as before. No new flag or setting. Nothing in CI or the justfile runs the client on a software renderer (the device tests on lavapipe do not use the client).

**Changed for an existing value.** `--gpu-wgpu-device Cpu` selects a software renderer, so it is now refused too; the help text no longer offers it. A fleet box whose CUDA fails and that has only Mesa now exits instead of benchmarking llvmpipe as a GPU.

**Not covered.** Windows' WARP ("Microsoft Basic Render Driver") is not in the name test and is still accepted.

**Tested.** Unit tests of the decision and of the name test over real adapter names. On lavapipe (Mesa 26.0.8): main runs on llvmpipe under `auto` and `cubecl`; this branch exits 1 with the reason, including with a stand-in libcuda that fails with `CUDA_ERROR_OUT_OF_MEMORY`. The warning for a hardware device after a CUDA failure was not run on a device.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
