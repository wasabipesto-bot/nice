# cfg.sh (sourced): setside SIDE -> BIN and NICE_EXP_* for that side. B = d813aea (binary B), F<n> = binary X1 with
# NICE_EXP_AND_FORM=<n>, G<n> = binary X2 (a later build) with NICE_EXP_AND_FORM=<n>.
setside() {
  unset NICE_EXP_AND_FORM
  case $1 in
    B) BIN=B;;
    F*) BIN=X1; export NICE_EXP_AND_FORM=${1#F};;
    G*) BIN=X2; export NICE_EXP_AND_FORM=${1#G};;
    *) echo "unknown side $1"; return 1;;
  esac
}
