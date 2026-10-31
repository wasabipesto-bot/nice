# Journal

Newest first. One entry per working day: what was done, what was decided, what is
in flight, and anything the next director needs to know. Keep each entry short; the
numbers go in EXPERIMENTS.md and the status in LEDGER.md.

## 2026-10-31 (day 4; routine fired 04:41 UTC)

- **Reconcile:** no research instances; October research invoiced $4.24 (yesterday's $2.36
  on seven rentals); fleet $66.92; credit $62.72; ivory disk 93 % → 89 % after removing two
  stray build caches (pr-detailed-fd, pr-readback: agents built on ivory despite the brief).
  #221 and #225 open and green, no review comments; #224 merged; **#226 merged** (API: detailed
  Next claims from a cursor, wait for refills — the user's answer to the claim-rate note).
  main = 472c9a0. No user messages since the authorisation; the Metal issue closed last night.
- **PR #227 opened** (browser CPU detailed on FD, stacked on #221): ×7.0 suite, byte-identical
  in Chromium on 141 windows (L23.1). L24 plan written: ~5 days, not 1–2 (L24/PLAN.md).
- **L25 audit (L25.1): one production kernel has the pattern (join `top_kernel`), harmless at
  live bases, wrong at b49–55 on Apple; fix exact on CUDA/lavapipe, no cost → PR #228 opened.**
  Needs one M4 run (main+windows expected to fail; branch to pass). Box destroyed (1.17 h).
- **Afternoon (user):** 1 h of mayalaran granted → #228 confirmed on the M4 (0 vs 934 / 0 vs 445
  survivors on main; branch passes), 8 min used; stride prefilter probe passes on main (fix is
  defensive → small PR, L26). L24 detailed proposal written (`L24/PROPOSAL.md`, ~6 days, PR split
  (a) seed refactor → (c) parity step → (b) kernel; headless Playwright on real GPUs; 10 open
  questions). Stride-prefilter detail answered in chat.
- **Evening (user):** #221, #225, #228 merged by the user; #227 rebased (CHANGELOG conflict
  resolved, one commit 33120f0). All ten L24 questions agreed; **mayalaran authorised 16 h from
  ~16:30 UTC or until the web GPU runner is complete.** Started L24 (a) seed-refactor PR (3080 box
  + M4 seed test) and the headless WebGPU bring-up on the M4 in parallel; L26 prefilter PR agent
  still running (3060 box). Stale agent pins stopped at the user's request.
- **PR #229 opened** (stride prefilter defensive fix; L26.1). **Headless Metal bring-up done:** no
  flags needed, adapter apple/metal-3, today's browser kernel exact on Apple via Chrome's Tint on
  201 windows (`L24/BRINGUP-M4.md`, harness `exp/browser-gpu-harness` 5eeed09); 22 min of Mac
  time. L24 (c) parity-step PR agent launched.
- **PR #230 opened** (L24 (a) seed refactor; verified CUDA/lavapipe/M4, L24.1). **PR (b) web FD
  kernel agent launched** (stacked on #230; 3080 box 6 h; M4 parity + speed within the window).
  (c) parity-step agent still running. #227 was merged by the user meanwhile.
- **PR #231 opened** (L24 (c): parity step + adapter check + WGSL lint as a CI step; M4 `--hw`
  parity 199 windows identical). User asked about a red NVRTC check on main that went green on
  rerun: diagnosed as the adaptive-MSD-floor timing dependence in the threaded-pipeline test (L24.2);
  fix agent launched (L27). Stray tracked `oom` file on main since #226 (rootless podman artefact).
- **PR #232 opened** (pin the MSD floor in the threaded-pipeline test; L27). #231 has one red
  check from that flake and cannot be rerun by me (no admin rights); rebase after #232 merges.
- **PR #233 opened** (L24 (b): browser GPU FD kernel; M4 6.7×/10.1×, score 265 → 2170; exact on
  lavapipe/SPIR-V/SwiftShader/M4 Chromium/M4 native; L24.3). All three L24 PRs are open (#230
  merged). #232 fixes the flake; after it merges, rebase #231 and #233; the lint's require list
  needs `DetailedFdKernelU32@40/50` in whichever of #231/#233 lands second. New lead L28.
- Today: 13 agents (all Opus), boxes: 3060 ×2, 3080 ×3; mayalaran ~1 h 45 min total today.
- **Leads today:** L25 kernel audit for the Apple half-shift-divide pattern (desk + WGSL
  dumps on a $0.056/h 3060, lavapipe) — kill criterion: none, it is an audit; L23 wasm CPU
  path on finite differences (ivory build + Playwright docker parity + web NiceMark) — kill
  criterion: parity mismatch or no speed-up in the browser; L24 web GPU port: plan only.

## 2026-10-30 (day 3, afternoon; user: "keep working on the FD ports today ... get all results submitted as PRs")

- 12:25 UTC: credit topped up to $65.37; **#222 merged**, **#223 merged** (the user raised the
  detailed field cap 1e9 → 1e10 after the report's round-trip note); #221 green, awaiting review.
  main = 46e4dc4.
- **PR #224 (readback, +7–9 %) and PR #225 (GPU FD, 3.3–4.0×, stacked) opened** from the 3080
  run (320 W default card; EXPERIMENTS L3.2). 4090 (thermally limited, not power-capped): rb ×1.14/1.09, FD ×3.46/3.92 vs main, score
  11,493 → 42,296; 1e10 fields ×3.06/3.77; identical results on 147 production fields (L3.3).
  Both PR bodies updated. Boxes destroyed (3080 2.1 h, 4090 2.3 h); today's Vast $2.33, month $4.00.

- **Evening, user's notes:** #224 merged; #225 CI red (`variant Division is never constructed`
  in the lib-test build: the agent's `cfg_attr(not(test), allow(dead_code))` does not cover
  `--all-targets`). Fixed properly: `DetailedKernel::for_base(base)` picks FD where `fd_plan`
  has a plan and `Division` elsewhere, so both variants are production code; rebased onto
  946ec15 (#224 in main), squashed, force-pushed as 18cba8b; local clippy (default, all
  targets) and fmt clean; **CI fully green on 18cba8b**, including the macOS Metal job (first
  real Metal run of the FD kernel) and lavapipe. Clippy build took ~7 GB on ivory; target removed after.
- **mayalaran (M4), 29 min used: #225's FD kernel is WRONG on Metal** at b23, b27–30, b49/50,
  b52–55 (division exact; CI's paravirtual Metal passed). → #225 converted to draft, comment
  posted. **User: keep using mayalaran until resolved (max 24 h from ~19:30 UTC 10-30).**
  Gate landed (d8038d6; CUDA/lavapipe still FD, speed unchanged) and the desk model of the
  Apple `(x>>16)/K` miscompile explains everything but b23 (L3.5); PR body updated. **M4 root cause found and fixed (L3.6):** Apple compiler miscompiles `(x>>16)/K`; seed
  rewritten in 16-bit limbs; exact on all 44 bases on the M4, speed unchanged; 1 h 11 min of
  machine time, cleaned up. CUDA/lavapipe verification passed (L3.7); squashed to dbe2ab7 on main 9747e39, body
  rewritten, **#225 ready for review**, resolution comment posted; **CI fully green on dbe2ab7** (incl. Metal, lavapipe, wasm). Boxes all
  destroyed; today's Vast $2.36 (month $4.24). New lead L25: audit nice-only kernels for the
  Metal pattern. mayalaran total today: 29 min + 1 h 11 min.
- **User questions:** detailed auto order (answer: no change; CubeCL CUDA already leads and
  wgpu serves AMD/Apple; hand-CUDA detailed is a third-stop fallback now ~3.5× slower) and the
  web runner port (L23 CPU ~half a day, L24 GPU 1–2 days; both queued as requested).

## 2026-10-30 (day 3; routine fired 04:41 UTC)

- **Reconcile:** no research instances; October research invoiced $1.66; fleet $65.02;
  credit $17.20 (fleet ~$2/day → the $10 floor in about 3.5 days); ivory disk 84 % after
  yesterday's cleanup. **#215 and #216 merged 2026-10-29 12:56–12:57 UTC**; #218 (the
  user's macOS paravirtual-GPU CI fix) too; main = d1ff798. Open upstream: #194, #160,
  #220 (dependabot). No user messages since the feedback of 10-29.
- **PR #221 opened** ("Detailed mode: digit arrays by finite differences instead of
  division", 7019653): CPU detailed score ×6.76 on a 15-CPU Broadwell box, no regression at
  any thread count (EXPERIMENTS L2.2). Box destroyed after 1.15 h.
- **L3 GPU detailed FD prototype: 2.6× / 3.2× (b40/b50) on a 180 W-capped 3080, ~2.2–2.7× per
  clock, exact; 3.2–4.0× with the near-miss readback fix** (L3.1; `exp/gpu-detailed-fd`
  e0c1b4c). PR tomorrow after an uncapped run; readback fix = L21, its own small PR.
- **L1 re-profile on d1ff798 (L1.5):** 1e14 fixed cost 40–74 % of a field; partitions per
  launch 16→32/64 gives ×0.78–0.92; new lead L20 (buffers sized by pruned lists + more
  partitions per launch), agent running on a 20 GB 3080 with a 10 GB-budget override;
  due by ~10:15 UTC at the latest; a one-shot reminder at 08:02 UTC is the fallback.
- **L20 result:** ×0.79–0.88 at 1e14, neutral at 1e16 → **parked**: the live fields are 1e16
  (b60) and 1e17 (b62) per the data API, so it does not help production. My brief's
  "production size = 1e14" came from a stale code comment. Lesson: check the live field
  sizes before calling a size "production".
- **Found a latent race in `join_kernel`'s flush decision** (L1.6): **PR #222** opened (one
  barrier; correctness; cost within noise).
- Boxes: l2-cpu 1.15 h, l1-profile2 1.67 h, l3-gpu-fd 1.93 h, l20-launch 3.36 h; all destroyed.
  Today $1.14; month $2.80. Credit $15.45.
- Agents: 4 Opus. Director ~5.3 h (over by 20 min: the L20 analysis ran long).

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
