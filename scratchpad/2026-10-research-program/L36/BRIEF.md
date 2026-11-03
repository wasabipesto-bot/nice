# L36 brief: the full open stack measured, and the top kernel's residual after #240 (2026-11-03)

## Context

Five program PRs are open and green, in two chains: #235 (c5fb040) → #237 (51410e7) → #240
(c7ef3c8, `pr/top-fd`) on the top kernel, and #236 (fb05597) → #239 (775b6d9,
`pr/join-transpose-and`) on the join kernel. `exp/join-all3` (0f1a8a7) = main 04693ac + #235 +
#236 + #237. Multiplying the per-PR ratios predicts about ×1.8 at b62 1e17 over main; nobody has
measured the five together. After #240 a stepped top partition costs 0.198 ns per prefix (b62),
and what it still pays for is the two certificate scans, x mod b^c0, the carry tests and the
append — not the step's additions (`L35/RESULTS.md`, `L35/PR-BODY.md`). The top kernel was 35 %
of a b62 1e17 field before #240 and the join 53 % (`L34/RESULTS.md` §7).

## What to do, in order

0. Box `nice-research-l36-stack` (RTX 3080, 6 h TTL, instance 58924168): from
   `~/projects/nice/scratchpad/2026-10-research-program` run `python3 vast.py ssh 58924168` for the
   ssh command; wait for `/root/READY`. The clone at /root/nice is of the fork
   (wasabipesto-bot/nice); `git fetch origin <branch>` there fetches fork branches; upstream main is
   `https://github.com/wasabipesto/nice.git` (add it as a remote on the box). All builds and runs on
   the box; nothing is built on ivory. Never `vast.py create`/`destroy`.
1. **Build `exp/join-all5`**: start from `exp/join-all3`, merge `pr/top-fd` (c7ef3c8), then merge
   `pr/join-transpose-and` (775b6d9). Only CHANGELOG should conflict (keep every line); if
   `cubecl_join.rs` conflicts, resolve carefully and say so. Push to the fork as `exp/join-all5`.
   Build with the CUDA feature (and the wgpu/lavapipe feature for step 2).
2. **Exactness of all5** (CUDA): `cubecl_cuda_join_matches_the_cpu_reference` (incl. b50/b54),
   the dense fields (`NICE_TEST_JOIN_DENSE`), whole b42 (`NICE_TEST_JOIN_FULL_FIELD=1`), #240's
   `cubecl_cuda_top_fd_matches_the_top_kernel`, #235's certificate test, and
   `NICE_TEST_JOIN_COMPARE=1` at 1e14 for b57/60/62/64 (counts must equal the values in #239's
   and #240's PR bodies). Whole-field counts in step 3 must equal all3's exact counts (b62 1e17
   1,020,844,021,499 / 62,584,252,554; b62 1e16 163,513,599,082 / 10,027,698,695; b60 1e16
   460,847,952,346 / 30,871,838,404; b64 1e16 787,584,956,227 / 47,900,853,327). Lavapipe: join
   parity with naga and with the direct SPIR-V compiler; `scripts/wgsl-lint.py` as the workflow
   runs it.
3. **A/B main (04693ac) vs all5**, same box, interleaved, medians, 3 rounds: b62 1e17 (1 field),
   b62 1e16, b60 1e16, b64 1e16 (2 fields each), NiceMark (`--benchmark-secs 150`, 3 rounds).
   Use the `cubecl_cuda_join_throughput_fixed_fields` harness and the scripts in
   `L30/combined-raw/` / `L34/raw/scripts/` (same fixed field starts). Report absolute device
   seconds, spreads, ratios, SM clock and power cap, and compare with the product of the per-PR
   ratios (#235+#236 ×1.365, #237 ×1.10, #240 ×1.14 with #236 underneath, #239 ×1.07).
4. **Profile all5** at b62 1e17 and b60 1e16: cherry-pick the `NICE_EXP_GPU_PROFILE` phase
   timers (commit 2ab1694 on `rp/gpu-profile-3`; it will need adapting to #240's extra launch —
   put the FD top kernel and the clipped-block launch in the "top" phase). Phase split: top /
   bucket / join / check / other, plus the join's AND vs walk if the timers allow. If adapting
   takes more than 40 min, skip the profile and say so.
5. **Top-kernel residual scoping** (`top_fd_kernel`, the stepped path) on all5, on an experiment
   branch `exp/top-fd-ablate` (fork): comptime ablation switches read from env on the host, each
   removing one part of the per-slot work while keeping the data flow alive enough that the
   compiler cannot delete the rest (write a cheap checksum): (a) the two certificate scans
   (`cert_power_fd`'s digit scan); (b) the x mod b^c0 remainder; (c) the carry tests; (d) the
   append (count only); (e) the step additions themselves. Time each with #240's ignored test
   `cubecl_cuda_top_fd_timing` (`NICE_TEST_TOPFD_TIMING`) at b62 1e17 and b60 1e16, 3 rounds, and
   turn it into a cost breakdown per stepped slot (ns and % of the 0.19–0.20 ns). Then say what
   could cut the largest term and by how much; prototype only if a change can plausibly take
   ≥ 25 % off the stepped slot (that is ≈ 5 % of a b62 1e17 field at the top kernel's post-#240
   share). Candidates to consider, not prescriptions: scanning the packed digits four at a time
   with SWAR (distinctness of a word's four digits via a 64-bit mask built by four shifts, or a
   byte-compare trick), fusing the square's and cube's scans, keeping the run mask across steps
   when the digits above c0 did not change (they rarely do between consecutive partitions — check
   how often they change: if almost never, the scan can be skipped when the step's carry did not
   reach position c0).
6. Write `L36/RESULTS.md` (stack A/B, exactness, profile) and `L36/SCOPING.md` (breakdown and the
   verdict), raw logs in `L36/raw/`. Update nothing else in the scratchpad; no PRs.

## Rules

- Vast only through `vast.py`, never create/destroy (tell the director when the box can go).
  On ivory: read the repo/scratchpad, write only under `scratchpad/2026-10-research-program/L36/`,
  push/fetch git. Nothing else under `~/projects/nice` outside `.worktrees/` is touched; no live
  fleet, no `~/fleet-run`, no PRs, no subagents.
- Hard stop 10:45 UTC (the box self-destroys ~11:45 UTC). Report whatever is complete.
