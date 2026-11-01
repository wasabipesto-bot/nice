# Overlap join: a lighter top certificate: skip known-zero limbs, difference of powers, digit count from the bit length

Stacked on #235 (its two commits are the base of this branch; the new work is the last commit). Independent of #236: this PR touches only the top kernel's certificate (`cert_power`, `powers_diff`, `ndig_fast` and their callers in `top_cert`), not the join kernel, and it was measured against #235 alone.

## What and why

After #235 the top kernel certifies a top [a, e] by dividing a² and a³ into digits (a 16-bit-limb long division, two digits a pass) and deciding e's digits from a carry test against d = e^j − a^j. At 1e16 the top kernel is about 36 % of device time at b62, 30 % at b60 and 15 % at b64 (#235's per-phase profile), and the long division is its largest stage. This PR makes three exact changes to that work. The certificate is the same object, bit for bit.

**1. Skip the limbs that are known to be zero in the long division.** a^j has at most sp digits, so before pass p it is below b^(sp − p·cd), and its 16-bit limbs from that power's limb count up are zero. The unrolled division nevertheless ran all 12 (a²) or 18 (a³, at 3 words) limbs in every pass. Each pass now divides only the limbs that can be nonzero. The bound is a compile-time constant per pass (`pow_limbs16(base, sp − pass·cd).len()`), so there is no branch, only fewer straight-line steps: 466 → 185 division steps a certificate at b62 (438 → 170 at b60, 466 → 200 at b64). The first step of each pass still divides the top two (now: the top two live) limbs as one u32, `(x[top] << 16) | x[next]`, so #228's rule (no constant division of a bare half-width shift) is kept.

**2. e^j − a^j from e − a.** The kernel formed e² and e³ by schoolbook only to subtract a² and a³ from them. `powers_diff` computes the differences directly, e² − a² = δ(2a + δ) and e³ − a³ = δ(3a² + 3aδ + δ²) with δ = e − a, in the same 16-bit limbs. In the top kernel δ < w, one word, so at 3 words this is 56 limb products instead of 108, and no multi-word subtraction. e² and e³ are never formed.

**3. ndig(d) from the bit length and one compare.** c0 = max(cap, ndig(d)) came from a binary search over the power table: about 6 multi-word compares against global memory, with a branch per word, twice per top. With L = d's bit length, ndig(d) is c or c + 1 for c = ⌈L·log_b 2⌉ − 1, and it is c exactly when d < b^c. `ndig_fast` gets c from a multiply-add-shift whose constants `ndig_magic` searches and checks on the host at kernel-build time, then makes one compare against b^c. It is branch-free.

`cert_power` now takes d instead of e^j. Its digit scan, the remainder a^j mod b^c0 and the carry test are #235's. No constant division is added anywhere. The kernel also gets smaller: TopKernel goes from 478 to 366 SPIR-V basic blocks at b57 and from 496 to 384 at b64 (CubeCL's SPIR-V compiler recurses once per block; see #235), and its WGSL has 270 constant divisions instead of 539.

## Soundness

- Change 1 skips limbs that are zero: their quotient limbs are zero and they contribute nothing to the remainder. The bound needs a^j < b^sp, which holds whenever the low endpoint has the field's digit counts: every production top, and every interval the certificate test builds (`Base::try_new` accepts only intervals whose n, n² and n³ each keep one digit length). The precondition is stated in `cert_power`'s doc.
- Changes 2 and 3 are identities: δ(2a + δ) and δ(3a² + 3aδ + δ²) are e² − a² and e³ − a³, and the digit-count rule is checked exhaustively on the host.
- **Tests:**
  - `top_certificates_match_the_lockstep_scan_and_the_cpu` (CUDA: `cubecl_cuda_…`) now also checks `powers_diff`'s a², a³ and both differences word for word against the full schoolbook powers (`powers16`, now test-only) and their subtraction. Its lockstep reference (`cert_power_lockstep`, kept from #235) still forms both powers, divides every limb in every pass and finds c0 by the binary search, so all three changes are checked against the old code power by power: mask, repeat flag, digit interval at the first disagreement and c0. `top_cert`'s result must still equal the CPU's `Base::cert` and `cert_floor`.
  - New host test `ndig_fast_constants_give_the_digit_count`: `ndig_magic` finds constants for every base 10–64 and every width of 1–9 words, and the rule gives ndig(d), against malachite, at both ends of every bit length and at b^i − 1, b^i and b^i + 1 for every i.
- **Division safety (#228).** No constant division is added: the trimmed division keeps the first step's `(x[top] << 16) | x[next]` on two stored limbs; `powers_diff` and `ndig_fast` only multiply, add, shift, count leading zeros and compare. CI's WGSL lint (`wgsl_dump_for_lint` + `scripts/wgsl-lint.py` with CI's requirements) flags 0 sites, and TopKernel's constant divisions drop from 539 to 270.

## Measured

**Card:** RTX 3080 10 GB on a rented box whose host caps it at **180 W** (default 320 W). Under the join it sat at the cap in every timed run (SW power cap throttle): CLOCKS_LINE.

**Method:**
- #235 (`6e7475e`, this branch's base) and this PR, same box, rounds interleaved (#235, PR, #235, PR, …), nothing else running.
- Harness: `cubecl_cuda_join_throughput_fixed_fields` after one 1e14 warm-up field per process, at the starts b60 1366406074057412100454, b62 7997740455941656911841 and b64 41242006262957161709568.
- s/field is the harness's mean device wall time per field (`device=`; two fields in flight at 1e16). Figures are medians of 3 rounds (2 at b64); spread = (max − min) / median; "per round" is #235's time over the PR's in the same round.

TABLE_FIELDS

PERFIELD_LINE

**NiceMark nice-only** (`--benchmark-secs 150`, 3 rounds each, interleaved):

TABLE_NM

**Where it comes from.** Change 1 cuts the long division's steps by 60 % (466 → 185 at b62) and halves TopKernel's constant divisions (539 → 270 in its WGSL); change 2 halves the schoolbook work for the powers (56 limb products instead of 108 at 3 words); change 3 replaces a data-dependent loop of global-memory compares with straight-line code. Their effect is largest where the top kernel's share is largest (b62, then b60) and smallest at b64, where the chunk divisor is 64² = 2^12, so the division was already shifts and masks. No per-phase profile was run for this PR.

## Exactness

All on an RTX 3080 (CUDA) unless noted, on this branch's code:

- `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu`: ok. 102,365 intervals, 33,582 kept, 203,413 powers scanned above c0, 69,824 with the carry: the same counts as #235. Every interval's `powers_diff` output equals the full powers word for word.
- The same test on lavapipe (llvmpipe, LLVM 20.1.2), through naga and through the direct SPIR-V compiler: ok, same counts, no stack overflow.
- `cubecl_cuda_join_matches_the_cpu_reference` (b10's 69; every window b20–b64 including b50 and b54; the b57 frontier; tight, sliced and refused layouts; the production shape): ok. The same test on lavapipe's direct SPIR-V compiler: ok.
- The dense-field test: b58 1e15 (32 partitions) and b62 1e16 (4 partitions): both pass against the CPU join.
- The whole b42 field (`NICE_TEST_JOIN_FULL_FIELD=1`): join = stride = the CPU reference (417,789,835 join survivors, 16,879,877 checked, no hits).
- `NICE_TEST_JOIN_COMPARE=1` on one 1e14 field at b57, b60, b62 and b64: join = stride, and the survivor and checked counts equal #235's to the last digit (b62: 1,439,469,648 / 88,159,810).
- At 1e16 and 1e17 the survivor counts vary from run to run in both trees, as on #235 and main, through the stage overrun, which depends on timing; this PR's counts vary by the same amount (COUNTS_PLACEHOLDER). found = 0 in every run.
- The new host test `ndig_fast_constants_give_the_digit_count`: ok.
- `cargo fmt --check`; clippy `-D warnings` default, `--features nice_client/gpu` and `--features nice_client/gpu,nice_client/cubecl-spirv`: clean.
- Not run here: Apple (Metal). The trimmed division's first step is still the OR of two stored limbs, `(x[top] << 16) | x[next]`, the shape #235 uses, not the bare `x >> 16` dividend that Apple's compiler miscompiles; only the limbs it picks change. But this branch has not been run on an M-series GPU.

## Not in this PR

- **A division-free digit step** (a Möller–Granlund-style 2/1 step by multiply-high in place of the constant division). It targets the same long division and is bit-identical on CUDA and lavapipe, but on CUDA the compiler already turns the constant division into a multiply, so it measured within noise there (×0.995–1.011 whole-field), and `mul_hi` lowers to a u64 product shifted by 32 in WGSL/MSL, which needs a check on Apple's compiler first. After this PR's trim there is less of the division left for it to save.
- **Rejecting a dead square early** (skip the cube's conversion when the square's certificate already has a repeat). It is exact, but it cannot fire where it would matter. The digits come out least significant first, and a top's new certified digits are the lowest two of each power (the parent prefix already certified the ones above), so nothing is known before the square's last few passes; only about a fifth of tops are dead by the end of the square. An exit in place needs all 32 lanes of a plane dead, and practically every plane holds a kept top. Compacting the survivors between the square and the cube saves whole planes only, and the barrier and the recomputation eat that: ×1.000 at b62 1e17.
