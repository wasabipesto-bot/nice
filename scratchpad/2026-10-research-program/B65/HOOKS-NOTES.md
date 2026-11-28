# The split-fault hooks compiled out of production kernels; the wide expansion's lookups (2026-11-28)

Brief: `BRIEF-HOOKS.md`. Scripts: `scripts/hooks/` (on eventeo under `~/research/b65h/scripts/`, on the M4 under
`~/claude/scripts/`). Logs: `runs/hooks/` (`eventeo/`, `m4/`). Timing numbers are field t 77777 after the warm-up
field in the same process (b65: 13731, b64 narrow: 4095), sampled check off; "fs" = fs per admissible n.

## Branch

Fork **`dev/mo-hooks`** on `dev/mo-mode` `f503a13c`:

| commit | what |
|---|---|
| `6abf5743` | step 1: the split-plane fault emulation a comptime value `emul` of the kernels, off in production |
| `87620a18` | clippy: `GpuJoin` has four bools now (`#[allow(clippy::struct_excessive_bools)]`; no kernel change) |

Step 2 is **not** on the branch (below its kill line on Vulkan; patch kept as `scripts/hooks/step2-v1.patch`, on `87620a18`).

No pull request; nothing pushed to `origin` or `dev/mo-mode`; no force-push, no amend. Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` (the model that wrote them), not the brief's `Fable 5.2`.

CI on the head `87620a18`: "GPU Device Parity" run 46115059232 **success** (lavapipe incl. lint, Metal); "Rust
Cross-Platform Build, Test, and Release" run 46115061293 **success** (every job). The runs on `6abf5743` were
cancelled (its clippy failure is the reason for `87620a18`).

## Step 1: how the emulation is selected, and where it is on

- The kernels that carried the emulation take a comptime `emul: bool`: wide `wide_kernel` (`F_SLAB_SPLIT`),
  `wanc_kernel` (`F_ANC_SPLIT`), `wtops5_kernel` (`F_T5_SPLIT`), `wexpand_kernel` (`F_EXP_SPLIT`); narrow
  `g2_kernel` (`F_SLAB_SPLIT`), `anc8_kernel` (`F_ANC_SPLIT`), `expand_kernel` (`F_EXP_SPLIT`). Each emulation sits
  in an `if comptime!(emul) { … }` block, so CubeCL emits nothing for it when `emul` is false; the code outside the
  blocks is the pre-hooks code (the records written as before, the ballot/scan over the lane's own value).
  `F_DROP_PARENT`'s emulation is older (it existed before 11-27 and only its count is new) and is unchanged, as are
  all the other fault bits (runtime, as before) and `F_ANC_DROP` (runtime; `wanc` is not a hot kernel).
- The joins (`WideJoin`, `GpuJoin`) hold `emul`, **false from the constructor**; the only setter is
  `set_split_emulation` (crate-private, "tests only"). Nothing in `route.rs`, the benches or the client calls it, so
  every production path (route's joins, `midout_bench`/`midout_wide_bench`, `nice_client midout`) runs the
  production kernels. `SPLIT_FAULTS` names the bits; `set_fault` **panics** on a split bit without the emulation
  build, so a test cannot inject a split fault that is silently not emulated.
- Where it is on: the split faults in `wide_faults_are_loud`, `wide_field_parent_sharing_is_exact_and_loud`,
  `accounts_faults_are_loud`/`cubecl_midout_faults_are_loud` (via `faults_are_loud`), `field_parent_sharing_is_exact_and_loud`
  and `audit_faults` (any `AUDIT_FAULTS` with a split bit); the agreement checks below; the WGSL dumps.

**What the fault tests prove now** (said in the code too, on `emul` and on the fault tests): the split faults show
that the host's checks fire on the kernels *built with the emulation*. The production kernels are the same source
with those blocks compiled out; the tests do not run a split fault on them (they cannot: there is nothing to
inject). Every other fault runs on the production build, as before.

**Evidence that the two builds are otherwise the same:**
1. Asserted in the tests: without a fault, the emulation build gives the production build's counts on the
   faults' slices (`WCounts` equal; narrow: every count but the order-dependent maxima), its accounts pass, and
   every clean rerun after a split fault (emulation build) equals the production baseline; the sharing tests
   compare the emulation build slice by slice with production's over the whole 130 (wide) / 128 (narrow) slices;
   and the sampled slice of the emulation build equals the CPU's n for n, as production's does. (Accounts are
   compared through these counts and their checks, not word by word.)
2. Kernel text (M4 dump, WGSL, `scripts/hooks/wgsldiff.py`, output `runs/hooks/m4/hk1-6abf-dump/wgsl_emul_diff.txt`):
   for all seven kernels, production's WGSL with SSA names abstracted and declarations dropped is the emulation
   build's with lines **removed 0, added only the emulation blocks** (wexpand/expand: 16 lines, the fault test and
   the zeroing of the lane's bits; wide/g2: 2 × 8, the zeroing of the record's words; wanc/wtops5/anc8: 7, the
   ballot flag). The abstraction hides which variable a line uses, so this shows structure, not data flow; (1)
   covers the data.

**The WGSL lint** (`wgsl_dump_for_lint` in both files, `--require` lists in `gpu-parity.yml`): the dumps compile
production's kernels at the device width and at 32 and 64, and the emulation build at the device width only.
The `--require` lists now name production's variants explicitly (`G2Kernel:w=32:emul=false`, …,
`WexpandKernel@65:emul=false`, `ExpandKernel:oh64=…:emul=false`, `Anc8Kernel:w=…:emul=false`) **and** the
emulation variants (`…:emul=true`, any width). So both are linted; the emulation variants only at the device's
width (W 32 on the M4, lavapipe's in CI).

## Step 1: timing (RTX 3060, one session, alternating; `runs/hooks/eventeo/hooks-ab/`, `scripts/hooks/ab_hk.sh`)

Three builds in each round: `fx-base` = `73bc0065` (before the counts and hooks), `fx-fin` = `f503a13c` (counts +
hooks; yesterday's binaries), `hk1` = `6abf5743` (counts, hooks compiled out). Round 1 in that order, round 2
reversed. Card beside every run: 97–100 % busy, 156–164 W, 1779–1798 MHz, except the very first run (CUDA b65
`fx-base` round 1, 1851 MHz: the card started cool), which is shown but left out of the means.

| runtime, path | before the hooks (`73bc0065`) | with hooks (`f503a13c`) | hooks compiled out (`6abf5743`) | out vs before | out vs with |
|---|---|---|---|---|---|
| CUDA b65 wide (fs) | (5.9230 hot), 6.0135 | 6.1069, 6.1125 | 6.0190, 6.0214 | **+0.1 %** (−0.1 % vs yesterday's 6.022 / 6.033) | −1.5 % |
| CUDA b64 narrow (fs) | 3.2771, 3.2794 | 3.3411, 3.3325 | 3.3034, 3.2806 | +0.4 % (round 2: +0.04 %) | −1.3 % |
| Vulkan/SPIR-V b65 wide (fs) | 5.7653, 5.7563 | 5.8196, 5.8171 | 5.7588, 5.7587 | **−0.04 %** | −1.0 % |
| Vulkan/SPIR-V b64 narrow (fs) | 3.2338, 3.2526 | 3.2741, 3.2661 | 3.2633, 3.2485 | +0.4 % (round 2: −0.1 %) | −0.4 % |

Base 64 narrow was rechecked in the step-2 session (`runs/hooks/eventeo/hooks-s2/`, `cuda64n_*_3/4`,
`vk64n_*_3/4`, two more alternating rounds, plus the step-2 session's `hk1` control): **CUDA** before 3.2795,
3.2829 / out 3.2832, 3.2999, 3.3025; **Vulkan** before 3.2647, 3.2713 / out 3.2811, 3.2751, 3.2557. Over all runs:
CUDA before 3.2797 (4 runs), out 3.2939 (5 runs): **+0.4 %**; Vulkan before 3.2556, out 3.2647: **+0.3 %**. So at
base 64 narrow the compiled-out build sits 0.3–0.4 % above the pre-hooks head: about what yesterday attributed to
the per-lane counts themselves (fx-noemul +0.15 %, one run), with ±0.3 % run-to-run spread here. **The done line
(within 0.3 %) is met at base 65 on both runtimes; at base 64 narrow it is met on Vulkan and missed by about
0.1 % on CUDA.** That remainder is the counts (mandated), not emulation code: the kernels' text has none (above).

**Counts:** every run above has identical survivors and checked: b65 77777 = 69,601,522,205 / 2,222,575,676, b64
77777 = 48,216,914,309 / 1,384,731,444, equal to `runs/fixes/` (and the M4's b65 field, below). Two Vulkan
processes ended with the known SPIR-V exit segfault (rc 139) after printing their totals.

## Step 1: tests (head `6abf5743`; `87620a18` adds only a clippy attribute)

| test | RTX 3060 CUDA | RTX 3060 Vulkan (direct SPIR-V) | M4 Metal (wgpu/WGSL) | CI on `87620a18` |
|---|---|---|---|---|
| card tier `cubecl_midout*` (8, incl. both fault tiers, which now run the split faults on the emulation build) | ok | ok (1) | ok | lavapipe WGSL 50 ok, lavapipe SPIR-V 39 ok, macOS Metal 50 + MSL 39 ok |
| `wide_slices_equal_cpu`; with `MIDOUT_WIDE_SHARE=1`; `MIDOUT_FORCE_W=64` compile-only | ok, ok, ok | ok, ok, ok | ok, ok, — | — |
| `wide_faults_are_loud` (+ emulation-build agreement) | ok | ok | ok | — |
| `wide_field_parent_sharing_is_exact_and_loud` (+ slice-by-slice agreement) | ok | ok | ok | — |
| `wide_whole_small_bases_vs_brute_force` | ok on the GTX 1060 (1,046 s) | ok on the GTX 1060 (1,071 s) | — (step 2's head: ok) | — |
| narrow `gpu_slices_equal_cpu` (+ `MIDOUT_SHARE8=1`), `accounts_faults_are_loud`, `field_parent_sharing_is_exact_and_loud` | ok | ok | faults, sharing ok | — |
| b65 field 77777 with the sampled check (`midout_wide_bench`) | (timing runs above) | (timing runs above) | ok, equal counts, 313.08 s (yesterday's head 324.09 s) | — |
| WGSL dump + lint with the new `--require` lists | — | — | ok, 0 flagged | lavapipe step ok, 71 shaders (63 yesterday: + the emulation variants), 0 flagged |
| `just lint`; clippy `-p nice_common --all-targets`, `cubecl-cuda,cubecl-spirv,midout-box-tests,midout-bench,midout-fault` | ivory: ok on `87620a18` (2) | | | "Format and clippy" ok; whole cross-platform matrix ok |

(1) The tier's process ended with the known SPIR-V exit segfault (rc 139) after "8 passed".
(2) `6abf5743` failed clippy's `struct_excessive_bools` (GpuJoin's fourth bool); fixed by `87620a18`, which CI
then passed.

**Fault messages:** every fault line of the wide and narrow fault and sharing tests is byte-identical to
yesterday's (`runs/fixes/fixes-tests`, same runtime), except numbers that already varied between yesterday's own
runs: the split faults' lost counts (e.g. `F_EXP_SPLIT` wide "appended 454438" today, 454667 / 454393 / 454217 /
453814 in yesterday's four runs: which lanes lose their entries depends on scheduling), the narrow `F_SKIP_TOPS`
dump's word 3 (stale per-prefix flags of the previous slice, as noted yesterday), the narrow `slabs_max` (order of
atomics) and `F_ANC_DROP`'s sampled slice (random). New lines only for the agreement checks ("split emulation
build, no fault: …").

## Step 2: the wide expansion's lookups (measured; **killed on Vulkan, not pushed**)

What was built (patch `scripts/hooks/step2-v1.patch` on `87620a18`, `gpu_wide.rs` only; locally committed on
eventeo as `78e333e1`, never pushed):
- **(b)** `wtdigz` (already in slot order) writes a 16-byte context per top slot, `tctx[i] = [unit | h mod b << 8 |
  (h div b) mod b << 16 | small-n << 24, clip lo, clip hi, mqh]` (the old `wtop_ctx` logic moved there, with the
  slice-digit value and small-n test it needed); the expansion does one vector load per record instead of `thd`,
  `ttqh`, a division and modulo by the runtime `nlead`, the u64 prefix arithmetic and the clip compares. `ttqh` is
  gone (its word is in the context).
- **(a)** the prefilter's fixed super-digits: the slice-only ones once per thread, the two that hold the record's
  top (positions k − 1 .. k + 1) once per record (`pf_w2_fixed` per record instead of per bit); per bit only two
  selects. The h-digit split comes ready from the context (no `h % b`, `/ b` per bit).
- (c) not touched (the record layout and `wrec_top` as before).

**Exact:** every device test passed on step 2's build: CUDA and Vulkan on the RTX 3060 (tier, wide slices n for n,
shared, forced w 64, wide faults, wide sharing, narrow set; `runs/hooks/eventeo/hooks-tests-s2v1/`), the brute-force
test on the GTX 1060 through CUDA (1,024 s) and Vulkan (1,079 s), and on the M4 through Metal (tier, wide slices,
shared slices, faults, sharing, brute force 2,698 s, b65 field with the sampled check, WGSL dump + lint 0 flagged;
`runs/hooks/m4/s2v1/`). Counts of every timing run equal (b65 77777 69,601,522,205 / 2,222,575,676). Fault messages
as step 1's (same deterministic text).

**Timing** (one session, `hk1` = step 1's head against `s2v1`, three alternating rounds, order reversed each round;
`runs/hooks/eventeo/hooks-s2/`):

| runtime, b65 wide (fs) | step 1 (`hk1`) | step 2 (`s2v1`) | change |
|---|---|---|---|
| CUDA | (5.9820 at 1842 MHz, first run), 6.0242, 6.0748 | 5.9387, 5.8846, 5.9076 | **−2.3 %** (−1.9 % counting the first run) |
| Vulkan/SPIR-V | 5.7782, 5.7730, 5.7788 | 5.7683, 5.7565, 5.7598 | **−0.26 %** |
| Metal (M4, one field each, sampled check on) | 313.08 s | 313.23 s | 0 % |

Where (CUDA, cumulative timing stops at field 77777, one run each): up to the main kernel 75.86 → 76.38 s
(+0.12 ms/slice: the context writes in `wtdigz`); the expansion itself (stop 5 − stop 3) 18.59 → 16.28 s, **4.40 →
3.85 ms/slice (−12.5 %)**. Base 64 narrow (untouched path, control): CUDA 3.3025 / 3.2829, Vulkan 3.2557 / 3.2686.

**Verdict: below the kill line.** The brief's line is 1.5 % of a base-65 field through CUDA *and* through Vulkan.
CUDA gains about 2 %, Vulkan 0.26 % (and the M4's Metal nothing), so it was **not pushed**. Reading of the numbers
(not measured further): the SPIR-V/WGSL compilers already hoisted or cheapened what NVRTC recomputes per bit (the
runtime division and the per-bit super-digit products), so the change only helps CUDA, which runs about 13 % of the
search. If wanted for the CUDA fleet alone, the patch is exact and ready.

## Not done

- Step 2 not on the branch (kill line on Vulkan); (c), the record carrying its top index, not tried.
- Base 64 narrow is +0.3–0.4 % over the pre-hooks head after the compile-out (the per-lane counts' own cost and
  noise), so the 0.3 % line is missed by ~0.1 % on CUDA there; nothing more was tried.
- Accounts are compared between the two builds through the counts they yield and their checks, not word by word.
- The WGSL text comparison is structural (SSA names abstracted) and on the M4's WGSL only; CUDA C++ and SPIR-V of
  the two variants were not diffed.
- The emulation variants are linted only at the device's plane width (not at forced 32/64).
- No pull request (as briefed).

## Machines and energy

- eventeo: woken 05:52 (ssh up after 43 s); my work 05:53–09:34 (step 1 build/tests/timing, step 2
  build/tests/timing); wall energy **05:52–09:34: 0.82 kWh** (counter 2.75 → 3.57; mean 222 W, peak 323 W with
  both cards busy), about $0.15. Then, as the coordinator asked, the director's group sweep (`runs_group.sh` with
  `hk1-bench-spv` = `6abf5743`, the hooks compiled out; 09:34–10:05; counter 3.71 at 10:06; logs copied to
  `runs/group/`). `off_if_idle.sh` at 10:06 answered "eventeo stays up: keep-up file; cargo running; rustc
  running": the director's queued v5 job had started; **eventeo is left up on purpose** (its job powers it off).
  `~/SYSTEM_STATE.md` has a changelog line. Nothing contacted the production API (every script sources `env.sh`).
- mayalaran: everything under `~/claude` (`src/hk1-6abf*`, `src/s2v1`, `t/hk1-6abf*`, `t/s2v1*`, `t/lint`, `bin/`,
  `runs/hk1-6abf*`, `runs/s2v1`, `logs/`, `xfer/step2-v1.patch`, `scripts/m4_hk.sh`, `scripts/m4_s2.sh`); no process
  of mine runs there (checked 09:35).
- ivory: worktree `.worktrees/mo-hooks` (the branch, clean); the step-2 worktree and its target dir removed.
