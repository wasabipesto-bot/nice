Stride walk: find no numbers at a base with no valid residue

**What breaks.** The stride table is empty at every base that leaves 3 when divided by 4 (7, 15, 19, 23, 43, …), where no number can be nice, and at bases 4 and 5, where the LSD filter at k = 3 empties it. The CPU nice-only walk's first lookup then panics ("index out of bounds: the len is 0 but the index is 0", `stride_filter.rs:165` on main) whenever the MSD filter keeps any part of the field.

**Who hits it.** A CPU client given a nice-only field of such a base that takes the stride walk. At bases 40–64, fields of 10^13 numbers or more take the overlap join instead. `--gpu` answers every base that leaves 3 when divided by 4 before building a table. Bases 4 and 5 fall back to the CPU walk, so they crashed under `--gpu` too. Whether that happens depends on which bases the server holds.

**How to see it.** Serve today's client the real base-43 field 60991418181959–60992418181959 as a nice-only claim from a local stub: `nice_client niceonly` panics and submits nothing. The new tests fail likewise without the change.

**What the change does.** The masked walk returns no numbers for a table without residues. Tables with residues take the same path as before; GPU code is unchanged.

**Not included.** `get_base_range_u128(3)` panics instead of returning `None`. `insert_new_fields` accepts such bases.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
