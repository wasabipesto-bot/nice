# L47 prototype brief: the check kernel, design D (2026-11-08)

Read `L47/SCOPING.md` first — it is the design: §1 the current kernel's budget (1,046 warp-
instructions per warp-iteration at 0.54 IPC), §2 the wave tail (1024 cubes = 3 waves where 2.51
fit on a 3080 → a device-side work counter), §3 design D (base-b² limbs from record word 6 =
P mod b⁵ and an exact H = (P − w6)/b⁵; u32 schoolbook n²; digits straight out of the carry
normalisation with magic multiplies proven exact over the input range; a gate on n² plus the low
10 digits of n³ so the rest of n³ runs in ~4.6 % of warps; no record change; one code path for
CUDA/HIP/wgpu), §4 exactness (every existing hit comparison but b10's is on an empty list, so an
over-rejecting check would pass today's suite: new count-mode and gate-mode device tests against
the CPU are required), §5 the plan and kill criteria. Estimates: ×1.05–1.09 at b62 1e17,
×1.06–1.12 at b60 1e16, under a memory floor of 2.7–4.2 s per b62 1e17 field.

## Base and box

Base: fork `pr/top-fd-round2` **d813aea** (= main 6f060a9 + #241 + #246 + #249 + FD round 2; the
full stack). Branch `exp/check-d` on the fork (→ `pr/check-d` if the bar is met). Box: instance
59671449 (`nice-research-l47-check`, RTX 3080, 7 h TTL): `python3 vast.py ssh 59671449` from this
directory; wait for `/root/READY`; the clone is of the fork. All builds and runs on the box;
nothing on ivory except the CPU mirror's unit tests if you prefer (then under `nice -n 19`, own
target dir, removed after). Never `vast.py create`/`destroy`. Another agent (L51) profiles the
same stack on another box; do not touch `L51/`.

## Order

0. **Step 0, the floor** (~45 min): on the current kernel add env knobs `NICE_EXP_CHECK=gather`
   (read the list and the record, write a checksum, no arithmetic) and `NICE_EXP_CHECK_CUBES`
   (408 / 1024 / 2048). Time at b62 1e17 and b60 1e16 (2 interleaved rounds). **Stop if the
   gather-only kernel takes > 6.3 s per b62 1e17 field** (report and park); build if ≤ 4.5 s;
   in between, build but state the ceiling. Report which end of the 6–16 % wave tail the cube
   sweep shows.
1. **CPU mirror** (~2 h): design D's arithmetic in plain Rust in a host module with: the magic
   constants and their exactness checked exhaustively over the input range (as `L41`'s FX tests
   did), the base-b² schoolbook and carry normalisation against `Natural`/u128 reference on random
   and adversarial n for every base 10–64, the gate's predicate against the full check. These
   tests ship with the PR.
2. **Kernel** (~3 h): design D with comptime base, s2, s3, f0, k2 and g (the gate's n³ digit
   count, screened over {8, 10, 12}); probe/count/gate modes for the tests; the device-side work
   counter (each warp takes the next chunk of the survivor list; one-chunk tail on any device).
   Codegen gate (NVRTC → driver JIT): ≤ 48 registers, 0 spills, no local memory, ≤ ~360
   instructions per warp-iteration on the b62 common path; lavapipe compiles (naga and direct
   SPIR-V); WGSL lint. `candidate_check` stays untouched (the stride path remains an independent
   reference).
3. **Device tests**: count mode (every survivor's distinct-digit count vs the CPU on real lists
   and adversarial n), gate mode (vs the CPU predicate), `check_all`, `NICE_TEST_JOIN_FULL_FIELD`
   (whole b42: join = stride = reference, 417,789,835 / 16,879,877, hits identical), the 1e14
   COMPARE at b57/60/62/64 (hits identical), the dense fields, b10's [69]; plus the full inherited
   list (parity, #249's sentinel FD-vs-top test, the certificate test). Whole-field counts =
   the exact counts (b62 1e17 1,020,844,021,499 / 62,584,252,554; b60 1e16 460,847,952,346 /
   30,871,838,404; b62 1e16 163,513,599,082 / 10,027,698,695; b64 1e16 787,584,956,227 /
   47,900,853,327).
4. **A/B vs d813aea** (3 interleaved rounds): screen g first (2 rounds), then b62 1e17, b62 1e16,
   b60 1e16, b64 1e16, the 1e14 set; NiceMark 6 rounds. Clock per side and clock-normalised
   ratios. Kill: < ×1.05 at both production fields → keep the work counter alone as a rider if it
   gives ≥ 1 %; any NiceMark scenario < ×0.98 over 6 rounds; exactness failing twice.
5. If the bar is met: squash to one commit on d813aea (no knobs; the shipped g only; the host and
   device tests stay), CHANGELOG line ending `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))`,
   push `pr/check-d`, write `L47/PR-BODY.md` in `L38/PR-BODY.md`'s style (stacked on the FD round
   2 branch, which is on #249; say so; no program/scratchpad references; state the floor and the
   backends not run). Do not open the PR.
6. `L47/RESULTS.md`, raw logs and scripts in `L47/raw/`. Rules as for every box agent (Vast via
   `vast.py` only, never create/destroy, say when the box can go; ivory writes only under `L47/`;
   HTTPS push fallback to the fork; never push to wasabipesto/nice; no PRs, no subagents). Hard
   stop 12:30 UTC (box self-destroys ~12:50 UTC). A second day is budgeted if the kernel is exact
   but the A/B is unfinished.
