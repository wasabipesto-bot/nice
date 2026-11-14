# Follow-up review: #263's CI failure, its fix (`165192ba`), and the reach of the CubeCL SPIR-V defect (2026-11-14)

Independent check of `git diff bec91fdd 165192ba` and of the author's account (`T26B/CI-FAIL.md`). I read
cubecl-opt, cubecl-core, cubecl-ir, cubecl-spirv and cubecl-cpp 0.10.0 in `~/.cargo/registry`. On the box (Vast
60696216) I built my own binaries from `git archive` trees in `/root/r2`, with their own target directories:
- main `54d0aac4` plus my test-only probe kernel;
- `165192ba`;
- `pr/top-slot-any-plane` `ec6a43a1`;
- `pr/check-d` `1f41d649`;
- `pr/join-prefilter-popcount-spirv` `3b773708`.

Each was built with both compilers (`cubecl-spirv` and `cubecl`, which is WGSL) and run in the author's Ubuntu 26.04
chroot on Mesa 26.0.8 lavapipe, with CubeCL's full compilation logger on. Everything is in `T26B/review2-box/`.

## Verdict on the fix: correct and complete; it is immune to the pass by construction

No kernel on upstream main or on any open PR branch I checked loses an operation (see the exposure table).

The fix is a single `OpAtomicStore` inside a runtime loop (`i = UNIT_POS_X; while i < 4 { q_acct[i].store(0);
i += CUBE_DIM_X }`). The pass that removed the stores only merges two or more store **instructions** in one basic
block. A single store instruction in a loop body cannot be merged, however many words it clears. The runtime index
is not what protects it (see below), and this loop cannot be unrolled because its bounds are not compile-time.

The clear is:
- **complete** for every cube size (units 0-3 clear one word each; a cube of 1-3 units loops);
- **ordered** before each word's first use by a cube barrier (barrier 1 of iteration 0 in the cube-scoped queue,
  the post-clear `sync_cube` in the plane-scoped one).

Two more places in this kernel matter:
- the in-loop clear of the alternating word (`q_acct[(1 - w)].store(0)`, line 1417) is the only store in its
  `if UNIT_POS_X == 0` block;
- the report uses `fetch_add` and `load`, which the pass does not merge.

So the account now starts at zero by construction on every backend.

The author's diagnosis is right, but narrower than the defect. The pass drops stores that write the **same value**,
whatever their target (any index, any array, shared or global, constant or runtime index), and not only stores at
constant indices.

## The defect, exactly

**Pass:** `MergeSameExpressions`, `cubecl-opt-0.10.0/src/passes/expression_merge.rs`, `check_op` (lines 111-145).
- It runs in `Optimizer::apply_post_ssa_passes` (`lib.rs` 281-300, the 4th of 10 passes, repeated to a fixed
  point). `EliminateUnusedVariables` runs in the same loop and removes what it leaves.
- Within one basic block, it replaces any later instruction whose `operation` equals an earlier one's
  (`op.operation == ops.borrow()[rhs_idx].operation`, line 137) and whose `out` has the same type with
  `Operation::Copy(earlier.out)` (line 140).
- The only guard is that every operand and the `out` be immutable (`Variable::is_immutable`,
  `cubecl-ir-0.10.0/src/variable.rs` 137-157).

**Why atomic stores fall into it.** `Atomic::store` registers
`Instruction::new(AtomicOp::Store(UnaryOperator { input: value }), ptr)` (`cubecl-core-0.10.0/src/frontend/element/atomic.rs` 45).
- The **target is the instruction's `out`**, and `operation` holds only the value.
- The target pointer is the result of an `Index` instruction, a `Versioned`/`LocalConst` local, which counts as
  immutable. The value is a constant or an SSA value, also immutable.
- So two stores of the same value compare equal whatever they point at. The second becomes `ptr_b = ptr_a`, which
  `EliminateUnusedVariables` deletes.

**Every other atomic carries its pointer inside `operation`** (`BinaryOperator { lhs: ptr, .. }`, `UnaryOperator
{ input: ptr }` for load):
- they merge only when they share one pointer local;
- every source-level `a[i]` produces a fresh local, and GVN treats `Index` as volatile (`gvn/numbering.rs` 193), so
  that does not happen in practice.

**Not affected:**
- plain stores (`IndexAssign`): their `out` is the array, which is not immutable, so the guard skips them;
- plane operations: they merge only with an identical plane op in the same block, which is sound.

**Who runs it:**
- `cubecl-spirv` runs the full pipeline (`Optimizer::new` → `run_opt`).
- `cubecl-cpp` (CUDA, HIP, MSL) calls only `Optimizer::shared_only` (`cubecl-cpp-0.10.0/src/shared/base.rs` 268;
  `run_shared_only`, `lib.rs` 253-259): graph, SSA, shared-memory liveness, no merge passes. It emits from the
  original scope.
- cubecl-wgpu's WGSL compiler does not use cubecl-opt.
- So only the SPIR-V build is affected.

**Class, measured on the device** (my probe kernel `rv_mini_kernel`, `review2-box/scripts/add_rvmini.py`). The
words are pre-set to distinct values in an earlier block, so a lost store shows as an unchanged word. Mesa 26.0.8
lavapipe, `review2-box/logs/probeS.log` and `probeW.log`, modules in `dump/probe_*.log`:

| operations in one block (unit 0) | `cubecl-spirv`: `OpAtomicStore`s kept / result | WGSL |
|---|---|---|
| `s[0..4].store(7)`, constant indices | 1 of 4; s = [7, 2, 3, 4] | all |
| `s[0].store(7); t[0].store(7)` (two shared arrays) | 1 of 2; `t[0]` unchanged | all |
| `v = val + UNIT_POS_X; s[0].store(v); s[1].store(v)` (runtime value) | 1 of 2 | all |
| `g[0].store(7); g[1].store(7)` (**global** atomic array) | 1 of 2; `g[1]` unchanged | all |
| `s[0].store(7); g[0].store(7)` (shared and global) | 1 of 2; `g[0]` unchanged | all |
| `#[unroll] for k in 0..4 { s[k].store(7) }` | 1 of 4 | all |
| the same two stores in two separate `if` blocks | 2 of 2 | all |
| plain `p[0] = 7; p[1] = 7` on `SharedMemory<u32>` | kept | kept |
| `s[0].fetch_add(1); s[1].fetch_add(1)`; `s[0].swap(7); s[1].swap(7)`; `s[0].fetch_add(1)` twice | kept (s[0] = 3 after two adds) | kept |

- **A runtime index does not protect a store by itself.** The comparison ignores the target entirely: the
  two-array and global cases above have nothing in common but the value. So `s[i].store(0); s[j].store(0)` in one
  block would also lose the second store [D, from the source and those two rows; not run with two runtime indices].
- What protects is one store instruction per block, or distinct values.

**The author's `[7, 7, 0, 0]`:** that module has a single `OpAtomicStore`, to word 0. Words 1-3 were never written,
so they show uninitialised workgroup memory. The 7 in word 1 is leftover data, not a store. My probe pre-sets the
words, and the unwritten words come back with their earlier values every time.

## Exposure, kernel by kernel

Method: per kernel variant (name plus CubeCL's full `KernelId`, i.e. every comptime argument), I count the atomic
operations in the SPIR-V module (`OpAtomicStore`, `IAdd`, `Or`, `Exchange`, ...) and in the WGSL module of the same
variant from the same test suite (`atomicStore`, `atomicAdd`, ...).
- The WGSL compiler emits every source-level operation; the probe confirms it keeps what SPIR-V drops.
- Any variant where SPIR-V has fewer stores or read-modify-writes is flagged.
- Script: `review2-box/scripts/atomcmp.py`. Suite: CI's `--ignored --nocapture cubecl_`, both compilers, Mesa 26.0.8.
- Validated on the author's bec91fdd dumps: it flags all 16 `niceonly_kernel` variants (stores 2 vs 5).

| tree | kernel variants compiled by the suite (SPIR-V = WGSL) | atomic stores / RMW missing in SPIR-V | `cmp_*.txt` |
|---|---|---|---|
| **upstream main `54d0aac4`** (+ my probe kernel) | 419: bucket 18, join 18, top 38, top-FD 21, check 12, detailed 4 + u32 34, detailed-FD 16 + u32 44, niceonly 9 (cube-scoped and uncompacted; the plane-scoped variant is not compiled on lavapipe), seed/cert probes, sentinel | **none**; only the probe kernel's 6 same-value modes (as intended) | `cmp_main.txt` |
| `165192ba` (the fix) | 425 (niceonly 26: 19 compacted with the account, both forms and queues' test variants, 7 uncompacted) | **none**; the compacted niceonly has 2 `OpAtomicStore` = WGSL's 2 (the clear loop and the in-loop clear) | `cmp_fix.txt` |
| `pr/top-slot-any-plane` `ec6a43a1` | 674 (top-FD 267 with its new account clear) | **none** | `cmp_top.txt` |
| `pr/check-d` `1f41d649` | 623 (check 213) | **none** | `cmp_checkd.txt` |
| `pr/join-prefilter-popcount-spirv` `3b773708` | 408 (its 18 join variants carry a compiler-dependent comptime flag, so they key differently; their counts are equal: 5 stores, 8 adds, 1 or, 3 loads on both sides) | **none** | `cmp_pop.txt` |
| `pr/join-survivor-stage-512` `0f6794a2`, `pr/join-prefilter-shift-pow2` `42d2afd9` | not dumped | source: no atomic store or RMW added, changed or moved by their diffs | |

The plane-scoped stride queue of `165192ba` cannot be compiled on lavapipe without a test-only knob; the author's
dump of it with that knob (`raw/ci/dump/spv_kf.log`, read with the author's `stores.py`) has one store into the
account words, at a dynamic index, which is the clear loop.

Source cross-check: every `.store(` on an atomic, on every branch, in every kernel file. No branch has two atomic
stores in one basic block:
- main's in `cubecl_join.rs` are `s_cnt[UNIT_POS_X]` (245), `s_cnt[0]` and `s_cw[UNIT_POS_X]` (563 and 566: the
  same value in **two separate `if` blocks**, so not merged, and the join kernel's module has all of its stores),
  `s_cw[UNIT_POS_X]` (1021) and `s_cnt[0]` (3091);
- the detailed kernels' histogram clear (one store in a loop: `cubecl_backend.rs` 115, `cubecl_detailed_fd.rs` 659,
  `cubecl_web.rs` 150/523).

Of the branches:
- `pr/top-slot-any-plane` adds `s_acct[UNIT_POS_X].store(0)` (one store, own block).
- `pr/check-d`, `pr/join-survivor-stage-512` and `pr/join-prefilter-shift-pow2` add no atomic store.
- `pr/join-prefilter-popcount-spirv` adds none either. Their hunks do not touch the blocks holding the stores
  (`git diff` of each against its merge base).
- `pr/join-survivor-stage-512` and `pr/join-prefilter-shift-pow2` were checked from source only.

**Production (RX 9070 XT, `cubecl-spirv`):**
- Production compiles different comptime variants (bases, the plane-scoped stride queue) from the same code. The
  pattern is structural: it needs two store instructions in one block.
- Main's atomic stores are all single per block, in every variant (none sits in an unrolled loop).
- Main's `niceonly_kernel`, plane-scoped included, has no atomic store at all, only `nice_count[0].fetch_add`.
- So nothing on main is exposed on the 9070 XT.

## Runs of the fix on Mesa 26.0.8 (my builds of `165192ba`: FXS = `cubecl-spirv` `0a75d0d5`, FXW = `cubecl` `1170d219`)

| run | result | log |
|---|---|---|
| the new partly-filled-plane test alone, 5 times per compiler | 10 × "32 runs, 0 wrong" | `newS_1..5`, `newW_1..5` |
| the fault test, each compiler | passes (each fault fails the field with its message) | `faultS`, `faultW` |
| CI's SPIR-V step (`--ignored --nocapture cubecl_`, one process), `--test-threads=4` | 28 passed, 0 failed | `suiteFS1` |
| the same, default threads (48) | 28 passed | `suiteFS2` |
| the same, `--test-threads=4` | 28 passed, 0 failed | `suiteFS3` |
| CI-style WGSL suite (`cubecl_`, `--test-threads=4`) | 28 passed | `suiteFW` |
| main `54d0aac4` (with the probe), SPIR-V / WGSL suites | 27 / 27 passed | `suiteMS`, `suiteMW` |
| `pr/top-slot-any-plane`, `pr/check-d`, `pr/join-prefilter-popcount-spirv`, SPIR-V and WGSL suites | 27/27, 28/28, 26/26 passed | `suiteTP*`, `suiteCD*`, `suitePP*` |

These suites ran beside each other on the box (up to six lavapipe processes at once), which is harsher than CI for
stale workgroup memory. CI on `165192ba` is green, including the lavapipe job (`gh pr checks 263`, read only).

## Findings

### F1: the fix is right; its doc comment and the PR body name the defect too narrowly (text, Low)

- `clear_queue_account`'s comment (`cubecl_backend.rs` 1576-1585) and the status paragraph say "four stores of `0`
  at constant indices ... came out as a single store". True of this kernel, but a reader will take "constant
  indices" as the trigger and a runtime index as the cure.
  - The trigger is two or more atomic stores of the **same value** in one basic block, to any target: shared or
    global, any array, any index.
  - What makes the fix safe is that it is one store instruction.
- **Suggested comment:** "CubeCL 0.10's SPIR-V optimizer (cubecl-opt's `MergeSameExpressions`) keeps only the
  first of several atomic stores of one value in a block, whatever they target; one store in a loop is not merged."
- **Suggested body sentence:** "...merged the four stores ... (a cubecl-opt pass that keeps only the first of
  several atomic stores of one value in a basic block, whatever their targets)".

### F2: the status paragraph against the evidence (Q4)

Supported:
- **"found and fixed in 165192ba, and CI is green on it":** `gh pr checks 263` (read only) shows every job passing
  at `165192ba`, including "cubecl on lavapipe (Linux)" and "cubecl (Metal) on macOS".
- **"from the new account, not from the queue":** yes; the queue's survivors were exact while the account fired.
- **"merged the four stores ... into a single store":** yes (F1 for the wording).
- **"Mesa 26's lavapipe hands a kernel memory that earlier kernels used":** an inference that fits every
  observation (passes alone, fails in the suite). Not traced in Mesa; "evidently" would be honest.
- **"an investigation build compared every run's survivors with the host mirror: all exact":** supported by
  `is_ci4_1.log`: 32 of 32 runs exact against the host mirror in a CI-style suite where the account fired (e.g.
  words `[283, 96636765, 0]`). It was a re-run on the box, not CI's own run; "in a re-run of CI's suite" would be
  exact.
- **"at the production workgroup size too":** supported (a 256-unit run fired in `hs_ci4_*`).
- **"the CUDA and WGSL compilers keep all four stores":** supported by source (cubecl-cpp runs only
  `shared_only`, the WGSL compiler no cubecl-opt) and by dumps (author's CUDA module; my WGSL modules and probe).
- **"20 times in a row with each compiler and every lavapipe suite passed":** the author's logs; my own runs agree
  (below).
- **"A four-line kernel ... four atomic stores of one value at constant indices: one `OpAtomicStore`":** supported;
  "of one value in one block" is the real condition.

Overstated:
- **"The same would have made stride-walk fields fail spuriously on any Vulkan device with the SPIR-V build":** the
  module is the same on every device (cubecl-opt runs before the driver), so every SPIR-V device got a kernel
  without the clear.
  - Whether a field failed depends on the workgroup memory being non-zero at kernel start. Vulkan does not zero it,
    and wgpu cannot zero-initialise a passthrough SPIR-V module. So "could have ..., whenever the workgroup memory
    a kernel inherits is not zero" is the supported form.
  - The consequence ("fail", not "report wrong results") is right: a failed field reports nothing.

### F3: a latent hazard for every future kernel built with `cubecl-spirv` (Medium, process)

Nothing on main or in the open PRs is exposed today. But any future kernel that stores one value into two atomics in
one block is silently miscompiled for the project's main production device, the RX 9070 XT. Typical cases: clearing
two counters with `0`, or setting two flags to `1`. No test of the WGSL or CUDA builds would show it.

Suggestions (not required for #263):
1. A rule in the kernel modules' docs: one atomic store per block, or distinct values; clear counters with one store
   in a loop.
2. A CI check that compares, per kernel variant, the atomic operation counts of the SPIR-V and WGSL modules (the
   `atomcmp.py` method; both logs already come from the lavapipe job if the compilation logger is switched on).
3. File the upstream report (`T26B/CUBECL-ISSUE-DRAFT.md`) and re-check after any CubeCL upgrade. I could not read
   cubecl-opt 0.11.3's pass: the registry copy on ivory is incomplete.

### F4: Informational: `cubecl-cpp` and the MSL path

CUDA, HIP and Metal-MSL builds go through `cubecl-cpp`, which uses cubecl-opt only for shared-memory liveness
(`shared_only`). They are not affected. The macOS CI job's MSL run of the new test passing is consistent with that.


## What I could not verify

- No RADV device: the exposure on the 9070 XT rests on the modules being the same for the same kernel. cubecl-opt
  runs before any driver sees the module, so the drop is device-independent.
- Production's own variants (the plane-scoped stride queue on main, bases outside the tests) were not dumped. They
  are covered by the structural argument above.
- The two runtime-index store case was argued from source, not run.
- `pr/join-survivor-stage-512` and `pr/join-prefilter-shift-pow2` were not dumped (source only; neither touches an
  atomic).
