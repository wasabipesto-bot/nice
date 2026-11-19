# Open decisions for the maintainer (kept current; last updated 2026-11-19 15:10 UTC)

This is the one document to read if you have ten minutes. It assumes you have read nothing else. Each
decision says what I will do if you do not answer. To answer, reply in the chat with the numbers, for
example: `D2 a, D3 yes, D5 yes hidden, D15 45`.

Paths below are relative to `~/projects/nice/scratchpad/2026-10-research-program/`.

## 0. Where things stand, in fifteen lines

**The middle-out join** is the redesigned nice-only GPU join you approved on 2026-11-18. Idea: today's overlap
join pairs top prefixes of n with bottoms inside a contiguous range of n. The redesign makes a unit of work
("slice") the set of all n that share five *middle* digits (positions 4–8), so tops and bottoms are each built
once for a far larger span and paired with a bit-sliced kernel.

| | state on 2026-11-19 |
|---|---|
| code | branch `dev/mo-clean` on the fork (`wasabipesto-bot/nice`): the development branch after a cleanup for review (done 2026-11-19: prototype leftovers removed, layouts documented, tests in tiers CI can run, the kernels also passing through WGSL); about 13,000 inserted lines, no PR yet; the first two PRs (no GPU code) are being cut |
| speed, base 64, RTX 3080, end to end against v3.4.8's join, same session | **×4.09** (1.62 fs against 6.62 fs per candidate) |
| speed, base 64, RX 9070 XT (demoux), end to end against v3.4.8's join, same session | **×4.79** (0.99 fs against 4.76 fs per candidate), measured 2026-11-19 at 64 lanes; exact on every slice and field tried; the client route also ran there against a local coordinator (12 fields). At that speed base 64 on that card alone is about 55 days instead of about 266 |
| base 65 (needs masks wider than 64 bits; production has no join there at all) | exact on a GPU; 3.47 fs per candidate, about half an RTX-3080-year for the whole base |
| exactness | CPU reference equals brute force on whole bases 10–25; GPU equals the CPU reference on 1,073 real base-64 slices; an independent audit found no loss path on a healthy card |
| failure handling | every stage proves it ran (what ran = what was queued), two conservation checks, and one random slice per field recomputed on the CPU; a dropped kernel, a failed allocation or a wrong prefilter stops the field instead of reporting it empty |
| how it runs today | a local coordinator script plus an off-by-default client flag; **no server, schema or API change exists or is proposed yet** |
| what a field is | all n sharing digits 5–7 (base 64: 262,144 fields of 2^57 n; in the fields table it would still be a range, of a renumbered coordinate) |

What it is not yet: reviewed by you, cleaned for review (in progress today), or connected to the real server.

Earlier ratios I reported (×4.6 to ×5.5) were kernel timings plus an assumption that was four times too low.
×4.09 is the honest end-to-end number on NVIDIA.

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
  page at the top) proved that any choice within digits 4–8 can be re-cut later without redoing any search,
  and that today's overlap join could still search such fields (about ×1.9 slower). It recommended fixing
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
- **Recommendation:** the three tiers; not on the Metal job for now, and the client flag refuses to run on
  Metal until someone has checked it on Apple hardware.
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

- **Options:** a. open each as soon as it is cleaned and independently reviewed (PRs 1 and 2 are CPU-only and
  could open within two days); b. hold everything until the whole first series is ready, for one sitting.
- **Recommendation: a**, never more than two or three waiting on you at once.
- **If you do not answer:** a.

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

1. Today: the first two pull requests cut from the cleaned tree (coordinate; CPU reference), then an
   independent review of each.
2. Tomorrow (2026-11-20): I open those two. The device PRs follow over the next days, at most two or three
   open at once.
3. Nothing touches the server, the fleet, or the default client's behaviour.
