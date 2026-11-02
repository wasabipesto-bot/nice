# L34 brief: digit-transposed AND in the join kernel (2026-11-02)

## Idea

The join kernel's AND loop (`join_kernel`, `common/src/cubecl_join.rs`, the `while jt < cend`
loop inside the chunk loop) tests each of a wave's entries against each top of a chunk of 32:
per (entry, top) pair two ANDs, an OR, a compare and a select, plus two broadcast shared loads
and loop overhead per top. The profile (L1.7, `L1/PROFILE-3.md` §5) fits 1.18 ps per real
lane-pair, 0.49 ps per empty lane and 238 ps per top; at b62 1e17 that is real lanes 30 s,
padding 6.7 s, per-top chunk cost 9.1 s of a 166 s field after #235+#236 (L30.3), i.e. the
AND phase is about 27 % of the field; at b60 1e16 about 29 %.

A bottom's mask has exactly 12 distinct digits (L1.1: 6 of n² and 6 of n³), plus the two key
digits at key level (≤ 14 set bits). A top's mask has ~16–18. So transpose the tops: for each
chunk c of 32 tops and each digit d, one word `T[c][d]` whose bit i is set iff top `jc+i` has
digit d. Then for an entry with digit set S:

    pass_mask[c] = ~( OR_{d in S} T[c][d] ) & vv

exactly the `pm` the walk consumes today (pair passes iff the masks are disjoint iff no digit
of S appears in the top). Cost per entry per 256-top batch: |S| ≤ 14 iterations of (trailing
zeros, clear bit, then for the 8 chunks one shared load + one OR), ≈ 14 × 18 = 252
instructions for 256 pairs ≈ 1 per pair, against ~7.5 per pair today (5 + the per-top loads
and loop overhead amortised over EPT 2). Shared loads drop from 512 broadcast loads per thread
per batch to 112 non-broadcast ones (bank = d mod 32: at most 2-way conflicts). `T` is
8 × 64 words = 2 KiB of shared memory, built once per top batch (`tc` loop) right after
`t_lo`/`t_hi` are loaded: e.g. thread u < 64 takes digit u and scans the ≤ 256 tops once
(broadcast loads of t_lo/t_hi, extract bit u, OR into the chunk's accumulator, store 8 words),
or 512 (chunk, digit) cells spread over the 256 threads. Either way ~1–2 k instructions per
batch per thread-group, against ~3.3 k saved per wave per thread; buckets at b62 1e17 average
332 entries (one 512-lane wave), so the build is amortised over ~1 wave: expect the AND phase
2–4× cheaper, 10–18 % of the field if the profile's split is right.

Two loop orders to try: (A) outer over the entry's digits, inner unrolled over the 8 chunks
with 8 accumulators per entry slot (EPT 2 → 16 accumulators; address of `T[c][d]` is
`c*64 + d`, the `c*64` folds into the load's immediate offset); (B) outer over chunks as the
code is today (one accumulator), inner over digits (re-walks the bits 8 times). (A) should win
on instructions; check register count and occupancy (`nvcc --resource-usage`-style via the
CubeCL/CUDA compile log, or `NICE_EXP_*` knobs if present).

The walk after the AND, the prefilter in the walk (#236), the stage and the flush are
untouched. Padding lanes still run the digit loop (their mask is all ones → |S| = 64; give
padding lanes `m = 0`, i.e. no digits, so they fall through at no cost, and let `vv` kill
them as today).

## What to do, in order

0. Box: `nice-research-l34-transpose` (RTX 3080, 7 h TTL). `cd ~/projects/nice/scratchpad/2026-10-research-program && python3 vast.py list`, then `python3 vast.py ssh <id>` prints the ssh command. Wait for `/root/READY`. Clone is of the fork (wasabipesto-bot/nice) at /root/nice; `git fetch origin exp/join-all3` and work from it (0f1a8a7 = main 04693ac + #235 c5fb040 + #236 fb05597 + #237 51410e7). All builds and runs happen on the box, nothing is built on ivory. Push your work to the fork as `exp/join-transpose` (make the change switchable: `NICE_EXP_JOIN_TRANSPOSE=1` env var read on the host and passed as a comptime flag, so one binary does A/B).
1. Baseline profile of `exp/join-all3` at b62 1e17 (1 field) and b60 1e16 (2 fields): cherry-pick `2ab1694` from `rp/gpu-profile-3` (the `NICE_EXP_GPU_PROFILE` phase timers and probe; resolve conflicts, the kernels changed) if it applies in under 30 min, otherwise skip the profile and rely on the A/B. Record phase shares (top/bucket/join/check/other) so we know the post-#237 split.
2. Implement the transposed AND behind the switch. Exactness first: `cargo test -p nice_common --features cubecl-cuda` (or the feature set the join tests use; see `common/src/cubecl_join.rs` tests and `common/src/gpu_niceonly.rs`), including the join parity tests against the CPU join, the dense fields (`NICE_TEST_JOIN_DENSE`), the b50/b54 cases, the whole-b42 test. Survivor counts (`nand`/AND survivors, prefilter survivors, full checks) must be identical to the switch-off binary on every field you time: compare the counters the client prints (COMPARE-style runs as in L30/L33: see `L33/raw/` and `L30/pr-raw/` for the scripts used; copy their method).
3. A/B on the box, interleaved, medians, ≥ 3 rounds: b62 1e17 (1 field), b62 1e16 (2 fields), b60 1e16 (2 fields), b64 1e16 (2 fields), and NiceMark (`nice_client` benchmark, as in L30.3). Same fields as L30.3 / L33.2 (`L30/COMBINED.md` names them). Report device seconds, spreads, the ratio, clock (nvidia-smi samples) and the power cap (`nvidia-smi -q -d POWER`).
4. Also build and run the lavapipe path once (`mesa-vulkan-drivers` is installed; the CubeCL wgpu feature; both the naga and the direct SPIR-V compiler, as in #235's L29.2 fix): the kernel must compile (the direct SPIR-V compiler overflows its stack on big kernels — keep the new loops simple) and the counts must match CUDA's. Run `scripts/wgsl-lint.py` the way `.github/workflows/gpu-parity.yml` does (`--require` list) on the dumped WGSL.
5. Write `L34/RESULTS.md` (method, numbers, exactness, register counts, what worked and what did not, the loop order chosen, anything surprising) and copy raw logs to `L34/raw/`. Update nothing else in the scratchpad; the director records the ledger and journal.

## Rules

- Vast only through `vast.py`; never create or destroy instances yourself (tell the director when you are done and the box can go). Nothing on ivory but editing files under `scratchpad/2026-10-research-program/L34/` and pushing the branch. Do not touch the live fleet, `~/fleet-run`, fleet config or anything under `~/projects/nice` outside `.worktrees/` and the scratchpad; do not open PRs; no nested agents.
- If the prototype is slower or exactness fails, stop tuning after two attempts and report the measurements and the reason; a clear negative is a result.
- Hard stop at 11:30 UTC (the box self-destroys at ~12:55 UTC). Report before then whatever is complete.
