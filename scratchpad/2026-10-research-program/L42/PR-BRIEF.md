# L42 PR brief: finite-difference top certificates in the CPU join (2026-11-06)

Read `L42/SCOPING.md` (the profile, the prototype `l42_fd.rs` in the kept worktree
`.worktrees/l42-cpu-join-prof`, and §6's plan) and PR #240's body (the GPU version of the same
idea: `gh pr view 240 --repo wasabipesto/nice --json body --jq .body`). The prototype measured
×1.10–1.20 at production shapes, exact on ~19 M slots and on whole b60/b62 1e14 fields.

## Deliverable

Branch `pr/cpu-join-fd-tops` on the fork, one squashed commit on upstream main 6f060a9
(independent of #241: this is CPU code only), that ports the prototype into `CpuJoin::tops`
(`common/src/cpu_join.rs`) as the plan says: step consecutive prefixes (consecutive P differ by
h = b^3 within a key's ascending prefix order) with the five packed digit-array additions from
`detailed_fd.rs`'s scheme; seed by `Base::cert`'s division on the first prefix and after gaps
larger than the step budget (§6 says up to 4 steps are walked); tighten the step's word counts;
cheapen the seed where the plan says; replace the u128 `dm`/`pc` work on kept tops if the plan's
version is exact. No env knobs, no dead prototype code; the FD path is the only path for the
shapes it covers and `Base::cert` remains for the seeds and anything it does not cover.

## Process (ivory, `nice -n 19`, worktree under `.worktrees/`, own `CARGO_TARGET_DIR` inside it; `df -h /` first; release builds only; remove target dirs at the end)

1. Tests, in the PR: a unit test that the FD certificate equals `Base::cert` for every top of the
   production-field reference set the crate already has (the opt-in reference test covering
   b42–b64) and on random prefix runs with gaps and clipped ends for bases 10–64; the existing
   `cpu_join` tests; the whole-b42 field test (join = reference = stride; 417,789,835 survivors,
   16,879,877 checked); the b60 and b62 1e14 fields with survivor and checked counts identical
   to main's (run main's binary too). `cargo fmt --check`; `cargo clippy -p "*" --all-targets --
   -D warnings` (default features; the GPU feature sets do not touch this code but run the default
   clippy CI uses).
2. A/B against main 6f060a9 on ivory: two release binaries, interleaved with alternating order,
   medians, **3 rounds**, at 1 thread and at 4 threads, on b60 1e16-shaped and b62 1e17-shaped
   partitions (the harness from `L42/raw/`) and whole b60/b62 1e14 fields; then the CPU nice-only
   NiceMark scenarios (`nice_client ... --benchmark` without `--gpu`, the same seconds as the GPU
   runs use) **4 rounds** interleaved. Note the load average before each round (other processes
   on ivory) and discard rounds with load > 2 before the run.
3. `L42/PR-BODY.md` in the style of `L38/PR-BODY.md`: what / why with the profile (top
   certificates 42–43 % of the CPU join at production shapes; 57 % of `Base::cert` on two hardware
   divides) / soundness (the stepped arrays equal the divided digits: the same argument as #240's,
   plus the seed/gap rule) / measurements (both thread counts, the fields, NiceMark; say the
   machine is a Zen 2 VM with AVX2 and that Zen 3/4 divide faster so the gain there is smaller) /
   exactness / not in this PR (the lean prefilter, the same arithmetic as the GPU's `walk_pf`,
   follows separately once the GPU version lands). No program/scratchpad references. CHANGELOG
   line under "## Unreleased" ending `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))`.
4. Push the branch (HTTPS fallback with `-c http.extraheader="AUTHORIZATION: bearer $(gh auth token)"`
   to `https://github.com/wasabipesto-bot/nice.git` if SSH is refused; never push to
   wasabipesto/nice). Do not open the PR. Write `L42/PR-RESULTS.md` with the numbers and raw logs
   in `L42/raw/pr/`. Remove the target dirs (`rm -rf <worktree>/target*`), keep the worktrees.

Rules: no pushes to upstream, no PRs, no GitHub comments, no subagents, nothing else in the
scratchpad touched, nothing under `~/projects/nice` outside `.worktrees/` touched (the main
checkout runs the live fleet). Hard stop 11:30 UTC.
