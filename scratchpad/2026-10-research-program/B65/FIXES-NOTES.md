# Base-65 branch: the review's fixes and an independent count for every list append (2026-11-27)

Brief: `BRIEF-FIXES.md`; work list: `LEVERS-REVIEW.md`. Scripts: `scripts/fixes/` (on eventeo under
`~/research/b65b/scripts/`, on the M4 under `~/claude/scripts/`). Logs: `runs/fixes/`.

## Branch

Fork **`dev/mo-wide-b65b`**, head **`f503a13c`**, on `dev/mo-mode` `c16d48e9`:

| commit | what |
|---|---|
| `73bc0065` | merge of `dev/mo-wide-b65` `a7ea3890` (git merged `gpu_wide.rs` itself, test modules of both sides kept; nothing to resolve) |
| `f8ee8d24` | finding 2: `tstat[2]` (the compact tops list's count) must equal `tstat[0]` |
| `ff2befbd` | finding 1: shared parents against brute force, n for n and through the field path; lists asserted used |
| `46fdb4f7` | finding 4: a per-lane count apart from the ballot for every list append (wide and narrow); five split faults |
| `96035974` | finding 3: `F_ANC_DROP` (a wrong shared list, consistent counts) caught by the sampled check's field-run comparison |
| `bc3afb76` | step 5 + finding 5: the dump builds `wanc`; CI requires `WancKernel`, `Wtops1Kernel` at w 32 and 64; field-path OOM test |
| `6cc94f43` | finding 6: the shared keys cleared at the field's end |
| `f503a13c` | fix of `46fdb4f7`: the main kernels' new survivor counter cleared in a block of its own (see "What went wrong") |

Commits `f8ee8d24`..`6cc94f43` were each checked on the M4 (`cargo fmt --check`, `cargo check --lib --tests` with
`cubecl,midout-box-tests,midout-bench`): all compile, no new warning. No pull request; nothing pushed to `origin`,
`dev/mo-mode` or `dev/mo-wide-b65`; no force-push, no amend.

## Per finding

1. **Shared path against an independent reference (B).** `wide_whole_small_bases_vs_brute_force` now runs every
   shape with k − 2 > f0 ((13; 0,3), (17; 1,4), (18; 1,4), (19; 0,4), (20; 1,4), (24; 1,4), (25; 2,5)) twice
   more: (a) every slice through its key's shared list (`run_slice_with(.., shared)`), survivors n for n against
   brute force, every slice's list used (counter in the join); (b) the field path with sharing on
   (`search_field_wide`, one field per value of digit f0, b slices per key, sampled check on): survivors, checked,
   nice numbers against brute force. The range's clipped first and last slices are among them. **`build_anc` now
   accepts an empty list**: (13; 0,3) has 2 empty keys of 13 (base 13 at that shape has 1 root). Caveat: these bases
   have few survivors (0–14k per shape), so the test proves the plumbing and the clipping, not volume; volume is
   the b65 sharing test (130 slices, 2.1G survivors) and `MIDOUT_WIDE_SHARE=1` on the b65 slice (n for n vs CPU,
   2,276,934 of 10,892,331 roots listed). The b65 sharing test now asserts that each of its 130 slices took a list
   shorter than the roots (used, not only built).
2. **`tstat[2]` read back (B).** `check_slice` fails "wtops1 tops listed" unless `tstat[2] = tstat[0]`, placed after
   the existing tops checks so every existing fault fails where it did.
3. **A fault confined to the shared lists (B).** `F_ANC_DROP`: `wanc` leaves out roots r_f ≡ 0 mod 997 as if
   uncertified (its counts consistent). Every account passes; the sampled check fails with "the field run counted
   survivors …, CPU …" (asserted on the message), then a clean rerun equals. On the final head: CUDA slice 5055545
   (field run 16432559, CPU 16449700), Vulkan slice 22906159 (16449977 vs 16466427), Metal slice 22906171 (16474907
   vs 16491132).
4. **Independent counts (C)**: the audit below. Every append that lacked one has a per-lane count now.
5. **w = 64, memory (C).** The compile-only path (`MIDOUT_FORCE_W=64 wide_slices_equal_cpu`) and the WGSL dump
   now call `build_anc`; both compile `wanc` at w 64 (plane check fails as expected under a forced width).
   `wide_field_oom_is_loud` (field path, sharing on, the card filled with 6,400 or 6,976 MiB after the join is made): the lists' allocation fails inside CubeCL's CUDA server thread (it panics there, `server.rs:124`), `wanc` never runs, and the field fails loudly, "wanc (key 5055528): cubes done: 0, want 42549". Both fills; nothing returned as searched.
   **Bases 66–70 are out of scope today**; no b68/b70 memory run, no fallback to unshared on a failed list
   allocation (it fails the field loudly, as before).
6. **Minor (D).** Done: `wanc`'s "roots certified" is now a per-lane count (the doc comment's claim is true now);
   `keys.clear()` after the field loop as on the narrow path; `WideJoin`'s doc says one field at a time. Not done:
   nothing else was listed.

## Audit of plane-ballot and plane-scan appends

"Append" = a position taken from a ballot rank or a plane scan, with a count added by one lane. "Independent" = a
count that no plane operation can drop, compared by the host with the list's own count.

| file | kernel | appends | list's own count | independent count (host check) | before |
|---|---|---|---|---|---|
| wide | `wtops5` | valid parent prefixes → `t5list` | `l5n[0]` (ballot, lane 0) | **new** `l5n[2]`: each valid lane +1 in shared memory; "wtops5 valid parents listed = counted by its lanes" | none (review finding 4) |
| wide | `wtops1` | certified tops → `tc` | `tstat[2]` (ballot) | `tstat[0]`: scan of `segc`, which every certifying lane increments itself; **now also checked directly** (finding 2) | via `A_T2_PLACED` only |
| wide | `wanc` | roots → shared lists | `cnt[0]` (ballot) | **new** `acc8[2]`: per-lane +1 ("roots certified = listed"); plus `acc8[1]` roots examined = nroots | `acc8[2]` was the same ballot sum |
| wide | `whist` | parents → `g_lst` | `lcnt` (ballot) | **new** `A_H_CERT`: per-lane +1 per certified parent ("parents certified (whist) = listed") | `A_H_CERT` was a ballot summed by lane 0 |
| wide | `wide_kernel` phase 1 | children → the cube's pending list | per-plane ballot totals through shared memory | `A_SC_CHILD` (wscatter counts each listed parent's children from its record) = `A_CHILD` | unchanged, already independent |
| wide | `wide_kernel` phase 3 | records → slabs | `slab_used`/slab ids (ballot, lane 0 atomic) | **new**: survivor bits counted per lane into shared memory (no plane sum) = the bits the expansion reads | `my_surv` summed by `plane_sum` |
| wide | `wexpand` | survivors → `surv` | `scount` (plane scan, lane 0) | **new** `est[4]`: per-lane bits appended ("expansion appended n survivors, its lanes counted …") | none |
| wide | `wscatter`, `wtops2`, `wcheck` nice | per-lane atomics, no ballot | — | not ballot appends | — |
| narrow | `tops5` | per-lane atomic append | — | not a ballot append (the review's suspicion does not hold) | — |
| narrow | `tops1`, `tops2`, `tdigz2` | per-prefix arrays / per-lane cursors | — | not ballot appends | — |
| narrow | `anc8` | roots → shared lists | `cnt[0]` (ballot) | **new** `acc8[2]` per lane | ballot sum |
| narrow | `hist2` | parents → list | `lcnt` (ballot) | **new** `A_H2_CERT` per lane | ballot |
| narrow | `g2_kernel` phase 1 | children | per-plane ballot totals | `A_SC_CHILD` = `A_CHILD` | unchanged |
| narrow | `g2_kernel` phase 3 | records → slabs | ballot | **new** per-lane survivor bits = bits read by the prefilter | `plane_sum` |
| narrow | `expand_kernel` | survivors → list | `scount` (plane scan) | **new** `stat[5]` per lane | none |

The ballot-transposes of the main kernels' phase 2 (`comm`, `sl`) are data, not appends: a lost lane there changes
survivor sets, which the main kernel's per-lane counts and the expansion's reads see only partly; the sampled check
covers them. Not changed.

**Faults that show each new count is loud** (each models a split: lanes outside lane 0 leave the ballot or scan,
their entries are lost, the ballot's own counts stay consistent): `F_T5_SPLIT`, `F_ANC_SPLIT` (wide and narrow),
`F_EXP_SPLIT` (wide and narrow), `F_SLAB_SPLIT` (wide and narrow); for `whist`/`hist2` the existing `F_DROP_PARENT`
now fails on the per-lane count. For `F_T5_SPLIT`, `F_ANC_SPLIT` and `F_EXP_SPLIT` the old
counts would pass (the emulation takes the lanes out of the ballot or scan that gave the old count, so the lost
entries are missing from both sides). `F_SLAB_SPLIT` only empties the records; the old plane sum would have caught it
too, so it shows the new count is loud, not that the old one was silent. Results: see Tests. `set_fault` now forgets the cached top-hierarchy list (otherwise a
fault never reaches `wtops5`: the first Metal run showed `F_T5_SPLIT` silent for that reason, fixed before commit).

## Tests (final head `f503a13c` unless stated)

| test | RTX 3060 CUDA | RTX 3060 Vulkan (direct SPIR-V) | M4 Metal (wgpu/WGSL) | CI |
|---|---|---|---|---|
| card tier `cubecl_midout*` (8: wide and narrow, incl. both b40/b64 fault tiers) | ok | ok | ok | lavapipe WGSL 50 ok, lavapipe SPIR-V 39 ok, macOS Metal 50 + MSL 39 ok |
| `wide_slices_equal_cpu` (b65 slice, tops and survivors n for n) | ok | ok | ok | — |
| same, `MIDOUT_WIDE_SHARE=1` (through the shared list, 2,276,934 of 10,892,331 roots) | ok | ok | ok | — |
| same, `MIDOUT_FORCE_W=64` compile-only (now with `wanc`) | ok | ok (1) | — | — |
| `wide_faults_are_loud` (b65, 2 slices; + `F_T5_SPLIT`, `F_EXP_SPLIT`, `F_SLAB_SPLIT`) | ok | ok | ok | — |
| `wide_field_parent_sharing_is_exact_and_loud` (+ used, `F_ANC_SPLIT`, `F_ANC_DROP`) | ok | ok | ok | — |
| `wide_whole_small_bases_vs_brute_force` (+ shared and field path) | ok on the GTX 1060 (1,005 s) | ok on the GTX 1060 (1,074 s) | ok (2,703 s) | — |
| narrow `gpu_slices_equal_cpu`, with `MIDOUT_SHARE8=1`, `accounts_faults_are_loud` (+ `F_EXP_SPLIT`, `F_SLAB_SPLIT`), `field_parent_sharing_is_exact_and_loud` (+ `F_ANC_SPLIT`) | ok | ok (1) | — | — |
| `wide_field_oom_is_loud` (6,400 and 6,976 MiB filled) | loud, both | — | — | — |
| WGSL lint with the new `--require` lists | — | — | ok (M4 dump) | lavapipe step ok, 63 shaders, 0 flagged |
| `just lint`; clippy `-p nice_common --all-targets` with `cubecl-cuda`/`cubecl-spirv` + `midout-box-tests,midout-bench` | ivory: all pass (2) | | M4 clippy fails on pre-existing macOS-only lints in `cpu_join.rs` and on the missing Vulkan SDK (not this branch) | "Format and clippy" ok; whole cross-platform matrix ok |

(1) Two processes ended with the known SPIR-V exit segfault (rc 139) after "1 passed".
(2) On `6cc94f43`; `f503a13c` changed only six kernel lines, and CI's "Format and clippy" passed on it.

CI on `f503a13c`: "GPU Device Parity" run 45979920949 success (lavapipe incl. lint, Metal); "Rust Cross-Platform
Build, Test, and Release" run 45979925310 success (every job; release skipped). The runs on `6cc94f43`: GPU parity
failed (below), the cross-platform run was cancelled as superseded.

**Fault messages:** every existing fault line of the wide and narrow fault and sharing tests is byte-identical to
yesterday's `runs/levers/levers-final-tests` (account dumps included), except the narrow `F_SKIP_TOPS` dump's word 3
(tops placed from stale per-prefix flags of the previous slice: 239391 then, 219134 / 239372 now; it depends on which
run came before, as the levers notes explained for the wide path; same check, same text). New lines only for the new
faults, e.g. "wtops5 valid parents listed = counted by its lanes: 88391, want 2838017", "wanc (key 5055505): roots
certified 2278489 = listed 71456", "expansion appended 454667 survivors, its lanes counted 527041", "861904
survivor bits read by the expansion, the kernel counted 26951472".

**Counts:** every timing run below (CUDA and Vulkan, before and after, b65 fields 13731 and 77777, b64 wide and
narrow 4095 and 77777) has identical survivors, checked, tops, children, chunks, flat and kept; b65 77777 = 69,601,522,205
survivors / 2,222,575,676 checked and b64 77777 = 48,216,914,309 / 1,384,731,444, equal to `runs/levers/` and
`runs/reads-bench/`. The M4's b65 77777 field (with the sampled check) is the same.

## What went wrong on the way (all loud)

- `46fdb4f7` cleared the main kernels' new survivor counter `s_nl[1]` next to `s_nl[0]` in one block: CubeCL 0.10's
  SPIR-V expression merge drops the second atomic store of the same value (the known issue,
  `reference_cubecl_spirv_atomic_store_merge`), so on lavapipe's SPIR-V run every middle-out slice failed with
  "survivors read by the prefilter, the kernel counted 11857851109" (and the GTX 1060 through Vulkan likewise). Fixed
  in `f503a13c` (thread 1 clears it alone); every other new clear is the only store of its block (checked).
- The first Metal run showed `F_T5_SPLIT` silent: the fault never reached `wtops5`, whose list is cached per group;
  `set_fault` now drops the cache. Fixed before the commits.
- The M4's `build_mo.sh` checks out the worktree's own `FETCH_HEAD`, which is stale in an existing worktree: a rerun
  under the old tag built the old head; the final M4 run used a new tag (`fx-f503`, head checked).

## Cost of the new counts (RTX 3060, same session, alternating, field 77777 after the warm-up field)

| runtime, path | before (`73bc0065`) | after (`f503a13c`) | change |
|---|---|---|---|
| CUDA b65 wide, ms/slice (fs) | 22.53, 22.57 (6.0221, 6.0334) | 22.86, 22.91 (6.1112, 6.1248) | **+1.5 %** |
| CUDA b64 wide (fs) | 3.4150, 3.4143 | 3.4700, 3.4710 | +1.6 % |
| CUDA b64 narrow (fs; production b64) | 3.2812, 3.2833 | 3.3475, 3.3275 | +1.3 to +2.0 % |
| Vulkan/SPIR-V b65 wide (fs) | 5.7636, 5.7620 | 5.8017, 5.8126 | +0.7 to +0.9 % |

Card beside every run: 98–100 % busy, 159–165 W (at the 170 W cap), 1777–1792 MHz, same before and after; peak card
memory unchanged (5,870 MiB CUDA, 6,379 MiB Vulkan at b65). Round 1 of the CUDA runs overlapped the brute-force test
on the GTX 1060; round 2 (clean) gives the same differences.

**Where it is** (stops, b65 CUDA, ms/slice): tops + parents 3.948 → 3.941 (none); + main kernel 17.98 → 18.30
(+0.32); + expansion 22.31 → 22.70 (+0.07 more). **And why:** the final head with only the five split faults'
emulation code removed (the counts kept; `fx-noemul`, built on ivory from `f503a13c`, not on the branch) runs
22.51 / 22.54 ms/slice (6.0186 / 6.0256 fs) at b65 and 3.2871 fs at b64 narrow: equal to before within 0.2 %. **So
the independent counts cost under 0.2 % of a field; the 1.5 % is the fault-injection hooks** (a runtime fault test
and a select per slab record in the main kernels' hot loop, a select and a branch per expansion round). Kept, as the
brief says. The obvious follow-up (not done): compile the split faults out of production kernels (a comptime flag
set only by the tests, or `cfg(test)`-gated kernel variants), which should give the 1.5 % back with the counts kept.

## Not done

- The compile-out of the fault hooks above (would need another full test round on three runtimes).
- Bases 66–70 (out of scope today): no run at w = 64 on a wave64 card (the 9070 XT is not on the lease), no b68/b70
  memory run, no fallback to unshared lists.
- The main kernels' phase-2 ballot transposes are not appends and got no new count (see the audit).
- A timing of the fault-free variant through Vulkan (CUDA only).
- No pull request (as briefed).

## Machines and energy

- eventeo: woken 09:07 (ssh up after 50 s), work 09:08–12:00, powered off at 12:01 with `off_if_idle.sh`; ssh from
  ivory times out after. Wall energy 09:07–12:01 UTC: **0.59 kWh** (counter 2.12 → 2.71; mean 203 W, peak 331 W
  with both cards busy), about $0.10. `~/SYSTEM_STATE.md` there has a changelog line (worktrees `b65b`, `b65t`, `b65w`,
  target dirs 3.9 GB, safe to delete). Nothing contacted the production API (every script sources `env.sh`).
- mayalaran: everything under `~/claude` (`src/fx-*`, `t/fx-*`, `t/lint`, `bin/fx-*`, `runs/fx-*`, `logs/fx-*`,
  `xfer/`); no process of mine runs there (checked 12:01).
- ivory: worktree `.worktrees/mo-wide-b65b` (the branch, clean); temporary build dirs removed.

