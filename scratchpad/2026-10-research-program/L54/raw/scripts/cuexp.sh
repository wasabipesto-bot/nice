#!/bin/bash
# cuexp.sh FILE.cu...: NVRTC (as CubeCL) -> driver JIT (registers, spills) -> SASS -> the AND loops (andloops.py).
for f in "$@"; do
  b=${f%.cu}
  python3 /root/l54/nvrtc.py $f || continue
  JC=$(mktemp -d)
  CUDA_CACHE_PATH=$JC python3 /root/l54/jitlog.py $b.ptx | sed 's/^.*rc=/rc=/'
  c=$(find $JC -type f ! -name index | head -1)
  python3 -c "import sys; d=open(sys.argv[1],'rb').read(); i=d.find(b'\x7fELF'); open(sys.argv[2],'wb').write(d[i:])" "$c" $b.cubin
  /usr/local/cuda/bin/cuobjdump -sass $b.cubin > $b.sass; echo "sass=$(grep -cE '^\s+/\*[0-9a-f]{4,}\*/' $b.sass)"
  python3 /root/l54/andloops.py $b.sass ${V:-}
  rm -rf $JC
done
