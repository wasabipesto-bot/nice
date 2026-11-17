# G2 port brief: the benchmark kernel in CubeCL, exact on lavapipe, priced for RDNA4 (2026-11-17)

Your benchmark (`G2/BENCH.md`) measured the redesigned join at ×5.13 against same-session main at
base 64 on an RTX 3080. A proposal document written since (`G2/PROPOSAL.md`: read its first
page and §1) found that base 64's range is exactly [2^75, 2^76), so a bit renumbering makes
transversal units fit the existing fields table: the server change shrinks to a claim gate.
The decision now hangs on one unknown: **the AMD RX 9070 XT**, which carries about 86 % of the
search and runs CubeCL kernels through wgpu's SPIR-V path (RADV, 64-lane planes). The
maintainer has not yet said whether to pursue this; I am preparing, at prototype level and
without their card, everything that an hour on that card would need.

## Task

1. **Port kernel v10 and its preparation to CubeCL** (`#[cube]` Rust, generic over the
   runtime, the way `common/src/cubecl_join.rs` is written: read its module docs and how it
   uses shared memory, plane operations (`plane_ballot`, `plane_shuffle`, the scan forms for
   64-lane planes), atomics and `comptime`). Throwaway code in a scratch worktree
   `~/projects/nice/.worktrees/g2-cubecl` on a local branch (never pushed), as a test-only module
   or example of `nice_common` so it builds with the workspace's CubeCL version and features.
   Keep the algorithm and its counts identical to v10. Respect what bit the project recently:
   CubeCL's SPIR-V compiler keeps only the first of several atomic stores of one value in a
   basic block (`T26B/REVIEW2.md`); Vulkan does not promise full subgroups and lane 0 may be
   absent (`T26/RESULTS.md`), although a benchmark may assume full planes if it checks its
   counts; plane width is 64 on the target and 8 on lavapipe, 32 on CUDA.
2. **Exactness on lavapipe from CI's Mesa** without any rented machine: the container image
   `localhost/lvp26:latest` on ivory (Ubuntu 26.04, Mesa 26.0.8, `VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json`;
   run with `podman run --rm --cgroups=disabled -v <dir>:<dir> localhost/lvp26 …`; binaries
   built on the host run inside it) with both compilers (`--features cubecl` for WGSL through
   naga, `--features cubecl-spirv` for the direct SPIR-V compiler, which is what the AMD card
   runs). lavapipe is slow: use a reduced input (a few classes and units of the staged
   super-unit, or a small synthetic unit) whose survivor sets you can check against the CPU
   reference; say exactly what was run. Dump the SPIR-V module and compare its atomic
   operations with the WGSL module's (`T26B/review2-box/` has the script).
3. **Price it for RDNA4 offline**, as `N22/RESULTS.md` did for the production kernels
   (`N22/raw/scripts`: RADV on the amdgpu no-op DRM shim with `AMDGPU_GPU_ID=gfx1201`, ACO's
   instruction dump; Mesa 26 in the same container if the shim package is available there,
   otherwise say what is missing): instructions per kept word and per child by kind, LDS bytes
   per work group and the waves per SIMD that follow (production's join sits at 18.9 KiB and 16
   waves; this kernel used 32 KB on CUDA), anything ACO does badly (64-bit emulation, the
   transpose by shuffles, ballots as uvec4). Then a **prediction for the card** from N17.1 /
   N21's calibration (seconds per instruction per field on that card), with its uncertainty
   stated honestly, and the LDS / occupancy variants worth trying there.
4. **A window plan of at most 45 minutes** (`G2/WINDOW-PLAN.md`): one binary with switches, the
   same-session main baseline at base 64 (which fields, how many), the runs, the clock and
   power checks that reject off-point runs (`N22/WINDOW-PLAN.md` and `N21/raw/scripts/window13/`
   are the templates; note cargo 1.100 changed where test binaries land), and the number
   below which the project stops (the proposal says ×4.0 same-session on that card). Dry-run
   the driver end to end on lavapipe.

## Rules

No rented machines and no GPU for this task: ivory only (4 cores; you may use two threads,
`nice -n 19`; **check `df -h /` before every build and keep 3 GB free**: build one profile only,
with its own `CARGO_TARGET_DIR` under the worktree, and delete artefacts you no longer need).
Nothing is pushed to any git remote; no pull requests; no subagents; nothing on the fleet, the
server, demoux or mayalaran; no contact with the production API. Keep a living
`G2/PORT-NOTES.md` (you may be resumed tomorrow; this is several days of work: say at the end
of today exactly where it stands). Hard stop for today **15:30 UTC**. Your final message is at
most 250 words for the program's director.
