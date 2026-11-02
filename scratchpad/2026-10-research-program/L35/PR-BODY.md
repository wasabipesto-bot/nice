# Overlap join: step the top certificates through a batch's partitions

Stacked on #237, which is on #235: this branch is #237's head plus one commit. It is independent of #236. It changes only the top stage (a new kernel beside `top_kernel`, its launch and the device test), not the join kernel, and it was measured against #237 alone.

## What and why

The top kernel certifies every top prefix P of every partition in a batch. In each, it builds the interval [a, e] = [P·w, P·w + w − 1] (w = b^f0) and divides a² and a³ into base-b digits with #237's trimmed long division. It then reads the certificate off those digits and #235's carry test.

A batch's partitions are consecutive partition values, so for one top-layer prefix they are consecutive P. The interval moves by w, a power of the base, and its low endpoint's powers are shifted copies of P's:

    a² = P²·b^(2·f0),   a³ = P³·b^(3·f0)

So the digits a partition needs follow from the previous partition's by additions:

    P² += 2P + 1,   2P + 1 += 2,   P³ += 3P² + 3P + 1,   3P² + 3P + 1 += 6P + 6,   6P + 6 += 6

This is the detailed mode's finite-difference step (#221, #225) with n = P, and it reuses that code: packed base-b digit arrays with four digits to a u32, and `fd_add_top`'s biased add. The arrays are short, because P has the top layer's t digits, not n's L. At b62 1e17 the five arrays take 23 words.

The binary differences the certificate also needs step the same way. With δ = w − 1, d2 = e² − a² grows by 2wδ per partition, and d3 = e³ − a³ by Δ3, which itself grows by 6w²δ. Only the first slot of a batch divides: a slot after a gap in the batch, and one after a clipped block, also re-seed by division, as does the first slot of each slot group (below).

**`top_fd_kernel`.**
- Grid x runs over the top layer only, and each thread walks its prefix through the batch's slots in order.
- **Seed.** P, P², P³ by schoolbook in 16-bit limbs, then #237's trimmed split16 long division (`fd_digits_trim`: the same per-pass limb bound and the same Apple-safe first step). 2P + 1, 3P² + 3P + 1 and 6P + 6 come from those digits by biased adds. d2 and d3 come from `powers_diff`, and Δ3 = 3wδ·(2a + 2w − 1).
- **Step.** Five digit-array adds and three multiword adds.
- **Certificate** (`cert_power_fd`). It is `cert_power`'s with the digits read from the state instead of divided out:
  - c0 = max(cap, `ndig_fast`(d)) as before;
  - a 4-digit word wholly below c0 only adds its value to x mod b^c0 (u32 words; nothing divides it);
  - the other digits go through `cert_power`'s scan step;
  - the repeat flags come from popcounts;
  - #235's carry test is unchanged;
  - the closure is shared with `top_cert` (`close_cert`).
- **Append.** Kept tops are appended with one atomic per plane: plane sum, exclusive scan, one `fetch_add`, broadcast. nvcc warp-aggregates `top_kernel`'s `top_count[slot]` atomic on its own, because there the slot is the cube's y. In a loop over slots it does not, and the same-address atomic per kept lane had capped the kernel.
- **Slot groups.** When the top layer has fewer than `TOP_FD_MIN_UNITS` = 2^17 prefixes, y splits the batch's slots into groups, each with its own threads and its own seed, so small fields still fill the GPU.
- **Clipped blocks.** Only P = plo and P = phi can be clipped to the slice's ends, so at most two partition values per slice. The FD kernel leaves them out, and `top_kernel` with a new comptime `only_clipped` certifies them, launched beside it only on the batches that hold one. The device compiles that variant when it is created, so it never compiles inside a batch.
- **Power-of-two bases keep `top_kernel`** (`TOP_FD_AT_POW2_BASES`). There the chunk divisor is a power of two, so the long division is already shifts and masks, and FD measured slower (b64 ×0.985, mostly its seed).

The old kernel stays for the excluded bases and the clipped blocks.

## Soundness

- **The stepped arrays hold exactly the divided digits.** The seed is exact integer arithmetic followed by #237's division of a value below b^q, the same precondition `cert_power` states: P^k·b^(k·f0) = a^k < b^(s_k) for an unclipped block of the field. Every step is an exact base-b addition (the biased add, valid for b ≤ 128). So after j steps the arrays hold P'², P'³ and their differences for P' = P + j, digit for digit. The same holds for the binary d2, d3 and Δ3, which are identities in P.
- **No overflow.** The state only ever holds a P whose own block is unclipped and in range: a slot steps only from P − 1 to P, where P is the slot it then certifies. So P^k < b^(s_k − k·f0), and the arrays are sized by those digit counts. `top_fd_fits` checks on the host that the differences' words fit the arrays they are added into, and the field falls back to `top_kernel` otherwise.
- **The certificate is the same function of the same digits.** `cert_power_fd` has `cert_power`'s scan, remainder and carry test.
  - Digits below k·f0 are zero, so whole words below them add nothing and are skipped.
  - If c0 < k·f0, the zero digits from c0 up enter the run before the scan. This cannot happen for P ≥ 1, since d2 ≥ w² and d3 ≥ w³, but it is handled.
  - The repeat flags: a digit repeats among n positions iff the mask of their values has fewer than n bits.
- **Gaps and clipping.**
  - A slot steps only if the previous slot of the same thread was P − 1 and unclipped. A gap, a backwards step, an out-of-range slot or a clipped one makes the next slot seed.
  - Production batches are consecutive (`run_pass` chunks `0..nparts`). The overflow re-runs, single-partition re-runs and samples are not, and they seed.
  - Clipped blocks are exactly `top_kernel`'s, in the `only_clipped` launch, which certifies them the old way.
- **Outputs.** Per slot, the same tops with the same mask, r (0, w), seed flag, bucket word and bucket counts. Only their order within a slot's list differs: atomic order, as before.

## Measured

**Card:** RTX 3080 10 GB on a rented box whose host caps it at **180 W** (default 320 W). Under the join it sat at the cap in every timed run (SW power cap throttle): CLOCKS_LINE.

**Method:**
- #237 (`51410e7`, this branch's base, on #235) and this PR, same box, rounds interleaved (#237, PR, #237, PR, …), nothing else running.
- Harness: `cubecl_cuda_join_throughput_fixed_fields` after one 1e14 warm-up field per process, at the starts b58 130525216587923470200, b60 1366406074057412100454, b62 7997740455941656911841 and b64 41242006262957161709568.
- s/field is the mean device wall time per field (`device=`; two fields in flight at 1e16). Figures are medians of 2 rounds; spread = (max − min) / median; "per round" is #237's time over the PR's in the same round.

TABLE_FIELDS

**Top kernel alone** (new ignored test `cubecl_cuda_top_fd_timing`: the first 40 batches of a production plan's first slice, each kernel in turn, three rounds, ns per top prefix and partition):

TABLE_KERNEL

- A stepped partition costs about 0.20 ns per prefix against `top_kernel`'s 0.36. A seeding slot costs about what `top_kernel` does.
- So the gain grows with the plan's slots per batch: 5 at b62 1e17, 13 at b62 1e16, 4 at b60 1e16.
- What a stepped slot still pays for is the two certificate scans, x mod b^c0, the carry tests and the append, not the step's additions.

**NiceMark nice-only** (`--benchmark-secs 150`, 2 rounds each, interleaved):

TABLE_NM

**NiceMark is neutral, and the PR is justified on whole-field runs.** NiceMark times a sample of each field's partitions, taken in bit-reversed order (`sample_order`). No batch in it holds two consecutive partitions, so every FD slot seeds by division, and it measures FD's worst case. Production runs a field's partitions consecutively (`run_pass` chunks `0..nparts`), where all but a batch's first slot step. The whole-field runs above are that production path.

## Exactness

All on an RTX 3080 (CUDA) unless noted, at this branch's head:

- **New `cubecl_cuda_top_fd_matches_the_top_kernel`.** For each batch it runs `top_kernel` and `top_fd_kernel` on the same device and batch, and asserts per slot: the same top count, the same bucket counts, and the same sorted (P, mask, r, x, bucket) entries. It does so in one slot group and in about three.
  - Fields: 26, namely the 17 test windows b20–b64 (clipped at both ends, every partition); the b57/b60/b62/b64 1e14 production plans; and the first and last slices of the b60/b62/b64 1e16 plans.
  - Batches: 279, namely consecutive (first three, middle, last), thinned live partitions (gaps), and one stepping back and skipping; 23 of them hold a clipped block.
  - Result: ok, 237,907,266 tops.
- The same test on lavapipe (llvmpipe), through naga and through CubeCL's direct SPIR-V compiler, on the windows and the 1e14 plans: ok on both, 21 fields, 142 batches (20 with a clipped block), 1,018,088 tops.
- `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu`: ok, 102,365 intervals, 33,582 kept, 203,413 powers above c0, 69,824 with the carry (#235's counts). `top_cert`'s closure moved into `close_cert`.
- `cubecl_cuda_join_matches_the_cpu_reference`: b10's 69, every window b20–b64 including b50/b54, the b57 frontier, tight/sliced/refused layouts, the production shape. ok. The same test on lavapipe through naga and through the direct SPIR-V compiler: ok, ok.
- The dense-field test, b58 1e15 (32 partitions) and b62 1e16 (4 partitions): both pass against the CPU join (b58: 254,938,965 join survivors, 14,396,829 checked).
- The whole b42 field (`NICE_TEST_JOIN_FULL_FIELD=1`): join = stride = the CPU reference: 1764 partitions, 417,789,835 join survivors, 16,879,877 checked, no hits.
- `NICE_TEST_JOIN_COMPARE=1` on one 1e14 field at b57, b60, b62 and b64: join = stride, found 0, and the survivor and checked counts equal #237's to the last digit (b57 4,850,227,888 / 268,123,373; b60 2,694,700,282 / 180,517,288; b62 1,439,469,648 / 88,159,810; b64 5,702,041,796 / 346,647,759).
- The whole-field runs above: COUNTS_LINE.
- CI's WGSL lint (`wgsl_dump_for_lint` + `scripts/wgsl-lint.py` with CI's requirements): 16 shaders, 0 flagged. CI's requirements are met as they stand: `TopKernel@57` is still compiled, for the clipped blocks. TopFdKernel b57 has 196 constant divisions (its seed's division and digit extraction, and the buckets' `% (b − 1)`), TopKernel b57 270.
- `cargo fmt --check`; clippy `-D warnings`, default and `--features nice_client/gpu`: clean.

## Registers and occupancy

- REGS_LINE.
- `top_kernel` is unchanged at 80 registers (3 blocks of 256 per SM). The FD kernel's state is 23 words of digits plus 24 words of binary differences (b62), so it fits 2 blocks of 256 per SM (16 warps). That made no measurable difference: the kernel ran the same at 64, 128 and 256 threads per cube.
- Lavapipe's direct SPIR-V compiler: TopFdKernel 298 basic blocks at b57 and b62, 304 at b58 and b60, 310 at b64, against TopKernel's 368–386. The FD kernel is smaller than `top_kernel` in basic blocks, which bounds that compiler's recursion (#235).

## Not in this PR

- **Keeping the FD state across batches.** It would make every partition but a slice's first a stepped one. That is about ×1.18 at b62 1e17 (against ×1.14 here) and ×1.11 at b60 1e16, estimated from the kernel's stepped and seeded costs. It needs 192 B per top prefix of device memory (≈ 700 MB for a b62 1e17 slice) budgeted in the join plan, and released with its layout.
- **Metal (Apple) is not run.** The FD kernel adds no new division shapes. Its seed uses #237's trimmed split16 division, including the first step on two stored limbs; the step and the certificate scan only add, shift, mask and multiply. CI's WGSL lint flags nothing.
- **b57/b58 at field level**: only through the whole-field runs above (b58 1e16) and the 1e14 compare (b57).
