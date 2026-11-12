# T2.3 audit: sampled re-verification of nice-only submissions, bases 58 and 60 (2026-11-12)

STATE AT HAND-BACK (18:2x UTC): the box went offline at ~18:03 UTC mid-run (Vast status "offline", ssh refused); everything
it produced up to 18:02 is on ivory under `raw/box/`. b58 is essentially done; b60 is mostly NOT re-run (section 7).
Labels: **[measured]** read off the API or a run,
**[derived]** computed from measured numbers, **[assumed]** stated without a measurement.

## 1. Census (ivory, public API, read-only)

Scripts `raw/census_fields.py`, `raw/census_subs.py` (bounded id ranges only: fields 206.7M–207.1M by 100k ids
with `base_id=in.(58,60)`; submissions 264.0M–294.5M by 100k ids with `search_mode=eq.niceonly` and the b58/b60
field-id window; 0.2 s apart; User-Agent nice-audit-census; 4 + 305 requests, 3 min). Data
`raw/fields_b58_b60.json`, `raw/subs_b58_b60.json` (compact columns), grouping `raw/census_cells.py`,
table `raw/census_table.md`.

- b58: 93,573 fields of 1e15 [measured], all check_level 1; every field has ≥ 1 qualified nice-only
  submission; 93,585 qualified submissions (12 fields twice).
- b60: 162,076 fields of 1e16 [measured]; 146,268 have a qualified submission; 15,808 (9.76 % of the range) have
  none and are check_level 0, i.e. not searched yet (outside this audit). 159,541 qualified submissions, 13,234
  fields searched more than once (mostly the re-searches after the M4 disqualification).
- 11,473 disqualified submissions (the M4 pre-#222 set), excluded from cells.
- Every qualified submission with valid_numbers > 0 has survivors > 0, and every one with valid_numbers = 0
  has survivors = checked = 0 [measured]: no field shows a join that "dropped everything". Empty fields
  (decided by the CPU-side MSD filter before any join runs) are excluded from the sample populations.
- Cells (GPU family × build): see `raw/census_table.md`. Shares are per submission, so a base's shares
  sum to slightly more than its searched fraction.

## 2. Mechanism (route (b): the real client against a local stub)

- Box: Vast 60374124, RTX 3080 (350 W cap), 64 threads, CUDA driver 595.99 (CUDA 13.2), NVRTC 12.8.
- Production hosts blocked before any client ran: `api.`, `data.`, `www.nicenumbers.net` and `nicenumbers.net`
  mapped to 127.0.0.1 and ::1 in the box's /etc/hosts; `curl https://<host>/` fails with exit 7 for each
  (15:43 UTC and again 17:09 UTC); github.com still reachable. Proof: `raw/proof_hosts_block.txt`. The only
  nicenumbers host in any built binary's strings is `api.nicenumbers.net` (the `--api-base` default), and every
  run passes `--api-base http://127.0.0.1:<port>` (and `NICE_API_BASE`); `raw/run_queue.sh` refuses to start if
  any production host answers or the hosts block is missing. No census query ran from the box.
- `raw/stub_api.py` (127.0.0.1 only) answers `GET /claim/niceonly` with the next field of a list
  (claim_id = the field id) and records every `POST /submit` body; nothing is forwarded. After the list it hands
  out a trivial padding field (base 10, 47..100, claim_id 1) so the client keeps cycling and submits what it holds
  (a 503 made the client give up and abandon in-flight work: the first 5-field trial lost one field that way).
- Client: each build compiled from its exact commit on the box (`raw/box_build.sh`, `--features gpu,cubecl-cuda`,
  one CARGO_TARGET_DIR per build), run as `nice-<sha> niceonly --telemetry --gpu --repeat --threads 8`
  (GPU backend auto = what the NVIDIA fleet ran; the join runs on CubeCL CUDA). The submitted telemetry's
  `build_sha` was checked per row by the comparison.
- Builds: 9a4f7406 (v3.4.6), 8c088a28, c72e2c6f, cb38b917, 18cba8bc, 8bd154bc (v3.4.7), 6f060a94, c0c357ae
  (current demoux main) all built and ran. 9bde4a87 was not built (its 20-field cell was compared against
  c0c357ae, see rules).



| base 58 cell (GPU family, build, version) | qualified subs | share of base range | non-empty (population) | sample target |
|---|---|---|---|---|
| RX 9070 XT [Vulkan, wgpu<spirv>], 9a4f7406, 3.4.6 | 42,794 | 45.73 % | 33,950 | 149 |
| TITAN Xp, 9a4f7406, 3.4.6 | 13,350 | 14.27 % | 12,189 | 149 |
| RTX 2070, 9a4f7406, 3.4.6 | 13,202 | 14.11 % | 12,097 | 149 |
| RTX 3060, 9a4f7406, 3.4.6 | 8,903 | 9.51 % | 8,255 | 59 |
| RX 9070 XT [Vulkan, wgpu<spirv>], c0c357ae, 3.4.8-dev | 3,415 | 3.65 % | 3,202 | 59 |
| RTX 4060, 9a4f7406, 3.4.6 | 2,734 | 2.92 % | 2,525 | 59 |
| RTX A2000, 9a4f7406, 3.4.6 | 2,423 | 2.59 % | 2,276 | 59 |
| RTX 4060 Ti, 9a4f7406, 3.4.6 | 1,926 | 2.06 % | 1,797 | 59 |
| no-telemetry, none, 3.4.6 | 1,901 | 2.03 % | 0 | not checkable |
| GTX 1080 Ti, 9a4f7406, 3.4.6 | 1,144 | 1.22 % | 1,076 | 59 |
| RTX 4060, 8bd154bc, 3.4.7 | 745 | 0.80 % | 693 | 20 |
| RTX 3060 Ti, 9a4f7406, 3.4.6 | 299 | 0.32 % | 282 | 20 |
| A100-SXM4-40GB, 9a4f7406, 3.4.6 | 261 | 0.28 % | 218 | 20 |
| Apple M4 [Metal, wgpu<wgsl>], 6f060a94, 3.4.8-dev | 255 | 0.27 % | 238 | 20 |
| CPU/none, 9a4f7406, 3.4.6 | 226 | 0.24 % | 214 | 20 |
| GTX 1070, 9a4f7406, 3.4.6 | 7 | 0.01 % | 5 | 5 |

| base 60 cell (GPU family, build, version) | qualified subs | share of base range | non-empty (population) | sample target |
|---|---|---|---|---|
| RX 9070 XT [Vulkan, wgpu<spirv>], 9a4f7406, 3.4.6 | 52,093 | 32.14 % | 44,386 | 149 |
| RX 9070 XT [Vulkan, wgpu<spirv>], 6f060a94, 3.4.8-dev | 37,714 | 23.27 % | 34,189 | 149 |
| RX 9070 XT [Vulkan, wgpu<spirv>], c0c357ae, 3.4.8-dev | 22,458 | 13.86 % | 20,462 | 149 |
| RTX 3060, 8bd154bc, 3.4.7 | 10,610 | 6.55 % | 10,176 | 59 |
| Apple M4 [Metal, wgpu<wgsl>], 6f060a94, 3.4.8-dev | 4,917 | 3.03 % | 4,805 | 59 |
| GTX 1070, 9a4f7406, 3.4.6 | 4,669 | 2.88 % | 4,226 | 59 |
| RTX 4060, 8bd154bc, 3.4.7 | 4,570 | 2.82 % | 4,263 | 59 |
| RX 9070 XT [Vulkan, wgpu<spirv>], 8c088a28, 3.4.7-dev | 3,845 | 2.37 % | 3,432 | 59 |
| RTX 2070, 9a4f7406, 3.4.6 | 3,508 | 2.16 % | 2,822 | 59 |
| RTX 4060, 9a4f7406, 3.4.6 | 3,028 | 1.87 % | 2,748 | 59 |
| TITAN Xp, 9a4f7406, 3.4.6 | 2,091 | 1.29 % | 2,029 | 59 |
| RTX A2000, 9a4f7406, 3.4.6 | 1,662 | 1.03 % | 1,445 | 59 |
| RTX 3060, 9a4f7406, 3.4.6 | 1,585 | 0.98 % | 1,469 | 20 |
| Apple M4 [Metal, wgpu<wgsl>], c0c357ae, 3.4.8-dev | 1,529 | 0.94 % | 1,505 | 20 |
| RX 9070 XT [Vulkan, wgpu<spirv>], c72e2c6f, 3.4.7-dev | 1,468 | 0.91 % | 1,448 | 20 |
| GTX 1080 Ti, 9a4f7406, 3.4.6 | 1,127 | 0.70 % | 1,082 | 20 |
| RTX 2070, 8bd154bc, 3.4.7 | 596 | 0.37 % | 586 | 20 |
| RTX 3050, 8bd154bc, 3.4.7 | 502 | 0.31 % | 496 | 20 |
| GTX 1080, 9a4f7406, 3.4.6 | 462 | 0.29 % | 425 | 20 |
| GTX 1650, 9a4f7406, 3.4.6 | 288 | 0.18 % | 264 | 20 |
| GTX 1080 Ti, 8bd154bc, 3.4.7 | 278 | 0.17 % | 240 | 20 |
| RTX 3070, 9a4f7406, 3.4.6 | 150 | 0.09 % | 139 | 20 |
| RTX 3060 Ti, 8bd154bc, 3.4.7 | 144 | 0.09 % | 140 | 20 |
| RX 9070 XT [Vulkan, wgpu<spirv>], 18cba8bc, 3.4.7-dev | 107 | 0.07 % | 107 | 20 |
| RX 9070 XT [Vulkan, wgpu<spirv>], 9bde4a87, 3.4.8-dev | 97 | 0.06 % | 97 | 20 |
| GTX 1660 Ti, 9a4f7406, 3.4.6 | 15 | 0.01 % | 15 | 15 |
| RTX 3070, 8bd154bc, 3.4.7 | 13 | 0.01 % | 13 | 13 |
| RX 9070 XT [Vulkan, wgpu<spirv>], cb38b917, 3.4.7-dev | 12 | 0.01 % | 12 | 12 |
| RTX 3050, 9a4f7406, 3.4.6 | 3 | 0.00 % | 3 | 3 |


## 3. What the counters mean, by build (the key finding for method)

- **Exact and deterministic only from #236 (b5802146) on**: 6f060a94 and c0c357ae. Census: every same-build pair of
  qualified submissions on one field agrees to the unit: 6f060a94 461 pairs (157 of them M4 vs 9070 XT),
  c0c357ae 125 pairs (25 M4 vs 9070 XT) [measured, `raw/dupcheck.txt`].
- **Timing dependent before #236** (9a4f7406, 8c088a28, c72e2c6f, cb38b917 have no #222 either; 18cba8bc, 8bd154bc,
  9bde4a87 have #222): a survivor that overruns the stage leaves `survivors` and is fully checked without the
  prefilter, so even the same build on the same device rarely reproduces the pair (9a4f7406: 670 of 9,362 census
  pairs equal) [measured]. What such a run preserves when it loses nothing is I = survivors + checked/(1 − q), q the
  overrun survivors' own pass rate (≈ p = checked/survivors; census q/p 0.97–1.005, p10–p90) [measured/derived].
- **Meanings differ across builds**: 9a4f7406 counts ≈ 1.07× (survivors) and 1.10× (checked) what c0c357ae counts on
  the same b58 field, varying 1.05–1.29 / 1.07–1.38 by field (134 fields) [measured, `raw/box/out_Q2_oracle_b58.jsonl`];
  census cross-build ratios: 8c088a28 / 9a4f7406 0.827, 9a4f7406 / c72e2c6f 1.20, 18cba8bc / 9a4f7406 0.82, but
  8bd154bc and 9bde4a87 ≈ 6f060a94 / c0c357ae within overrun noise [measured, `raw/crossbuild.txt`].
  So a c0c357ae run is no reference for 9a4f7406 (my first oracle attempt: all 134 9a4f7406 fields "mismatched" by
  +5–30 %, an artefact, discarded) but is one for 8bd154bc / 9bde4a87.

## 4. Comparison rules (`raw/compare.py`)

1. **exact** (6f060a94, c0c357ae): same-build re-run; match iff survivors and checked both equal.
2. **invariant vs same build** (9a4f7406, 8c088a28, c72e2c6f, 18cba8bc, cb38b917): same-build re-run on the 3080;
   p = checked/survivors of the re-run; r = (I_orig − I_rerun)/survivors_rerun; match iff |r| ≤ 3e-7 + 0.06·p·|Δsurvivors|/T
   (the second term covers q ≠ p when either run overran a lot). The same rule flags 3 of 11,087 census same-build
   pairs (section 6).
3. **overrun model vs c0c357ae** (8bd154bc, 9bde4a87): T, P = c0c357ae's exact counts; x = T − survivors must be ≥ 0
   and |checked − P − x(1 − P/T)| ≤ 5·sqrt(x·p(1 − p)) + 2.

A lost candidate lowers I (a deficit); the #222 race's stale-entry checks raise checked (an excess). Caveat: per #222's
own text the race can also overwrite list entries, which loses candidates *without* changing the counts, so for
pre-#222 builds counter agreement is necessary, not sufficient [assumed from the PR text; the M4 measurements of
2026-11-10 found count and list deficits of similar size].

## 5. Validation of the mechanism (current main on demoux's fields)

c0c357ae on the 3080 reproduced demoux's c0c357ae counters exactly on **59 of 59 b58 and 149 of 149 b60** sampled
fields, and the M4's c0c357ae counters on 20 of 20 b60 fields (exact equality of both counters, every field)
[measured, `raw/box/out_c0c_b58.jsonl`, `out_Q1_c0c.jsonl`]. A wgpu/Vulkan AMD card, Metal M4 and CUDA 3080 agree to
the unit on this build. 9a4f7406 re-runs on the 3080 also overrun (|Δsurvivors|/T median 3.6e-6, max 2.2e-4), and the
invariant held on all of them (max |r|/tol 0.40, max |r| 2.1e-7) [measured].

## 6. Results per cell

| base | cell | rule | share | subs | non-empty | sampled (target) | matched | mismatched | 95 % bound |
|---|---|---|---|---|---|---|---|---|---|
| 58 | RX 9070 XT [Vulkan, wgpu<spirv>], 9a4f7406 | invariant vs same build | 45.73 % | 42,794 | 33,950 | 145 (149) | 145 | 0 | 2.0 % |
| 58 | TITAN Xp, 9a4f7406 | invariant vs same build | 14.27 % | 13,350 | 12,189 | 144 (149) | 144 | 0 | 2.1 % |
| 58 | RTX 2070, 9a4f7406 | invariant vs same build | 14.11 % | 13,202 | 12,097 | 145 (149) | 145 | 0 | 2.0 % |
| 58 | RTX 3060, 9a4f7406 | invariant vs same build | 9.51 % | 8,903 | 8,255 | 58 (59) | 58 | 0 | 5.0 % |
| 58 | RX 9070 XT [Vulkan, wgpu<spirv>], c0c357ae | exact, same build | 3.65 % | 3,415 | 3,202 | 59 (59) | 59 | 0 | 5.0 % |
| 58 | RTX 4060, 9a4f7406 | invariant vs same build | 2.92 % | 2,734 | 2,525 | 57 (59) | 57 | 0 | 5.1 % |
| 58 | RTX A2000, 9a4f7406 | invariant vs same build | 2.59 % | 2,423 | 2,276 | 58 (59) | 58 | 0 | 5.0 % |
| 58 | RTX 4060 Ti, 9a4f7406 | invariant vs same build | 2.06 % | 1,926 | 1,797 | 57 (59) | 57 | 0 | 5.1 % |
| 58 | no-telemetry, none | not checkable (no telemetry) | 2.03 % | 1,901 | 0 | 0 (0) | 0 | 0 | — |
| 58 | GTX 1080 Ti, 9a4f7406 | invariant vs same build | 1.22 % | 1,144 | 1,076 | 57 (59) | 57 | 0 | 5.1 % |
| 58 | RTX 4060, 8bd154bc | overrun model vs c0c357ae | 0.80 % | 745 | 693 | 3 (20) | 3 | 0 | 63.2 % |
| 58 | RTX 3060 Ti, 9a4f7406 | invariant vs same build | 0.32 % | 299 | 282 | 20 (20) | 20 | 0 | 13.9 % |
| 58 | A100-SXM4-40GB, 9a4f7406 | invariant vs same build | 0.28 % | 261 | 218 | 20 (20) | 20 | 0 | 13.9 % |
| 58 | Apple M4 [Metal, wgpu<wgsl>], 6f060a94 | exact, same build | 0.27 % | 255 | 238 | 0 (20) | 0 | 0 | — |
| 58 | CPU/none, 9a4f7406 | invariant vs same build | 0.24 % | 226 | 214 | 19 (20) | 19 | 0 | 14.6 % |
| 58 | GTX 1070, 9a4f7406 | invariant vs same build | 0.01 % | 7 | 5 | 5 (5) | 5 | 0 | 45.1 % |
| 60 | RX 9070 XT [Vulkan, wgpu<spirv>], 9a4f7406 | invariant vs same build | 32.14 % | 52,093 | 44,386 | 3 (149) | 3 | 0 | 63.2 % |
| 60 | RX 9070 XT [Vulkan, wgpu<spirv>], 6f060a94 | exact, same build | 23.27 % | 37,714 | 34,189 | 0 (149) | 0 | 0 | — |
| 60 | RX 9070 XT [Vulkan, wgpu<spirv>], c0c357ae | exact, same build | 13.86 % | 22,458 | 20,462 | 149 (149) | 149 | 0 | 2.0 % |
| 60 | RTX 3060, 8bd154bc | overrun model vs c0c357ae | 6.55 % | 10,610 | 10,176 | 0 (59) | 0 | 0 | — |
| 60 | Apple M4 [Metal, wgpu<wgsl>], 6f060a94 | exact, same build | 3.03 % | 4,917 | 4,805 | 0 (59) | 0 | 0 | — |
| 60 | GTX 1070, 9a4f7406 | invariant vs same build | 2.88 % | 4,669 | 4,226 | 1 (59) | 1 | 0 | 95.0 % |
| 60 | RTX 4060, 8bd154bc | overrun model vs c0c357ae | 2.82 % | 4,570 | 4,263 | 0 (59) | 0 | 0 | — |
| 60 | RX 9070 XT [Vulkan, wgpu<spirv>], 8c088a28 | invariant vs same build | 2.37 % | 3,845 | 3,432 | 0 (59) | 0 | 0 | — |
| 60 | RTX 2070, 9a4f7406 | invariant vs same build | 2.16 % | 3,508 | 2,822 | 1 (59) | 1 | 0 | 95.0 % |
| 60 | RTX 4060, 9a4f7406 | invariant vs same build | 1.87 % | 3,028 | 2,748 | 2 (59) | 2 | 0 | 77.6 % |
| 60 | TITAN Xp, 9a4f7406 | invariant vs same build | 1.29 % | 2,091 | 2,029 | 1 (59) | 1 | 0 | 95.0 % |
| 60 | RTX A2000, 9a4f7406 | invariant vs same build | 1.03 % | 1,662 | 1,445 | 1 (59) | 1 | 0 | 95.0 % |
| 60 | RTX 3060, 9a4f7406 | invariant vs same build | 0.98 % | 1,585 | 1,469 | 0 (20) | 0 | 0 | — |
| 60 | Apple M4 [Metal, wgpu<wgsl>], c0c357ae | exact, same build | 0.94 % | 1,529 | 1,505 | 20 (20) | 20 | 0 | 13.9 % |
| 60 | RX 9070 XT [Vulkan, wgpu<spirv>], c72e2c6f | invariant vs same build | 0.91 % | 1,468 | 1,448 | 0 (20) | 0 | 0 | — |
| 60 | GTX 1080 Ti, 9a4f7406 | invariant vs same build | 0.70 % | 1,127 | 1,082 | 1 (20) | 1 | 0 | 95.0 % |
| 60 | RTX 2070, 8bd154bc | overrun model vs c0c357ae | 0.37 % | 596 | 586 | 0 (20) | 0 | 0 | — |
| 60 | RTX 3050, 8bd154bc | overrun model vs c0c357ae | 0.31 % | 502 | 496 | 0 (20) | 0 | 0 | — |
| 60 | GTX 1080, 9a4f7406 | invariant vs same build | 0.29 % | 462 | 425 | 0 (20) | 0 | 0 | — |
| 60 | GTX 1650, 9a4f7406 | invariant vs same build | 0.18 % | 288 | 264 | 0 (20) | 0 | 0 | — |
| 60 | GTX 1080 Ti, 8bd154bc | overrun model vs c0c357ae | 0.17 % | 278 | 240 | 0 (20) | 0 | 0 | — |
| 60 | RTX 3070, 9a4f7406 | invariant vs same build | 0.09 % | 150 | 139 | 0 (20) | 0 | 0 | — |
| 60 | RTX 3060 Ti, 8bd154bc | overrun model vs c0c357ae | 0.09 % | 144 | 140 | 0 (20) | 0 | 0 | — |
| 60 | RX 9070 XT [Vulkan, wgpu<spirv>], 18cba8bc | invariant vs same build | 0.07 % | 107 | 107 | 0 (20) | 0 | 0 | — |
| 60 | RX 9070 XT [Vulkan, wgpu<spirv>], 9bde4a87 | overrun model vs c0c357ae | 0.06 % | 97 | 97 | 0 (20) | 0 | 0 | — |
| 60 | GTX 1660 Ti, 9a4f7406 | invariant vs same build | 0.01 % | 15 | 15 | 0 (15) | 0 | 0 | — |
| 60 | RTX 3070, 8bd154bc | overrun model vs c0c357ae | 0.01 % | 13 | 13 | 0 (13) | 0 | 0 | — |
| 60 | RX 9070 XT [Vulkan, wgpu<spirv>], cb38b917 | invariant vs same build | 0.01 % | 12 | 12 | 0 (12) | 0 | 0 | — |
| 60 | RTX 3050, 9a4f7406 | invariant vs same build | 0.00 % | 3 | 3 | 0 (3) | 0 | 0 | — |

Bound = 95 % one-sided upper bound on the cell's per-field rate of counter disagreement given zero mismatches
(1 − 0.05^(1/n)) [derived]; it bounds fields that disagree, not candidates.
Sample: `raw/make_sample.py` (seed 20261112, time-stratified, written before any run: `raw/sample.json`, queues
`raw/queue_*.json`). Every sampled field ran with its cell's build except the 8bd154bc b58 cell (rule 3).

**Mismatches in the re-runs: none** (0 of 1,026 compared submissions: 795 under rule 2, 228 under rule 1, 3 under rule 3)
[measured, `raw/compare.txt`, `raw/compare_detail.jsonl`].

**Census-level same-build cross-check (free, not a random sample)** — `raw/dup_rule.py` → `raw/dup_rule.txt`,
`raw/pair_cover.py` → `raw/pair_cover.txt`. Of 11,087 same-build pairs of qualified submissions on pre-#236 builds,
3 break the invariant, all on 9a4f7406 b60, **all excesses of `checked`** (the #222 race's stale-entry signature), on
three device families, none Apple:

| field | the off submission | the other submission | my 9a4f7406 re-run (3080) |
|---|---|---|---|
| 206943130 | 268729348 wp-vast-fleet GTX 1080: surv 172,426,289,017 chk 11,297,004,429 (r = +3.29e-5 vs re-run) | 268719456 demoux 9070 XT: 172,466,274,343 / 11,254,321,048 (r = −1.05e-7, matches) | 172,440,774,765 / 11,278,169,780 |
| 206950836 | 269917800 wp-vast-fleet TITAN Xp: 88,600,810,065 / 5,791,565,076 (r = +2.83e-5) | 269893752 same card class: 88,600,810,128 / 5,789,219,256 (r = +4.1e-9, matches) | 88,600,622,909 / 5,789,393,904 |
| 206956667 | 270992509 demoux 9070 XT: 8,126,941,029 / 536,352,273 (checked +10,006 over the other with survivors −15) | 270982919 demoux 9070 XT: 8,126,941,044 / 536,342,267 | not re-run (box lost; it headed the b60 queue) |

Reading: on v3.4.6 the #222 race fired in production on a GTX 1080, a TITAN Xp and the RX 9070 XT, not only on the M4
(the 2026-11-09 exposure note's "no measurable trace on AMD/NVIDIA" used a cruder statistic). Detectable rate ≈ 3 per
11,087 pairs ≈ 1.4e-4 per submission [derived]; applied to the ~95k b60 and ~88k b58 9a4f7406 submissions that is of
order 10 fields per base [derived, rough]. Each such event may also have overwritten list entries (lost candidates)
that counts cannot show. All three fields have a second, consistent qualified submission, so each is covered. No
other cell shows a single disagreement in its census pairs (8c088a28 1,094 subs with a partner, 8bd154bc 1,665,
6f060a94 911, c0c357ae 250, c72e2c6f 560, ...; `raw/pair_cover.txt`). Nothing was changed, re-queued or reported anywhere.

The three b60 pairs that my first, cruder tolerance (|r| > 3e-6 with the pair's own p) also flagged (206953754,
206954374, 206956663) are explained by large overruns: the three runs of 206953754 (9070 XT, GTX 1070, 3080 re-run)
lie on one line in (survivors, checked) to 1.5e-4 in slope, i.e. lossless with q = 0.066 against p = 0.069 [measured].

## 7. Bottom line

**Base 58** (all 93,573 fields searched): 74.1 % of the range lies in cells verified clean at a ≤ 2.1 % per-field bound
(9070 XT, TITAN Xp, RTX 2070 on 9a4f7406); 22.0 % in cells clean at ≤ 5.1 % (RTX 3060, 4060, A2000, 4060 Ti,
GTX 1080 Ti on 9a4f7406; 9070 XT on c0c357ae); 0.85 % in small cells clean at 14–45 % (3060 Ti, A100, the 9a4f7406
CPU cell, GTX 1070); 0.80 % (RTX 4060, 8bd154bc) only 3 fields; 0.27 % (M4, 6f060a94) not re-run; **2.03 % (anvil,
1,901 fields, v3.4.6 without telemetry) cannot be checked by counters at all**. Caveat for 93 % of b58 (pre-#222
builds): a race event that only overwrote entries is invisible to counters; the census suggests such events are rare
(~1e-4 per field) but not absent.

**Base 60** (146,268 of 162,076 fields searched, 90.2 % of the range): verified by re-run only the c0c357ae cells:
9070 XT 13.9 % of the range at ≤ 2.0 %, M4 0.94 % at ≤ 13.9 %. **Not verified by re-run** (box lost at 18:03 UTC):
9a4f7406 cells ≈ 47 % of the range (10 fields run, all clean), 6f060a94 cells 26.3 %, 8bd154bc cells 10.6 %,
8c088a28 2.4 %, c72e2c6f 0.9 %, the rest < 0.3 %. For those only the census same-build pairs speak: 6f060a94 exact on all
461 pairs; pre-#236 builds 3 race excesses in 11,087 pairs (above). 9.8 % of the range is not searched yet.

## 8. What could not be checked, and what remains

- The anvil no-telemetry b58 cell (2.03 %): no counters; only a full re-search would cover it.
- Pre-#222 builds (9a4f7406 and the three dev builds): counter-silent overwrite losses (section 4 caveat).
- b60 re-runs, in the prepared order (queues on ivory, ready to run unchanged on any CUDA box with the same scripts):
  `raw/QC1_oracle_8bd1_9bde.json` (231 fields, c0c357ae, ≈ 9 s each), `raw/QD_<build>.json` (56 fields of
  8c088a28/c72e2c6f/18cba8bc/cb38b917, own builds, ≈ 30 s), `raw/Q3s_6f06.json` (100 fields, 6f060a94, ≈ 12 s; full
  sample `raw/Q3_6f06.json` 228), `raw/QE_9a4f_b60.json` (553 fields of 9a4f7406, ≈ 37 s each on a 3080 = 5.7 h;
  field 206956667 first). Sequence and commands: `raw/chain3.sh`, `raw/run_queue.sh`, `raw/box_build.sh`.
- b58: the remaining 22 of 787 9a4f7406 sample fields and 17 of 20 8bd154bc ones; the M4 6f060a94 cell (20).

## 9. Files

`raw/`: census (`census_fields.py`, `census_subs.py`, `census_cells.py`, `census_table.md`, `fields_b58_b60.json`,
`subs_b58_b60.json`), sample (`make_sample.py`, `sample.json`, `queue_*.json`, `Q*.json`), box side (`stub_api.py`,
`run_queue.sh`, `box_build.sh`, `chain*.sh`, `extract.py`, `proof_hosts_block.txt`), raw outputs (`box/out_*.jsonl` =
every submission body the clients sent to the stub, `box/client_*.log`, `box/stub_*.log`, `box/runs.log`),
analysis (`compare.py` → `compare.txt`, `compare.json`, `compare_detail.jsonl`, `cell_table.md`; `dupcheck.py`,
`dup_invariant.py`, `dup_rule.py`, `pair_cover.py` with their `.txt` outputs; `outlier_pairs_9a4f.json`).
