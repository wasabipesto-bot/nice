# G2 GPU benchmark (base 64): status 2026-11-16 18:40 UTC

## Verdict: none yet. Nothing has run on the card.

This session's permission system denied the ssh connection to Vast 60959320. The classifier
flagged it as unauthorized access. A coordinator's message does not count as the user's consent,
so I did not try to get around the block. The user has to allow ssh to the box (a Bash permission
rule), and then the steps below can run. The box destroys itself at about 03:25 UTC.

## Ready on ivory (`G2/bench/`)

- **Inputs** for one real b64 super-unit, π′ = 712012851 (digits 4–8). It covers all 64 units of
  digit 9; unit 51 is the author's unit 55472845875. The dump is in `su64_712012851/`:
  - `tops.bin`: 238,813 tops.
  - `surv.bin`: the prototype's survivor set for every unit, 11,768,560 n.
  - `meta.txt`: per-unit counts.
- **`g2bench.cu`**, CUDA (nvcc, sm_86) plus a CPU reference path in the same file, built and run
  with g++ on ivory. It runs these steps:
  - Base-wide depth-4 roots: 9,298,544.
  - Per super-unit preparation on the GPU: parents from the roots, a stable `cub` select and radix
    sort on (class, 8-bit key), gather, and class segments. The GPU order is checked to equal the
    CPU's.
  - The main kernel, with switches for probes off, skip off and full. Grid = 63 parent classes ×
    64 unit digits. Per block: affine children, ordered ballot compaction, 64-chunks transposed by
    ballots into padded LDS slices with common and valid masks, then probes with lanes over chunks,
    the common-mask skip, a bit-sliced OR over the probe's digits, and survivors appended.
  - Before printing any timing it checks every unit's survivor **set** against the prototype's.
  - It reports ps per child, per flat incidence and per kept word, prep ps per parent, end-to-end
    fs per admissible n, registers, shared memory and occupancy.
- **CPU reference, measured** (`cpu_ref.txt`). Same chunking rule as the kernel and the 8-bit key
  (digits 1 2 3 16 36 0 4 17):

  | count | per super-unit | per admissible n |
  |---|---|---|
  | parents | 1,042,046 | |
  | stored children | 33,705,647 | 7.54e-6 |
  | chunks | 528,635 | |
  | flat incidences | 250,486,772 | 5.61e-5 |
  | kept incidences | 123,163,397 (kept fraction 0.492) | 2.76e-5 |
  | survivors | 11,768,560 | 2.63e-6 |

  **All 64 units' survivor sets equal the prototype's.** The GPU run must reproduce these counts
  exactly, because its sort is stable and its compaction keeps order.
- **Box scripts** in `bench/box/` (driven from ivory by `bench/drive.sh push | setup | build_main
  | bench TAG | main TAG | pull`):
  - `setup.sh` blocks the production hosts and records the proof (T28's `hosts_block.sh`).
  - `build_main.sh` builds upstream main's client with `--features gpu,cubecl-cuda`.
  - `run_main.sh` runs the real client against T28's `stub_api.py` only. It aborts if a production
    host answers. The queue is a 1e14 warm-up field, then ten b64 1e17 fields at 0.05–0.95,
    aligned to 1e17 as in B64.1.
  - `summarize_main.py` turns that run into fs per admissible n.
  - `run_bench.sh` builds and runs the kernel with nvidia-smi sampling.

## Not in the kernel's number, to be added from measurements

- **Tops:** the f0 4 tops are made on the CPU. On the card they would be production's FD kernel:
  B64.1 measured 0.104 ns per test, and 4.69e-7 tests per admissible n (every top, F4) adds
  ≈ 0.05 fs.
- **Survivor checks:** 2.6e-6 per admissible n × the prefilter and check cost.

## Stop numbers (REVIEW.md), base 64 against the same-session main

- **Stop** if end-to-end is above 1.06 fs per admissible n (under ×5), if the kept word is above
  25 ps, or if a stored bottom is above 25 ps.
- **Worth a run on the RX 9070 XT** at ×6 or better.
