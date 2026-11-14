# T2.6b follow-up: the new test fails on CI's lavapipe with the SPIR-V compiler (2026-11-14, 20:35 UTC)

PR #263 was opened from `pr/stride-queue-any-plane` after the review. Its first CI run failed a
job that is not the runner: **"cubecl on lavapipe (Linux)"**, second step (`--features
cubecl-spirv`, runtime `wgpu<spirv>`), test
`cubecl_queues_check_every_survivor_on_partly_filled_planes`: **7 of 32 runs wrong**, all
`plane=false` (cube-scoped queue), all at the test-only cube sizes, each stopped by the account.
The first step (`--features cubecl`, `wgpu<wgsl>`) passed 32 of 32; Metal passed. The log is
`T26B/ci-fail/lavapipe-job-132562181509.log` (search `plane=false`). CI's driver:
`llvmpipe (LLVM 21.1.8, 256 bits)`, **Mesa 26.0.8-1ubuntu0.3** on an `ubuntu-26.04` runner; your
box and the reviewer's had an older Mesa, where the same test passed 32 + 32 and 120 of 120.

The wrong runs:

```
b50 plane=false ballot=true  cube=100 lanes/range=4: checked 1 fewer survivors than they queued
b40 plane=false ballot=true  cube=100 lanes/range=1: checked 3401 fewer
b40 plane=false ballot=true  cube=100 lanes/range=4: checked 1669 fewer
b40 plane=false ballot=true  cube=48  lanes/range=4: checked 182536111 fewer
b40 plane=false ballot=true  cube=36  lanes/range=4: checked 128849019 fewer
b40 plane=false ballot=false cube=100 lanes/range=1: low words differ by 109 mod 2^32
b40 plane=false ballot=false cube=48  lanes/range=1: low words differ by 347 mod 2^32
```

What I notice (hypotheses, not findings): the b40 window has 283 survivors, so "3401 fewer" and
"182536111 fewer" cannot be counts of survivors: the account words carry garbage. 128849019 is
round(0.03 · 2^32) and 182536111 is ceil(0.0425 · 2^32), so they look like stale data read as a
count, i.e. shared memory that was never cleared or a word read before it was written. Cube 48
is six full 8-lane subgroups, so a partly filled plane is not required. Every 256-unit run
passed, in both forms. naga zero-initialises workgroup memory on the WGSL path; the SPIR-V
compiler's module goes to the driver as it is. "Low words differ by 109 / 347" with the count
equal looks like one slot read in place of another. Whether survivors were actually lost, or
only the account misread, the log cannot say (a failed field prints no hit comparison).

## Task

1. **Reproduce** on Mesa 26.0.8. Box: Vast instance **60693354** (Ubuntu 26.04 image, 20 cores,
   a GPU you do not need; `python3 vast.py ssh 60693354` from the program directory; wait for
   `/root/READY`; it destroys itself at about 23:55 UTC). `apt-cache policy mesa-vulkan-drivers`
   should show 26.0.8; `VK_ICD_FILENAMES` as in `.github/workflows/gpu-parity.yml`, and run the
   test the way that job does (the whole `--ignored` suite in one process as well as the single
   test alone, and with `--test-threads=1`: say which of these fail and how often).
2. **Find the cause** and say which it is, with evidence: (a) a defect in the new queue or its
   account that other drivers could also hit (then it must be fixed, and say whether a real
   device in production configuration, 256-unit cubes, could be affected and whether survivors
   are lost or only the account is wrong); (b) a defect of this llvmpipe version (then show it
   with the smallest kernel you can, say whether main's own cube-scoped queue at 256 units is
   exposed to it, and decide what the test should do: the PR must not make CI red, and must not
   hide a real loss either); (c) a defect of the test. Check in particular: every read of
   `q_acct`, `q_lo`, `q_hi` against the barrier that orders it after its write, on the path
   where shared memory starts as garbage; what the SPIR-V compiler emits for
   `SharedMemory<Atomic<u32>>`, the atomics and both barriers (dump the module:
   `CUBECL_DEBUG_LOG` or the test's dump hook) compared with naga's output for the WGSL path;
   whether the failure needs a cube size below 256, a particular number of iterations, or other
   tests running in the same process.
3. **Fix** by new commits on top of the branch's current head (`bec91fdd` on the fork: your
   commit, the changelog number, a merge of main `54d0aac4`, and a comment fix; **fetch first**).
   Never force-push; never rewrite. Then on the box: the failing test 20 times in a row on Mesa
   26.0.8 with both compilers, the whole lavapipe suite as CI runs it with both compilers, and
   `just lint` (CI's lint recipe: it includes `--features nice_client/gpu,nice_client/cubecl-spirv`;
   my own comment commit failed it once today because I linted with fewer features). If the
   kernel changes, say what must be re-verified on CUDA (no CUDA box is rented now) and whether
   the generated CUDA source of the kernel changed.
4. **Write up** `T26B/CI-FAIL.md` (cause, evidence, fix, runs) and the replacement for the
   status paragraph at the top of `T26B/PR-BODY.md` (do not edit the PR itself; I do that).

Rules as before: push only to the fork branch `pr/stride-queue-any-plane` (new commits, plain
pushes); never force-push or delete; no PR actions (open, comment, edit); no subagents; never
`vast.py create` or `destroy`; nothing on the fleet, the server, demoux or mayalaran; no contact
with the production API (if you run NiceMark, point its API address at a closed local port).
Copy results to ivory early. Hard stop **23:15 UTC**. If the cause is not found by then, write
up exactly what is and is not established and propose what the PR should do meanwhile.
