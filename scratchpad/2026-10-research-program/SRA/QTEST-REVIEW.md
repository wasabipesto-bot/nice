VERDICT: MERGE (one optional wording fix and one optional log line below; nothing blocking).

Review of `pr/queue-test-plane-width` (fd33d84d on origin/main 974d7194), common/src/cubecl_backend.rs, 10+/2-.
Reviewer: independent, read-only (no build or run; logs read from window_1119).

## 1. Diagnosis

Correct.

- The kernel reads only word 0 of every ballot. `plane_ballot` returns `Vector<u32, 4>` (cubecl-core 0.10.0 plane.rs:487; 0.11.3 plane.rs:428), and every ballot use in the stride walk takes `bal[0usize]`:
  plane-scoped queue cubecl_backend.rs:961-963 (`bl0`) and 1112-1121 (`bp`, `bl`); cube-scoped queue 1351-1366 (`bp`, `bh`, `bl`). Ranks are `(word & lt).count_ones()` with `lt = (1u32 << UNIT_POS_PLANE) - 1` (980/1234). On a 64-lane plane, lanes 32-63 are not in the word, and for them the shift is by 32 or more, which is undefined in SPIR-V. A 64-lane plane cannot work in the ballot form.
- Production cannot pick the ballot form on a 64-lane device:
  `NiceonlyPlan.ballot = ballot_append(plane_size_max)` (cubecl_backend.rs:3042) → `ballot_append` returns `plane_size_max <= 32` (cubecl_join.rs:195-197) → `dispatch_ballot` (3313-3319) returns `plan.ballot` unless `ballot_override` is set. `ballot_override` and its check are `#[cfg(test)]` (3073-3074, 3314). Its only writer is `queue_partial_planes` (4320), a test helper. `plane_size_max` is the largest plane the driver may use, so it is the right (conservative) property.
- Logs: p_pr270.log has 64 runs, 32 wrong: every `ballot=true` run (2 bases x 2 queues x 4 cube sizes x 2 lane widths) fails with the account error. All 32 scan runs are exact. p_qtest.log has 32 runs, all `ballot=false`, 0 wrong. The brief says 16 forced-ballot runs failed. The log shows 32, so correct that count in the PR text.
- "Necessarily loud": not strictly. This is a caveat for the record. It does not block, because production never runs this form.
  - The plane-scoped queue exits on `plane_all(!have_range)` (full width), so upper-lane survivors are written and counted in `acc_n` but are not in `tot`/`qn`. The account catches that.
  - The cube-scoped queue's exit is `all_done = (tw >> 10) == 0` (1438-1439), and `tw` adds up `bh.count_ones()` (1357-1361, 1386), the lanes with ranges left, read from word 0 only. If every plane's lanes 0-31 run out of ranges while some lanes 32-63 still have ranges, the cube leaves the loop. The upper lanes' remaining candidates are then never generated, never queued and never counted. That is a silent loss the account cannot see.
  - The account also compares only counts and low-word sums mod 2^32 (`report_queue_account`, 1617-1636), so offsetting errors could in principle cancel. On the test's inputs every run failed loudly.

## 2. Same rule as production

Yes. The test calls the same function on the same property (`ballot_append(client.properties().hardware.plane_size_max)`, cubecl_backend.rs:4391) that `NiceonlyPlan::new` uses (3042). The scan form is always run as well. That is extra coverage, since a device of 32 lanes or fewer never runs scan in production.

- lavapipe: plane_size_max of 8 (16 on AVX-512 builds) is 32 or less, so both forms stay.
- CUDA: its test `cubecl_cuda_queues_check_every_survivor_on_partly_filled_warps` (4411-4421) is separate and unchanged. It is ballot-only, plus scan under `NICE_TEST_QUEUE_SCAN`. Warps are 32 lanes, so it is not exposed.

The same pattern (`if ballot { &[true, false] } else { &[false] }`) is already used in the join tests (cubecl_join.rs:6410-6411, 8108-8109). The change brings this test in line with its siblings.

## 3. Other tests that force the ballot form or assume planes of at most 32 lanes

None of the wgpu tests are exposed.

| Test | File:line | Form | Exposed on 64 lanes? |
|---|---|---|---|
| cubecl_check_counts_match_the_cpu | cubecl_join.rs:6398-6404 | `ballot_append` | no (gated) |
| cubecl_check_takes_every_entry_on_partly_filled_planes | cubecl_join.rs:6406-6413 | `ballot_append` | no (gated) |
| top_fd_appends_every_top_on_partly_filled_planes | cubecl_join.rs:8104-8111 | `ballot_append` | no (gated) |
| cubecl_queue_faults_fail_the_field (via `queue_faults`) | cubecl_backend.rs:4426-4460 | production plan | no (scan on 64 lanes) |
| cubecl_cuda_check_counts_match_the_cpu | cubecl_join.rs:6415-6431 | forced `true` | CUDA only, 32-lane warps: no |
| cubecl_cuda_check_takes_every_entry_on_partly_filled_warps | cubecl_join.rs:6433-6443 | forced `[true]` | CUDA only: no |
| cubecl_cuda_top_fd_appends_every_top_on_partly_filled_warps | cubecl_join.rs:8113-8127 | forced `[true]` | CUDA only: no |
| cubecl_cuda_queues_..._partly_filled_warps | cubecl_backend.rs:4411-4421 | forced `[true]` | CUDA only: no |
| the_ballot_append_is_for_planes_of_at_most_32_lanes | cubecl_join.rs:8256-8259 | pure unit test | no |

Other places that look like width assumptions but are not:
- The CUDA-only `assert_eq!(least, want)` on 32-lane warps (cubecl_join.rs:6386-6389).
- The `NICE_CUBECL_LANES <= 32` filter (cubecl_backend.rs:3448). That is lanes per range, not plane width.

No HIP device tests exist, so there is no HIP exposure. Only the test changed here was exposed.

## 4. Doc comment (cubecl_backend.rs:4371-4377)

It is accurate and plain. One wording fix (optional):
- "fails the account by design" makes the failure sound intended. Suggest: "...production takes the scan form there, and the ballot form forced on such a device fails (seen on an RX 9070 XT)". Alternatively, drop the clause.
- The first sentence still says "checked once, by ballot and by scan". The new sentence qualifies it, which is fine.

Optional, matching `plane_queue_runs` (4246-4248), which prints when it skips the plane queue: print a line when the ballot form is skipped. A 64-lane run's log would then show the coverage it did not run, e.g. `println!("{device}: planes of up to {w} lanes: the ballot form is not tested (production takes the scan form)")`.

## 5. Scope

There is one commit and one file, inside `mod tests`, under a test that needs `#[ignore]`/a wgpu device. No production code changes: `ballot_append`, `dispatch_ballot` and the kernel are untouched. The commit message is accurate.
