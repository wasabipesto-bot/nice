# Journal

Newest first. One entry per working day: what was done, what was decided, what is
in flight, and anything the next director needs to know. Keep each entry short; the
numbers go in EXPERIMENTS.md and the status in LEDGER.md.

## 2026-10-29 (day 2; routine fired 04:41 UTC)

- **Reconcile:** no research instances; October research invoiced $0.44; fleet $62.83;
  credit $20.61 (fleet burns ~$2/day); ivory disk 96 % (3.6 GB free; the day-1 build
  caches); no user replies since the day-1 report.
- **The user merged the queue on 10-28 evening:** #188–#193, #195–#197, #200–#209,
  #211–#214, including #203 (closure), #205 (EPT 6 from b62), #206 (memory budget),
  #204, #207. Open upstream: #194 (fleet host CPU) and #160 (Lean). main = 2709d3f.
  So the prune PR rebases onto a main that already has EPT 6 at b62/b64; the prune's
  gain there must be re-measured against it, and the wave size may need to move with it.
- **L2 prototype (finite differences for detailed mode): 5.6× scalar, 8.5× packed on
  b50_detailed_1t, exact on 11 tests** (`rp/l2-finite-diff`, EXPERIMENTS L2.1). Not wired
  into the client yet; ivory cannot build the client (disk 1.6 GB free after the build).
- **L7 sweep 1:** no new papers; two counting ideas (L18 bit-sliced bucket scan, L19).
- **Prune vs new main, two cards (L1.4, PR-RESULTS-3080.md):** 1e16 ×1.10–1.25, 1e14
  ×1.4–2.3; NiceMark ×1.17–1.22; exact (counts identical to the last digit at 1e14). The
  day-1 stage-overrun ripple does not exist on new main (#205's wave already holds a
  bucket); main itself overruns 0.4 % at b60 (+5 % full checks), a follow-up.
- **PR #215 opened** ("Overlap join: prune the bottom list by the field certificate",
  head 941e39e). `pr/join-ept-2` (cb38b91, EPT 2 everywhere, replaces #205's rule) is
  stacked and measured; PR named for tomorrow.
- **Boxes:** 3080 KR 3.1 h ($0.38), 4090 PL 2.2 h ($0.81; 330 W-limited). The 3080 was
  host-capped at 150 W. Both destroyed. Month-to-date $1.66.
- **ivory disk 97 %:** cleaned my rp-l1 build cache (641 MB); the rest is the user's
  (old worktrees 8 GB, yarn/uv caches 8 GB, docker images 6 GB, toolchain 1.99.0).
  No more builds on ivory until there is room; client builds go to boxes anyway.
- **User feedback after the report (saved to memory):** PR bodies must not reference the
  program or scratchpad; follow-ups brief and explicitly excluded; open PRs immediately when
  measured; re-pinning is ops. #215's body trimmed; **PR #216 (EPT 2) opened**. Cleanup on
  the user's instruction: yarn cache 4.5 GB, toolchain 1.99.0, 19 worktrees older than 7 days.
- **Tomorrow:** L2 client wiring + 5 % protocol on a box, then its PR; GPU port scoping;
  L18 counting experiment if time allows.

## 2026-10-28 (day 1; routine fired 04:41 UTC)

- **Reconcile:** no research instances; research invoiced $0.00 for October; fleet $61.33;
  credit $23.27; ivory disk 91 % (6.7 GB free); 19 PRs open upstream, all green except
  dependabot #198 (cubecl-common 0.11, failing) and two cancelled dependabot runs.
- **L1 answered.** Per-prefix join cost by base is explained by the number of roots of
  x² + x³ ≡ b(b−1)/2 (mod b−1): b58 4, b60 2, b62 2, b64 8 (EXPERIMENTS L1.0–L1.2). CPU
  counts (agent, ivory) and a GPU phase profile (agent, Vast RTX 3080) agree with each
  other and with the earlier 9070 XT rates. The join kernel is 56–83 % of device time;
  its cost is 0.58 ps per lane-pair (padded to 1024-entry waves) + 74 ps per AND survivor.
- **Lever found: field-certificate bottom prune.** Bottoms sharing a digit with the
  field's own certificate can never pair with any top in the field; dropping them removes
  73–86 % of bottoms on 1e14 fields (60–82 % on 1e16). Sound by construction (the field
  mask is a subset of every top mask). Implemented on `rp/field-cert-prune` (fork), exact
  on CPU against the reference join; GPU A/B running on the third box of the day (the
  first two replacement boxes were the same Taiwan machine refusing ssh keys; machine
  146647 is now excluded in the rental query).
- **Prune A/B (L1.3): ×1.15 / 1.15 / 1.42 / 1.64 at b58/60/62/64 on 1e16 fields, NiceMark
  score +28 %, exact on every parity test.** With the prune, EPT 2 beats 4 by 5–14 % (EPT 6 =
  #205 and the EPT 5 note are superseded); prune + EPT 2 = 1.51× (b62), 1.91× (b64) vs main.
  PR to open tomorrow; it needs the staging-flush tweak (b64 crosses a test's 1e-4 limit).
- **L2/L3 merged into one lead:** detailed mode is compute-bound on per-number long
  division on both CPU and GPU (GPU kernel: one thread per number, u32 limbs, divide by
  b⁵; SM 98 %). Finite differences (digit arrays updated by addition) remove the
  divisions; op-count estimate 3–8× on CPU single-thread. `L2/SCOPING.md`; prototype next.
- **Closed:** L4 (final check is 3–11 % everywhere) and L6 (interior-digit theorems are
  non-effective at our lengths, primary sources read).
- **Spend:** four rentals, three RTX 3080 boxes used ($0.134/h), two destroyed early as
  duds; invoiced so far $0.24 (more lands tomorrow). Agents: 6 (3 Opus, 3 Sonnet).
- **Branches on the fork:** `rp/l1-selectivity` (a76984f, tests only), `rp/gpu-profile`
  (69a83b5, profile + EPT override), `rp/field-cert-prune` (c1306b5), `research-program`.
- **Worktrees created:** `.worktrees/rp-l1`, `rp-prune`, `rp-gpu-profile`. `rp-l1` and
  `rp-prune` share `rp-l1/target` (the prune build now occupies it; rebuild before reuse).
- **Tomorrow:** prune verdict → PR if ≥ 5 % (named in today's report); L2 CPU prototype;
  EPT third round on a second GPU; a b60 field at the 9070 XT's density for calibration.

## 2026-10-28 (setup)

- The user approved PROPOSAL.md as written. Decisions: routine into this session;
  00:41 America/Indiana/Indianapolis; report as the session reply; urgent pings to ntfy
  (topic not yet given); **heavy posture** ($200/month plan); $30/month Vast on top of
  the fleet's $50 (the fleet budget may drop later); **up to 5 program PRs open, 2–3 if
  large**; closed items may be reopened with a reason; demoux/mayalaran time may be
  requested when genuinely helpful.
- Built: `vast.py` (budget-guarded rentals), `sync.sh` (branch snapshot to the fork),
  LEDGER/JOURNAL/EXPERIMENTS/REPORTS, README.md (operating notes).
- In flight: nothing. Day one is the routine's first firing.
