#!/bin/sh
# chain_smoke.sh: every mode once on a small field (default b62 at 1e14; SZ62 overrides), to check that each builds
# its kernel, runs, and (for the exact modes) gives the base counts. PFX names the set (e.g. cu_ or lp_).
. "${SCRIPTS:-$(dirname "$0")}/lib.sh"
: "${SZ62:=1e14}"
for m in ${MODES:-c info c_nohost prof_c d_load d_copy d_and d_walk d_pf d_check d_wave d_bar r_a r_b r_p r_z r_s5 r_s6 r_s7 r_s8 wsync bal0 bal1 bal2 ept1 ept3 tc128 wg128 wg64 wg128tc wg128e4 wg64tc s1 s2 s4 vram tcvram}; do
  one $m ${TAG:-b62} 1
done
echo SMOKE_DONE $(date -u +%T)
