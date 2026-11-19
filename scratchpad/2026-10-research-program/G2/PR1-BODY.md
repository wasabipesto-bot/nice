**Title:** midout: the field coordinate for a middle-out nice-only search (library only, unused)

This is the first of a series of stacked pull requests for a new nice-only GPU search at base 64, the "middle-out join" (a working name; the module is `midout`). This one adds only the unit of work: what a field of the new kind is. It has no GPU code, no client route and no server change, and nothing calls it.

### What it adds

`common/src/midout/coord.rs` (with `mod.rs` and one `mod` line in `lib.rs`):

- A per-base coordinate `v`: a fixed renumbering of `n` that moves digits 4–7 of `n` above all the others and keeps the rest in order. At base 64 the range is exactly `[2^75, 2^76)`, so `v` is a permutation of the bits of `n` (bits 24–47 move up to bits 51–74), written out in the module docs.
- `v_of_n` / `n_of_v`, the *quantum* (one value of the field's fixed digits), `field_digits` (which digits a field `(base, v_start, v_size)` fixes; anything that is not whole quanta is refused) and `n_count` (how many `n` a field holds). A `Coord` can only be built by `Coord::for_base` or `Coord::with_digits`, which check the digit positions and that `v` fits in a `u128`; its values are read through getters.
- At base 64 a field of one quantum is every `n` with one value of **digits 5–7**: `2^57` numbers, 262,144 fields for the base, each exactly 4,096 *slices* (a slice: one value of digits 4–8, the unit the search works on).
- The formula is written for any base. Where a base's range does not start and end on multiples of `b^k1` (`k1` = 8 at base 64), some `v` have no `n` (padding, `n_of_v` returns `None`). Only base 64 has a coordinate (`Coord::for_base`); the other bases appear in the tests, to check the formula in its general form on small bases where every `n` can be visited.

### Why a field is defined this way

- A field commits the project to one thing only: it is the set of `n` whose digits 5–7 lie in a range. The order of `v` inside a quantum is not part of that.
- Any search that splits `n` into a top part and a bottom part (today's overlap join included) sees every digit of `n` on one side or the other, so it can search a field by filtering on those three digits.
- Every field is a union of whole slices, so how the search cuts a field inside (its shape, kernels, chunking, order and mask width) stays free and can change without changing what a field is. What a field fixes is a per-base choice: another base could use other digits.
- Why digits 5–7: they are the middle of a slice's digits 4–8, so the two ends, digits 4 and 8, stay free inside a field, and neighbouring slices of a field can share preparation on both the top and the bottom side.
- This pull request proposes no field row, claim format or API. No server stores this coordinate.

### What you can check with this pull request alone

Six ordinary CPU tests in `coord.rs` (`cargo test -p nice_common --lib midout`: 0.2 s in release, 0.6 s in a debug build):

- `small_bases_bijection_and_counts`: on nine small bases (each `b mod 5` class with a range, padded and unpadded), every `n` of the range maps to a distinct `v` and back; the padding is exactly the `v` with no `n`; each quantum's `n` all have its fixed digits; the per-quantum counts add up to the range.
- `b64_is_a_bit_permutation`: base 64's `v` equals the bit formula in the docs on 20,000 random `n` and both ends of the range.
- `b64_quantum_fixes_digits_5_to_7`: a field of one quantum holds exactly the `n` with one value of digits 5–7, every `n` lands in the field of its digits 5–7, misaligned and empty fields are refused, and the counts are `2^57` per quantum and the whole range in all.
- `b64_field_is_4096_whole_slices`: for five fields, each of the 4,096 values of digits 4–8 with those digits 5–7 gives `n` in that field, with random other digits.
- `b65_padded`: base 65 with the same digit positions, as a large base that pads: the padding is tiny, the counts add up to the range over all 274,625 quanta, and each quantum's `n` have its digits.
- `only_base_64_has_a_coordinate`: every other base is refused, and so are digit positions that are out of order.

`just lint` passes, and so does the whole workspace suite as CI runs it (`cargo test --locked --release --no-fail-fast`) and `nice_common --features gpu --lib`.

### What comes next

The CPU reference of the search for one field, tested against brute force on whole small bases (next pull request), then the GPU path at base 64 in a few steps. The GPU search measured about ×4.8 production's overlap join at base 64 on an RX 9070 XT, with the same results; each step will carry its own tests and evidence.

**Nothing uses this yet.** It is library code that no client route, test outside the module, or server reaches. No changelog entry, since no user can see it.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
