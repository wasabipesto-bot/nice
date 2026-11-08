#!/usr/bin/env python3
"""Apply one named mutation to common/src/cpu_join.rs (exact-string replacements)."""
import sys, pathlib
path = pathlib.Path(sys.argv[1]); name = sys.argv[2]
s = path.read_text()
POS_END = "        byte += 1;\n    }\n    t\n};\n\n/// For each byte of pass bits, how many bits it has set"
CNT_END = "        t[byte] = t[byte / 2] + t[byte % 2];\n        byte += 1;\n    }\n    t\n};"
M = {
  # BIT_POS: wrong value in a rare byte's last listed position (0xFE: 1..7 -> ...,6,6)
  "M1_pos_value_FE": [(POS_END, POS_END.replace("    t\n};", "    t[0xFE][6] = 6;\n    t\n};", 1))],
  # BIT_POS: two positions swapped (order) in a mid byte (0x5A: 1,3,4,6 -> 1,4,3,6)
  "M2_pos_order_5A": [(POS_END, POS_END.replace("    t\n};", "    t[0x5A][1] = 4;\n    t[0x5A][2] = 3;\n    t\n};", 1))],
  # BIT_CNT: one count low (0xDF has 7 bits -> 6)
  "M3_cnt_DF": [(CNT_END, CNT_END.replace("    t\n};", "    t[0xDF] = 6;\n    t\n};", 1))],
  # AVX2: the two halves of the byte swapped
  "M4_avx2_swap": [("bits |= lanes << (4 * q);", "bits |= lanes << (4 * (1 - q));")],
  # each_pass: the piece offset off by one from the second piece on
  "M5_piece_offset": [("for (at, piece) in (0..).step_by(PIECE).zip(masks.chunks(PIECE)) {",
                        "for (at, piece) in (0..).step_by(PIECE + 1).zip(masks.chunks(PIECE)) {")],
  # tail: the piece's last bottom (when the tail is non-empty) is never listed
  "M7_tail_last": [("        idx[cnt] = j;\n        cnt += usize::from(m & t == 0);",
                    "        idx[cnt] = j;\n        cnt += usize::from(m & t == 0 && usize::from(j + 1 - at) < masks.len());")],
  # pass 2 visits the list in reverse
  "M10_reverse": [("            for &i in &idx[..n] {", "            for &i in idx[..n].iter().rev() {")],
  # a smaller piece (not a mutation: the end-to-end tests should still pass)
  "P9": [("const PIECE: usize = 1024;", "const PIECE: usize = 9;")],
}
for old, new in M[name]:
    assert s.count(old) == 1, (name, old, s.count(old))
    s = s.replace(old, new)
path.write_text(s)
print("applied", name)
