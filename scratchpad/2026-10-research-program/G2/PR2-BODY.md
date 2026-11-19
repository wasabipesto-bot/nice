**Title:** midout: the exact CPU reference of the middle-out join for a field (library only, unused)

Stacked on #NNN (the field coordinate); review that one first. This adds the definition of the middle-out search: an exact, slow CPU reference that searches a field of the coordinate and says which `n` it examined. It has no GPU code and nothing calls it; it is what the GPU path in the following pull requests will be tested against, number for number.

### What it adds

`common/src/midout/cpu.rs`, `arith.rs`, `mask.rs` (and their entries in `mod.rs`):

- **The search, for one slice** (`slice_join`), with a shape `(f0, k)`: a *top* is a prefix `n div b^f0` certified by the digits of `n²` and `n³` at positions `>= k` that are the same for every `n` it covers; a *bottom* is `n mod b^k`, certified by the low `k` digits of its square and cube. At base 64 the shape is `(4, 10)` and a slice fixes digits 4–8. The slice's bottoms are built from *parents*, bottoms of `k − 1` digits whose digits 4–8 are the slice's, each with one *child* per value of digit 9 (the slice's `b` *units*); its tops are found unit by unit. A (top, child) pair whose classes mod `b − 1` add up to a root, whose digit masks are disjoint and whose `n` lies in the top's interval is a *survivor*; every nice number is one. Survivors go through a middle-digit prefilter, the same rule as production's (`cpu_join`'s) computed independently, and the ones that pass get the full check.
- **The field search** (`search_field`): every slice of a field, on several threads, returning `FieldOutcome { nice, survivors, checked, slices }`. `survivors` and `checked` are exact and depend only on the shape and the field, not on the order of work or the device. They are the same kind of count as production's `survivors` and `checked`, for this join's shape (the numbers are not comparable with the overlap join's): `survivors` passed the join's predicate, `checked` also passed the prefilter and got the full check.
- **The same two counts by brute force** (`q_shape`, `q_checked`): the predicate at one `n`, straight from the definitions (class, top certificate, bottom certificate, disjoint masks; then the prefilter). These are what the tests compare with.
- `arith.rs`: 384-bit arithmetic for `n²` and `n³` and its own nice-ness test and residue roots. It deliberately re-implements what production already has (`client_process`, `residue_filter`): a reference should not reuse the code it checks.
- `mask.rs`: digit masks generic over the word, `u64` up to base 64 and `u128` above, through the same code.

The pairing inside a slice runs over 64-child chunks sorted by a key of frequent digits, skipping a chunk on its common mask. That is the GPU kernel's structure, kept here so that the work counts (`Counts`: chunks, kept tops, words) can later be compared with the device's. Only `survivors`, `checked` and the nice numbers are results, and only they are tested; the work counts are documented field by field and no test checks them yet.

### Why a field is defined this way

(As in #NNN.) A field fixes digits 5–7 at base 64 and nothing else. Any top–bottom search can restrict itself to a field by those digits, and every field is a whole number of slices, so this reference (and the GPU path after it) is free in its shape and in how it cuts a field. The tests below search the same fields with two different shapes and get the same nice numbers.

### What you can check with this pull request alone

Seventeen CPU tests in `cpu.rs` and `arith.rs`, plus the coordinate's six, all ordinary. On a machine with about five cores, `cargo test --release -p nice_common --lib midout` takes 11 s and the debug build that `just test` uses 54 s, most of it base 25 (no single test reaches libtest's 60-second warning).

- `whole_base_<b>_vs_brute_force`, one test per base, the ones that matter: eleven small bases (10, 12, 13, 14, 17, 18, 19, 20, 22, 24, 25: every `b mod 5` class with a range, odd and even), one or two shapes each (17 cases). For each, the join runs over every field of the base, and the survivors must be exactly the `n` of the whole range that pass the brute-force predicate, each once and in its own field. `checked` must equal the brute-force count, and every survivor's prefilter verdict must match one recomputed from the full digits of `n²` and `n³`. The nice numbers must equal a brute-force scan of the range. Then the field search itself: the whole base as one field with `u128` masks, and the first field with `u64` masks, must give the same counts and nice numbers. Honest coverage: nine of the bases have survivors (bases 12 and 19 have none in their shapes, so they only test that nothing is found); the prefilter is exempt over all of bases 10–14; the only nice number in these ranges is 69 at base 10.
- `top_certificate_equals_its_definition`: the top certificate against the digits that are the same for *every* `n` of the interval, computed one `n` at a time, on seven base and shape pairs including three with `f0 = 0`, where the certificate reaches the positions the prefilter uses.
- `roots_equal_production_residue_filter`: the residue classes against production's `residue_filter`, bases 3–128. (The reference still computes its own; comparing with production in a test is not reusing it.)
- `prefilter_at_base_64_equals_full_digits`: the prefilter at base 64, shape `(4, 10)`, on 100,000 random `n` and random top digits, against the full digits of `n²` and `n³`. This is the only test of the 128-bit modular arithmetic base 64 uses; no small base reaches it.
- `fields_are_whole_slices_of_the_shape`: at base 64 (and base 65 with the same digit positions) a field is 4,096 (4,225) distinct slices, exactly those with the field's digits 5–7, and sampled `n` of the field all lie in one of them.
- `shapes_that_do_not_fit_are_refused`, and `arith`'s `known_nice_and_roots` (69 is nice in base 10; base 64's roots).

**What the reference and its brute-force predicate share**, since an error in a shared piece would pass the whole-base tests and every later GPU test: the top certificate (`top_cert_split`), the residue classes (`roots`), nice-ness (`unique_digits`, used by both the search's full check and the brute-force scan), the clipping of a top's interval to the base's range, and the prefilter's exemption for small `n` (the same condition in `prefilter` and in the test's full-digit version). The new tests check the first two independently, and the prefilter's arithmetic at base 64. Nice-ness and the clipping rule are short and read directly. The exemption is the same text on both sides (when `n²` may have fewer than `k + 2` digits). The bottom certificate is computed twice, independently (`bottoms` incrementally, `bot_cert_direct` from full products).

To check that the tests can fail, the reference was broken on purpose, one line at a time: 27 one-line faults in the top certificate, the bottoms and children, the prefilter and its arithmetic, the roots, nice-ness, the class pairing, the interval clipping and the leads. 24 make at least one test fail. Before the three independent tests, six of these passed: a top certificate one or two digits short, its upper part missing position `k + 2` or taking position `k + 1` (that one silently drops nice numbers), an extra residue class below base 64, and a wrong 128-bit modular product at base 64. All six now fail. Three still pass, as expected: reversing the chunk key's order and disabling the chunk's common-mask skip change only the work counts, not the result. Changing the small-`n` exemption in both the prefilter and its full-digit check alike changes nothing these bases reach, because `n²` is still long enough.

`just lint` passes, and so does the whole workspace suite as CI runs it (`cargo test --locked --release --no-fail-fast`), and `nice_common --features gpu --lib`.

### What comes next

The GPU path at base 64, in steps: the tops of a slice on the device, then one slice's join with per-stage counts the host checks, then a whole field, each compared with this reference on the CI's software Vulkan device.

**Nothing uses this yet.** No client route, server or other module reaches it. No changelog entry, since no user can see it.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
