#!/bin/bash
# omnibus middle test on windows of large bases (u128 n, digit-vector powers)
cd "$(dirname "$0")/.."
for b in 45 50 55 62; do
  read rs re < <(python3 -c "import sys; sys.path.insert(0,'code'); from ranges import rng; print(*rng($b))")
  W=$(python3 -c "rs,re=$rs,$re; w=re-rs; print(' '.join(f'{rs+int(w*f)}:150000000' for f in [0.05,0.3,0.55,0.8]))")
  s=$(date +%s)
  A3_RANGE="$rs:$re" nice -n 19 ./code/enum/target/release/a3enum $b data/big 7 $W
  echo "b$b $(( $(date +%s)-s ))s" >> data/big/log.txt
done
echo ALLDONE >> data/big/log.txt
