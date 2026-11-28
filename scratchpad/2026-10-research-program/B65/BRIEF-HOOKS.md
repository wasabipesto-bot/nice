# Take the split-fault hooks out of production kernels; then the wide expansion's lookups (brief, 2026-11-28 06:00 UTC)

You are a GPU engineer (Rust, CubeCL kernels). Work alone (do not start subagents). **Hard stop for card work
11:30 UTC; report by 12:00 UTC** (check `date -u`).

## Where things stand

The "nice" project's redesigned search join (the middle-out join; fork branch `dev/mo-mode`, head `f503a13c`,
worktree `~/projects/nice/.worktrees/mo-mode`) has a narrow device path for base 64 (`common/src/midout/gpu.rs`)
and a wide one for bases 65–70 (`gpu_wide.rs`). **A kernel that silently loses a candidate is the one unforgivable
failure**, so every stage keeps accounts that the host checks, and fault tests show that each account fires.
Yesterday every list appended by a subgroup ballot or plane scan got a second count kept lane by lane, with five
new faults that model a split plane (`F_T5_SPLIT`, `F_ANC_SPLIT`, `F_EXP_SPLIT`, `F_SLAB_SPLIT`, and
`F_DROP_PARENT` on the new count). Read first, under `~/projects/nice/scratchpad/2026-10-research-program/`
(paths below are relative to it unless they start with `~`): **`B65/FIXES-NOTES.md`** (the audit table, the tests,
"Cost of the new counts"), `B65/LEVERS-RESULTS.md` (the stage profile at base 65 and "Step 3 (note)"),
`B65/RESULTS.md` §4.

Base 65 is about 73 % of what the search can still reach (`YIELD/yield.txt`), so the wide path is where time
matters most; base 64's narrow path is the other 27 %.

## Step 1: the new fault hooks cost 1.5 % of every field; take them out of production kernels

Measured yesterday on an RTX 3060 (`B65/FIXES-NOTES.md`): base 65 +1.5 % through CUDA, base 64 narrow +1.3 to
2.0 %, Vulkan +0.8 %; the counts themselves cost under 0.2 % (the same head with only the five split faults'
emulation code removed times equal to before). The hooks sit in the main kernels' slab loop (a runtime fault test
and a select per record) and in the expansion.

- Make the five split faults' emulation a **comptime** choice of the kernels, off in every production path
  (`route.rs`'s joins, the benches, the client) and on only where a test asks for it, so that a production
  kernel carries the per-lane counts and no emulation code. Follow how the files already pass comptime values
  to kernels. The older fault bits (the ones that existed before yesterday) stay as they are.
- **Say plainly in the code and in your notes what the fault tests then prove:** that the host's checks fire on
  the kernel built with emulation; the production kernel is the same source with the emulation compiled out.
  Add the cheapest evidence that the two builds are otherwise the same: for example the production variant
  and the emulation variant with no fault set must give identical counts and accounts on the tests' slices
  (assert it in a test), and the generated kernel text of the two variants differs only in the emulation
  blocks if that is easy to show for one kernel.
- The WGSL lint's dump (`wgsl_dump_for_lint` in both files, the `--require` lists in
  `.github/workflows/gpu-parity.yml`) must cover the production variants; say whether it also covers the
  emulation variants.
- **Done when:** base 65 (wide) and base 64 (narrow) time within 0.3 % of the head before the hooks
  (`73bc0065`: 6.022 / 6.033 fs at base 65 and 3.281 / 3.283 at base 64 narrow through CUDA on this card) with
  identical counts; every fault test passes with byte-identical messages; the device tests pass through CUDA
  and Vulkan (direct SPIR-V) here and through Metal on the M4; the fork's CI is green on the head.

## Step 2: the wide expansion's lookups (only after step 1 is pushed and green on the card)

`B65/LEVERS-RESULTS.md` "Step 3 (note)": the wide expansion finds each record's top by dependent loads
(`wrec_top`), divides by a runtime value and recomputes per-top values for every bit (`wtop_ctx`, the h-digit
split, `pf_w2_fixed`); the narrow one reads them ready-made. At base 64 the wide expansion costs 2.58 ms per slice
against the narrow one's 2.00; at base 65 the expansion is 4.40 ms of 23.8 (18.5 %). Do (a) the hoisting of
per-top values out of the bit loop and (b) a per-slot top context written once per top by `wtdigz` (which now
runs in slot order), so that the expansion does one load instead of `wtop_ctx`. Leave (c) (the main kernel
writing the top index into the record) alone. Exact first: survivors n for n in the slice tests, every fault
message unchanged, counts equal.
**Kill: if (a)+(b) gain less than 1.5 % of a base-65 field on this card through CUDA and through Vulkan, do not
push them; say what was measured.**

## Where and how

- Branch **`dev/mo-hooks`** cut from the fork's `dev/mo-mode` `f503a13c`; step 2 as further commits on it only if
  it passes its kill line. Pushes to `fork` only; never to `origin` or `dev/mo-mode`; never force-push or amend a
  pushed commit; commit trailer exactly `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; no mention
  of assistants, agents, reviews by agents or a research program in commits or comments. No pull request.
- **eventeo** (RTX 3060 = nvidia-smi index 1 for timing; GTX 1060 = index 0 for long exactness runs, never during
  a timed run). Rules as on the earlier days: read `README.md` "Machines the program may use" and the memory entry
  `~/.claude/projects/-home-claude/memory/reference_eventeo_host.md`; `ssh claude@eventeo`, only `/home/claude`;
  wake it from ivory with `~/.local/bin/wake-eventeo`; every script sources `~/research/scripts/env.sh` (and
  `env_vulkan.sh` for Vulkan, adapter `DiscreteGpu(1)`); never the production API; long jobs through
  `setsid nohup … &`; never `pkill -f`/`pgrep -f`, kill only what you started by recorded PID; at the end
  `bash -l ~/research/scripts/off_if_idle.sh` and confirm from ivory that ssh is gone. Yesterday's scripts:
  `B65/scripts/fixes/` here and `~/research/b65b/scripts/` there (builds, test rounds, alternating timing with
  the card sampled, `energy.py`). Old target directories under `~/research/t/` may be deleted if space is short.
- **The M4** for Metal: `ssh justin@mayalaran` (the owner's account: write only inside `~/claude`; source
  `~/claude/scripts/env.sh`; `build_mo.sh BRANCH TAG` checks out a stale `FETCH_HEAD` in an existing worktree: use
  a new tag per head and check the head it built; ssh there always exits 0, so wait loops must test output).
- **The fork's CI** on the final head: `gh workflow run "GPU Device Parity" -R wasabipesto-bot/nice --ref
  dev/mo-hooks` and `"Rust Cross-Platform Build, Test, and Release"`; if macOS jobs are cancelled for lack of
  runners, `gh run rerun <id> --failed`. Beware CubeCL's SPIR-V compiler: two atomic stores of one value in one
  block lose the second (it bit yesterday).
- Timing protocol: same session, alternating before and after, two rounds at least, field 77777 after the warm-up
  field, sampled check off, card utilisation and power beside every run; counts compared with
  `B65/runs/fixes/`.

## Deliverables (by 12:00 UTC)

- `dev/mo-hooks` on the fork with the fork's CI on its head.
- `B65/HOOKS-NOTES.md`: how the emulation is selected and where it is on; what the fault tests prove now and the
  evidence that the variants agree; the timing table (before the hooks, with hooks, hooks compiled out; CUDA and
  Vulkan; base 65 and base 64 narrow); the tests and where they ran; step 2's numbers and verdict; what is not
  done; energy; eventeo off, nothing left running on the M4.
- A final report to me of at most 15 lines. If the tooling denies something or a machine does not answer, do not
  work around it: stop and report.
