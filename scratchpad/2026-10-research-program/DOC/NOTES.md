# Notes: DESIGN.md and the map brought to `dev/mo-mode` `0b6e22e1` (2026-11-27)

Brief: `DOC/BRIEF.md`. Files changed, all under `~/projects/nice/scratchpad/2026-11-midout-design/`: `DESIGN.md`,
`interactive/midout-map.html`, `README.md`, `tools/check_refs.py`, `tools/print_inline_refs.py`. Nothing else touched;
the worktree was only read (`git show 0b6e22e1:…`, `grep`, `wc`, `python3 scripts/midout_coordinator.py --help`).
No build, no container, no screenshot run.

**Result:** `python3 tools/check_refs.py interactive/midout-map.html` → `worktree head 0b6e22e1 | origin/main
fdbe07d3`, **89 refs, 0 bad** (14 bad at the start, all in the client and coordinator nodes). Both script blocks of
the map pass `node --check`. `DESIGN.md` 790 → 810 lines.

## 1. What changed, section by section

**DESIGN.md**
- Header: describes `dev/mo-mode` `0b6e22e1`, worktree `mo-mode`; the italic "read the hidden flag as…" paragraph
  replaced by two sentences (mode built §6.11; server a proposal; no server code).
- §1: new paragraph "Why the wide path matters as much as the narrow one" (73 % / 73 % / ×2.7, pointing to §8's
  base paragraph). "Where it stands" rewritten shorter: all devices in one paragraph, base 65 on the RX 9070 XT
  pointing to §9, the real client on real cards pointing to §6.11.
- §4: removed the "at base 65 the sampled check was off until 2026-11-20" bullet from "What nothing catches" (it is
  not a detection gap any more; §9 keeps the CPU-dependence item). "route waits" → "client waits" was in that bullet.
- §6.11 rewritten: "A local coordinator instead of a server change" → "The client mode `midout`, and a development
  server until there is a real one": alternatives (C first behind a hidden flag, now B), the mode and its options
  (short; full table pointed to `G2/MODE-NOTES.md` §1), the stop rule and retries, the development server and its
  two harness rounds, the review and what is fixed, the runs on real cards, why. The hidden-flag text is gone.
- §6.13: the word-width / shared-loads part compressed (same numbers).
- §7: tier bullet rewritten (`mod.rs:34–60`, the client's 22 tests, four end to end); new CI bullet.
- §8: two rows added (RTX 3060 base 65 at `f61cf79e` against the trunk; reads batched at `0b6e22e1`); the row
  "RX 9070 XT, b64, client route" (2026-11-19, the old flag against the old coordinator) deleted, as it measured
  the code the mode replaced; the "prefilter adds 2.6 ms" bullet compressed; the branch-size bullet rewritten
  (it read "against `origin/main` at `5a048669` 13,939 at …", garbled) and extended to `0b6e22e1`.
- §9: new first item "No field has gone through a real server" (proposal §7 five sub-decisions, §9 eight
  questions, review C5, what only a server can test, result held in memory). Base-65 item rewritten: the
  read-batching cause and fix, not confirmed on the RX 9070 XT, ranked further gains. Metal item rewritten: exact on
  the M4, refusal now a warning, not checked (other GPUs, older macOS, MSL), **the WGSL lint does not cover the
  middle-out kernels**. Removed: "The cleaned branch ran on the RX 9070 XT" (done; its 6–10 % slowdown folded into
  the base-65 item), the old "No server design is chosen" item (coordinator, `--reissue-after`, the four proposed
  client changes: "already accepted for my own claim" is now `already_recorded`; the spool to disk is not built
  and is covered by the new item's "held in memory only"; longer claim retries and giving a claim back are proposal
  questions §9.7 and the release endpoint, listed there), the old Metal-refusal text. "Smaller": added the
  software-renderer refusal not on the branch and the Vulkan exit segfaults. `route.rs:36–58` → `:33–56`.
- §10: branch, head, commit counts, diff size; the file table re-counted at `0b6e22e1` (`wc -l` of `git show`,
  `git diff --numstat be9cc923 0b6e22e1` for partial files); new rows (`midout_route/tests.rs`, `support/args.rs`,
  `README.md`); the commands now `--features gpu` and `nice_client midout --api-base …` plus the audit; the long-
  version list adds `MODE-NOTES.md`, `MODE2/REVIEW.md`, `MODE2/FIX-NOTES.md`, `B65/RESULTS.md`, `B65/READS-RESULTS.md`.
- The paragraphs added by hand on 2026-11-25/26 are kept: §8's base paragraph and 3060/1060/M4 rows unchanged;
  the §1 sentence on 2026-11-26 devices folded into the rewritten "Where it stands"; the §6.13 run of 2026-11-25
  kept (compressed); the §9 Metal and B65 sentences replaced by the rewritten items (same facts).

**Map**
- Sub-title, the data comment and the panel's repo note: `dev/mo-mode` at `0b6e22e1`, worktree `mo-mode`.
- Node `coord`: "local coordinator" → "development server (script)", its endpoints, checks, both harness rounds, the
  route-cost line replaced (see §2 below). Node `claim`: new refs, the production-host refusal replaced by the
  test-build loopback refusal, 404, 204 wait, Metal warning, claim ahead. Node `submit`: background submission, one
  in flight, retries, signals, new refs. Node `guard`: `field_of_claim_body`, socket-free test, `--legacy-path`.
  Node `route`: `search` ref 87 → 88, "route switches base" → "mode", wide note with the 3060 base-65 profile.
- Frame and legend labels: "Coordinator and client route" → "Development server and client mode"; "coordinator /
  wire" → "server side / wire". Edge label "next claim" → "next field". No style touched.
- **Every inline `gpu_wide.rs:N` in the wide notes was wrong already at `66305ada`** (they matched an older head;
  `check_refs.py` reads only the `refs` arrays, never the text). All 21 fixed against `0b6e22e1` and checked by a
  script that prints each target line. Wide notes "off by default at 65" (×2) were wrong since 2026-11-20 (the
  sampled check is on at 65, `route.rs:74–78`): fixed. `wide_kernel` "not yet run on that card" → its half-clock run.
  `finish_group` wide note: the batched read. Mutation-test note aligned with DESIGN §7 (2 survive since 11-22).
- `README.md` (folder): branch/head, lane wording, ref count (89 refs, 0 bad).
- Tools: `check_refs.py` and `print_inline_refs.py` point at `~/projects/nice/.worktrees/mo-mode`, docstrings say
  `dev/mo-mode`.

## 2. Numbers added, with sources

| number | where | source |
|---|---|---|
| 73 % of reachable probability and of remaining time at base 65; ×2.7 worth of a wide-path gain | §1 | EXPERIMENTS YIELD.1; `YIELD/yield.txt` |
| RTX 3060 3.23 fs ×4.1, M4 12.9 fs ×3.9, GTX 1060 8.77 fs (moved into §1) | §1 | OWN.1 (already in §8) |
| 6 fields, 61 s a field vs 59 s bench | §6.11, map `coord` | OWN.1 |
| M4 three fields 235.4 / 236.9 / 234.6 s; SIGTERM finished in ≤ 1 s | §6.11 | MODE.3; `MODE2/FIX-NOTES.md` §2 |
| 2,514 fields coordinate port; 1,500 runs 0 failed; 300 stress 1 failed (seed 50081); defect a38c9f4d | §6.11, map | MODE.1; `G2/MODE-NOTES.md` §4–5 |
| review: 2 rank A, 7 rank B, 7 rank C; fixed A1 A2 B1–B7 C1–C4 C6 | §6.11 | `MODE2/REVIEW.md`; `MODE2/FIX-NOTES.md` §4 |
| outage ≈ 8.5 min loses the last field; submit retry 3600 s | §6.11, map | REVIEW B3; FIX-NOTES §4 (`MIDOUT_SUBMIT_RETRY`) |
| 22 client tests, 4 end to end | §7 | counted in `client/src/midout_route/tests.rs` at 0b6e22e1 |
| CI 16 jobs run 45777405453; device run 45777409152; 231,506 threads | §7 | MODE.3; FIX-NOTES §1, §6 |
| b65 RTX 3060 CUDA 6.30/6.44, SPIR-V 6.32/6.36, trunk 6.98/7.12, 7.33/7.25 | §8 | B65.1; `B65/RESULTS.md` §2 |
| reads batched: 6.191/6.172 quiet (6.381 before), 6.35 under load (14.25 before) | §8, §9, map | B65.3; `B65/READS-RESULTS.md` |
| 29,600 vs 260 reads per field; ×2.3 under load, card 24 % busy; CUDA +3 %; head 10–13 % faster than trunk; narrow −5 % | §9, map | B65.1 |
| stage profile b65 CUDA 10.8/11.9/58.3/18.5/0.6 % of 23.81 ms; gains ~4 %, ~5 %, up to 10 % | §9, map `route` | B65.1; `B65/RESULTS.md` §4–5 |
| 17,822 insertions, 24 deletions, 27 files; 32 commits on 66305ada; line counts | §8, §10 | `git diff --shortstat/--numstat be9cc923 0b6e22e1`, `git log`, `wc -l` (my reads) |

## 3. Disagreements found (not resolved by picking one)

1. **Base 65 through Vulkan/SPIR-V on the RTX 3060**: under six busy threads B65.1 gives 14.62 fs (head
   `f61cf79e`), B65.3's "before" 14.25 (`4fff25e7`); quiet 6.34 (B65.1) against 6.381 (B65.3). Different heads and
   sessions; the document quotes each with its own head. Not a contradiction I can resolve.
2. **"The HTTP does not hold the card"** (OWN.1) rests on 61 s a field through the mode against 59 s in the bench
   (+3 %); the 366 s total is not split into start-up and per-field. I quote the two numbers and drop the claim.
3. **The README's `auto` command "would die on the RX 9070 XT and the M4"** (REVIEW B2, by reading); FIX-NOTES
   §2 confirms the death on the M4 only. DESIGN says the M4.
4. **README of the folder said 87 refs**; the checker counted 88 at the start (89 now).
5. **DESIGN's old branch-size line** said "against `origin/main` at `5a048669`"; `git merge-base` gives `be9cc923`
   for every head listed, and the counts (13,525 … 14,875) match against `be9cc923`. Rewritten accordingly.
6. **The checker's `origin/main`** is now `fdbe07d3`; the map still names `974d7194` for the overlap lane. Its refs
   all pass at `fdbe07d3`; I left the lane's label (written against `974d7194`) unchanged.
7. `G2/MODE-NOTES.md` §1 says `--telemetry` has no effect; FIX-NOTES C4 (`ddc0a96b`) added a warning. Used the later.

## 4. Unsure, or left

- **"A searched field's result is held in memory only"** (§9) is [judged by reading]: no spool or disk write in
  `client/src/midout_route.rs` (grep for spool/disk/persist: none). The proposed spool of the old §9 is not built.
- **The static overview** (`static/midout-overview.{svg,png}`, `static/make.py`) does not name the hidden flag, but
  says "claim from a local coordinator · not the production API" and "submit to the coordinator → next claim":
  both out of date. Not regenerated, as the brief says.
- **`screenshots/`** show the old panels; not re-taken (the harness runs in a container: not run).
- **The map was not rendered**: the edits keep each node's line count of its `s` captions and its size; the frame
  label "Development server and client mode" is about as long as the old one. JS parses. A visual check is left.
- The CI statement in §7: the last two commits (`457ad99a`, `0b6e22e1`) have no CI run recorded anywhere I read;
  `just lint` on `0b6e22e1` and the RTX 3060 wide tests are from `B65/READS-RESULTS.md`.
- DESIGN is 20 lines longer (810 against 790): §6.11, §7's CI and §9's server item are new content; cuts in §1,
  §4, §6.13, §8 and §9 did not cover all of it.
- The two RX 9070 XT gaps (base 65 since the fit; whether the fix holds there) are stated as open; nothing in the
  sources measures the fix on that card.
- Tooling: nothing was denied.
