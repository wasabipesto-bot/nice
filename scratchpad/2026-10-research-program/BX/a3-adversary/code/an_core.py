# Core (interior middle) tests: given E2 (ends + 2-digit buffers) clean,
#  (1) total-distinct distribution vs iid-uniform core model (chi2, tail ratios)
#  (2) per core position P(digit in E2) vs e2/b
#  (3) every pair of core positions: P(equal) vs 1/b  (includes all square-cube cross pairs)
#  (4) E-clean fraction vs uniform product P(e) (the baseline's ends formula)
import json, sys, math
sys.path.insert(0,'code'); from an_middle_model import model
bases=[int(x) for x in sys.argv[1].split(',')]
tot_pairs=0; allz=[]
for b in bases:
    s=json.load(open('data/b%d_stats.json'%b)); l2=s['l2']
    if 'hist_e2' not in s: continue
    H=s['hist_e2']; N2=sum(map(sum,H))
    # (1)
    chi=0; dof=0; meas=[0]*4; mod=[0.0]*4
    for e,row in enumerate(H):
        Ne=sum(row)
        if not Ne: continue
        p=model(b,e)
        for sidx,pv in enumerate(p):
            ex=Ne*pv; ob=row[e+sidx]
            if ex>=5: chi+=(ob-ex)**2/ex; dof+=1
        for j in range(4):
            meas[j]+=sum(row[b-jj] for jj in range(j+1)); mod[j]+=Ne*sum(p[b-e-jj] for jj in range(j+1) if 0<=b-e-jj<len(p))
    # (2)
    ebar=sum(e*sum(r) for e,r in enumerate(H))/N2
    zin=[]
    for pos in range(64):
        m=s['core_n'][pos]
        if not m: continue
        r=s['core_inE'][pos]/m; zin.append((r-ebar/b)/math.sqrt(ebar/b*(1-ebar/b)/m))
    # (3)
    zs=[]; worst=[]
    for i in range(64):
        for j in range(64):
            m=s['pair_n'][i][j]
            if m<1000: continue
            r=s['pair'][i][j]/m; z=(r-1/b)/math.sqrt((1/b)*(1-1/b)/m)
            nm=lambda q: f"S{q}" if q<l2 else f"C{q-l2}"
            zs.append(z); worst.append((abs(z),nm(i),nm(j),r*b,m))
    worst.sort(reverse=True); allz+=zs
    if not worst: worst=[(0,"-","-",0,0)]
    # (4) ends formula
    HA=s['hist_e_all']; T=s['total']
    clean=sum(r[0] for r in HA); expc=sum(sum(r)*math.prod((b-i)/b for i in range(e)) for e,r in enumerate(HA))
    ratio=' '.join(f"{meas[j]/mod[j]:.3f}" if mod[j] else '-' for j in range(4))
    print(f"b{b} N_E2clean={N2} chi2/dof={chi/max(dof-1,1):.2f}({dof}) tail ratio j=0..3: {ratio} [{' '.join(map(str,meas))}]")
    print(f"     core P(inE2) z: max|z|={max(map(abs,zin),default=0):.1f} over {len(zin)} positions;  core pairs: {len(zs)}, max|z|={worst[0][0]:.1f}, #|z|>4={sum(abs(z)>4 for z in zs)}; worst {worst[0][1]}-{worst[0][2]} rate*b={worst[0][3]:.4f} n={worst[0][4]}")
    print(f"     ends: E-clean fraction {clean/T:.4f}, uniform-product prediction {expc/T:.4f}, ratio {clean/expc:.3f}")
import statistics
if allz: print(f"ALL core pairs: {len(allz)}, mean z {statistics.mean(allz):+.3f}, sd {statistics.pstdev(allz):.3f}")
