# N16 modes: `setmode NAME` clears every experiment switch and sets NAME's (sourced by wrun.sh and the chains).
# Every mode runs UNPROFILED (no per-phase syncs) with host-side launch accounting on (NICE_EXP_HOSTACC=1),
# except c_nohost (the accounting's own cost) and prof_c (the old per-phase profile, for comparison only).
# exact = same counts as c (checked by chain_x.sh's dense compare and by every run's counts);
# timing = counts change (removal modes), said in the analysis output.
setmode() {
  for k in NICE_EXP_JOIN_ABL NICE_EXP_JOIN_DBL NICE_EXP_JOIN_WG NICE_EXP_JOIN_TCAP NICE_EXP_JOIN_TMIN \
           NICE_EXP_JOIN_AG NICE_EXP_JOIN_EPT NICE_EXP_SLOTS NICE_EXP_VRAM NICE_EXP_WALK_SYNC NICE_EXP_BALLOT \
           NICE_EXP_GPU_PROFILE NICE_EXP_INFO NICE_EXP_HOSTACC NICE_EXP_JOIN_SCAP NICE_EXP_JOIN_FLUSH; do unset $k; done
  export NICE_EXP_HOSTACC=1
  case $1 in
    c|c[0-9]) ;;                                                   # production kernel (tree E's), exact
    info) export NICE_EXP_INFO=1;;                                 # c + device/plane info lines, exact
    c_nohost) unset NICE_EXP_HOSTACC;;                             # c without the accounting, exact
    prof_c) export NICE_EXP_GPU_PROFILE=1;;                        # c with L51's per-phase syncs (clock drops!)
    # --- doubling: one part executed twice, exact (primary instrument)
    d_load) export NICE_EXP_JOIN_DBL=1;;     # batch loads of the top records into shared memory
    d_copy) export NICE_EXP_JOIN_DBL=2;;     # transposed copy (t_tr)
    d_and) export NICE_EXP_JOIN_DBL=4;;      # AND (transposed ORs / per-top tests)
    d_walk) export NICE_EXP_JOIN_DBL=8;;     # shadow walk (rounds: vote + pop), no prefilter
    d_pf) export NICE_EXP_JOIN_DBL=16;;      # lean prefilter twice per walked pair
    d_check) export NICE_EXP_JOIN_DBL=32;;   # check kernel launched twice
    d_wave) export NICE_EXP_JOIN_DBL=64;;    # entry waves' loads and terms
    d_bar) export NICE_EXP_JOIN_DBL=128;;    # every work-item and batch barrier twice
    # --- removal (second instrument; timing only, counts change): L51's a b p z and N16's base cuts
    r_a) export NICE_EXP_JOIN_ABL=1;;  r_b) export NICE_EXP_JOIN_ABL=2;;  r_p) export NICE_EXP_JOIN_ABL=3;;
    r_z) export NICE_EXP_JOIN_ABL=4;;  r_s5) export NICE_EXP_JOIN_ABL=5;; r_s6) export NICE_EXP_JOIN_ABL=6;;
    r_s7) export NICE_EXP_JOIN_ABL=7;; r_s8) export NICE_EXP_JOIN_ABL=8;;
    # --- survivor path and tops
    wsync) export NICE_EXP_WALK_SYNC=1;;     # plane barrier after every walk round (CUDA's setting), exact
    bal0) export NICE_EXP_BALLOT=0;;         # top append: plane sum + exclusive scan, exact
    bal1) export NICE_EXP_BALLOT=1;;         # one-word ballot: exact only on planes of <= 32 lanes
    bal2) export NICE_EXP_BALLOT=2;;         # two-word ballot (planes up to 64 lanes), exact if the backend returns both words
    ept1) export NICE_EXP_JOIN_EPT=1;;  ept3) export NICE_EXP_JOIN_EPT=3;;
    # --- work-group geometry (exact)
    tc128) export NICE_EXP_JOIN_TCAP=128 NICE_EXP_JOIN_TMIN=96;;                       # N13's winner (wg 256)
    wg128) export NICE_EXP_JOIN_WG=128;;                                                # 256 tops per batch on 128 threads
    wg64) export NICE_EXP_JOIN_WG=64;;                                                  # 256 tops on one wave64
    wg128tc) export NICE_EXP_JOIN_WG=128 NICE_EXP_JOIN_TCAP=128 NICE_EXP_JOIN_TMIN=96;; # JOIN_WG == TOP_CAP at 128
    wg128e4) export NICE_EXP_JOIN_WG=128 NICE_EXP_JOIN_EPT=4;;                          # 512 entries a wave, as wg 256
    wg64tc) export NICE_EXP_JOIN_WG=64 NICE_EXP_JOIN_TCAP=64 NICE_EXP_JOIN_TMIN=48 NICE_EXP_JOIN_AG=2;;
    # --- shared-memory occupancy (Task C: on RDNA4 the join's cube is LDS-bound, 18.5 KiB -> 12 waves/SIMD), exact
    sc512) export NICE_EXP_JOIN_SCAP=512 NICE_EXP_JOIN_FLUSH=256;;                     # stage 4 KiB (-> 14.5 KiB)
    sc256) export NICE_EXP_JOIN_SCAP=256 NICE_EXP_JOIN_FLUSH=128;;                     # stage 2 KiB (-> 12.5 KiB)
    tcsc) export NICE_EXP_JOIN_TCAP=128 NICE_EXP_JOIN_TMIN=96 NICE_EXP_JOIN_SCAP=512 NICE_EXP_JOIN_FLUSH=256;;
    # --- launches (H1): partitions per launch and the denser plan
    s1) export NICE_EXP_SLOTS=1;; s2) export NICE_EXP_SLOTS=2;; s4) export NICE_EXP_SLOTS=4;;
    vram) export NICE_EXP_VRAM=1;;
    tcvram) export NICE_EXP_JOIN_TCAP=128 NICE_EXP_JOIN_TMIN=96 NICE_EXP_VRAM=1;;
    *) echo "unknown mode $1" >&2; return 1;;
  esac
}
