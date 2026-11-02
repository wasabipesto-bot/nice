# L35 brief: top kernel stepping partitions by finite differences (2026-11-02)

## Idea

`top_kernel` (`common/src/cubecl_join.rs`) certifies one (top-layer prefix i, slot) pair per
thread: p = P0·pdiv + v (v = the slot's partition value), the interval [a, e] = [p·w, p·w+w−1]
(w = b^(L−t), clipped only at the field's ends), then `top_cert` turns a's square and cube into
base-b digits by long division (one endpoint since #235, known-zero limbs skipped since #237)
and reads the certified run off the top digits. After #235/#236/#237 the top kernel is ~39 % of
a b62 1e17 field (L30.3 profile: 43 % before #237's ×1.10) and about half of it is still the
limb → digit conversion (L33 §: long division + extraction were 55 % of the kernel before the
limb skip).

Consecutive slots have consecutive v, so consecutive p, so a steps by exactly w = b^(L−t):
a digit shift. Therefore the digits of a², a³ for slot v+1 follow from slot v by additions of
shifted digit arrays, no division at all:

    (a+w)² = a² + (2a)·b^s + b^(2s)                       s = L − t
    (a+w)³ = a³ + (3a²)·b^s + (3a)·b^(2s) + b^(3s)
    2a  += 2·b^s;   3a += 3·b^s;   3a² += (6a)·b^s + 3·b^(2s)   (6a = 3·(2a), or keep 6a += 6·b^s)

That is the finite-difference scheme of #221/#225 (`common/src/detailed_fd.rs`,
`common/src/cubecl_detailed_fd.rs`: packed digit arrays, 16-bit limbs on GPU, addition with
carry fix-up, Apple-safe because nothing divides), with the increments shifted by s digits
instead of being 2n+1 and 3n²+3n+1. Per step: ~6 packed-array additions over ≤ 3L ≈ 39 digits
(≈ 5 words of 8 digits) ≈ 200–300 instructions, against ~2000–3000 per (prefix, partition) for
the conversion today. The certificate read-off (digits above the floor c0, distinctness, run
mask, #235's carry test for e = a + w − 1) is unchanged in meaning; note e_v = a_{v+1} − 1, so
the next state is the high endpoint's power plus a small correction — #235's carry test already
handles exactly that, keep it.

So: one thread per top-layer prefix, looping over the batch's slots in order (5–8 slots per
batch at b62 1e17; `launch_batch(vs)`), converting a² and a³ by division only for the first
slot and stepping the rest. Expected: the conversion share drops to ~1/(slots) of today → the
top kernel ×1.5–2, i.e. 10–20 % of the field at b62 1e17 and b60 1e16 (b64: the top kernel
is only ~15 % there). Persisting the state across batches (3844 partitions per prefix per
slice; ~17 u64 per prefix ≈ 380 MB at b62 1e17 on a 10 GB card) would remove the division
entirely but needs memory-budget work — measure the in-batch version first and only note what
persistence would add.

## Watch out

- Batches are not guaranteed consecutive: the tests thin the live partitions (`check_window`
  steps through `live_partitions` and chunks by `max_slots`), and production runs only live
  partitions too. The slot loop must handle gaps: if `vs[j+1] != vs[j] + 1`, re-seed that slot
  by the division path (or step the gap when it is small, say ≤ 3, whichever is simpler and
  exact). Production fields have every partition live, so the common case is a step of 1.
- Verify first that a batch's `vs` are consecutive in production runs (the host builds batches in
  `cubecl_join.rs` around `launch_batch` / the `batch.iter()` site near the slice loop) and
  that p's clipping to [plo, phi] and [a, e]'s clipping to [s, e−1] only happen at the field's
  ends. Clipped or out-of-range slots take the existing division path (they are rare).
- Exactness is bit-for-bit: `top_m`, `top_r`, `top_x`, `top_b`, bucket counts and the number of
  certified tops must equal the current kernel's for every slot. Build a device test that runs
  both kernels on the same batch and compares the outputs (the L29 certificate test with its
  counts 102,365 / 33,582 / 69,824 is the model; see `cubecl_join.rs` tests), then confirm with
  COMPARE-style field runs (AND survivors, prefilter survivors, full checks identical).
- Grid change: x over prefixes only (2.8e6 at b62 1e17 per slice: plenty of parallelism), the
  slot loop inside; `top_count`/`bucket_cnt` atomics stay per slot. Keep `cube_done(ran, 0)`
  semantics.
- Register pressure: the packed state is ~17 u64 = 34 u32 registers plus the certificate
  logic; check the compile's register count and occupancy; if it spills, keep 2a/3a/3a² as
  u32-limb numbers (they are ≤ L+1 digits) and only a², a³ as digit arrays.
- Apple: no new division (the step is additions and shifts); the initial conversion is the
  existing #235/#237 code. Run `scripts/wgsl-lint.py` as `.github/workflows/gpu-parity.yml`
  does. The CubeCL direct-SPIR-V compiler overflows its stack on big kernels (L29.2): keep the
  step code compact (loops over words, not fully unrolled digit-by-digit code).
- Digits per word and the digit width: base ≤ 64 needs 6 bits; #221 packs 8 digits per u64 with
  8-bit lanes and fixes carries by compare-subtract; reuse its scheme or the GPU FD kernel's
  u32 form rather than inventing a third.

## What to do, in order

0. Box: `nice-research-l35-topfd` (RTX 3080, 7 h TTL). `cd ~/projects/nice/scratchpad/2026-10-research-program && python3 vast.py list`, then `python3 vast.py ssh <id>` prints the ssh command. Wait for `/root/READY`. The clone at /root/nice is of the fork (wasabipesto-bot/nice); `git fetch origin exp/join-all3` (0f1a8a7 = main 04693ac + #235 c5fb040 + #236 fb05597 + #237 51410e7) and work from it. All builds and runs on the box; nothing built on ivory. Push to the fork as `exp/top-fd`, switchable: `NICE_EXP_TOP_FD=1` read on the host → comptime flag (or a second kernel chosen on the host), so one binary does A/B.
1. Read `top_kernel`, `top_cert`, `cert_power`, the batch/slot host code, `detailed_fd.rs`'s packed arithmetic and `cubecl_detailed_fd.rs`'s step. Write a 1-page design note (`L35/DESIGN.md`): state layout, step, where the certificate read-off plugs in, the clipping fallback, the exactness test. Spend at most 45 min here.
2. Implement; device exactness test (both kernels, same batch, compare outputs) on CUDA; then whole-field COMPARE runs (counts identical) at b62 1e16 and b60 1e16 and a dense field (`NICE_TEST_JOIN_DENSE`, as L30/L33 did).
3. A/B on the box, interleaved, medians, ≥ 3 rounds: b62 1e17 (1 field), b62 1e16 (2 fields), b60 1e16 (2 fields), b64 1e16 (2 fields), NiceMark. Same fields and scripts as L30.3/L33.2 (`L30/COMBINED.md`, `L33/PR-RESULTS.md`, raw dirs `L30/combined-raw`, `L33/pr-raw`). Report device seconds, spreads, ratios, SM clock and power cap.
4. Lavapipe: build the wgpu path, run the join parity tests with both compilers (naga and the direct SPIR-V one; see #235's L29.2 notes `L29/SPIRV-FIX.md`), run the WGSL lint.
5. Write `L35/RESULTS.md` (method, numbers, exactness, register counts, what the step costs per partition, what persistence across batches would add, surprises) and copy raw logs to `L35/raw/`. Update nothing else in the scratchpad.

## Rules

- Vast only through `vast.py`; never create or destroy instances (tell the director when the box can go). On ivory: read the repo and scratchpad, write only under `scratchpad/2026-10-research-program/L35/`, push/fetch git. Nothing under `~/projects/nice` outside `.worktrees/` and the scratchpad is touched; no live fleet, no `~/fleet-run`, no PRs, no subagents.
- If exactness cannot be reached after two serious attempts, or the prototype is slower, stop and report the measurements and the reason.
- Hard stop 11:45 UTC (the box self-destroys at ~13:30 UTC). Report whatever is complete before then.
