# Review: fork/pr/ci-gpu-image-runner (024cf43f), 2026-11-14

## Verdict: open after the listed fixes (all small, none touch the YAML change)

The diagnosis and the fix are correct and the evidence supports them. The two required fixes are
to the PR body and commit trailers, not the code:

1. Remove or neutralise the commit trailers `Co-Authored-By: Claude Fable 5.2 ...` on both
   commits (a model name; brief says nothing internal may appear; also not the attribution line
   the session instructions prescribe) and the `claude@example.com` author identity.
2. Soften the unevidenced "as the label's rollout proceeds" prediction (see M1) and say something
   about the shared cargo cache (see L1).

## Findings

### Medium

M1. Body: "It will fail on main and on every PR as the label's rollout proceeds." Evidence shows
the label gave 24.04 on 2026-11-13 (main push runs 43454688877/43454718747 and PR #259 run
43475311988, all jobs `Image: ubuntu-24.04`) and 26.04 on 2026-11-14 (both #260 runs, every
`ubuntu-latest` job I sampled in 43585489777 and 43585489786). A flip between those two days is
shown; a gradual "rollout" is not. Suggest: "ubuntu-latest resolved to 24.04 on 11-13 and to
26.04 on 11-14, so any run from now on is exposed." Also "first seen on #260" is correct only
as "first seen in the runs I checked": the one other recent GPU-job failure (dependabot cubecl,
run 43363170002, 11-13 04:10) ran on `ubuntu-24.04` and died with exit code 101 (a cargo
error), unrelated.

### Low

L1. Cache interaction (item 5). Both amd64 jobs cache `target` + `~/.cargo/{registry,git}`
under `cargo-amd64[-gpu]-${{ runner.os }}-<Cargo.lock hash>` with a prefix `restore-keys`;
`runner.os` is `Linux` on both 24.04 and 26.04. The CPU job on 26.04 succeeded in #260 and so
saved a cache (PR-scoped, not visible to other branches). If any run of the CPU job on 26.04
ever saves into main's scope, a later 24.04 job could restore a `target/` whose build-script
binaries were linked against glibc 2.43 and cargo's fingerprints would not notice, giving
`GLIBC_2.43 not found` at build-script run time. I found no such main-scope save today (last
main runs were on 24.04, the GPU job failed so never saved), so this is a latent, low-probability
risk, and it is also what pinning removes going forward. Optional hardening: put the runner
image into the key (`cargo-amd64-ubuntu-24.04-...`); not needed for this PR. Worth one sentence
in the body if you keep the "drop that hunk" offer, since the CPU job restores a 26.04-built
cache until it is pinned.

L2. Body's "Not in this PR" says the other workflows "already ran on ubuntu-26.04 and passed":
true for every job I sampled (see Verified). Precise wording nit: the x86_64-musl job builds
natively (no cross container, `set-cross-compile.py x86_64-unknown-linux-musl false`), so
"built in the cross containers" does not cover it; it is a static musl binary, so the runner
glibc is irrelevant, but the sentence as written is slightly broader than the truth.

L3. `ubuntu-24.04` is a valid GitHub-hosted label and is already used elsewhere (the arm64 job
uses `ubuntu-24.04-arm`); the pin will need moving when 24.04 is retired. The workflow comment
says "Move this pin together with the image's base", which is right.

### None found

- Diff is exactly what the body says: two `runs-on` lines plus comments in
  `docker-build-push.yml` and a comment in `client/gpu.Dockerfile`; nothing else
  (`git diff --stat`: 2 files, +12/-3). YAML parses (PyYAML): runs-on map is
  amd64 `ubuntu-24.04`, amd64-gpu `ubuntu-24.04`, arm64 `ubuntu-24.04-arm`, both manifest jobs
  `ubuntu-latest`.
- Comments accurate: 24.04 glibc 2.39, trixie 2.41, 26.04 glibc 2.43 all consistent with the
  logs and the Dockerfile bases (`debian:trixie-slim`, `nvidia/cuda:12.8.1-runtime-ubuntu24.04`).
  The only remaining `ubuntu-latest` mention outside workflows (gpu.Dockerfile line 7) is the
  one the branch fixes.
- `needs` graph unchanged (manifest-cpu needs both CPU jobs, manifest-gpu needs the GPU job);
  the manifest jobs run no built binary, so leaving them on `ubuntu-latest` is fine.
- Docker, buildx and `dtolnay/rust-toolchain@stable` all ran on `ubuntu-24.04` the day before.
- Body/commit text mentions no research program, scratch path or agent.

## Other jobs exposed to the same defect

None found that needs fixing.
- `rust-build-test.yml`: every glibc Linux release artifact is built through
  `houseabsolute/actions-rust-cross` with `cross build` (log lines for x86_64-gnu, i686, armv7,
  arm-musl, riscv64, FreeBSD all show `.../cross build --target ...`; aarch64-gnu is
  `force_cross` too), so the container's glibc applies. The x86_64-gnu job asserts
  `requires up to GLIBC_2.18 (allowed: GLIBC_2.28)` on both CPU and GPU binaries (run 43585489777,
  job 132435829341, on 26.04). The x86_64-musl job is native but static. aarch64-musl is on the
  pinned arm runner. Windows/macOS irrelevant.
- The release workflow publishes only the artifacts uploaded by that `build` matrix (the cross,
  musl, Windows, macOS ones) via the `release` job; it publishes no binary built natively against
  the runner's glibc. The release job itself only downloads and uploads.
- `test-workspace`, `test-gpu-host`, lint, gpu-parity lavapipe, browser-client (wasm build, then
  runs in the Playwright container), and `documented-deps` (builds inside `debian:bookworm`)
  build and run on the same host, or build inside the container; none copy a runner-built
  native binary into an older image. browser-client only copies wasm `pkg`, which is glibc-free.
- Only `docker-build-push.yml` has the build-on-runner, run-in-older-image construction, and the
  branch covers both of its amd64 jobs (arm64 already pinned).

## What I verified, and how

- `git fetch fork` / `git fetch origin main`; branch head 024cf43f on origin/main 41b4b405;
  `git diff origin/main fork/pr/ci-gpu-image-runner`; YAML parse of the branch's workflow.
- Logs via `gh api .../actions/jobs/<id>/logs` (read-only):
  - Run 43585489772 (#260, 9c27023b): GPU job 132418978883 `failure`, `Image: ubuntu-26.04`,
    `Version: 20261111.82.6`; failing line at smoke test:
    `/usr/local/bin/nice_client: /lib/x86_64-linux-gnu/libm.so.6: version 'GLIBC_2.43' not found`
    (matches the body verbatim). CPU amd64 job 132418979104 `success`, `ubuntu-26.04`
    (image 20261111.196.1), smoke test passed; manifest jobs `skipped`.
  - Run 43585477078 (#260 first push, f9a25017): GPU job 132418939259 `failure`, 26.04,
    same image version; CPU job success. Both pushes confirmed.
  - Run 43475311988 (#259): GPU job 132057497257 `success`, `Image: ubuntu-24.04`
    (20261111.370.1); CPU job 132057497509 success on 24.04.
  - Main push runs 43454688877/43454718747 (11-13 15:38): all jobs success; GPU and CPU on
    24.04.
  - Run 43585489777 (Rust build): test-workspace, lint, GPU host tests, Linux-x86_64 and all
    other Linux/FreeBSD builds: `ubuntu-26.04`, success. Run 43585489786: lavapipe job
    `ubuntu-26.04`, success.
- Body claims "CPU job: its binary references no symbol newer than 2.41" follows from the
  passing smoke test, as stated.

## What I could not verify

- That GitHub is rolling `ubuntu-latest` out progressively rather than having flipped it for
  everyone: the logs show only the two days. I could not read runner-images announcements.
- That the 24.04 pin will make the GPU job pass: it is the configuration that passed on #259 and
  on main, so very likely, but this PR's own run is the test (as the body says). I did not
  check fork-side Actions for a run of the branch itself (none listed under
  `wasabipesto/nice` for the branch name).
- Whether a main-scope cache written from a 26.04 run exists (L1): the cache listing needs
  broader `gh` access than the read-only runs/logs I used.
