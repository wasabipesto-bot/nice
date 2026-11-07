## What

Stacked on #246 (and #241).

The FD top kernel (#240) takes each top-layer prefix through a batch's consecutive partitions. A slot that steps from P − 1 to P updates the packed base-b digits of P² and P³ by additions, steps e^k − a^k in binary, and then certifies the block from those digits. Most of a b62 1e17 field's top certificates are such stepped slots; the rest are seeds, the first slot of each prefix in each batch, which divide P² and P³ into digits.

This PR makes a stepped slot cheaper and seeds rarer:

- **Carry c0 and the carry test's bound.** Each power's c0 = max(cap, ndig(e^k − a^k)) and dm = b^c0 − 1 − (e^k − a^k) are kept from slot to slot. A step subtracts the step of e^k − a^k from dm; only when that borrows (the difference reached b^c0, which happens rarely) is the difference recovered as b^c0 − 1 − dm and c0 and dm formed again. The carry test, (x mod b^c0) + (e^k − a^k) ≥ b^c0, becomes x mod b^c0 > dm: one subtraction whose borrow is the answer. A stepped slot no longer reads the power table (`ndig_fast`'s compare and the test's b^c0) and no longer runs `ndig_fast`.
- **No bookkeeping above the run.** The digit scan tracks x's run of (b − 1)s from c0 up digit by digit. Once the run has ended, every later digit lies above c0, so a word after that point only sets its digits' bits in both masks.
- **No block endpoints for a step.** Only P = plo and P = phi can be clipped, and a step uses neither a nor e, so a slot that steps and is neither skips forming them and the clip test.
- **One ballot for the append.** The plane's count of kept tops and each lane's rank are popcounts of one `plane_ballot` instead of a `plane_sum` and a `plane_exclusive_sum` (up to 128 lanes a plane).
- **Carries only when there are some.** The step's base-b additions and binary steps propagate a carry or borrow past the addend's words only when there is one, and the binary addends use comptime bounds on their length (2wδ < 2w², 6w²δ < 6w³, Δ3 < 3w²·2^(32·limbs + 2)).
- **`SURV_PER_PREFIX` 2 → 1.** A batch is planned for one prefilter survivor per top-layer prefix and partition instead of two (measured 0.53 at b62 1e17). That allows about twice as many partitions per launch where the survivor bound was binding, so half as many seeds per field, and fewer batches and slices.

## Why

After #246 the FD top kernel is about a quarter of a b62 1e17 field (25 s of 100 s on an RTX 3080 at 180 W) and a fifth of a b60 1e16 field. An ablation of its stepped slot (RTX 3080) put about 22 % of it on the two power-table reads and `ndig_fast`, 27 % on the scan's per-digit bookkeeping, 17 % on the append and 13 % on the step's additions. A seed costs about 2.4 times a stepped slot, and at 5–7 partitions per launch a seed is one slot in five to seven.

## Soundness

- **c0 and dm.** e^k − a^k only grows from one slot to the next. While it stays below b^c0, ndig(e^k − a^k) ≤ c0, and since ndig never decreases, max(cap, ndig) and its clamp to the power's digit count stay at c0. It reaches b^c0 exactly when dm − step < 0, the subtraction's borrow; then b^c0 − 1 − dm (mod 2^(32·nl)) is the difference itself, and c0 and dm are formed as at a seed. For c0 below the power's digit count, b^c0 ≤ b^(s − 1) ≤ x < 2^(32·nl), so dm fits its words; at c0 = s the carry test is skipped, as before, and c0 cannot grow, so nothing is re-formed. (x mod b^c0) + d ≥ b^c0 ⟺ x mod b^c0 > b^c0 − 1 − d = dm.
- **Above the run.** The run ends only at a digit at or above c0, so after it every digit is above c0: the per-digit step then sets the digit's bit in both masks, cannot end the run, and adds nothing to x mod b^c0. The short path does exactly that.
- **Clipping.** P·w ≥ s for P > plo and P·w + w − 1 ≤ e − 1 for P < phi, so only plo and phi can be clipped; a step reuses the previous slot's state and needs neither endpoint.
- **Ballot.** The ballot's popcount and the popcount of its bits below a lane are the sum and the exclusive prefix sum of the 0/1 flags.
- **Early-exit carries.** A packed word plus the bias with no carry-in comes back unchanged: no byte reaches 256, every byte keeps bit 7, so the bias is taken back, and the carry-out is 0. In binary, x + 0xFFFFFFFF + 1 = x with carry 1. Skipping those words is the same as running them. The words above the comptime bounds are zero.
- **The plan.** Only the survivor bound changes; the budget and largest-binding bounds are the same, so every layout still fits the device the way the plan says (b62 1e17: 7 partitions per launch at most, 2,438 MiB; b60 1e16: 6, 2,260 MiB; both within the 2,560 MiB budget of a 10 GB card). A batch whose survivors overflow its list is re-run in smaller batches, as before; no run below re-ran a batch (dense b58 1e15: 16 partitions per launch, dense b62 1e16: 9, 0 re-runs).

MEASUREMENTS_PLACEHOLDER

🤖 Generated with [Claude Code](https://claude.com/claude-code)
