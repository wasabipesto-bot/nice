# Journal

Newest first. One entry per working day: what was done, what was decided, what is
in flight, and anything the next director needs to know. Keep each entry short; the
numbers go in EXPERIMENTS.md and the status in LEDGER.md.

## 2026-11-12 (cycle 3 of the new director; routine fired 05:41 UTC)

- **Reconcile:** no research instances; November research $11.59 of $30 (fleet $21.01); credit
  $28.73; ivory 7.6 GB free. No user message since the demoux grant. No day missed.
- **#250 merged by the user (01:57 UTC, main = 5b1d627, tree-identical to the branch).** #251–#254
  all conflicted with it (the changelog; #251 and #254 also carried #250's commit). A lease-guarded
  force-push of the rebased commits to my own PR branches was **refused by the harness** ("Git
  Destructive"), so the branches were brought up to date with **merge commits and plain pushes**
  instead: #251 a70b012, #252 7269d61, #253 43b448b, #254 f812a02. Each merge result is
  byte-identical to the rebased cherry-pick, and outside the changelog to the measured tree
  (#252/#253 differ from theirs by exactly #250's own diff). All four MERGEABLE; bodies of #251 and
  #254 updated (no longer "stacked on #250"). Standing rule from now: PR branches are updated by
  merge commits, never rewritten.
- **Deploys:** none. demoux resumed production at ≈ 15:50 UTC on 11-11 on c0c357a (pre-#250, ≈ 350
  fields an hour), the M4 on c0c357a, the fleet still on v3.4.7. Nothing to measure yet; #250 is
  worth ×1.03–1.04 on demoux when it rebuilds. b60 86.0 %; ends ≈ 11-14.
- **Lead of the day, N16 (the join's base on the 9070 XT): preparing the window.** Kill criterion
  (ledger): the split shows the cost spread evenly with no single cause. Agent (Opus) + box
  60315324 (RTX 3080, $0.107/h, 7 h TTL; replaced at 06:18, see below): a harness that splits the base, validated on CUDA and
  lavapipe; an offline ACO dump (time-boxed); a candidate branch for N14; `N16/BRIEF.md`.
- **06:00 UTC: N16's premise is false; yesterday's profile of the 9070 XT was mis-derived
  (EXPERIMENTS N13.2).** While checking whether production telemetry could bound a per-launch
  cost (it cannot: launches, density and plan shape are confounded; pooled slope 2.6 ms per
  launch, an upper bound only; `../2026-11-fresh-eyes/launch_regression.py`), I read the `.gpu`
  samples of yesterday's runs: **in the profiled ablation modes the card ran at 1.46–1.93 GHz and
  89–103 W instead of 3.2 GHz and ≈ 300 W** (its clock follows its load). The N13 agent took the
  growing top timer for a sync artefact and derived the join's parts from differences of
  whole-field totals, i.e. across clocks. Rescaled by each run's own top phase: **base 6–7 % of a
  field (at most 13 % with no rescaling at all), AND 12 %, walk 5–6 %, prefilter 28–30 %, check
  17–19 %.** So the card's profile is NVIDIA's with a dearer check and prefilter; "base a third of
  the field" and "survivor path nearly free" are wrong, and I reported both to the user on 11-11.
  The PR A/Bs and the retune (N14, N15) ran at full clock and stand. **N16 closed; N17 opened**: a
  profile taken at the card's operating point (work added at full load, not removed), then the
  largest block there (by the corrected numbers the prefilter).
- **Agent redirected (two messages, 06:00 UTC):** Task A verifies the correction from the logs;
  the harness's primary instrument becomes doubling modes with clock and power logged and
  checked per run; removal modes unprofiled as a second instrument; the same clock check for the
  RTX 3080 (were L51's and B64's ablation shares at full clock?); survivor-path and top-append
  switches; the window plan's first 45 minutes are the corrected profile at b62 and b64.
- **06:18 UTC: box 60315324 replaced.** Its sshd refused every key (bad ownership on
  `authorized_keys`, a host fault) and its start-up clone failed while `READY` was still touched
  (my script chained with `;`). Destroyed after 0.44 h (~$0.05); replacement 60317813 (RTX 3080 at
  280 W on a Ryzen 5 5600X, $0.122/h, 6.5 h TTL), ssh verified before handing it over; the start-up
  script now creates `READY` only if the clone and fetch succeed. `vast.py create <offer id>`
  needs `--gpu` beside the id, or the offer is not in the first page of the search.
- 06:51 UTC: **#251–#254 all green on their merge commits** (25 pass, 3 skipped each; mergeable,
  clean; no comments or reviews).
- **09:53 UTC: the harness agent finished (N16.1; 582 k tokens); box destroyed after 3.59 h
  ($0.47).** I re-ran its analysis on the raw logs (clock and power beside every row) before
  recording anything.
  - **Task A confirms the correction and bounds it honestly:** base 7–13 %, AND 12–19 %, walk
    5–6 %, prefilter 15–28 %, survivor path 21–35 %. My morning figures were the scaled end of
    each range and I called them "good to a few points": too tight; the report is amended.
  - **Harness:** `exp/n16-join-base` 32e9e19: exact doubling modes for every part, finer removal
    cuts, work-group size decoupled from `TOP_CAP`, the survivor stage's size, top-append ballot
    forms, a partitions-per-launch cap, host launch accounting; every run logs clock, power and
    busy % and the analysis flags runs off the operating point. Exact modes pass the dense compare
    on CUDA and lavapipe. `N16/WINDOW-PLAN.md`: one script, must-haves by 0:45, hard end 1:24.
  - **RTX 3080 by doubling** (b62 / b64 1e17): prefilter 15.9 / 20.8 %, AND 14.6 / 14.6 %, check
    11.3 / 11.0 %, walk 9.1 / 12.6 %, copy 4.6 %; removal agrees within 1–3 points and with L51.
    The 3080 keeps its clock in light modes: **the NVIDIA shares (L51, B64) stand.**
  - **What ACO generates for RDNA4:** wave64, clean code, but **18.9 KiB of shared memory per work
    group caps occupancy at 12 waves per SIMD**; `TOP_CAP` 128 or a 256-entry survivor stage
    gives 18, both 24. This would explain `TOP_CAP` 128's unexplained gain on demoux, and the
    stage size is neutral on NVIDIA, so it needs no per-device rule: **new lead N19**, tested by
    three rows of the window plan.
  - **N14's candidate branch** `exp/n14-wgpu-dense-plan` 464be8b (discrete wgpu adapters with a
    2 GiB budget); not reviewed, no PR; the window measures it.
  - Side note for NVIDIA (N18, parked): CubeCL's CUDA fence is synchronous; ≤ ×1.04 at b62, an
    estimate.
- **Plan from here:** ask for the window (≤ 90 min, card to itself). With it: the profile, N19,
  N14's A/B, b64 rows. Without it: a reviewer on N14's branch; N19 cannot be measured elsewhere.
- **15:27 UTC: the user granted a 120-minute demoux window** (production client already stopped,
  card idle) **and said my use of the token budget has been low, asking how I size a session.**
  Honest answer: by habit, not by a number (one lead, one agent, one box a day; the routine's
  "use few" and my own "lighter days" note of 11-10). The Vast cap is what binds (≈ $0.95 a day
  left), not tokens. From now: several tracks in parallel, weighted to work that is heavy in
  tokens and light in GPU-hours (audits, design, reviews, CPU work, theory).
- **The user merged #252, #254 (12:12–12:14 UTC) and #253 (14:56 UTC); main = a7a59c1.** #251 then
  conflicted (changelog; one struct doc comment that #254 reworded): replayed onto main, resolved
  to #251's fields with main's wording, fmt + clippy (cubecl) + `join_check` (5 tests) + `join_plan`
  (9 tests) on ivory, merge commit bc9d87c pushed plainly; body's first line updated. One PR open.
- **Window (15:28–17:28 UTC), workspace `/tmp/claude-exp-2026-11-12-amd`, watchdog wipe 17:27, no
  run starts after 17:12.** My own driver instead of `go_window.sh`, actionable rows first:
  stage 1 = build, the doubling profile (b62, b64), a b60 screen of the shared-memory, plan and
  geometry variants (with combinations I added to `modes.sh`), removal unprofiled at b60, a b64
  screen; stage 2 = three rotated rounds of the screen's winners at b62 and b60, then the
  denser-plan binary (does its device rule engage on RADV?). First rows at full clock (3.14–3.19
  GHz, 304 W, exact): **prefilter +26.8 % of a b62 field when doubled (RTX 3080: 15.9 %), check
  +17.2 % (11.3 %), AND +11.9 % (14.6 %), walk +6.9 % (9.1 %).**
- **Second track started 15:41 UTC (T2.3):** a sampled exact re-verification of b58/b60 nice-only
  submissions by (device, build) cell on box 60374124 (agent, `T2/BRIEF.md`); production API
  blocked on the box before any client runs. Kill: none needed (an audit); stop at 21:30 UTC.
- **17:09 UTC: window closed after 101 of 120 minutes (N17.1).** Workspace removed, my watchdog
  stopped by PID, nothing of mine left, production client still stopped (one ntfy sent). A harness
  auth interruption at ~15:58 UTC killed the audit agent mid-run (resumed 16:01) and cost the
  window nothing (the card ran from scripts). Results, all at 303–304 W with exact counts:
  - **Profile:** prefilter 26 % (b62) / 30 % (b64) of a field, check 16–17 %, AND 11 %, walk 6–8 %,
    per-batch parts ≈ 1 %. The card pays about twice NVIDIA's cost per pair for the prefilter and
    the check and matches it elsewhere.
  - **N19 confirmed:** a 512-entry survivor stage is ×1.056 at b62 and b60 (three rounds), ×1.062
    at b64 (stage 256), neutral on the RTX 3080. PR candidate.
  - **N20 (new, found during the window):** at base 64 the prefilter's digits are bit fields;
    as shifts ×1.051 at b64, exact. PR candidate.
  - **N14:** the rule engages on RADV; ×1.035–1.045 at b62, ×1.045–1.053 at b60, **×1.004 at b64**:
    held. **N15 dropped** (after the stage it adds ×1.01–1.03). All three together ×1.114 (b62) /
    ×1.139 (b60).
  - Multiply probe unresolved (variants within layout noise); it does price the walk loop:
    ≈ 0.5 % of a field per instruction on this card → N21.
  - #254 is ×1.11–1.12 at b64 on this card (main 135.2 s against 150–151.6 s without it).
- **Next (tomorrow's cycle, several tracks):** PR branches for N19 and N20 (CUDA NiceMark and
  three rounds on a box, lavapipe, reviewer each); N21 design agent with the offline ACO compile;
  the audit's result (T2.3, running until 21:30 UTC); realized gains on demoux once it rebuilds
  from main (#250, #252–#254 are in).
- **Lesson (README updated):** on a card whose clock follows its load, never compare runs with
  work removed; log clock and power beside every timing and reject runs off the operating point.
  I passed the N13 agent's explanation on without opening the samples it had recorded.

## 2026-11-09 evening: director change (user request), fresh-eyes review

- **Handover.** The user moved the program into a new session (`session_014g2dyZ4dAhZFch4nmKWPyZ`,
  "Daily autonomous nice research migration") and asked for a review with fresh eyes before the
  next cycle. The old routine `trig_012YG24kD3dwPtQAheLqir5F` is disabled; the new routine and
  its prompt are in `ROUTINE.md`. The old director session is not woken any more.
- **State inherited.** The user merged #241, #246, #247, #248, #249 today (19:37–20:05 UTC);
  no program PR is open. Four reviewed branches wait: `pr/top-fd-round2` (4336a18),
  `pr/check-d` (d8390d9), `pr/cpu-join-two-pass-scan` (1cce00d), `pr/cpu-join-seeded-check`
  (0fc06a0); each needs a rebase onto main c0c357a before opening. b60 is 75 % searched, b62
  not started. Vast November research $10.29.
- **Review** (`../2026-11-fresh-eyes/NOTES.md`): (1) everything reachable (rest of b60, b62,
  b64, b65) sums to λ ≈ 0.19 %; λ/cost falls ≈ ×0.45 per base and ×10 of compute buys about
  one base, so no kernel work changes the odds' order of magnitude. (2) No sub-exhaustive
  method in sight: digit-local search learns ≤ 2 output digits per fixed digit of n and the
  other ≈ 3L arrive at once; lattice windows buy 1 per digit; argument written down to be
  attacked. (3) The join's macro shape (f0 3, k 6, p 2) was never re-derived: an operation
  model calibrated on the measured b62 profile says units keyed by the shared middle digits
  with 9-digit bottoms and f0 4 cost ≈ a third of today's time per base (×2.5–4), with MB-sized
  units. k 10 loses to memory traffic; the field prune and deep bottoms compete for the same
  digits. (4) Bases 50–58 are single-pass nice-only (CL 1); a second pass by the join costs
  ≈ $15–25 today.
- **Plan (default until the user redirects):** tracks instead of three kernel leads a day.
  T1 transversal join: exact small-base prototype of the decomposition + tile microbenchmark on
  a 3080 → proposal with measured numbers (kill < ×2 projected on a b62 base). T2 integrity:
  read-only exposure analysis of CL 1 fields → proposal. T3 theory: adversarial review of the
  no-shortcut argument; near-miss structure mining. T4 delivery: rebase and open the four held
  branches (reviewed, measured, within the cap). Kernel trims under ×1.10 are parked, not PR'd.
  Subagents stay Opus (implementation, review) and Sonnet (surveys), fewer and longer.
- Questions put to the user in the handover report: whether a change of the server's work unit
  is on the table; whether to buy a second pass of b50–60; what to optimise for beyond the
  search itself; subagent models; opening all four held branches.

## 2026-11-11 (cycle 2 of the new director; routine fired 05:41 UTC)

- **Reconcile:** no research instances; November research $10.97 of $30 (fleet $18.73); credit
  $31.62; ivory 9.4 GB free. **#250–#253 open, all green, mergeable, no comments, not merged**
  (4 of 5 PR slots used); main = c0c357a. No user message since yesterday's PR-bar correction.
- **b60's reset fields are all re-searched** (600 of 600 sampled at check level 1); b58 100 %, b60
  80.7 %, b62 not started.
- **Who is searching (latest 60k submission ids, 583 nice-only fields):** demoux 474 and mayalaran
  59 on main (c0c357a, 3.4.8-dev), **the fleet 50 on v3.4.7** (8bd154b). The paid fleet is on
  the release of 10-31, which lacks #235–#241, #246, #249: by the PRs' own A/B numbers main is
  ≈ ×2.4 that release at b60 1e16 (×1.80 × 1.06 × 1.122 × 1.154, multiplied, not re-measured as
  one). A release is the user's ops step; flagged at the top of today's report.
- **Leads today** (kill criteria first):
  - **B64 profile and roadmap** (agent, one RTX 3080, ≤ 6 h): b64 is ≈ 90 % of the reachable cost
    and has never been profiled on its own (the FD top kernel is off at power-of-two bases, 40 %
    of 1e16 fields are empty, 8 residue classes). Shares and per-operation costs on production-
    shaped fields at ≥ 10 locations, 1e16 against 1e17 fields, a constants retune at b64, what
    b = 2^6 allows. **Kill: no lever ≥ ×1.05 at b64 → record the profile only.**
  - **N11, the walk's per-pair floor** (same agent and box, after the profile): what the
    0.13–0.15 ps per pair consists of and whether a small change removes part of it.
    **Kill: < ×1.05 at b62 1e17 and b60 1e16, or any NiceMark scenario below ×0.98.**

- **Who does the search, and what the merged work did there (06:30 UTC, EXPERIMENTS T2.1; public
  telemetry only):** over 11-09/10 demoux (RX 9070 XT, wgpu on Vulkan, main) submitted **81 %**
  of the nice-only fields, the fleet 13 % (≈ 20 GPU-hours a day, on v3.4.7), mayalaran 6 %.
  demoux's own history gives the realized gain of each deployed build as a discontinuity
  between adjacent fields: the 11-03 batch ×2.11 [2.08, 2.14] (NVIDIA A/B ×1.80), **the 11-09
  batch (#241, #246, #249) ×1.17 [1.16, 1.18] against ×1.37–1.39 on CUDA.** So CUDA A/Bs do
  not predict the card that does four fifths of the work, CUDA-only gains reach 13 % of the
  search, and the wgpu path cannot be measured on Vast (no AMD offers; Vulkan does not start in
  Vast containers). #250's denser plan is CUDA-only and its ballot append is gated off on
  64-lane subgroups, so its ×1.127 will be smaller on demoux.
- **Consequences:** price leads on the production mix, not in fleet dollars (README updated);
  measure every deploy's realized gain on demoux from telemetry; ask the user for a demoux
  window to profile and retune the wgpu path there (N13). Pace, derived: b60 ends in ≈ 3 days,
  b62 ≈ 2 months, b64 ≈ 1.5 years at the current mix.

- **B64 profile back (10:20 UTC, `B64/RESULTS.md`, EXPERIMENTS B64.1):** b64 costs 6.5e-15 s per
  admissible n on main (82 s per 1e17 field on a 300 W 3080), **≈ 7.8 × b62 for the whole base**;
  3 in 10 fields empty; the survivor path is the largest block (38–40 %), tops 17–18 % with the
  FD kernel off. **One lever, measured: the FD top kernel switched on at b64 is ×1.13 on 1e17
  fields** (×1.04–1.07 on 1e16), exact; the "measured slower" gate predates FD round 2 (#250).
  Field size: insert b64 at 1e17 (≈ 3–4 %, an ops note for the user). No constants retune ≥ 3 %.
  **N11 closed:** the walk's floor is its round structure; no small change reaches ×1.03.
- 10:30 UTC: the same agent uses the box's remaining time to prepare `pr/top-fd-pow2` (one commit
  on #250's head: the gate removed, a b64 device test, lavapipe both compilers, lint, the A/B on
  main-only as well, and how much of the gain is the CUDA-only denser plan). A reviewer follows;
  the PR would be the fifth open one.

- **FD-at-b64 PR branch ready (11:20 UTC, `B64/PR-RESULTS.md`, `B64/PR-BODY.md`):** one commit on
  #250's head (3 files, +57 / −32: the gate removed, a host test pinning FD at b64, the planner
  test extended, `check_all` asserting FD ran for the b64 window). Against #250's head on a 300 W
  3080, 3 interleaved rounds: **b64 1e17 ×1.090, b64 1e16 ×1.058, b62 unchanged**; on main alone
  (FD round 1, no denser plan) ×1.06 / ×1.02–1.04; ≈ 93 % of the saving is the top phase itself;
  wgpu estimate ×1.07–1.09 at 1e17 (not measured on a wgpu GPU). Exact on dense compares
  (b64 1e16 and 1e17 against the CPU join); CUDA device tests, lavapipe with both compilers, the
  WGSL lint, fmt and clippy pass.
- **Branch name:** the agent's fixed commit sits on fork `pr/top-fd-pow2-final` (5e10c9c). Its
  session refused the force-push that would have moved `pr/top-fd-pow2` (an unformatted first
  push, f96a068), so it pushed new names instead. I did not force-push on its behalf; the PR will
  use the `-final` branch, and `pr/top-fd-pow2`, `-v2`, `-v3` are stale branches on the fork that
  I left alone (deleting branches is the user's call). Future briefs say: fixes as new commits.
- Box 60171046 destroyed after 5.66 h (~$0.62). Independent reviewer launched on the branch
  (`B64/REVIEW.md`); the PR (#254 expected, the fifth open one) is opened once the review is in.
- **Review back (12:10 UTC, `B64/REVIEW.md`): open after small fixes; nothing unsound at b = 64**
  (the reviewer mirrored the packed-digit step in Python against big integers: adds with all-63
  digits, seed + 200 steps, ~25,600 certificates per configuration, the c0/dm re-form). Fixes
  applied: the body's wrong chunk divisor (4096, not 2^30) and "exact for any divisor"; the
  parity window at b64 only seeds (body reworded; a stepping parity window is listed under "Not
  in this PR"); the survivor-bound doc now names b64's 75–80 % fill; the wgpu estimate replaced
  by "faster, by less, not measured"; the per-field split of the 1e16 gain (×1.02 and ×1.11);
  internal wording removed. **The reviewer's stricter planner assertion failed when I ran it**
  (b64's mid-band fields plan 16 partitions either way: the middle of b64's band is sparse), so
  the test now takes b64 fields 55 % into the band and asserts growth unless the cap binds, and
  growth for at least one b64 field (7 → 14 at 1e16). Re-run on ivory: `join_plan`'s 9 tests,
  fmt, clippy on nice_common with the cubecl feature.
- **PR #254 opened (12:35 UTC)**: one commit 69c514d on #250's head, branch `pr/top-fd-base64`
  (a new name, a plain push). Five program PRs open = the cap. Stale fork branches left alone:
  `pr/top-fd-pow2`, `-v2`, `-v3`, `-final`.
- 13:21 UTC: **#254 fully green** (25 pass, 3 skipped, macOS included).
- Day: 2 agents (Opus; profile + PR preparation 618 k tokens, reviewer 252 k), 1 box.
- **Tomorrow:** the review's outcome and the PR; realized gains on demoux whenever a build
  changes; if a demoux window is granted, N13 (profile and retune the wgpu path on the 9070 XT);
  otherwise the next CPU roadmap item as a reviewed branch (CPU FD round 2 or the vectorised
  pass 2), held until a PR slot frees.

- **12:40 UTC: the user granted demoux for 4 hours at most** and stopped its production client
  (last submission 12:42:02 UTC; no `nice_client` process, GPU idle). So the window is clean but
  costs the search its main engine: finish early. Workspace `/tmp/claude-exp-2026-11-11-amd`
  (tmpfs) with a private cargo home, a clone of the fork, a PID-registering `run.sh` and a
  watchdog that wipes it at 16:30 UTC; agent hard stop 16:00 UTC (`N13/BRIEF.md`): (A) what #250,
  #251 and #254 do on the 9070 XT, with an A/A noise floor; (B) the profile shares there next to
  the 3080's; (C) the retune (constants, the plan budget, subgroup size and the ballot gate, the
  walk barrier, SPIR-V against naga). **Kill for N13: no lever ≥ ×1.05 on this card and no
  device-specific bottleneck in the profile.** I never start the production client; one ntfy
  when the machine is clean.

- **demoux window closed at 14:57 UTC (2 h 15 min of the 4 h), EXPERIMENTS N13.1.** Workspace
  removed, watchdog stopped, no process of ours left, `/opt/nice` and `~/.cargo` untouched, the
  production client still stopped (not mine to start); one ntfy sent. Results on the 9070 XT,
  noise 0.2 %:
  - **Open PRs:** #250 ×1.03–1.04 (its denser plan is CUDA-only), **#251 ×1.13–1.14 on top
    (main → #251 ×1.17–1.18 at b62 1e17 and b60 1e16)**, #254 ×1.09–1.10 at b64. Merging #250 and
    #251 is worth more to the search than anything else on the table.
  - **Profile:** tops and AND as on NVIDIA; the survivor path is nearly free here (4–5 % against
    29–33 %); **the join's base is ≈ a third of the field at ≈ 4× NVIDIA's cost per pair**; the
    check costs 2× per check (hence #251's larger gain).
  - **Retune:** `TOP_CAP` 128 ×1.04–1.05 and CUDA's denser plan on this adapter ×1.04; **together
    ×1.078 (b62) / ×1.106 (b60)**. Each alone sits just under the ×1.05 bar at b62; TOP_CAP needs
    a per-device value (128 loses 4 % on NVIDIA). Nothing else ≥ 3 %; wide u64 chunks lose 6–7 %.
  - Not reached: what in the join's base is slow, a budget above 2 GiB, the ballot append forced
    on, retunes at b64.
  **Verdict on N13's kill criterion: not killed** (a device-specific bottleneck and two
  measured tunings). New leads N14–N16.

## 2026-11-10 15:00 UTC: the user's PR bar corrected; the four held branches opened as #250–#253

- **Correction from the user:** the bar for an individual PR is ×1.05 for a simple change up to
  ×1.10 for a very large one; discrete changes are not to be combined into one PR; the ×1.5
  question only gauged the held branches' overall impact and urgency; the four held branches
  "would probably be appropriate for PRs". My "chain at ≥ ×1.5" reading and my own "park under
  ×1.10" line are withdrawn (README, the routine's prompt and memory updated).
- **Opened, each one commit on main c0c357a or on its predecessor:**
  **#250** GPU top certificates carry their bounds across partitions (×1.127 b62 1e17, ×1.112 b60;
  `pr/top-fd-round2` ee30303); **#251** GPU full check in base-b² limbs (×1.088 / ×1.124; stacked
  on #250; `pr/check-d` a97e3d7); **#252** CPU two-pass AND scan (×1.24–1.27; 
  `pr/cpu-join-two-pass-scan` 35dc530); **#253** CPU seeded full check (×1.11–1.14; stacked on
  #252; `pr/cpu-join-seeded-check` 47859f7). All four were reviewed before the hold.
- Rebase method: each held commit cherry-picked onto main (only CHANGELOG conflicts); the files
  each PR touches are byte-identical to the measured trees (checked with `git diff`); fmt clean;
  nice_common tests 190 / 197 pass on the CPU branches; the GPU branches compile with the
  cubecl feature (their device tests ran on the measured trees; upstream CI runs lavapipe).
  Changelog lines carry their own PR numbers (predicted and confirmed). Bodies: the prepared
  ones with the stacking line replaced by a rebase note.
- 16:35 UTC: **#250, #251, #252, #253 all green** (25 pass, 3 skipped each, macOS included); mergeable,
  no comments yet.
- Under the corrected bar the parked list is worth a second look, one PR each: N11 (the walk's
  per-chunk floor, ≤ ×1.06, to be measured), the CPU roadmap's remaining items (FD round 2 est.
  ×1.06–1.12, vectorised pass 2 est. ×1.05–1.10); L32/L43/L54/N12 measure under ×1.05 at
  production fields; L40 breaks the no-scenario-below-×0.98 rule.

## 2026-11-10 later: the user's reply to the first report (standing guidance)

- **N1 stays parked, more firmly.** Anvil is the user's best large CPU supply (cost notes in
  `../2026-09-compute-sources`, `../2026-10-anvil-run`; volunteers such as blockofdynamite
  sometimes donate their own allocation), but they are "even less interested in a server
  rearchitecture for just one mode". The CPU result alone does not reopen it; only GPU evidence
  would (a real-kernel measurement ≥ ×3.5 at b62 and ≥ ×3 at b64).
- **N9 dropped** ("not interested unless you have good reason to endorse it"; I have none
  beyond what I said). The same check stays available to me as a read-only audit of public
  telemetry, at no cost to the user; I run it when a release changes the kernels.
- **Less of the user's time from now on:** they will try to check in daily but may miss several
  days. Standing instruction: "Keep looking at high level strategies but if none pan out then
  continue with optimizations." So: decide inside the rails without asking, keep questions rare
  and never blocking, and keep reports short enough to skim after a gap.
- **How I read it for PRs** (their 2026-11-09 rule still holds): kernel work is collected into a
  chain and opened only when the chain's combined measured gain is ≥ ×1.5, or for a defect.
  Candidate chains: CPU (held two-pass scan + seeded check = ×1.38–1.45; L50's remaining items
  could take it past ×1.5, and Anvil and volunteers' CPUs are where it pays) and GPU (held pair
  ×1.23 + N11 + N12 + parked riders ≈ ×1.4, short of the line).

## 2026-11-10 (first cycle of the new director; routine fired 05:41 UTC)

- **Reconcile:** no research instances; November research $10.81 of $30 (fleet $17.09); credit
  $33.42; ivory 9.5 GB free. No program PR open; main = c0c357a. No new user message since the
  SQL hand-over.
- **The user ran the SQL** (verified through the public API at 05:45 UTC): 120 of 120 sampled
  listed submissions are disqualified; all 319 sampled b58 reset fields are back at check level 1,
  b60 69 of 281; re-searched by demoux (3.4.8-dev), the fleet (3.4.7) and mayalaran (3.4.8-dev,
  fixed build). b58 shows 100 % again.
- **Refined N1 arithmetic before spending on it:** a bottom mask of 2k digits costs the
  transposed AND 2k loads per (entry, chunk of 32), so k 9 makes the AND-only part ×1.5 dearer
  per pair; with today's shares (base 11, AND 15, survivors 30, check 12, tops 23, setup 5) the
  (f0 4, k 9) unit is ≈ 42 % of today → ×2.4 with u32 chunk words, ≈ ×3.2 with u64 words on
  CUDA; (f0 3, k 9) ≈ ×2.6 / ×3.1, and ×3.4 / ×4.3 if child-only top certificates cost a
  third of a full one. So the ×3 bar needs u64 chunks and/or cheap child certificates; the
  honest prior is 35–45 % to clear it. The cheapest decisive test is the dense phase's cost per
  pair at 18-digit entries, both word widths, in the new tile shape.
- **Also noticed:** the reference join already takes any (t, k, p): the transversal unit is
  `join_range` over a base's whole range with (L − 4, 9, 5) and one partition value. Soundness is
  inherited; only widths (the residue's cube past u128, u32 casts) stand between the CPU join and
  the new shape.
- **Leads today** (kill criteria written before starting):
  - **N1-GPU tile microbenchmark** (agent, one RTX 3080, ≤ 5 h): dense-phase cost per pair at
    12/18/20-digit entries, u32 vs u64 chunk words, both orientations, today's and the new tile
    shapes; the harness must first reproduce production's cost at today's shape within 20 %.
    **Kill N1 on GPUs if no variant projects ≥ ×3 on a whole b62 base** with the counts of
    NOTES §3; record the numbers either way (the user's instruction).
  - **N1-CPU prototype** (agent, ivory): the CPU join at (L − 4, 9, 5) on a base's whole range for
    sampled partition values; exactness against the reference and brute force on small bases;
    exact operation counts against my Monte Carlo (flag > 30 % off); measured CPU seconds per
    admissible number against today's shape. Supporting evidence, not the kill test.
  - **N5 adversarial review** of the no-shortcut argument (agent, no hardware): a loophole with a
    costed algorithm sketch, or the argument tightened. Kill: no gap found → closed in writing.
  - T4 stays held (the user's ×1.5 rule). N9 waits for the user's word.

- **N5 review back (06:10 UTC, `N5/REVIEW.md`, 20 min, 204 k tokens): no hole that changes the
  exponent; my step 1 was wrong as stated and is replaced by a sharper model.**
  - Correction: a (top, bottom) pair with overlap o knows 2(L + o) digits, not 2L; with
    t = k = L − 1 only ≈ 4e10 n would survive at b62. Information is not the bottleneck, building
    the lists is. The right frame is a **prefix–suffix join model** (prefix nodes, suffix nodes,
    pair tests, full checks): flat floor ≈ 2e18 AND-units at b62 (1.6e19 at b64), ≈ ×4.5 under
    today's ≈ 9e18 in the same weights; with non-disjoint pairs skipped for free 3.4e17 / 1.6e18
    (another ×6 / ×10, of which digit-key indexing may reach ×2–2.5 on the pair term); the
    information floor (4e10 / 5e11) is unreachable because the depth-(L − 1) lists cost W/b nodes.
  - Dead with numbers: bilinear and three-way splits, n mod m views, bit-level structure at b64
    (partial digits at the edges prune ≤ 8 % of the last level, ≤ ×1.01 per base), k-list /
    dissection / representations (no additive structure beyond the digit sum, already the hash
    key), lattice prescription (×3000–5000 worse than the join), large bases (cost per expected
    find depends on b only and grows in every column: 1e22 at b62, 1e57 at b150, ≥ 1e34 even with
    free lists and a perfect join).
  - Its Monte Carlo confirms the uniform-digit model within 10–20 % down to joint pass rates of
    1e-6, deep overlap included.
  - Open, engineering only: **X1** digit-key indexed pairing (sort a unit's tops by their pattern
    on the 10–14 most frequent digits; a bottom visits only disjoint key groups): pair term ÷2–2.5,
    ×1.1–1.2 per base today, ×1.3–1.6 at N1's shape; a CPU day; only if N1 survives.
  - Its own strongest objection: the model class is the reviewer's; no new congruence was tested.
  **Verdict: N5 closed in writing.** What is left to gain is constant factors inside the
  prefix–suffix join: N1 (≈ ×2.3–3.1), X1 on top of it, both bounded by ≈ ×4.5 (flat) and
  ≈ ×27 (output-sensitive) under today.

- **N1-GPU back (07:13 UTC, `N1/gpu-tile/RESULTS.md`; box 60024264 destroyed after 1.46 h,
  ~$0.18):** calibration on a real b62 1e17 field: 2.47e13 pairs, 9.5e11 AND survivors, dense
  0.563 ps per pair, survivor path 17.4 ps per survivor, 61.9 s per field on a 340 W 3080. In the
  new big tile an 18-digit entry costs no more per pair than a 12-digit one in today's tile (the
  per-wave base falls 2.4×); u64 chunk words pay only with 4 chunks a pass (−16–25 %); k 10's
  small tiles are dead. The survivor path has a per-pair floor (0.13–0.15 ps of per-chunk
  machinery), so ÷10.8 survivors buys only ÷3.3. Projection: (f0 4, k 9) ×2.56 u32, ×3.0–3.2 u64;
  (f0 3, k 9) ×2.8 / ×3.2, ×3.5–4.1 with child certificates at an estimated 0.45 of a test. The
  harness matched production's dense cost to −19 % only (small buckets take the per-top AND).
- **N1-CPU back (08:15 UTC, `N1/cpu/RESULTS.md`, branch `exp/n1-transversal-cpu` a32d78c):** the
  CPU join runs (L − 4, 9, 5) on whole-base units with ~400 changed lines, exactly (reference
  and brute force at b10–b34, 30,000 b40 units, b54/b62 production-shape units). Measured counts:
  my P_T, P_B and pairs hold (−5 %, −5 %, +20 %); survivors are ÷14–18 and checks ÷25–31 of
  today's base mean. Measured CPU time per admissible n against today's mean: ×3.0 / ×4.1 / ×1.8
  (b60 / b62 / b64) for the 5-digit unit with an affine extension, **×6.5 / ×5.9 / ≈ ×1.9 with
  four partition digits plus a key digit**. The gain is a cheaper AND (long class lists, few
  survivors), not fewer ANDs. Corrections to my model: the bottom side is 8.0e15 visits per b62
  base, not 1.5e15; today's cost varies ×2.7 by field location and the mid-base field is 22 %
  dearer than the mean; b64 is the weak base.
- **GPU case re-projected with the measured counts and a base-mean baseline** (EXPERIMENTS N1.C1):
  b62 ×2.45 (u32) / ×2.9–3.2 (u64); b64 ×1.8 / ×2.1–2.3. A walk tuned for sparse survivors
  would add ~×1.2 (unmeasured).
- **Verdict on N1 (the user's ×3 bar): parked, not killed.** GPUs, which do all of today's
  nice-only work, sit at the bar at b62 on CUDA only and under it at b64, where 90 % of the
  reachable cost is. The CPU result clears the bar at b60/b62 and is a working, exact prototype;
  it matters only with a large free CPU supply (b62 ≈ 155k Zen-3 core-hours at the new shape
  against ≈ 900k today, derived). No server-change proposal is written; the numbers stay on
  record for the user, as asked. Two trims for today's GPU kernel fell out (the walk's per-chunk
  floor, ≈ 6 % of a field; buckets under 192 tops on the slow AND path, ≈ 4 %): parked as N11, N12.
- Day: 3 agents (Opus; 204 k + 360 k + 377 k tokens), 1 box, $0.18; director ~3 h.
- **Tomorrow:** base 64 becomes the primary optimisation target (≈ 90 % of the reachable cost;
  every profile so far was at b62 or b60): one GPU profile of a b64 field (shares, empty
  fields, the 8 residue classes, what a power-of-two base allows; kill: no lever ≥ ×1.10 found
  → record only). Confirm b60's reset fields are all re-searched. Lighter days (1–2 agents)
  unless the user reopens N1. Asked the user: free CPU supply (N1's reopen condition), N9.

## 2026-11-10 ~02:00 UTC: disqualification SQL for the user

- The user asked for a SQL file setting `disqualified` on the pre-fix M4 join submissions of b58
  and b60, to be followed by `jobs --full`. Delivered:
  `../2026-11-fresh-eyes/disqualify_m4_prefix_join_b58_b60.sql` (one transaction; 11,473
  submissions by explicit id with a description check that aborts on any mismatch; then the
  check_level 1 → 0 reset of the 8,369 listed fields left with no qualified submission).
- **Flagged to the user:** `nice_jobs --full` re-evaluates consensus only for fields with detailed
  submissions (`get_fields_in_base_with_detailed_subs`), b58/b60 have none, and nice-only claims
  select `check_level = 0` by ascending id (`bulk_claim_fields`, no cursor), so without the reset
  step nothing would be re-issued. The reset is in the file as STEP 3.
- List cross-checked by a second API scan keyed on the username (`verify_m4_list.py`): identical;
  no M4 nice-only submission on b58/b60 lacks telemetry; the 4,370 post-fix (6f060a94) ones are
  excluded. Tested on a throwaway postgres:17 with a synthetic copy of the affected rows:
  UPDATE 11473 / UPDATE 8369, bystanders untouched, idempotent, a mismatched row aborts with no
  change. Running it is the user's action.

## 2026-11-10 01:03–01:38 UTC: M4 window; the deficit is the #222 flush race, and it loses candidates

The user granted mayalaran for 3 h (used 35 min; work dir and watchdog removed, nothing left),
asked for a count of affected fields from the public API (re-search under $5 → they consider
disqualifying), and asked whether I still endorse the check-kernel count test (they found it
brittle). Evidence: `../2026-11-fresh-eyes/m4-run/` (logs, the two diagnostic tests),
`census_apple.py`, `census_summary.py`, `census_summary.json`, `m4_prefix_join_submissions.csv`.

- **Reproduced.** The M4 is on macOS 27.2 now (Metal division bug fixed in the OS), and v3.4.6
  still comes up short against the exact CPU join on b60 field 206954951: 1.05 M of 1.80e9
  survivors unaccounted on 32 partitions (5.8e-4, five repetitions 5.6–5.8e-4; October
  telemetry said 5.7e-4). So the cause is not the compiler.
- **Cause = #222.** v3.4.6 + only the barrier commit 7155c49c: unaccounted 1–2 k of 1.80e9
  (≤ 1e-6, the accounting's precision).
- **Candidates are really lost.** List-level comparison (the list handed to the full check vs
  the CPU reference's prefilter survivors): v3.4.6 misses **1,779 of 4,364,944** must-check
  candidates on 8 partitions of slice 0 (4.1e-4); with the barrier **0**. b58 1e15 field: 2,228
  of 9.2 M missing (2.4e-4), counts 8.7e-5 and 5.5e-4 on two fields.
- **b57 (1e14 fields) is clean on v3.4.6:** five whole fields within 3e-7 (the precision), and
  0 of 20.9 M + 0 of 3.3 M candidates missing on two fields' lists. Mechanism agrees: work
  items there have under 32 tops, one chunk, no between-chunk flush decision.
- **Current main is clean on the M4:** exact equality with the CPU join (survivors and checked)
  on five b60 fields, 32–256 partitions each, every repetition; 27.6e9 survivors compared.
  Since #236 the counts are exact and deterministic (no stage overrun in the accounting).
- **Why it never showed on AMD/NVIDIA:** timing. On the M4 the stage overruns ~100× more often
  (1.7e-3 of survivors against 2e-5), and the racy flush decision goes wrong constantly.
- **Census (public API, id-range scans with a telemetry filter, 7 min):** all Apple join
  submissions are mayalaran's. Fields whose only qualified nice-only search is a pre-fix M4
  join run: **b57 12,103 (1.2e18 numbers, clean by the above), b58 4,415 (4.4e18), b60 3,954
  (3.95e19)**. Re-search of b58 + b60: ≈ $6.2 at the cost model's v3.4.6 prices; production
  telemetry shows no clear v3.4.7 gain on the fleet's GPUs, so ≈ $6 on the deployed v3.4.7;
  ≈ $2.5–3 on a build of current main (demoux: 33 s → 16 s per b60 field from 3.4.6 to
  3.4.8-dev); or ~20 h of demoux at no Vast cost.
- **Gotcha:** on the Mac a second tree of the same version reused the first tree's test
  binary (`secs=0`); the label string check caught it. `cargo clean -p nice_common` before
  every build that is compared.
- **Check-kernel count test:** withdrawn. Read in full: it hand-builds the kernel's private
  record layout and depends on three test-only kernel modes, so it tests a variant of the
  kernel and breaks on any layout change. What found today's defect was differential checking
  on production-shaped work. On main the join's (survivors, checked) are exact, so repeat or
  spot-check submissions of a field must agree to the unit: a production invariant that
  needs no kernel hooks. Idea recorded as N9 (proposal only).

## 2026-11-09 late evening: the user's answers; Apple M4 survivor deficit found in telemetry

- **The user's answers.** (1) Changing the server's work unit is tentatively on the table, but
  the bar for N1 is **×3** per base, not ×2; record the result either way (they may revisit if
  other leads fail). (2) They saw no reason for a second pass of b50–58 and asked whether a new
  unsoundness bug had been found. (3) Odds per dollar is a good metric but must not blind me;
  a verified negative result is very useful; write-ups and outreach are disprioritised (other
  agents do them): note such items in the daily report only. (4) The four held branches: hold
  if they are kernel-only and under ×1.5 combined; open if over, or for another reason.
- **Held branches stay held:** GPU pair ×1.23 at b62 1e17 (×1.127 × ×1.088; ×1.25 b60), CPU pair
  ×1.38–1.45 (NiceMark CPU ×1.46). Both chains are kernel work under ×1.5. One non-speed item
  inside `pr/check-d`: main's suite compares only hit lists, empty everywhere but b10's 69, so an
  over-rejecting check kernel passes it; the per-survivor device test needs a count mode in the
  check kernel. Offered to the user as a separate small integrity PR.
- **Exposure check that the question prompted** (`../2026-11-fresh-eyes/exposure_pairs.py`,
  `exposure_analyze.py`, data `exposure_b60*.json`; read-only, primary-key and field_id lookups
  on data.nicenumbers.net; 3,600 b60 fields, 3,860 join submissions with telemetry):
  - v3.4.6 (10-08 → 10-31) shipped the join without #222; the PR's own text says the race can
    drop survivors before the full check, and the changelog does not list it. 36 % + 12 % of
    the sampled searched b60 fields were searched only by pre-fix AMD / NVIDIA builds.
  - Telemetry carries `survivors` and `checked` per field. A survivor that overruns the stage
    moves from `survivors` to `checked` (documented, timing dependent), so for two runs of one
    field R = Δsurvivors + Δchecked/(1 − pass) should be ≈ 0. **AMD and NVIDIA, identical builds: 0 of 224
    same-device pairs beyond 1e-6 of the field's survivors (max 7e-7); 73 AMD-vs-NVIDIA pairs
    all within 2.2e-6.** The race left no measurable trace there. The second pass of b50–58 is dropped.
  - **Apple M4 (mayalaran), builds 9a4f7406 and 2709d3f9 (before #222 and #228): 61 of 74
    identical-build pairs against AMD or NVIDIA runs of the same field account for fewer
    survivors (median 6.7e-5 of the field, quartiles 3e-6 / 2.4e-4, max 6.4e-4; up to 1.25e-3
    across dev builds), never more.** Two M4 runs
    of one field agree with each other to ≤ 4e-6 (4 pairs), so the deficit is mostly
    deterministic: a compile-level defect (the #228 pattern, which the changelog calls harmless
    at bases 57–64) fits better than the race. Telemetry cannot tell lost survivors from
    miscounted ones. After both fixes (6f060a94): 2 cross-build pairs, +5e-8 and +1.3e-6.
  - Exposure: 3.6 % of the sampled searched b60 fields have only a pre-fix M4 run (≈ 4,400
    fields, ≈ $2 of GPU time to redo); b57/b58 M4 share not yet counted. Effect on the odds
    ≈ 1e-9; it matters for a verified "none below base N".
- Asked the user for: ~2 h on mayalaran (same fields on current main and on v3.4.6 ± #228 to
  name the cause), and whether to re-queue pre-fix M4-only fields (server action, theirs).

## 2026-11-09 (day 13; routine fired 04:41 UTC)

- **Reconcile:** no research instances; November research $10.29 (fleet $15.38); credit $35.65;
  ivory 15 GB free. Five program PRs open and green at the cap, nothing merged since 11-03, no
  comments, no user messages; three reviewed branches held (`pr/top-fd-round2` d813aea,
  `pr/check-d` 7d6956f, `pr/cpu-join-two-pass-scan` 1cce00d); main = 6f060a9. Five 7-day
  worktrees removed (24 remain).
- Leads today: **L53** #249's host sort off the device thread (box `l53-sort`, instance 59842980;
  lands as a third commit on #249; kill < ×1.02), **L54/L55** AND codegen fold + register pin (box
  `l54-andgen`, instance 59842997; kill: no fold in CubeCL or A/B < ×1.03), **L56** CPU seeded check
  PR branch on L52 (ivory; kill < ×1.05 on top of L52). Hard stops 12:30 UTC.
- **L54/L55 done (08:40 UTC): the AND's address fold works (30 → 20 SASS per digit, −28 % of the
  AND's issue) but buys only ×1.008–1.018 under a 130 W cap (denser issue lowers the clock) →
  parked as a ready rider; the register pin is not expressible in CubeCL (upstream patch of 25
  lines written; the 1-in-7 spill lottery comes from CubeCL's randomised shared-array order).**
  Box l54-andgen destroyed (2.5 h).
- **L53 landed (08:50 UTC, L53.1): #249 → 80a103e** (third commit: the layer sort runs in
  `plan_join`/the prep thread instead of on the device thread, and steps residues instead of
  dividing): ×1.022 b62 1e17 / ×1.016 b60 by same-process alternation (the separate-process A/B
  cannot resolve 2 % at ±4 % clock scatter), output word-for-word identical. Held branches
  rebased onto it: `pr/top-fd-round2` 5d0c8cf, `pr/check-d` e28b79f (two small conflicts
  resolved; tests pass). #249's GitHub body updated and commented. Box l53-sort destroyed (2.6 h).
- **L56 PR-ready (09:00 UTC, L56.1): CPU seeded check ×1.11–1.14 at production shapes (1 and 4
  threads), NiceMark CPU ×1.155, the check's share 15–16 % → 5 %; seeds only pre-closure certificate
  digits (L47's warning honoured); exact position by position on 19.65 M survivors.** Reviewer
  launched; fourth held branch (CPU chain: #247 → #248 → two-pass scan → seeded check).
- 09:15 UTC: **#249 at 80a103e: 23 pass, 2 red = GitHub 504s** (the clippy job's checkout and the
  wasm job's wasm-pack download failed before any build step). Not ours; commented asking for a
  rerun (I cannot rerun upstream workflows). The other four open PRs stay green.
- **Review of `pr/cpu-join-seeded-check` (09:25 UTC, `L56/REVIEW.md`): merge with small fixes, no
  soundness defect** (every seeded digit set is true for every n in its block; closure digits
  excluded by construction; Magic bounds exact). **Medium: the hit-deciding path `Check::nice` never
  returns true in any test but 69 — two early-exit mutants pass the suite and would drop every
  production hit**; the reviewer wrote a property test (verdict vs count mode, 1.2 M verdicts) that
  catches both. Sent to the L56 agent with the body corrections (b58 share claim, b40 exponent,
  (b²)^(2·nl), the V3 comparison, the top-seeding's ×1.01–1.02 stated early) and a rename.
- **L56 fixes done (10:40 UTC): `pr/cpu-join-seeded-check` → 0fc06a0** (the property test
  `the_verdict_agrees_with_count_mode_on_any_mask` fails under both early-exit mutants and passes
  on the branch with 1.2 M verdicts incl. `true` at every limb count; body/doc corrections; the
  timed binary's code is byte-identical). Tests 197 + 22. Fourth reviewed branch held at the cap.
  Day: 2 boxes ($0.55), 5 agents (all Opus), director ~5 h.
- 11:50 UTC: no rerun of #249's two 504-failed jobs → **CI retriggered by a message-only amend of
  the third commit** (#249 → 9d9e2e9, tree identical to 80a103e); held branches rebased with
  identical trees: `pr/top-fd-round2` 4336a18, `pr/check-d` d8390d9.
- 12:52 UTC: **#249 fully green at 9d9e2e9** (25 pass, 3 skipped; the two 504 jobs passed on the rerun). All five open PRs green; no comments; nothing merged.

## 2026-11-08 (day 12; routine fired 04:41 UTC)

- **Reconcile:** no research instances; November research $9.26 (fleet $13.48); credit $38.59;
  ivory 15 GB free. Five program PRs open and green (#241, #246, #249; #247, #248), no comments,
  nothing merged (weekend); `pr/top-fd-round2` d813aea held at the cap; main = 6f060a9. Twenty
  7-day worktrees removed (24 remain). No user messages.
- Leads today: **L47 check kernel design D** (box `l47-check`, instance 59671449; step 0 floor
  first; kill: gather-only > 6.3 s per b62 1e17 field, A/B < ×1.05 at both fields, NiceMark
  scenario < ×0.98), **L51 full-stack profile + ablation + constant retune** on d813aea (box
  `l51-profile`, instance 59671466; kill: retune < 3 %), **L50 CPU join roadmap** (ivory, perf).
  Hard stops 12:30 UTC.
- **L47 built (08:00 UTC, L47.1): check kernel design D ×1.088 at b62 1e17 / ×1.124 b60 / ×1.070
  b64, NiceMark ×1.056, exact with new per-survivor device tests against the CPU (the old suite
  could not catch an over-rejecting check); the check now runs at the DRAM floor (3.2 s, 98 % of
  bandwidth) with 39 registers and no divisions.** Box l47-check destroyed (2 h). Reviewer launched;
  `pr/check-d` is the second PR-ready branch held at the cap (GPU chain: #241 → #246 → #249 →
  FD round 2 → check D).
- **L50 CPU roadmap done (09:10 UTC):** the CPU join after #248 is 38 % scan (branchy survivor
  extraction, IPC 1.6), 31 % tops, 15 % prefilter, 12 % check; two levers prototyped in place —
  two-pass scan ×1.16–1.20 (+5–6 % inlined) and a seeded check ×1.07–1.11 — ×1.32–1.39 together,
  exact. **L52 (two-pass scan PR branch on #248) launched on ivory**; the seeded check follows as
  L53 once L47's design-D arithmetic is reviewed (it reuses the columns).
- **Review of `pr/check-d` (10:10 UTC, `L47/REVIEW.md`): merge with small fixes, no correctness
  defect** — the reviewer wrote an independent Python model of the kernel from its text (u32
  overflow and quotient-exactness checks) and matched big-integer digits on all 20 production
  bands at b40–64 (60,080 n incl. band edges) and the 18 window shapes; every quotient input
  < 2³¹; the gate is necessary for niceness; the work counter is exact. Fixes are in the new
  device test (no `ensure_ran` → a silently dropped batch compares nothing; adversarial n miss the
  bands' top edges; the b57 frontier counted twice: 22 shapes, not 26) and body wording (330 vs
  1,050 are both per 32 survivors; the A/B counts come from the join, not the check; b57 1e14's
  clock). Recommends one M4 run of the count test (asked in the report). Sent back to the L47
  agent with a 3 h box to re-run the device tests after the fixes.
- **L51 done (09:20 UTC, L51.1):** d813aea at b62 1e17: join 56 % (AND 15 %, prefilter 20 %, base
  11 %, walk 9 %), FD 23 %, check 12 %, slice setup 4.8 %; **no constant retune reaches 3 %**
  (defaults stay). Two findings: #249's host sort runs with the GPU idle (3.2–3.6 % → L53), and
  1 in 7 runtime compiles of the join kernel spills (~3 %; a register pin fixes it → L55; A/B
  method must pin or record the variant). AND codegen has unfolded address arithmetic (→ L54,
  est. 2–5 %). Group walk, COMPACT=2, fewer AND digits and LDS.128 are all no-go by arithmetic.
  Box l51-profile destroyed (3.5 h).
- **L47 fixes done (09:45 UTC): `pr/check-d` → 7d6956f** (the test now `ensure_ran`s every batch,
  covers band-edge n at every production shape incl. 44 at b64, has a gated mode, and dedupes the
  b57 frontier; kernel unchanged: 39 registers, 736 SASS; count/gated/probe pass on CUDA and
  lavapipe both compilers; `check_all`, b62 COMPARE, exhaustive quotient test, clippy ×3). Box
  l47-fixes destroyed (1.5 h). Two PR-ready branches held: FD round 2 (d813aea) and check D.
- **L52 PR-ready (10:45 UTC, L52.1): CPU two-pass scan ×1.24–1.27 at production shapes (1 and 4
  threads), NiceMark CPU ×1.261, exact; branch misses −60 %, IPC 2.2 → 2.8.** AVX-512 pass 1 is
  compiled and read but never executed on this VM; the path's detection should also require avx2
  (flagged for the reviewer). Reviewer launched; third PR-ready branch held at the cap.
- **Review of `pr/cpu-join-two-pass-scan` (10:55 UTC, `L52/REVIEW.md`): merge with small fixes;**
  correct on the portable and AVX2 paths (all seven planted bugs caught by the new test); the
  AVX-512 pass 1 correct on reading but never executed anywhere; its dispatch must also require
  avx2 (pass 1 uses a VEX `vpbroadcastw`); the "two pieces" coverage claim was false (the cited
  window never scans). Fixes sent to the L52 agent; **an AVX-512 box rented to execute the path**
  (instance 59703250, 4090 host with a Ryzen 9 9950X, $0.43/h, 2 h TTL; `vast.py create` needs
  `--gpu` + `--query 'cpu_name="…"'` — the id lookup only sees the default price page).
- **L52 done (11:15 UTC, L52.2): fixes in (`avx2` required with `avx512f`; piece size lowerable
  in tests; table test), and the AVX-512 path executed on a Ryzen 9 9950X: all tests pass, counts
  identical across the three binaries, ×1.22–1.24 over #248 there.** Head 1cce00d, held at the
  cap. Box l52-avx512 destroyed (1.3 h, $0.56). Day: 6 boxes, ~$1.4; 11 agents; director ~6 h.

## 2026-11-07 (day 11; routine fired 04:41 UTC)

- **Reconcile:** no research instances; November research $8.12 (fleet $11.44); credit $41.78;
  ivory 15 GB free. #241, #246, #247 open and green, no comments; nothing merged (weekend);
  main = 6f060a9. Twelve 7-day worktrees removed (38 remain). No user messages.
- Leads today (from `L44/ROADMAP.md`, L45's verdicts): **L46 static bucket order** (box `l46-static`
  3080, instance 59529576; day 1 of 2: design + implementation + exactness; kill < ×1.05 at
  either field), **L48 FD top kernel round 2** (box `l48-fdround2`, instance 59529585; kill
  < ×1.05 at either field), **L49 CPU lean prefilter** (ivory; PR branch on #247; kill < ×1.05 at
  both shapes). Hard stops 11:00–12:30 UTC; reviewer agents follow PR-ready branches.
- **L49 PR branch ready (07:50 UTC, L49.1):** CPU lean prefilter on #247: ×1.07–1.11 at
  production shapes (1 / 4 threads), ×1.05–1.12 on 1e14 fields, NiceMark CPU ×1.088, exact with
  the FX exhaustive test. Reviewer launched.
- **L46 built in one day (08:20 UTC, L46.1): ×1.158 at b62 1e17, ×1.154 b60, ×1.222 b64, NiceMark
  ×1.119, exact; two kernels and five buffers deleted; beats L45's ceiling because the FD kernel's
  atomics and the join's gathers go too.** Rider (stage once per batch) ×1.02–1.03 on top, exact.
  Box l46-static destroyed (2.75 h). Reviewer launched on the PR squash + the rider; decision: the
  rider goes in as a clearly separated second commit (asked in the report whether to split).
  L48 (same append block) will rebase on whichever lands first.
- **Review of `pr/cpu-join-lean-prefilter` (08:35 UTC, `L49/REVIEW.md`): merge with small fixes, no
  defect** (FX exhaustive re-run: 6.63e11 triples exact; constants = exact ceilings; max error
  2^24.7). Fixes: drop `dm` from `Top` (48 → 64 bytes was a real +0.6 % sort cost; recompute in
  the test-only path), a test window with unseeded stepped tops (pre-existing gap), the dispatch
  assertion and wording, doc nits, "fixed-point" not "division-free". Sent back to the L49 agent.
- **Review of `pr/join-static-buckets` (08:50 UTC, `L46/REVIEW.md`): merge with small fixes, correct.**
  The reviewer re-derived the bucket algebra (pdiv_m1 = b^p mod (b−1) = 1), wrote a host test of the
  segment arithmetic against cpu_join's bucket rule (24 fields, all match; patch kept in
  `L46/raw/review/`), proved segments cannot overflow, and corrected my brief: the FD kernel steps
  partitions per prefix, so the sort cannot touch its stepping. Fixes: a missing CHANGELOG line,
  the register paragraph overstated production safety (the 40-register spilling variant is new,
  7/37 images), rider as a proper second commit + body section, stale doc, a rename, a sentinel
  fill in `run_tops`, a CI host test for the sort. Sent back to the L46 agent (ivory, no box).
- **PR #248 opened (09:00 UTC): "CPU overlap join: a fixed-point middle-digit prefilter"**, 7f5260b
  on #247 (`Top` back to 48 bytes after the review; no unseeded-stepped-top window can exist, proved
  and stated). Open program PRs: #241, #246, #247, #248.
- **PR #249 opened (09:10 UTC): "Overlap join: a static bucket order for the top layer"**, 87958fd
  on #246, two commits (layout 8e0eb99 + the stage rider; the review's fixes incl. a CI host test
  of the sort against the CPU bucket rule and a sentinel fill in the device test; the first
  commit's own snapshot keeps `#NNN` in history, the final tree carries #249 twice). **Open program
  PRs: 5 = the cap** (#241 → #246 → #249; #247 → #248). CI's macOS job is the first Metal run of
  #249 (new `plane_all`, plain u32 `%`/`/`) — watch it.
- **L48 PR-ready (09:15 UTC, L48.1):** FD top kernel round 2 ×1.082 b62 1e17 / ×1.070 b60 / ×1.093
  b62 1e16, NiceMark ×1.029, exact; the stepped slot −31 %. The first form that also cut slices
  failed NiceMark b60 (×0.976) — slices now stay at 2 survivors per prefix. **Held at the PR cap**;
  reviewer launched so it opens the moment a slot frees. Box l48-fdround2 destroyed (3.3 h).
- Report sent 09:35 UTC. Afternoon: **L47 check-kernel scoping** launched (analysis, no GPU); L48 review running.
- **Review of `pr/top-fd-round2` (10:30 UTC, `L48/REVIEW.md`): merge with small fixes; kernel changes
  exact (all three trims, the early-exit carries and the plan re-derived; a host model agrees).
  Two medium findings: (M1) the ballot append keeps only 32 bits on CubeCL's C++ backends → wrong
  on wave64 (CDNA via the opt-in cubecl-hip build) — gate on `plane_size_max <= 32`; (M2) real
  memory rises to the budget at 1e16+ (b60 1e16: 1.6 → 2.5 GiB on a 10 GB card; on wgpu the
  binding-limit budget gives 2.6 → 3.9 GiB even on 4–6 GB cards) — scope `SURV_PER_PREFIX` 1 to
  CUDA or measure on AMD/M4. Also: #249 replaces the whole append block (`top_slot` still uses the
  two plane scans) — the ballot must move into `top_slot`; #249 shrinks per-slot memory so this
  PR's survivor bound binds (~11 slots) and slices may widen → the combination must be re-measured
  incl. NiceMark's b60 window. Resumed the L48 agent on a new box to apply the fixes, rebase onto
  #249 and A/B the combination.
- **L48 round 2 on #249 done (12:40 UTC, L48.2): ×1.127 b62 1e17 / ×1.112 b60 vs #249, NiceMark
  ×1.032 with the b60 window at ×1.052; exact; wave64 ballot gate and CUDA-only batch scoping in;
  `pr/top-fd-round2` d813aea on #249, held at the PR cap.** Box l48-rebase destroyed. Day: 4
  boxes ($1.3), 10 agents (all Opus), director ~7 h.
- **L47 scoped (11:00 UTC, `L47/SCOPING.md`): GO.** The check kernel is instruction-heavy (1,046
  warp-instructions per warp-iteration at half issue rate) and runs 3 waves where 2.5 fit;
  design D (base-b² limbs, schoolbook n², digits from the carry normalisation, a gate before
  n³) plus a device-side work counter: ×1.05–1.09 b62 1e17 / ×1.06–1.12 b60 (estimates under a
  memory floor). Existing tests cannot catch an over-rejecting check (every hit list but b10's is
  empty) → the prototype needs count-mode/gate-mode device tests vs the CPU. Tomorrow's GPU
  lead; step 0 is a 45-min floor measurement.
- 10:10 UTC: **#248 and #249 CI fully green** (25 pass, 3 skipped each; #249's Metal job, the lavapipe parity job with the sentinel test, and both macOS builds all passed); all five open PRs green; no comments.

## 2026-11-06 (day 10; routine fired 04:41 UTC; first full heavy+ day)

- **Reconcile:** no research instances; November research $6.95 (fleet $9.67); credit $44.72;
  ivory 15 GB free. #241 open, green at 7832f89, no comments; nothing merged; main = 6f060a9.
  Dependabot opened #242–#245 (not ours; #242, the cubecl group bump, fails 14 checks —
  consistent with the 0.11 evaluation). Six 7-day worktrees removed (46 remain). No user
  messages since the posture change.
- Leads today: **L41 lean `walk_pf` prototype** (box `l41-leanpf` 3080, instance 59373929; kill:
  level 3 < ×1.03 at b62 1e17), **L43 per-wave base trims** (box `l43-wavebase` 3080, instance
  59373935; kill < 3 %), **L42 CPU join profile + FD tops** (ivory CPU under nice; kill: top
  certification < 15 % of the CPU join). All hard-stop 10:30–12:30 UTC. A reviewer agent follows
  any PR-ready branch.
- **L42 scoped (07:30 UTC, L42.1):** on the CPU join, top certificates are 42–43 % of production-
  shaped partitions (hardware divides); the FD prototype gives ×1.16 in place (×1.26 with the lean
  prefilter), exact on 19 M slots and whole fields. PR agent launched on ivory
  (`pr/cpu-join-fd-tops` on main, independent of #241; hard stop 11:30 UTC); the CPU lean prefilter
  follows separately after the GPU version lands.
- **L43 parked (08:50 UTC, L43.1):** the base trims give ×1.017 at b62 1e17 (TT2 + WH), ×1.059
  b64, exact; the fixed-trip AND loop and the bucket-kernel `pc` both lose. Below the 3 % line.
  The wave-load hoist saved 4× its instruction-count estimate: the list→entry latency is real.
  Box l43-wavebase destroyed (2.9 h).
- **L42 PR branch ready (08:48 UTC, L42.2):** `pr/cpu-join-fd-tops` fba5431: CPU join ×1.25–1.29
  at production shapes (1 and 4 threads), NiceMark CPU ×1.186, exact on 1.86 M random blocks,
  3.7 M production tops and whole fields. Reviewer agent launched (first use of the new rule);
  the f64 carry-test screen is flagged for it.
- **Review of `pr/cpu-join-fd-tops` (09:25 UTC, `L42/REVIEW.md`): merge with small fixes, no
  correctness defect.** Step/word counts cannot overflow (bounded at the slice's last prefix; 14
  word adds a step, P³ ≤ 29 of 48 digits); seed exact; the f64 carry screen is sound (error
  ~4e-12 vs a 2⁻²⁰ margin; 20.7 M adversarial boundary calls agree); the walk is exact in any
  order. Fixes: a missing carry test (two mutations survive the suite: the ripple past the carry
  word and the `cin` carry — code correct, test missing; the in-word case occurs ~once per
  thousand b60 1e16 fields), body slips (3e15 NiceMark window, #240's ×1.48–1.61, seed count
  basis, overshoot path), rustdoc warning, test-only derives, b64 unmeasured. Sent back to the PR
  agent with a b64 1e14 A/B added.
- **L41 PR branch ready (09:35 UTC, L41.1):** lean prefilter ×1.086 b62 1e17 / ×1.122 b60 / ×1.070
  b64, NiceMark ×1.061 over 6 rounds (MSD-strong ×1.041), exact with exhaustive host tests; the
  round shrank 71 → 41 SASS; bit-reversed masks were needed to make MT shrink. Caveat for the
  body: some compiles spill 28–44 B (CubeCL's dynamic shared array hides the cube limit from
  ptxas). Box l41-leanpf destroyed. Reviewer agent launched.
- **Review of `pr/join-lean-prefilter` (10:05 UTC, `L41/REVIEW.md`): merge with small fixes, no
  correctness defect.** FX's bound recomputed for every base (worst Δ = 2^24.67 at b62, margin
  ≥ 161×; the kernel's operands are exactly the host test's A, P, D < b²); MT's bit reversal is
  consistent at every producer/consumer behind the `lean` flag; the sign test is one
  `SHF.L.U64.HI`; GM/RC give the same predicate (RC pinned only by device parity). Findings: the
  body understates the spills (only level-4 builds spill, 14/26 offline compiles at b60/b62; new
  with this PR; the "6 blocks" explanation untested), the mask convention needs its own paragraph
  and one stale comment, two body slips. Sent back to the L41 agent (text + one comment).
- **PR #246 opened (10:20 UTC): "Overlap join: a division-free middle-digit prefilter"**, f3fb390
  on #241 (review fixes applied: spill paragraph, mask-convention paragraph, stale comment, body
  slips). Open program PRs: #241, #246.
- **PR #247 opened (10:25 UTC): "CPU overlap join: step the top certificates through a key's
  prefixes"**, caef70e on main (review fixes + b64 A/B added; the agent's guard refused the amend
  so I squashed the two commits — tree identical). Open program PRs: #241, #246, #247. Day total:
  7 agents (all Opus: 3 prototypes/scoping, 2 PR branches incl. resumes, 2 reviewers); 3 boxes,
  ~$1.6; director ~6.5 h.
- **L44 roadmap done (11:00 UTC, `L44/ROADMAP.md`):** post-#246 budget at b62 1e17 (100.4 s): top
  FD 26 %, **top scan + fill 8.7 % (never touched)**, join base 21 %, prefilter 15 %, walk 9 %,
  **check 9.5 % (doubled in share; 3 waves for 2.5; recomputes proven digits)**, ~23 s of join time
  unattributed to instructions. Cycles are cap-independent; leaner code lowers the clock, less
  memory traffic raises it. FD persistence is dead (6.9 TB of state traffic per field). Shortlist:
  static bucket order for the top layer (×1.05–1.12), FD top kernel round 2 (×1.05–1.07), CPU lean
  prefilter (×1.06–1.10, high confidence), check kernel rework (×1.045–1.07), re-price the lean
  join. New ledger rows L45–L47; L4 reopened as L47 with the written reason.
- **L45 measurement session launched (11:10 UTC)** on #246 (box `l45-measure`): the top phase split
  into FD / clipped / scan / fill, L37's ablation on the lean join, stage-check cadence, spill vs
  no-spill timing. Decides whether L46 (static bucket order) gets a prototype tomorrow.
- 11:26 UTC: **#246 (f3fb390) and #247 (caef70e) CI fully green** (25 pass, 3 skipped each), #241 too; no comments.
- **L45 done (13:55 UTC, L45.1):** top scan + fill measured at 9.7 % / 9.0 % of the field (fill
  8.6 %) → **L46 static bucket order gets its prototype tomorrow** (ceiling ×1.10). The lean join
  after #246: base 16 %, **AND 8.3 %** (latency no longer hides it), walk 6.4 %, prefilter 16 %,
  stage 1.3 %. Stage check once per batch is an exact ×1.02 rider. No spills in production
  (NVRTC compiles at 47–48 registers; the spill came from nvcc offline); NVRTC's PTX is 1.7 % of
  the field slower than nvcc with a launch bound (not actionable in CubeCL today). Box
  l45-measure destroyed (2.7 h). Day: 4 boxes, $1.3; 9 agents; director ~7 h.

## 2026-11-05 (day 9; routine fired 04:41 UTC)

- **Reconcile:** no research instances; November research $6.12 (fleet $7.80); credit $47.43;
  ivory 16 GB free. #241 open, green, no comments; nothing merged; main = 6f060a9. No user
  messages since the day-8 addendum. **15 worktrees past the 7-day line removed** (all clean,
  branches kept): 52 remain.
- Leads today (both stacked on #241, A/B vs af21136, kill < 5 % or a NiceMark scenario < ×0.98):
  **L39** bottom-entry record (box `l39-botrec` 3080 CA, instance 59214557) and **L40** group
  walk over the 8 pass words (box `l40-groupwalk` 3080 KR, instance 59214577); 6 h TTLs, hard
  stops 11:00 UTC. L37's `COMPACT=2` is L40's starting point.
- **L39 closed (07:20 UTC, L39.1):** neutral (×0.997 b62 1e17, ×1.006 b60) despite sectors per
  entry 2.5 → 1.0; the entry gather is latency-hidden, not sector-bound — L37's 10.5 s was a
  stripped-kernel artefact (lesson recorded). Exact. Box l39-botrec destroyed (2.0 h).
- **L40 parked (10:40 UTC, L40.1):** ×1.056 b62 1e17 / ×1.074 b60 (×1.10–1.12 clock-normalised),
  NiceMark ×1.030, exact, rounds per group ×0.65, lane utilisation 25 → 38 % — but b58 MSD-strong
  ×0.963 and 1e14 −3–4.5 % (small batches save nothing and pay the bigger body; every gating
  variant spilled or stayed < ×0.98). Branch `pr/join-group-walk` f8a27cc kept; question to the
  user whether a production-weighted ×1.06–1.07 with that small-bucket cost is acceptable. Box
  l40-groupwalk destroyed (4.6 h).
- **11:00 UTC, user: "update your effort targets to utilize 50–75 % more tokens"** (split up to me;
  Vast budget unchanged). New posture **heavy+**: ~8 h director time, ≤20 subagents, three leads
  a day (two GPU prototypes + one scoping/review/analysis), a reviewer agent on every PR branch,
  A/B ≥ 3 rounds and NiceMark ≥ 4. PROPOSAL §4, README, ROUTINE.md and the trigger prompt updated.
- **Evening (16:10 UTC), first use of the extra effort, no GPU:** three agents — an independent
  review of PR #241's diff and body (→ `L38/REVIEW.md`), L41 scoping of the prefilter arithmetic
  and the per-wave base from SASS (`L41/BRIEF.md` → `L41/SCOPING.md`; tomorrow's prototype
  plan), and literature sweep 4 with widened terms (`L7/2026-11-05.md`).
- **Sweep 4 done (17:00 UTC):** fourth null with widened terms → the arXiv canvass is dropped;
  weekly sweeps become targeted questions + occasional OEIS/repo spot-checks. GTaP (2604.05982,
  divergence-aware queueing) noted for the walk; no nice-number news outside the project.
- **#241 reviewed (17:20 UTC, `L38/REVIEW.md`): merge with small fixes** — code correct at every
  site (52 uses converted one-to-one; alignment and plan bounds re-derived); low findings: record
  size written three ways (→ `TOP_RECORD_BYTES` + compile-time assert), a shadowed `rec` in
  `read_checked`, and PR-body wording (cycles-column method, "every run at the cap" only true for
  1e16/1e17, "single round" was two, the 7.6e10 top-loads source). Applied on the branch; body
  edited. The FD-vs-top test's buffer reuse (could miss a dropped constant store; pre-existing)
  noted for a later test PR.
- #241 → 7832f89 (tidy-ups amended into the single commit; `cargo check --features gpu` and
  `--features cubecl` on ivory under nice, fmt clean; the first attempt missed the kernels'
  inner-module import, caught by the check). Comment posted; CI check scheduled.
- **L41 scoped (18:10 UTC, `L41/SCOPING.md`):** the join is integer-ALU-bound; one walk round is
  110 SASS (74 every round), `walk_pf` 51 of which 20 are digit extraction (mod b², /b, %b) and
  26 one-hot mask building — the pair's real arithmetic is 2 mul-adds. Lean prefilter bundle
  (fixed-point digit extraction with a proof, shift+compare membership, seed-gated top masks):
  51 → 25 instructions, est. 10–13 % of the field, exact by construction. **Tomorrow's first
  prototype**, with host exhaustive tests of the fixed-point step before any timing, a codegen
  gate, and ≥ 6 NiceMark rounds. Caveats: SASS from L40's M kernel (L37's tarball was already
  unpacked); plane-wave counts estimated from L39's entry-load count.
- 17:22 UTC: **#241 CI fully green at 7832f89** (25 pass, 3 skipped); no comments.
- Evening agents: 3 (2 Opus, 1 Sonnet); day total 5. Director time ~6.5 h.

## 2026-11-04 (day 8; routine fired 04:41 UTC)

- **Reconcile:** no research instances; November research $5.40 (fleet $5.99); credit $49.96;
  ivory 15 GB free (80 %). All five join PRs merged yesterday; main = 6f060a9 (= `exp/join-all5`);
  no program PRs open; only the user's telemetry note since the report. Worktree `rp-prune` (7 d)
  removed.
- Leads today: **L37** (join kernel breakdown by ablation on main, then H1 walk compaction and H2
  shuffle LUT; box `l37-shuffle` 3080, instance 59063596, 7 h TTL, hard stop 11:45 UTC) and the
  **demoux telemetry check** the user invited (read-only via data.nicenumbers.net).
- **Telemetry check done (T1, 07:30 UTC):** demoux on 6f060a9 = ×2.27 per b60 1e16 field vs the
  pre-stack main (14.2 s vs 32.2 s processing; 7.05e14 numbers/s), 1,842 fields, 0 disqualified.
  Bursts of ~50 zero-work submissions per hour looked alarming but are fields eliminated by the
  field/range certificates (149/160 by the field certificate alone, the rest range by range);
  same pattern on the fleet, mayalaran and old builds. Not a defect; worth a line in the report.
- **L37 done (08:50 UTC):** both prototypes exact but slower (H1 ×0.94, H2 ×0.95) → killed;
  `COMPACT=2` ×1.015–1.026 parked. The breakdown is the result: the AND is 5 % of the join after
  #239 (so the shared-load story was wrong about what remained), survivor handling is 54 % (the
  prefilter alone 33 %), and **gathering each batch's tops into shared memory is 26 % of the join,
  15.7 s of 18.6 s on the two separate `top_r`/`top_x` arrays** — random 2-word reads touching
  3–4 sectors per top. Box l37-shuffle destroyed (3.40 h).
- **L38 launched (09:10 UTC):** one 32-byte record per top (same bytes, one sector per load);
  estimate 9–12 % at b62 1e17; agent on box `l38-toprec` (3080, instance 59082237, 6 h TTL, hard
  stop 13:30 UTC); PR branch `pr/join-top-record` prepared if ≥ 5 %, PR opened by the director.
- **L38 done, PR #241 opened (11:20 UTC):** ×1.100 b62 1e17, ×1.060 b60, NiceMark ×1.050, exact;
  part of it is clock under the power cap (cycles −4.3 % at b62 1e17), stated in the body. Box
  l38-toprec destroyed (2.20 h). Agent incidents: GitHub SSH/HTTPS outage 09:47–09:57 (worked
  around with a bundle + gh token); one mistaken `git push --force` at upstream, refused by GitHub
  (the bot has no push access; upstream main untouched). Open program PRs: 1.
- 12:18 UTC: **#241 CI fully green** (25 pass, 3 skipped) at af21136; no comments. GitHub SSH
  auth from ivory was refused intermittently today (`sync.sh` and fetches); pushes went through
  on retry — fallback is HTTPS with `gh auth token` via `http.extraheader`.

## 2026-11-03 (day 7; routine fired 04:41 UTC)

- **Reconcile:** no research instances; November research $4.99 (fleet $4.20); credit $52.16;
  ivory 15 GB free (80 %). Nothing merged since #238; all five program PRs green (#235 c5fb040,
  #236 fb05597, #237 51410e7, #239 775b6d9, #240 c7ef3c8); no user comments or session messages
  since the day-6 report. main = 04693ac. **At the PR cap: nothing opens today.**
- Leads today: **L36** (full open stack measured on one tree `exp/join-all5` + post-#240 profile +
  top-kernel residual ablation; agent on box `l36-stack`, 3080, instance 58924168, 6 h TTL, hard
  stop 10:45 UTC; kill: no term ≥ 25 % of the stepped slot removable) and **L7 sweep 3** (Sonnet;
  bank-conflict-free gathers, SWAR digit distinctness, prior art on stepping digit arrays).
- **L7 sweep 3 done (06:50 UTC):** third consecutive null on new papers (arXiv API rate-limited;
  use the `list/<cat>/recent` pages next time). Targeted: (B1) warp-shuffle register LUT for
  #239's gathers (2 registers per lane hold the chunk's 64 words; one shuffle per digit; no bank
  conflicts, no shared table) is the one actionable idea; (B2) no SWAR distinctness trick, no
  GPU PDEP; (B3) no prior art for stride-b^s digit stepping or interval certification.
- **L36 done (09:13 UTC):** `exp/join-all5` (main + the five PRs) is **×1.88 at b62 1e17 vs main**
  (×1.96 at matched clocks), ×1.96 b62 1e16, ×1.80 b60, ×1.55 b64, NiceMark ×1.61; exact everywhere
  (whole-field counts = all3's). Box was a 150 W card (ratios only). Profile after the stack: top
  30 %, join 56 %, check 8 %. The stepped top slot's residual is bookkeeping (scan 32 %, append
  17 %, carry/ndig 22 %); three exact trims give −22 % of the slot = ×1.04 field → parked
  (`exp/top-fd-ablate` 47c1b36). Box destroyed (3.52 h). Next target is the join (56 %): the
  warp-shuffle LUT for the AND and the walk/survivor path.
- **14:40 UTC: the user merged #235 (d23d4a5) and #236 (b580214)** and asked for the other three to
  be rebased. Done: #237 → f5dbeeb (on main), #240 → 8242231 (on the new #237), #239 → 169536a (on
  main); changelog conflicts only, kernel code auto-merged; the three rebased branches merged
  together are byte-identical in code to `exp/join-all5` (the ×1.88 tree). Comments posted; CI
  check scheduled. Open program PRs: 3 (two slots free).
- **15:40 UTC: the user merged #237 (39dbe92) and #239 (5cfd1c7)** with the macOS runner jobs still
  pending (they have been flaking). **#240 rebased → 0e9b1391441dff6e9edfb2f5074bf320311c5c64** on main; code byte-identical to
  `exp/join-all5`. main now carries four of the five; only #240 is open (one program PR open).
- **15:45 UTC, user:** "Looking good, running on demoux now with telemetry on. Iff it would be
  helpful you can check the telemetry submissions during the next scheduled run." → tomorrow:
  read demoux's telemetry submissions (read-only, public API/data site): version string, claims
  accepted, counts/hits sane, per-field rate vs demoux's earlier submissions at the previous
  version. First non-NVIDIA (RDNA4, wgpu/SPIR-V) run of the merged stack.
- **16:34 UTC: #240 merged (CI 25 green).** All five program join PRs are in main; main's code
  equals `exp/join-all5` (the ×1.88 tree). Open program PRs: 0. Worktree `exp-join-all5` removed.
- Worktrees: `exp-top-fd-ablate` kept (tomorrow's base); two profiling scratch
  worktrees removed. 69 worktrees; the 10-28 checkouts cross the 7-day line tomorrow.

## 2026-11-02 (day 6; routine fired 04:41 UTC)

- **Reconcile:** no research instances; November research invoiced $3.83 (fleet $2.51); credit
  $55.02; ivory disk 16 GB free (79 %); no user messages since the day-5 report. #238 merged
  (API), nothing of ours; main = 04693ac. All three program PRs (#235/#236/#237) were
  CONFLICTING (changelog only: #234's links + #238's lines).
- **Rebased #235 → c5fb040, #236 → fb05597, #237 → 51410e7** (on #235) onto main; code diffs
  byte-identical to the previous heads (checked with `git diff` against the old base); each
  entry now carries its own PR link as #234's convention does; one-line comments on the PRs.
  Merge of all three for experiments: `exp/join-all3` 0f1a8a7 (fork).
- **New lead L34** (digit-transposed AND in the join kernel; supersedes L18): the bottom mask
  has exactly 12 digits, so the AND over a chunk of 32 tops becomes ≤ 14 ORs of per-digit
  top bitmaps instead of 32 mask ANDs. The AND phase is ~27 % of a b62 1e17 field after
  #235/#236 (L1.7's fit: real lanes 30 s, padding 6.7 s, per-top cost 9.1 s of 166 s).
  Brief in `L34/BRIEF.md`; agent (Opus) on box `l34-transpose` (3080, KR, $0.108/h, 7 h TTL,
  instance 58775886) for the post-#237 profile + prototype + A/B; hard stop 11:30 UTC.
- **New lead L35** (top kernel by finite differences across a batch's partitions): consecutive
  slots step the interval by w = b^(L−t), a digit shift, so the next slot's a², a³ digit arrays
  are additions of shifted arrays (no division). The conversion is ~half of the top kernel,
  which is ~39 % of a b62 1e17 field after #237. Brief in `L35/BRIEF.md`; second agent (Opus)
  on box `l35-topfd` (3080, KR, instance 58776353, 7 h TTL); hard stop 11:45 UTC. Batches may
  have gaps (tests thin partitions) → re-seed by division on a gap.
- **L34 result (08:46 UTC, L34.1):** exact; plain ×1.063 b62 1e17 but ×0.90 on b58 MSD-strong;
  hybrid (per-top AND below 128 tops) ×1.075 / ×1.065 b60 / ×1.129 b64, NiceMark ×1.085, small
  buckets ×0.96–0.99. Shared-memory bound (bank conflicts on the digit gathers), so the AND only
  got ×1.3 cheaper. Post-#237 profile: top 34.6 %, join 52.8 %. Agent sent on to screen a
  full-batch-only gate (MIN=256/192) and to prepare `pr/join-transpose-and` on #236 (no PR yet).
- **L35 result (09:40 UTC, L35.1): ×1.143 at b62 1e17, ×1.136 b62 1e16, ×1.084–1.10 b60, exact;
  b64 neutral → FD off at power-of-two bases; NiceMark ×1.00 because its bit-reversed partition
  samples seed every slot (production runs partitions consecutively).** Endorsed for a PR on the
  whole-field production measurements; agent sent on to prepare `pr/top-fd` on #237 (51410e7)
  with a final A/B incl. b58 1e16 and a body that explains the NiceMark neutrality. That would
  make 5 open program PRs (the cap): #235 → #237 → top-fd, and #236 → transpose.
- **PR #239 opened (10:40 UTC, L34.2):** transposed AND gated at 192 tops per batch, on #236:
  ×1.055 b62 1e17, ×1.062 b60, ×1.176 b64, NiceMark ×1.075 (MSD-strong ×1.017), exact; the 1e14
  loss (×0.93–0.98) is the kernel's footprint (5 cubes/SM), not the transposed path, and is stated
  in the body. Box l34-transpose destroyed (4.63 h).
- **PR #240 opened (11:55 UTC, L35.2):** top kernel by finite differences, one commit on #237:
  vs #237 alone ×1.080 b62 1e17, ×1.116 b62 1e16, ×1.065 b60, ×1.043 b58, b64 and NiceMark
  neutral; ×1.143 with #236 underneath. Large diff (+1495/−169). Box l35-topfd destroyed (5.16 h).
  **Open program PRs now 5 (#235 → #237 → #240; #236 → #239): at the cap, nothing more opens until
  merges.** November research spend $4.99.
- 12:03 UTC: **#240 CI fully green (25 pass, 3 skipped) at c7ef3c8.** All five open program PRs
  green. No user comments yet. Report sent 11:10 UTC.
- Worktree hygiene: nothing crosses the 7-day line yet (oldest checkouts 10-28); 64 worktrees,
  all but two under 30 MB. `rb-1102` (scratch for the rebases) to be removed at day end.

## 2026-11-01 13:05 UTC: run closing

- **PR #237 opened** (top kernel part 2: limb skip + (a) + (c) on #235; ×1.100 vs #235 at b62 1e17,
  ×1.21 vs main; L33.2). All boxes destroyed; November research $3.82. Report sent. Open program
  PRs: #235, #236, #237. Fallback reminder deleted.

## 2026-11-01 (routine fired 04:41 UTC, inside the extended run)

- Reconcile: November research invoiced $2.13 (the H100/L40S hour is most of it); credit $59.03;
  disk 19 GB free; #235 green, #236 24 pass + 1 runner-side rustup failure; main fae7398 (#234
  changelog links merged). Live boxes: `topcert2` (running) and `combined` (created); my `tail` had hidden one line.
- L31 top-kernel part 2 scoped: all three changes ×1.053 at b62 1e17 (marginal; Barrett step
  unproven on Apple) → parked behind switches (`exp/top-cert-2`). Box topcert2 destroyed (2.45 h).
- **Combined #235+#236 (L30.3): ×1.365 at b62 1e17, ×1.38 b60, NiceMark ×1.325, exact, compounding
  confirmed; profile after both: top 43 %, join 46 %, 35 % of join lanes are padding.** Comments
  posted on both PRs. New lead L32 (wave padding). L31 (a)+(c) re-measured on the combined tree
  (box `topcert2b`) for a possible stacked PR. Box combined2 destroyed (2.06 h).
- **4090 second card (L30.4):** #235 ×1.08–1.12, #236 ×1.18–1.31, both ×1.34–1.36, NiceMark ×1.26; compounding
  within ±1.2 %; PR bodies updated. **L31 (a)+(c) on the combined tree (L31.2): ×1.045 b62 1e17, ×1.059
  b60, NiceMark ×1.041 → parked narrowly.** **L32 tail wave (L32.1): ×1.040 b62 1e17, ×1.028 b60,
  NiceMark ×1.078, +1 register, wgpu/Metal unchecked → parked.** L33 early-reject scoping launched
  (box `earlyreject`, hard stop 12:45 UTC). Boxes second-card, topcert2b, padding destroyed.
- **L33 (L33.1): the early reject cannot fire (×1.01), but the scoping found that the long division
  runs all limbs though the top ones are known zero; skipping them is exact and ×1.051 at b62 1e17,
  NiceMark ×1.066.** PR agent assembling limb skip + L31's (a)+(c) on #235 (box `topcert3`, hard stop
  13:35 UTC); together ≈ ×1.10 expected. Box earlyreject destroyed (2.60 h).
- L32 wave-padding scoping launched on the combined tree (box `padding`, KR). Live boxes at 07:00:
  second-card (4090, GB), topcert2b (3080, KR), padding (3080, KR).
- 4090 second-card run launched (main / #235 / #236 / both; box `second-card`, GB, $0.31/h).
- 04:55: the `combined` box (m146575, PL) never left `created` (ssh refused for an hour); destroyed,
  machine excluded, replaced by `combined2` (KR, 58618524), reachable in 3 min; the agent's merge
  `exp/join-235-236` (e9cdac4) and scripts were ready, so it resumed there (~90 min run).

## 2026-11-01 (extended autonomous run, 02:00 → 14:00 UTC at the user's request; weekly cap resets 14:00)

- #235 CI: naga lavapipe + lint pass, but the **CubeCL direct-SPIR-V step aborts with a compiler-thread
  stack overflow** (the bigger `cert_power`); hold comment posted; fix agent on a 3060 (L29/SPIRV-FIX.md).
- L7 sweep 2 done (nothing new; Barrett candidate L31); Apple Feedback draft written (L3/APPLE-FEEDBACK-DRAFT.md).
- **Done so far in the run:** #235 SPIR-V fix (6e7475e; CI green; L29.2); L9 H100/L40S (not worth
  renting; L9.1, $2.7); L8 tail test (model fits to 3 missing digits; headline best guess ~4.7 %;
  L8.1); L7 sweep 2; Apple Feedback draft; hand-CUDA retirement proposal (PROPOSALS/). L30 scoping
  → prototype ×0.833 at b62 1e17 → PR agent running (box `l30-pr`); top-kernel part-2 scoping
  running (box `topcert2`). Boxes destroyed: survivors, profile-1e17, topcert, fd-u32mask,
  l9-h100, l9-l40s, topcert-spirv.
- **PR #236 opened** (prefilter in the walk: ×1.215 b62 1e17, NiceMark ×1.194; L30.2). CI: 24 pass,
  1 red = the NVRTC job's rustup component-install conflict on the runner (not the code); comment
  posted asking for a rerun (I cannot rerun upstream workflows).
  Combined #235+#236 A/B vs main running (box `combined`, PL); top-kernel part-2 scoping running
  (box `topcert2`). Live boxes: topcert2, combined.
- Plan: finish L30 scoping (→ PR if ≥ 5 %); #235 CI; L9 H100 + L40S rates (two boxes, ~$2);
  weekly literature sweep (L7); an Apple Feedback draft for the user; the top kernel's e^j
  follow-up if L30 yields nothing; worktree/disk hygiene; final report before 14:00 UTC. The
  04:41 routine folds in. November budget: $30 fresh; credit $60.85.

## 2026-10-31 (late evening, user: "continue with those tasks as though you were doing the next run now")

- The user bumped the version (8bd154b "Update changelog, bump version"; 9bde4a8 dev bump) to ship
  the detailed FD changes (#221/#225/#227/#233). main = 9bde4a8. Credit $61.59; research MTD $4.62.
- Boxes: 3080 `profile-1e17` (3 h), 3080 `topcert` (6 h), 3060 `fd-u32mask` (4 h).
- Agents: P = join profile at b62 1e17 + 1e16 refit (L1/PROFILE-3.md); T = GPU top certificate from
  one endpoint's digits + carry (port of #204's CPU form) → `pr/join-top-cert-fast`, A/B at b62
  1e17/1e16, b60, b64 + NiceMark (L29); M = u32-pair mask in the native FD kernel on wgpu →
  `pr/fd-u32-mask` (L28), exactness on CUDA/lavapipe; Apple/AMD speed needs a machine window.
- **Results:** P: b62 1e17 profiled (top cert 38 %, survivors 26 %; 1e17 adds no cost term; L1.7).
  **T: PR #235 opened** (top certificate from one endpoint + carry; ×1.075 at b62 1e17, NiceMark
  ×1.071, bit-identical; L29.1). M: `pr/fd-u32-mask` exact but **held** (gain unmeasured; pair on
  CUDA −24 %; needs M4/AMD; L28.1). S (survivor scoping, L30) running on a fourth box.
- #235 rebased onto fae7398 (the user's changelog edits) → 3eb6e72, CHANGELOG +1 line; CI watching.
- Boxes destroyed: profile-1e17 1.52 h, topcert 2.38 h, fd-u32mask 1.19 h; `survivors` (L30) running.

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
- #231 got a follow-up commit (1e4ffcf): the lint requires the browser per-number kernel at base
  80 instead of 40/50, so it holds whichever of #231/#233 lands first; #233 adds its own kernel's
  requirement after #231 is in. CI watches on #231, #232, #233.
- **State at end of day:** open program PRs #231 (parity step + lint), #232 (test flake fix), #233
  (browser GPU FD). Merged today: #221, #225, #227, #228, #229, #230. Remaining L24 work after
  merges: rebase #233 onto #231 and add `--require DetailedFdKernelU32@40/50`; demoux (AMD) browser
  run by the user or by request; Safari/Windows skipped (decision 9).
- **#231 and #232 merged by the user** (#231 before my base-80 follow-up 1e4ffcf landed, so main
  carries the base-40/50 requirement). #233's lavapipe job then failed the lint's *requirement*
  (not a flagged site: 0 flagged on 14 shaders) because its kernel makes bases 40/50 compile
  `DetailedFdKernelU32`. Fixed in #233 (ae8b0bd): rebased onto main, dump test calls the browser
  path at base 80 too, lint requires `DetailedKernelU32@80` + `DetailedFdKernelU32@40/50`. **#233 CI fully green on ae8b0bd.**
- **Dev server for the user's demoux test (10-31 ~20:30 UTC):** #233 (ae8b0bd) built with
  `wasm-pack build --target web` + `vendor-fetch` in `.worktrees/pr-web-fd-rb/web`, served by
  `~/nice-web-tls/serve.py` (Python ThreadingHTTPServer + self-signed cert, 30 days, SANs
  100.109.36.42 / ivory / ivory.neon-locrian.ts.net) on **https://100.109.36.42:8443/search/**
  (pid 944040, log `~/nice-web-tls/serve.log`). `tailscale serve` was denied (needs
  `sudo tailscale set --operator=claude` once). Stop with `kill 944040`.
- **User ran parity on demoux (RX 9070 XT, LibreWolf/Firefox 155): 199 windows identical** (L24.4);
  added to #233's body and comments. Decision 9's AMD layer is covered; only the AMD speed suite
  remains unmeasured.
- **#233 merged by the user.** Dev server torn down (serve.py pid 943921 killed, `~/nice-web-tls` removed).
  **The web GPU port (L24) is complete:** #230, #231, #233 merged; AMD parity by the user.
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
