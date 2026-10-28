# Research ledger

One entry per lead. Status: idea → scoping → active → paused → verdict (merged / closed /
parked). A lead gets a kill criterion before any work starts. Evidence lives in
EXPERIMENTS.md and the per-lead directories. BACKLOG numbers refer to
`../2026-10-next-steps/BACKLOG.md`.

Reopening: closed items may be reopened with a written reason for what the earlier
verdict missed (user, 2026-10-28).

## Active and queued

| id | lead | path | status | expected | cost | kill criterion | last update |
|---|---|---|---|---|---|---|---|
| L1 | Join per-prefix cost at b62–b64 (BACKLOG 68): phase profile per base; why cost per prefix climbs ~2.5× at b64, and whether b62 already pays part of it | compute | active (day 1: roots-per-base explanation found, CPU counts + GPU profile running) | 5–20 % on b62_msd_weak | 2 days, ~$1 | profile shows the climb is irreducible bottom-layer work | 2026-10-28 |
| L2 | Detailed mode by finite differences (digit arrays updated by addition; supersedes BACKLOG 55's SIMD framing; `L2/SCOPING.md`) | compute | scoped; prototype queued | 3–8× on b40/b50_detailed (op-count estimate) | 1 agent-day prototype, 1–2 weeks to PR | scalar prototype under 1.3× on b50_detailed_1t | 2026-10-28 |
| L3 | Detailed mode GPU: compute-bound on per-number long division (`L3/NOTES.md`); the L2 finite-difference scheme targets exactly that | compute | scoped; merged into L2's plan (CPU prototype first, GPU port second) | unknown | 3 days, ~$1 | already bound by the final check | 2026-10-28 |
| L5 | CUDA occupancy hint for the join (BACKLOG 19); now also the wave size / entries-per-thread question (EPT 5 beat 4 and 6 at b62/b64 on a 3080, L1.2) | compute | queued, after the prune | 0–5 % | 1 day, $0.50 | no scenario moves 2 % | 2026-10-28 |
| L7 | Weekly literature sweep: arXiv math.NT / cs.DS / cs.DC; GPU hash-join and bit-sliced scan work for the AND scan | math+compute | recurring (weekly) | leads | 2 h/week | none | 2026-10-28 |
| L8 | Near-miss tail test (BACKLOG 39) | science | queued | model validation | 2 days | none | 2026-10-28 |
| L9 | H100 / L40S on the join (BACKLOG 59) | sourcing | queued | fleet pricing data | $1 | none | 2026-10-28 |
| L10 | Join past 64 (BACKLOG 31, `exp/join-wide`) | compute | held by the user until b64 is close | b65 $27–49K vs $1.0M | large | — | 2026-10-28 |

## Candidate pool (not yet scoped)

| id | lead | path | note |
|---|---|---|---|
| L11 | Browser nice-only through the CPU join in wasm (BACKLOG 36) | outreach | capability, not a benchmark number; needs a "convincing reason" case |
| L12 | GPU stride floor ladder cost in candidates (BACKLOG 66) | compute | stride path only matters above 64 or for detailed |
| L13 | CPU stride depth-22 cap wastes ~half the work in large chunks (BACKLOG 65) | compute | same condition as L12 |
| L14 | LSD tree / H1 above base 64 (BACKLOG 53): 2.1–2.85× over the scan at b65 | compute | only if the join is not extended (competes with L10) |
| L15 | Compute sourcing: Anvil/ACCESS allocations, BOINC (undecided, detailed-only), volunteers via the discussion post | sourcing | user-facing decisions |
| L16 | Stronger reservation masks / full Hall cut (math-reassessment): +1.5–2 % over the shipped closure | math | below the bar alone; feeds L4 |
| L17 | Checker ordering from joint central-window statistics (literature EVALUATION, "joint central-window experiments") | compute+math | cheap to measure on the final check |

## Watch list (report, do not act)

- BACKLOG 13: detailed mode runs out of fields after base 50 (has a deadline; server side).
- BACKLOG 61: fleet pricing defect across benchmark-scale changes; disk storage unbilled in the fleet ledger.
- Account credit (fleet shares it; $23.42 on 2026-10-28).
- The user's open PR queue (19 on 2026-10-28); program PRs capped at 5 open, 2–3 if large.

## Closed (do not reopen without a written reason)

| item | verdict | source |
|---|---|---|
| Carry-state ladder, CP-SAT | frontier states do not collapse; MITM only 2–3× with worse constants and GBs of state | theory eval 2026-08-30 |
| Selective Hall subdivision, tuple domains | production-weighted −0.5 % (b40) / −11 % (b52); 2-slice smoke run misled | theory eval 2026-08-30 |
| b^r+1 filters | 100 % coset saturation b10–20, closed permanently | theory eval 2026-08-30 |
| Theory-review GPU items §8.1–8.3 | null or moot on NVIDIA | theory eval 2026-08-30 |
| Swaenepoel prescribed-digit theorem as a tool | no admissible digit budget at our lengths for any base 50–150 | literature EVALUATION 2026-09-09 |
| Sidon / repetend / few-digit constructions | structurally incompatible with strict pandigitality | literature EVALUATION 2026-09-09 |
| Finite-state carry model as an exact automaton | statistical approximation only | literature EVALUATION 2026-09-09 |
| Per-device join autotune (BACKLOG 35) | only entries-per-thread moves, and it follows a per-base rule | BACKLOG 2026-10-09 |
| Colour-coded join below b80; hand-CUDA join phase 2; removing the 1e13 cutoff; runtime fallback to stride; nice-only under BOINC; PRs #170/#173/#174 | see BACKLOG "Not re-proposed" | BACKLOG 2026-10-09 |
| Routing fields by predicted cost | does not change throughput (user) | filter map round 3, 2026-10-23 |
| L4: post-join filter bundle (BACKLOG 56, full-Hall cut) | the final check is 8–11 % of a CPU partition and 3–5 % of GPU device time (3.8–9.8 % of the join kernel), under the 15 % kill criterion; halving it cannot reach 5 % | L1.1 / L1.2, 2026-10-28 |
| L6: Bassily–Kátai / Drmota interior-digit distribution as a rejection rule | Drmota 2001 (via Steiner 2002) gives joint uniformity of any *fixed* set of interior positions of n², n³ with a non-effective error term; nothing computable at b58–64, and pandigitality needs all positions jointly. Eight 2020–26 papers checked, none explicit at 20–40 digits. (The note's "4–5 known digits" sizing used t≈6–7; the join's t = L−3 knows ~19–20 output digits. Immaterial to the verdict.) `L6-literature-2026-10-28.md` | research program day 1, 2026-10-28 |
