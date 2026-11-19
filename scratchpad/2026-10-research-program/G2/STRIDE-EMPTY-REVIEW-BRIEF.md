# Independent review of a small production fix before it is offered as a pull request (2026-11-19 20:15 UTC)

You are an independent reviewer. You did not write this code. Work alone (do not start subagents).
**Hard stop 21:15 UTC; the box destroys itself at about 21:55 UTC.**

## What you review

Branch `pr/stride-empty-residues` on the fork of the "nice" project (an exhaustive search for numbers whose
square and cube together use every digit of a base exactly once): one commit, `3701a353`, on upstream main
`974d7194`; worktree `~/projects/nice/.worktrees/stride-empty` on ivory (this machine); 48 added lines in
`common/src/stride_filter.rs` and `CHANGELOG.md`. Drafted description:
`~/projects/nice/scratchpad/2026-10-research-program/G2/STRIDE-EMPTY-PR-BODY.md`. The author's notes:
`…/G2/CARRYBACK-NOTES.md` §6 and §7 (§7 corrects a claim in §6).

The claim: at a base with no valid residue (4, 5, 7 and every base ≡ 3 mod 4) no number can be nice; the CPU
nice-only search built an empty stride table and panicked at its first lookup whenever the MSD filter kept any
part of the field; the fix makes the masked walk return no numbers for an empty table before any lookup; a
table with residues takes exactly the path it took before; the GPU paths already answer such bases first.

## Decide: ready to offer, ready with fixes (list them), or not ready

Try to break it, in this order:

1. **Is "no number can be nice at these bases" proven, not assumed?** Derive it yourself from the residue
   filter's definition in the code (`common/src/residue_filter.rs`), and check that an empty table can arise
   **only** when no nice number exists: could `StrideTable::new` come out empty for a base that does have valid
   residues (the LSD filter at k = 1, 2, 3 emptying a table the residue filter does not; the modulus limits)?
   The author lists bases 4 and 5 as empty "by the LSD filter": is returning nothing sound there too (are there
   nice numbers in base 4 or 5 by brute force)? A silent empty answer where a nice number exists would be far
   worse than the panic it replaces.
2. **Every path to the lookup.** `git grep -n "first_valid_at_or_after\|valid_residues\["` on the branch: for
   each caller outside tests (the walks in `stride_filter.rs`, `client_process_cuda.rs`, `cubecl_backend.rs`,
   `gpu_niceonly.rs`), is it reachable with an empty table, from which client command and backend
   (`--gpu-backend` values included), and what happens? The author ran the real client on the CPU, on CUDA (the
   default backend) and on wgpu/lavapipe; check the hand-written CUDA backend and any other selectable route by
   reading, and by running if the binary on the box allows it.
3. **No behaviour change where residues exist.** The guard is one `is_empty` test at the top of `walk_masked`:
   confirm nothing else changed, and that the counters a caller reads (not only the returned numbers) are the
   same as before for a non-empty table and are sensible for an empty one (what does the client submit for the
   field: is "searched, no numbers" the truth for it?).
4. **The test.** Does it fail without the guard for the stated reason, is it fast in debug and release (time
   it), does it depend on nothing outside the repository, and does it cover what the description says?
5. **Standing alone:** in your own clone and target directory on the box: `just lint`; the whole suite in the
   forms CI uses (the workspace run and `nice_common --features gpu --lib`).
6. **The description and the changelog line** against the code and against the maintainer's rules: plain
   words; accurate; says what a GPU device should expect; **no reference to any research program, notes,
   scratchpad path, agent, assistant or model name, and no private host names**; the changelog line one short
   sentence.

Do not rewrite; list. Do not review anything else on the fork.

## Machines and rules

- **ivory**: reading and notes only; do not build here.
- **One rented box, handed to you for this task:** `ssh -p 26994 root@ssh5.vast.ai` (16 threads visible with a
  CPU quota of about 5; an RTX 3080; the toolchain, `just` and lavapipe are installed; the author's clones are
  under `/root`: use your own clone and target directory, fetched from
  `https://github.com/wasabipesto-bot/nice.git`). Production hosts are mapped to 127.0.0.1 and ::1 on it:
  check that first (`getent hosts api.nicenumbers.net data.nicenumbers.net`) and never contact the production
  API. Never create or destroy instances; never use another machine. Leave it running and idle.
- **You change nothing on the branch.** Experiments live in your scratch clone on the box. No pushes, no pull
  request.

## Deliverable (by 21:15 UTC)

`~/projects/nice/scratchpad/2026-10-research-program/G2/STRIDE-EMPTY-REVIEW.md`: the verdict in the first line;
findings ranked (must fix before offering; should; note) with file and line and the evidence; what you ran
yourself and its result; corrections to the description. Then a report to me of at most 15 lines.
