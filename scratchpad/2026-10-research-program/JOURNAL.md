# Journal

Newest first. One entry per working day: what was done, what was decided, what is
in flight, and anything the next director needs to know. Keep each entry short; the
numbers go in EXPERIMENTS.md and the status in LEDGER.md.

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
- **Side finding:** 5 entries per thread beats 4 (current) and 6 (PR #205) at b62/b64 on
  the 3080 by 3.4–5.4 %, two rounds, one field; wave padding explains it. Not a claim yet.
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
