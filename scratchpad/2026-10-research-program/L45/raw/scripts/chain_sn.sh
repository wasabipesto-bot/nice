#!/bin/bash
# chain_sn.sh: (ii) register variants of #246's join kernel, timed separately (after chain_main.sh).
# 1. classify every main-chain process's join kernel as the runtime compiled it (ptxjit.py: driver JIT of the
#    process's own PTX; SASS from the JIT's cubin);
# 2. one untimed 1e14 process (b62, b60) with CUBECL_DEBUG_LOG: CubeCL's CUDA source of each join kernel, and a PTX
#    cache holding every kernel of both fields (a field's kernels have the 1e14 keys);
# 3. nvcc -cubin (L41's offline method) of that source with __launch_bounds__(256, 6) and (256, 5): ptxas targets
#    6 or 5 cubes per SM, plain (L41's exact method) and -maxrregcount=40;
# 4. pins (every kernel's image fixed; they differ in the join kernel only):
#      N = the runtime's own compile (NVRTC PTX -> driver JIT), M = nvcc at 5 cubes (no spill),
#      S = the first nvcc compile with spills of plain / -maxrregcount=40 / 6 cubes;
# 5. a 1e14 check of each pin (counts), then 3 rounds S/N/M rotating, b62 1e17 then b60 1e16, profile on.
R=/root/l45/run.sh; L=/root/l45/logs; P=/root/l45/ptx; D=/root/l45/dbg; S=/root/l45/sass
export PATH=/usr/local/cuda/bin:$PATH
cd /root/l45
echo SN_START $(date -u +%T)
python3 /root/l45/ptxjit.py --only join --sass $S $P/san_c_e14 $P/m_* > $L/main_jit.txt 2>&1
echo "classified $(grep -c join_kernel $L/main_jit.txt) join compiles; spill variants: $(grep -c variant=SPILL $L/main_jit.txt)"
rm -rf $D; mkdir -p $D
CUBECL_DEBUG_LOG=$D/cubecl.log NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=0 $R dbg_e14 E2 62,60 1 1e14
python3 - $D/cubecl.log $D <<'PY'
import sys, re
log, out = sys.argv[1:3]
txt = open(log, errors='replace').read(); k = 0
for blk in txt.split('[START_KERNEL_COMPILATION]')[1:]:
    blk = blk.split('[END_KERNEL_COMPILATION]')[0]
    m = re.search(r'name: nice_common::cubecl_join::kernels::(\w+)::', blk)
    if not m or m.group(1) != 'join_kernel' or '```cpp' not in blk: continue
    base = re.search(r'base: (\d+)', blk).group(1)
    open(f'{out}/join_b{base}.cu', 'w').write(blk.split('```cpp', 1)[1].split('```', 1)[0]); k += 1
    print('join source', base)
PY
gzip -f $D/cubecl.log
python3 /root/l45/ptxjit.py --only join --sass $S $P/dbg_e14 | tee $D/dbg_jit.txt
# keys of the join entries, in compile order (b62 then b60)
K62=$(grep -o 'key=[0-9]*' $D/dbg_jit.txt | sed -n 1p | cut -d= -f2); K60=$(grep -o 'key=[0-9]*' $D/dbg_jit.txt | sed -n 2p | cut -d= -f2)
for b in 62 60; do
  # variants: plain (L41's exact offline compile), lb5 / lb6 (__launch_bounds__(256, 5 / 6)), r40 (-maxrregcount=40)
  cp $D/join_b$b.cu $D/join_b${b}_plain.cu; cp $D/join_b$b.cu $D/join_b${b}_r40.cu
  for nb in 5 6; do sed "s/__launch_bounds__(256)join_kernel/__launch_bounds__(256, $nb)join_kernel/" $D/join_b$b.cu > $D/join_b${b}_lb$nb.cu; done
  for v in plain lb5 lb6 r40; do
    X=""; [ $v = r40 ] && X="-maxrregcount=40"
    o=$(nvcc -cubin -arch=sm_86 -O3 $X -Xptxas -v -o $D/join_b${b}_$v.cubin $D/join_b${b}_$v.cu 2>&1)
    echo "b$b $v: $(echo "$o" | grep -o 'Used [0-9]* registers' ) $(echo "$o" | grep -o '[0-9]* bytes spill stores')" | tee -a $D/nvcc.txt
    cuobjdump -sass $D/join_b${b}_$v.cubin > $S/nvcc_join_b${b}_$v.sass
  done
  # S = the first spilling one of plain, r40, lb6; M = lb5 (L41's no-spill variant)
  for v in plain r40 lb6; do
    if grep -q "^b$b $v: .* [1-9][0-9]* bytes spill stores" $D/nvcc.txt; then cp $D/join_b${b}_$v.cubin $D/S_b$b.cubin; echo "S b$b = $v" | tee -a $D/nvcc.txt; break; fi
  done
  [ -e $D/S_b$b.cubin ] || { cp $D/join_b${b}_r40.cubin $D/S_b$b.cubin; echo "S b$b = r40 (no spilling compile found)" | tee -a $D/nvcc.txt; }
  cp $D/join_b${b}_lb5.cubin $D/M_b$b.cubin
done
python3 pin.py /root/l45/pin/N $P/dbg_e14 | tee -a $L/pins.txt
python3 pin.py --replace $K62=$D/M_b62.cubin --replace $K60=$D/M_b60.cubin /root/l45/pin/M $P/dbg_e14 | tee -a $L/pins.txt
python3 pin.py --replace $K62=$D/S_b62.cubin --replace $K60=$D/S_b60.cubin /root/l45/pin/S $P/dbg_e14 | tee -a $L/pins.txt
python3 /root/l45/ptxjit.py --only join /root/l45/pin/N /root/l45/pin/M /root/l45/pin/S | tee -a $L/pins.txt
cp $D/nvcc.txt $L/nvcc.txt
for v in N M S; do
  PTXFROM=/root/l45/pin/$v NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=0 $R snchk_${v}_e14 E2 62,60 1 1e14
  echo "check $v: $(grep -o 'base=[0-9]* fields.*found=[0-9]*' $L/snchk_${v}_e14.log | sed 's/rate.*survivors/survivors/' | tr '\n' ' ')"
done
for r in 1 2 3; do
  case $r in 1) ORDER="S N M";; 2) ORDER="N M S";; 3) ORDER="M S N";; esac
  for spec in "62 1 1e17 e17_b62" "60 2 1e16 e16_b60"; do
    set -- $spec
    for v in $ORDER; do
      [ -e $L/stop ] && { echo STOPPED $(date -u +%T); exit 0; }
      PTXFROM=/root/l45/pin/$v NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=0 $R sn_${v}_$4_r$r E2 $1 $2 $3
      echo "$(date -u +%T) sn_${v}_$4_r$r $(grep -o 'device=[0-9.]*s' $L/sn_${v}_$4_r$r.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/sn_${v}_$4_r$r.log | tail -1)"
    done
  done
done
python3 /root/l45/ptxjit.py --only join $P/sn_* > $L/sn_jit.txt 2>&1
echo SN_DONE $(date -u +%T) | tee $L/sn.done
