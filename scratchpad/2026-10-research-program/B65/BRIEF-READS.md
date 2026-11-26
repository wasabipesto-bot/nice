# Batch the wide driver's result reads (brief, 2026-11-26 08:10 UTC)

Same engineer as `B65/RESULTS.md`, same machine rules as `B65/BRIEF.md` (eventeo: wake it, source `env.sh`, power it
off with `off_if_idle.sh` at the end; nothing reaches the production API; kill only by recorded PID). This time
there is a code change. **Hard stop 11:15 UTC; report by 11:30 UTC.**

## The change

Your finding: the wide path's `finish_group` (`common/src/midout/gpu_wide.rs`) reads every small buffer of a group
with one blocking `read_one` each (about 7 per slice, 29,600 per base-65 field), while the narrow path
(`gpu.rs`) collects a group's buffers in one `read_async`; through wgpu on a contended host each read waits
milliseconds and the card idles (base 65 through Vulkan: 6.34 → 14.6 fs under six busy threads).

1. **Port the narrow path's batched read to the wide `finish_group`**: one `read_async` for the group's `cnt`, the
   tickets' `scount`, `ran`, `tstat`, `stat`, `est` and the slices' `acc`, `l5n` (whatever the wide path reads
   there today), then the same checks on the returned buffers, in the same order, with the same errors. Host code
   only: **no kernel changes, no change to any count, account or error text.** Keep it the smallest diff that
   does this; where the narrow path already has a helper, use the same shape so the two read side by side.
   Reads elsewhere that are once per field or per sampled slice (`check_slice`, `run_slice`, `nice()`) stay.
2. **Only if 1 is finished, verified and pushed with time to spare (before 10:15 UTC): look at, but do not
   necessarily build, the next step** for both paths: queueing group k + 1 before the reads of group k (so the
   reads never idle the card). Write down what it would take (which handles are per group, what the accounts
   need, what a failure in group k means for an already queued group k + 1) and what it would be worth from your
   stop-5 numbers (3.7 % quiet through Vulkan on the wide path; the narrow path's 4.9 % under load). Build it only
   if it is clearly small and safe; otherwise the note is the deliverable.

## Where and how

- Branch **`dev/mo-wide-reads`**, cut from the fork's `dev/mo-mode` as it stands when you start (`git fetch fork
  dev/mo-mode`; another engineer has been committing there today and should be done; do not push to `dev/mo-mode`
  yourself). Work in a worktree on ivory (`~/projects/nice/.worktrees/mo-wide-reads`) or directly on eventeo's
  clone, as you find quicker; commits in small named steps, pushed to `fork` only, never force-pushed or amended
  once pushed; commit trailer exactly `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; no mention of
  assistants, agents or a research program in commits or comments. No pull request, no push to `origin`.
- Builds and tests on eventeo (`~/research/scripts/build_mo.sh` and your `build_b65.sh` show how).

## Verification (all on eventeo's RTX 3060; say which runtime each ran on)

1. **Exactness and loudness, unchanged:** the wide tests of the card tier through CUDA
   (`midout::gpu_wide::tests::wide_slices_equal_cpu`, `wide_faults_are_loud`, and the `cubecl_midout_wide*` tests of
   the ordinary tier), and the same through Vulkan (the direct SPIR-V build and WGSL: `env_vulkan.sh`,
   `CUBECL_WGPU_DEFAULT_DEVICE='DiscreteGpu(1)'`). Every fault of the fault tests must still be loud **with the same
   message as before** (diff the test output against a run of the branch point's binary); the narrow tests
   (`gpu_slices_equal_cpu`, `accounts_faults_are_loud`) once, to show nothing moved there.
2. **Counts:** base-65 fields 13731 and 77777, counts equal to your earlier runs.
3. **The cells that matter, before and after in the same session:** base 65 wide through Vulkan/SPIR-V, quiet and
   with 6 busy threads; the same through CUDA; base 64 through the wide path once (no regression). Report fs per
   admissible n, the time outside device waits, "sync+reads", card utilisation and power.
   **Kill criterion: if the batched build still loses more than 30 % under six busy threads through Vulkan, the
   reads were not the whole mechanism: stop, do not tune further, and report the cells.**
4. `cargo fmt` and clippy with the feature sets the branch's lint uses for this file (`just lint` is installed on
   eventeo: run it there if it completes in the time; otherwise say what ran).

## Deliverables (by 11:30 UTC)

- `dev/mo-wide-reads` on the fork; `B65/READS-RESULTS.md` (the diff's size, the before/after table, the tests and
  where they ran, the fault-message comparison, the note on step 2, what is not done, the session's energy,
  confirmation that eventeo is off); logs under `B65/runs/`.
- A final report to me of at most 15 lines. If the tooling denies something, do not work around it: note it.
