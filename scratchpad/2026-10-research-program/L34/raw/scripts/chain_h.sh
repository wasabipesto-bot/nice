#!/bin/bash
# Hybrid (H = transposed AND only for batches of >= NICE_EXP_JOIN_TRANSPOSE_MIN tops): build after F_spv's build,
# cargo fmt on its tree (the source is then copied back), registers, then screens interleaved:
# b62 1e14 (1 field) and b62 1e16 (2 fields) for F off, F G=4, H G=4 MIN=64, H MIN=96, H MIN=128; 2 rounds at 1e16.
L=/root/l34/logs; S=/root/l34; R=$S/run.sh
mkdir -p /root/l34/src/H && tar xzf /root/l34/H.tgz -C /root/l34/src/H
while pgrep -f "^/bin/bash /root/l34/build.sh F F_spv" > /dev/null; do sleep 5; done
( cd /root/l34/src/H && source ~/.cargo/env && cp common/src/cubecl_join.rs /root/l34/H_cubecl_join.prefmt.rs && cargo fmt --all && cargo fmt --all --check; echo "fmt rc=$?"; diff /root/l34/H_cubecl_join.prefmt.rs common/src/cubecl_join.rs | wc -l ) > $L/h_fmt.log 2>&1
$S/build.sh H H gpu > $L/build_H.out 2>&1 || exit 1
G4="NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=4"
for m in 0 64 96 128; do $S/regs.sh H h$m $G4 NICE_EXP_JOIN_TRANSPOSE_MIN=$m; done
$S/regs.sh H hoff
for r in 1 2; do
  $R h_Foff_e16_r$r F 62 2 1e16
  env $G4 $R h_Fg4_e16_r$r F 62 2 1e16
  for m in 64 96 128; do env $G4 NICE_EXP_JOIN_TRANSPOSE_MIN=$m $R h_H${m}_e16_r$r H 62 2 1e16; done
done
STARTS=60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
$R h_Foff_e14 F 60,62,64 3 1e14
env $G4 $R h_Fg4_e14 F 60,62,64 3 1e14
for m in 64 128; do env $G4 NICE_EXP_JOIN_TRANSPOSE_MIN=$m $R h_H${m}_e14 H 60,62,64 3 1e14; done
echo H_DONE $(date -u +%T) > $L/h.done
