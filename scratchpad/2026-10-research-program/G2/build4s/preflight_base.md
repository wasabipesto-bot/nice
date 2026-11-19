
### base_narrow

| kernel | wave | VGPRs | SGPRs | LDS B | waves/SIMD | scratch | spills | instr | valu | q | v64 | salu | lds | vmem | vcyc | spirv-val |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| CheckKernel | 64 | 48 | 108 | 0 | 32 | 0 | 0/0 | 1037 | 540 | 116 | 90 | 80 | 0 | 10 | 1184 | ok |
| DoneKernel | 32 | 24 | 108 | 0 | 16 | 0 | 0/0 | 14 | 3 | 0 | 0 | 4 | 0 | 2 | 3 | ok |
| ExpandKernel | 64 | 48 | 108 | 0 | 32 | 0 | 0/0 | 930 | 611 | 30 | 2 | 105 | 0 | 19 | 735 | ok |
| G2Kernel | 64 | 120 | 108 | 21504 | 12 | 0 | 0/0 | 2131 | 773 | 0 | 21 | 626 | 111 | 26 | 815 | ok |
| Hist2Kernel | 64 | 48 | 108 | 1024 | 32 | 0 | 0/0 | 364 | 141 | 14 | 27 | 80 | 3 | 8 | 251 | ok |
| HsortKernel | 64 | 12 | 108 | 16384 | 16 | 0 | 0/0 | 220 | 55 | 0 | 0 | 86 | 13 | 10 | 55 | ok |
| Scan16Kernel | 64 | 24 | 108 | 4096 | 32 | 0 | 0/0 | 529 | 143 | 0 | 0 | 127 | 32 | 70 | 143 | ok |
| Scatter3Kernel | 64 | 48 | 108 | 1024 | 32 | 0 | 0/0 | 1430 | 803 | 0 | 257 | 149 | 5 | 6 | 1317 | error: line 84: ID '25' decorated with ArrayStride multiple  |
| Tdigz2Kernel | 64 | 48 | 108 | 0 | 32 | 0 | 0/0 | 661 | 417 | 0 | 20 | 17 | 0 | 5 | 457 | ok |
| Toprec2Kernel | 64 | 12 | 108 | 0 | 32 | 0 | 0/0 | 52 | 16 | 0 | 0 | 14 | 0 | 4 | 16 | ok |
| Tops1Kernel | 64 | 48 | 108 | 0 | 32 | 0 | 0/0 | 2285 | 1003 | 90 | 159 | 493 | 0 | 8 | 1681 | ok |
| Tops2Kernel | 64 | 48 | 108 | 0 | 32 | 0 | 0/0 | 99 | 31 | 2 | 0 | 22 | 0 | 9 | 39 | ok |
| Tops5Kernel | 64 | 48 | 108 | 0 | 32 | 0 | 0/0 | 1969 | 808 | 88 | 158 | 424 | 0 | 3 | 1476 | ok |
| TscanKernel | 64 | 12 | 108 | 4096 | 32 | 0 | 0/0 | 245 | 53 | 0 | 0 | 79 | 32 | 14 | 53 | ok |

Loops (per wave-iteration, the loop body including nested loops once):

- CheckKernel loop 0 (BB13..BB58, innermost): alu=723 valu=474 q=116 v64=90 salu=43 lds=0 vmem=6 smem=5 wait=143 vcyc=1118
- ExpandKernel loop 0 (BB7..BB95): alu=699 valu=588 q=30 v64=2 salu=79 lds=0 vmem=14 smem=11 wait=117 vcyc=712
- ExpandKernel loop 1 (BB16..BB94): alu=687 valu=584 q=30 v64=2 salu=71 lds=0 vmem=13 smem=10 wait=115 vcyc=708
- ExpandKernel loop 2 (BB37..BB45, innermost): alu=256 valu=228 q=15 v64=1 salu=12 lds=0 vmem=1 smem=1 wait=26 vcyc=290
- ExpandKernel loop 3 (BB47..BB55, innermost): alu=256 valu=228 q=15 v64=1 salu=12 lds=0 vmem=1 smem=1 wait=25 vcyc=290
- ExpandKernel loop 4 (BB63..BB77, innermost): alu=31 valu=24 q=0 v64=0 salu=7 lds=0 vmem=2 smem=2 wait=7 vcyc=24
- ExpandKernel loop 5 (BB79..BB93, innermost): alu=31 valu=24 q=0 v64=0 salu=7 lds=0 vmem=2 smem=2 wait=7 vcyc=24
- G2Kernel loop 0 (BB29..BB43, innermost): alu=21 valu=11 q=0 v64=0 salu=9 lds=1 vmem=1 smem=1 wait=7 vcyc=11
- G2Kernel loop 1 (BB61..BB302): alu=1161 valu=670 q=0 v64=21 salu=364 lds=106 vmem=11 smem=11 wait=364 vcyc=712
- G2Kernel loop 2 (BB65..BB98, innermost): alu=127 valu=52 q=0 v64=5 salu=64 lds=6 vmem=2 smem=2 wait=42 vcyc=62
- G2Kernel loop 3 (BB224..BB238, innermost): alu=79 valu=52 q=0 v64=0 salu=6 lds=21 vmem=0 smem=0 wait=18 vcyc=52
- G2Kernel loop 4 (BB240..BB282, innermost): alu=260 valu=171 q=0 v64=0 salu=50 lds=39 vmem=5 smem=5 wait=79 vcyc=171
- HsortKernel loop 0 (BB15..BB18, innermost): alu=16 valu=9 q=0 v64=0 salu=5 lds=2 vmem=0 smem=0 wait=7 vcyc=9
- HsortKernel loop 1 (BB27..BB30, innermost): alu=4 valu=0 q=0 v64=0 salu=4 lds=0 vmem=0 smem=0 wait=1 vcyc=0
- HsortKernel loop 2 (BB32..BB46, innermost): alu=14 valu=6 q=0 v64=0 salu=7 lds=1 vmem=1 smem=1 wait=3 vcyc=6
- HsortKernel loop 3 (BB48..BB78): alu=40 valu=10 q=0 v64=0 salu=22 lds=8 vmem=0 smem=0 wait=8 vcyc=10
- HsortKernel loop 4 (BB52..BB77): alu=35 valu=10 q=0 v64=0 salu=17 lds=8 vmem=0 smem=0 wait=7 vcyc=10
- HsortKernel loop 5 (BB56..BB76, innermost): alu=26 valu=9 q=0 v64=0 salu=9 lds=8 vmem=0 smem=0 wait=5 vcyc=9
- HsortKernel loop 6 (BB80..BB88, innermost): alu=10 valu=5 q=0 v64=0 salu=4 lds=1 vmem=2 smem=1 wait=4 vcyc=5
- HsortKernel loop 7 (BB91..BB104): alu=19 valu=7 q=0 v64=0 salu=12 lds=0 vmem=3 smem=3 wait=9 vcyc=7
- HsortKernel loop 8 (BB100..BB103, innermost): alu=8 valu=2 q=0 v64=0 salu=6 lds=0 vmem=0 smem=1 wait=5 vcyc=2
- Tops1Kernel loop 0 (BB1..BB267, innermost): alu=1704 valu=979 q=90 v64=159 salu=476 lds=0 vmem=6 smem=5 wait=502 vcyc=1657
- Tops2Kernel loop 0 (BB1..BB21, innermost): alu=30 valu=18 q=2 v64=0 salu=10 lds=0 vmem=8 smem=6 wait=13 vcyc=26

### base_wide

| kernel | wave | VGPRs | SGPRs | LDS B | waves/SIMD | scratch | spills | instr | valu | q | v64 | salu | lds | vmem | vcyc | spirv-val |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| WcheckKernel | 64 | 60 | 108 | 0 | 24 | 0 | 0/0 | 1629 | 915 | 199 | 72 | 84 | 0 | 8 | 1855 | ok |
| WexpandKernel | 64 | 60 | 108 | 0 | 24 | 0 | 0/0 | 2362 | 1242 | 290 | 105 | 265 | 0 | 19 | 2612 | ok |
| WhistKernel | 64 | 48 | 108 | 1024 | 32 | 0 | 0/0 | 788 | 396 | 110 | 27 | 81 | 3 | 8 | 890 | ok |
| WideKernel | 64 | 192 | 108 | 24576 | 8 | 0 | 0/0 | 2393 | 980 | 10 | 21 | 625 | 145 | 28 | 1062 | ok |
| WscanKernel | 64 | 24 | 108 | 4096 | 32 | 0 | 0/0 | 781 | 195 | 0 | 0 | 197 | 33 | 82 | 195 | ok |
| WscanKernel | 64 | 12 | 108 | 4096 | 32 | 0 | 0/0 | 336 | 79 | 0 | 0 | 100 | 33 | 22 | 79 | ok |
| WscatterKernel | 64 | 48 | 108 | 1024 | 32 | 0 | 0/0 | 3389 | 2182 | 130 | 261 | 282 | 5 | 6 | 3224 | error: line 84: ID '25' decorated with ArrayStride multiple  |
| WsortKernel | 64 | 12 | 108 | 16384 | 16 | 0 | 0/0 | 221 | 54 | 0 | 0 | 87 | 13 | 10 | 54 | ok |
| WtdigzKernel | 64 | 48 | 108 | 0 | 32 | 0 | 0/0 | 881 | 598 | 0 | 20 | 16 | 0 | 7 | 638 | ok |
| Wtops1Kernel | 64 | 72 | 108 | 0 | 20 | 0 | 0/0 | 3082 | 1463 | 353 | 98 | 551 | 0 | 10 | 3071 | ok |
| Wtops2Kernel | 64 | 48 | 108 | 0 | 32 | 0 | 0/0 | 125 | 40 | 2 | 0 | 26 | 0 | 13 | 48 | ok |
| Wtops5Kernel | 64 | 60 | 108 | 0 | 24 | 0 | 0/0 | 2872 | 1314 | 360 | 97 | 534 | 0 | 3 | 2948 | ok |

Loops (per wave-iteration, the loop body including nested loops once):

- WcheckKernel loop 0 (BB1..BB33, innermost): alu=1191 valu=877 q=199 v64=72 salu=43 lds=0 vmem=5 smem=7 wait=302 vcyc=1817
- WexpandKernel loop 0 (BB7..BB113): alu=1826 valu=1207 q=290 v64=105 salu=224 lds=0 vmem=14 smem=16 wait=380 vcyc=2577
- WexpandKernel loop 1 (BB16..BB112): alu=1814 valu=1203 q=290 v64=105 salu=216 lds=0 vmem=13 smem=15 wait=379 vcyc=2573
- WexpandKernel loop 2 (BB32..BB46, innermost): alu=792 valu=527 q=142 v64=49 salu=74 lds=0 vmem=1 smem=1 wait=141 vcyc=1193
- WexpandKernel loop 3 (BB48..BB62, innermost): alu=792 valu=527 q=142 v64=49 salu=74 lds=0 vmem=1 smem=1 wait=141 vcyc=1193
- WexpandKernel loop 4 (BB76..BB90, innermost): alu=18 valu=11 q=0 v64=0 salu=7 lds=0 vmem=2 smem=2 wait=4 vcyc=11
- WexpandKernel loop 5 (BB92..BB106, innermost): alu=18 valu=11 q=0 v64=0 salu=7 lds=0 vmem=2 smem=2 wait=4 vcyc=11
- WideKernel loop 0 (BB37..BB51, innermost): alu=22 valu=10 q=0 v64=0 salu=10 lds=2 vmem=2 smem=1 wait=8 vcyc=10
- WideKernel loop 1 (BB62..BB441): alu=1515 valu=871 q=10 v64=21 salu=476 lds=137 vmem=11 smem=11 wait=425 vcyc=953
- WideKernel loop 2 (BB66..BB99, innermost): alu=149 valu=71 q=2 v64=5 salu=65 lds=6 vmem=2 smem=2 wait=47 vcyc=89
- WideKernel loop 3 (BB357..BB371, innermost): alu=86 valu=56 q=0 v64=0 salu=7 lds=23 vmem=0 smem=0 wait=24 vcyc=56
- WideKernel loop 4 (BB373..BB415, innermost): alu=276 valu=181 q=0 v64=0 salu=52 lds=43 vmem=5 smem=5 wait=82 vcyc=181
- WsortKernel loop 0 (BB15..BB18, innermost): alu=16 valu=9 q=0 v64=0 salu=5 lds=2 vmem=0 smem=0 wait=8 vcyc=9
- WsortKernel loop 1 (BB27..BB30, innermost): alu=4 valu=0 q=0 v64=0 salu=4 lds=0 vmem=0 smem=0 wait=1 vcyc=0
- WsortKernel loop 2 (BB32..BB46, innermost): alu=15 valu=7 q=0 v64=0 salu=7 lds=1 vmem=1 smem=1 wait=3 vcyc=7
- WsortKernel loop 3 (BB48..BB78): alu=40 valu=10 q=0 v64=0 salu=22 lds=8 vmem=0 smem=0 wait=8 vcyc=10
- WsortKernel loop 4 (BB52..BB77): alu=35 valu=10 q=0 v64=0 salu=17 lds=8 vmem=0 smem=0 wait=7 vcyc=10
- WsortKernel loop 5 (BB56..BB76, innermost): alu=26 valu=9 q=0 v64=0 salu=9 lds=8 vmem=0 smem=0 wait=5 vcyc=9
- WsortKernel loop 6 (BB80..BB88, innermost): alu=10 valu=5 q=0 v64=0 salu=4 lds=1 vmem=2 smem=1 wait=4 vcyc=5
- WsortKernel loop 7 (BB91..BB104): alu=22 valu=9 q=0 v64=0 salu=13 lds=0 vmem=3 smem=3 wait=10 vcyc=9
- WsortKernel loop 8 (BB100..BB103, innermost): alu=9 valu=2 q=0 v64=0 salu=7 lds=0 vmem=0 smem=1 wait=5 vcyc=2
- Wtops1Kernel loop 0 (BB1..BB303, innermost): alu=2429 valu=1439 q=353 v64=98 salu=539 lds=0 vmem=8 smem=11 wait=574 vcyc=3047
- Wtops2Kernel loop 0 (BB1..BB21, innermost): alu=47 valu=27 q=2 v64=0 salu=18 lds=0 vmem=12 smem=7 wait=22 vcyc=35

### base_hosttops

| kernel | wave | VGPRs | SGPRs | LDS B | waves/SIMD | scratch | spills | instr | valu | q | v64 | salu | lds | vmem | vcyc | spirv-val |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| CheckKernel | 64 | 48 | 108 | 0 | 32 | 0 | 0/0 | 1037 | 540 | 116 | 90 | 80 | 0 | 10 | 1184 | ok |
| DoneKernel | 32 | 24 | 108 | 0 | 16 | 0 | 0/0 | 14 | 3 | 0 | 0 | 4 | 0 | 2 | 3 | ok |
| ExpandKernel | 64 | 48 | 108 | 0 | 32 | 0 | 0/0 | 930 | 611 | 30 | 2 | 105 | 0 | 19 | 735 | ok |
| G2Kernel | 64 | 120 | 108 | 21504 | 12 | 0 | 0/0 | 2131 | 773 | 0 | 21 | 626 | 111 | 26 | 815 | ok |
| Hist2Kernel | 64 | 48 | 108 | 1024 | 32 | 0 | 0/0 | 364 | 141 | 14 | 27 | 80 | 3 | 8 | 251 | ok |
| HsortKernel | 64 | 12 | 108 | 16384 | 16 | 0 | 0/0 | 220 | 55 | 0 | 0 | 86 | 13 | 10 | 55 | ok |
| Scan16Kernel | 64 | 24 | 108 | 4096 | 32 | 0 | 0/0 | 529 | 143 | 0 | 0 | 127 | 32 | 70 | 143 | ok |
| Scatter3Kernel | 64 | 48 | 108 | 1024 | 32 | 0 | 0/0 | 1430 | 803 | 0 | 257 | 149 | 5 | 6 | 1317 | error: line 84: ID '25' decorated with ArrayStride multiple  |
| TdigzKernel | 64 | 48 | 108 | 0 | 32 | 0 | 0/0 | 642 | 416 | 0 | 20 | 8 | 0 | 5 | 456 | ok |
| ToprecKernel | 32 | 12 | 108 | 0 | 32 | 0 | 0/0 | 32 | 15 | 0 | 0 | 4 | 0 | 3 | 15 | ok |

Loops (per wave-iteration, the loop body including nested loops once):

- CheckKernel loop 0 (BB13..BB58, innermost): alu=723 valu=474 q=116 v64=90 salu=43 lds=0 vmem=6 smem=5 wait=143 vcyc=1118
- ExpandKernel loop 0 (BB7..BB95): alu=699 valu=588 q=30 v64=2 salu=79 lds=0 vmem=14 smem=11 wait=117 vcyc=712
- ExpandKernel loop 1 (BB16..BB94): alu=687 valu=584 q=30 v64=2 salu=71 lds=0 vmem=13 smem=10 wait=115 vcyc=708
- ExpandKernel loop 2 (BB37..BB45, innermost): alu=256 valu=228 q=15 v64=1 salu=12 lds=0 vmem=1 smem=1 wait=26 vcyc=290
- ExpandKernel loop 3 (BB47..BB55, innermost): alu=256 valu=228 q=15 v64=1 salu=12 lds=0 vmem=1 smem=1 wait=25 vcyc=290
- ExpandKernel loop 4 (BB63..BB77, innermost): alu=31 valu=24 q=0 v64=0 salu=7 lds=0 vmem=2 smem=2 wait=7 vcyc=24
- ExpandKernel loop 5 (BB79..BB93, innermost): alu=31 valu=24 q=0 v64=0 salu=7 lds=0 vmem=2 smem=2 wait=7 vcyc=24
- G2Kernel loop 0 (BB29..BB43, innermost): alu=21 valu=11 q=0 v64=0 salu=9 lds=1 vmem=1 smem=1 wait=7 vcyc=11
- G2Kernel loop 1 (BB61..BB302): alu=1161 valu=670 q=0 v64=21 salu=364 lds=106 vmem=11 smem=11 wait=364 vcyc=712
- G2Kernel loop 2 (BB65..BB98, innermost): alu=127 valu=52 q=0 v64=5 salu=64 lds=6 vmem=2 smem=2 wait=42 vcyc=62
- G2Kernel loop 3 (BB224..BB238, innermost): alu=79 valu=52 q=0 v64=0 salu=6 lds=21 vmem=0 smem=0 wait=18 vcyc=52
- G2Kernel loop 4 (BB240..BB282, innermost): alu=260 valu=171 q=0 v64=0 salu=50 lds=39 vmem=5 smem=5 wait=79 vcyc=171
- HsortKernel loop 0 (BB15..BB18, innermost): alu=16 valu=9 q=0 v64=0 salu=5 lds=2 vmem=0 smem=0 wait=7 vcyc=9
- HsortKernel loop 1 (BB27..BB30, innermost): alu=4 valu=0 q=0 v64=0 salu=4 lds=0 vmem=0 smem=0 wait=1 vcyc=0
- HsortKernel loop 2 (BB32..BB46, innermost): alu=14 valu=6 q=0 v64=0 salu=7 lds=1 vmem=1 smem=1 wait=3 vcyc=6
- HsortKernel loop 3 (BB48..BB78): alu=40 valu=10 q=0 v64=0 salu=22 lds=8 vmem=0 smem=0 wait=8 vcyc=10
- HsortKernel loop 4 (BB52..BB77): alu=35 valu=10 q=0 v64=0 salu=17 lds=8 vmem=0 smem=0 wait=7 vcyc=10
- HsortKernel loop 5 (BB56..BB76, innermost): alu=26 valu=9 q=0 v64=0 salu=9 lds=8 vmem=0 smem=0 wait=5 vcyc=9
- HsortKernel loop 6 (BB80..BB88, innermost): alu=10 valu=5 q=0 v64=0 salu=4 lds=1 vmem=2 smem=1 wait=4 vcyc=5
- HsortKernel loop 7 (BB91..BB104): alu=19 valu=7 q=0 v64=0 salu=12 lds=0 vmem=3 smem=3 wait=9 vcyc=7
- HsortKernel loop 8 (BB100..BB103, innermost): alu=8 valu=2 q=0 v64=0 salu=6 lds=0 vmem=0 smem=1 wait=5 vcyc=2
