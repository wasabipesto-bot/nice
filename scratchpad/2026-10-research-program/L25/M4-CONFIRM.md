# L25 on the M4 "mayalaran": PR #228 confirmed, stride prefilter clean (2026-10-31)

**Test 1: the prediction holds.**
- **Without the fix.** 472c9a0 plus only the windows commit fails `cubecl_join_matches_the_cpu_reference` at b50. The
  device returns **0 join survivors where the CPU has 934**. The ad-hoc per-window run shows b54 fails the same way
  (0 vs 445). Every other window agrees.
- **With the fix.** The branch (`56b68bf`) passes the whole test, b50 and b54 included.
- **Reruns.** Both results reproduced on a second run.
- **`join_sample_runs_partitions_of_a_production_field`** (b57) passes on both trees, as expected: the b57 top word is 0.

**Test 2: the stride path's low-digit prefilter shows no fault on this M4.**
- `cubecl_prefilter_survivors_match_the_host_mirror` (b30/b34/b40) passes on main's stride code, twice.
- `cubecl_matches_cpu_niceonly`, `cubecl_cross_filter_survivors_match_the_host_mirror` and
  `cubecl_niceonly_finds_69_in_base_10` pass too.

## Machine

- **Hardware.** Apple M4 (10 CPU cores, 10 GPU cores, Metal 4), 16 GiB, on AC power. Load average was about 1.1
  before I started, and no process was above 5 % CPU.
- **OS.** macOS 26.3 (25D125), the build of the 10-06 and 10-30 sessions.
- **The user's work.** The user's `SCREEN -S nice` session was present, with an attached `screen -r nice` login from
  100.100.130.95. No `nice_client` process was running. I left it untouched.
- **Toolchain.** Rust 1.99.1 (`58cf8f9c3`), selected by `rust-toolchain.toml` and already installed. No
  `RUSTUP_TOOLCHAIN` override.
- **GPU stack.** wgpu → naga WGSL → MSL → Apple's compiler. The device reports as `Apple M4 (Metal, wgpu<wgsl>)`, an
  IntegratedGpu on the Metal backend. `cubecl-metal` was not enabled.

## Trees and builds

- **Trees.** Both were built on ivory from local commits (nothing pushed) and copied over with `git archive`.

| tree | commits | role |
|---|---|---|
| A | 472c9a0 → `a115c3b` (cherry-pick of 56b68bf, the windows) → `a8aca8b` (diagnostic) | main + windows |
| B | 472c9a0 → ed972c7 (fix) → 56b68bf (windows) → `33db915` (diagnostic) | the branch |

- **The diagnostic commit** adds one ad-hoc `#[ignore]` test, `zz_l25_windows_each`, at the end of
  `cubecl_join::tests`. It is local only and was deleted with the Mac directory; the source is
  `raw/m4/diag_body.rs`.
  - It runs the same comparison as `check_window` over the b10 band and every `WINDOWS` entry.
  - It totals each window instead of panicking at the first difference.
  - Its only difference between the trees is a `L25TREE-A`/`L25TREE-B` label string.
  - `git diff A B` is exactly ed972c7 plus that label line. `common/src/cubecl_backend.rs` in tree A is identical to
    472c9a0, so Test 2 ran main's stride code.
- **Offline build.**
  - `CARGO_HOME` was inside the work directory: an APFS clone of `~/.cargo/registry` (`cp -cR`, 4 s).
  - I added ivory's `.crate` files with `rsync -a --ignore-existing`: 1,864 files, 403 MB, 82 s.
  - I added ivory's index with `rsync -a --update`: 1,058 files, 55 MB, 14 s.
  - After that, `cargo test --release --offline -p nice_common --features cubecl --no-run` built with no network.
- **Build times.** A took 91 s with cold dependencies; B took 56 s with `cargo clean -p nice_common` first. Both
  shared one target dir.
- **Binaries.** Each was copied out after its build, since cargo reuses the same `nice_common-d0848b236b51588b` slot.
  - They are verified by string: A's binary contains `L25TREE-A` once and `L25TREE-B` zero times, and B's the reverse.
  - sha256: A `46797cab…a4fb`, B `80a058cd…5f24`.
- **No build warnings.**

## Test 1: PR #228, the join's top kernel

- **Command.** The test binary run directly: `<bin> <filter> --ignored --test-threads=1 --nocapture`, from `common/`.
- **The windows.** b50 is `[62082117268529817, +3e5)` with (7,4,1), and b54 is `[2321864499473908801, +3e5)` with
  (8,4,1).

| tree | test | result | time |
|---|---|---|---|
| A (main + windows) | `cubecl_join_matches_the_cpu_reference` | **FAIL** at b50 | 9.4 s to failure |
| A, rerun | same | **FAIL**, identical message | 8.2 s |
| A | `zz_l25_windows_each` | **2 of 20 windows differ: b50 and b54** | 16 s |
| A | `join_sample_runs_partitions_of_a_production_field` | pass | 0.6 s |
| B (branch) | `cubecl_join_matches_the_cpu_reference` | **pass** | 39.9 s |
| B, rerun | same | **pass** | 38.4 s |
| B | `zz_l25_windows_each` | 0 of 20 windows differ | 15 s |
| B | `join_sample_runs_partitions_of_a_production_field` | pass | 0.5 s |

**Tree A failure message:**
```
assertion `left == right` failed: b50 [62082117268529817, 62082117268829817) JoinParams { t: 7, k: 4, p: 1 } partitions [0, 48, 49]: join survivors differ
  left: 0
 right: 934
```
Every window before b50 had passed: b20 ×3, b25 ×2, b30, b34 and b40 ×2. The test stops at b50, so it never reached
b54, the b57-64 windows, the tight, sliced and refused layouts, or the production shape.

**Tree A, per window (`zz_l25_windows_each`; device against CPU):**

| window | live partitions | join survivors (GPU / CPU) | prefilter survivors (GPU / CPU) | hits | verdict |
|---|---|---|---|---|---|
| b10 band [47, 100) | 1 | 1 / 1 | 1 / 1 | 1 / 1 (69) | agrees |
| b20 ×3, b25 ×2 | 1-90 | 1,496, 1,599, 1,461, 4,251, 842: equal | 139, 135, 124, 137, 30: equal | 0 | agree |
| b30, b34 | 90, 87 | 0 / 0 | 0 / 0 | 0 | agree |
| b40 (6,5,2), (7,4,2) | 90, 95 | 4 / 4, 5 / 5 | 0 / 0 | 0 | agree |
| **b50 (7,4,1)** | 3 | **0 / 934** | **0 / 97** (97 missing, 0 extra) | 0 / 0 | **DIFFERS** |
| **b54 (8,4,1)** | 3 | **0 / 445** | **0 / 51** (51 missing, 0 extra) | 0 / 0 | **DIFFERS** |
| b57 ×3 | 57, 2, 3 | 0, 0, 405: equal | 0, 0, 36: equal | 0 | agree |
| b58, b60, b64 | 90, 84, 74 | 204, 0, 362: equal | 20, 0, 37: equal | 0 | agree |

- **How b50 and b54 fail.** The device loses every survivor and adds none. That fits wrong top certificates that
  reject every top in these windows. It is the lost-survivor direction the AUDIT warned could miss a nice number.
- **Tree B.** It matches the CPU in all 20 windows, with the same counts as the CPU column above, including b50
  934/97 and b54 445/51.
- **The rest of B's test.** These all agree on B:
  - the b57 frontier field (partitions 0, 1000, 3248);
  - the tight layouts (b20 ×3, b25);
  - 5 windows sliced;
  - refused layouts at b20, b25, b50 and b54 (ceilings 512-688 MiB);
  - the b57 production shape, tight and refused.
- **join_sample.** Partition 1000 of the b57 frontier field gives (1,486,824 join survivors, 82,672 checked) on the CPU,
  the production layout and the 4-slot layout, on both trees.

## Test 2: the stride path's low-digit prefilter (AUDIT §3 site (c), main's code)

- **The probe test.** The "prefilter probe test" from August is `cubecl_backend::tests::cubecl_prefilter_survivors_match_the_host_mirror`.
  It reports every candidate the prefilter passes, at every lane width, and checks them against a u128 host mirror.
- **Binary.** All four tests ran on tree A's binary, whose `cubecl_backend.rs` is 472c9a0's.

| test | result | detail |
|---|---|---|
| `cubecl_prefilter_survivors_match_the_host_mirror` | **pass** (twice) | b30: 396 of 159,058 candidates survive; b34: 2,099 of 350,205; b40: 4,472 of 288,591; every lane width equals the mirror |
| `cubecl_matches_cpu_niceonly` | **pass** | 5e6 at each range start: b10 (1 nice: 69), b12, b25, b40, then b45, b62, b80, all 0 nice and equal to the CPU |
| `cubecl_cross_filter_survivors_match_the_host_mirror` | **pass** | b40 (prefilter base) and b50, each compact/plane variant the test selects for this device (the log prints only `ok`) |
| `cubecl_niceonly_finds_69_in_base_10` | **pass** | |

- **Bases ≤ 40.** `cubecl_matches_cpu_niceonly` can't be narrowed to bases ≤ 40 without editing it, so it ran its full
  list. Of its bases, b25 and b40 run the prefilter, at their range starts only.
- **What this does not cover.** The probe test covers b30/b34/b40 at their range starts; no window was run mid-range.
  The stride offset-reduction gap (`off_hi ≠ 0`, AUDIT §5) stays untested; the existing windows are 5e6 wide.

## Machine time and cleanup

- **Machine time.** About 8 minutes in total.
  - First ssh at 14:59:34 UTC; the jobs ran from 15:01:36 to 15:06:49.
  - Cleanup finished at 15:07:04 and the final check at 15:07:15.
  - A local polling monitor kept making read-only `cat` connections until I stopped it at about 15:07:40. Its exit
    check had missed the end of the pipeline. It found no files.
- **Watchdog.** It started in the first ssh with a sleep of 3,460 s, a deadline about 57.7 min after the first ssh.
  - Every job ran under a wrapper that registers its PID and removes it on exit.
  - At cleanup the PID file was empty.
  - I killed the watchdog `sh` (88057) and then its `sleep` (88060), parent first, and confirmed both gone.
- **Directory.** `~/claude-exp-2026-10-31-top` was removed: `test -e` reports it gone, and `~/claude-exp-*` matches
  nothing.
- **One file outside the directory.** The final process listing went through a temporary file, `/tmp/.ps.90075`. It was
  deleted in the same command, and a later `test -e` confirmed it gone. Nothing else outside the directory was touched.
- **Processes.** The final `ps` showed no process of mine other than that check's own login shell.
- **Nothing was pushed.**

## Files (`raw/m4/`)

- `logs/`: every job log and its status file.
  - `build-{A,B}.log`, `testbuild-{A,B}.err`;
  - `A-join.log`, `A-join-r2.log`, `A-diag.log`, `A-sample.log`;
  - `B-join.log`, `B-join-r2.log`, `B-diag.log`, `B-sample.log`;
  - `T2-*.log`;
  - `pipeline.log`.
- `setup.sh` / `setup.out`: the first ssh, with the watchdog start and machine facts.
- `pipeline.sh`, `build.sh`, `test.sh`, `run.sh`, `env.sh`: the harness.
- `diag_body.rs`: the ad-hoc per-window test.
- `TREE_COMMIT_{A,B}`, `timeline.log`, `cleanup.out`.
- **Local commits.** The two trees are still in `/home/claude/l25-m4/repo` (branches `treeA`, `treeB`, `treeA-base`,
  `treeB-base`). It is a scratch clone and can be deleted.
