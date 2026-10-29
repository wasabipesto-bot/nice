Overlap join: prune the bottom list by the field certificate

Research program L1 follow-up (`L1/PRUNE.md`). Based on main at `2709d3f`, after #203, #204, #205 and #206.

Every top of a field certifies a sub-interval of the field, so its mask contains the field's own certificate, `cert(s, e − 1, k)`: the digits of n² and n³ at positions ≥ k that every nice n of the field has. A bottom residue whose low digits meet that mask fails every AND of the field. On production fields that is most of the bottom list: of the entries a partition lists, 63–77 % on the 1e16 fields measured here and 72–86 % on 1e14 fields at bases 58–64. Until now they were extended, listed, loaded into registers and ANDed against every top of their bucket, only to fail.

This PR drops them on the bottom side. `FieldSetup` keeps the field's certificate (`fc`) and prunes `bpre` by it. The CPU extension and lists and the GPU bucket kernel also test every digit they add (the partition's fixed digits and the key digit) against it, so those entries are never listed. The AND, the prefilter, the full check and the reference `join_range` are unchanged. A slice prunes by its own certificate, from the unpruned list (`bp_all`). Buffers are still sized by that unpruned list, so layouts, partitions per launch and slices are the same as on main. Pruned buckets are a quarter to a third of the size, so the join kernel gathers and ANDs far fewer entries for the same survivors.

**Soundness.** The field's certificate is, by `Base::cert`'s contract, a set of digits that every nice n of the field has at positions ≥ k, including the digits #203's closure forces. A residue's digits sit below k. So a residue whose mask meets the certificate, or that a partition or key digit extends by one of its digits, is part of no nice n. That holds whatever the tops are. Because every top certifies a sub-interval of the field, those residues would also fail every AND, so the join's survivors are the same with or without the prune. The counters below, and the parity tests against the unpruned reference, show exactly that. The argument is now a paragraph under "Soundness" in `overlap_join.rs`'s module doc.

## Measured

Fixed fields through the client's route (`cubecl_cuda_join_throughput_fixed_fields`), two fields in flight, after a 1e14 warm-up per base, 3 interleaved rounds. Starts: b58 104400216587923470200, b60 1366406074057412100454, b62 7997740455941656911841, b64 41242006262957161709568. Main is `2709d3f` plus this PR's test-only harness commit. Seconds per field, medians:

**1e16 fields** (on new main every field is one slice on both cards; layouts and partitions per launch are identical between trees):

| base | RTX 3080: main | this PR | **×** | RTX 4090: main | this PR | **×** |
|---|---|---|---|---|---|---|
| 58 | 81.11 | 72.69 | **×1.116** | 24.78 | 22.58 | **×1.097** |
| 60 | 56.97 | 51.90 | **×1.098** | 17.77 | 16.40 | **×1.084** |
| 62 | 29.19 | 25.25 | **×1.156** | 9.00 | 8.09 | **×1.112** |
| 64 | 94.97 | 76.00 | **×1.250** | 27.53 | 22.85 | **×1.205** |

Spreads are 0.2–1.5 % on the 3080 and 0.1–2.4 % on the 4090.

**1e14 fields** (production size; 20 consecutive fields per base):

| base | RTX 3080: main | this PR | **×** | RTX 4090: main | this PR | **×** |
|---|---|---|---|---|---|---|
| 58 | 1.543 | 0.982 | **×1.57** | 0.519 | 0.367 | **×1.41** |
| 60 | 1.336 | 0.782 | **×1.71** | 0.457 | 0.304 | **×1.50** |
| 62 | 1.810 | 0.800 | **×2.26** | 0.570 | 0.305 | **×1.87** |
| 64 | 2.268 | 1.043 | **×2.17** | 0.695 | 0.389 | **×1.79** |

Spreads are 0.2–4.1 % on the 3080 and up to 4.2 % on the 4090, where these runs are 6–14 s per base.

- **Smaller fields gain more.** A 1e14 field knows 6–9 certificate digits and loses 72–86 % of its bottoms, against 63–77 % at 1e16. At 1e14 the bottom side is a large fixed cost per field, and the prune removes most of it.
- **The cards.** Both are power-limited by their hosts: the 3080 to 150 W (default 320 W, SM clock 1260–1275 MHz), the 4090 to 330 W (default 450 W). The ratios are what matters here.
- **Against yesterday's base.** Against `85b5b4e` (4 entries per thread everywhere, 5–8 slices per field) the same 1e16 fields gave ×1.153 / 1.145 / 1.415 / 1.643 on a full-power 3080 and ×1.14 / 1.14 / 1.37 / 1.58 on this 4090. The gain is smaller on new main for two reasons:
  - #205's 6 entries per thread at b62/b64 already took ×1.08–1.16 of what the prune also recovers, and leaves pruned buckets (about 280–420 entries) in 1,536-entry waves that run mostly empty. That is the follow-up below.
  - Main's own gains (#204, #206) shrink the share of time the prune removes.

**NiceMark nice-only** (`nice_client niceonly --gpu --benchmark --benchmark-secs 150`, 3 interleaved rounds, every scenario on the join on both trees):

| scenario | RTX 3080: main | this PR | **×** | RTX 4090: main | this PR | **×** |
|---|---|---|---|---|---|---|
| b58_msd_weak (1e15) | 1.096e14 | 1.309e14 | **×1.193** | 3.640e14 | 4.194e14 | **×1.152** |
| b58_msd_strong (1e15) | 5.894e14 | 8.186e14 | **×1.389** | 1.798e15 | 2.392e15 | **×1.330** |
| b60_msd_weak (1e16) | 2.272e14 | 2.614e14 | **×1.151** | 7.767e14 | 8.348e14 | **×1.075** |
| b62_msd_weak (1e16) | 2.631e14 | 3.093e14 | **×1.176** | 9.029e14 | 1.016e15 | **×1.126** |
| **score** | 2451 | 3001 | **×1.224** | 8086 | 9494 | **×1.174** |

Medians of 3 rounds (n/s); spreads up to 2.3 % on the 3080 and 6.2 % on the 4090. With 2 entries per thread the 3080 scores 3310 (×1.350 over main).

**Counters.** In every 1e16 run the two trees count the same AND survivors and full checks to 5–8 significant figures. They differ only by the timing-dependent stage overrun (Δchecked ≈ −0.93 Δsurvivors, the overrun path), which is the same on both trees on new main. The 1e14 runs, which have no overrun, are identical to the last digit across main and the PR on both cards.


## Where the saving lands

The 3080 with the research program's phase timers (`NICE_EXP_GPU_PROFILE=1`, which synchronises after each kernel group; +0.4–2 % here), one 1e16 field per base, main against this PR. Seconds per field:

| base | top (certify + bucket the tops) | bucket kernel | join kernel (AND + prefilter) | full check | other | device | listed entries | AND pairs | survivors |
|---|---|---|---|---|---|---|---|---|---|
| 58 | 20.00 → 20.20 | 0.70 → 0.36 | **56.77 → 48.53** | 3.00 → 3.03 | 1.36 → 1.25 | 81.83 → 73.37 | −63 % | −62 % | = |
| 60 | 15.68 → 15.78 | 0.76 → 0.41 | **35.92 → 30.26** | 2.62 → 2.60 | 1.55 → 1.64 | 56.54 → 50.70 | −63 % | −57 % | = |
| 62 | 12.12 → 11.88 | 0.55 → 0.23 | **25.12 → 20.04** | 1.23 → 1.19 | 1.00 → 1.01 | 40.02 → 34.36 | −74 % | −74 % | = |
| 64 | 8.24 → 8.07 | 0.62 → 0.22 | **81.92 → 63.99** | 2.92 → 2.88 | 0.79 → 0.78 | 94.50 → 75.93 | −77 % | −77 % | = |

- **90–97 % of the saving is in the join kernel.** The bucket kernel halves, but on new main (one slice per field) it is under 1.5 % of the time. Top certification, the full check and the survivors do not change.
- **The join saves 14–22 %, though its pairs fall 57–77 %.** Wave-padded lane-pairs are the same on both trees at every base (b64: 4.76e13), because a bucket takes one wave either way: 1,024 entries per wave at b58/b60 and 1,536 from b62, against pruned buckets of about 280–420 entries. Padded lanes skip the loads, so the PR saves the gathers and ANDs of the entries it drops but keeps the empty lanes (padded/pairs rises from 1.07–1.29 to 2.6–5.5). Two entries per thread (512-entry waves) recover those lanes; that is the follow-up below.


## Exactness

- **New unit test** `cpu_join::tests::the_field_prune_drops_exactly_the_bottoms_that_meet_the_certificate`, on every `PLAN_FIELDS` field (b42–b64). It asserts:
  - `fs.fc == cert(s, e − 1, k)`;
  - `fc = 0` prunes nothing, and neither does a certificate that meets every residue (the fallback for a range with no nice number);
  - the pruned `bpre` (class, residue, mask) equals the unpruned one filtered by `m & fc == 0`;
  - on two live partitions per field and every key digit, the CPU bottom lists (key, class, residue, mask, carries) equal the unpruned lists filtered the same way.

  It prints the counts. At 1e14, of the entries a partition lists, it drops 81.5 % (b57), 82.3 % (b60), 86.3 % (b62) and 85.0 % (b64), with 6–9 certificate digits; 39.7 % at b50; none at b42, whose certificate is empty.
- **The unpruned reference.** `join_range` is untouched, and the parity tests compare the pruned joins against it: join survivors, prefilter survivors and hits.
  - `cpu_join_matches_the_reference_on_production_fields` (`NICE_TEST_CPU_JOIN_REF=2`, b42–b64): passes on the 3080's host (2 partitions per field).
  - `cubecl_cuda_join_matches_the_cpu_reference` (every window, tight layouts, slices, refused layouts): passes on the 3080 and the 4090.
  - The dense-field test passes at b58 1e15 (32 partitions: 0 survivors overran the stage). At b64 1e16, with the new `NICE_TEST_JOIN_DENSE_FIELD`, it passes as well (8 partitions, first slice: 2.5e-5 of the survivors overran the stage, under the test's 1e-4 limit; main's overrun on that field is the same, 3.7e-5 counted directly).
- **Join against stride.** `NICE_TEST_JOIN_COMPARE=1` on 2 fields of 1e14 per base at the A/B starts: the join and the stride pipeline agree at b58–64 on both cards. These fields hold no nice numbers, so this check is weak on its own.
- **Counters at production size.** At 1e14 the survivors and full checks are identical to the last digit between main and the PR at every base and round, on both cards (b64: 65,747,036,999 survivors and 3,999,993,450 full checks per 20 fields). At 1e16 they agree to within the stage overrun, which is the same on both trees.
- **Host tests:** `nice_common` with `--features gpu`, 207 passed. **Lint:** `cargo fmt --all --check`, and `cargo clippy -p nice_common -p nice_client --all-targets -- -D warnings` with default features, with `nice_client/gpu` and with `nice_client/gpu,nice_client/cubecl-spirv`, are clean at the head (`941e39e`).


## Not in this PR (deliberately)

- **NiceMark references.** `bench_defs.rs`'s nice-only references were pinned on main. With the prune they read about 17–22 % high (NiceMark above). Re-pin once this merges, as a separate change.
- **Entries per thread.** #205's rule (6 from base 62, 4 below) was fitted to unpruned buckets of about 1,200 entries. Pruned buckets hold about 280–420 entries at 1e16 and fewer at 1e14, so 1,024- and 1,536-entry waves run mostly empty lanes. With the prune, 2 entries per thread are the fastest at every base on both cards. That goes in a stacked PR (`pr/join-ept-2`, one commit on this branch); the numbers are under "Follow-up: entries per thread" below.
- **Buffer sizing.** `Footprint` sizes the bottom-side buffers by the unpruned `bpre` (`bp_all`), so every layout, slot count and slice is exactly main's. Sizing them by the pruned lists (the largest over a field's slices) would free memory for more partitions per launch. That changes layouts, so it should be measured on its own.
- **The survivor stage's overrun.** Yesterday's A/B (against `85b5b4e`, 4 entries per thread) had more survivors overrun the join kernel's shared stage with the prune. That came from 4-entry waves at b62/b64: an unpruned bucket spread its survivors over two waves, a pruned one put them in one. On main after #205 every unpruned bucket already fits one wave, and the overrun is the same with and without the prune at every base (counted directly on experiment builds; "Follow-up: the survivor stage" below). b64 is at 3.7e-5, under the dense test's 1e-4 limit, which now passes at b64. Main's own b60 overrun is large, though: 0.4 % of the survivors and 5 % more full checks on the 1e16 field. Flushing the stage at a quarter (256) instead of half removes every overrun at b58–64, but costs 1–2 % at b58/b64 on this card, so it is not in this PR.


## Follow-up: entries per thread (`pr/join-ept-2`, stacked)

Same fields and protocol. "+ EPT 2" is this PR with 2 entries per thread at every base. On the 3080 the 1e16 column is this PR's tree with a box-only override (the same constant reaches the kernel, 3 rounds interleaved with the A/B above), and the 1e14 column is `pr/join-ept-2` itself (`cb38b91`; one more 1e16 round of it agrees with the override within 2 %). The 4090's columns are the override.

| base | 3080 1e16: + EPT 2 vs this PR | vs main | 3080 1e14: vs this PR | vs main | 4090 1e16: vs main | 4090 1e14: vs main |
|---|---|---|---|---|---|---|
| 58 | ×1.091 | **×1.218** | ×1.076 | **×1.69** | **×1.19** | **×1.55** |
| 60 | ×1.059 | **×1.163** | ×1.037 | **×1.77** | **×1.16** | **×1.55** |
| 62 | ×1.167 | **×1.349** | ×1.117 | **×2.53** | **×1.26** | **×1.97** |
| 64 | ×1.262 | **×1.577** | ×1.220 | **×2.65** | **×1.52** | **×2.08** |

On the 4090 (the prune on the old base, 3 rounds), EPT 2 beats 4 by ×1.07–1.13 and 6 by ×1.15–1.27, with the order 2 < 3 < 4 < 6 in every round. The counters are unchanged by the wave size.

## Follow-up: the survivor stage

Survivors that overran `join_kernel`'s shared stage (and went to the full check without the prefilter), counted per flush on experiment builds of both trees (one 1e16 field per base, 3080). In the last column the stage flushes at a quarter (256) instead of half (512):

| base | main | this PR | this PR, flush at 256 | 256's time against 512 (2 rounds) |
|---|---|---|---|---|
| 58 | 1.1e-7 | 1.2e-7 | 0 | +2.0 % |
| 60 | **4.0e-3** | **4.0e-3** | 0 | 0.0 % |
| 62 | 2.8e-5 | 2.8e-5 | 0 | +1.0 % |
| 64 | 3.7e-5 | 3.7e-5 | 0 | +2.0 % |

At b60 a 32-top chunk stages about 540 survivors on average, more than the 512 places left after a half-full stage. So 0.4 % of the survivors skip the prefilter there, which adds 5.3 % to the full checks. That is main's, not the prune's. Two untested alternatives keep the flush rate: a 2,048-entry stage (8 KiB more shared memory per cube, to be checked against wgpu and Metal limits), or prefiltering the overflow inline.

## Commits

1. `7efe289`: the prune (`overlap_join.rs`, `cpu_join.rs`, `cubecl_join.rs`, `join_plan.rs`), its unit test and the module-doc paragraph.
2. `941e39e`: test-only. The throughput harness gets starts at bases 58 and 62, `NICE_TEST_JOIN_SIZE` and `NICE_TEST_JOIN_STARTS`. The dense-field test gets `NICE_TEST_JOIN_DENSE_FIELD=base:start:size`, so the stage's overrun can be checked at bases other than 58. These are the knobs this PR's A/B used.

One CHANGELOG line.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
