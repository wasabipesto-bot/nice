# L52 review: `pr/cpu-join-two-pass-scan` (cd661b0) on #248 (7f5260b)

Independent review, 2026-11-08, on ivory (EPYC-Rome VM, Zen 2, AVX2 only). Read-only on the branch: my own detached
worktree `.worktrees/review-l52` at `cd661b0` with its own target dir; mutations and instrumentation below were
temporary edits there, restored after each run, never committed. Line numbers are `common/src/cpu_join.rs` at `cd661b0`.

## Verdict: merge with small fixes

The change is correct as far as reading and testing can show. On the two paths this machine has (portable,
AVX2) the tests pass, and every one of the seven bugs I planted in pass 1 / the piece loop was caught. The
AVX-512 pass 1 looks right on reading. The speed-up is solid and consistent across the logs. Before merge:

1. **Gate AVX-512 on `avx2` as well** (one line; the new pass 1 executes an AVX2-only instruction on that path).
2. **Run the `cpu_join` tests once on an AVX-512 host.** #204 did this on a Vast Threadripper PRO 7975WX (Zen 4).
   This path becomes the default on every AVX-512 CPU and has never been executed.
3. **Correct the body's coverage claim.** The b57 window does **not** run two-piece classes. It scans nothing.
   No end-to-end test in CI scans a class longer than 141 bottoms (the opt-in production ones reach ~340), so
   nothing end-to-end crosses a piece. Optionally make the piece length lowerable in tests
   so the reference comparison covers multi-piece classes (see M-3).
4. Small: an exhaustive table test, the commit-message wording on "inlined", and body wording (see Low).

None of these is a correctness bug in the shipped code paths I could execute.

## Findings

### Medium

**M-1. The AVX-512 pass 1 has never run anywhere; it becomes the default path on every AVX-512 host**
(`pass1_avx512`, :1000–1011; dispatch :820–831).

My reading of the code and of `L52/raw/pass1-avx512.asm`:
- **Test and mask.** `vpbroadcastq %rdi,%zmm0` (EVEX, AVX-512F), then `vptestnmq (%rsi,%r10,8),%zmm0,%k0` per
  eight bottoms. The memory operand is the 64-byte unaligned chunk, which is in bounds (`as_chunks::<8>`). VPTESTNMQ
  with qword elements sets k[j] iff `src1[j] & src2[j] == 0` for j < 8 and zeroes k[MAX_KL−1:8]. So lane j ↔ bit j ↔
  `masks[at + j]`, the same mapping as the portable byte (`bit i = masks[at+i] & t == 0`, :957) and the AVX2 byte.
  It is also the mapping the old 32-a-step loop relied on, which #204 validated on Zen 4.
- **`kmovw` width.** `kmovw %k0,%r9d` reads 16 bits: the byte plus zeros. The redundant `movzbl` comes from the
  `__mmask8` → `u8` type. `kmovb` would need AVX512DQ, so `kmovw` is the right F-only form.
- **Store width.** `vmovd`+`vpbroadcastw` of the offset, `vpaddw` with the 16-byte `BIT_POS` row, and one 16-byte
  `vmovdqu` to `idx[cnt..cnt+8]`. That is exactly the eight `u16` slots `emit` writes, and they are bounds-checked
  just before (`cmp $-9,%rax; ja` / `cmp %r8,%r9; ja`). This part is byte-for-byte the AVX2 function's tail.
- **Tail.** The scalar store/`cmp $1`/`adc` loop, identical to the AVX2 function's.
- **vzeroupper/ABI.** Both SIMD pass-1 functions are out-of-line `#[target_feature]` functions and end in
  `vzeroupper` (also before the panic calls). Pass 2 and the inlined `survivor` are ordinary code and do not cross
  a target-feature boundary, so I see no ABI or transition concern.

Verdict by reading: correct. But this is the path every Zen 4/5, Sapphire Rapids, Ice Lake and Genoa CPU client
takes from this release on. The PR replaces its loop structure, and the roadmap's own rule (L50 item 1) was to
"measure on one AVX-512 host before the gain is quoted" and keep the old loop if it is slower.

What would pin it:
- **The tests already exist.** On an AVX-512 host, `cargo test --release -p nice_common cpu_join::` runs:
  - `the_first_pass_lists_the_same_bottoms_on_every_path` with an `avx512` arm against the plain filter, over all
    256 byte values (instrumented: every byte occurs ≥ 4 times with this seed);
  - its `each_pass` part with AVX-512 as the best dispatch;
  - `every_scan_finds_the_same_pairs` with AVX-512 as `best`;
  - `check_partitions` against the reference join.
- **The missing piece is a host.** Options, cheapest first:
  - (a) a Vast Zen 4 box for 10 minutes: tests plus one b60 1e16 A/B, as #204 did. Pennies, inside the program's
    $30/month.
  - (b) a CI job under Intel SDE (`sde64 -spr -- <test binary> cpu_join::`), with an env such as
    `NICE_REQUIRE_AVX512=1` that makes `pass1_paths` assert the arm ran. That mirrors `NICE_REQUIRE_NVRTC` in
    `rust-build-test.yml`.
  - (c) at minimum, log the runner CPU in CI (`grep -m1 'model name' /proc/cpuinfo; grep -ow avx512f /proc/cpuinfo
    | head -1`) and run the new test with `--nocapture` so its "first pass on [...]" line shows.
- **CI today tells you nothing.** I fetched the logs of runs 42358661620 (Rust build/test) and 42358661629 (GPU
  parity) of 2026-11-07. Neither shows the CPU model. The only CPU-adjacent line is lavapipe's
  `llvmpipe (LLVM 20.1.2, 256 bits)`, which does not settle AVX-512. Test stderr is captured on pass. Whether a
  given CI run executes the AVX-512 arm is therefore unknown and may vary between runs (the runner pool is mixed).
- **Precedent.** `scratchpad/2026-10-next-steps/prs/cpu-join-speedups.md` (#204): "`every_scan_finds_the_same_pairs`
  passes, so AVX-512, AVX2 and the portable loop agree" on a 7975WX. The new PR should carry the same line.

**M-2. AVX-512 is selected on `avx512f` alone, but `pass1_avx512` executes an AVX2 instruction**
(:467, SAFETY comment :823, test helper :1241).

`emit` is inlined into `pass1_avx512`. Compiled under `avx512f`, which in rustc implies `avx2`, its offset
broadcast is the VEX-encoded `vpbroadcastw %xmm1,%xmm1`, an AVX2 instruction. The EVEX form would need
AVX512BW+VL. You can see it in the PR's own `raw/pass1-avx512.asm`.

So on a CPU or VM that reports AVX-512F without AVX2 the join would SIGILL. More to the point, the `unsafe` call's
SAFETY comment ("only set where the CPU has AVX-512F") does not cover the features the function is compiled with.
`stride_filter::best_phase1_impl` (stride_filter.rs:493–504) already requires both, with the comment "a VM can
expose one without the other".

The old `scan_avx512` had the same gate, but this PR is what puts an AVX2-only instruction on the path. It is a
one-line fix, so it belongs in this PR rather than in "Not in this PR":

```rust
// :466-467
#[cfg(target_arch = "x86_64")]
avx512: std::arch::is_x86_feature_detected!("avx512f")
    && std::arch::is_x86_feature_detected!("avx2"),
```

Also update the SAFETY comment at :823 ("AVX-512F and AVX2, which `avx512f` implies for code generation"), and use
the same condition in the test helper at :1241. stride_filter's test helper at stride_filter.rs:1048 has the same
test-only gap; that is out of scope here.

**M-3. The body's claim that the end-to-end tests run classes in two pieces is false; nothing end-to-end scans a
class longer than 141 bottoms.**

PR-BODY "Tests" says: "One test window (b57 at 20635899893042801193, t = 9, k = 5, p = 1) has classes of
1353–1439 bottoms, so those comparisons also run classes in two pieces". PR-RESULTS "Interpretation notes" says
the same.

I instrumented `scan` (temporary `#[cfg(test)]` counters: scans, longest class, classes > `PIECE`) and ran both
end-to-end comparisons:
- **That window performs 0 scans.** Neither `cpu_join_matches_the_reference_on_the_test_windows` nor
  `every_scan_finds_the_same_pairs` (which runs every partition) has a single top there. Its large classes are
  listed (presumably what the throwaway test measured) but never scanned. The b57 [3e19, +3e5), b30, b34 and b60
  windows also scan nothing.
- **The longest class any window scans** is 141 bottoms (b50), then 124 (b54) and 61 (b57 p = 2). Only six of
  the 18 windows ever scan a class of 8 or more, so `emit` runs at all. Four scan only 1-bottom classes, three
  only classes of 3–7, so only the tail runs for them. The production shapes in the opt-in test have ~300
  (max 340).
- **So a class longer than a piece is exercised only by the synthetic `each_pass` part of the new test** (lengths
  1025 / 2085 / 5120). That part is effective: it caught the planted piece-offset bug (M5 below). Note that no
  production shape comes near 1024 either.

Fix:
- **Required:** remove or correct the claim in both files.
- **Optional, cheap, and the better test:** make the piece length something tests can lower, as they already lower
  `avx2`/`avx512`. For example, a `piece: usize` field on `CpuJoin`, set to `PIECE` in `new` and used by
  `each_pass` (with `debug_assert!(piece <= PIECE)`). Then add a lowered-piece join (say 9 or 16) to `lesser` in
  `every_scan_finds_the_same_pairs`, and/or a `check_partitions` variant. My P9 run below changed the constant to
  9 and the whole end-to-end `cpu_join` suite still passes, so that variant would pass today and would compare
  multi-piece scans against the reference join from then on.

### Low

**L-1. No exhaustive check of the two tables** (:73–102). The random test happens to reach every byte value: I
counted `emit`'s inputs, and all 256 occur, the rarest 4 times. But that is a property of the fixed seed, not of
the test's design. A structural test costs nothing:

```rust
#[test]
fn the_bit_tables_list_every_byte() {
    for b in 0..=255u8 {
        let want: Vec<u16> = (0..8).filter(|i| b >> i & 1 == 1).collect();
        let n = usize::from(BIT_CNT[usize::from(b)]);
        assert_eq!(n, b.count_ones() as usize, "{b:#04x}");
        assert_eq!(BIT_POS[usize::from(b)][..n], want[..], "{b:#04x}");
    }
}
```

`BIT_CNT` could also simply be `t[byte] = (byte as u8).count_ones() as u8` (const-callable), which reads better
than the `t[byte / 2] + t[byte % 2]` recurrence at :98. Both are correct.

**L-2. `pass1`'s length contract is implicit** (:820). `pass1_*` index with a `u16` `at` and need
`masks.len() <= idx.len()` and `<= 65535`. Only `each_pass` guarantees this. Writes are bounds-checked, so a
violation panics or produces wrong indices rather than writing out of bounds. A
`debug_assert!(masks.len() <= PIECE && idx.len() >= PIECE)` at the top of `pass1` documents and checks it in
debug builds for free.

**L-3. Commit message: "Pass 2 takes the listed bottoms … through the survivor code (the in-range test, the
prefilter, the full check), now inlined."** This reads as if the full check were inlined; it stays a call, as the
body says. Suggest "…through the survivor code, now inlined (the full check stays a call)".

**L-4. Body wording**:
- (a) Soundness says "The hits and the checked numbers come out in the same order (`every_scan_finds_the_same_pairs`
  compares whole `PartitionResult`s, hits in order)". A `PartitionResult` holds counts plus hits, and the windows
  have at most one hit per partition (b10's 69), so that test cannot see order. Every end-to-end comparison is
  order-insensitive: `check_partitions` sorts. My planted order swap (M2) and the reversed pass 2 (M10) passed
  every end-to-end test. **The order is pinned only by the new test**, which compares the index lists in order.
  Reword to say that. Order does not affect correctness anyway: `run_all` sorts hits, and the client takes sets.
- (b) "`vpand`, `vpcmpeqq` and `vmovmskpd` on AVX2": these are the intrinsics. The compiled code
  (`raw/pass1-avx2.asm`) merges the two compares with `vpackssdw` + `vpermq` and a single `vmovmskps`. That is
  harmless and LLVM's doing, but the body describes the code it read for AVX-512, so it should say the same for
  AVX2 or drop the instruction names.
- (c) "Not in this PR → The AVX-512 path's detection is unchanged": move this into the PR (M-2).
- (d) The AVX-512 bullet should state what will be run before merge (M-1), not only the estimate.

**L-5. Three meanings of "pass".** In this file "pass" now means the `Pass` struct (a scan's context), the scan's
first and second passes, and a bottom that passes the AND. `each_pass` reads as "each of the passes", but it
means "each passing bottom". Consider `for_each_passing` and `list_passing{,_any,_avx2,_avx512,_rest}`. Optional.

**L-6. `NICE_SIMD` does not reach the CPU join** (pre-existing). `stride_filter` honours `NICE_SIMD=avx2|0`, but
`cpu_join` always takes the best detected path. If the never-run AVX-512 pass 1 misbehaved on some host, an
operator could not turn it off without a release. Not for this PR (it would be a new knob, needing its own
approval), but worth a follow-up note.

### Info (checked, no action)

- **Exactness of the pass-bit bytes.**
  - Portable (:955–958): `u8::from(m & t == 0) << i`, i < 8.
  - AVX2 (:982–988): `cmpeq(and(v, t), 0)` per 4 lanes, `movemask_pd` takes lane sign bits in lane order,
    `to_le_bytes()[0]` holds bits 0–3, and `<< 4*q` places q = 1 in bits 4–7. The `u8` shift never loses bits.
    LLVM's pack/permute rewrite keeps that order; I followed it through.
  - AVX-512: see M-1.
  - All three are the old predicate, `m & t == 0`.
- **The tables are correct for every byte.** By reading: `BIT_POS[b]` lists set bits ascending then zeros, and
  `BIT_CNT` is popcount by the recurrence. By instrumented test: all 256 bytes go through `emit` and the lists
  match the filter on both local paths.
- **Bounds.**
  - `emit` writes `idx[cnt..cnt+8]` with `cnt <= at <= len − 8`, so the slots end at most at `len <= PIECE`.
  - `pass1_rest` writes `idx[cnt]` with `cnt <= j < len`.
  - u16 indices stay ≤ 1023 and `at` ≤ 1024.
  - The compiled code has two predictable compares per eight bottoms plus one per tail bottom.
  - No new `unsafe` beyond the SIMD loads and target-feature calls, whose pattern the old code had.
- **Memory.** `idx` is 1024 × u16 = 2 KiB per thread in `Scratch`, `resize`d at the top of each `run` (:537; a
  no-op after the first partition). There is no per-call allocation. The tables are `static` (4 KiB + 256 B), not
  `const`, so they are not copied.
- **Pieces and order.**
  - `each_pass` (:808–815): `(0..).step_by(PIECE).zip(masks.chunks(PIECE))` gives each piece's start, and pass 2
    adds it.
  - A class longer than a piece is split in order. Pass 2 visits `idx[..n]` ascending, and `survivor` gets
    `masks[j]`/`j` class-local, exactly as before.
  - `survivor`'s body is unchanged apart from `#[inline(always)]`; prefilter and full check are still the same calls.
- **Dead code.** None: the old `scan_avx512`/`scan_avx2`/`scan_any` are gone, with no stale references in code or
  docs.
- **CHANGELOG line.** One sentence, in the file's style, `#NNN` placeholder. Fine (the user prefers short ones).

## Mutation testing (what the tests catch)

Each row is one deliberate bug, built in release and run against all 14 non-ignored `cpu_join` tests.

| mutation | where | caught by |
|---|---|---|
| M1: `BIT_POS[0xFE]` last entry 7 → 6 (a rare byte, 7 bits set) | table value | **new test only** |
| M2: `BIT_POS[0x5A]` entries 3, 4 swapped | table order | **new test only** (order is invisible end-to-end) |
| M3: `BIT_CNT[0xDF]` 7 → 6 | count table | new test + reference windows |
| M4: AVX2 byte halves swapped (`lanes << 4*(1−q)`) | AVX2 byte order | new test + reference windows + `every_scan` + slices |
| M5: piece offset `step_by(PIECE + 1)` (wrong from the 2nd piece on) | piece boundary | **new test only** (its `each_pass` part) |
| M7: a piece's last tail bottom never listed | 0–7 tail, off by one | new test + reference windows + stride + b10's 69 + slices |
| M10: pass 2 walks the list in reverse | pass-2 order | **new test only** |
| P9 (not a bug): `PIECE` = 9, so every class of ≥ 10 bottoms is split | multi-piece end-to-end | all 13 other non-ignored `cpu_join` tests pass (the new test is skipped: its fixed lengths assume `PIECE` ≥ 1024) |

The new test catches all seven. The end-to-end tests catch the bugs that hit common bytes or every tail (M3, M4,
M7), but none of the rare-byte, order or piece-boundary ones (M1, M2, M5, M10). This is expected: their classes
are short, and they compare sets, not order.

## Claims check (PR-BODY against PR-RESULTS and `raw/`)

| claim | evidence | verdict |
|---|---|---|
| ×1.266 / ×1.237 (b60 1e16 / b62 1e17 s0, 1 t), ×1.260 / ×1.237 (4 t) | `raw/ab-summary.txt`: medians and per-round ratios recomputed (e.g. 2378/1860 = 1.278, 2346/1922 = 1.221) | ✓ |
| "every single round ×1.22–1.28" at production shapes | per-round min 1.221, max 1.278 | ✓ |
| b58 ×1.300 / ×1.316; whole 1e14 ×1.08–1.18 | `ab-summary.txt`, `ab-summary-whole1t.txt` | ✓ |
| b64 1e14 has 4.3× b60's join survivors for 1.14× the partitions | 5,702,041,796 / 1,326,103,590 = 4.30; 4096/3600 = 1.14 | ✓ |
| Mispredictions −59 to −63 %, IPC 2.18 → 2.81, instructions +3–4 %, branches +5–8 %, cycles −19 to −21 % | `perfstat-summary.txt`: −58.7 % / −62.8 %, +4.1 / +3.0, +7.8 / +5.2, −19.2 / −20.5 | ✓ (−58.7 rounds to 59) |
| NiceMark ×1.261 (864.9 → 1091.0), per round 1.280 / 1.277 / 1.257 / 1.222 | `nicemark-summary.txt` recomputed; runs gated at 1-min load ≤ 2 (1.85–1.98, `nicemark-runs.txt`) | ✓ |
| #248's NiceMark 864.9 within 0.5 % of its own PR's 868.5 | 0.41 % | ✓ |
| Every timed run of both sides has #248's counts | `ab-summary*.txt` count columns; NiceMark within-side counts agree | ✓ |
| Whole b42 417,789,835 / 16,879,877, join = reference = stride | **reproduced** (my run: same counts, no hits) | ✓ |
| `NICE_TEST_CPU_JOIN_REF=3` ok | **reproduced** (25.6 s) | ✓ |
| 189 nice_common tests pass, 6 ignored | **reproduced** | ✓ |
| fmt / clippy `-D warnings` clean | **reproduced** (see below) | ✓ |
| AVX-512 pass 1 is `vptestnmq`, `kmovw`, two table loads, `vpaddw`, one 16-byte store, AVX-512F/AVX2 only | `raw/pass1-avx512.asm` | ✓; the "AVX2 only" part is why M-2 matters |
| CI runner CPU unknown | confirmed from two 2026-11-07 runs' logs | ✓ |
| "One test window (b57 …) has classes of 1353–1439 bottoms, so those comparisons also run classes in two pieces" | instrumented: that window scans 0 classes; max scanned class anywhere 141 | **✗** (M-3) |
| "`every_scan_finds_the_same_pairs` compares whole `PartitionResult`s, hits in order" (as evidence of order) | true statement, but it cannot detect order changes (M10 passes it) | misleading (L-4a) |
| The chunk-branch story (1 − 0.97¹⁶ ≈ 0.39, ~30 M misses, half the partition's) | arithmetic ✓; shares from `L50/ROADMAP.md` §1.2 (50.0 % / 49.8 %) | ✓ |
| AVX-512 estimate ×1.08–1.15 | estimate, labelled as such, unmeasured | fine as labelled; see M-1 |

The A/B method is sound: release builds of both heads, alternating order, load-gated, counts compared. The
4-thread and later 1-thread runs started at loads up to ~2.9 because of the preceding runs, equally for both sides.

## What I ran (all under `nice -n 19`, release only; target peaked at 1.6 GB, removed at the end)

Scripts, logs and the instrumentation output are in `L52/raw/review/`.

- `cargo test --release -p nice_common` on `cd661b0`: **189 passed, 0 failed, 6 ignored**. The new test printed
  `first pass on ["portable", "avx2"]: 84860 bottoms listed alike`.
- `NICE_TEST_CPU_JOIN_REF=3 … cpu_join_matches_the_reference_on_production_fields`: ok, 25.6 s (b42 0.7, b50 11.5,
  b57 4.8, b60 1.7, b62 2.3, b64 4.6 s).
- `NICE_TEST_JOIN_FULL_FIELD=1 … cpu_join_matches_the_reference_on_a_whole_field`: ok, 1764 partitions,
  417,789,835 join survivors, 16,879,877 checked, no hits. On 4 threads: reference 115 s, join 15.5 s, stride
  151 s. These are slower than the author's because my mutation builds ran alongside.
- `cargo fmt --all --check`: clean. `cargo clippy -p "*" --all-targets -- -D warnings` (default features, rustc
  1.99.1, i.e. the first clippy line of `just lint`): clean, 0 warnings. I did not run `just lint`'s second
  clippy line (`--features nice_client/gpu,nice_client/cubecl-spirv`). `cpu_join.rs` has no feature-gated items,
  but CI does run that line.
- Instrumentation (temporary `#[cfg(test)]` counters in `emit` and `scan`): byte coverage of the new test and
  scan/class-length statistics per window in both end-to-end tests (M-3, L-1).
- Seven mutations plus a PIECE = 9 run (table above).
- Read the CI logs of upstream runs 42358661620 and 42358661629 (`gh run view --log`) for CPU information.
- Read `raw/pass1-avx512.asm` and `raw/pass1-avx2.asm`, the summaries and run logs in `raw/`, and the #204 notes.
- Not run: an AVX-512 host (none available; no SDE or qemu on ivory, and I did not install one), `nice_client`
  tests (the PR does not touch the client), GPU-feature clippy (`cpu_join.rs` has no feature-gated items).
