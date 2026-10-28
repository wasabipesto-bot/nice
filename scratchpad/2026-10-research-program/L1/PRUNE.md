# L1 follow-up: drop the bottoms that meet the field's certificate (2026-10-28)

Branch `rp/field-cert-prune` on the fork (`wasabipesto-bot/nice`), on origin/main `85b5b4e`:

| commit | what |
|---|---|
| `71a085e` | test only: the throughput harness takes bases 58 and 62 (`THROUGHPUT_STARTS`) and `NICE_TEST_JOIN_SIZE`. This is the **A** tree of the A/B, so both trees run the same harness. |
| `c1174c1` | the prune |
| `e252bf4`, `c1306b5` | test only: the prune check takes `NICE_TEST_PRUNE_FIELDS`; a lint allow |

**Status: implemented and exact on the CPU. The GPU A/B was NOT run: instance 58053611 refused ssh (`Permission denied (publickey)`) from creation (05:25 UTC) to at least 05:52 UTC.** See "Not done".

## What changed

- `common/src/overlap_join.rs`
  - `FieldSetup` gains `fc: u64` (≈ l. 861–868), the field's certificate `base.cert(s, e − 1, k)`, computed in `top_side` (≈ l. 1005–1027). If that certificate fails (a repeated constant digit), `fc = 0` (no prune). The top layer is then already empty: every top certifies a sub-interval, so its digit set is a superset and fails too. A `debug_assert` checks that. An empty `tlay` already returns early on both paths (`cpu_join` l. 383, `cubecl_join` `run_slice` l. 1997).
  - `FieldSetup` gains `bp_all: Arc<(Vec<u32>, Vec<u64>)>` (≈ l. 875–878): `bpre` before the prune, sorted by class as before.
  - New `FieldSetup::prune_bottoms` (≈ l. 966–1003) keeps the entries with `m & fc == 0` and rebuilds `seg`. It logs `keeps X of Y bottom prefixes` at debug level.
  - `FieldSetup::new` prunes `bpre` by its own `fc`.
  - `sub_range` re-prunes `bp_all` by **the slice's own** `fc`. This is needed for soundness. `plan_join` builds a probe over the first prefix block only, then `sub_range`s the first slice from it, and `run_field` `sub_range`s later slices from the first slice's setup. So a parent's certificate is not in general a subset of a slice's, and reusing the parent's pruned list would drop live bottoms.
- `common/src/join_plan.rs` `Footprint::with_prefixes` (l. 168–170): `nbp` is `bp_all`'s length, the unpruned count. Buffer sizes, slots per launch and slice caps are therefore identical to main, and fit every slice.
- `common/src/cpu_join.rs`
  - `extend` (l. 469, 487) tests each fixed partition digit against `mask | fc`.
  - `list` (l. 573, 582) tests the last (key) digit against `mask | fc`.
- `common/src/cubecl_join.rs`
  - `bucket_kernel` takes `fc_lo, fc_hi: u32` (l. 155–156, 165). The partition-digit test uses `(m | fc) & bb` (l. 231). The key-digit test uses `mf = m | fc` (l. 239–241, 265).
  - `JoinDevice` stores `fc: [u32; 2]` (l. 1276, 1436–1439) and passes it to the launch (l. 1625–1626).
- Unchanged: the AND, `ext_m` (the bottom's own mask, which the AND and the full check's known-LSD mask read), the reference `join_range`, and every kernel but `bucket_kernel`.

## Exactness evidence (ivory, CPU, release build)

- New unit test `cpu_join::tests::the_field_prune_drops_exactly_the_bottoms_that_meet_the_certificate`, on every `PLAN_FIELDS` field. It asserts:
  - `fs.fc == cert(s, e − 1, k)`;
  - `fc = 0` prunes nothing;
  - pruned `bpre` (class, residue, mask) == unpruned `bpre` filtered by `m & fc == 0`;
  - on 2 live partitions per field and every key digit, the CPU's bottom lists (key, class, residue, full mask, carries) == the unpruned lists filtered by `mask & fc == 0`.
  - It passes on PLAN_FIELDS, on the four throughput fields at 1e14, and on the eight L1 fields (1e15 b58, 1e16 b60–64). Log: `prune-raw/ivory-bottoms-before-after.log`.
- Existing tests, unchanged:
  - `cpu_join::`, `overlap_join::` and `join_plan::` unit tests: 19 passed (`prune-raw/ivory-cpu-unit-tests.log`).
  - `cpu_join_matches_the_reference_on_production_fields` with `NICE_TEST_CPU_JOIN_REF=2`: passed, b42–b64 (`prune-raw/ivory-cpu-join-ref-production.log`). It asserts equal join survivors, equal prefilter survivors and equal hits against the unpruned reference join.
- Lint: `cargo fmt --check` is clean. `cargo clippy --release -p nice_common --all-targets -- -D warnings` (default features) is clean (`prune-raw/ivory-clippy-default.log`). The GPU-feature clippy (`gpu,vulkan,cubecl-spirv`, as `just lint`) was planned for the box and was **not run**. The CUDA kernel change has therefore **not been compiled yet**.

## Bottoms before / after the prune (CPU lists = the GPU's per-key lists)

Listed bottoms per partition, summed over all key digits, mean of 2 partitions; `bpre` is per field.

| base | field | size | fc digits | bpre before → after | listed bottoms before → after | pruned |
|---|---|---|---|---|---|---|
| 58 | item 18 (130525…) | 1e14 | 6 | 142,260 → 76,236 | 3.17M → 0.78M | 75.5 % |
| 60 | THROUGHPUT (1573714…) | 1e14 | 6 | 137,775 → 76,708 | 3.23M → 0.86M | 73.4 % |
| 62 | PLAN (7997740…) | 1e14 | 8 | 176,671 → 65,394 | 4.50M → 0.61M | 86.3 % |
| 64 | PLAN (41242006…) | 1e14 | 9 | 180,003 → 78,784 | 4.85M → 0.73M | 85.0 % |
| 57 | FRONTIER_57 | 1e14 | 6 | 133,645 → 54,885 | 2.86M → 0.53M | 81.5 % |
| 50 | PLAN | 1e14 | 2 | 71,034 → 57,717 | 1.16M → 0.70M | 39.7 % |
| 42 | PLAN | 1e13 | 0 | no change | no change | 0 % |
| 58 | item 18 / item 23 | 1e15 | 5 / 4 | 142k → 84k / 87k | 3.17M → 0.98M / 1.16M | 69.0 / 63.3 % |
| 60 | item 23 / plan | 1e16 | 5 / 4 | 138k → 86k / 101k | 3.23M → 1.08M / 1.47M | 66.6 / 54.6 % |
| 62 | item 23 / plan | 1e16 | 5 / 6 | 177k → 106k / 95k | 4.50M → 1.49M / 1.16M | 66.8 / 74.3 % |
| 64 | item 23 / plan | 1e16 | 7 / 7 | 180k → 72k / 94k | 4.85M → 0.87M / 1.11M | 82.0 / 77.1 % |

- The 1e15/1e16 rows reproduce RESULTS.md's `prune_window` column (68.8/63.2, 66.2/54.6, 66.8/73.7, 82.2/76.8 %, weighted by ANDs there and by bottoms here).
- At production size (1e14) the field knows 6–9 digits, and the prune removes **73–86 %** of the bottoms at b58–b64.

## A/B on the GPU

Not run (see below). Scripts are ready in `prune-raw/box/`:
- `setup.sh`: builds `/root/main` at `71a085e` and `/root/prune` at `c1306b5`, client and test binaries;
- `thr.sh TREE TAG SIZE FIELDS BASES`: one throughput-harness run;
- `nicemark.sh TREE ROUND`: NiceMark, 150 s, JSON on stdout.

## Verdict

Pending the GPU A/B. On the CPU, RESULTS.md bounds the saving at the AND share times the skipped fraction: 7–12 % at b58–b62 and about 20 % at b64 at the L1 sizes. At 1e14, where 73–86 % of the bottoms go, the bound is a little higher. That clears the 5 % bar on the CPU's arithmetic but is not measured here.

## Not done

- **No GPU measurement and no CUDA compile.** `ssh -p 35942 root@ssh6.vast.ai` (from `vast.py ssh 58053611`) answered `Permission denied (publickey)` on every try from 05:31 to 05:52 UTC, offering `~/.ssh/id_ed25519`. The instance showed `running` throughout. That matches the known "host sshd refuses keys" failure in the fleet notes. I may not run other vastai commands (attach, logs, destroy), so I could not fix or replace it.
- `CARGO_TARGET_DIR` was shared with `.worktrees/rp-l1` as instructed. Both worktrees are `nice_common v3.4.6`, so the test binary `nice_common-ff746edb5f48128a` there is now this branch's build, not `rp/l1-selectivity`'s. Rebuild in rp-l1 before reusing it.
