# A design document and a process map of the middle-out join, for the maintainer (brief, 2026-11-19 17:50 UTC)

You are a technical writer and engineer. Work alone (do not start subagents), on this machine only (ivory),
**reading the code, changing none of it**. **Hard stop 21:30 UTC.**

## Who it is for, and why now

The maintainer of the "nice" project (one person; wrote most of the client and server; reviewed the current
overlap join in depth) wrote today: *"Hold the PRs for now, I want to take some time to dig in to your design
and the decisions doc."* and earlier: *"I check this chat infrequently and only read the last few messages, so
in general you'll need to keep in mind I don't have all your context."* They approved building a redesigned
nice-only GPU join (the "middle-out join") two days ago and have seen none of its code. About 13,000 lines
exist on a fork branch. They will now sit down to understand it.

When they reviewed the overlap join (pull request #178) they liked an **interactive process map** very much,
and said they would reuse the format: read `~/projects/nice/scratchpad/2026-10-process-map/README.md`, open
`interactive/niceonly-map-pr178-cfbf10b.html` (and `static/`, `tools/`, `screenshots/`) and study how it is
made: columns per path, colour by layer, shape by role (decision, loop, cached, kernel), a highlight colour for
what is new, time-share bars, a click panel that gives *why it exists, how it connects, what it costs, and
file:line*, and spotlight toggles. "They could point at any piece and see why it exists and where its code
lives."

## What to produce, in `~/projects/nice/scratchpad/2026-11-midout-design/`

1. **`DESIGN.md`**, the document they read first. It assumes they know the project and the overlap join, and
   nothing of this work. Not a history; a description of what is there and why. Aim for 400–600 lines:
   - **The idea in one page**: what the overlap join does today, what the middle-out join changes (the unit of
     work is every n sharing five middle digits; tops and bottoms built once for a far wider span; bit-sliced
     pairing), and why that is faster, with one worked picture of the digits of n.
   - **The pipeline, stage by stage**, for one field: what comes in, what goes out, where it runs, what it
     costs (measured ms per slice on the RX 9070 XT and on an RTX 3080, and its share), and which check guards
     it. Include the data that passes between stages (records, lists) at the level the code documents them.
   - **What a field is** (digits 5–7, a range of a per-base renumbering), what that commits the project to and
     what it leaves free, with the corrected statement on re-cutting (only between bases).
   - **How it knows the work ran** (the execution accounts, the two conservation laws, the sampled CPU slice),
     what each catches and what nothing catches.
   - **The design decisions inside the join**, each as: the decision, the alternatives that were tried or
     priced, the numbers, why this one. At least: the shape (f0 4, k 10) and why not others; five middle digits
     as the slice key; tops on the device and their hierarchy; parents shared across digit 8; chunks of 64 and
     the common-mask skip; the bit-sliced pairing against table lookups; the record format and the expansion;
     where the prefilter sits; one narrow and one wide device path instead of a generic one; the per-stage
     accounts instead of a retry; a local coordinator instead of a server change.
   - **What is measured, and where**: one table (card, base, end to end against v3.4.8's join, exactness
     evidence), each number with its date and conditions; and what the earlier, wrong ratios were and why.
   - **What is not done or not known**: honest list (Metal never run; bases 68–70 partly; the cleaned branch
     not re-run on the RX 9070 XT; the wide path untuned there; no server design chosen; the sampled check does
     not fit base 65; and so on).
   - **Where the code is**: a file map of `common/src/midout/` and the client and script files, with sizes and
     one line each; which branch; how to run it on one machine (the coordinator and client command lines).
   - Every claim labelled **measured**, **proven**, or **judged**; no reference to internal step names,
     agents or notes the reader has not got: where a detail matters, state it; where a source helps, give the
     path as "for the long version".
2. **An interactive process map**, `interactive/midout-map.html`, one self-contained file in the format of the
   #178 map (reuse its tooling and style): the whole path of one field from claim to submit; a column for
   today's overlap join beside it where the stages correspond, since the reader knows that one; colour by where
   it runs or by origin (reused from production, new); shape by role; bars for time share (RX 9070 XT numbers,
   with the RTX 3080's in the panel); the click panel with *why, how it connects, cost, the check that guards
   it, file:line*; spotlight toggles such as "what runs once per field / per 64 slices / per slice", "where
   each execution check is produced and compared", "base-64 path against the wide path", "what a field fixes".
   File and line references must point into the cleaned branch (`dev/mo-clean`, head `5a048669`, worktree
   `~/projects/nice/.worktrees/midout-clean`): check every one.
3. **A static, simplified version**, `static/midout-overview.svg` (and a PNG): high-level labels, no line
   numbers, one cohesive picture that fits a screen, for the top of `DESIGN.md`.
4. `README.md` in that directory: what the three things are, how they were made, how to regenerate.

**Verify what you make**: render the HTML and the SVG in the pre-installed Chromium through Playwright
(`require('playwright')`, `chromium.launch()` with no options), click through several nodes and toggles, take
screenshots into `screenshots/` (deviceScaleFactor 2 for ones a person will look at), and look at them. A map
that does not render or whose panel is empty is not delivered.

## Sources (all under `~/projects/nice/scratchpad/2026-10-research-program/` unless a path is given)

`DECISIONS.md` (the decisions the maintainer is being asked; do not duplicate it: link to it),
`G2/RESULTS.md` (the original design and its Amdahl tables), `G2/REVIEW.md` (the first adversarial review),
`G2/BUILD-NOTES.md` (the build, long: §2 interface, §3 decisions, §9–§14 the steps), `G2/CLEAN-NOTES.md`,
`G2/AUDIT-MO.md` (the soundness audit), `G2/fs/REVIEW.md` (the field-structure review; note that its claim
about re-cutting fields was later found false as stated: `DECISIONS.md` D2 has the corrected wording),
`G2/BUILD-NOTES-CLIENT.md` (the coordinator and client route), `G2/BUILD-NOTES-WIDE.md`, `G2/PR-PLAN.md`,
`G2/MAINTAINABILITY.md`, `G2/PR12-REVIEW.md`, and `EXPERIMENTS.md` entries G2.7–G2.11, MO.1–MO.15, FS.1,
SRA.0–SRA.5 for every number (each entry says measured or derived and where the raw data is). The code is
the authority where notes disagree: `~/projects/nice/.worktrees/midout-clean` (its module docs now carry the
stage table and the data layouts). The overlap join for the comparison column:
`~/projects/nice/common/src/cubecl_join.rs`, `overlap_join.rs` at `origin/main`.

Numbers to use for the headline (all measured on 2026-11-19 unless noted): RX 9070 XT, base 64: 0.99 fs per
admissible n against v3.4.8's 4.76 fs, ×4.79, exact at 64 lanes (trunk `66259bb0`, before the cleanup); stage
profile there (ms per slice): main kernel 2.607, expansion 0.356, check 0.112, whole slice 4.312, tops and
parents measured off the operating point (say so); RTX 3080 at a 240 W cap, base 64: 1.62 fs against 6.62,
×4.09, and after the cleanup 1.627 against 1.624 at the trunk; base 65 on the 3080: 3.47 fs; base 65 on the
RX 9070 XT: 3.1 fs (untuned there).

## Rules

- ivory only; read-only on every repository and worktree; no builds beyond what Playwright needs; no rented
  machines; no production API; no pushes. Write only under `~/projects/nice/scratchpad/2026-11-midout-design/`.
  Check `df -h /` before writing anything large (keep screenshots modest); `/tmp` is small.
- Plain words. Define each term where it first appears (slice, top, bottom, parent, child, chunk, probe,
  record, quantum). No internal labels ("step 5L", "G2", "MO.9"), no agent or model names.
- Do not smooth over what is uncertain or was wrong. The reader will check.

## Deliverables (by 21:30 UTC)

The four items above, verified by screenshots, and a report to me of at most 25 lines: what exists, what you
could not verify, any contradiction you found between the notes and the code.
