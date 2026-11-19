VERDICT: MERGE WITH FIXES. The code is sound and I found no code defect. Two must-fixes come before the pull request opens. M1: run the plane-scoped path with the new count on one real Vulkan GPU, or have the description say it has not been run there. M2: the description should say that this PR's macOS CI runs it on Metal. Two small should-fixes follow.

# SRA review: `pr/stride-ran-account` at 3940f8a9 (independent reviewer, 2026-11-19 01:27–02:25 UTC)

Scope: `common/src/cubecl_backend.rs` (+170/−5) and `CHANGELOG.md` (+4), two commits on upstream main 71eb5fcd.
Line numbers are from the branch's `common/src/cubecl_backend.rs`. My box work is in `/root/rev/` on Vast
61303619: clones `a` (branch as is), `b` (mutants) and `c` (plane-path probes) at 3940f8a9, each with its own
target directory (`ta`, `tb`, `tc`). Logs are in `/root/rev/logs/{a,b,c}`, copied to `SRA/raw/review/`. The
branch and the author's trees were not touched.

## Must fix before the pull request

**M1. The description says a healthy wgpu device sees nothing new. For the path wgpu GPUs actually run, nobody
has checked that.** (PR-BODY "What a wgpu device should expect"; kernel `cube_ran` at :1575/:1578–1587)
- On real Vulkan GPUs with the SPIR-V compiler, and on Metal, production runs the plane-scoped queue path. With
  the new count, that path has run in two places only. On CUDA it passes (my `cuda_stride` run, and
  `rev_multicube_cuda` with 18 cubes, plane=true). On llvmpipe it **fails the count**: "finished 0 of 2 cubes"
  and "1 of 5 cubes" (`raw/review/c/v1.log`, forced with `plane_override = Some(true)`, ballot and scan forms).
- The llvmpipe failure is llvmpipe's known plane-path bug, not this change:
  - Main's kernel on the same forced path (no count, no host check: `c/v3.log`) returns `Ok` with **72 of
    30449** and **30116 of 30449** survivors. The queue account reads `[.., 0, 0]` and does not notice. So
    llvmpipe already loses work on this path, and production keeps the path off on software rasterizers
    (`is_software_rasterizer`).
  - Removing the new `sync_cube` changes nothing (`c/v2.log`: same deficit). The barrier is not the cause.
  - `spirv-val --target-env vulkan1.3 --scalar-block-layout` accepts all four plane-scoped modules (ballot and
    scan, cubes of 256 and 100), so neither SPIR-V trap applies:
    - The module keeps its `OpAtomicIAdd`s; the count is an add, not a store.
    - The count adds no loop or break.
  - The new barrier stands right after `report_queue_account`'s existing cube barrier, in the same control
    flow, and that barrier already runs in production on Vulkan GPUs.
- So the risk is low. But if it were wrong, every stride field on every AMD/Intel Vulkan client would error and
  the client would exit 1. The failure would be loud (nothing false is submitted), but it would hit the whole
  fleet. The text "Nothing new on a healthy device" is therefore asserted, not measured.
- Fix, either way:
  - **(a), preferred, minutes of work.** On a real Vulkan GPU, run
    `cargo test --release --features cubecl-spirv -p nice_common -- --ignored --nocapture cubecl_dropped_launches_fail_the_field cubecl_queues_check_every_survivor_on_partly_filled_planes`.
    There `plane_queue_runs` is true, so the plane-scoped path is covered, including partly filled planes.
    Then say so in the description.
  - **(b)** Say in the description that the plane-scoped path with the count was run on CUDA only.
- I could not do (a). The box's NVIDIA Vulkan ICD does not initialise in this container (`vkCreateInstance:
  Found no drivers` even after installing `libxext6`), and I may use no other machine.

**M2. The description says Metal "was not run on an Apple device". That is true today, but the pull request's
own CI will run it, and the description should say so.**
- `.github/workflows/gpu-parity.yml` has a macOS job, `metal`. It runs `cargo test --release --features cubecl
  -p nice_common -- --ignored` (wgpu to Metal) and `--features cubecl-metal ... cubecl_` (direct MSL) on the
  runner's paravirtual Apple GPU.
- That job runs `cubecl_dropped_launches_fail_the_field` and every stride device test through the new count. If
  the runner reports `Plane::Sync`, it covers the plane-scoped path too.
- Reword to: "Metal: not run on Apple hardware by the author; this PR's macOS CI job runs the new test and every
  stride device test through the count (wgpu to Metal and the direct MSL compiler); the MSL itself was not
  inspected."
- Reading the kernel, I found nothing Metal should object to: a `threadgroup_barrier` reached in uniform control
  flow after the paths' loops, and one relaxed device atomic add by thread 0, which `report_queue_account`
  already does. But I did not compile or run any MSL, so **Metal is unverified by me.**

## Should fix

**S1. The new regression test launches one cube at a time, so it cannot tell a per-cube count from a
per-launch count.** (`dropped_launches`, :4480–4524)
- Each launch is one range, `threads = 1 << lane_shift` ≤ 32, so it is one cube ("finished 1 of 2 cubes").
- Mutant B (`b/m2.diff`) counts once per launch (`ABSOLUTE_POS_X == 0` in place of `UNIT_POS_X == 0`). The new
  test still **passes** on CUDA and on lavapipe WGSL (`b/m2_cuda.log`, `b/m2_lvp_wgsl.log`).
- The suite does catch the mutant, through `cubecl_matches_cpu_niceonly` and `cubecl_cuda_matches_cpu_niceonly`
  ("stride walk b25: … finished 1 of 3 cubes"), so nothing is unguarded today.
- The smallest fix: in `dropped_launches`, set `run.lane_shift_override = Some(0)` and cut the window into
  ranges of ~100, half of them per launch. That gives 9 + 9 cubes. I ran exactly this as `rev_multicube_*`
  (`b/probe.rs`):
  - Clean, it is exact on CUDA (3 paths), lavapipe WGSL and lavapipe SPIR-V (plain and cube-scoped):
    "30449 of 30449 survivors, 18 cubes".
  - Under mutant B it fails: "finished 2 of 18 cubes".

**S2. The description says "the same results and launch counts per field". The raw timings do not support
that.**
- `raw/box/logs/timings.txt`, b64 field 1: this branch launched 119/116/279, v3.4.8 launched 117/118/117.
- Results are identical (all `[]`). Launch counts vary run to run in both binaries (the floor controller), as
  RESULTS §6 itself says.
- Reword to: "the same results, launch counts within the same run-to-run spread".

## Notes (no change needed)

- **N1. Wrap argument.**
  - `ran_complete` compares mod 2^32 (:3266). A loss slips through only if the deficit is a multiple of 2^32
    cubes. A b64 1e13 field launches ~2.8e5 cubes in all, so this cannot happen.
  - The doc comment and the description justify it per launch ("one launch is at most 4096 cubes, so a dropped
    launch cannot wrap it"). The real bound is the field's total. Optional rewording: "a field launches far
    fewer than 2^32 cubes".
- **N2. A field with no launches.** It is accepted with `cubes = 0`, as before (:3160, :3472). A real launch with
  no ranges still launches one cube (`clamp(1, …)`, :3465) and counts it, so host and kernel agree on every
  path, including a partial last launch.
- **N3. Every consumer passes the check.**
  - There is one stride kernel and one reader, `read_niceonly_hits` (:3198). Its callers are
    `CubeclPendingField::wait` (the pipeline, :3372) and `CubeclNiceonlyRun::finish` (tests, :3166).
  - Benchmarks and NiceMark go through the pipeline. The browser runner (`cubecl_web.rs`) has no nice-only
    kernel.
  - Fields in flight each have their own `CubeclNiceonlyRun` and count buffer (`begin_field`, :2821), and the
    count accumulates in `launch` (:3472) before the launch, so a launch that is never run is counted as owed.
- **N4. Count buffer, 3 to 4 words.**
  - It has one creator (`from_plan`, :3127, zero-initialised per field) and one binding (:3489). Both use
    `NICEONLY_COUNT_WORDS`.
  - Kernel writers: `[0]` in `candidate_check` (:833), `[1]` and `[2]` in `report_queue_account`, `[3]` in
    `cube_ran`.
  - Host readers: `ran_complete` uses `.get(3)`, `queue_complete` uses `.get(1)` and `.get(2)`, and the hit
    count uses `[0]`.
  - Nothing else shares it. The hand-CUDA backend's `d_nice_count` is a separate one-word buffer.
- **N5. Barrier legality.**
  - `cube_ran` follows a comptime branch. Every unit leaves the plain path's `while`, and both queue loops exit
    uniformly at cube scope.
  - The plain path had no cube barrier before. naga accepts it (the WGSL tests run that path), the SPIR-V
    modules validate, and CUDA is fine.
  - No early `return` or `terminate!` exists in the kernel.
  - Unit 0 exists in every cube, including the partly-filled-plane tests' cubes of 100, 48 and 36 units, which
    pass on CUDA and lavapipe.
- **N6. Detailed mode is covered.**
  - `detailed_impl` (:2440–2451) and the browser runner (`cubecl_web.rs:1007`) require the histogram total to
    equal `range.size()`. Every candidate of every launch bins exactly once, into a fresh zeroed buffer per
    drain.
  - A dropped launch therefore falls short. A dropped zeroing of a reused buffer would over-count, and the `==`
    catches that too.
  - Not measured under the memory hog, by the author or by me.
- **N7. Bonus.** On llvmpipe's broken plane path (N/A in production), the new count catches lost work that the
  queue account missed (main: `Ok` with 72 of 30449; branch: an error). That is independent evidence the count
  works.
- **N8. One discrete change.**
  - The second commit is test-only plus `cargo fmt` of the new test (two hunks in `mod tests`).
  - No new flag or environment variable. `skip_launches` is a `#[cfg(test)]` field, and its accessor returns a
    constant `false` under `cfg(not(test))`, the same pattern as `test_bits`.
  - The first commit alone fails `just lint`. The maintainer squashes, so this does not matter.
- **N9. Timings.**
  - The author's timings measured the plane-scoped path on CUDA. The plain path, which gained its first cube
    barrier, is not timed on any device.
  - I expect no effect: the barrier comes at kernel end, where a cube's early units idle until the cube retires
    anyway.
- **N10. Pre-existing, outside scope.** A count buffer whose zero upload was dropped could in principle reread a
  previous field's words from a pooled slot. In the measured failure, only launches that bind the dead handle
  are dropped, so this cannot happen there.

## What I ran myself (box, toolchain 1.100.0, branch at 3940f8a9, my target dirs)

Hosts block proved before anything ran:
- `/etc/hosts` maps api., data., www. and the bare `nicenumbers.net` to 127.0.0.1 and ::1.
- `getent` resolves them to 127.0.0.1.
- `curl https://<each>/` fails to connect.

No client binary was run, and nothing claimed or submitted.

| check | result |
|---|---|
| `just lint` | pass |
| `cargo clippy -p nice_common --all-targets --features cubecl-cuda,cubecl-spirv -- -D warnings` | pass |
| `cargo test --locked --release --no-fail-fast` (CI form) | pass, 231 |
| `cargo test --release -p "*" --no-fail-fast` | pass, 278 (incl. `ran_complete_wants_every_launched_cube`) |
| `NICE_REQUIRE_NVRTC=1 cargo test --locked --release -p nice_common --features gpu --lib` | pass, 261 |
| `cargo check -p nice_common --all-targets --features cubecl-metal` | pass (Rust only) |
| CUDA, `cubecl_backend::tests::cubecl_cuda_` (serial) | pass, 7 (stride + detailed; the new test on all 3 paths: clean 30449/30449, "0 of 2", "1 of 2") |
| lavapipe WGSL, CI's command (`--ignored`, all) | pass, 41 |
| WGSL Apple-division lint, CI's `--require` list | pass, 14 shaders, 0 flagged |
| lavapipe SPIR-V, CI's command (`--ignored cubecl_`) | pass, 32 (the new test on the plain and cube-scoped paths: clean 30449/30449, "0 of 2", "1 of 2") |
| **mutant A**: `ran_complete(...)?` deleted | new test **fails** on CUDA, lavapipe WGSL and lavapipe SPIR-V: "compact=false plane=false skip_from=Some(0): a dropped launch must fail the field" |
| **mutant B**: per-launch count | the new test passes (S1); suite parity tests fail |
| multi-cube probe `rev_multicube_*` (18 cubes, 2 launches) | exact on CUDA (3 paths), lavapipe WGSL, lavapipe SPIR-V |
| forced plane path on lavapipe SPIR-V, branch / no barrier / main | count fails / count fails / main accepts 72 and 30116 of 30449 (see M1 and N7) |
| `spirv-val` of the plane-scoped `NiceonlyKernel` modules | 4 of 4 valid |

Not run by me: the overlap join's CUDA device tests (untouched by the change), the hog reproductions (the
author's raw logs are consistent, below), and any real Vulkan, Metal or HIP device.

## The description against its rules and the raw logs

- **Rules.** No research program, scratchpad path, agent, assistant or model name. No private host names (grep
  for those and the box names: clean). It ends with the Claude Code line. Follow-ups are one line each, marked
  "Not included". The CHANGELOG line is one sentence with a `(#NNN)` placeholder.
- **Spot checks against `SRA/raw/box/`, all match:**
  - b62/290: `Task failed` ×45, `dev_wait_s 0.0786`, fix "finished 0 of 200319 cubes", rc=1, 0 submissions.
  - b64/400: ×71, 0.132 s, "0 of 277280". b64/520: ×92, "0 of 282373".
  - Timings: medians 2.051/2.137 and 7.799/7.765; device waits 0.709/0.696 and 2.600/2.597.
  - "About 5,900 base-10 fields": 2976 + 2891 submissions of `[69]` in the two healthy runs.
- **Corrections:**
  1. M1: the wgpu section's healthy-device claim.
  2. M2: Metal will run in this PR's CI.
  3. S2: launch counts.
  4. N1: the wrap justification (optional).
  5. Wording: "Reads of the buffers that did allocate succeed and return what the dropped kernels would have
     changed: zeros" means "succeed and return them unchanged: zeros".
