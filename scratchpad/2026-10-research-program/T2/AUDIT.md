# T2.3 audit: sampled re-verification of nice-only submissions, bases 58 and 60 (2026-11-12)

Two boxes: 60374124 (15:38–18:03 UTC, went offline mid-run; its outputs up to 18:02 are in `raw/box/`) and the
replacement 60389955 (RTX 3080, 380 W cap, 16 threads; 18:22–21:46 UTC; outputs in `raw/box2/`), which ran the base-60
queues in the prepared order. Final state: section 7.
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
  (current demoux main) built and ran (8bd154bc's binary only on the first box, unused). 9bde4a87 was not built (its
  cell was compared against c0c357ae, see rules).
- Replacement box 60389955: the same hosts block applied and proven with failing curls at 18:22 UTC before any build
  (appended to `raw/proof_hosts_block.txt`); only the builds its queues needed; each target directory deleted when its
  queue finished (`raw/chain4.sh`, `raw/builds4.sh`, log `raw/box2/runs.log`). The 9a4f7406 queue was re-ordered so any
  prefix holds the cells in proportion to their share of the base (key (i + ½)/share within each cell's already
  shuffled, time-stratified list; field 206956667 first): `raw/QE2_9a4f_b60_byshare.json`. Small cells therefore get
  few or no fields in a short run.



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
   and |d| = |checked − P − x(1 − P/T)| ≤ 5·sqrt(x·p(1 − p)) + 2 + 0.06·p(1 − p)·x.
   **Rule change during the run, stated openly:** the first version had no 0.06 term. On the first 58 b60 fields it
   flagged 34, all with d < 0 growing with x: the overflowing survivors pass the prefilter slightly more often than
   the average (q/p − 1 = +0.1 % to +1 %, measured on those fields; the fleet's v3.4.7 cards overflow 1e-4–4e-3 of a
   field's survivors), so d ≈ −x(q − p) sits 5–27 σ below zero without any loss. I added the same 0.06 band rule 2
   uses; with it all match. What this costs: a loss of up to ≈ 0.06·p·x survivors (≈ 1e-5 of the field at the
   largest overflows seen, 4e-3) would hide in a heavily overflowed field; the M4 defect (median 6.7e-5) would not.

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
| 58 | Apple M4 [Metal, wgpu<wgsl>], 6f060a94 | exact, same build | 0.27 % | 255 | 238 | 9 (20) | 9 | 0 | 28.3 % |
| 58 | CPU/none, 9a4f7406 | invariant vs same build | 0.24 % | 226 | 214 | 19 (20) | 19 | 0 | 14.6 % |
| 58 | GTX 1070, 9a4f7406 | invariant vs same build | 0.01 % | 7 | 5 | 5 (5) | 5 | 0 | 45.1 % |
| 60 | RX 9070 XT [Vulkan, wgpu<spirv>], 9a4f7406 | invariant vs same build | 32.14 % | 52,093 | 44,386 | 149 (149) | 149 | 0 | 2.0 % |
| 60 | RX 9070 XT [Vulkan, wgpu<spirv>], 6f060a94 | exact, same build | 23.27 % | 37,714 | 34,189 | 65 (149) | 65 | 0 | 4.5 % |
| 60 | RX 9070 XT [Vulkan, wgpu<spirv>], c0c357ae | exact, same build | 13.86 % | 22,458 | 20,462 | 149 (149) | 149 | 0 | 2.0 % |
| 60 | RTX 3060, 8bd154bc | overrun model vs c0c357ae | 6.55 % | 10,610 | 10,176 | 59 (59) | 59 | 0 | 5.0 % |
| 60 | Apple M4 [Metal, wgpu<wgsl>], 6f060a94 | exact, same build | 3.03 % | 4,917 | 4,805 | 26 (59) | 26 | 0 | 10.9 % |
| 60 | GTX 1070, 9a4f7406 | invariant vs same build | 2.88 % | 4,669 | 4,226 | 26 (59) | 26 | 0 | 10.9 % |
| 60 | RTX 4060, 8bd154bc | overrun model vs c0c357ae | 2.82 % | 4,570 | 4,263 | 59 (59) | 59 | 0 | 5.0 % |
| 60 | RX 9070 XT [Vulkan, wgpu<spirv>], 8c088a28 | invariant vs same build | 2.37 % | 3,845 | 3,432 | 30 (59) | 30 | 0 | 9.5 % |
| 60 | RTX 2070, 9a4f7406 | invariant vs same build | 2.16 % | 3,508 | 2,822 | 20 (59) | 20 | 0 | 13.9 % |
| 60 | RTX 4060, 9a4f7406 | invariant vs same build | 1.87 % | 3,028 | 2,748 | 20 (59) | 20 | 0 | 13.9 % |
| 60 | TITAN Xp, 9a4f7406 | invariant vs same build | 1.29 % | 2,091 | 2,029 | 12 (59) | 12 | 0 | 22.1 % |
| 60 | RTX A2000, 9a4f7406 | invariant vs same build | 1.03 % | 1,662 | 1,445 | 10 (59) | 10 | 0 | 25.9 % |
| 60 | RTX 3060, 9a4f7406 | invariant vs same build | 0.98 % | 1,585 | 1,469 | 9 (20) | 9 | 0 | 28.3 % |
| 60 | Apple M4 [Metal, wgpu<wgsl>], c0c357ae | exact, same build | 0.94 % | 1,529 | 1,505 | 20 (20) | 20 | 0 | 13.9 % |
| 60 | RX 9070 XT [Vulkan, wgpu<spirv>], c72e2c6f | invariant vs same build | 0.91 % | 1,468 | 1,448 | 10 (20) | 10 | 0 | 25.9 % |
| 60 | GTX 1080 Ti, 9a4f7406 | invariant vs same build | 0.70 % | 1,127 | 1,082 | 7 (20) | 7 | 0 | 34.8 % |
| 60 | RTX 2070, 8bd154bc | overrun model vs c0c357ae | 0.37 % | 596 | 586 | 20 (20) | 20 | 0 | 13.9 % |
| 60 | RTX 3050, 8bd154bc | overrun model vs c0c357ae | 0.31 % | 502 | 496 | 20 (20) | 20 | 0 | 13.9 % |
| 60 | GTX 1080, 9a4f7406 | invariant vs same build | 0.29 % | 462 | 425 | 3 (20) | 3 | 0 | 63.2 % |
| 60 | GTX 1650, 9a4f7406 | invariant vs same build | 0.18 % | 288 | 264 | 2 (20) | 2 | 0 | 77.6 % |
| 60 | GTX 1080 Ti, 8bd154bc | overrun model vs c0c357ae | 0.17 % | 278 | 240 | 20 (20) | 20 | 0 | 13.9 % |
| 60 | RTX 3070, 9a4f7406 | invariant vs same build | 0.09 % | 150 | 139 | 1 (20) | 1 | 0 | 95.0 % |
| 60 | RTX 3060 Ti, 8bd154bc | overrun model vs c0c357ae | 0.09 % | 144 | 140 | 20 (20) | 20 | 0 | 13.9 % |
| 60 | RX 9070 XT [Vulkan, wgpu<spirv>], 18cba8bc | invariant vs same build | 0.07 % | 107 | 107 | 10 (20) | 10 | 0 | 25.9 % |
| 60 | RX 9070 XT [Vulkan, wgpu<spirv>], 9bde4a87 | overrun model vs c0c357ae | 0.06 % | 97 | 97 | 20 (20) | 20 | 0 | 13.9 % |
| 60 | GTX 1660 Ti, 9a4f7406 | invariant vs same build | 0.01 % | 15 | 15 | 0 (15) | 0 | 0 | — |
| 60 | RTX 3070, 8bd154bc | overrun model vs c0c357ae | 0.01 % | 13 | 13 | 13 (13) | 13 | 0 | 20.6 % |
| 60 | RX 9070 XT [Vulkan, wgpu<spirv>], cb38b917 | invariant vs same build | 0.01 % | 12 | 12 | 6 (12) | 6 | 0 | 39.3 % |
| 60 | RTX 3050, 9a4f7406 | invariant vs same build | 0.00 % | 3 | 3 | 0 (3) | 0 | 0 | — |

Bound = 95 % one-sided upper bound on the cell's per-field rate of counter disagreement given zero mismatches
(1 − 0.05^(1/n)) [derived]; it bounds fields that disagree, not candidates. Sample: `raw/make_sample.py` (seed 20261112,
time-stratified, written before any run: `raw/sample.json`, queues `raw/queue_*.json`, `raw/Q*.json`). Every sampled
field ran with its cell's own build, except the 8bd154bc and 9bde4a87 cells (rule 3, against c0c357ae).

**Mismatches in the re-runs: none.** 0 of 1,662 compared submissions (1,100 under rule 2, 328 under rule 1, 234 under
rule 3) [measured, `raw/compare.txt`, `raw/compare_detail.jsonl`]. Largest |r|/tolerance under rule 2: 0.69.

**Census-level same-build cross-check (free, not a random sample)**: `raw/dup_rule.py` → `raw/dup_rule.txt`,
`raw/pair_cover.py` → `raw/pair_cover.txt`. Of 11,087 same-build pairs of qualified submissions on pre-#236 builds,
3 break the invariant, all on 9a4f7406 b60, all excesses of `checked`, on three device families, none Apple. All three
are now settled by a 9a4f7406 re-run on a 3080:

| field | off submission (excess) | other submission | 9a4f7406 re-run (3080) | verdict |
|---|---|---|---|---|
| 206943130 | 268729348, GTX 1080 (fleet): 172,426,289,017 / 11,297,004,429, r = +3.29e-5 | 268719456, 9070 XT (demoux), r = −1.05e-7 | 172,440,774,765 / 11,278,169,780 | demoux's run is consistent; the GTX 1080's has ≈ +5.4e6 surplus checked entries |
| 206950836 | 269917800, TITAN Xp (fleet): 88,600,810,065 / 5,791,565,076, r = +2.83e-5 | 269893752, TITAN Xp, r = +4.1e-9 | 88,600,622,909 / 5,789,393,904 | the first run is consistent; the second has ≈ +2.35e6 surplus checked |
| 206956667 | 270992509, 9070 XT (demoux), retried_partitions = 16: 8,126,941,029 / 536,352,273, r = +1.32e-6 (tol 3e-7) | 270982919, 9070 XT, retried 0: 8,126,941,044 / 536,342,267, r = −8e-10 | 8,126,941,159 / 536,342,166, retried 0 | the retried-0 run matches the re-run to the overflow arithmetic (115 overflowed survivors, +101 checked); the other has 130 overflowed survivors but +10,107 checked, ≈ 9,990 surplus |

On 206956667's retries (the director's question): in 9a4f7406 a batch whose `checked` count overflows the list is
dropped from the tally and run again in smaller batches (`run_pass`/`run_partition`); the counted totals of the re-run
are clean by construction, so the retry path itself should not add 10,000 checks. The other two runs of the field did not
overflow at all. My reading: a surplus of checked entries is what the #222 race produces (a lone plane's flush writes
stale entries), and the same surplus can push a batch's count past the list end, which would explain the 16 retries as
a consequence rather than the cause. This is inference from the code, not a measurement: the counters cannot separate a
race event from an unknown retry-path accounting fault, and the retried batches' own counts are not in the telemetry.
In all three cases the field has another, consistent qualified submission, so each field is covered.

No other cell shows a single disagreeing census pair (8c088a28 1,094 submissions with a same-build partner, 8bd154bc
1,665, 6f060a94 911, c0c357ae 250, c72e2c6f 560, ...). Nothing was changed, re-queued or reported anywhere.

## 7. Bottom line

**Base 58** (all 93,573 fields searched; `raw/bottom_line.py`): 74.1 % of the range lies in cells verified clean at a
≤ 2.1 % per-field bound (9070 XT, TITAN Xp, RTX 2070 on 9a4f7406); 22.0 % at ≤ 5.1 % (RTX 3060, 4060, A2000, 4060 Ti,
GTX 1080 Ti on 9a4f7406; 9070 XT on c0c357ae); 0.84 % at 14–15 % (3060 Ti, A100, the 9a4f7406 CPU cell); 1.08 % with
few fields (RTX 4060 on 8bd154bc 3, M4 on 6f060a94 9, GTX 1070 5); **2.03 % (anvil, 1,901 fields, v3.4.6 without
telemetry) cannot be checked by counters.**

**Base 60** (146,268 of 162,076 fields searched = 90.2 % of the range; shares below are of the whole base):
46.0 % in cells clean at ≤ 2.0 % (9070 XT on 9a4f7406 149/149, 9070 XT on c0c357ae 149/149); 32.6 % at ≤ 5.0 %
(9070 XT on 6f060a94 65 fields, 4.5 %; RTX 3060 and 4060 on 8bd154bc, 59/59 each); 2.4 % at 9.5 % (8c088a28); 11.9 % at
10.9–13.9 % (M4 on 6f060a94, GTX 1070 / RTX 2070 / RTX 4060 on 9a4f7406, the M4 on c0c357ae, small 8bd154bc and 9bde4a87
cells); 5.5 % in cells with few fields (TITAN Xp 12, A2000 10, 3060 9, 1080 Ti 7 on 9a4f7406; c72e2c6f 10; and smaller);
0.01 % not re-run (GTX 1660 Ti, RTX 3050 on 9a4f7406). 9.8 % of the range is not searched yet.

**Zero mismatches anywhere.** No (device, build) cell in either base shows the kind of systematic deficit the M4 had.

## 8. What the race events imply, and what could not be checked

- **Field with one pre-#222 submission** (9a4f7406, 8c088a28, c72e2c6f, cb38b917; `raw/pre222_only.py`: b58 89,158 fields,
  95.3 % of the range incl. the anvil cell; b60 64,590 fields, 39.9 %). What can be said: its cell shows no systematic
  loss (the bounds above), and its own counters, where sampled, satisfy the lossless invariant. The race's visible
  signature (surplus checked) appears in ≈ 3 of 11,087 same-build census pairs, ≈ 1.4e-4 per submission [derived],
  so order 10 fields per base carry a race event [derived, rough]. What cannot be said: that this particular field was
  searched completely. Per #222 a race event can also overwrite list entries reserved by another flush, which loses
  candidates without changing the counts; a run with such a loss and no surplus is indistinguishable from a clean one
  by telemetry. The residual risk per such field is therefore roughly "≈ 1e-4 chance of an event, and an event may
  skip some candidates", unbounded by counters. Only a search with a #222 build closes it. For a *verified* "none
  below 62" that means re-searching the pre-#222-only fields (b58 ≈ all of it, b60 ≈ 40 %), or accepting the residual
  explicitly. User decision; nothing was queued.
- Fields with a pre-#222 submission and a consistent second one (e.g. the three above) are covered by the second.
- Builds with #222 but not #236 (8bd154bc, 18cba8bc, 9bde4a87): race-free; counters timing dependent but consistent.
- Not checkable: the anvil no-telemetry b58 cell (2.03 %).
- Not run: GTX 1660 Ti and RTX 3050 on 9a4f7406 at b60 (0.01 %); remainders of cells listed with n < target.
- Rule 3's tolerance was widened during the run (section 4), which hides losses up to ≈ 1e-5 of a heavily overflowed
  field in the 8bd154bc/9bde4a87 cells.

## 9. Files

`raw/`: census (`census_fields.py`, `census_subs.py`, `census_cells.py`, `census_table.md`, `fields_b58_b60.json`,
`subs_b58_b60.json`, `pre222_only.py/.txt`), sample (`make_sample.py`, `sample.json`, `queue_*.json`, `Q*.json`,
`QE2_9a4f_b60_byshare.json`), box side (`stub_api.py`, `run_queue.sh`, `box_build.sh`, `builds4.sh`, `chain*.sh`,
`extract.py`, `proof_hosts_block.txt`), raw outputs (`box/` first box, `box2/` replacement: `out_*.jsonl` = every
submission body the clients sent to the stub, `client_*.log`, `stub_*.log`, `runs.log`), analysis (`compare.py` →
`compare.txt`, `compare.json`, `compare_detail.jsonl`, `cell_table.md`, `bottom_line.py`; `dupcheck.py`,
`dup_invariant.py`, `dup_rule.py`, `pair_cover.py`, `crossbuild.py` with their `.txt` outputs; `outlier_pairs_9a4f.json`).
