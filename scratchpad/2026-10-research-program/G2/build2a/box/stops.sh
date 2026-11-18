#!/bin/bash
# usage: stops.sh BIN TAG [field]  -- cumulative stops on one field
BIN=$1; TAG=$2; F=${3:-77777}
for st in 1 2 3 5 6; do
  echo "== $TAG stop $st $(date -u +%T)"
  MIDOUT_STOP=$st $BIN --cuda --fields $F 2>&1 | grep -E "FIELD|TOTAL|rror"
done
