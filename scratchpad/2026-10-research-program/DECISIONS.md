# Open decisions for the maintainer (kept current; last updated 2026-11-20 10:50 UTC)

This is the one document to read if you have ten minutes. It assumes you have read nothing else. Each
decision says what I will do if you do not answer. **How the join works and why it is built this way is in a
separate document:** `../2026-11-midout-design/DESIGN.md` (with a one-screen picture,
`../2026-11-midout-design/static/midout-overview.png`, and a clickable process map,
`../2026-11-midout-design/interactive/midout-map.html`). To answer, reply in the chat with the numbers, for
example: `D2 a, D3 yes, D5 yes hidden, D14 45, D16 yes`.

Paths below are relative to `~/projects/nice/scratchpad/2026-10-research-program/`.

## 0. Where things stand, in fifteen lines

**The middle-out join** is the redesigned nice-only GPU join you approved on 2026-11-18. Idea: today's overlap
join pairs top prefixes of n with bottoms inside a contiguous range of n. The redesign makes a unit of work
("slice") the set of all n that share five *middle* digits (positions 4–8), so tops and bottoms are each built
once for a far larger span and paired with a bit-sliced kernel.

| | state on 2026-11-19 |
|---|---|
| code | branch `dev/mo-clean` on the fork (`wasabipesto-bot/nice`): the development branch after a cleanup for review (done 2026-11-19: prototype leftovers removed, layouts documented, tests in tiers CI can run, the kernels also passing through WGSL); 14,405 inserted lines in 21 files (head `10ddbf17` since 2026-11-20), no PR (held at your word, see D9); the first two PRs (no GPU code) are cut, reviewed and waiting on the fork |
| speed, base 64, RTX 3080, end to end against v3.4.8's join, same session | **×4.09** (1.62 fs against 6.62 fs per candidate) |
| speed, base 64, RX 9070 XT (demoux), end to end against v3.4.8's join, same session | **×4.79** (0.99 fs against 4.76 fs per candidate), measured 2026-11-19 at 64 lanes on the branch just before its cleanup (the cleaned branch has not run on that card; on the 3080 the cleanup changed the time by +0.17 %); exact on every slice and field tried; the client route also ran there against a local coordinator (12 fields). The 4.76 fs baseline there is production's join throughput harness (ten fields on 2026-11-18, scaled ×1.012 by two fields re-measured in the same session), not the client's own ten-field run that the 3080 baseline uses. At that speed base 64 on that card alone is about 55 days instead of about 266 |
| base 65 (needs masks wider than 64 bits; production has no join there at all) | exact on a GPU; 3.47 fs per candidate on 2026-11-19, about half an RTX-3080-year for the whole base; 10 % less since 2026-11-20 (3.29 against 3.66 fs in one session on a slower box). On your card it measured 3.1 fs on 2026-11-19; the wide kernel has since been fitted to that card offline (12 waves instead of 8), not re-run: predicted 2.4–3.0 fs |
| exactness | CPU reference equals brute force on whole bases 10–25; GPU equals the CPU reference on 1,073 real base-64 slices (measured on 2026-11-18, before the execution checks and the digits-5–7 field were added; since then: 100 of them again, the first and last slice of the range, and every slice of one field under both field definitions); an independent audit found no loss path on a healthy card |
| failure handling | every stage proves it ran (what ran = what was queued), two conservation checks, and one random slice per field recomputed on the CPU (at base 65 too since 2026-11-20: the CPU slice now runs on up to 4 threads); a dropped kernel, a failed allocation or a wrong prefilter stops the field instead of reporting it empty |
| how it runs today | a local coordinator script plus an off-by-default client flag; **no server, schema or API change exists or is proposed yet** |
| what a field is | all n sharing digits 5–7 (base 64: 262,144 fields of 2^57 n; in the fields table it would still be a range, of a renumbered coordinate) |

What it is not yet: reviewed by you, run on Apple hardware, or connected to the real server.

Earlier ratios I reported (×4.6 to ×5.5) were kernel timings plus an assumption that was four times too low.
×4.09 is the honest end-to-end number on NVIDIA.

**How much more is in it (counted 2026-11-20):** the pairing kernel is 60 % of a slice. Exact counts on real
slices show that no other order of the work and no extra skip test beats today's by more than ×1.18, and that a
perfect skip test would give ×1.99 at most. So the join is near the end of what this kind of join can do; what
is left is ordinary tuning for the card (wider words per lane are the one untested lever) and the stages around
the kernel. The argument and the counts: `CEIL/NOTES.md`, `CEIL/RESULTS.md`.

## A. The middle-out join

### D1. How much goes into the first series of pull requests?

- **Why it matters:** the branch is large. The independent plan (`G2/PR-PLAN.md`) cuts it into 12 stacked PRs.
- **Options:**
  - **a. Base 64 only first** (PRs 1–6: coordinate; CPU reference; device tops; one slice with its checks; a
    whole field with the CPU spot-check; shared preparation): about 5,500 lines of code and 1,400 of tests. The
    wide path (bases 65–70, 4,700 lines) follows once base 64 has run on the fleet.
  - b. Everything, including the wide path.
- **Recommendation: a.** Base 65 is at least months away; its code has had less scrutiny (its own check
  kernel is unaudited).
- **If you do not answer:** a.

### D2. Which definition of a field?

- **Background:** a field must fix some middle digits of n. An independent review (`G2/fs/REVIEW.md`, half a
  page at the top) showed that the join's internals (its shape, kernels, slice size) stay free under any choice
  within digits 4–8, that the choice can cost at most ×1.15 (base 64) to ×1.30 (base 65), and that today's
  overlap join could still search such fields (about ×1.9 slower). **A correction (2026-11-19):** I told you
  such fields "can be re-cut later without redoing any search". That holds only between bases, or if the
  server tracked single slices: a field cut along other digits is not a union of finished fields, so re-cutting
  a partly searched base would leave partly searched fields. Treat the definition as fixed for a base once its
  first field is handed out; it remains a free choice per base. It recommended fixing
  digits **5–7** rather than 6–8; that is built and measured (3.1 % faster, exact slice by slice against the
  old definition).
- **Options:** a. only 5–7 in the PRs (the old definition stays on the archive branch); b. keep both.
- **Recommendation: a.** **If you do not answer:** a.

### D3. The client flag and the coordinator script

- **Background:** with no server change, the only way to run the join for real is a small local coordinator
  (`scripts/midout_coordinator.py`, standard library, binds to 127.0.0.1) and a client flag
  `--midout-coordinator URL`. The flag refuses the production API by name; nothing is submitted after a failed
  check. Details and command lines: `G2/BUILD-NOTES-CLIENT.md` §2.
- **Decide:** (i) is this new flag acceptable at all; (ii) hidden from `--help`; (iii) where the script lives.
- **Recommendation:** yes; hidden; `scripts/`. It goes in its own PRs (7–10), after the first series.
- **If you do not answer:** I prepare those PRs but do not open them.

### D4. How base 64's fields reach clients (the server side)

- **Not needed yet**; base 62 ends around late December. Three options were worked out (`G2/PROPOSAL.md` §2–4):
  - **A.** Base 64 goes into today's `fields` table as ranges of a renumbered coordinate; the server needs a
    claim filter so old clients are never handed such a field (about 150–250 lines, no new table).
  - **B.** A separate table and endpoints (3–4 times the server work; buys nothing at base 64).
  - **C.** No server change: a private coordinator for your own machines; results backfilled into the table
    later.
- **Recommendation:** C first (demoux alone is 86 % of the search), then A once the join has run for a while.
- **If you do not answer:** nothing happens on the server; I keep to C in everything I build.

### D5. The guard in the ordinary client

- **Background:** one small edit to production's claim path makes every ordinary route refuse a field marked
  as coordinate-space (otherwise an old route would search the wrong numbers and call the field done). It does
  nothing unless a claim carries a `coordinate` key, which the real server never sends today.
- **Options:** a. land it with the client-route PRs; b. only together with a server design.
- **Recommendation: a.** **If you do not answer:** a (inside PRs that wait for D3 anyway).

### D6. Tests in CI

- **Background:** CI's GPU jobs run every ignored test. The branch's long tests need a real card or hours.
- **Proposal:** three tiers: fast CPU tests (always); small device tests that the lavapipe jobs run with both
  compilers; card-only and long tests behind a cargo feature that no default build enables.
- **Also decide:** should the new device tests run on the macOS (Metal) job? The join has never run on Metal.
- **Recommendation:** the three tiers; not on the Metal job for now, and the client flag should refuse to run
  on Metal until someone has checked it on Apple hardware. (Built on the evening of 2026-11-19: the route refuses a
  device whose name says Metal. The refusal itself has not been run on a Mac.)
- **If you do not answer:** as recommended.

### D7. A benchmark example in the repository?

- The engineers timed the join through `common/examples/midout_bench.rs`; the repo has no examples today.
- **Recommendation:** not in the first series; timing stays in ignored tests behind the feature of D6.
- **If you do not answer:** as recommended.

### D8. The name

- Working name: **middle-out join**, module `midout`, a unit of work is a **slice**. Sober alternative:
  "transversal join". Renaming is cheap until the first PR opens.
- **If you do not answer:** middle-out / `midout`.

### D9. When to open the pull requests

- **Your answer (2026-11-19):** hold. No pull request is opened from the middle-out work until you say so; work
  on the branch continues.
- **What is ready when you do say so:** the first two (no GPU code), cut, independently reviewed including
  mutation testing, and fixed: `pr/midout-field-coordinate` (the field coordinate, about 570 lines) and
  `pr/midout-cpu-ref` (the exact CPU reference, about 1,300 lines), both on the fork, one commit each. Their
  drafted descriptions: `G2/PR1-BODY.md`, `G2/PR2-BODY.md` (to be shortened before opening).
- **To read the design** (written 2026-11-19, all under `../2026-11-midout-design/`): `DESIGN.md` (the idea,
  the pipeline stage by stage with measured costs, what a field commits the project to, how the code knows the
  work ran, each internal design decision with its alternatives and numbers, what is measured, what is not done,
  a file map and the command lines); `static/midout-overview.png` (one screen); `interactive/midout-map.html`
  (open in a browser: click any stage for why it exists, what it costs on both cards, which check guards it and
  its file:line on `dev/mo-clean`; a column beside it shows today's overlap join stage for stage).

## B. Production soundness

### D10. Pull request #270 (merged by you on 2026-11-19) and one small follow-up

- **What it was:** after a GPU memory allocation failure, the runtime silently skips later kernel launches; on
  the nice-only *stride* path the v3.4.8 client then submitted unsearched fields as empty. The *join* path (all
  of today's base-62 fields) already caught this. #270 adds the same check to the stride path.
- **Effect on past results:** none known. A census of all 984,248 nice-only submissions since v3.4.0 found 451
  that ran the exposed path (one fleet test on 2026-09-03), all on fields already searched on the CPU; the
  hand-written CUDA backend was tested separately and is not exposed (`EXPERIMENTS.md` SRA.3, SRA.4).
- **On your card (run after the merge, in the lease of 14:00 UTC):** #270's new test passes on all three stride
  paths. One *older* test (from #263, mine) fails there: it forces a form of the survivor queue that production
  never selects on a 64-lane card. Production's own form passes in every configuration, and the forced form
  fails loudly, not silently. So: nothing is wrong with the client on demoux; the test is wrong on that card.
- **Follow-up: pull request #271** (opened 2026-11-19 15:00 UTC): a 16-line, test-only fix, independently
  reviewed, run on your card (both tests pass), on the software renderer with both compilers, and through
  `just lint`. **Recommendation:** merge.

### D11. A `--gpu` client whose CUDA runtime cannot start

- Today it falls back silently to the CPU software renderer: correct results, hundreds of times slower.
- **Recommendation:** make it an error. A behaviour change, so it needs your yes; a small PR.
- **If you do not answer:** nothing.

### D12. Three older items

| | question | recommendation | if no answer |
|---|---|---|---|
| a | 153,748 fields of bases 58 and 60 were searched only by builds before #222, which could lose candidates on some devices (seen on the M4): accept the residual (expected loss about 4e-9 of those bases' candidates) or re-search? | accept | nothing |
| b | Pin the CPU's survivor and check counts in NiceMark, so the benchmark is also a known-answer test on every device | yes, a small PR | nothing |
| c | CubeCL 0.10's SPIR-V optimizer drops repeated atomic stores of one value: add a CI check for that pattern | yes, small | nothing |

### D13. Report the CubeCL loop/break defect upstream?

- A draft issue is ready (`G2/port/CUBECL-LOOP-BREAK-ISSUE-DRAFT.md`). The other two CubeCL defects found are
  gone in 0.11 by reading its source; none of the three is a reason to upgrade.
- **If you do not answer:** nothing is filed.

### D16. A crash at bases where no number can be nice (found 2026-11-19; not part of the middle-out work)

- **What it is:** at every base that leaves 3 when divided by 4 (43, 47, 63, 67, …) no number can be nice. The
  CPU nice-only search builds an empty table for such a base and panics at its first lookup
  (`stride_filter.rs:165`, "index out of bounds") unless the leading-digit filter has already rejected the whole
  field. Shown with today's client against a local stub serving a real base-43 field (id 49999): exit 101,
  nothing submitted. `--gpu` is not affected (it answers such bases before building a table). `niceonly
  --validate` is not affected either (the client refuses that combination outright); **an earlier message of
  mine said validate "may crash about half the time": that was wrong.**
- **Can production hit it today? No.** The database's bases of this kind (15, 19, 23, 27, 35, 39, 43, 47) are
  all fully checked, and none above 50 was ever inserted. It needs a nice-only field of such a base, which only
  appears if one is inserted (the insert script does not refuse them).
- **Fix ready:** branch `pr/stride-empty-residues` on the fork: one guard, two tests, a changelog line (about 60 lines).
  The search then reports such a field searched with no numbers, which is the truth.
- **Decide:** may I open it as a small pull request? I read your hold as covering the middle-out series only,
  but you wrote "hold the PRs", so I am not opening anything new without your word.
- **Recommendation:** yes. **If you do not answer:** it stays a branch.
- **Review status (2026-11-19 20:45 UTC):** independently reviewed and the review's two small fixes applied
  (branch head `82108efb`, two commits). The reviewer's findings: the guard is correct and can only turn a panic
  into an empty result; no nice number exists at any base it covers (bases 4 and 5 are covered too: checked by
  brute force); `just lint` and the suites CI runs pass. Description drafted: `G2/STRIDE-EMPTY-PR-BODY.md`.

### D17. A short window on demoux, when convenient (new 2026-11-20; nothing waits on it)

- **Why:** three things are predicted for your card and not measured there: (a) the cleaned branch at base 64
  (×4.79 was measured just before the cleanup; on an RTX 3080 the cleanup and everything since changed nothing);
  (b) base 65 with the wide kernel as fitted to the card on 2026-11-20 (3.02 fs measured before; 2.4–3.0
  predicted); (c) the stage profile for tops and parents at the card's operating point (the one I have was taken
  with the card idling and reads too high).
- **What it takes:** about 45 minutes with the production client stopped by you, as on 2026-11-19; I use the
  window only for these three and clean up.
- **If you do not answer:** nothing runs there; the numbers stay labelled as predictions.

## C. Operations

### D14. Rented-card budget

- My cap is $30 a month; November is at $22. The build uses $1–2.50 a day (builds and device tests cannot run
  on ivory: 4 cores, nearly full disk).
- **Recommendation:** $45 for November. **If you do not answer:** I stop renting at $30 (about four more days)
  and continue offline only.

### D15. Disk on ivory

- 4–5 GB free. 7.7 GB is build output in two worktrees of other sessions whose PRs merged on 2026-11-18
  (`gpu-probe-msg`, `nicemark-repin`); 4.9 GB is the uv cache. Not mine to clear without your word.
- **If you do not answer:** I leave them and keep builds off ivory.

## What happens next if you say nothing

1. Done on 2026-11-19: the first two pull requests (coordinate; CPU reference) cut from the cleaned tree,
   independently reviewed (including mutation testing) and fixed: branches `pr/midout-field-coordinate` and
   `pr/midout-cpu-ref` on the fork.
2. **Nothing is opened from this work until you say so** (your hold of 2026-11-19). Meanwhile I keep working
   on the branch. Done on the evening of 2026-11-19: the review's changes carried back into `dev/mo-clean`
   (head `c2152084`; every test tier re-run; kernels' generated code and speed unchanged). Done on 2026-11-20
   (head `10ddbf17`): the CPU spot check on several threads and on at base 65; the wide expansion a third
   cheaper (base 65 −10 % on an RTX 3080); the wide kernel fitted to your card offline. Next: a test of wider
   words per lane, bases 68–70.
3. Nothing touches the server, the fleet, or the default client's behaviour.
