# cfg.sh: config name -> NICE_EXP_* environment (sourced). setcfg NAME exports the variables of NAME and unsets the rest.
# Main-chain modes (profiled unless noted): c full, a AND only, b walk without prefilter/stage, p walk + prefilter (no
# stage), z no AND, d per-top AND everywhere (TMIN 2^30), u full unprofiled, B = d813aea's own binary unprofiled.
# Screen variants (unprofiled): base, ept1, ept3, tm128, tm256, tm512, ag2, ag8, tc128 (TMIN 96), tc512, fd128, fd512,
# stg1 (stage once per work item), fl256, fl768 (SURV_FLUSH).
setcfg() {
  unset NICE_EXP_GPU_PROFILE NICE_EXP_JOIN_ABL NICE_EXP_JOIN_TMIN NICE_EXP_JOIN_SPILLCNT NICE_EXP_JOIN_EPT NICE_EXP_JOIN_AG \
        NICE_EXP_JOIN_TCAP NICE_EXP_JOIN_FLUSH NICE_EXP_JOIN_STAGE NICE_EXP_FD_WG
  BIN=E
  case $1 in
    c) export NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=0;;
    a) export NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=1;;
    b) export NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=2;;
    p) export NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=3;;
    z) export NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=4;;
    d) export NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=0 NICE_EXP_JOIN_TMIN=1073741824;;
    u|base*) ;;
    B) BIN=B;;
    ept1) export NICE_EXP_JOIN_EPT=1;;
    ept3) export NICE_EXP_JOIN_EPT=3;;
    tm128) export NICE_EXP_JOIN_TMIN=128;;
    tm256) export NICE_EXP_JOIN_TMIN=256;;
    tm512) export NICE_EXP_JOIN_TMIN=512;;
    ag2) export NICE_EXP_JOIN_AG=2;;
    ag8) export NICE_EXP_JOIN_AG=8;;
    tc128) export NICE_EXP_JOIN_TCAP=128 NICE_EXP_JOIN_TMIN=96;;
    tc512) export NICE_EXP_JOIN_TCAP=512;;
    fd128) export NICE_EXP_FD_WG=128;;
    fd512) export NICE_EXP_FD_WG=512;;
    stg1) export NICE_EXP_JOIN_STAGE=1;;
    fl256) export NICE_EXP_JOIN_FLUSH=256;;
    fl768) export NICE_EXP_JOIN_FLUSH=768;;
    spc) export NICE_EXP_JOIN_SPILLCNT=1;;
    spcstg1) export NICE_EXP_JOIN_SPILLCNT=1 NICE_EXP_JOIN_STAGE=1;;
    spcfl768) export NICE_EXP_JOIN_SPILLCNT=1 NICE_EXP_JOIN_FLUSH=768;;
    spctc512) export NICE_EXP_JOIN_SPILLCNT=1 NICE_EXP_JOIN_TCAP=512;;
    *) echo "unknown cfg $1"; return 1;;
  esac
}
