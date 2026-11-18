# NM notes (living; newest at the bottom)

## 2026-11-18 05:47 UTC start
- Worktree `~/projects/nice/.worktrees/nm-near-miss`, local branch `nm/near-miss` off origin/main 7e0113fc.
- Join shape (origin/main `overlap_join.rs`): t = L − 3, k = 6, p = 2, f0 = 3; overlap o = 3 digits
  (positions 3, 4 partition, 5 key). Survivors must be in a root class of n mod (b − 1):
  n² + n³ ≡ b(b − 1)/2 (mod b − 1) (`FieldSetup::roots`, `residue_filter`).

## 05:55 The residue wall (analytic, to be checked by brute force)
The digit sum of n² ‖ n³ is ≡ n² + n³ (mod b − 1). A number with b − 1 distinct digits has one
digit x twice and one digit y missing: its digit sum is S0 + x − y with S0 = b(b − 1)/2. In a root
class the sum is ≡ S0, so x ≡ y (mod b − 1), x ≠ y: {x, y} = {0, b − 1}. **Only near misses that
duplicate 0 and lack b − 1, or the reverse, can reach the join at all**: about 2/(b(b − 1)) of
them (1 in 1,900 at b62), whatever the check does. At b − 2 the residue keeps the configurations
whose excess digit sum ≡ 0 (mod b − 1): about 1/(b − 1).

## 06:20 Model (code/model.py; raw/model_b{58,60,62,64}.txt)
DP over digit occupancies with the digit sum mod (b − 1) exact; coverage from the real geometry of
sampled n (positions the join knows before the check: bottom 12, prefilter 4, top common digits;
|K| ≈ 33.6 at b62, 34.5 at b64). Whole-base expectations:

| base | nice | b−1 all n | b−1 reaching the check | b−2 all | b−2 in root classes | b−2 reaching | b−3 reaching |
|---|---|---|---|---|---|---|---|
| 58 | 4.6e-4 | 0.18 | 3.3e-4 | 76 | 5.5 | 2.7 | 294 |
| 60 | 5.5e-4 | 0.48 | 3.9e-4 | 207 | 7.2 | 3.7 | 443 |
| 62 | 4.5e-4 | 0.42 | 3.2e-4 | 191 | 6.5 | 3.2 | 416 |
| 64 | 9.7e-4 | 0.22 | 6.9e-4 | 119 | 15.5 | 7.8 | 1078 |

In a root class the b − 1 near misses are exactly as many as the nice numbers (b!/2 strings
with 0 doubled and b − 1 missing, b!/2 the reverse: b! in all). Root-class share at b − 2 and
below is ≈ R/(b − 1) (2/61, 8/63).
Model P(reach check) = 6.0e-7 per n at b62 vs the measured 4.5e10 per 1e17 (4.5e-7): the closure
of the certificate (below) is not in the position model.

## 06:40 The exact definition needs the certificate's closure
First brute-force pass at b40 disagreed (1787 reached vs 1451 checked). The top certificate is
*closed* (`close_certificate`): at each power's first disagreement at or above c0 the digit is d
or d + 1, and when one of the two is already in the mask the other is added to it, a digit only
a nice n is sure to have there. A near miss whose repeat sits at that position, or that has the
forced digit elsewhere, is dropped. With the closure the definition matches exactly at b40
(65,612 checked over a whole 1e10 field, every (n, distinct) equal). A second mismatch at b44 was
my harness (n³ of the field start overflowed u128); fixed with malachite.

## 07:00 Prototype (variant A) in the worktree, uncommitted
- `common/src/cpu_check.rs`: `Scan` gains a const `TOL` (default 0: the production code path
  unchanged, `repeat |= ...`); with `TOL > 0` it counts repeats and stops at the first count above
  `TOL`; `Check::reps::<TOL>` returns the count (`b − reps` distinct when `<= TOL`).
- `common/src/cpu_join.rs`: `CpuJoin::set_tolerance(m)` (0, 1, 2, 3 or 64 = count everything);
  `PartitionResult::{near, reps, kreps, sample, pre}` (near misses, repeat histogram, (known digits,
  repeats) histogram, a 1/1024 hash sample of checked n, prefilter-repeat histogram of AND survivors).
  Counters and hits untouched; the tolerance only changes what `full_check` does after `checked += 1`.
- `common/examples/nm_join.rs`: `bf` (join vs brute force of the definition) and `run` (CPU2-style
  contiguous partitions).
- Harness bug found and fixed on the way: a u128 overflow of the field start's cube in my own
  brute force (b44+), and an unbounded `near` list in count-everything mode (would have OOMed b64).

## 07:10 Exactness (raw/bf.txt, raw/bf2.txt): EQUAL everywhere so far
Whole bases 20, 22, 24, 25, 28, 29 (scaled shapes t,k,p = 3,2,0 / 4,3,1 / 5,4,2), b40 full 1e10
fields (1600 partitions, m = 64, 1, 2, 3), b44 / b45 / b50 / b60 / b62 / b64 partitions: the
reported set {(n, distinct)} equals the definition, `checked` equals the brute-force reach count,
and with m = 64 the whole repeat histogram matches.

Small bases, every n of the base (brute force) vs those reaching the check (b − 1 / b − 2 / b − 3):
b20 1/15/222 → 0/0/8; b22 0/10/261 → 0/1/5; b24 1/3/145 → 0/0/2; b25 0/18/481 → 0/2/19;
b28 0/8/367 → 0/0/9; b29 0/4/400 → 0/0/3. Model (same shapes) predicts reaching b−3:
7.0, 6.7, 2.5, 26.4, 6.4, 3.2 (sum 52 vs 46 seen); b−2: 0.85, 0.85, 0.24, 2.05, 0.46, 0.21 (4.7 vs 3).

## 07:15 GPU gate and prefilter variants (code/gate.py on raw/sample.txt; one b62 partition)
- Gate (n²'s 25 digits + n³'s low 10 distinct) among checked survivors at b62: passes 1.5e-3 at m=0,
  1.7e-2 at m=1, 8.4e-2 at m=2. Planes that must build the rest of n³: W32 4.8 % → 94 % (m=2),
  W64 9.3 % → 99.6 %. Variant A as a straight edit of the kernel makes every plane do the whole cube.
- Prefilter tolerance (one b62 1e17 partition, 34.4 M AND survivors): 0 repeats 2.05 M (checked
  today), 1 repeat 8.80 M, 2 repeats 13.3 M: tolerating 1 multiplies the check's load by 5.3,
  tolerating 2 by 11.8.

## 07:30 Checked survivors per field: production telemetry (read-only, ../2026-11-fresh-eyes/recent_niceonly_1116b.json)
16,013 recent nice-only submissions split by 16 primary-key field lookups (first b62 id 207064110):
- b62 1e17 (12,370 subs, 12,038 fields): mean **1.22e10 checked per field**, 72.6 % of fields check
  nothing (instant verdicts), 4.44e10 per non-empty field (the brief's 4.5e10 is per non-empty field).
- b60 1e16 (3,643): mean 5.77e9, 52.8 % empty, 1.22e10 per non-empty field.
So the uniform model's reach rate (6.0e-7 per n at b62) is ×5 the frontier's real rate (1.2e-7): the
top digits of n² and n³ are not uniform (leading digits Benford-like, the two powers' tops
correlated), which the position model ignores. Yield must therefore be computed as
(checked survivors) × P(j repeats | checked), not from the whole-base model.

## 07:35 The middle model holds at production shapes (code/hist.py on raw/hist2.txt, first 8 runs)
Given the digits known at the check's start (K, measured per survivor), P(repeats = j) for uniform
middle digits matches the measured histogram to 0–11 % from j = 7 to 19 at b62 and b64 (ratio
1.07–1.11 in the tail j = 8–12). So P(j = 2, 3 | checked) can be taken from the model with
confidence; the residue constraint multiplies j = 2 by ≈ 1.03 and j = 1 by ≈ 0.033 (DP).

## 07:50 Server, jobs and site (origin/main 7e0113fc)
- Client: nice-only hits are submitted as `NiceNumberSimple { num_uniques: base }` hard-coded:
  `client/src/main.rs:949-957` (CPU join), `common/src/cubecl_backend.rs:3185`, `common/src/stride_filter.rs:298,365`.
  Variant A needs these to carry the real count.
- GPU kernel: gate `common/src/cubecl_join.rs:3611` (`pass = seen == s2 + 2·gl`), hit `:3652`
  (`pass && uniq == base`), output `:3657` (`put_n`, n only: a near miss needs its count written too).
- API: `api/src/main.rs:344` `expand_numbers` (niceness = uniques/b), `:347-356` the Niceonly branch
  stores the numbers as given, no checks ("honor system"), then CL 0 → 1. A near miss would be
  stored with num_uniques < b and niceness < 1; nothing on this path calls it nice.
- Jobs: `jobs/src/main.rs:271` (chunks) and `:335` (bases) rebuild `numbers` only when the detailed
  coverage exceeds `DOWNSAMPLE_CUTOFF_PERCENT` = 0.2 (`common/src/lib.rs:50`), from canon submissions.
  b62/b64 are nowhere near 20 % detailed, so `bases.numbers` stays empty and nice-only near misses
  would never reach `cache_notable_numbers` (`common/src/db_util/cache.rs:163-190`) or the site's
  chart (`web/index.html:64`, which shows niceness, colour = off_by; no "found" banner anywhere).
- Consensus (`common/src/consensus.rs:13`, `jobs/src/main.rs:149-157`) and client validation
  (`client/src/main.rs:1170-1180`, `/claim/validate` → fields with CL >= 2, `db_util/fields.rs:997`)
  only see detailed submissions: mixed client versions cannot conflict.
- Needed server-side for the numbers to be visible: a jobs change folding nice-only submissions'
  numbers into `bases.numbers` regardless of coverage (~20 lines), and (recommended) the API
  verifying each submitted num_uniques in the Niceonly branch (`get_num_unique_digits`, a few per field).
  Nothing is needed for them merely to be stored.

## 07:55 Full histogram (30 runs, 2.2e9 checked) and yield
- b62: 7.4e8 checked, per field (slice-sampled) 4.15e10 ± 0.88e10; b64: 1.46e9, 7.47e10 ± 2.27e10.
  9 of 15 b62 runs and 8 of 15 b64 runs hit empty slices.
- Model/measured 1.03–1.09 (b62, j 7–13), 1.04–1.08 (b64).
- Gate (7.2e5 / 1.4e6 sampled): m=0 1.4e-3 / 1.3e-3, m=2 8.5e-2 / 7.6e-2, m=3 0.25 / 0.23.
- Prefilter variant: x4.2 (1 repeat), x6.3 (2 repeats) AND survivors per checked, both bases.
- Yield ≥ b−2, rest of b62 + b64: 4.4–7.0. KILL by yield. RESULTS.md and PROPOSAL.md drafted;
  CPU cost runs (raw/cost.txt) in progress.

## 07:50 Cost and close
- CPU cost (raw/cost-clean-summary.txt, instrumentation-free build, 5 rounds, counters identical):
  m=2 vs main ×1.046 / ×1.065 / ×1.057 (b60 / b62 / b64); m=2 vs m=0 prototype ×1.013 / ×1.038 / ×1.037.
  The first run (raw/cost-summary.txt) had per-pair instrumentation and is not a cost figure.
- cpu_check unit tests (6) and four cpu_join tests (69 in b10, reference windows, stride agreement,
  production-survivor check) pass on the prototype.
- Verdict KILL. RESULTS.md, PROPOSAL.md final. Baseline worktree removed, target dirs deleted;
  `.worktrees/nm-near-miss` kept (uncommitted, never pushed; diff in raw/nm-near-miss.patch).
