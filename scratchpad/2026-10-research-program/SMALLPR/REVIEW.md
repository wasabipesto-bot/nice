# Independent review: two small PR branches (2026-11-25, ivory)

Reviewed cold against upstream main `fdbe07d3`. Nothing changed on either branch; nothing pushed, opened or
commented. No subagents, no production API, no local builds (CI results were sufficient; see "What I ran").

---

## 1. `pr/gpu-software-renderer-error` (5781393a)

**Verdict: open with fixes** (one must-fix, cheap; two shoulds).

### Reach (confirmed by reading `client/src/main.rs` on the branch)

- **AMD on RADV / Apple M4, no CUDA:** unchanged. `cuda_failure` is set (main.rs:695-697) only under
  `cuda_toolkit_missing || cuda_driver_rejected`, the same predicate `log_cuda_fallthrough` (main.rs:400-416)
  already uses to decide warn vs info. A no-libcuda failure ("Unable to dynamically load the "cuda" shared
  library ...", seen verbatim in `logs/run_client_pr1_auto.log`) matches neither, so `cuda_failure` stays
  `None`; `judge_wgpu_adapter(_, false, None)` returns `Ok(None)` (main.rs:427-445): same device, same info
  line, no new message. Wherever the new warning can fire, main already warned once.
- **Fleet NVIDIA with working CUDA:** CubeCL CUDA succeeds and returns before the wgpu arm; named `cuda`
  never reaches it. Unchanged.
- **New refusals:** only `ctx.is_software_rasterizer()` true, i.e. a wgpu context whose name contains
  llvmpipe/lavapipe/swiftshader/softwarerasterizer (common/src/cubecl_backend.rs:2084-2086, 2907-2912,
  pre-existing name test used by kernel choices). CUDA/HIP contexts can never be refused (`matches!(Wgpu)`).
- **Name test false positives:** none plausible: RADV/AMDVLK names, "Apple M4", NVIDIA, Intel names do not
  contain those substrings (RADV's "LLVM" is not "llvmpipe"). The `(Vulkan, wgpu<…>)` suffix `device_name()`
  appends (cubecl_backend.rs:1873-1878) contains none either. Windows WARP ("Microsoft Basic Render Driver")
  is not caught; note the browser's own test `web/search/parity.js:272` also matches "software" and
  "basic render", so "one definition of software in the code" holds for Rust only.
- **Pinned `--gpu-wgpu-device`:** a pinned hardware adapter is unaffected; a pinned `Cpu` (llvmpipe) is now
  always an error.
- **Nothing in the repo runs the client on a software renderer on purpose:** confirmed. `.github/workflows/*`
  never runs `nice_client --gpu`; lavapipe jobs run `nice_common` tests only, which call
  `CubeclContext::new_default` (unchanged). `client/gpu.Dockerfile` installs no Mesa/libvulkan. Justfile
  `--gpu` recipes are for a developer's own GPU. Fleet: `fleet/controller.py:60-68` chains benchmarks with
  `;`, so a refused GPU benchmark no longer uploads an llvmpipe "GPU" datapoint, and the `exec … --gpu
  --repeat` exits, which the controller already treats as a broken box (comment at controller.py:189-190).

### Findings

**Must fix before opening**

1. **The refusal under `auto` is not logged at warning level** (main.rs:821-824). The maintainer's one
   condition was "everything is properly logged at warning or error level". Under `auto` the refusal reason
   goes to `debug!`, and the visible line is `info!("CubeCL unavailable; trying the next backend")`, which
   also misdescribes a refusal as unavailability. When the chain ends in the final error (the common case),
   the reason does reach ERROR (`logs/fake_client_pr1_auto.log`). When hand-CUDA then succeeds, it stays at
   debug only. Fix is a few lines: in the `auto` `Err` arm, `warn!` when the wgpu attempt was refused as a
   software renderer, keep info/debug for "no adapter". The author flagged this themselves (NOTES "look
   hardest" 3); given the maintainer's wording I would not ship it at debug.

**Should**

2. **Help text still advertises `Cpu`** (main.rs:322-324 doc comment of `gpu_wgpu_device`; mirrored in the
   README's help block, README.md:189). That spelling now always errors. Drop `Cpu` from the example list
   (and the README copy), or say it is refused. The description should mention this behaviour change of an
   existing setting value (see corrections).
3. **No test covers the name test or the new method.** The unit test
   `a_software_renderer_is_refused_and_a_gpu_after_cuda_warns` (main.rs:2017-2041) passes `software` as a
   bool, so it checks only `judge_wgpu_adapter`'s branching and message text; `is_software_rasterizer(&str)`
   has no unit test anywhere (`grep` of common/ finds no call with a literal), and the wiring is exercised
   only by the author's manual lavapipe run. A host test over a few real names (llvmpipe and SwiftShader
   true; the RADV, Apple M4, NVIDIA names false) would pin the false-positive question for future edits.

**Note**

4. Wiring of the hardware-after-CUDA warning is correct by reading: set in the CubeCL CUDA `Err` arm under
   `auto` only (main.rs:693-698), read in the wgpu arm (main.rs:795-801), printed after the "GPU
   initialized" info (main.rs:812-814). It never fires under named `cubecl` (CubeCL CUDA arm not run). It is
   a second warning after `log_cuda_fallthrough`'s, repeating the same error text; acceptable.
5. A refused wgpu attempt has already initialised the process-wide `WGPU_DEFAULT` lavapipe client
   (cubecl_backend.rs:1862); it is left alive while hand-CUDA runs. Harmless.
6. Both branches add a changelog line at the same place (CHANGELOG.md:5): whichever merges second conflicts
   trivially.
7. Commit message carries only the `Co-Authored-By` trailer, as upstream's merged commits do (e.g. 7e640149).
   No forbidden references in the diff, commit message or BODY-1.

### What I ran or read

- Read the full diff and `init_gpu` / classifiers / `guarded_init` context on the branch; `is_software_rasterizer`,
  `new_default`, `device_name` in common; workflows, justfile, `client/gpu.Dockerfile`, `fleet/controller.py`.
- Read the author's run logs: `logs/run_client_{main,pr1}_{auto,cubecl}.log`, `logs/fake_client_{main,pr1}_auto.log`
  (they match the table in NOTES).
- Fork CI on 5781393a: run 45544909480 all jobs success incl. "Format and clippy" (= `just lint`,
  rust-build-test.yml:37), "Test workspace", "Test GPU host code"; run 45545836683 (GPU Device Parity) success.
- No local build: no reason to doubt CI.

### Corrections to BODY-1

- "`--gpu-backend cubecl` on a machine with no GPU driver did the same, silently": `auto` did the same too
  (`logs/run_client_main_auto.log`), and it was not silent, it logged "GPU initialized: CubeCL wgpu device
  (llvmpipe …)" at info. Say "with only an info line".
- "Under `auto` it counts as a failed backend": after fix 1, add that the reason is logged at warning.
- Add: `--gpu-wgpu-device Cpu` now errors like any software renderer; Windows WARP is not detected.
- "a warning naming both": say it is in addition to the existing CUDA warning, and names the device and the
  CUDA error.
- Optionally for fleet operators: a box whose CUDA fails and that has only Mesa now exits instead of
  benchmarking llvmpipe as a GPU.

---

## 2. `pr/ci-spirv-atomic-stores` (68194bf1)

**Verdict: open with fixes** (two small shoulds, nothing blocking; could open as is).

### The check

- **Fails on the bad pattern for the right reason, passes on main's kernels:** CI run 45545815302, step
  "Compare the kernels' atomic operations, SPIR-V against WGSL": `AtomicStoreTrapKernel: lost in SPIR-V:
  store 2 in WGSL, 1 in SPIR-V`; 15 WGSL / 15 SPIR-V variants, 15 paired, 11 kernels; exit 0 with the
  expectation. CI's lavapipe is Mesa 26.0.8-1ubuntu0.3 (log), as the body says. Step took ~12 s (reused binary).
  Locally I re-ran the script on the author's dumps: exit 0 with `--expect-dropped`, exit 1 without it;
  and on the #263-first-version dumps (`T26B/raw/ci/dump/wgsl_hw.log` vs `spv_hs.log`): 16 `NiceonlyKernel`
  variants flagged, store 5 vs 2, exit 1. Confirmed.
- **Job or step:** a step (plus an on-failure upload step) in the existing `lavapipe` job of
  `gpu-parity.yml` (lines 107-134). No new job, flag or dependency.
- **Readable cold:** the script header (lines 2-39) explains the trap, what is counted, `--require`,
  `--expect-dropped`, exit codes and limits. Good.
- **Vacuous passes:** empty or missing-kernel dumps pass only if no `--require`/`--expect-dropped` is given
  (I ran two empty files: exit 0). CI passes ten `--require` and the expectation, so empty logs, an unpaired
  or renamed required kernel, or a compiler that stops dropping all fail with exit 2. Swapped dumps: exit 2
  (fence check). A new kernel not added to the dump test is not seen (stated in the header). The `pf_count`
  strip regex also handles the last-field case (Rust's pretty Debug keeps the trailing comma).
- **Trap kernel scope:** inside `#[cfg(test)] mod tests` (cubecl_backend.rs:3530-4650); launched only by
  `wgsl_dump_for_lint`, which returns early without `CUBECL_DEBUG_LOG`. It also runs in the Metal job's
  `cubecl_` filter (passes) and is seen by `wgsl-lint.py` (CI: 0 flagged). Nothing outside tests.

### Findings

**Should**

1. **Unreadable input exits 1, not 2** (`scripts/spirv-atomic-check.py:77`, `open()` unguarded). Ran with a
   missing file: `FileNotFoundError` traceback, exit 1, which the header (line 34) assigns to "a kernel lost
   an atomic operation"; NOTES says "exit 2 for … unreadable dumps", which is not true. Catch `OSError` and
   `fail()`. In CI it only bites if an earlier step already failed, hence should, not must.
2. **Body should say what a CubeCL upgrade will do:** if a bump fixes the merge pass, this step fails
   ("REQUIREMENT FAILED: AtomicStoreTrapKernel: expected to lose …", exit 2) until the trap kernel and
   expectation are removed. That is deliberate, but the maintainer will meet it on a dependency bump and
   should know from the description.

**Note**

3. A dangling `--require`/`--expect-dropped` with no value raises `StopIteration` (exit 1)
   (script lines 112-115). Cosmetic.
4. Counting per kernel can miss a drop masked by an extra op of the same kind (stated in header). Only
   "fewer in SPIR-V" fails; more passes. Both reasonable.
5. Changelog line (CHANGELOG.md:5) is one sentence but its "it" is ambiguous ("…that its WGSL compiler
   keeps, since it drops…"). Suggest: "Check in CI that the kernels' SPIR-V keeps every atomic operation
   their WGSL has, since CubeCL's SPIR-V compiler can drop a repeated atomic store ([#NNN](…))."
6. Commit message, comments and BODY-2: no forbidden references ("#263" is a public PR; "notes" in the
   script means its own header).

### What I ran or read

- Read the full diff, the script, the workflow job before and after.
- `gh run view` of 45545815302 (GPU Device Parity, success; read the new step's output) and 45545819469
  (Build/Test: "Format and clippy" = `just lint` success, every job success except "Build Linux-arm-musl",
  still in progress at 05:48 UTC in "Run tests"; the same job took 65 min on branch 1, and this branch
  changes only test code and CI, so not a concern, but check it finished green before opening).
- Ran the script locally (`python3 -I`) on the author's dumps, the #263 dumps, swapped, missing and empty
  inputs (results above).

### Corrections to BODY-2

- Add the upgrade behaviour (finding 2).
- "CI caught it only in some runs" about #263: not verified by me; fine if it matches #263's public thread.
- Otherwise accurate: `-gpu` image is built with `cubecl-spirv` (docker-build-push.yml:131); "No new job,
  flag or dependency" holds (one new step and an upload-on-failure step); "Nothing changes at run time" holds.
