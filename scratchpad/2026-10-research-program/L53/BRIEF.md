# L53 brief: #249's layer sort off the device thread (2026-11-09)

## Why (L51.1)

#249's `sorted_layer(fs, nkeys)` (`common/src/cubecl_join.rs` ~3108, called from the per-slice
setup ~3197) is a host counting sort over the slice's top layer with ~7 u64 divisions per prefix.
L51 measured it at 2.55–2.84 s per b62 1e17 field (3.2–3.6 %) and 0.44–0.46 s per b60 1e16 field
(2.8–2.9 %), **with the GPU idle**: it runs on the thread that drives the device. `run_slices_with`
(~3822) already prepares the next slice on a thread (`prep … h.join()`): find out why the sort is
not covered by that overlap (does it run before the prep thread starts, or inside it but on the
critical path because the prep is joined before the GPU work is queued?), and fix it: move the
sort (and anything else per-slice that does not need the device) into the overlapped
preparation, or into the field setup the client already overlaps across fields; and make the
sort cheap (u32 arithmetic, no u64 division per prefix — the class and key of a prefix are small
residues that can be computed incrementally or from precomputed powers mod (b−1) and mod b).
Both are exact by construction (the same permutation; the test
`sorted_layer_and_segments_match_the_cpu_buckets` pins it). Estimate ×1.03–1.04 at b62 1e17,
×1.03 at b60 on this host's CPU, less on a faster host. Kill: < ×1.02 at both fields → record
only; any count change.

## Where it goes

This is an improvement to the open PR #249 (`pr/join-static-buckets`, head 87958fd, two commits
on f3fb390). Add it as a **third commit on that branch** ("Overlap join: sort the top layer off the
device thread", with a body) and push with lease — do not rewrite the two existing commits. Then
**rebase the two held branches onto the new #249 head**: `pr/top-fd-round2` (d813aea, one commit)
and `pr/check-d` (7d6956f, one commit on d813aea), keeping each a single commit; conflicts should
be none (host-side change vs kernel changes) — if any, say what. Update `L46/PR-BODY.md`'s "Not in
this PR" / add a short section for the new commit (measured numbers), and edit the PR body on
GitHub? No — I edit the GitHub body; you update the file.

## Process

Box: instance 59842980 (`nice-research-l53-sort`, RTX 3080, 7 h TTL): `python3 vast.py ssh
59842980`; wait for `/root/READY`; the clone is of the fork. All builds and runs on the box. Never
`vast.py create`/`destroy`. Another agent (L54) works on the join kernel's AND codegen on another
box; do not touch `join_kernel` or `L54/`.
1. Read the slice pipeline (`run_slices_with`, `run_slice`, the prep thread, `JoinDevice::new`,
   `sorted_layer`) and write five lines in `L53/RESULTS.md` on where the sort sits today and why
   the GPU idles.
2. Implement; measure the sort's own time (host timers) before/after, and the per-field A/B vs
   87958fd: 3 interleaved rounds at b62 1e17 and b60 1e16, plus b62 1e16 and b64 1e16 (2 rounds),
   counts exact (b62 1e17 1,020,844,021,499 / 62,584,252,554; b60 1e16 460,847,952,346 /
   30,871,838,404; b62 1e16 163,513,599,082 / 10,027,698,695; b64 1e16 787,584,956,227 /
   47,900,853,327). Record each process's join-kernel register variant (L51's `ptxjit.py` in
   `L51/raw/scripts/`) so a spill-variant process does not distort the A/B; re-run any that spilled.
   Note the host CPU model and its load.
3. Exactness: the host test above, `cubecl_cuda_join_matches_the_cpu_reference`, #249's sentinel
   FD-vs-top device test, dense fields, whole b42, 1e14 COMPARE; lavapipe parity (naga + SPIR-V);
   lint; fmt; clippy ×3.
4. Push: the third commit on `pr/join-static-buckets` (no force needed), then the rebased
   `pr/top-fd-round2` and `pr/check-d` with lease. Report the three new heads. Write
   `L53/RESULTS.md`, raw logs in `L53/raw/`.
Rules as for every box agent (Vast via `vast.py` only; ivory writes only under `L53/` and the
`L46/PR-BODY.md` section; HTTPS push fallback to the fork; never push to wasabipesto/nice; no PRs,
no GitHub comments or edits, no subagents). Hard stop 12:30 UTC.
