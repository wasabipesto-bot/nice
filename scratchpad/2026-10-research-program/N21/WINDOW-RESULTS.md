# Window on the RX 9070 XT, 2026-11-13 15:40–16:21 UTC (41 of 60 minutes granted)

Machine: the user's desktop (AMD Radeon RX 9070 XT, RADV GFX1201, Vulkan, wgpu with CubeCL's SPIR-V
compiler; 304 W cap), production client stopped by the user. Build: `cargo test --release -p nice_common
--features gpu,cubecl-spirv --no-run` per tree. Harness `join_throughput_fixed_fields`, one untimed 1e14 warm-up field
per process, then one field: b62 1e17 at 7520566762397899821056, b64 1e17 at 58557331862957161709568, b60 1e16 at
1447429612114824200908. Every timed run: 99–100 % busy, 302–305 W, 3.00–3.17 GHz; hit and survivor counts identical
per field (b62 1,097,114,812,011 / 66,862,268,894; b64 3,092,989,872,066 / 191,683,594,021; b60 190,770,281,868 /
12,786,993,080). Raw logs `raw/demoux/` (`go.out`, `tests_C.log`, `<run>.log`, `<run>.gpu`), driver
`raw/scripts/window13/go13.sh`. [M] = measured here.

Binaries: **C** = fork `pr/check-d` 1f41d649 (PR #251's fixed head); **M** = upstream main a7a59c11; **E** = fork
`exp/n21-walk-loop` 2d3e10d3 (main + #255 + #256 + the N21 switches; `NICE_EXP_N21` 0 = that base, 8 = the digit
test as one population count, 9 = 8 plus the cheaper pop).

## PR #251's device tests on this card [M]

`C --ignored cubecl_join::tests:: --skip cuda`: **10 passed, 0 failed** (142.8 s). Among them:
`cubecl_check_counts_match_the_cpu` (65 lists, 1,168,717 list entries, 84,652 synthetic n over 22 shapes) and
`cubecl_check_takes_every_entry_on_partly_filled_planes` (84 runs; the card takes the scan form, planes up to 64
lanes; smallest take 36 lanes with cubes of 100 threads and 48 with cubes of 48: partly filled planes ran, every
entry checked once).

## PR #251's fixed head against main [M]

| field | main (s) | fixed head (s) | main ÷ head |
|---|---|---|---|
| b62 1e17 | 72.74, 73.33 | 64.94, 65.09 | ×1.120, ×1.127 |
| b60 1e16 | 13.05, 12.99 | 11.56, 11.60 | ×1.129, ×1.120 |
| b64 1e17 | 136.51 | 120.31 | ×1.135 (one round) |

## The walk-loop variants (binary E) [M]

| field | base, mode 0 (s) | mode 8: population-count test (s) | mode 9: 8 + cheaper pop (s) | base ÷ 8 | base ÷ 9 |
|---|---|---|---|---|---|
| b62 1e17, rounds 1–3 (order rotated) | 68.34, 68.58, 68.71 | 65.69, 66.31, 66.23 | 65.41, 65.40, 65.41 | ×1.040, ×1.034, ×1.037 → **×1.037** | ×1.045, ×1.049, ×1.050 → **×1.049** |
| b64 1e17, round 1 | 117.80 | 109.08 | 107.10 | **×1.080** | **×1.100** |
| b64 1e17, round 2 | 117.66 | — | 107.27 | — | ×1.097 |

The base here already holds #255 (shift form at b64) and #256 (512-entry stage): main alone ran 72.7–73.3 s at b62
and 136.5 s at b64 in the same hour, so #255 and #256 together are ×1.07 at b62 and ×1.16 at b64 on this card [D].
b60 was not timed for the variants.
