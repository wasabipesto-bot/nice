**Why.** CubeCL 0.10's direct SPIR-V compiler (`cubecl-spirv`, which the `-gpu` image uses on Vulkan) merges equal instructions within a basic block, and it compares an atomic store without its target. So a second atomic store of the same value in one block is removed, whatever it points at. WGSL, CUDA and Metal keep it, so no parity test on them shows the loss; #263's first version lost its queue account this way.

**What.** The lavapipe job already dumps the kernels' WGSL for the Apple division lint. It now runs the same dump under `cubecl-spirv`, and `scripts/spirv-atomic-check.py` pairs each kernel variant across the two dumps and fails if one has fewer atomic stores or read-modify-write operations in SPIR-V than in WGSL. The dump also compiles a small test kernel with two atomic stores of one value in a block, which the check must flag, so a check that goes blind fails too. No new job, flag or dependency: one step in the existing job (about 12 s) and an upload of the SPIR-V dump when it fails.

**On a CubeCL upgrade.** If a later CubeCL stops merging these stores, this step fails with "expected to lose an atomic operation" until the test kernel and its `--expect-dropped` are removed. That is deliberate: it is the signal that the trap is gone.

**Tested** on lavapipe from Mesa 26.0.8, CI's version: the 10 production kernels in the dump pass, the test kernel is flagged (2 stores in WGSL, 1 in SPIR-V), and without its expectation the check fails. On dumps of #263's first version it flags `NiceonlyKernel` (5 stores against 2). An unreadable or mismatched dump exits 2, a lost operation exits 1.

**Devices.** Nothing changes at run time. Only Vulkan through `cubecl-spirv` has the trap; WGSL, Metal and CUDA do not run that optimizer.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
