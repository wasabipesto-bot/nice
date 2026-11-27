# Bring the design document and its map to the branch as it is now (brief, 2026-11-27 06:00 UTC)

You are a technical writer who reads Rust. Work alone (do not start subagents), on this machine (ivory),
**reading code and editing documents only: no builds, no code changes, no pushes.** **Hard stop 09:30 UTC.**

## The documents and their reader

`~/projects/nice/scratchpad/2026-11-midout-design/`: `DESIGN.md` (about 780 lines) and
`interactive/midout-map.html` (one file; every stage of the pipeline with its cost, its check and `file:line`
references), `static/midout-overview.{svg,png}`, `tools/check_refs.py`. They describe the "middle-out join", a
redesigned GPU search join for the "nice" project (a distributed exhaustive search), **for the project's
maintainer, who will decide from them whether and how the work is merged**. The maintainer knows the project and
today's production join, has seen none of this work's history, reads carefully, and dislikes padding, jargon
and overselling. Every claim in the document carries a label: **[measured]** (with date and where the raw data
is), **[proven]**, **[judged]**. Keep that discipline exactly; a number you cannot trace to a file gets no place.

## What changed since the document's code references were last checked

The document and map were written against the fork branch `dev/mo-clean` at `66305ada`. The work has moved to
**`dev/mo-mode`, now at `0b6e22e1`** (worktree `~/projects/nice/.worktrees/mo-mode`; 32 commits on `66305ada`:
`git log --oneline 66305ada..0b6e22e1`). In those commits:
- the hidden development flag `--midout-coordinator` became a client mode `nice_client midout` that speaks the
  endpoint shapes of a server proposal (`…/2026-10-research-program/G2/PROPOSAL-B.md`, not yet approved by the
  maintainer; no server code exists), with a development server in Python for tests
  (`G2/MODE-NOTES.md`, `MODE2/REVIEW.md`, `MODE2/FIX-NOTES.md` under `~/projects/nice/scratchpad/2026-10-research-program/`);
- the tests were made to pass the whole CI matrix; the Metal refusal became a warning;
- the wide path's result reads were batched (`B65/RESULTS.md`, `B65/READS-RESULTS.md` there).
Measurements since then are recorded in `…/2026-10-research-program/EXPERIMENTS.md` (entries WIN3.1, OWN.1,
YIELD.1, B65.1, B65.3, MODE.1–MODE.3: read these; they are the source for any number you add) and several
paragraphs were already added to `DESIGN.md` by hand on 2026-11-25/26 (search it for those dates): keep them, fix
their placement if they sit awkwardly.

## The job

1. **Re-base the document on `dev/mo-mode` `0b6e22e1`:** the header, every statement about which branch and head
   the text describes, §10 ("Where the code is, and how to run it": the file table with line counts, the
   commands), §7 (tests: the tiers, what CI runs, the end-to-end tests of the client mode), and the section
   on the client route and coordinator (§6.11 or wherever it now sits): rewrite it for what exists now (the
   mode, its option table, the wire as built, the stop rule, the development server and its audit, the review
   and what it found), briefly, pointing to the notes for detail. Where the old text described the hidden flag,
   replace it; do not leave both.
2. **§9 ("What is not done, or not known"):** make it true as of today. Known changes: Metal ran on an M4 and
   the refusal is a warning; the project's WGSL lint for the old Apple division defect **does not cover the
   middle-out kernels** (found 2026-11-26; they were linted once by hand); base 65's slow run on the RX 9070 XT
   has a likely cause and a fix that is not yet confirmed on that card; no real field has gone through a real
   server (there is none); the server proposal's open questions. Remove items that are done.
3. **A short section on the choice of base** already exists as a paragraph in §8; make sure §1 ("The idea in one
   page") says in two or three sentences that base 65 is most of what remains within reach, since that changes
   how a reader weighs the wide path.
4. **The map** (`interactive/midout-map.html`): point `tools/check_refs.py` at the `mo-mode` worktree (it reads
   the middle-out references from a worktree path near its top: change that path, and its docstring) and fix
   every reference it reports until it prints 0 bad; update the map's sub-title (branch and head), the panel(s)
   on the client route and coordinator to the mode as it is now, and any stage cost that the entries above
   supersede (say the date and device with each number, as the map does elsewhere). Do not restyle anything.
   The static overview needs no change unless it names the hidden flag (then say so in your notes; do not
   regenerate images).
5. Keep the document's length about where it is: for everything added, look for what it replaces.

## Rules

- You change only files under `~/projects/nice/scratchpad/2026-11-midout-design/`. Another engineer is committing
  to branches cut from `dev/mo-mode` today: read the code at `0b6e22e1` (the `mo-mode` worktree is at that commit
  now; if it moves, use `git show 0b6e22e1:<path>`), and do not touch the worktree.
- No reference to assistants, agents or "the research program" inside `DESIGN.md` or the map (they are written
  as the work's own documentation); paths into the notes directory are fine.
- If two sources disagree about a number, do not pick one silently: list it in your notes.

## Deliverable (by 09:30 UTC)

The updated `DESIGN.md` and map; `check_refs.py` printing 0 bad against `0b6e22e1`; and
`~/projects/nice/scratchpad/2026-10-research-program/DOC/NOTES.md`: what you changed section by section, every
number you added with its source, disagreements found, what you were unsure about and left. A final report to me
of at most 12 lines.
