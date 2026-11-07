# L46 review: static bucket order (`pr/join-static-buckets` 318fdae) and the rider (`exp/join-static-buckets-s15` 4b27507)

Reviewer: independent, read-only on the branches (2026-11-07). Base f3fb390 (main 6f060a9 + #241 + #246). Line
numbers are `common/src/cubecl_join.rs` at 318fdae unless marked.

## Verdict: merge with small fixes

The design is correct. The bucket algebra holds for every base and both key modes. I checked it on the host against
`cpu_join`'s bucket rule on 24 fields, simulating the join's u32 segment arithmetic exactly; every bucket matched. A
segment cannot overflow. The sort does not interact with #240's stepping, which steps partitions, not prefixes.
The join's segment walk covers every top once. Every measured number in the body matches the raw logs. The fixes
are small: a missing CHANGELOG line, one inaccurate paragraph in the body (registers), a stale doc comment, a
misleading variable name, and two test-hardening items. The rider is correct and exact. It can go in as a second
commit if the body gets a section for it. Otherwise it should be its own PR.

## Findings by severity

### Fix before opening (small)

1. **No CHANGELOG line.** The diff touches only `cubecl_join.rs` and `join_plan.rs`. Each of #240, #241 and #246 added
   one line under Unreleased (see `git show --stat 7832f89 f3fb390 6f060a9`). Add a short one, with the number once
   the PR is open. For example: "Speed up the GPU overlap join by sorting each slice's top prefixes once by the
   buckets they feed, so the tops need no bucketing pass and the join reads each bucket's tops in order
   ([#NNN](…))." If the rider goes in, add half a sentence for it or a second line.

2. **The body's register paragraph reads as if production is safe from the spill variant; the data says it is not.**
   - #246's join never spilled under the runtime compile: 37 of 37 images here, and 100 of 100 processes in the
     previous session.
   - This PR's join compiles to 40 registers plus 8–32 B of spills in 7 of 37 images. The intermediate trees did too
     (S2 1 of 9, S4 5 of 9, in `raw/box/logs/regsample.txt`). So the 47↔48 wobble was there before, but **the
     spilling variant is new**.
   - `join_params_for` gives the **same JoinParams at 1e14 and at 1e16/1e17** for b57/60/62/64 (b62: t 10, k 6, p 2
     at all three sizes; checked on the host). So the 1e14 processes and the production processes compile the same
     join kernel. That 0 of 12 production processes spilled is probably chance: at ~19 % per process, 0 of 12 has
     about an 8 % chance.
   - "Those runs were no slower" is not quite what the data shows. Against the same field's spill-free S5 runs, the
     4 spilling A/B processes were −2.7 % (b57), +1.0 % (b60), +1.8 % (b62) and +1.7 % (b64) in device time. All of
     that is inside the 1e14 runs' 2–4 % spread.

   Suggested text: "In about one process in five, the driver's JIT allocates the join 40 registers and spills 8–32 B
   in the per-work-item and per-wave code (not in the chunk loop or the walk). #246's join never did. The kernel is
   the same at every field size, so production processes will get this variant at about that rate. Where it
   occurred (1e14 fields), the runs were within their 2–4 % spread." Optionally pin a spilling image and time b62
   1e17 against a clean one, as was done for #246's nvcc spill variant (it cost about 1.5 % of a field there).
   Either way, it does not change the merge decision.

3. **If the rider goes in:**
   - Its commit subject "(rider, measured separately)" is internal jargon, and the commit has no body. Retitle it
     "Overlap join: check the survivor stage once per top batch", with a 3–5 line body (why, ×1.022–1.030, exact).
   - In the PR body, move it from "Not in this PR" to its own section with the S5-vs-R table and the NiceMark ×1.019
     (2 rounds).
   - It cherry-picks cleanly: 4b27507's parent b058bb7 has the same tree as 318fdae (`8a16709`).

### Should fix (low)

4. **Stale doc, cubecl_join.rs:82–84** (`TOP_REC_WORDS`): "The join gathers a batch's tops by their ids". It now reads
   them in order from the segments; only the check kernel still reads a record by its index. Suggested: "The join
   reads a bucket's tops record by record, and the check reads one by its index, so a top's words are one sector of
   one array rather than one from each of three."

5. **Misleading name, cubecl_join.rs:2719**: `let g = top_slot(...)` binds the **record index**. Throughout the change,
   `g` means the group (`tl_g`, `top_kernel`'s `let g = tlay[5i+2]` at 1906, the doc comments). Rename it to `at` or
   `rec`. `top_slot`'s own doc says it returns "a kept lane's record index".

6. **Test hardening, `run_tops` (6170–6181).** `top_rec` is never cleared between the `top_kernel` run and the FD runs.
   - A kernel that bumped a group's counter but skipped a record write would read back the other kernel's stale
     record at that index.
   - Under the sorted layer, both kernels tend to put the same top at the same index: per-group counters, and planes
     of one group appending in lane order. So such a bug can now be masked.
   - The issue was there before (the old test didn't clear `top_rec` either), and the end-to-end parity tests would
     still catch it.
   - Fix: write a sentinel over `top_rec` (e.g. `0xFFFF_FFFF`) before each `launch_top` in `run_tops`.

7. **No test pins the host sort or the join's segment formula on their own.** The FD-vs-`top_kernel` device test
   recomputes each record's group with the same formula as `sorted_layer`. It does not compare that formula with the
   CPU join's buckets; only the end-to-end parity tests do, and they need a device. A host unit test is cheap and
   runs in the plain `cargo test` job. Mine is at `L46/raw/review/sorted_layer_host_test.patch` (applies to
   318fdae). It checks:
   - `goff`, and that the sort is a stable permutation;
   - words 2–4;
   - for each sampled partition, kept subset and two slot offsets (u32 wrap included): the join's
     `s_db`/`s_cum`/`select` mapping, simulated in u32, gives exactly `cpu_join`'s top multiset for every bucket
     `(key, (root + m1 − pc) mod m1)`;
   - that a bucket's `nroots` groups are distinct.

   It takes 52 s in debug over 24 fields. For CI, trim it to the windows plus two 1e14 fields with ~8 partitions
   (a few seconds).

### Nits and follow-ups (no change needed to merge)

8. **`top_slot` aggregates on lane 0's group (1741–1742), whether or not lane 0 is live or kept.** Some planes
   therefore fall back to per-lane atomics even when all their kept lanes share a group:
   - the last, partial plane of the layer (dead lanes have `tl_g = 0`);
   - planes whose lane 0 is out of range;
   - planes whose lane 0 sits in the previous group.

   This is correct, only slower. Keying on the first kept lane would fix it, but it is not worth a re-measure now.

9. **`sorted_layer` (3105–3150):**
   - `pdiv_m1` (3112) is always 1, because b ≡ 1 (mod b−1); the multiply at 3124 is dead arithmetic (harmless, and it
     documents the rule).
   - `group()` is computed twice per prefix, and `p0s` is an extra 8 B/prefix temporary.

   This is host-side and off the critical path: later slices are prepared while the previous one runs, and it
   replaced three u128 mods per prefix.

10. **`top_kernel` went from 80 to 97–103 registers.** At 256 threads that is 3 → 2 cubes/SM on GA102. Its timing was
    neutral at b60/b62, but there `top_kernel` is not the production top stage. At b64 it is, and it was not timed on
    its own: the field's ×1.22 includes it. A follow-up could time the b64 top stage. The body's "Its timing above is
    unchanged" is literally true, but it refers to the b60/b62 timings.

11. **Bindings.** The join now has 15 storage buffers (was 13), plus CubeCL's info buffer. That is within Metal's 31
    and desktop Vulkan/DX12 limits. No browser path uses the join (the wasm client doesn't import it). No action.

12. **L48 overlap.** L48 rewrites `top_fd_kernel`'s stepped arithmetic. This branch replaces only the append block
    (2718–2730) and the kernel's argument list. Whichever lands second rebases the append and the FD test helper.
    That is mechanical.

## The checks, item by item

### 1. Bucket algebra

- **The old rule.** Both top kernels computed `pc = (tlay[5i+2]·pdiv_m1 + v) % m1`, where:
  - `tlay[5i+2] = P0 mod (b−1)`;
  - `pdiv_m1 = b^p mod (b−1)` (`JoinDevice.pdiv_m1 = pdiv % m1`, with `pdiv = fs.nparts = b^p`);
  - the key is `tlay[5i+3] = P0 mod b` at the key level, else 0.

  Each kept top counted `bucket_cnt[slot·nb + key·m1 + (root_r + m1 − pc) % m1]` for every root. `top_fill_kernel`
  listed it in the same buckets, reading the `pc | key<<8` word back from `top_b`.
- **The CPU rule.** `cpu_join::run`: `c = (root + m1 − top.pc) % m1` with `top.pc = P mod (b−1)`, at key `P0 mod b`
  (`key_of = p0 % keyspace`). The reference join is the same, with `bx = key·m1 + (root + m1 − pc) % m1`.
- **Why the rules agree.** b ≡ 1 (mod b−1), so b^p ≡ 1 for every p ≥ 0 at every b ≥ 3, and `pdiv_m1 = 1` always.
  Then `pc = (P0 + v) mod (b−1) = P mod (b−1)`.
- **Which groups a bucket takes.** Bucket (key, cls) of slot v gets prefix P0 iff key(P0) = key and cls ≡ root_r − c0
  − v for some r, i.e. c0 ≡ root_r − cls − v. That is the join's `(roots[r] + 2m1 − cls − v % m1) % m1` (587). There
  is no u32 underflow: 2m1 − cls − v mod m1 ≥ 2, and roots < m1.
  - The roots are distinct residues in [0, m1): `Base::try_new` filters `0..m1`. So a bucket's `nroots` groups are
    distinct, and each kept top is in exactly `nroots` buckets, as before.
  - Most roots at any base ≤ 64: 8 (b46, b50, b64). b58 has 4, b60/b62 have 2, b57 has 6. The host check
    `nroots ≤ MAX_ROOTS` is at 3227.
- **Key level.**
  - `key_level` ⇔ o − p = 1, and `nb = b^(o−p)·m1`, so nkeys ∈ {1, b}.
  - `sorted_layer` checks that nkeys·m1 = nb (3107). The join's comptime `nbk = nkeys·m1` (574) therefore equals the
    top kernels' `nb`.
  - When not at the key level, `dkey` = 0 everywhere and the group is just c0.
  - The host test covers both modes (key level false: the b20 (2,3,1), b25 (3,4,2) and b50–b64 windows).
- **Clipped tops.** `top_kernel(only_clipped)` reads the same tlay words 2–3 and the same `grp_cnt` (1906–1909), so its
  tops go into the same segments. The FD kernel never keeps a clipped pair (`res[0] = 0` when `clipped`), and
  `only_clipped` keeps only clipped pairs. So each (prefix, slot) is certified by exactly one launch. The device test
  covered 23 batches with a clipped block (lavapipe: 20).
- **Capacity: a segment cannot be exceeded.**
  - Thread i owns sorted prefix i.
  - The FD grid's y dimension partitions the slots into groups; the `top_kernel` grid has one y per slot.
  - With FD, the two launches split the (prefix, slot) pairs between them (unclipped / clipped).
  - Each visit appends at most one record, at a distinct `at`: an aggregated `fetch_add(n)` plus the exclusive
    prefix, or a per-lane `fetch_add(1)`.
  - Hence `grp_cnt[s][g]` ≤ |{prefixes in g}| = goff[g+1] − goff[g], and records lie in [goff[g], goff[g] + cnt).
- **Empty group.** goff[g] = goff[g+1], no thread carries g, and its count stays 0 (the buffer is zeroed per batch).
  The join reads 0 tops from it: equal `s_cum` entries, and `select` lands on the later segment.
- **`top_slot` itself.**
  - `one` is plane-uniform (`plane_all`). When it is false, `kc` = 0 everywhere, `n` = 0, and lane 0 takes no atomic.
  - A dead lane 0 (g = 0) can only aggregate kept lanes that really are in group 0.
  - It is called in plane-uniform control flow: the slot loop's bounds come from `CUBE_POS_Y`, and every unit runs
    it (2512–2719).

### 2. Host sort, offsets, and the FD kernel

- **Sort.** A counting sort, stable (3126–3149); `goff` is nb + 1 words, `goff[nb] = ntlay`.
  - Stability is not needed for correctness: a bucket is a set, and `read_hits` sorts.
  - It only keeps P0 ascending within a group, which is what makes most planes single-group.
- **tlay words 2–3.** They held `P0 mod (b−1)` and `P0 mod b`, read only by `top_kernel`/`top_fd_kernel` to form
  `pc`/`key`. They now hold `g` and `goff[g]`, read by the same two kernels and nothing else. Word 4 is unchanged.
- **Original order.** Nothing indexes the device layer by its original order.
  - `clip_vs` comes from plo/phi (3259–3268); `top_expect` and `top_fd_groups` depend on `ntlay` only.
  - Slices (`sub_range`) and overflow splits (`run_partition` halves `fs.tlay` in host order) each build a fresh
    `JoinDevice`, and so a fresh sort. The dense b62 test ran 2 slices.
  - The CPU join and the test references read `fs.tlay` (host order), which `sorted_layer` leaves alone.
- **The FD kernel: the brief's premise doesn't match the code.** #240 does not step consecutive prefixes. Thread i
  owns prefix i and walks *its own* P = P0·b^p + v through its slot group. It steps when
  `valid && v == prev_v + 1` (2665): consecutive partitions of one prefix, P → P + 1, whose key is fixed. There is no
  shared memory and no neighbour lane in the certificate path; only the final append uses plane ops. So reordering
  prefixes cannot touch the seed/step logic. It changes only which prefixes share a plane: P0 values ≡ g
  (mod b(b−1)), 3,782 apart at b62, instead of adjacent ones.
- **What ×1.054–1.060 implies.** The absolute saving per slot is the same whether a slot stepped or was seeded:
  - b62: 0.0118 ns (consecutive) and 0.0110 ns (every other, a seed per slot);
  - b60: 0.0130 and 0.0115 ns.

  So the gain is in the append (`nroots` counting atomics and the `top_b` store gone). The new lane grouping costs
  nothing visible in either the step path or the more data-dependent seed path. It cannot rule out a small
  divergence cost hidden under a larger append saving; separating the two would need the sorted layer with the old
  append, and that isn't worth doing.

  `top_kernel` (full launch, b60/b62) lost the same work but stayed neutral. It gained a non-aggregated per-top
  atomic (the address is data-dependent, so the compiler can't aggregate it, and neighbouring lanes now share it)
  and ~20 registers. See item 10.

### 3. The join's segment loop

- **Barriers.**
  - Barrier 1 (584) orders the item's writes after every thread's last read of the previous item's
    `s_cum`/`s_db`/`s_hd`: the batch-loop exit test, and the per-wave `s_hd` reads.
  - Barrier 2 publishes the per-root offsets and counts to thread 0's serial scan.
  - Barrier 3 publishes the scan. The scan leaves `s_cum` exclusive-cumulative and `s_db[r] = start_r − cum_r`,
    which may wrap; it unwraps in `s_db[sr] + q`.
- **Coverage.**
  - `sr` = the last j with `s_cum[j] ≤ q` (630). Since `s_cum` is non-decreasing and q < total, q lies in segment
    `sr`, and empty segments in between are skipped.
  - The batches take q = 0..total in 256s (`tc`), so every position is covered once, and the batch shapes are the
    old ones.
  - Simulated exactly (u32, slots 0 and 3) on the host for every bucket of every sampled partition: a bijection onto
    the union of the segments, equal to the CPU buckets.
- **The rest.**
  - `nroots` is comptime (one kernel per base anyway). Loops over `1..nroots` and `0..nroots` are fine at 1 or 0
    roots.
  - The loop bounds `while tc < s_cum[nroots]` and `while ws < s_hd[2]` are uniform shared reads, constant within
    the item.
  - `v_part` from `vs[slot]` is exact because `v_digits ≤ p`: `key_level` gives p = k − 1 − f0, and
    `v_digits = min(k−1−f0, mid+1−f0)`.
  - Shared memory grows by 21 words (84 B). At ~1 item per cube in production (nwork = 5·3782 at b62 1e17), the 3
    barriers per item cost nothing measurable.

### 4. The adapted device test

`run_tops` (6170–6220):
- It returns per-(slot, group) counts and, per slot, the sorted (group, 8 record words) of every segment's first
  `count` records.
- It asserts that `count` fits the segment and that every record's `P / b^p` belongs to the segment's group.
- The comparison is complete for what both kernels write. Gaps: items 6 (stale records) and 7 (no test of the sort
  and formula against the CPU rule). No test shuffles the input layer. The host patch checks the sort's
  postconditions instead, and the sort is a pure function of `fs.tlay`.

### 5. Registers and spills

The body's numbers are right (`raw/box/logs/ptxjit_ab.txt`, `regsample.txt`, `ptxjit_S5.txt`; recounted):
- join: 30 of 37 spill-free at 46–48 registers; 7 at 40 registers with 8–32 B of spills (4 A/B 1e14 processes, 2
  register samples, 1 in the 4-base process).
- `top_fd_kernel` 108–112, `top_kernel` 97–103 (base 80).

What it needs is the framing in item 2:
- The 47↔48 wobble is pre-existing (it moves with CubeCL's per-process ordering of the shared arrays).
- The 40-register spill variant is new.
- It is not specific to 1e14, because the kernels are identical across field sizes at each base.

### 6. The rider (4b27507)

- **What it changes.** It moves the two barriers, the count read and the conditional flush from the end of every
  chunk to after a batch's last wave (rider file lines 979–1010). The `s_cw` clear now sits after the first of
  those barriers, which orders it after every thread's last chunk read. All barriers stay in uniform control flow.
  `s_t` holds global record indices, so deferring the flush across batches and work items is safe.
- **Can the stage overflow? Yes, and overflow is handled exactly.** The stage cannot be shown not to overflow: a
  batch can produce up to 256 tops × `ne` passes, far above `SURV_SH_CAP` = 1024. But:
  - a pass past the stage goes straight to the list (`surv_count` atomic, written only if `g < surv_cap`);
  - `s_cnt` keeps counting, `flush_survivors` copies `min(sc, SURV_SH_CAP)`, and the host sees any list overflow in
    the count and re-runs.

  The rider only makes the direct path more likely; that is a cost, not an error. In the session that first
  measured this cadence (on #246), a spill counter found 0 pairs past the stage at b62 1e17 and b60 1e16 with
  once-per-batch checks. The code comment "(none did on the production fields measured)" rests on that run, on
  #246's tree. The claim is minor, and exactness doesn't depend on it.
- **Measurement.** Matches the raw logs: S5/R ×1.029 (b62 1e17), ×1.024 (b62 1e16), ×1.022 (b60 1e16), ×1.030 (b64
  1e16); NiceMark ×1.019, per scenario 1.009–1.030. R's clocks were lower: b62 1e17 1504 vs 1455 MHz, cycles
  ×1.060. The exactness list on R is the same as S5's (logs `x_R_*`, `cmp_R_e14`, `lvp_*_R`, `wgsl_lint_R`,
  `clippy_R_rerun`).
- **Does it belong in this PR?** It is orthogonal (it reproduces the earlier ×1.02 measured on #246), exact, and 30
  lines. As a second commit with its own body section (item 3) it's fine, and that is what the earlier analysis
  planned ("a rider for the next join PR"). If you'd rather keep this PR's attribution clean, give it its own small
  PR. Your call.

### 7. Claims check (body vs raw)

| claim | raw / recomputed | ok |
|---|---|---|
| A/B b62 1e17 100.38 → 86.68 s, ×1.158 (1.141, 1.158, 1.158), 13.7 s saved | `ab_*_e17_b62_r*.log`: same | yes |
| b62 1e16 ×1.147, b60 1e16 ×1.154, b64 1e16 ×1.222; 1e14 ×1.096 / 1.056 / 1.055 / 1.028, per-round values | same | yes |
| s/field = mean device time per field | `device=` is the per-field mean (5100–5110) | yes |
| counts identical in every round | survivors/checked per field identical across sides and rounds (b60/b62/b64 1e16 figures are 2-field totals) | yes (consider "two fields' totals") |
| batches, slots unchanged; layouts −11 to −29 % (1671→1463, 2050→1825, 1566→1367, 2151→1519 MiB) | `batches=`/`slots=`/`plan_mib=` lines | yes |
| scan + fill 9.7 s of 100.2 (9.7 %), 1.77 of 19.6 (9.0 %), 0.25 ns per kept top, 3.8e10 kept | earlier session's RESULTS §A: 9.692 / 100.23, 1.770 / 19.63, 0.254 ns, 3.816e10 | yes |
| NiceMark ×1.119 (6 rounds), per scenario ×1.145 / 1.043 / 1.153 / 1.145; no scenario < ×0.98 | `nm_table.py`; per-round scenario minimum 1.004 (b58 MSD-strong) | yes |
| top stage alone: FD ×1.054 / 1.032 (b62), ×1.060 / 1.036 (b60); `top_kernel` neutral | `topt.py B S5`: same | yes |
| exactness list (CUDA ref, FD 26/279/23/237,907,266, cert 102,365/33,582, dense, whole b42, COMPARE, lavapipe 8+8, lint 14/0) | `x_S5_*`, `cmp_S5_e14`, `lvp_*_S5`, `wgsl_lint_S5` | yes |
| fmt, clippy ×3 clean | box logs; I also ran clippy `--features cubecl --all-targets -D warnings` and rustfmt: clean | yes |
| registers | see item 2 | numbers yes, framing no |
| "The host checks nroots ≤ 8 … and that every prefix fits 64 bits, as before" | the nroots check is new; only the 64-bit check is "as before" | nit: reword |
| card default 340 W | `power.txt`: Default Power Limit 340 W | yes |
| no non-public refs in the body | grep: none | yes |

### 8. What a maintainer would want

- **Before merge:** items 1–5 (CHANGELOG; register text; rider commit and body if included; stale doc; rename).
- **Cheap, and they make the change self-checking without a GPU:** items 6–7.
- **Nothing structural.** The deletion is clean: no references to `top_scan_kernel`, `top_fill_kernel`, `tl`, `top_b`,
  `work`, `cursor`, `bucket_cnt` or `top_count` remain in code, docs, CI (`gpu-parity.yml`'s lint requires don't
  name the deleted kernels), the wasm client or `join_plan.rs`.
- **Footprint.** It is consistent: `goff` is counted in `fixed`, `grp_cnt` in `scratch`, and `per_largest` is now
  `top_rec` alone (`tl` was never the larger: ≤ 8 roots × 4 B vs 32 B per prefix).
- **Metal.** CI's macOS job runs the wgpu suite on Metal (WGSL and direct MSL), which nothing in L46 covered. The new
  `plane_all` and the `% m1` / `w / nbk` divisions are plain u32 forms, not the M4 divide-by-constant pattern (a
  shifted or high-word value divided by a constant). Expect it green, but watch that job.

## What I ran (ivory)

- Worktree `.worktrees/review-l46` (detached at 318fdae), `CARGO_TARGET_DIR` inside it, `nice -n 19`, `-j 2`. Peak
  target 1.9 GB; removed afterwards.
- `cargo test -p nice_common --features cubecl --lib -- join_plan:: cubecl_join::`: 11 passed, 8 ignored (device).
- Scratch host test (`L46/raw/review/sorted_layer_host_test.patch`):
  - Fields: b10 (47..100), the 18 `WINDOWS`, and `PLAN_FIELDS` (b42 1e13; b50/57/60/62/64 1e14).
  - Covers key level on and off, 2/4/6/8 roots, p = 0/1/2.
  - Partitions: all of them where b^p ≤ 400, else 24 (edges plus random).
  - Kept sets: every in-range top, or a 60 % random subset. Two slot offsets.
  - Result: every bucket equals `cpu_join`'s multiset, e.g. b64 1e14: 12.9 M bucket slots; b50 1e14: 43.3 M. 52 s.
- Scratch host print: `join_params_for` at 1e14/1e16/1e17 for b57–64 gives identical params per base.
- `cargo clippy -p nice_common --features cubecl --all-targets -- -D warnings` (1.99.1, forced re-check): clean.
  `rustfmt --check` on both changed files at 318fdae and on 4b27507: clean.
- Recomputed from `raw/box/logs`:
  - A/B tables (`device=`/`batches=`/`slots=`/`plan_mib=`/counts);
  - NiceMark (`nm_table.py`, plus per-round scenario ratios);
  - top-stage table (`topt.py`);
  - register images (`ptxjit_*.txt`, `regsample.txt`);
  - exactness logs (S5, R).
- Not run: anything on a GPU (none here), lavapipe (not installed on ivory).
