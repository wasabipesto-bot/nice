# L8: near-miss tail test (BACKLOG 39)

2026-11-01. Does the project's probability model predict the observed tail of near misses?
Scripts and data are in this directory; nothing in the repo was changed and nothing was built.

## Answer

- **The near tail fits.** The project's local factors are the low-digit factor α_{b,3}/P₆ and the digit-sum factor that gives R_b at k = b. Applied at every k, they predict the counts at 3–6 missing digits to within 2–3 %, pooled over bases 12–50 (ratios 0.970–0.979). The iid model over-predicts these counts by 13 %. So the August ×0.846 fit was mostly the low-digit factor in disguise, as METHODOLOGY suspected (the leading-digit factor below accounts for the rest), and dropping it was right.
- **One more structural factor exists and can be computed.** The leading digits of n² and n³ are both set by the leading digits of n, so they are correlated, and the project's λ does not include this. Fixing the top digit of each power from the real numbers brings d = 3–6 to 0.99–1.00. It also explains the per-base scatter: at d = 4 the correlation is 0.91, and χ² over 25 bases drops from 3,890 to 156.
  - At k = b this factor is 0.86–1.06 depending on the base. For b ≥ 20 one top digit is enough: taking two or three changes it by under 1 % at most bases, and by 3.4 % at worst (b34).
  - Folded into the searched λ at bases ≥ 20, it moves today's 5.45 % to **5.34 %**.
  - For the bases ahead: b60 ×0.99, b62 ×0.91, b64 ×1.02.
- **Right at the tail the model over-predicts, but the evidence is thin.**
  - **d = 2** (k = b−2): 512 observed against 582 expected, a ratio of 0.88 [0.81–0.96]. The deficit is the same across bases (χ² 30 on 31 degrees of freedom).
  - **The new bases neither confirm nor rule it out.** Most of the deficit sits in bases 20–45, the bases that first flagged it in August. The bases added since (12–19 and 47–50) give 0.96 [0.82–1.12].
  - **d = 1:** 7 observed against 5.7 expected. **d = 0:** 0 against 0.05. Neither says anything either way.
- **What it means for the headline.** The readings the data allow put the correction on λ at k = b between about 0.67 and 1.0; their confidence intervals widen that to 0.53–1.14. The model does not under-predict at any depth. The data cannot separate the readings in the table below.

| reading of the tail | factor on searched λ | today's odds (5.45 % now) |
|---|---|---|
| leading-digit factor only; d = 2 treated as noise | 0.98 | 5.34 % |
| smooth depth fit over d = 1–4 (project model) | 0.94 [0.78–1.14] | 5.14 % [4.28–6.19] |
| leading digit × a constant 0.88 step below d = 3 (best fit to d = 1, 2) | 0.86 | **4.72 %** |
| leading digit × 0.88 compounding per step (d = 1–3 fit) | 0.67–0.70 [0.53–0.91] | 3.7–3.8 % [2.9–5.0] |

The constant-step and compounding readings fit the d = 1 and d = 2 counts equally well: their log-likelihoods differ by 0.3. The no-effect reading is 4.1 log-likelihood units worse, a likelihood-ratio p of 0.004. That p-value overstates the evidence, because the d = 2 bin was singled out in August from most of the same data.

**For the cost model:**
- **Costs and search order don't change.** A common factor doesn't reorder the bases. The leading-digit factor varies by about ±10 % per base, which is small next to the cost spread.
- **Change the stated uncertainty.** Replace METHODOLOGY's "the tail itself is untested" with "tested to two missing digits: the low-digit and residue factors hold; the near tail may be up to ~1.5× optimistic".
- **Optionally fold in the leading-digit factor.** It is computed per base like α (`data/top_factor.csv`).
- **The headline rests mostly on tiny bases.** 77 % of today's Σλ comes from bases 12–25, whose ranges hold 185 to 6.4 million numbers. There the tail data agree with the model about as well as they do elsewhere (12–24: d = 3 0.99, d = 2 0.88 with the leading digit).

## Data and API queries

`https://data.nicenumbers.net` (PostgREST, `curl -A "nice-L8-tailtest/1.0"`). Nine requests in all, spaced at least 0.6 s apart: the three below, which produced the data used, plus OpenAPI reads and small probes.

| query | gives | saved as |
|---|---|---|
| `GET /bases?select=id,range_start,range_end,range_size,checked_detailed,checked_niceonly,minimum_cl,niceness_mean,niceness_stdev,distribution&order=id` | the aggregated `num_uniques` histogram per base (`distribution`, summed from the canonical detailed submissions) | `data/bases.json`, `data/observed.csv` |
| `GET /cache_notable_numbers?select=base,number,num_uniques,off_by&order=base,number&limit=1000` | 957 individual near misses: every d ≤ 2 at bases 22–50, every d ≤ 1 at bases 12–50, plus some d = 3–4 | `data/notable.json`, `data/notable.csv` |
| `GET /chunks?select=id,base_id,range_start,range_end,range_size,checked_detailed&base_id=eq.50&order=range_start` | base 50's detailed coverage by chunk | `data/chunks50.json`, `data/chunks50.csv` |

**Coverage.**
- **Bases 12–49:** detailed search is complete, so these are exact counts over every n in the range.
- **Base 50:** 1.70e16 of 7.1e16 searched. The first 14 chunks are complete, then about 20 % of chunks 1237–1283 and 0.1 % beyond. The models for base 50 are sampled with the same per-chunk weights.
- **Base 10** (53 numbers, holds 69) is excluded.
- **Higher bases** have no detailed data.

**Checks.**
- Each histogram sums to `checked_detailed`; base 50 is 0.1 % short.
- The d ≤ 2 counts equal the `cache_notable_numbers` rows at every base where both exist. The list omits d = 2 at bases ≤ 20.
- A brute-force recount of bases 20, 22 and 24 matches the API exactly at d ≤ 3 (`extra.py`).
- The stored `range_end` sits one below `base_range.rs` at 27 bases, the known off-by-one. The stored range is the one that was searched, so it is used.

## Method

**Notation.**
- n²‖n³ has exactly b digits, and K is the number of distinct digits among them.
- d = b − K is the number of missing digits; a nice number is d = 0.
- **Observed:** the API histogram.
- **Expected:** N × P_model(K = k), where N is the number of n searched.

**The model ladder** (`models.py`):

| model | what is exact | rest |
|---|---|---|
| M0 | nothing | b iid uniform digits: classic occupancy, C(b,k)·Surj(b,k)/b^b |
| M1_J | the low J digits of n² and of n³ (exact enumeration of n mod b^J; J = 1–4) | b − 2J iid |
| DS | digit-sum class: S ≡ n² + n³ (mod b−1) | exact DP over iid strings, P(K=k, S≡c); averaged over the classes of n mod b−1 |
| M2_t | low 3 digits **and** the top t digits of n² and n³, taken from actual n (every n for ranges ≤ 2e6, otherwise 10⁶ uniform samples) | b − 6 − 2t iid |

**Why only the count of distinct fixed digits matters.** The free digits are iid uniform, so they are symmetric under any relabelling of the symbols. A structural model with f fixed positions holding u distinct values therefore gives P(K=k) = Σ_u P(u)·Occ(k | u pre-occupied, b−f draws). The occupancy part is computed in exact integers.

**The project's λ in this ladder.** It is exactly M1_3 × DS at k = b. `models.py` reproduces build.py's λ to 4 significant figures at every base from 22 to 49, and at b20 to 0.1 %. Bases 12–18 differ from build.py by −20 % (b12) to +1 %. Their ranges span only a few periods of b³, so the low-digit distribution there comes from the actual n rather than from uniform residues; at b12 build.py's range is also one number longer.

**Why the R_b factor cannot be seen below k = b.** This is math-reassessment §2.2: the digit-sum weight is R_b at k = b but (b+1−R_b)/b at k = b−1, and closer still to 1 below that. The tail therefore cannot test R_b, and R_b does not need testing: it follows from digit sum ≡ value (mod b−1). The test is of everything else, i.e. whether the remaining digits behave like iid draws as k → b.

**Is R_b's conditioning right where it bites?** With R_b's conditioning applied, the per-class version of DS predicts the share of near misses that fall in the "good" classes, the residues where a pandigital is possible.
- **d = 2** (live bases 22–50): 34 observed against 28.7 predicted, out of 314. Consistent.
- **d = 1:** 0 of 6 against 0.04 predicted.

This test has little power, because the conditioning barely moves the share at d ≥ 2 (`data/class_test.csv`).

**Combining the factors.** DS and the structural factor are multiplied together. At k = b this is exact, the same assumption as the project's λ. At k < b DS is within O(R_b/b) of 1, so any interaction is second order.

**Trend fit** (`analyze.py`, `tables.py`).
- A Poisson GLM obs ~ Pois(E·c·s^d) over bases × depths, with quasi-Poisson confidence intervals.
- c is the extrapolated correction at d = 0.
- Pooled ratios carry exact Garwood 95 % intervals.

## Results

### Pooled over bases 12–50: observed / expected and ratio [95 % CI] by model

| d = b−k | observed | M0 iid: E | project (low-3 × DS): E | + lead digit (top-1): E | + top-3: E | M0 iid: ratio | project (low-3 × DS): ratio | + lead digit (top-1): ratio | + top-3: ratio |
|---|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 0.04 | 0.05 | 0.05 | 0.03 | 0.00 [0.00–90.39] | 0.00 [0.00–74.00] | 0.00 [0.00–77.42] | 0.00 [0.00–131.12] |
| 1 | 7 | 7.50 | 5.97 | 5.74 | 5.12 | 0.93 [0.38–1.92] | 1.17 [0.47–2.42] | 1.22 [0.49–2.51] | 1.37 [0.55–2.82] |
| 2 | 512 | 684 | 599 | 582 | 569 | 0.75 [0.68–0.82] | 0.86 [0.78–0.93] | 0.88 [0.81–0.96] | 0.88 [0.81–0.97] |
| 3 | 39,150 | 45,675 | 40,363 | 39,368 | 39,135 | 0.86 [0.85–0.87] | 0.97 [0.96–0.98] | 0.99 [0.98–1.00] | 1.00 [0.99–1.01] |
| 4 | 1,767,568 | 2,042,856 | 1,811,498 | 1,770,168 | 1,761,543 | 0.87 [0.86–0.87] | 0.98 [0.97–0.98] | 1.00 [1.00–1.00] | 1.00 [1.00–1.00] |
| 5 | 52,904,966 | 60,919,857 | 54,151,348 | 53,012,410 | 52,748,684 | 0.87 [0.87–0.87] | 0.98 [0.98–0.98] | 1.00 [1.00–1.00] | 1.00 [1.00–1.00] |
| 6 | 1,093,763,460 | 1,252,978,018 | 1,117,141,573 | 1,095,901,357 | 1,090,336,002 | 0.87 [0.87–0.87] | 0.98 [0.98–0.98] | 1.00 [1.00–1.00] | 1.00 [1.00–1.00] |

The top-3 model is undefined at b12–13 and is missing from those sums. Below b20 it fixes most of the string, so it describes the actual numbers rather than acting as a prior. Read its d ≤ 1 cells, and the d = 0 row generally, with that in mind.

### By base group (ratio obs/E; project model / with leading digit)

| group | d=1 | d=2 | d=3 | d=4 |
|---|---|---|---|---|
| 12–24 | 5: 1.699 / 1.794 | 79: 0.833 / 0.877 | 1,282: 0.950 / 0.994 | 10,607: 0.967 / 1.007 |
| 25–34 | 0: 0.000 / 0.000 | 105: 0.842 / 0.860 | 4,745: 0.964 / 0.986 | 101,690: 0.977 / 0.998 |
| 35–44 | 1: 0.877 / 0.897 | 165: 0.803 / 0.820 | 14,866: 0.971 / 0.990 | 602,249: 0.982 / 1.000 |
| 45–50 | 1: 1.511 / 1.565 | 163: 0.940 / 0.969 | 18,257: 0.972 / 1.001 | 1,053,022: 0.972 / 0.998 |
| live (R_b>0) | 6: 1.423 / 1.484 | 356: 0.825 / 0.846 | 28,302: 0.980 / 0.996 | 1,279,596: 0.989 / 0.999 |
| dead (R_b=0) | 1: 0.571 / 0.590 | 156: 0.934 / 0.971 | 10,848: 0.944 / 0.990 | 487,972: 0.943 / 0.997 |

### Depth-trend fits (Poisson GLM, ratio = c·s^d, quasi-Poisson CI), bases 12–50

| model | depths | c (d=0) [95 %] | s per step | dispersion φ |
|---|---|---|---|---|
| project (low-3 × DS) | 3,4,5,6 | 0.967 [0.82–1.14] | 1.0021 | 11530.65 |
| project (low-3 × DS) | 1,2,3,4 | 0.941 [0.78–1.14] | 1.0091 | 24.57 |
| project (low-3 × DS) | 1,2,3 | 0.684 [0.48–0.98] | 1.1233 | 2.02 |
| project (low-3 × DS) | 1,2 | 1.608 [0.36–7.09] | 0.7293 | 0.84 |
| + lead digit (top-1) | 3,4,5,6 | 0.998 [0.97–1.03] | 1.0000 | 395.19 |
| + lead digit (top-1) | 1,2,3,4 | 0.971 [0.92–1.03] | 1.0071 | 2.11 |
| + lead digit (top-1) | 1,2,3 | 0.710 [0.54–0.93] | 1.1187 | 1.13 |
| + lead digit (top-1) | 1,2 | 1.691 [0.38–7.46] | 0.7216 | 0.85 |

### Three readings of the d ≤ 2 bins (leading-digit model), and their fit to d=1 and d=2

| reading | ratio at d=2 | at d=1 | at d=0 (c) | E d=2 | E d=1 | log-lik vs best |
|---|---|---|---|---|---|---|
| no tail effect | 1.0 | 1.00 | 1.00 | 582 | 5.7 | -4.13 |
| constant step below d=3 | 0.88 | 0.88 | 0.88 | 512 | 5.0 | +0.00 |
| compounding ×0.88 per step | 0.88 | 0.77 | 0.68 | 512 | 4.4 | -0.29 |

Observed: d=2 512, d=1 7.

### Per base: observed / expected (project model M1×DS) for the top five k

| base | R_b | N searched | k=b | k=b−1 | k=b−2 | k=b−3 | k=b−4 | ratio b−2 | ratio b−3 | ratio b−4 | ratio b−4, lead-digit model | lead-digit factor at k=b |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 12 | 2 | 1.85e+02 | 0 / 8.7e-03 | 0 / 0.34 | 3 / 5.64 | 24 / 28 | 53 / 59 | 0.53 | 0.856 | 0.905 | 0.959 | 1.011 |
| 13 | 2 | 2.11e+02 | 0 / 7.7e-03 | 0 / 0.28 | 6 / 4.84 | 34 / 26 | 43 / 60 | 1.24 | 1.302 | 0.712 | 0.713 | 0.922 |
| 14 | 2 | 4.04e+02 | 0 / 4.9e-03 | 0 / 0.22 | 3 / 4.51 | 27 / 30 | 84 / 90 | 0.66 | 0.895 | 0.938 | 0.956 | 0.933 |
| 15 | 0 | 2.01e+03 | 0 / 0 | 1 / 0.50 | 13 / 11 | 95 / 88 | 299 / 322 | 1.22 | 1.080 | 0.927 | 0.940 | 0.931 |
| 17 | 1 | 7.72e+03 | 0 / 3.2e-03 | 2 / 0.43 | 11 / 12 | 125 / 132 | 611 / 643 | 0.89 | 0.950 | 0.950 | 1.005 | 0.891 |
| 18 | 2 | 9.46e+03 | 0 / 1.7e-03 | 0 / 0.13 | 4 / 5.06 | 73 / 66 | 411 / 413 | 0.79 | 1.098 | 0.994 | 0.972 | 1.022 |
| 19 | 0 | 1.89e+04 | 0 / 0 | 0 / 0.20 | 3 / 6.88 | 78 / 97 | 589 / 638 | 0.44 | 0.808 | 0.924 | 0.930 | 0.991 |
| 20 | 2 | 1.01e+05 | 0 / 3.7e-03 | 1 / 0.34 | 15 / 15 | 222 / 240 | 1857 / 1,857 | 1.00 | 0.925 | 1.000 | 1.018 | 0.959 |
| 22 | 4 | 4.22e+05 | 0 / 4.6e-03 | 0 / 0.23 | 10 / 14 | 261 / 278 | 2617 / 2,725 | 0.71 | 0.938 | 0.960 | 1.047 | 0.858 |
| 23 | 0 | 5.46e+05 | 0 / 0 | 0 / 0.17 | 8 / 9.18 | 198 / 201 | 2134 / 2,158 | 0.87 | 0.983 | 0.989 | 0.981 | 1.019 |
| 24 | 2 | 1.14e+06 | 0 / 7.4e-04 | 1 / 0.10 | 3 / 6.58 | 145 / 163 | 1909 / 2,002 | 0.46 | 0.891 | 0.953 | 1.035 | 0.870 |
| 25 | 6 | 6.43e+06 | 0 / 5.4e-03 | 0 / 0.22 | 18 / 19 | 481 / 504 | 6741 / 6,785 | 0.95 | 0.954 | 0.993 | 0.986 | 1.007 |
| 27 | 0 | 2.87e+07 | 0 / 0 | 0 / 0.23 | 20 / 18 | 502 / 560 | 8727 / 8,893 | 1.13 | 0.897 | 0.981 | 1.029 | 0.939 |
| 28 | 4 | 3.88e+07 | 0 / 1.2e-03 | 0 / 0.10 | 8 / 9.86 | 367 / 339 | 5960 / 5,955 | 0.81 | 1.081 | 1.001 | 1.002 | 0.997 |
| 29 | 2 | 8.32e+07 | 0 / 5.5e-04 | 0 / 0.11 | 4 / 10 | 400 / 385 | 7372 / 7,225 | 0.38 | 1.040 | 1.020 | 0.982 | 1.064 |
| 30 | 2 | 4.94e+08 | 0 / 1.0e-03 | 0 / 0.21 | 18 / 22 | 898 / 898 | 18730 / 18,548 | 0.81 | 1.000 | 1.010 | 1.017 | 0.991 |
| 32 | 2 | 2.34e+09 | 0 / 7.1e-04 | 0 / 0.17 | 19 / 20 | 845 / 950 | 20492 / 22,698 | 0.93 | 0.890 | 0.903 | 0.996 | 0.872 |
| 33 | 5 | 3.28e+09 | 0 / 1.0e-03 | 0 / 0.09 | 10 / 13 | 651 / 640 | 16278 / 16,366 | 0.77 | 1.016 | 0.995 | 1.001 | 0.992 |
| 34 | 4 | 7.21e+09 | 0 / 6.7e-04 | 0 / 0.09 | 8 / 12 | 601 / 644 | 17390 / 17,604 | 0.65 | 0.933 | 0.988 | 0.974 | 1.021 |
| 35 | 0 | 4.47e+10 | 0 / 0 | 0 / 0.24 | 21 / 32 | 1859 / 1,794 | 52537 / 52,397 | 0.66 | 1.036 | 1.003 | 1.007 | 0.994 |
| 37 | 4 | 2.21e+11 | 0 / 1.1e-03 | 0 / 0.17 | 21 / 29 | 1675 / 1,836 | 56015 / 60,690 | 0.72 | 0.912 | 0.923 | 1.000 | 0.901 |
| 38 | 2 | 3.21e+11 | 0 / 2.9e-04 | 0 / 0.10 | 21 / 17 | 1167 / 1,121 | 40639 / 39,458 | 1.26 | 1.041 | 1.030 | 1.003 | 1.036 |
| 39 | 0 | 7.21e+11 | 0 / 0 | 0 / 0.09 | 14 / 15 | 1068 / 1,088 | 39830 / 40,684 | 0.92 | 0.981 | 0.979 | 0.981 | 1.001 |
| 40 | 4 | 4.64e+12 | 0 / 1.0e-03 | 1 / 0.19 | 25 / 38 | 2865 / 2,855 | 113348 / 113,455 | 0.66 | 1.004 | 0.999 | 1.007 | 0.989 |
| 42 | 2 | 2.40e+13 | 0 / 3.7e-04 | 0 / 0.16 | 23 / 33 | 2472 / 2,758 | 114871 / 122,343 | 0.70 | 0.896 | 0.939 | 1.007 | 0.919 |
| 43 | 0 | 3.57e+13 | 0 / 0 | 0 / 0.11 | 25 / 23 | 1990 / 2,047 | 94710 / 94,871 | 1.08 | 0.972 | 0.998 | 0.989 | 1.013 |
| 44 | 2 | 8.19e+13 | 0 / 1.8e-04 | 0 / 0.09 | 15 / 20 | 1770 / 1,817 | 90299 / 89,241 | 0.77 | 0.974 | 1.012 | 0.995 | 1.024 |
| 45 | 2 | 5.44e+14 | 0 / 4.4e-04 | 1 / 0.21 | 48 / 51 | 5065 / 5,023 | 259592 / 259,816 | 0.94 | 1.008 | 0.999 | 1.001 | 0.997 |
| 47 | 0 | 2.92e+15 | 0 / 0 | 0 / 0.21 | 52 / 53 | 5058 / 5,621 | 289146 / 317,398 | 0.99 | 0.900 | 0.911 | 0.999 | 0.892 |
| 48 | 2 | 4.46e+15 | 0 / 1.7e-04 | 0 / 0.09 | 17 / 26 | 2870 / 2,944 | 171609 / 176,112 | 0.65 | 0.975 | 0.974 | 0.994 | 0.976 |
| 49 | 2 | 1.04e+16 | 0 / 1.6e-04 | 0 / 0.09 | 34 / 27 | 3107 / 3,174 | 196480 / 197,961 | 1.26 | 0.979 | 0.993 | 0.985 | 1.010 |
| 50 | 8 | 1.70e+16 | 0 / 3.6e-04 | 0 / 0.05 | 12 / 16 | 2157 / 2,016 | 136195 / 132,030 | 0.73 | 1.070 | 1.032 | 1.013 | 1.021 |


The k = b and k = b−1 cells are too sparse for per-base ratios: 0 and 7 events in all. Expected counts are under the project model; the leading-digit model's ratio is shown at b−4.

## Interpretation

1. **The ×0.846 is explained.**
   - Under M0 the ratio is a flat 0.87 at d = 3–6 (the August result).
   - The low-digit factor takes it to 0.97–0.98.
   - The leading digit takes it to 0.99–1.00 (0.994–1.003 depending on how many top digits are fixed).
   - The low digits beyond 3 (J = 4) change nothing.
2. **The leading-digit factor is real.**
   - It predicts which bases run high or low in the high-statistics bins: at d = 3, χ² over 25 bases goes from 150 to 34; at d = 4, from 3,890 to 156.
   - At k = b it is the base's chance that the top digits of n² and n³ (and the six low digits) are all distinct, against the iid chance.
   - It converges at one top digit for b ≥ 20.
   - For b < 20 the M2 models fix most of the string, so they become a description of the actual numbers rather than a prior. The k = b factor is not used there.
3. **The tail below d = 3 is where the model and the data part.**
   - All the evidence is in d = 2 (512 near misses); d = 1 has 7 and d = 0 has none.
   - The d = 2 deficit is about 2.5–3σ against the best structural model. It is homogeneous across bases (χ² 30 on 31 degrees of freedom), which is what a genuine common factor would look like. Live and dead bases give 0.85 and 0.97 with the leading digit, a 1.4σ difference.
   - But it was spotted in August on most of these same data, and the independent part (bases 12–19 and 47–50, 165 expected) is too small to confirm or refute it.
   - **No known arithmetic mechanism explains it.** Divisibility by b−1 is in DS. Divisibility by b+1 fixes the alternating sum, which depends on digit positions and so does not constrain the multiset. The low and top digits are in M2.
4. **Proportionate claim.** The probability model is consistent with the data from d = 6 down to d = 3 at the 0.3 % level, once the leading digit is added. At d = 2 the observed count is about 12 % below it. The k = b case is an extrapolation of at least two steps beyond any well-measured bin. The quoted odds therefore show no sign of being pessimistic, and could be optimistic by 1.2–1.5×. That puts today's figure at roughly 3.7–5.3 %, rather than 5.45 % with no stated uncertainty.

## Caveats

- **d = 1 and d = 0 carry almost no weight:** 7 and 0 events. Every statement about k = b is an extrapolation in d. The data cannot tell a step from a slope below d = 3.
- **Look-elsewhere.** The pooled d = 2 p-value of 0.002–0.003 is nominal. d = 2 was one of six bins, and was flagged beforehand on 70 % of these data.
- **Factorisation.** DS × structure is approximate at k < b. The error is O(R_b/b) of a factor that is itself 3–20 % from 1 at d = 1 and under 2 % from 1 at d ≥ 2. The k = b factors are exact under the model's assumption.
- **Sampling.** M2 is sampled at 10⁶ n per base when the range exceeds 2e6. The relative sampling error on P(u) is about 0.1 %. At d = 5–6, with 10⁷–10⁹ counts, this sampling noise dominates the GLM dispersion. The leading-digit model's d = 1–4 fit has φ ≈ 2; the project model's has 25, from its per-base scatter.
- **Small bases** (12–19) have ranges shorter than a few periods of b³. Their models use the actual n, so they differ from build.py's uniform-residue λ (b12 ×0.80, b13–18 within 3 %).
- **Base 50** is a non-uniform 24 % sample, with check level 1; bases ≤ 49 have check level 2–3. It agrees with its neighbours (d = 4 ratio 1.01 with the leading digit).
- **Correlations beyond the top 3 and bottom 3 digits** are tested only through the near-tail fit itself.

## Files

| file | what |
|---|---|
| `models.py` | the model ladder per base → `data/models.csv` (expected counts for d = 0–6), `data/udist.csv` (P(u) of the fixed digits) |
| `analyze.py` | pooled ratios, GLM fits, digit-sum class test → `data/tail_table.csv`, `data/pooled.csv`, `data/fits.csv`, `data/class_test.csv` |
| `extra.py` | brute-force recount, d = 2 heterogeneity and replication split, leading-digit factor to b64 and the headline translation → `data/top_factor.csv` |
| `tables.py` | the markdown tables above → `tables.md` |
| `data/*.json`, `data/observed.csv`, `data/notable.csv`, `data/chunks50.csv` | fetched data |

Run: `nice -n 19 uv run --no-project --with numpy --with pandas --with scipy python models.py` (about 3 min), then `analyze.py`, `extra.py` (about 2 min) and `tables.py`.
