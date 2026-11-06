#!/bin/bash
# Mutation runs for the L42 review: each mutation applied to a copy of the
# reviewed file (+ the review tests), the relevant tests run, then restored.
cd /home/claude/projects/nice/.worktrees/review-l42-fd
export CARGO_TARGET_DIR=$PWD/target
F=common/src/cpu_top_fd.rs
BASE=/tmp/cpu_top_fd.review.rs
declare -a NAMES SEDS
NAMES+=("M1 ripple past the carry word dropped");          SEDS+=('s/if co {/if co \&\& false {/')
NAMES+=("M2 carry into the carry word dropped");           SEDS+=('s/let (t, co) = add_word(x\[hi\], 0, c, bias);/let (t, co) = add_word(x[hi], 0, false, bias);/')
NAMES+=("M3 addend words trimmed by one");                 SEDS+=('s/let addend_words = \[words(&ds), words(&dc), words(&ddc)\];/let addend_words = [words(\&ds) - 1, words(\&dc) - 1, words(\&ddc) - 1];/')
NAMES+=("M4 add_word drops the carry from cin");           SEDS+=('s/let cout = c1 | c2;/let cout = c1;/')
NAMES+=("M5 seed DS without h^2");                         SEDS+=('s/st.ds = sum(&shl_digits(&two_p, o), &self.h2, bias);/st.ds = shl_digits(\&two_p, o);/')
NAMES+=("M6 seed DDC without 6h^3");                       SEDS+=('s/st.ddc = sum(&shl_digits(&six_p, 2 \* o), &self.dddc, bias);/st.ddc = shl_digits(\&six_p, 2 * o);/')
NAMES+=("M7 screen margin -2^-20");                        SEDS+=('s/const SCREEN_MARGIN: f64 = 1.0 \/ 1_048_576.0;/const SCREEN_MARGIN: f64 = -1.0 \/ 1_048_576.0;/')
NAMES+=("M8 screen false branch r instead of r+1");        SEDS+=('s/if r + 1.0 + df <= self.b2f - SCREEN_MARGIN {/if r + df <= self.b2f - SCREEN_MARGIN {/')
NAMES+=("M9 walk overshoot not re-seeded");                SEDS+=('s/if st.p == p {/if st.p >= p {/')
for i in "${!NAMES[@]}"; do
  cp "$BASE" "$F"
  sed -i "${SEDS[$i]}" "$F"
  if cmp -s "$BASE" "$F"; then echo "=== ${NAMES[$i]}: SED DID NOT APPLY"; continue; fi
  echo "=== ${NAMES[$i]}"
  nice -n 19 cargo test --release -p nice_common --lib -- \
    cpu_top_fd::tests::stepped_certificates_equal_the_divided_ones \
    cpu_join::tests::stepped_tops_equal_divided_tops_on_production_fields \
    cpu_join::tests::cpu_join_matches_the_reference_on_the_test_windows \
    cpu_join::tests::a_field_in_slices_finds_what_it_finds_whole \
    cpu_join::tests::cpu_join_agrees_with_the_stride_path_on_whole_windows \
    review_carry_boundary 2>&1 | grep -E "^test .*\.\.\. |test result|panicked at|error\[" | sed 's/^/  /'
done
cp "$BASE" "$F"
echo "=== restored"
