# Decided (a log; the open decisions are in `DECISIONS.md`)

Each entry: what was asked, the maintainer's answer in their words, and what I am doing about it.
The decisions document as it stood with their notes on 2026-11-25 is kept as `DECISIONS-2026-11-25-with-notes.md`.

## 2026-11-25 (answers written into the decisions document)

| what was asked | answer (verbatim) | what follows |
|---|---|---|
| How much of the middle-out join goes into the first series of pull requests | "Already noted, do not open PRs for this work until I have gone through the design." | Nothing from the middle-out work is opened until you say. |
| Which definition of a field | "I'd avoid locking this in until we are closer to merging." | The coordinate stays a parameter; nothing downstream may assume digits 5–7. |
| The client flag and coordinator script | "The new mode would sit alongside detailed and niceonly, with a new claim endpoint on the server. Not hidden from --help." | The target is a `midout` mode with its own endpoint; the hidden flag and the local coordinator are development tools only. The client mode is being built on the fork branch `dev/mo-mode` (2026-11-25). |
| How base 64's fields reach clients | "This will be option B. This does not have the same semantics as the previous fields so it will not go in that table." | A written proposal for the new table and endpoints comes first (`G2/PROPOSAL-B.md`); no server code before your yes. |
| The guard in the ordinary client | "There should be no issue here. Detailed claims are capped and niceonly will not be dispensed past b62. A client will have to use midout mode to get fields b64+." | The guard is not needed as a separate change. |
| Tests in CI | "Same as current testing strategy. Cover as much as feasible in lavapipe and check against CPU results. Key PRs and releases get full test coverage on owned or rented cards." | As built: lavapipe tiers plus card runs for key changes. |
| A benchmark example in the repository | "Build it, this will be part of the final package." | The bench examples stay and get finished. |
| The name | "That is fine, `middle-out` / `MiddleOut` / `midout`" | Kept. |
| When to open the pull requests | "If I've already made this decision why is it in this doc?" | Decided items no longer stay in the decisions document. |
| PR #270 and its follow-up #271 | "Merged." | #271 merged 2026-11-25 03:08 UTC. |
| A `--gpu` client whose CUDA runtime cannot start | "I don't see an issue with this as long as everything is properly logged at warning or error level." | Opened as #277 on 2026-11-25: a software renderer is refused (an error when named, a warning and the next backend under `auto`). I read your note as yes to the error; if you meant "keep the fallback but log a warning", say so on the pull request. |
| 153,748 fields searched only by builds before #222 | "Keep this on list (table it), I don't want it to fall off but I don't want to spend cycles on it for now." | Tabled; kept in `LEDGER.md` (lead N2). |
| Pin known survivor and check counts in NiceMark | "The benchmark and the validation are two different functions, I'd be more comfortable putting this in validation." | The proposal is written: `T2/VALIDATION-PROPOSAL.md` (open decision 3 in `DECISIONS.md`); nothing is built before a yes. |
| A CI check for the SPIR-V atomic-store trap | "Sure, I don't see why not." | Opened as #278 on 2026-11-25. |
| Report the CubeCL loop/break defect upstream | "Even if they fix it, I assume they would not backport to 0.10 and we have already worked around. Pass." | Not filed. |
| Rented-card budget | "No change to budget." | $30 a month stays; the wrapper's last-week reserve stands. |
| Disk on ivory | "OK to clean up worktrees from merged PRs in general. Also OK to clean the uv cache in this case." | Done 2026-11-25: 19 clean worktrees of merged PRs removed (branches kept), uv cache cleared; 4.3 GB → 19 GB free. |
| The crash at bases where no number can be nice | "Proceed with this PR. PRs are allowed in general, I meant to hold the midout PRs." | Opened as #276 on 2026-11-25. Ordinary pull requests go ahead under the usual bar. |
| A short window on demoux | "I will notify when this is available." (granted the same day, 4 hours) | Used 2026-11-25, 03:48–05:53 UTC; results in `G2/WINDOW3-RESULTS.md`. Base 65 gave no result (open decision 4 in `DECISIONS.md`). |
| The Lean proof of the join, and extending it to the GPU path | "I'm not opposed to lean verifications, I think they're good but formalizing something we already have every reason to believe is correct seems low-value comapred to working on proving something new and directly useful. I would be more interested in utilizing lean to e.g. pose some falsifiable statement that would be very high-value and then working to prove/disprove it (like in the GRH case), something else along those lines." | The existing proof stays on its fork branch, unextended. No formalisation of the GPU path. Candidates for a statement worth proving or refuting are the first open decision. |

## 2026-11-26 (in the chat)

| what was asked | answer (verbatim) | what follows |
|---|---|---|
| Use of mayalaran and eventeo | "You now have primary lease on mayalaran and eventeo. … You may create a new folder within the home directory for persistence. … you have primary lease on that box as well and can boot or shutdown whenever you need it, and you can persist whatever you need inside your claude home directory." | Both are used without asking (`README.md`, "Machines"): `~/claude` on mayalaran, `~/research` on eventeo. demoux is still asked for each time. |
| The rented-card budget | "Budget: Agreed to drop to $10/mo" | `vast.py`: cap $10 a month from 2026-11-26, $2 held back in the last week. |
| Hours on eventeo | "any hours are fine, noise/heat from your tests was not noticeable in this room and I was in here the whole time" | No time-of-day limit. It still runs only while a job needs it. |
| If the owner is logged in on eventeo when a job ends, leave it on | "That sounds appropriate, thank you." | `off_if_idle.sh` keeps doing that. |
| Long GPU runs on mayalaran | "Totally fine" | No limit on run length there. |
| `strace` and `vulkan-tools` on eventeo | "Just booted and installed, please log in and see if that gives you enough info to diagnose. The shut down when done." | Diagnosed the same hour: the NVIDIA EGL library is not installed; worked around inside `~/research/vk` without root; shut down. |

