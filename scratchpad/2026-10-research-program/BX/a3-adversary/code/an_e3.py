# Omnibus higher-order test: n whose non-core digits (all positions except a fixed interior core)
# are distinct; distribution of total distinct vs iid-uniform core model.
import json, sys, math
sys.path.insert(0,'code'); from an_middle_model import model
for b in [int(x) for x in sys.argv[1].split(',')]:
    s=json.load(open('data/b%d_stats.json'%b))
    if 'hist_e3' not in s: continue
    h=s['hist_e3']; N=sum(h); c=s['n_core']; e=b-c
    p=model(b,e)
    chi=0; dof=0; rows=[]
    for si,pv in enumerate(p):
        ex=N*pv; ob=h[e+si]
        if ex>=5: chi+=(ob-ex)**2/ex; dof+=1
        if ex>=1 or ob>0: rows.append(f"{e+si}:{ob}/{ex:.1f}")
    mean_o=sum(i*h[i] for i in range(65))/N; mean_e=sum((e+si)*pv for si,pv in enumerate(p))
    print(f"b{b} core={c} N={N} chi2={chi:.1f} dof={dof-1} mean distinct obs {mean_o:.4f} model {mean_e:.4f} (sd of mean {math.sqrt(sum(((e+si)-mean_e)**2*pv for si,pv in enumerate(p))/N):.4f})")
    print("    ", ' '.join(rows[-8:]))
