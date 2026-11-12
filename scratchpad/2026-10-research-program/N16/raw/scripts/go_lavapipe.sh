#!/bin/sh
# go_lavapipe.sh (the box): the window's chains end to end on lavapipe (wgpu, CubeCL's SPIR-V compiler, Vulkan on the
# CPU), with only W, DEV and the field sizes changed, then the dense exactness compare of every exact mode against
# the CPU join on a small b60 field. Timings mean nothing here; it checks that every script, mode and parser works on
# the wgpu path. NB=N16b on the box (the branch head), PFX0=lp. (names lp.<chain>-<mode>_<tag>_r<round>).
# Small non-empty fields (1e13; found on CUDA: 241 / 256 / 225 batches, 5.1e7 / 2.6e6 / 1.8e8 join survivors).
export DEV=wgpu PFX0=lp. SZ62=${SZ62:-1e13} SZ64=${SZ64:-1e13} SZ60=${SZ60:-1e13} NB=${NB:-N16b}
export F62=${F62:-7520567872397899821056} F64=${F64:-58557334082957161709568} F60=${F60:-1447430722114824200908}
S=${SCRIPTS:-/root/n16/scripts}
{
echo "LP_START $(date -u +%T)"
# lavapipe runs ~2-3 minutes per 1e13 field, so each chain runs a shortened list (every script and parser path, the
# removal, ballot and geometry kinds included); the exactness of every exact mode is the dense compare at the end.
ROUND=1 L62="info d_pf c2" L64= sh $S/chain_must.sh
ROUND=1 S62="c bal1" S60="c r_z r_s5 prof_c" sh $S/chain_surv.sh
ROUND=1 MODES="c tcsc wg64 s2 c_nohost" sh $S/chain_geo.sh
DROUNDS=1 sh $S/chain_D.sh
XPFX=xlp60 NX=8 XFIELD=60:1447429612114824200908:1e15 sh $S/chain_x.sh
XPFX=xlp62 NX=2 XFIELD=62:7520566762397899821056:1e17 sh $S/chain_x.sh
echo "LP_DONE $(date -u +%T)"
} > ${OUT:-/root/n16/out}/go_lavapipe.out 2>&1
