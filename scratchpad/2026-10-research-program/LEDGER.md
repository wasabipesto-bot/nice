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
| L1 | Join per-prefix cost at b62–b64 (BACKLOG 68): phase profile per base; why cost per prefix climbs ~2.5× at b64, and whether b62 already pays part of it | compute | **PR #215 open (2026-10-29)**: prune ×1.10–1.25 at 1e16 and ×1.4–2.3 at 1e14 vs main 2709d3f on two cards; NiceMark ×1.17–1.22 | 5–20 % on b62_msd_weak | 2 days, ~$1 | — | 2026-10-28 |
| L2 | Detailed mode by finite differences (digit arrays updated by addition; supersedes BACKLOG 55's SIMD framing; `L2/SCOPING.md`) | compute | **#221 merged 2026-10-31** (CPU detailed score ×6.76); GPU port #225 merged too | 5–10× on b40/b50_detailed CPU; GPU unknown | 1–2 days to PR | — | 2026-10-28 |
| L3 | Detailed mode GPU: compute-bound on per-number long division (`L3/NOTES.md`); the L2 finite-difference scheme targets exactly that | compute | **#225 merged 2026-10-31** (3.3–4.0× NVIDIA, 3.0–4.5× M4, exact everywhere after the Metal seed fix) | unknown | 3 days, ~$1 | already bound by the final check | 2026-10-28 |
| L5 | Join wave size: 2 entries per thread with the prune, best at every base on two cards (L1.3/L1.4, EPT2-3080.md); **PR #216 open (2026-10-29)**, stacked on #215; also BACKLOG 19's occupancy hint | compute | PR open | 0–5 % | 1 day, $0.50 | no scenario moves 2 % | 2026-10-28 |
| L7 | Weekly literature sweep: arXiv math.NT / cs.DS / cs.DC; join inner-loop techniques | math+compute | recurring (weekly); sweep 1 done (`L7/2026-10-29.md`): no new papers; brute force near-optimal at 300-entry buckets, two counting experiments proposed (L18, L19) | leads | 2 h/week | none | 2026-10-29 |
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
| L23 | Web runner CPU path on finite differences: `wasm-client/src/lib.rs` calls `process_range_detailed` → `_fd`; wasm32 build check; Playwright parity vs the current wasm on b40/b50 windows; web NiceMark numbers | compute | **PR #227 open, rebased onto main after #221 merged** (33120f0): browser CPU suite ×7.0 (b40 ×10.3, b50 ×6.6), byte-identical on 141 windows |
| L24 | Web runner GPU path on finite differences: port the FD `#[cube]` step into `cubecl_web.rs`'s `detailed_kernel_u32` (own launch shape, one-round-trip near-miss readback, u32-only, WebGPU limits); harness parity; web NiceMark GPU | compute | **approved 2026-10-31 with all 10 decisions (PROPOSAL.md §7); in progress: (a) = **PR #230 open**; bring-up done (headless Metal, no flags; today's kernel exact on Apple); **COMPLETE 2026-10-31: #230, #231, #233 merged; M4 6.7×/10.1×; AMD parity by the user** (M4: 6.7× / 10.1×, exact on every layer)** · plan (`L24/PLAN.md`): ~5 days (10 half-days), of which kernel + native tests 1–2 days, browser parity step + hardware runs ~2.5 days (M4/demoux permission); seed must be refactored to a shared u32 `fd_seed_split16` (re-run of the seed test on the M4); CI's SwiftShader e2e exercises the browser GPU path already; expected ~3× (b40) / 4× (b50) in the browser |
| L25 | **Audit the nice-only CubeCL kernels (join, stride) for the Apple half-shift-divide pattern** (`(x>>16)/K`, `u32(u64>>32)/K`, `% K` with constant K) in the generated WGSL, then a parity run on mayalaran | integrity | **#228 merged 2026-10-31** (M4-confirmed: main lost 934/445 survivors at b50/b54) |
| L26 | Stride prefilter (`candidate_check`, b ≤ 40 only): same half-shift shape in a paired `/`+`%` form that still passes the M4 probe; defensive fix with the #228 construction, user wants it fixed (no cost to current work) | integrity | **PR #229 open (2026-10-31)**; WGSL sites 6→0 at b30/34/40; counts = main on CUDA and lavapipe |
| L27 | Timing-dependent test `threaded_pipeline_matches_the_one_field_form_field_by_field` (adaptive MSD floor under load; CI red 2026-10-31 attempt 1, 3× on boxes) | integrity | **#232 merged 2026-10-31**: floor controller injected at pipeline start; test pins 4000; 1/20 parallel failures before, 30/30 + 40/40 after |
| L22 | Join-kernel flush-decision race (found via L20): **PR #222** (one barrier; correctness) | integrity | merged 2026-10-30 |
| L21 | GPU detailed: read back only the written part of the near-miss buffer (20 MB copied per call today; L3.1): +5–8 % for the current kernel, +30 % with FD | compute | **#224 merged 2026-10-30** (+8.8 % / +7.2 % 3080; +13.7 % / +9.3 % 4090) |
| L20 | **Partitions per launch at production field size** (L1.5): the per-field fixed cost is 40–74 % of a 1e14 field; 16→32 partitions per launch ×0.83–0.92 of the time, 16→64 ×0.78–0.88; needs the bottom buffers sized by the pruned slice (deferred in #215) to go past 32 on 10 GB cards, and the 0.4 % extra full checks seen once at 64 explained | compute | **parked 2026-10-30**: ×0.79–0.88 at 1e14 but neutral at 1e16/1e17, which is where the live b60/b62 fields are; branch kept (`pr/join-partitions-per-launch`) |
| L28 | Native wgpu FD kernel: u32-pair mask instead of the u64 mask (the browser kernel is ~1.8× faster than native on the same M4, L24.3); Apple emulates u64; measure on M4 and lavapipe; NVIDIA via CUDA unaffected | compute | candidate, cheap |
| L18 | Bit-sliced bucket scan: 64 per-digit bitmaps over each ~300-entry bucket, OR-ed over a top's ~17 known digits instead of ~300 ANDs (L7 sweep 1) | compute | counting experiment first; L1.5: real AND lanes are 13–26 % at 1e16 and less at 1e14, so the ceiling is ~10 % end to end; low priority |
| L19 | Static rare-bit bucket partitioning (2–3 levels) to skip 30–45 % of a bucket (L7 sweep 1) | compute | overlaps the signature-bucketing counts of L1.1 (21–42 % for low digits); low priority |

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
