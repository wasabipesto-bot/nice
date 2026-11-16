# MU260: PR #260 merged up with main (2026-11-16)

**Merge commit `31ba079b`** (`31ba079ba2dae573e372aa01ecd50eb20eb391e5`), parents `ec6a43a1` (#260's head) and
`0711b163` (upstream main). Made with `git merge --no-ff origin/main` in `.worktrees/t26-top-slot` (branch
`t26/top-slot`); no rebase, no force. Push: see §4.

## 1. Resolution, hunk by hunk

Conflicts: `CHANGELOG.md` (1 region), `common/src/cubecl_join.rs` (10 regions). Nothing else conflicted; every
other file of main merged in unchanged (`git diff origin/main 31ba079b --stat`: `CHANGELOG.md` +1,
`common/src/cubecl_join.rs` +501/−50, nothing else).

**`CHANGELOG.md`.** Main's file byte for byte, with #260's line (`ec6a43a1`'s, unchanged) inserted as the first item
of Unreleased. `git diff origin/main 31ba079b -- CHANGELOG.md` is exactly that one added line.

**`common/src/cubecl_join.rs`: built mechanically from the tested resolution, not by hand.** The file is
`git merge-file -p main.rs 99b283ab.rs 8bcee21f.rs`: main's file plus the change that took `exp/integration-1114`
from variant 1 (`99b283ab` = old main + #251 + #255 + #256 + #259) to variant 2 (`8bcee21f` = the same + #260's fix,
resolved against #251 as T26 §7 item 5 / REVIEW F4 describe). It applied with 0 conflicts. So the `ran` region, the
top kernels, the check kernel and the host checks are 8bcee21f's text:

- words `0..4` the four kernels' cube counts; `4..7` #251's check (work counter, entries checked, index sum), at
  `STAGES + 0..3` as on main; then #260's account: `TOP_ACCOUNT = STAGES_U32 + 3`, `RAN_WORDS = STAGES + 5`;
- the `STAGES` doc comment lists all three regions in one place;
- `const _: () = assert!(TOP_ACCOUNT as usize + 2 == RAN_WORDS)` (#260's `TOP_ACCOUNT == STAGES` assert replaced):
  the account's two words sit after #251's three and `RAN_WORDS` covers them;
- #251's test-only smallest-take word moved from `ran[STAGES_U32 + 3]` (which would now be `TOP_ACCOUNT`) to
  `ran[TOP_ACCOUNT + 2]` = `ran[RAN_WORDS]`, the word `run_check` allocates (`RAN_WORDS + 1`) and reads; both
  `fetch_min`s in `take_entries`;
- `ensure_ran` reads `&ran[..STAGES]` only, `ensure_checked` `STAGES + 1`, `STAGES + 2`, `ensure_appended`
  `TOP_ACCOUNT`, `TOP_ACCOUNT + 1`; `run_partition` and `run_pass` call `ensure_ran`, then `ensure_appended`, then
  (after reading the counts) `ensure_checked`;
- both sides of the rest: the `use super::{..}` list (#251's `CHECK_*` and #260's `TOP_*` names), the buffers sized
  `RAN_WORDS` with the "five more words" comment, the thread-locals, `check_all` calling `check_skipped_entries` and
  `check_lost_tops`, both host unit tests.

The ten conflict regions (reconstructed with `git merge-file` over the merge base `54d0aac4`, `work/conflicts.rs`):
(1) the `STAGES`/`TOP_ACCOUNT`/`RAN_WORDS` block; (2) `mod kernels`' `use super::{..}` list; (3) the `ran` buffer
after the cube counts (`RAN_WORDS`, the "five more words" comment); (4) `ensure_ran`'s body; (5) `ensure_checked` /
`ensure_appended`; (6) `check_complete` / `top_complete`; (7) `run_partition` after `ensure_ran`; (8) the test
thread-locals; (9) `check_all`; (10) the host unit tests. Each takes both sides as 8bcee21f does. **#251's two
smallest-take `fetch_min`s at `STAGES_U32 + 3` did not conflict** (the quiet hazard F4 names): left as merged they
would have written over `TOP_ACCOUNT`; the resolution moves them to `TOP_ACCOUNT + 2`.

**Not done, and why.** REVIEW F4's fuller recommendation (name #251's words too, `CHECK_WORK`/`CHECK_COUNT`/`CHECK_SUM`,
and a `MIN_TAKE_WORD`, and assert `CHECK_SUM < TOP_ACCOUNT`) is not in 8bcee21f, and the brief requires the merge to
equal 8bcee21f outside #255/#259. `CHECK_COUNT` is also already taken (a `check_kernel` mode). #251's words stay
`STAGES + 1`/`+ 2` in the check kernel and host, the smallest-take word is `TOP_ACCOUNT + 2`; disjointness holds by
construction (`TOP_ACCOUNT = STAGES + 3` follows #251's last word `STAGES + 2`) and the assert pins the tail. A naming
follow-up would be a separate, cosmetic commit.

## 2. Mechanical checks

**(a) merge vs the integration branch.** `git diff 31ba079b 8bcee21f -- common/src/cubecl_join.rs`: 14 hunks
(`work/merge_vs_int.diff`), all #255's or #259's: `join_kernel`'s doc + `pf_count` comptime parameter + its pass to
`walk_pf_lean`; `walk_pf_lean`'s doc, `count` parameter, power-of-two digits and count form; `JoinDevice.pf_count`
field, its setting in `new`, its pass at launch; the host `pf_count` helper, `fx_digits_are_bit_fields_at_powers_of_two`,
and the `pf_count` lines in the two lean-test loops and the gated test. Nothing in `ran`, the top kernels, the check
kernel or the host checks. **Proof that it is exactly those two PRs:** applying #255's own diff
(`git diff 911305ec 25ad18dd`, its merge on the integration branch) and then #259's (`git diff 2189dc75 99b283ab`) to
the merge's file gives 8bcee21f's file **byte for byte** (`cmp` equal; patches applied with offsets only, no fuzz).
Main's file against the integration's pre-#259 point: `git diff origin/main 2189dc75 -- cubecl_join.rs` is +61/−5,
#255's size (its PR branch: +62/−5 incl. its CHANGELOG line), so main carries #251 and #256 as the integration did.

**(b) merge vs main.** `git diff origin/main 31ba079b -- common/src/cubecl_join.rs` (+501/−50) against #260's own
change `git diff 41b4b405 f9a25017` (+503/−49), compared line by line with `-U0` (`work/interdiff.txt`, 63 lines).
Every difference is one of:
1. the `STAGES` doc comment: #260 alone had "finished cubes in `ran`, whose next two words are the top stage's
   account"; the merge extends #251's sentence "(mod 2^32), then the top stage's account …" (the F4 doc change);
2. `TOP_ACCOUNT = 4` / `RAN_WORDS = STAGES + 2` / `assert!(TOP_ACCOUNT == STAGES)` (#260 alone) against
   `TOP_ACCOUNT = STAGES_U32 + 3` / `RAN_WORDS: STAGES + 3 → STAGES + 5` / `assert!(TOP_ACCOUNT + 2 == RAN_WORDS)` (merge);
3. the test `use` list: same added names (`TOP_ACCOUNT`, `TOP_DUP_RANK`, `TOP_LANE0_OUT`, `TOP_SHORT_TAKE`), wrapped
   against main's longer list;
4. a diff-alignment artefact in `top_slot` (the same added lines; `diff` places one `}` and the removed
   `slot * ntlay + goff + at` at a different point) — the added text is identical;
5. the merge's two extra changed lines: #251's `fetch_min` word `STAGES_U32 + 3 → TOP_ACCOUNT + 2`;
6. buffer sizing: #260 alone changed `vec![0u32; expect.len()]` to `RAN_WORDS` and added `&ran[..STAGES]` in
   `ensure_ran`; main already had both (#251), so the merge only rewrites #251's "three more words" comment to "five";
7. `run_partition`: #260 alone introduced `let ran = dev.read_u32(..)` before `ensure_ran`; main already has it
   (#251), so the merge adds only the `ensure_appended` call.

So the merge is #260's change, adapted to #251's `ran` words, and nothing else.

## 3. Verification

Box: Vast 60886021 (RTX 3080, 300 W limit, 24 threads), tree `/root/mu/m` = `31ba079b` (from a bundle of the local
commit, before the push), clean; one target dir `/root/mu/target-m`; rustc 1.100.0. Binaries (`box/out/builds.txt`):
**G** `--features gpu` (CUDA + wgpu) md5 e07360e4; **W** `--features cubecl` (CI's WGSL job) md5 c377896d; **S**
`--features cubecl-spirv` (CI's SPIR-V job) md5 f22c950c; **GM** = upstream main `0711b163`, `--features gpu`, md5
4b7fda8f (for two comparisons only). Scripts `scripts/` (setup, build, builds, ex, t, lvp, atomcmp); logs `box/logs/`.

| check | where | result | log |
|---|---|---|---|
| `just lint` (fmt; clippy `-D warnings` default and `nice_client/gpu,nice_client/cubecl-spirv`) | ivory, `nice -n 19`, rustc 1.100.0 | **clean** (exit 0; only cargo's pre-existing `web-sys` manifest note) | `work/lint_ivory.log` |
| host tests, `cargo test -p nice_common --lib` (debug, no GPU features: ivory allows no release/GPU builds) | ivory | **207 passed**, 9 ignored | `work/host_tests_ivory.log` |
| host tests, CI's command `cargo test --release -p nice_common --features gpu --lib` | box | **260 passed**, 64 ignored | `box/logs/G_host_tests.log` |
| `cubecl_cuda_check_counts_match_the_cpu` (#251) | RTX 3080 | ok: 64 lists, 1,168,717 entries, 84,652 synthetic n, 3,047 past the gate (= T26) | `G_cubecl_cuda_check_counts…` |
| `cubecl_cuda_check_takes_every_entry_on_partly_filled_warps` (#251) | RTX 3080 | ok, 84 runs; smallest take 16 / 4 / 32 at cubes of 48 / 100 / 256 | `G_cubecl_cuda_check_takes…` |
| `cubecl_cuda_join_matches_the_cpu_reference` (`check_all`: both PRs' fault tests in one binary, one `ran` array) | RTX 3080 | ok. Check faults: b10 0 of 1; b20 138 of 139; index sum 9590 not 9591. Top faults: 112 more tops kept than counted; record indices off by −87 | `G_cubecl_cuda_join_matches…` |
| `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu` | RTX 3080 | ok: 102,365 intervals, 33,582 kept (= T26) | `G_cubecl_cuda_top_cert…` |
| `cubecl_cuda_top_fd_appends_every_top_on_partly_filled_warps` (#260) | RTX 3080 | ok: 230 runs, 23 fields, 4,764,544 tops (= T26) | `G_cubecl_cuda_top_fd_appends…` |
| `cubecl_cuda_top_fd_matches_the_top_kernel` (heavy), own process | RTX 3080 | ok: 26 fields, 279 batches, 422,559,183 tops; **main `0711b163` (GM): the same 422,559,183** | `G_…top_fd_matches…`, `GM_top_fd_matches.log` |
| dense vs CPU join, 8 partitions of slice 0, b60 1e16 @ `1447429612114824200908` | RTX 3080 | ok: 336,157,460 survivors / 22,524,024 checked; **main GM: identical** | `G_dense_b60.log`, `GM_dense_b60.log` |
| the same, b62 1e17 @ `7520566762397899821056` | RTX 3080 | ok: 170,247,827 / 10,384,896 (= T26) | `G_dense_b62.log` |
| the same, b64 1e17 @ `58557331862957161709568` | RTX 3080 | ok: 697,596,881 / 43,247,716 (= T26) | `G_dense_b64.log` |
| **lavapipe WGSL, as CI**: W, `--ignored --nocapture` (every ignored test), in the Ubuntu 26.04 chroot, Mesa **26.0.8**-1ubuntu0.3 (LLVM 21.1.8) | box CPU | **40 passed**, 0 failed (1171 s) | `lvp_W.log` |
| **lavapipe SPIR-V, as CI**: S, `--ignored --nocapture cubecl_`, same chroot | box CPU | **31 passed**, 0 failed (1413 s) | `lvp_S.log` |
| in both lavapipe runs: #260's `top_fd_appends_every_top_on_partly_filled_planes` (partly filled planes **and planes without lane 0**), #251's `cubecl_check_takes_every_entry_on_partly_filled_planes`, `cubecl_join_matches_the_cpu_reference` with both fault tests | lavapipe | ok in both: 552 runs, 23 fields, 6,492,699 tops (= T26); every entry checked once, 168 runs, smallest take 4 at cubes of 100 ("partly filled planes ran"); faults: 0 of 1, 138 of 139, sum 9590/9591, 447 tops, −44 — each fault reports its own words, no collision | `lvp_W.log`, `lvp_S.log` |
| **SPIR-V atomics** (`atomcmp.py`, T26B's method): CubeCL full compilation logs of both lavapipe runs, per kernel variant SPIR-V vs WGSL | box | **902 variants matched (902 / 902), 0 store / RMW missing in SPIR-V** (top_fd 267, check 213, cert probes 105, top 58, …) | `box/out/cmp_merge.txt` (dumps 158 MB / 109 MB stay on the box) |

**Counts that differ from T26 (2026-11-14), and why it is not the merge.** b60 dense (334,071,589 / 22,383,910 on
11-14) and the heavy FD comparison's top total (423,104,943 on 11-14) differ on this tree. Upstream main `0711b163`
built on the same box gives exactly this tree's numbers (`GM_*`). In every run the device equals the CPU reference.
b62 and b64 dense counts are unchanged from 11-14. **Corrected by §6:** my first reading ("the change came with main")
was wrong. The 11-14 integration binary itself (same md5) gives today's numbers on this box: the input differs, not
the code.

Not run: Metal, HIP, any 64-lane device; whole-workspace `cargo test` (the merge changes `nice_common` only).

## 4. Push

`git push fork t26/top-slot:pr/top-slot-any-plane` at 06:49 UTC: `ec6a43a1..31ba079b` (fast-forward, accepted).
`fork/pr/top-slot-any-plane` = `31ba079ba2dae573e372aa01ecd50eb20eb391e5`. No PR action taken.

GitHub (read only, 07:22 UTC): PR #260 head = `31ba079b`, **MERGEABLE**; its CI on the merge: every finished job green
(Format and clippy, Test workspace, Test GPU host code, cubecl on lavapipe, cubecl (Metal) on macOS, wasm e2e, image
and release-target builds); Linux-armv7 and Linux-arm-musl builds still running at that time (state UNSTABLE only for
those).

## 5. Files

`scripts/` (box scripts: `setup.sh`, `build.sh`, `builds.sh`, `ex.sh`, `t.sh`, `lvp.sh`, `atomcmp.py` from T26B);
`work/` (`lint_ivory.log`, `host_tests_ivory.log`, `cand_vs_int.diff` = `merge_vs_int.diff`, `p255.diff`,
`p259.diff`, `interdiff.txt`, `merge_vs_main.u0`, `fix_vs_oldmain.u0`, `conflicts.rs`, the five source files of the
merge-file step, `mu260.bundle`); `box/logs/` (every run), `box/out/` (`builds.txt`, `cmp_merge.txt`, `setup.out`
with the chroot's Mesa version, build logs). CubeCL compilation dumps (`spv.log` 158 MB, `wgsl.log` 109 MB) stayed on
the box, which destroys itself at about 10:45 UTC.

## 6. The counts that differ from 11-14 (written by the director; the engineer was stopped by a harness outage at about 07:35 UTC before writing this section)

- Same test, same field string, same partition count on both days (T26/RESULTS.md §5: b60 1e16 at
  `1447429612114824200908`, 8 partitions of slice 0; both logs print "2 slice(s), 9 per launch").
- **The 11-14 integration build (`8bcee21f`), built and run on this box today, gives today's numbers** [M]:
  `box/logs/GI_dense_b60.log`: survivors 336157460, checked 22524024; `box/logs/GI_top_fd_matches.log`: 422,559,183
  tops. So the code merged since 11-14 did not change them; the box did.
- Which input differs was not shown. The engineer's unfinished probe (`box/probe/probe_plan.rs`) was testing the
  likely cause: the test plans the field with `JoinLimits::for_buffer(device memory / 4).with_vram_budget()`, so
  the first slice's extent, and with it "8 partitions of slice 0", depends on the memory the card reports; the
  heavy FD comparison includes the same 1e16 field. Vast's "RTX 3080" covers 10 GB and 12 GB cards. [inferred]
- Whole-field totals do not depend on slicing: the production comparisons (T2.3, T28.1, and task 2 above:
  main `0711b163` equals yesterday's main on six base-62 fields exactly) are unaffected.
