**Title:** midout: the exact CPU reference of the middle-out join for a field (library only, unused)

Stacked on #NNN (the field coordinate); review that one first. This adds the definition of the middle-out search: an exact, slow CPU reference that searches a field of the coordinate and says which `n` it examined. It has no GPU code and nothing calls it; it is what the GPU path in the following pull requests will be tested against, number for number.

### What it adds

`common/src/midout/cpu.rs`, `arith.rs`, `mask.rs` (and their entries in `mod.rs`):

- **The search, for one slice** (`slice_join`), with a shape `(f0, k)`: a *top* is a prefix `n div b^f0` certified by the digits of `n²` and `n³` at positions `>= k` that are the same for every `n` it covers; a *bottom* is `n mod b^k`, certified by the low `k` digits of its square and cube. At base 64 the shape is `(4, 10)` and a slice fixes digits 4–8. The slice's bottoms are built from *parents*, bottoms of `k − 1` digits whose digits 4–8 are the slice's, each with one *child* per value of digit 9 (the slice's `b` *units*); its tops are found unit by unit. A (top, child) pair whose classes mod `b − 1` add up to a root, whose digit masks are disjoint and whose `n` lies in the top's interval is a *survivor*; every nice number is one. Survivors go through production's middle-digit prefilter (the same rule as `cpu_join`'s), and the ones that pass get the full check.
- **The field search** (`search_field`): every slice of a field, on several threads, returning `FieldOutcome { nice, survivors, checked, slices }`. `survivors` and `checked` are exact and depend only on the shape and the field, not on the order of work or the device. They mean what production's counters mean: `survivors` passed the join's predicate, `checked` also passed the prefilter and got the full check.
- **The same two counts by brute force** (`q_shape`, `q_checked`): the predicate at one `n`, straight from the definitions (class, top certificate, bottom certificate, disjoint masks; then the prefilter). These are what the tests compare with.
- `arith.rs`: 384-bit arithmetic for `n²` and `n³` and its own nice-ness test and residue roots. It deliberately re-implements what production already has (`client_process`, `residue_filter`): a reference should not reuse the code it checks.
- `mask.rs`: digit masks generic over the word, `u64` up to base 64 and `u128` above, through the same code.

The pairing inside a slice runs over 64-child chunks sorted by a key of frequent digits, skipping a chunk on its common mask. That is the GPU kernel's structure, kept here so that the work counts (`Counts`: chunks, kept tops, words) can later be compared with the device's. Only `survivors`, `checked` and the nice numbers are results; the rest describe the work.

### Why a field is defined this way

(As in #NNN.) A field fixes digits 5–7 at base 64 and nothing else. Any top–bottom search can restrict itself to a field by those digits, and every field is a whole number of slices, so this reference (and the GPU path after it) is free in its shape and in how it cuts a field. The tests below search the same fields with two different shapes and get the same nice numbers.

### What you can check with this pull request alone

Four ordinary CPU tests, plus the coordinate's six. `cargo test --release -p nice_common --lib midout` takes 13 s on a machine with about five cores; nearly all of it is base 25. In a debug build (`just test`) the big test takes about 67 s. Dropping base 25 would bring it to a few seconds, at the cost of the only 5-digit bottom shape in the test.

- `whole_small_bases_vs_brute_force`, the one that matters: eleven small bases (10, 12, 13, 14, 17, 18, 19, 20, 22, 24, 25: every `b mod 5` class with a range, odd and even), one or two shapes each (17 cases). Every field of the base is searched; the survivors found must be exactly the `n` of the whole range that pass the brute-force predicate, each once and each in its own field; `checked` must equal the brute-force count, and every survivor's prefilter verdict must also match one recomputed from the full digits of `n²` and `n³` (`prefilter_direct`, in the test); the nice numbers must equal a brute-force scan of the range (69 at base 10). The whole base is then searched again as one field with `u128` masks and must give the same three results.
- `fields_are_whole_slices_of_the_shape`: at base 64 (and base 65 with the same digit positions) a field is 4,096 (4,225) distinct slices, exactly those with the field's digits 5–7, and sampled `n` of the field all lie in one of them.
- `shapes_that_do_not_fit_are_refused`, and `arith`'s `known_nice_and_roots` (69 is nice in base 10; base 64's roots).

To check that the test can fail, I broke the reference on purpose, one line at a time. Each of these makes `whole_small_bases_vs_brute_force` fail: a prefilter that ignores the top's certified digits; a child kept when the new digits of its square and cube are equal; a top that skips one of its residue classes.

This test is the only place where a mistake in the *definition* of the search could be seen: the GPU path will be compared with this reference, so an error shared by both would pass every later test. It deserves the slow read. The one piece the reference and its brute-force predicate share is `top_cert_split`, the top certificate. It is sound because `n²` and `n³` increase with `n`: digits that are the same at both ends of an interval are the same for every `n` in it. The bottom certificate and the prefilter are each computed twice, independently (`bottoms` incrementally against `bot_cert_direct` from full products; `prefilter` from residues against `prefilter_direct` from full digits).

`just lint` passes, and so do the whole workspace suite as CI runs it (`cargo test --locked --release --no-fail-fast`) and `nice_common --features gpu --lib`.

### What comes next

The GPU path at base 64, in steps: the tops of a slice on the device, then one slice's join with per-stage counts the host checks, then a whole field, each compared with this reference on the CI's software Vulkan device.

**Nothing uses this yet.** No client route, server or other module reaches it. No changelog entry, since no user can see it.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
