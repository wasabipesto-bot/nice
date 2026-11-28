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

STEP2_BRANCH

No pull request; nothing pushed to `origin` or `dev/mo-mode`; no force-push, no amend.

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

STEP1_TIMING

STEP1_TESTS

STEP2

## Not done

NOTDONE

## Machines and energy

MACHINES
