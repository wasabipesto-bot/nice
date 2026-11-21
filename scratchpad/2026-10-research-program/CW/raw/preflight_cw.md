
### cw

| kernel | wave | VGPRs | SGPRs | LDS B | waves/SIMD | scratch | spills | instr | valu | q | v64 | salu | lds | vmem | vcyc | spirv-val |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| w128s1 | 64 | 120 | 108 | 20480 | 12 | 0 | 0/0 | 473 | 197 | 0 | 0 | 100 | 40 | 12 | 197 | ? |
| w128s2 | 64 | 120 | 108 | 20480 | 12 | 0 | 0/0 | 653 | 298 | 0 | 0 | 110 | 76 | 14 | 298 | ? |
| w128v1 | 64 | 120 | 108 | 20480 | 12 | 0 | 0/0 | 473 | 197 | 0 | 0 | 100 | 40 | 12 | 197 | ? |
| w128v2 | 64 | 120 | 108 | 20480 | 12 | 0 | 0/0 | 653 | 298 | 0 | 0 | 110 | 76 | 14 | 298 | ? |
| w256s1 | 64 | 120 | 108 | 20480 | 12 | 0 | 0/0 | 623 | 282 | 0 | 0 | 100 | 74 | 14 | 282 | ? |
| w256v1 | 64 | 120 | 108 | 20480 | 12 | 0 | 0/0 | 623 | 282 | 0 | 0 | 100 | 74 | 14 | 282 | ? |
| w256v2 | 64 | 120 | 108 | 20480 | 12 | 0 | 0/0 | 914 | 438 | 0 | 0 | 110 | 144 | 18 | 438 | ? |
| w256x1 | 64 | 120 | 108 | 20480 | 12 | 0 | 0/0 | 679 | 328 | 0 | 0 | 100 | 74 | 14 | 328 | ? |
| w256x2 | 64 | 120 | 108 | 20480 | 12 | 0 | 0/0 | 1024 | 528 | 0 | 0 | 110 | 144 | 18 | 528 | ? |
| w64 | 64 | 120 | 108 | 20480 | 12 | 0 | 0/0 | 531 | 234 | 0 | 0 | 108 | 42 | 12 | 234 | ? |

Loops (per wave-iteration, the loop body including nested loops once):

- w128s1 loop 0 (BB1..BB9, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=3 vcyc=4
- w128s1 loop 1 (BB11..BB69): alu=271 valu=165 q=0 v64=0 salu=67 lds=39 vmem=7 smem=9 wait=82 vcyc=165
- w128s1 loop 2 (BB15..BB23, innermost): alu=11 valu=4 q=0 v64=0 salu=6 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w128s1 loop 3 (BB25..BB33, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w128s1 loop 4 (BB35..BB68, innermost): alu=200 valu=122 q=0 v64=0 salu=41 lds=37 vmem=5 smem=4 wait=56 vcyc=122
- w128s2 loop 0 (BB1..BB9, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=3 vcyc=4
- w128s2 loop 1 (BB11..BB78): alu=418 valu=266 q=0 v64=0 salu=77 lds=75 vmem=9 smem=10 wait=112 vcyc=266
- w128s2 loop 2 (BB15..BB23, innermost): alu=11 valu=4 q=0 v64=0 salu=6 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w128s2 loop 3 (BB25..BB33, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w128s2 loop 4 (BB35..BB77, innermost): alu=347 valu=223 q=0 v64=0 salu=51 lds=73 vmem=7 smem=5 wait=86 vcyc=223
- w128v1 loop 0 (BB1..BB9, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=3 vcyc=4
- w128v1 loop 1 (BB11..BB69): alu=271 valu=165 q=0 v64=0 salu=67 lds=39 vmem=7 smem=9 wait=82 vcyc=165
- w128v1 loop 2 (BB15..BB23, innermost): alu=11 valu=4 q=0 v64=0 salu=6 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w128v1 loop 3 (BB25..BB33, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w128v1 loop 4 (BB35..BB68, innermost): alu=200 valu=122 q=0 v64=0 salu=41 lds=37 vmem=5 smem=4 wait=56 vcyc=122
- w128v2 loop 0 (BB1..BB9, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=3 vcyc=4
- w128v2 loop 1 (BB11..BB78): alu=418 valu=266 q=0 v64=0 salu=77 lds=75 vmem=9 smem=10 wait=112 vcyc=266
- w128v2 loop 2 (BB15..BB23, innermost): alu=11 valu=4 q=0 v64=0 salu=6 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w128v2 loop 3 (BB25..BB33, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w128v2 loop 4 (BB35..BB77, innermost): alu=347 valu=223 q=0 v64=0 salu=51 lds=73 vmem=7 smem=5 wait=86 vcyc=223
- w256s1 loop 0 (BB1..BB9, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=3 vcyc=4
- w256s1 loop 1 (BB11..BB69): alu=390 valu=250 q=0 v64=0 salu=67 lds=73 vmem=9 smem=9 wait=111 vcyc=250
- w256s1 loop 2 (BB15..BB23, innermost): alu=11 valu=4 q=0 v64=0 salu=6 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w256s1 loop 3 (BB25..BB33, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w256s1 loop 4 (BB35..BB68, innermost): alu=291 valu=179 q=0 v64=0 salu=41 lds=71 vmem=7 smem=4 wait=77 vcyc=179
- w256v1 loop 0 (BB1..BB9, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=3 vcyc=4
- w256v1 loop 1 (BB11..BB69): alu=390 valu=250 q=0 v64=0 salu=67 lds=73 vmem=9 smem=9 wait=111 vcyc=250
- w256v1 loop 2 (BB15..BB23, innermost): alu=11 valu=4 q=0 v64=0 salu=6 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w256v1 loop 3 (BB25..BB33, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w256v1 loop 4 (BB35..BB68, innermost): alu=291 valu=179 q=0 v64=0 salu=41 lds=71 vmem=7 smem=4 wait=77 vcyc=179
- w256v2 loop 0 (BB1..BB9, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=3 vcyc=4
- w256v2 loop 1 (BB11..BB78): alu=626 valu=406 q=0 v64=0 salu=77 lds=143 vmem=13 smem=10 wait=161 vcyc=406
- w256v2 loop 2 (BB15..BB23, innermost): alu=11 valu=4 q=0 v64=0 salu=6 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w256v2 loop 3 (BB25..BB33, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w256v2 loop 4 (BB35..BB77, innermost): alu=527 valu=335 q=0 v64=0 salu=51 lds=141 vmem=11 smem=5 wait=127 vcyc=335
- w256x1 loop 0 (BB1..BB9, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=3 vcyc=4
- w256x1 loop 1 (BB11..BB69): alu=435 valu=295 q=0 v64=0 salu=67 lds=73 vmem=9 smem=9 wait=121 vcyc=295
- w256x1 loop 2 (BB15..BB23, innermost): alu=11 valu=4 q=0 v64=0 salu=6 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w256x1 loop 3 (BB25..BB33, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w256x1 loop 4 (BB35..BB68, innermost): alu=336 valu=224 q=0 v64=0 salu=41 lds=71 vmem=7 smem=4 wait=87 vcyc=224
- w256x2 loop 0 (BB1..BB9, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=3 vcyc=4
- w256x2 loop 1 (BB11..BB78): alu=715 valu=495 q=0 v64=0 salu=77 lds=143 vmem=13 smem=10 wait=181 vcyc=495
- w256x2 loop 2 (BB15..BB23, innermost): alu=11 valu=4 q=0 v64=0 salu=6 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w256x2 loop 3 (BB25..BB33, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w256x2 loop 4 (BB35..BB77, innermost): alu=616 valu=424 q=0 v64=0 salu=51 lds=141 vmem=11 smem=5 wait=147 vcyc=424
- w64 loop 0 (BB1..BB9, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=3 vcyc=4
- w64 loop 1 (BB11..BB78): alu=317 valu=201 q=0 v64=0 salu=75 lds=41 vmem=7 smem=10 wait=92 vcyc=201
- w64 loop 2 (BB15..BB23, innermost): alu=11 valu=4 q=0 v64=0 salu=6 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w64 loop 3 (BB25..BB33, innermost): alu=9 valu=4 q=0 v64=0 salu=4 lds=1 vmem=1 smem=1 wait=4 vcyc=4
- w64 loop 4 (BB35..BB77, innermost): alu=261 valu=173 q=0 v64=0 salu=49 lds=39 vmem=5 smem=5 wait=70 vcyc=173
