# L54 brief: the transposed AND's codegen, and the join kernel's register pin (2026-11-09)

## Why (L51.1)

After #249 the transposed AND is 14.9 % of a b62 1e17 field (11.4 s) and runs at ~2× its shared-
memory floor: 52–60 % of its time is instruction issue, and 8 of its ~30 instructions per digit are
address arithmetic that CubeCL leaves unfolded (the `t_tr[c·64 + d]` index built per load instead
of a base register plus an immediate offset). Folding it is ≈ 4.3 % of the field in cycles (2.1–
3.6 % in time); with a leaner bit loop (fewer instructions per digit iteration) 3.0–5.1 %. Kill:
the SASS shows the fold cannot be expressed through CubeCL, or the A/B is < ×1.03 at both fields
→ record only; ≥ ×1.03 → a PR-ready commit, held (it would ride with #246 or #249 as a kernel
change in `join_kernel`; say which base you used).

Second item, L55: ~1 in 7 runtime (NVRTC → driver JIT) compiles of `join_kernel` picks a
40-register variant with 8–44 B of spills, ~3 % slower; `.maxnreg 48` or `.minnctapersm 5` in the
PTX gives 44 registers, no spill, at ×0.992–1.003 of the normal code. Find out whether CubeCL 0.10
can express a register bound or launch bound for one kernel (compile options on the CUDA runtime,
`cube_dim`/`launch_unchecked` attributes, a PTX post-pass hook); if yes, implement and measure the
variance away (10+ processes: all should land on one register count); if no, write the smallest
upstream-friendly way (a CubeCL option or a documented PTX edit) in the results, and stop.

## Process

Box: instance 59842997 (`nice-research-l54-andgen`, RTX 3080, 7 h TTL): `python3 vast.py ssh
59842997`; wait for `/root/READY`; the clone is of the fork. Base: fork `pr/top-fd-round2` d813aea
(the full stack; L53 may move #249's head today — that is host code, irrelevant to your kernel
work). Branch `exp/join-and-codegen` on the fork. All builds and runs on the box. Never `vast.py
create`/`destroy`. Another agent (L53) changes host-side slice setup on another box; do not touch
`sorted_layer`/the slice pipeline or `L53/`.
1. Codegen first (no timing): dump the join kernel's CUDA source and SASS (L51's scripts in
   `L51/raw/scripts/`, `ptxjit.py`, SASS classification from `L41/raw/classify.py`), isolate the AND
   loop's per-digit instruction sequence, and try CubeCL-level rewrites that let NVCC/ptxas fold the
   address: e.g. walk a `SharedMemory` slice/pointer-like index with the chunk offset hoisted
   (`t_tr` indexed by `d` only inside a per-chunk sub-view if CubeCL has one), reorder the loops so
   the digit-dependent part is the only runtime index, use `comptime!` offsets for the 4 chunks of
   a group, or change the table layout to `[d][c]` with the chunk index comptime (bank conflicts
   change — count them). Report SASS instructions per digit per variant. Also try the leaner bit
   loop (one `ffs`/`brev`-based iteration vs the current trailing-zeros + clear).
2. A/B of the best variant(s) vs d813aea: 3 interleaved rounds at b62 1e17 and b60 1e16 (+ b62 1e16,
   b64 1e16 2 rounds), counts exact (see the usual values), each process's register variant recorded
   with `ptxjit.py` (re-run spill-variant processes); NiceMark 4 rounds if ≥ ×1.03.
3. Exactness for any variant that might ship: parity incl. b50/b54, #249's FD-vs-top device test,
   dense fields, whole b42, 1e14 COMPARE; lavapipe naga + SPIR-V; lint; fmt; clippy ×3.
4. L55 as above.
5. `L54/RESULTS.md` (codegen table, A/B, L55 verdict), raw in `L54/raw/`. If ≥ ×1.03: a squashed
   PR-ready commit `pr/join-and-codegen` on the base you name, CHANGELOG line with `#NNN`, body in
   `L38/PR-BODY.md`'s style (no program/scratchpad references); do not open the PR.
Rules as for every box agent (Vast via `vast.py` only; ivory writes only under `L54/`; HTTPS push
fallback to the fork; never push to wasabipesto/nice; no PRs, no subagents). Hard stop 12:30 UTC.
