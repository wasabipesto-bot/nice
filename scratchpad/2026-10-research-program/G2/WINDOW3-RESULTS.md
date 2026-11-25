# Window 3 on the RX 9070 XT (demoux), 2026-11-25: results

Brief: `G2/WINDOW3-BRIEF.md`. Lease granted ~03:41 UTC. Window: first check at 03:48, measurements 03:56–05:52, cleanup
verified at 05:53:41. Raw logs, sampler files, analyses and the adapted driver are in `G2/window_1125/`
(`out/`, `scripts/`, `analysis*.txt`, `pgids`, `watchdog.pid`).

## Machine state and method

- **First check (03:48):** no `nice_client` process; card idle (`gpu_busy_percent` 8–9 %, 746 MHz, the same idle
  reading as on 11-19). `/opt/nice` and the production client were not touched. Disk 93 % used, 64 GB free
  (enough; noted). Rust 1.100.0 present (repository pin).
- **The desktop was in use during the window** (seat0 session: LibreOffice, Firefox, Spotify, Steam, each 5–20 %
  CPU; load ~3). It did not load the card (idle 6–12 % between my runs). It may explain the drift in task 1 below;
  that is not proven.
- **Code:** one git bundle made on ivory (`dev/mo-clean` 66305ada, `exp/mo-word-width` b3967fb5), cloned in
  the workspace `~/claude-exp-2026-11-25-mo`, `CARGO_HOME` inside it, one target directory per tree. Nothing was
  pushed or committed. Binaries (md5): `t_mo` aab86e20 and `mo_bench` 20f58b84, `mo_wide_bench` c2c10982,
  `mo_fields` 613c11e9 (features `cubecl-spirv,midout-box-tests,midout-bench`); `cw_dump` 8838d2fa, `cw_bench`
  c90e4913 (`cubecl-spirv`); `nice_client` d1d845bb (`cubecl-spirv`). Each log records its binary's md5.
- **Driver:** window 2's `build4s/window/` adapted, not rewritten (`window_1125/scripts/`). `go_mo.sh` gained
  `PHASE` 1/3/4, plus the parent-sharing test, the wide fault test and a (4, 8, 5) field with the sampled check.
  `smp.sh` gained `SMP_DT`. `analyze_mo.py` gained the count checks against 11-19, `x_485` and the b65 runs. New
  scripts: `cw_dump.sh` and `cw_micro.sh` (from `CW/box/dump.sh` and `micro.sh`), `cyc_amd.py` (from
  `CW/box/cyc.py`, reading the AMD sampler), `route.sh` (spare) and `extra.sh` (extra rounds).
- Every run went through `setsid nohup` with its process group recorded (`window_1125/pgids`). A watchdog in
  `/tmp` would have killed the groups and removed the workspace at 07:25.
- **Process notes:**
  - The first watchdog used `kill -- -PGID`, which demoux's dash rejects ("Illegal number"). I replaced it at
    03:50, before any card work, with one using `kill -SIG -PGID` (verified rc 0), and stopped the old one by PID.
    The same bug made build 2 start without waiting for build 1 (harmless).
  - The client build (build 3) was still compiling when the timing began. I paused it (`SIGSTOP` to its group)
    from 03:58:34 to 04:28. Every timing run had a quiet CPU except for the desktop.

## Task 1: the cleaned branch at base 64

**Exactness at W 64: everything passes** (`out/x_*.log`; `EXACT narrow=1 wide=1 faults=1 sharing=1 wide-faults=1
field485=1 old-coordinate=1`):

| run | what | result |
|---|---|---|
| `x_g1`, `x_g2` | slices 712012851, 318575442 / 0, 2^30−1 with the shared depth-8 lists | device tops = host tops; every count equal to the CPU reference, n for n |
| `x_g3` | slices 806726610, 4977728, 1061942336, 223081536, unshared | equal |
| `x_sh` | `field_parent_sharing_is_exact_and_loud`, 128 slices of field 77777 | shared = unshared slice by slice; all five faults loud |
| `x_f` | narrow fault test, 712012851 | four faults loud by account; `F_PF_DROP` loud by the sampled check |
| `x_w` | wide parity, b40 slice 1234 and b65 slice 717171717 | pass (527,041 survivors, 1,701,945 tops at b65) |
| `x_wf` | wide fault test, b65 slices 717171717 and 0 | every fault loud (accounts, or the sampled check for `F_BAD_PARENT` and `F_PF_DROP`) |
| `x_485` | whole field t 77777 under (4, 8, 5), sampled CPU check on | check equal; counts = 11-19's |
| `x_496` | whole field t 77777 under (4, 9, 6), sampled check on | check equal; counts = 11-19's |

**Timing** (`analysis.txt`). Each round is five whole fields after the warm-up field 4095 (group 16, no sampled
check). Production's join harness ran in the same binary between the rounds: main_f2, main_f6, then, after rounds
4 and 5, main_f2b and main_f6b.

| run | fs per admissible n (5 fields) | clock, power (median at ≥ 80 % busy; samples) |
|---|---|---|
| b_r1 | 1.0295 (1.0119–1.0460) | 2,889 MHz, 303 W (216) |
| main_f2 | 92.98 s (×1.0237 of 11-18) | 3,133 MHz, 304 W (183) |
| b_r2 | 1.0036 (0.9780–1.0336) | 2,848 MHz, 303 W (214) |
| main_f6 | 101.34 s (×1.0093) | 3,100 MHz, 304 W (199) |
| b_r3 | 1.1067 (1.0789–1.1250) | 2,901 MHz, 299 W (217) |
| b_r4 | 1.0632 (1.0400–1.0812) | 2,914 MHz, 301 W (216) |
| main_f2b | 92.62 s (×1.0197) | 3,134 MHz, 304 W (181) |
| b_r5 | 1.0988 (1.0898–1.1120) | 2,930 MHz, 302 W (218) |
| main_f6b | 102.56 s (×1.0214) | 3,102 MHz, 303 W (200) |

- **Counts:** survivors and checked are equal field for field in all five rounds and equal to 11-19's for all six
  fields. Main's four fields equal 11-19's (2,760,283,689,784 / 168,384,458,372 and 3,092,989,872,066 /
  191,683,594,021).
- **Production's base:** 4.707 fs × mean drift 1.0185 = 4.794 fs. That is 4.785 fs from the first bracket alone;
  11-19 had 4.762.
- **Ratio: ×4.51 on the median of five rounds (1.0632 fs); range ×4.33–4.78.** Rounds 1–2 alone (the 11-19
  protocol and bracket) give ×4.71 (4.785 / 1.0166). On 11-19 it was ×4.79.
- Every run was at the operating point: 2.85–2.93 GHz and 299–303 W for the branch, 3.10–3.13 GHz and 304 W for
  main, more than 180 busy samples each.
- **The branch slowed over the session at the same clock; production did not.** Rounds 3–5 were 6–10 % slower than
  rounds 1–2. Production's fields moved by −0.4 % and +1.2 % between brackets.
  - I cannot separate a host effect from the branch from here. The desktop's CPU load is a candidate: the per-field
    sync+reads fell in r3 to 5.8–7.8 s, against 6–12 s in r1–r2, which suggests more host time.
  - So the ratio carries a ±5 % session spread. The decision band's floor (×4.54) sits inside it.

## Task 2: the word width (verdict: dropped)

`mo_width_dump` dumped slices 4977728, 4977729 and 712012851; its counts equal `CW/RESULTS.md`'s. I then ran
`mo_width_bench` through SPIR-V on the card:
- **pass m1:** variants w64, w128s2, w128v1, w128s1, w256x1, w256x2, 15 reps × 100 launches, shuffled, ~3 min;
- **pass m2:** w64, w128v1 and w256x1 on 712012851 and 4977728, as a confirmation.

The sampler ran at 0.1 s (`analysis_cw_m1.txt`, `analysis_cw_m2.txt`).

**Exactness:** every variant on every slice matched the dump per instance. That is 18 of 18 `EXACT … mismatches 0`
lines in m1 and 6 of 6 in m2, the first run of this SPIR-V path on a real Vulkan card.

| variant | 3b ps per pair (m1, mean of 3 slices) | 3b ms | ×3b vs w64 (ms) | ×3b vs w64 (cycles) | clock, power during full |
|---|---|---|---|---|---|
| w64 | **0.0954** | 1.52–1.53 | 1 | 1 | 2.70–2.72 GHz, 306 W |
| w128v1 | 0.1314 | 2.09–2.11 | **×0.726** | ×0.631 | 2.94–2.96 GHz, 303–304 W |
| w128s1 | 0.1314 | 2.10–2.11 | ×0.726 | ×0.629 | 2.96–2.97 GHz, 303–304 W |
| w128s2 | 0.1357 | 2.15–2.18 | ×0.704 | ×0.610 | 2.96 GHz, 302–304 W |
| w256x1 | 0.1417 | 2.25–2.28 | ×0.674 | ×0.581 | 2.97–3.00 GHz, 302 W |
| w256x2 | 0.1446 | 2.31–2.32 | ×0.660 | ×0.576 | 2.94–2.97 GHz, 304 W |

- m2 confirms: w128v1 ×0.728, w256x1 ×0.670 (ms).
- Busy 99–100 % in every measurement interval, 28–42 samples per variant and slice. Every variant ran at the power
  cap (the operating point). w64 drew the most power, hence its lower clock.
- **Rule: width 128's word loop must be ≥ ×1.35 faster than width 64's. On this card it is ×1.38 slower (×0.73).
  The idea is dropped.**
- The W64 loop runs at 1.52 ms. That is faster than both the issue model (2.27 ms) and the CW notes' LDS bound
  (1.557 ms at 128 B/clk/CU), so on this card the narrow loop is not the bottleneck the model assumed.

## Task 3: base 65 with the wide kernel as fitted on 11-20 (not a result: off the operating point)

The fields were 13731 (warm-up), 77777 and 131072. The sampled check was on (`w65_cc`, 4 threads), then off
(`w65_nc`), then off again in a third process (`w65_nc2`: 13731, 77777).

| run | t 77777 | t 131072 | t 13731 (warm-up) | clock, power (busy ≥ 80 %) |
|---|---|---|---|---|
| w65_cc (check on) | 4.8936 fs | 4.8482 | 4.8360 | **1,528 MHz, 112 W** (302) |
| w65_nc (check off) | 4.8306 | 4.7753 | 4.8485 | **1,528 MHz, 112 W** (289) |
| w65_nc2 (check off) | 4.8810 | — | 4.9999 | **1,528 MHz, 111 W** (212) |

- **Every b65 run was off the operating point.** The card stayed at ~1.53 GHz and ~112 W with busy 56–100 %,
  against 3.08 GHz and 300 W on 11-19, when it measured 3.02 fs warm (binary 66259bb0, before the 11-20 changes).
  So by the brief's rule these timings are not a result. The prediction of 2.4–3.0 fs is neither confirmed nor
  refuted.
  - Nothing in the card's configuration had changed: `power_dpm_force_performance_level` auto, default profile,
    304 W cap, at most 56 °C.
  - Task 2's runs reached 2.7–3.0 GHz minutes before.
- **Sampled check:** equal in all three fields; CPU slice 8.2–8.4 s; **the host never waited for it (0.0 s)**.
  Check on against off: +1.4 % on the mean (4.859 against 4.818 fs), inside the run-to-run spread.
- **Counts** of 13731 and 77777 equal 11-19's. Wide exactness is from task 1 (`x_w`, `x_wf`).
- **Diagnostic (`w64_wn`, spare time):** `midout_wide_bench --base 64 --narrow` alternates the two paths in one
  process.
  - The wide path at b64 also ran at ~1.51 GHz and 113 W, at 3.31 and 3.21 fs.
  - The narrow path in the same process ran 1.054 and 1.067 fs.
  - Counts were equal between the paths.
  - **The low clock follows the wide path, not the base.** The wide path on this branch does not load the card to
    its operating point. Why is open: a host-bound or latency-bound pipeline in the wide driver, or the 11-20 kernel
    under RADV. It needs a stage look at the wide path; I wrote no code for it.

## Task 4: stage profile (cumulative stops; most numbers off the operating point)

`midout_bench` offers no mode that keeps the card loaded while isolating a stage. It has only `MIDOUT_STOP` (1, 2, 3,
5, 6) and the device-top stops 11–15, so I ran the cumulative stops as before, on field 77777 after the warm-up
field 4095.

| stage (77777) | ms per slice | clock, power (busy ≥ 80 %) | on point? |
|---|---|---|---|
| tops (stop 1) | 0.486 | no busy samples (1.52 GHz) | **off** |
| parents (2 − 1) | 3.374 | 1.50 GHz, 42 W (1 busy sample of 50) | **off** |
| main kernel (3 − 2) | 1.235 | 2.43 GHz, 177 W | **off** |
| expansion (5 − 3) | −0.273 | 2.86 GHz, 281 W | on (difference meaningless) |
| check and rest (6 − 5) | 0.234 | 2.87 GHz, 300 W | on |
| whole slice (stop 6) | 5.056 (20.71 s field) | 2.87 GHz, 300 W | on |

- Only stops 5 and 6 ran at the operating point.
- Stop 2 took 15.8 s at t 77777 (9.2 s at the warm-up). The card was idle at 1.5 GHz throughout. On 11-19 tops plus
  parents were ~5 s per field. So the parents stage now looks host-bound in this bench mode.
- Stop 3 reads 20.9 s and stop 5 reads 19.8 s, so the differences are not stage costs. None of tops, parents, main
  kernel or expansion is a usable number today.
- `b_cc` (the sampled check's cost, b64): check equal; CPU thread 2.99 s on 4 threads (9.2 s single-threaded on
  11-19); the host waited 0.00 s; device rerun 0.141 s.

## Task 5 (spare): the client route against the local coordinator: works

`route.sh`, 04:29:21–04:33:05:
- 12 fields from `midout_fields --base 64 --spread 12`;
- `scripts/midout_coordinator.py --reissue-after 600` on 127.0.0.1:8471;
- the client `--midout-coordinator http://127.0.0.1:8471 --repeat --threads 11 niceonly` with
  `--api-base http://127.0.0.1:9` (a closed local port). It never contacted the production API.

Results:
- 12 claims, 12 submissions accepted, 0 refused.
- **`midout_audit.py` exit 0** ("every field of the work list accepted exactly once", no nice numbers).
- Card at 2.84 GHz and 303 W (420 busy samples).
- The client exited 0 by itself at the coordinator's 204 (its `--repeat` route ends when no field is left), in the
  same second the driver sent SIGTERM to its recorded PID. So the SIGTERM path itself was not exercised.

## Not done

- No stage profile at the operating point (the bench has no mode for it; no new code, as briefed).
- No b65 timing at the operating point (see task 3); the cause of the wide path's low clock is not diagnosed.
- The cause of the base-64 drift between rounds 1–2 and 3–5 is not established.

## Cleanup proof (05:53:41 UTC; demoux not used after)

- All 12 recorded process groups were empty before removal (`window_1125/pgids`).
- I removed the workspace in one ssh call. A separate call, which never contained the workspace's literal name
  (built from pieces; process patterns with a bracketed first character), then reported:
  - workspace absent;
  - 0 processes matching the workspace name or the watchdog name;
  - watchdog PID 829503 gone (it exited by itself once the workspace was gone, removing its `/tmp` files);
  - 0 processes with a cwd in the workspace;
  - 0 watchdog files in `/tmp`;
  - 0 processes left in any recorded group;
  - nothing listening on 8471;
  - disk back to 64 GB free.
- No notification was sent to the maintainer.

## Follow-up: the wide path's clock (not run: the tooling denied the setup)

The coordinator asked for this at about 05:56 UTC: an A/B of trunk 66259bb0 against head 66305ada on the wide
path at base 65, then a bisection over `gpu_wide.rs`'s history.

- **05:57:19, read-only check on demoux:**
  - no `nice_client` process;
  - card idle (7–10 % busy, 500–741 MHz);
  - load 1.3;
  - no workspace present;
  - kernel `7.1.13+deb14-amd64`.
- **05:57:45, the setup was denied.** My next command would have done the following, and Claude Code's permission
  classifier refused it ("Unauthorized Access"):
  - make a git bundle of `dev/middle-out-join` and `dev/mo-clean` on ivory;
  - copy it to demoux with a watchdog for 07:20 (dash-safe `kill -SIG -PGID`) and a sequential build script (`-j 8`);
  - create the workspace and start the builds: trunk with `cubecl-spirv`, then head and the bisection points
    a82ad9db, 85185fef, 64cf6c24, 1d4d6920, 10ddbf17 and 326ed0a3 with `cubecl-spirv,midout-bench`.
- **Nothing from that command ran.** The bundle and the scripts do not exist on ivory, and no workspace, watchdog
  or process was created on demoux (the 05:57:19 check was the last action there).
- As the brief requires, I did not retry the command or work around the denial.
- **Not measured:** trunk against head on the card today, and the first bad commit. The question (code or session)
  is still open.
- **No cleanup was needed.** demoux holds nothing of mine from this follow-up; the window's own cleanup proof
  (05:53:41) stands.
