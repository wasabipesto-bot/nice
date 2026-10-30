import re,sys,collections
for f in sys.argv[1:]:
    lines=open(f).read().splitlines()
    ins=[]
    for l in lines:
        m=re.match(r'\s+/\*([0-9a-f]{4})\*/\s+(.*?);',l)
        if m: ins.append((int(m.group(1),16),m.group(2).strip()))
    addr={a:i for i,(a,_) in enumerate(ins)}
    # find backward branches
    loops=[]
    for i,(a,t) in enumerate(ins):
        m=re.search(r'BRA\s+(?:`\(\.L_x_\d+\)\s*)?0x([0-9a-f]+)',t)
        m2=re.search(r'BRA\s+`\((\.L_x_\d+)\)',t)
        if m:
            tgt=int(m.group(1),16)
            if tgt<a and tgt in addr: loops.append((addr[tgt],i))
    print(f, 'total',len(ins))
    # labels approach
    labels={}
    for l in lines:
        m=re.match(r'\.(L_x_\d+):',l.strip())
    for (s,e) in loops:
        body=ins[s:e+1]
        ops=collections.Counter(t.split()[0].lstrip('@!P0123456789T ').split('.')[0] if not t.startswith('@') else t.split()[1].split('.')[0] for _,t in body)
        print(f'  loop {body[0][0]:#x}-{body[-1][0]:#x}: {len(body)} instrs', dict(ops.most_common(14)))
