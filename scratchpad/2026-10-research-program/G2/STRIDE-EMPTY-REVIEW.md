VERDICT: ready with fixes — the code change is correct and safe; fix the test's base-43 field (S1) and the two wording points (S2) before offering.

# Review: `pr/stride-empty-residues` (`3701a353` on `974d7194`), 2026-11-19 20:10–20:35 UTC

Independent reviewer. Read on ivory (worktree `~/projects/nice/.worktrees/stride-empty`), built and ran only on the
rented box in my own clone `/root/rv/src` (target `/root/rv/target`) and scratch clone `/root/rv/scr` (target
`/root/rv/target-scr`). Nothing changed on the branch; nothing pushed; no instance created or destroyed; box left idle.
Production hosts checked first and again before the client runs: `/etc/hosts` maps api/data/www/bare nicenumbers.net
to 127.0.0.1 and ::1; `getent ahosts` gives 127.0.0.1 (`/root/rv/runs/hosts_proof.txt`). Client runs used only my
local stub on 127.0.0.1:8761 (a copy of the author's `stub_validate.py`).

## Findings

### Must fix before offering
None.

### Should
**S1. The test's "real base-43 field" never reaches the walk, and is not the field the commit message names.**
`common/src/stride_filter.rs:1551` uses `40_992_418_181_959..40_993_418_181_959`, which is field 30000; the commit
message ("on that base-43 field", i.e. 60991418181959–60992418181959) and the author's notes (§7: field 49999) name
the field that crashed. Measured in a scratch probe (`/root/rv/probe.log`, `/root/rv/probe2.log`):
- `get_valid_ranges_masked(40992418181959 + 1e9, 43, 3)`: **0 ranges kept** — the MSD filter rejects it whole.
- 60991418181959 + 1e9: 20 426 ranges, 155 838 006 numbers kept.
- With the guard removed: the 40992… field does **not** panic; the 60991… field **panics**.
So the last leg of the test covers nothing. Swap in `60_991_418_181_959, 60_992_418_181_959` (the test then
exercises the reported crash on its real field; base 43's windows already hit the walk 5/16 times, so the test
still fails without the guard either way).

**S2. Bases 4 and 5 are missing from the wording, and with them the "GPU sees no difference" claim is not exact.**
The table is empty at 4 and 5 too (residue filter non-empty, LSD filter at k = 3 empties it; my probe over bases
3–128 finds exactly these two with residues but an empty table). The test covers them, but:
- the `# Panics` doc at `stride_filter.rs:148-151` says "every base `b ≡ 3 mod 4`" only;
- commit message, PR body and changelog say only "every base that leaves 3 when divided by 4";
- `residue_empty_result` (`gpu_niceonly.rs:1390`) checks the residue filter only, so at bases 4 and 5 `--gpu` goes
  `begin_niceonly` → `!gpu_supports_base` (needs base ≥ 10) → CPU fallback `process_range_niceonly`
  (`gpu_route.rs:154-158`), the same walk that panics on main (probe2: 16/16 windows panic at 4 and 5 without the
  guard). With the fix, `--gpu` on bases 4 and 5 submits `[]` on auto, cuda, cubecl-cuda and wgpu/lavapipe (ran).
  So "a GPU device should see no difference" is true for b ≡ 3 mod 4 but not for 4 and 5 (crash → empty).
These are toy bases (ranges of 1 and 2 numbers), so one clause is enough: "and bases 4 and 5, whose stride
table is empty for the same reason at k = 3" in the doc comment and description, and qualify the GPU sentence.

### Notes
- **N1. Test time:** debug 7.2–7.8 s for this one test (two runs), release 0.65 s. Most of it is building 20
  k = 3 tables (base 95: modulus 94·95³ ≈ 8.1e7). Acceptable; could drop the bases whose windows never reach the
  walk (next note) or use a lower k for the large bases if the maintainer minds.
- **N2. Six of the 20 bases never reach the walk in the test** (59, 67, 75, 79, 87, 95: 0/16 windows kept by the
  MSD filter; measured identically with and without the guard). They pass trivially; harmless, but the doc line
  "every such base with a range ... on windows spread over the range" overstates what is exercised.
- **N3. Who hits it is narrower than "a CPU client given a nice-only claim of such a base":** at bases 43–63 a
  field ≥ 1e13 takes the CPU overlap join, which iterates the (empty) roots and was never affected. Ran: base-43
  field of 1e13 (60991418181959–70991418181959) on the CPU with no override → `[]` in 7.25 s (by reading
  `join_verdict` this size takes the join; the route is not logged at info level, so not confirmed from the log);
  field 49999 with `NICE_JOIN_ROUTE=join` (forces the join) → `[]` in 0.5 s. Worth one clause ("fields that take the stride walk").
- **N4. Line reference:** the body's `stride_filter.rs:165` is main's line; on the branch the same index is at 170
  (the panic without the guard reads `170:54`). Say "on main" or drop the line number.
- **N5. Changelog line** is one sentence but ~50 words with a parenthesis and a semicolon; the maintainer has cut
  long entries before. Shorter would match: "Stop the CPU nice-only search crashing on bases where no number can be
  nice, such as 43 (every base that leaves 3 when divided by 4)."
- **N6. Description rules:** no research-program, notes, scratchpad, host or agent references in the body text;
  "a local stub" is fine. It ends with the "Generated with Claude Code" footer and the commit carries a
  `Co-Authored-By: Claude Fable 5.2` trailer: both match upstream's merged history (#270 and the preceding
  commits), so I flag them only because the brief asks for no assistant/model name — the maintainer's own
  convention keeps them.

## Point by point

1. **Soundness.** Residue filter (`residue_filter.rs:6-11`): keeps n mod (b−1) with n²+n³ ≡ b(b−1)/2. Necessary
   condition: a nice n's digits of n²‖n³ are 0..b−1 once each, digit sum b(b−1)/2, and digit sum ≡ value mod b−1.
   For b ≡ 3 mod 4, b−1 ≡ 2 mod 4, so b(b−1)/2 is odd, and odd mod an even modulus stays odd; n²(n+1) is always
   even and stays even mod an even modulus — no residue, no nice number. More generally the guard only fires when the
   table is empty, and a non-empty table's walk visits only table residues, so the guard adds no exclusion the
   existing filters did not already make: the fix can only turn a panic into `[]`. Empty tables over 3–128 (k = 3):
   {4, 5} ∪ {b ≡ 3 mod 4 with a range}, as the author found. Brute force over the whole range (`/root/rv/brute.log`):
   no nice number at 4, 5, 7, 15, 19, 23, 27 (control: base 10 → [69]). Modulus limits make `new` panic via
   `expect`, never return an empty table.
2. **Every path to the lookup.** Non-test callers of `first_valid_at_or_after` are only `walk_masked` and
   `walk_two_phase` (reached only from `walk_masked`, after the guard); `two_phase_survivor_count` is `#[cfg(test)]`.
   The calls in `client_process_cuda.rs`, `cubecl_backend.rs` and `gpu_niceonly.rs` are all inside their test
   modules (which run to the files' ends). Production table builders: client CPU stride walk (`main.rs:922`),
   `gpu_route::begin_niceonly` CPU fallback, `bench.rs` (fixed non-empty bases), `scripts/naive_base_search.rs`
   (k = 1, now fixed too), the GPU plans (`niceonly_defines`, `NiceonlyPlan::build`: both `ensure!` non-empty, and are
   only reached after `residue_empty_result`). All `--gpu-backend` values (auto, cuda, cubecl, cubecl-cuda,
   cubecl-hip) go through `begin_niceonly`. The wasm client is detailed-only. Detailed mode never builds a table.
3. **No behaviour change with residues.** Diff is the 5-line guard, a doc block and the test; nothing else in the
   walk changed. The walk returns only the number list; there are no counters on the CPU path. The client submits
   `{"nice_numbers":[]}` with exit 0 for an empty base, which is the truth (point 1). Base-42 control and base-10
   control (69 found on CPU and all four GPU backends) unchanged.
4. **The test.** Without the guard it fails with "index out of bounds: the len is 0 but the index is 0" at
   `stride_filter.rs:170:54`, at the first base (4) — the stated reason. Per leg, without the guard: windows that
   panic 16/16 at 4–23, 14 at 27, 12 at 35, 8 at 39, 5 at 43, 4 at 47, 2 at 55, 1 at 63 and 83, 0 elsewhere; the
   base-43 field leg does not panic (S1). Depends on nothing outside the repository.
5. **Standing alone** (my clone, `/root/rv/ci.log`): `just lint` rc 0 (only the pre-existing `web-sys`
   unused-dependency manifest warning); `cargo test --locked --release --no-fail-fast` rc 0 (nice_common lib 208
   passed, 9 ignored; client 24 passed); `cargo test --locked --release -p nice_common --features gpu --lib` rc 0
   (262 passed, 66 ignored); `cargo build --locked --release -p nice_client --features gpu` rc 0 (binary md5
   `b9534437…`, build string `3701a353` present).
6. **Description and changelog:** S2, N3–N6.

## What I ran (box, all rc 0 unless stated)
- Brute force of every n in the range, bases 4, 5, 7, 10, 12, 13, 15, 19, 23, 27 (python): only base 10 → 69.
- Scratch probe (release): MSD coverage of both base-43 fields and of the test's windows; empty-table scan 3–128.
- Scratch, guard removed: the new test (FAILED, panic above); a per-leg `catch_unwind` count (above).
- CI forms and the client build (point 5); new test timed in debug (7.78 s, 7.23 s) and release (0.65 s).
- Fixed client against my stub, nice-only claims (`/root/rv/runs/rc.txt`, `stub.jsonl`): CPU on base-43 fields
  30000, 49999 and a 1e13 field, base-42 25000, bases 4, 5, 7, 10, 27 (whole ranges); CPU join forced on 49999;
  `--gpu` with auto, cuda, cubecl-cuda and cubecl (lavapipe) on 49999 and bases 4, 5, 7, 10. All 30 runs exit 0
  and submit `[]`, except base 10 → `[69]` everywhere. I did not run main's client (the author did, §7).

## Corrections to the description
- Field: the test should use, and the body already names, 60991418181959–60992418181959 (S1); the commit message's
  test paragraph is wrong for the code as committed.
- Add bases 4 and 5 (empty table at k = 3) and qualify "a GPU device should see no difference": at 4 and 5 the GPU
  route falls back to the CPU walk, so they crashed there too and now return no numbers (S2).
- "Who hits it": a CPU client given such a field that takes the stride walk (below 1e13 numbers, or bases outside
  40–64); larger fields at 43–63 take the overlap join and were never affected (N3).
- `stride_filter.rs:165` → "on main" (N4); shorter changelog line (N5).
