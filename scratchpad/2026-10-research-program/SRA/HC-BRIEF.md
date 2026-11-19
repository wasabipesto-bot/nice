# SRA follow-up: the hand-written CUDA backend under an allocation failure (brief, 2026-11-19 06:10 UTC)

You are an engineer running one measurement. Work alone (do not start subagents). **Hard stop 08:15 UTC.**

## The question

Two nights ago's finding (read `~/projects/nice/scratchpad/2026-10-research-program/G2/build2e/ALLOC-FAILURE.md`
first; raw logs and the harness in `G2/build2e/raw/alloc/`): on the CubeCL CUDA runtime, a failed buffer
allocation makes every later launch silently do nothing, and production's client then submitted unsearched
nice-only "stride" fields as searched and empty. That path is fixed in pull request #270. A census of
production (`SRA/census/`, `EXPERIMENTS.md` SRA.3) showed that path produced only 451 submissions ever.

**But 15,046 nice-only submissions (client versions 3.4.2 to 3.4.5, September and early October) ran the
stride path on a different backend: the hand-written CUDA one** (the `cuda` feature: per-base kernels compiled
with NVRTC, driven through `cudarc`; the default for nice-only on NVIDIA through v3.4.5, used for
stride-routed fields in v3.4.6, and still selectable with `--gpu-backend cuda` today). It was never examined.
**Can that backend report a field as searched and empty when its kernels did not run?**

## What to do

1. **Read first** (the code decides most of this): in the tag `v3.4.5` and in upstream main, the hand-written
   backend's nice-only path (find it from `client/src/main.rs`'s `GpuBackend::Cuda` arm: `try_init_cuda`, the
   context, the per-field driver, how buffers are allocated, how launches are issued and synchronised, how
   results are read back). For each device call: is its error a `Result` the host propagates, a panic, or
   ignored? What does the host check before accepting a field's result? Is an all-zero result distinguishable
   from a kernel that did not run?
2. **Measure on the card**, with the memory-hog harness of `G2/build2e/raw/alloc/` (copy it; the write-up says
   how it was used): the v3.4.5 client (the release most of those submissions came from) built with its `gpu`
   features, default backend selection for nice-only, against the local stub only, on fields like the ones
   production ran then (base 54 fields of 1e13 are in the census; pick ones known to be non-empty), with the
   card's memory squeezed before start, a few seconds in, and between fields, at several sizes. Also upstream
   main with `--gpu-backend cuda`. For each case: does the client abort, error, retry, or submit, and with
   what? Compare a submitted result with a healthy run of the same field.
3. If you find a way to a false empty, show it with the log; if you do not, say which failure points you
   covered and which you could not reach (for example a failure inside a kernel launch).

No code changes on any branch: this is a measurement. If a fix is needed, describe it in two lines.

## Machines and rules

- **ivory**: reading and notes only; do not build here.
- **One rented box, which I rented and logged in to for you:** the ssh line at the end. A fresh Ubuntu 24.04
  CUDA 12.8 image: install the toolchain; v3.4.5 may want an older Rust than main pins (use what its
  `rust-toolchain` file or CI says). **Before any client binary runs, map the production hosts to 127.0.0.1
  and ::1 and save the proof** (`G2/build1/box/`, `../T28/raw/hosts_block.sh`, and the stub
  `G2/build1/box/stub_api.py`). **Nothing ever claims from or submits to the production API.** The box
  destroys itself about 08:45 UTC. Leave it running and idle. Never create or destroy instances; never use
  another machine; if the box misbehaves, stop and report.
- No pushes, no pull request.

## Deliverable (by 08:15 UTC)

`SRA/HC-RESULTS.md`: the answer in the first line (yes / no / only in such a case), the code path with files
and lines, the table of cases with what the client did, what was not covered; raw logs under `SRA/raw/hc/`.
Then a report to me of at most 20 lines.

## The box

    ssh -p 26496 root@ssh3.vast.ai

Vast instance 61386568: RTX 3080, 251 GB of memory, 32 GB of disk, Ubuntu 24.04, image
nvidia/cuda:12.8.1-devel-ubuntu24.04 (nvcc present). ivory's ssh key is accepted; I logged in at 05:47 UTC.
Check the card's power limit and memory with `nvidia-smi` first and write them down. It destroys itself at
about 08:45 UTC.
