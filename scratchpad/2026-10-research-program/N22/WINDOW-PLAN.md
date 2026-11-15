# N22 window plan: the RX 9070 XT, at most 30 minutes (2026-11-15)

**What it decides.** Whether **W** (the walk as a per-lane loop on SPIR-V; ACO −4 ALU per walk round) is the
predicted ×1.04–1.05 at b64 1e17, and how much **W + B** (B = b64's low digits as one bit field, −2 more), **K**
(the check kernel's limb products in 24-bit multiplies) and **A** (fixed-trip AND digit loop) add. W + B is the
PR-shaped result if both land: W as its own PR (gated to `wgpu<spirv>`), B folded into #255 as N21 recommended.
Everything is one binary with switches (`NICE_EXP_N22`), so the window builds once.

**Binary.** X = fork `exp/n22-rdna4` at `c750605e` (or its head; `git log` it into the log), production's features
`--features gpu,cubecl-spirv`, `cargo test --release -p nice_common --no-run`. Modes (`NICE_EXP_N22`): **0** =
`exp/integration-1114`'s kernels (8bcee21: main + #251 + #255 + #256 + #259 + #260), **2** = W, **10** = W + B,
**16** = K, **32** = A. Bit 1 is not needed on the card (its planes are 64 lanes: the scan forms already).

**Scripts** (`raw/scripts/window/`, from N21's `window13/` with the switch renamed): `env.sh`, `wrun.sh` (one
process of `join_throughput_fixed_fields`: one untimed 1e14 warm-up field, then the timed field; the card sampled
every 2 s from sysfs: busy, shader clock, power, temperature), `go22.sh` (the order below, `END_AT` and the stop
file), `analyze_window.py` (per run: seconds, counts, median clock / power over ≥ 80 % busy samples, OFF-POINT
flag; per field and mode: base ÷ mode per round and the median).

**Fix carried in `go22.sh`:** cargo 1.100 (the repo's pin) no longer puts the test binary under
`target/release/deps/`; `go13.sh`'s `grep -o "$W/target-…/deps/nice_common-…"` finds nothing. `go22.sh` takes the
path cargo prints (`Executable unittests src/lib.rs (…)`).

## Steps (director, on demoux, production client stopped by the user)

1. `W=/tmp/claude-exp-$(date +%Y%m%d)-amd; mkdir -p $W/scripts $W/wt; cp N22/raw/scripts/window/* $W/scripts/`;
   `git -C ~/nice-src worktree add --detach $W/wt/X <commit>` (or a fresh clone of the fork at that commit).
2. `W=$W END_AT=$(( $(date +%s) + 29*60 )) sh $W/scripts/go22.sh 2>&1 | tee $W/out/go.out` (build ≈ 3–5 min at
   `JOBS=12`; if the build has not finished by minute 6, stop and report).
3. Order and budget (seconds at today's speed, [D] from §1 of RESULTS: b64 ≈ 93–96 s, b62 ≈ 58–59 s, + ≈ 5 s
   warm-up each):
   - **b64 1e17 at 0.55, three rotated rounds of 0 / 2 / 10 / 16** (12 runs, ≈ 20 min): the decision.
   - **b62 1e17 at 0.45, one round of 0 / 2 / 16 / 32** (4 runs, ≈ 4 min).
   - spare if time is left: b62 round 2 of 16 / 0 / 32 / 2.
4. **Accept a run** only if `analyze_window.py $W/out 3150 300` shows it on point: median clock ≥ 97 % of 3,150 MHz
   and power ≥ 90 % of 300 W over its ≥ 80 % busy samples (N13.2: this card's clock follows its load; every timed
   run of N17.1 and N21.2 sat at 3.0–3.2 GHz and 302–305 W), and counts (survivors, checked) identical to the mode-0
   run of the same field. A run off point is re-run once in the spare slot, not averaged in.
5. `touch $W/stop` ends it before the next run; at the end remove `$W` (copy `$W/out` to ivory first), stop the
   sampler by PID if it is still alive, and report.

## What the numbers mean

| measured on the card | reading |
|---|---|
| mode 2 ÷ 0 at b64 ≥ ×1.05 (three rounds, spread < 1 %) | W is a PR on its own (the bar for a simple change); gate it to `wgpu<spirv>` as #259 is (CUDA keeps the vote: see the CUDA table) |
| mode 2 at b64 ×1.03–1.05, mode 10 ≥ ×1.05 | W + B: W as a PR stacked on #255 with B folded into #255 (the director's call; B is #255's own two lines) |
| mode 2 < ×1.03 | the per-instruction price does not hold for SALU savings; the walk round is at its floor for this method |
| mode 16 ≥ ×1.03 at b64 | the check kernel is issue-bound on the card (the 24-bit form's −33 % VALU issue shows); worth a PR only if ≥ ×1.05 |
| mode 32 at b62 | the AND's ALU price (A: −24 % of the digit loop's instructions); ×1.02 would match the count model |

The doubling method of N17.1 is not needed for these decisions (each candidate is timed directly, at full load,
against the same binary's mode 0); if the window has time left after the spare, one doubled-check run (N16's
`exp/n16-join-base` modes) would re-measure the check's share after #251, which §1 only infers.
