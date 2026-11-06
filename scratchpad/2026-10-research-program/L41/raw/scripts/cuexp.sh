#!/bin/bash
# cuexp.sh NAME: compile /root/l41/cuexp/NAME.cu offline, report registers, walk loop counts and the loop-head artifact.
cd /root/l41/cuexp; export PATH=/usr/local/cuda/bin:$PATH
r=$(nvcc -cubin -arch=sm_86 -O3 -Xptxas -v -o $1.cubin $1.cu 2>&1 | grep -o "[0-9]* bytes spill stores\|Used [0-9]* registers" | tr '\n' ' ')
cuobjdump -sass $1.cubin > $1.sass
echo "$1: $r"
python3 /root/l41/walkcount.py $1.sass | sed 's/; ops:.*//; s/^.*sass //'
a=$(python3 /root/l41/walkcount.py $1.sass | grep loop1 | grep -o "loop1 0x[0-9a-f]*" | cut -c9-)
sed -n "/\/\*$a\*\//,+4p" $1.sass | grep -c "\-0x1\|@!PT BRA" | sed 's/^/head artifacts: /'
