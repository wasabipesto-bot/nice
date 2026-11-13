#!/usr/bin/env python3
"""summarize.py ACO_TXT...: instruction mix of each ACO dump (after lowering to hw instructions): totals and per
opcode family; wave size from the exec mask width. python3 -I summarize.py files"""
import sys, re, collections
for p in sys.argv[1:]:
    t = open(p).read()
    i = t.find('After lowering to hw instructions')
    body = t[i:t.find('*** SHADER STATS', i)] if i >= 0 else ''
    ops = collections.Counter()
    for l in body.splitlines():
        l = l.strip()
        if not l or l.startswith(('BB', '/*', 'ACO')): continue
        m = re.match(r'(?:(?:s|v|lv)\d+: \S+ (?:, *(?:s|v)\d+: \S+ )*= )?(\w+)', l)
        if m: ops[m.group(1)] += 1
    st = dict(re.findall(r'^(SGPRs|VGPRs|Spilled VGPRs|Code size|LDS size|Subgroups per SIMD|Instructions|VALU|SALU|VMEM|SMEM|Latency|Inverse Throughput): (\d+)', t[t.find('*** SHADER STATS'):], re.M))
    wave = 64 if re.search(r'%0:exec = s_mov_b64', body) else 32
    fam = collections.Counter()
    for o, c in ops.items():
        k = ('barrier' if o.startswith('s_barrier_signal') else 'lds_read' if o.startswith('ds_read') or o.startswith('ds_load') else
             'lds_write' if o.startswith(('ds_write', 'ds_store')) else 'lds_atomic' if o.startswith('ds_') else
             'vmem_load' if o.startswith(('buffer_load', 'global_load')) else 'vmem_store' if o.startswith(('buffer_store', 'global_store')) else
             'vmem_atomic' if o.startswith(('buffer_atomic', 'global_atomic')) else
             '64bit_valu' if o.startswith('v_') and re.search(r'_(u64|i64|b64|f64)$', o) else
             'mul_hi' if 'mul_hi' in o else 'bfrev' if 'bfrev' in o else 'subgroup' if o.startswith(('v_readlane', 'v_readfirstlane', 'v_permlane', 'v_writelane', 's_bcnt', 'v_mbcnt')) else
             'clamp(min/med3)' if o.startswith(('v_min_u32', 'v_med3_u32', 's_min_u32')) else
             'salu' if o.startswith('s_') else 'valu' if o.startswith('v_') else 'other')
        fam[k] += c
    print(f"{p.split('/')[-1]}: wave{wave} " + ' '.join(f'{k}={v}' for k, v in st.items()))
    print('   ' + ' '.join(f'{k}={v}' for k, v in sorted(fam.items(), key=lambda x: -x[1])))
