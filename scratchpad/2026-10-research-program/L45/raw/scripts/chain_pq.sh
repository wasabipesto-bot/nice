#!/bin/bash
# chain_pq.sh: why the runtime's own compile (N) is slower than nvcc's (M): two more images of the same join kernels,
#   P = the runtime's NVRTC PTX compiled by the offline ptxas 12.8 (cubin): NVRTC front end, offline back end;
#   Q = nvcc 12.8's PTX of the same CUDA source (no launch bound), JIT-compiled by the driver: nvcc front end, driver back end.
# Then 2 rounds of N, M, P, Q (order rotating), b62 1e17 then b60 1e16, profile on. Waits for chain_ab.sh.
R=/root/l45/run.sh; L=/root/l45/logs; D=/root/l45/dbg; X=/root/l45/pq; S=/root/l45/sass
export PATH=/usr/local/cuda/bin:$PATH
until [ -e $L/ab.done ] || [ -e $L/stop ]; do sleep 10; done
[ -e $L/stop ] && exit 0
echo PQ_START $(date -u +%T)
rm -rf $X; mkdir -p $X; cd /root/l45
python3 extract_ptx.py /root/l45/pin/N $X
K62=$(sed -n 1p $X/keys.txt); K60=$(sed -n 2p $X/keys.txt)
for b in 62 60; do
  K=$K62; [ $b = 60 ] && K=$K60
  echo "b$b P (NVRTC PTX, offline ptxas): $(ptxas -arch=sm_86 -O3 -v -o $X/P_b$b.cubin $X/join_$K.ptx 2>&1 | grep -o 'Used [0-9]* registers\|[0-9]* bytes spill stores' | tr '\n' ' ')" | tee -a $X/pq.txt
  nvcc -ptx -arch=sm_86 -O3 -o $X/Q_b$b.ptx $D/join_b$b.cu 2> /dev/null
  echo "b$b Q (nvcc PTX) under offline ptxas: $(ptxas -arch=sm_86 -O3 -v -o /tmp/q.cubin $X/Q_b$b.ptx 2>&1 | grep -o 'Used [0-9]* registers\|[0-9]* bytes spill stores' | tr '\n' ' ')" | tee -a $X/pq.txt
  cuobjdump -sass $X/P_b$b.cubin > $S/pq_P_b$b.sass
done
python3 pin.py --replace $K62=$X/P_b62.cubin --replace $K60=$X/P_b60.cubin /root/l45/pin/P /root/l45/ptx/dbg_e14 | tee -a $X/pq.txt
python3 pin.py --replace $K62=$X/Q_b62.ptx --replace $K60=$X/Q_b60.ptx /root/l45/pin/Q /root/l45/ptx/dbg_e14 | tee -a $X/pq.txt
python3 /root/l45/ptxjit.py --only join --sass $S /root/l45/pin/P /root/l45/pin/Q | tee -a $X/pq.txt
cp $X/pq.txt $L/pq.txt
for v in P Q; do
  PTXFROM=/root/l45/pin/$v NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=0 $R pqchk_${v}_e14 E2 62,60 1 1e14
  echo "check $v: $(grep -o 'base=[0-9]* fields.*found=[0-9]*' $L/pqchk_${v}_e14.log | sed 's/rate.*survivors/survivors/' | tr '\n' ' ')"
done
for r in 1 2; do
  case $r in 1) ORDER="P Q N M";; 2) ORDER="M N Q P";; esac
  for spec in "62 1 1e17 e17_b62" "60 2 1e16 e16_b60"; do
    set -- $spec
    for v in $ORDER; do
      [ -e $L/stop ] && { echo STOPPED $(date -u +%T); exit 0; }
      PTXFROM=/root/l45/pin/$v NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=0 $R pq_${v}_$4_r$r E2 $1 $2 $3
      echo "$(date -u +%T) pq_${v}_$4_r$r $(grep -o "device=[0-9.]*s" $L/pq_${v}_$4_r$r.log | tail -1) $(grep -o "survivors=[0-9]* checked=[0-9]*" $L/pq_${v}_$4_r$r.log | tail -1)"
    done
  done
done
python3 /root/l45/ptxjit.py --only join /root/l45/ptx/pq_* > $L/pq_jit.txt 2>&1
echo PQ_DONE $(date -u +%T) | tee $L/pq.done
