# Review brief: a skip walk for the CPU join's top certificates (2026-11-14)

You are an independent reviewer. The repository is `~/projects/nice` on this machine (ivory);
upstream is `wasabipesto/nice` (git remote `origin`), the fork `wasabipesto-bot/nice` (remote
`fork`). The project searches for numbers whose square and cube together use every base-b digit
exactly once. A search result is "no such number in this field", submitted once and never
cross-checked, so **a candidate that is wrongly skipped is the worst possible defect**. You were
not involved in writing the change; take none of its claims on trust.

## The branch

Fork branch **`exp/cpu-top-skip-squashed`**, one commit `e0bf513e` on upstream main `41b4b405`
(`git -C ~/projects/nice fetch fork exp/cpu-top-skip-squashed && git -C ~/projects/nice fetch
origin main`); about 600 changed lines in `common/src/cpu_join.rs`, `common/src/cpu_top_fd.rs` and
`client/src/main.rs`. Read the module docs of `common/src/overlap_join.rs` first (tops, partitions,
`Base::cert`), then the CPU join and its stepped top certificates on main, then the diff.

What it claims: in the CPU join, each (top prefix, partition) pair is certified on its own and
about two thirds fail, in long runs along the partition axis. When a certificate fails because
two certified digit positions hold the same digit, the branch computes a lower bound on how many
of the following partitions must fail for the same reason, and skips certifying that prefix in
those partitions. The state (a "next partition to certify" per prefix) is kept per worker thread
and used only when the thread's next partition closely follows its previous one in the same
join. The claim is that the set and order of passing tops, and therefore every result and
counter of the join, are bit-identical to main's. The author's write-up is `CPU2/RESULTS.md` in
`~/projects/nice/scratchpad/2026-10-research-program/` (the rule and its proof are §2), raw
outputs under `CPU2/raw/`.

## What to check, in order of importance

1. **The rule.** Re-derive it yourself. For a failing pair, which later blocks are guaranteed
   to fail, and why: which digits of which power are provably unchanged, and is "the certificate
   scans those positions again and finds the same repeat" true for every block in the claimed
   run, at every base and field shape the join accepts (including the first and last partitions,
   blocks clipped to a field's or slice's ends, the largest base, bases where the square and cube
   have different digit counts, and blocks whose certificate depth differs from the failing
   block's)? Try to construct a counter-example before you accept the proof.
2. **The bound's arithmetic.** The run length is computed in `f64` with margins. Is the computed
   bound always at most the true run, for every magnitude the code can see (numbers up to about
   2^76 and their cubes far beyond `f64`'s exact range)? Check each rounding step, each cast and
   the `u16` state for overflow or wrap. Write your own check against exact big-integer
   arithmetic on adversarial inputs (values just below and above a digit boundary), not only
   random ones.
3. **The carried state.** When is a prefix's "next partition" valid: same join, same slice,
   same key and prefix index, a later partition? What identifies "the same join" (the author
   uses a process-wide id), and can state from one field, slice or base ever be applied to
   another: across fields in one process, across threads, when partitions run out of order,
   when a partition is retried, when the client is interrupted and resumes? Read the change to
   `client/src/main.rs` (one scratch per worker thread instead of rayon's `map_init`) for the same
   question, and for anything else it changes about how partitions are distributed.
4. **Equivalence in practice.** Run the branch's tests and the existing CPU join tests
   (`nice -n 19 cargo test --release -p nice_common <filter>` is acceptable here: CPU-only, no GPU
   features; `CARGO_TARGET_DIR=~/projects/nice/target`; at most two threads). Then write your own
   comparison of main against the branch on fields the author did not use (other positions of
   bases 57–64, a few small bases exhaustively): passing tops, survivor and check counts must be
   identical. Say what you ran and what it covered.
5. **Everything else the diff touches:** nothing unrelated should change; performance-only
   constants (the author raised a `MAX_STEPS` from 4 to 12) must not affect results.
6. **The measurements** in `CPU2/RESULTS.md` against the raw files (`CPU2/raw/ab*-summary.txt`,
   `ab*-runs.txt`): recompute a sample. The author reports about ×1.13 at b60, ×1.14 at b62 and
   ×1.01 at b64 on one thread of this shared machine.

## Deliver

`CPU2/REVIEW.md`: the verdict first (sound as far as you can tell / sound after the listed fixes
/ unsound, with the counter-example), findings by severity with file and line, how you know,
and the fix you suggest; then what you verified and how (your own checks' code under
`CPU2/review/`); then what you could not verify. Use a worktree
`~/projects/nice/.worktrees/review-cpu2` (detached at the branch head). ivory is small and shared:
about 10 GB of disk, a small tmpfs `/tmp`, at most two threads under `nice -n 19`. Do not change
the branch, push, open or comment on a PR, start subagents, or touch any rented machine, the
fleet, the server, demoux or mayalaran. Your final message is a short summary for the program's
director.
