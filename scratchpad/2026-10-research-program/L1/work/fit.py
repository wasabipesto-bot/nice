import re, sys, numpy as np
rows=[]
for path in sys.argv[1:]:
    for line in open(path):
        if 'GPU_PROFILE' in line and 'size=10000000000000000' in line:
            kv={k:float(v) for k,v in re.findall(r"(\w+)=([0-9.e+-]+)", line)}
            rows.append(kv)
y=np.array([r['join'] for r in rows])
cols={'pairs':lambda r:r['pairs'],'padded':lambda r:r['padded_pairs'],'surv':lambda r:r['survivors'],
      'entry_loads':lambda r:r['listed']}
for combo in [('pairs',),('padded',),('pairs','surv'),('padded','surv'),('pairs','padded'),('padded','surv','entry_loads'),('pairs','surv','entry_loads')]:
    M=np.array([[cols[c](r) for c in combo] for r in rows])
    c,_,_,_=np.linalg.lstsq(M,y,rcond=None)
    pred=M@c
    print(combo, ['%.3e'%x for x in c], 'max rel err %.3f'%np.max(np.abs(pred-y)/y), 'per base:', ' '.join('b%d:%.2f/%.2f'%(r['base'],p,yy) for r,p,yy in zip(rows,pred,y)))
