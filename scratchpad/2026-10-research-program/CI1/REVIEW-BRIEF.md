# Review brief: a CI fix branch, before its PR is opened (2026-11-14)

You are an independent reviewer. Repository: `~/projects/nice` on this machine (upstream
`wasabipesto/nice` = git remote `origin`; fork `wasabipesto-bot/nice` = remote `fork`). Use `gh`
read-only against `wasabipesto/nice`.

**Branch:** `fork/pr/ci-gpu-image-runner` (head `024cf43f`, two commits on `origin/main`
`41b4b405`). **PR body draft:** `CI1/PR-BODY.md` in
`~/projects/nice/scratchpad/2026-10-research-program/`.

The claim: GitHub's `ubuntu-latest` now resolves to Ubuntu 26.04 for some jobs; the job "Build
(amd64, GPU) + Push arch image" of `.github/workflows/docker-build-push.yml` builds the client on
the runner and copies it into an Ubuntu 24.04 based image, so its smoke test fails with
`GLIBC_2.43 not found`; pinning the two amd64 image jobs to `ubuntu-24.04` fixes it.

Check, and do not take the author's word for any of it:

1. `git diff origin/main fork/pr/ci-gpu-image-runner`: is it exactly what the body says? Valid
   workflow YAML (indentation, the `runs-on` label `ubuntu-24.04` is a real GitHub-hosted
   label)? Are the comments accurate?
2. The evidence, from the Actions logs: run `43585489772` (PR #260, head `9c27023b`) and
   `43585477078` (its first push): the failing job's runner image and the failure line; the CPU
   amd64 job's runner image and result in the same run; run `43475311988` (PR #259, the day
   before): the same GPU job's runner image and result. (`gh run view <id> --repo wasabipesto/nice --json jobs`,
   `gh api repos/wasabipesto/nice/actions/jobs/<job id>/logs`; the runner image is printed
   under "Runner Image" near the top of each log.)
3. Every statement of the body's "Not in this PR" and "The change" sections against the
   workflows under `.github/workflows/` and the logs of PR #260's other runs (which jobs ran on
   `ubuntu-26.04` and passed): sample at least the Rust build workflow (run `43585489777`) and
   the GPU parity workflow (run `43585489786`).
4. Is anything else exposed to the same defect that the branch does not fix: another job, in
   any workflow, that builds a binary on an `ubuntu-latest` runner and then runs it in an older
   container or ships it? Does the release workflow publish a binary built on the runner?
5. Is pinning the right fix, and could it break anything (caches keyed on `runner.os`, the
   toolchain step, Docker availability on the 24.04 image, the `needs` graph of the manifest
   jobs)? Does the body say anything the evidence does not support, or mention anything
   internal (a research program, scratch directories, agents, model names: it must not)?

Deliver `CI1/REVIEW.md` in the program directory: verdict first (open as is / open after the
listed fixes / do not open), then findings by severity with evidence, then what you verified
and how, then what you could not verify. Do not change the branch, do not push, do not open,
comment on or edit any pull request, do not re-run workflows, do not start subagents. Your final
message is a short summary of the verdict and findings for the program's director.
