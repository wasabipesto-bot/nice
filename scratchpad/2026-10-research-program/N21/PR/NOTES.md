# N21 PR: notes (2026-11-13, 16:20–16:40 UTC, ivory only)

## Branch

- Fork `pr/join-prefilter-popcount` = **`d32c5b49`**, one commit on upstream main `a7a59c11` (as briefed). Plain push,
  new branch, accepted. Worktree `~/projects/nice/.worktrees/n21-pr`.
- Upstream main has since moved to `41b4b405`: #258 (rust-toolchain 1.99.1 → 1.100.0) and #257 (cc 1.11.1), both
  Dependabot, neither touching `cubecl_join.rs` or `CHANGELOG.md`. `git merge-tree --write-tree origin/main d32c5b49`
  is clean. My checks used the pin of `a7a59c11` (1.99.1); 1.100.0 is not installed on ivory, so CI on the PR (which
  will build the merge with 1.100.0) is the first run under the new toolchain.

## What I changed against the candidate `3a4899ee`

Code: nothing. `git diff 3a4899ee d32c5b49 -- common/src/cubecl_join.rs` has only comment lines (checked by filtering
non-`//` lines: none). So every device test of the candidate binary (CMw / CMwn) applies to this commit's code.

- `walk_pf_lean` doc: restated the identity precisely (A built in the masks' bit-reversed order, `2^63 >> d`, digits
  < b ≤ 64; `A & !seen` = one bit per distinct unseen digit) and why CUDA is excluded, with numbers from the evidence:
  ACO 8 fewer ALU per walk round (RESULTS §4: 52 → 44), NVIDIA +4 SASS per round (§5: 78 → 82 loop, 42 → 46 no-pass
  round), "1-2 % slower on an RTX 3080" (§5).
- `join_kernel` doc: it said the prefilter reads digit g as the sign bit of `hi32(seen << g)`; added the count form
  (bit 63 − g of the digits' mask), else that doc would be wrong off CUDA.
- `JoinDevice` init comment: points to the doc and says CUDA's kernel is unchanged (the candidate's comment there
  explained only the mechanism).
- CHANGELOG line (end of Unreleased, `#NNN` placeholder): "Speed up the GPU overlap join's middle-digit prefilter on
  AMD GPUs (on every runtime but CUDA) by testing its four digits with one population count instead of six
  comparisons".
- Commit message rewritten to match.

## Reading the diff: what is and is not as the study describes

- **Set identity: correct.** With seen bit-reversed (digit d at bit 63 − d), `0x8000…0 >> d` is digit d's bit; A has one
  bit per element of D = {g2, g3, h2, h3}; popcount(A & !seen) = |D \ seen| = 4 iff |D| = 4 and D ∩ seen = ∅. Holds for
  any values < 64 (not only < b), so no dependence on the fixed-point bound beyond d < 64 (shift amount in range).
  Word split matches today's `seen`: low word of A (digits 32–63) against `mlo | tlo`, high word (0–31) against
  `mhi | thi`.
- **Comptime switch: as described.** `pf_count: !R::name(client).contains("cuda")`. CubeCL 0.10.0 names: CUDA `"cuda"`,
  HIP `"hip"`, wgpu `"wgpu<spirv>"`/`"wgpu<wgsl>"`/Metal/DX12 variants (`cubecl-*-0.10.0/src/runtime.rs`). So HIP gets
  the count form too (unmeasured; would include HIP on NVIDIA, if anyone ran that). `pf_count` is used only in the one
  `walk_pf_lean` call (lean path; `walk_pf` untouched).
- **Not quite as the study says (two points):**
  1. *CUDA timing was of P+M, not M alone.* Every RTX 3080 timing (§5, `raw/ab_table.txt`: modes 9, 73, 41, 137) has
     the cheaper pop (P) in it; M alone (mode 8) was never timed on CUDA. The attribution to M rests on P's SASS having
     mode 0's instruction mix (§5, the discarded first protocol paragraph) and M's SASS being +4 per round
     (`raw/box/sass/s62_8`). The brief's "population-count form everywhere was 1–2 % slower" is that inference; the PR
     body says it was timed together with the pop change.
  2. *The RX 9070 XT measured mode 8 of `exp/n21-walk-loop` (2d3e10d3), not this code.* Same algorithm, different
     text: mode 8 writes `alo & (sl ^ 0xFFFF_FFFF)` through mutable `alo`/`ahi`, the candidate `u32::cast_from(a) &
     !(mlo | tlo)` directly; and the measured base has #255 (b64 digits by shifts) and #256. RESULTS §6's "on wgpu it
     is mode 8's code" is true semantically, not byte for byte; ACO was never run on the candidate's own SPIR-V. I
     expect NIR to canonicalise `x ^ ~0` to `inot` and to promote the locals, so the same ACO code, but that is not
     checked. The PR body says the change was measured behind a switch on main + #255 + #256.
- **lavapipe "8/8"**: three of the eight (`fx_digits_are_exact_everywhere`, `join_matches_the_reference_on_a_whole_field`,
  `join_throughput_fixed_fields`) print "skipping" and return without their opt-in variables
  (`raw/box/logs/t/lvp_CMw_0.log`); five ran. The body says so.

## Checks on ivory (toolchain 1.99.1, `CARGO_TARGET_DIR=~/projects/nice/.worktrees/rebase-1112/target`)

| check | result | log |
|---|---|---|
| `cargo fmt --all --check` | rc 0, no output | `N21/PR/fmt.log` |
| `nice -n 19 cargo clippy -p nice_common --all-targets --features cubecl -- -D warnings` | rc 0 | `N21/PR/clippy.log` |
| `nice -n 19 cargo test --release -p nice_common --features cubecl cubecl_join` | 7 passed, 8 ignored (device), incl. `lean_membership_matches_the_masks`, `lean_prefilter_matches_the_division_form`, `fx_digits_match_the_division` | `N21/PR/test.log` |
| `nice -n 19 cargo test --release -p nice_common --features cubecl` | 233 passed, 0 failed, 34 ignored | `N21/PR/test-all.log` |

`--release` (not in the brief) because the shared target already had release artefacts; it cost ~0.9 GB (disk now
5.7 GB free). No GPU features built.

## Evidence that CUDA's kernel is unchanged (step 3)

**It rests on reading the comptime switch only.** No generated CUDA source, PTX or SASS of the candidate (CMw) was
compared against main, and CMw was never run on CUDA: RESULTS §7 says "CMw's CUDA kernel is today's (its switch is off
on CUDA), so its CUDA run would repeat main's", and no `cuda_CMw` / `x_CMw_*` log exists in `raw/box/logs/t/`
(only CM, CP, X, X4). The kernel-id identity in RESULTS §1 (`0xa7510423e66e1ef2`) is for mode 0 of the experiment
branch's SPIR-V dumps on lavapipe, not for CMw on CUDA, so it does not cover this. The argument: `pf_count` is a
`#[comptime]` bool, false when `R::name` is `"cuda"`; `if comptime!(count) { … } else { … }` expands only the `else`
block, which is main's code verbatim (the diff moves it into the `else` unchanged, sign-test comment reflowed). One
expected difference: the extra comptime argument enters CubeCL's kernel id, so the CUDA kernel's cache key changes
(a one-time recompile), not its source. A CUDA-source diff (`CUBECL_DEBUG_LOG`, as the #255 body did) would close this
on any CUDA box; it needs a GPU and was not done.

## Device tests the candidate binary passed (RESULTS §7 and logs)

- CMw (`gpu,cubecl-spirv`, md5 198ef7e2) and CMwn (`gpu`, naga, md5 86e31c9c): lavapipe `--ignored
  cubecl_join::tests:: --skip cuda`, **8 passed each** (5 ran, 3 skip-returns), incl. the b64 window
  (11,4,2) "agrees" (`raw/box/logs/t/lvp_CMw_0.log`, `lvp_CMwn_0.log`; summary `raw/box/out/after_ab.out` l.74–75).
- CMw host: 247 passed (`host_CMw.log`); fmt/clippy `gpu,cubecl-spirv` clean (`fmt_CMw.log`, `clippy_CMw.log`).
- Count form on CUDA, other binaries: X mode 8 dense compares b60/b62/b64 ok (`x_X_8_b6*.log`); CM (count form
  everywhere, same count code as CMw) dense compares ok (`x_CM_0_b6*.log`) and CUDA suite 7/7 (`cuda_CM.log`).
- RX 9070 XT: the E-mode-8 timed runs gave identical counts (`raw/demoux/go.out`).

## Numbers in the body and where they come from

- 9070 XT seconds/ratios: `WINDOW-RESULTS.md` and `raw/demoux/go.out`, `m{0,8}_b6{2,4}_r*.log`. Clock medians
  recomputed from `m*_*.gpu` (samples at ≥ 99 % busy): b62 base 3129/3092/3088, count 3102/3095/3089 MHz; b64 base
  3035 (r1), count 3007 MHz; power medians 303–304 W. b64 count: **one round**; b62: three.
- CUDA ×0.989/×0.981/×0.987 and 78 → 82 SASS: RESULTS §5, `raw/ab_table.txt`.
- ACO table: RESULTS §4 rows "0 default", "8 M", "b64 0", "b64 8 M".
- Cheaper pop "×1.01–1.02 more": m9 over m8, b62 1.049/1.037 = 1.012, b64 1.100/1.080 = 1.019 (one round).

## Would not sign off without saying

- "CUDA unchanged" is by construction, not by a compared kernel (above).
- The PR's code was not itself timed or ACO-counted on the RX 9070 XT; the measured kernel is mode 8 on
  main + #255 + #256. On main alone the b64 digits are four `mul_hi`, so the b64 ratio on main may differ.
- b64 ×1.080 is one round.
- Metal (6 % of the search on the M4), HIP and DX12 get the count form unmeasured; the study's own guess (§8) is that
  Apple, with per-lane predicate compares, may lose ~1 % like NVIDIA. If the director wants it gated to Vulkan until the
  M4 is measured, that is a one-line change to the `pf_count` expression.
