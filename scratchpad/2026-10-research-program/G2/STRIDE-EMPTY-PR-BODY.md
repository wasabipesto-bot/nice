Stride walk: find no numbers at a base with no valid residue

**What breaks.** At every base that leaves 3 when divided by 4 (7, 15, 19, 23, 43, 47, …) no number can be nice: the residue filter is empty, so the stride table has no residues. The CPU nice-only search builds that table anyway, and its walk's first lookup panics ("index out of bounds: the len is 0 but the index is 0", `stride_filter.rs:165`) whenever the MSD filter keeps any part of the field.

**Who hits it.** A CPU client given a nice-only claim of such a base. With today's client against a local stub serving real base-43 field 49999 (60991418181959–60992418181959), `nice_client niceonly` crashes with exit 101 and submits nothing. Fields 30000 and 40000 survive only because the MSD filter rejects them whole. `--gpu` (CUDA, wgpu) is fine. `niceonly --validate` is refused before any search, and detailed mode never uses the table. Whether the server holds nice-only work at these bases is a database question.

**How to see it.** Run `cargo test -p nice_common --lib residue_empty_bases_search_to_nothing` without the change.

**What the change does.** The masked walk returns no numbers for a table without residues before it looks anything up. A table with residues takes the same path as before. The GPU paths already answer these bases first (`residue_empty_result`) and are untouched, so a GPU device should see no difference.

**Not included.** `get_base_range_u128(3)` panics instead of returning `None`; `insert_new_fields` accepts such bases.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
