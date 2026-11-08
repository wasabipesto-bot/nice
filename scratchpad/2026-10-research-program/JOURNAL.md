# Journal

Newest first. One entry per working day: what was done, what was decided, what is
in flight, and anything the next director needs to know. Keep each entry short; the
numbers go in EXPERIMENTS.md and the status in LEDGER.md.

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
