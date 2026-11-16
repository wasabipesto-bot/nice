# Table + growth fits: admissible A, exact flat PSJ (with list costs), exact ideal output-sensitive PSJ,
# the free-list flat VC floor (sum 1/mu), and mu=1 count.
import json, math, glob
F={}
for line in open('data/floor_29_32.txt').read().split('\n')+open('data/floor_33.txt').read().split('\n'):
    if line.strip(): d=json.loads(line); F[d['base']]=d
small={17:(483,324.5256969718702,187),18:(1112,391.1223080995326,266),20:(10638,4051.859288944007,2001),22:(80406,14470.596863833169,10216),24:(98707,13936.24476453247,7475),25:(1606456,170504.3959947754,108179),28:(5749318,390397.95560905273,237144)}
for b,(a,f,m) in small.items(): F.setdefault(b,{'admissible':a,'floor':f,'mu1':m})
P={20:(6251,4054),22:(31279,None),24:(36958,16843),25:(468548,181017)}
try:
    lines=[json.loads(l) for l in open('data/psj2.txt') if l.startswith('{')]
    for d in lines:
        b=d['base']; p=P.get(b,(None,None))
        if 'ideal_ov' in d: P[b]=(p[0],d['ideal_ov'][0])
        if 'psj_best' in d: P[b]=(d['psj_best'][0],P[b][1] if b in P else None)
except FileNotFoundError: pass
P.setdefault(17,(569,None)); P.setdefault(18,(661,None))
rows=[]
print("| b | A (admissible) | flat PSJ (exact) | ideal-OV PSJ (exact) | VC floor, free lists | n with mu = 1 | PSJ / floor |")
print("|---|---|---|---|---|---|---|")
for b in sorted(F):
    A=F[b]['admissible']; fl=F[b]['floor']; m=F[b]['mu1']; p,i=P.get(b,(None,None))
    fm=lambda v: f"{v:,}" if v else "-"
    print(f"| {b} | {A:,} | {fm(p)} | {fm(i)} | {fl:,.0f} | {m:,} | {(p/fl) if p else float('nan'):.2f} |")
    rows.append((b,A,p,i,fl,m))
def fit(xs,ys):
    n=len(xs); mx=sum(xs)/n; my=sum(ys)/n
    sl=sum((x-mx)*(y-my) for x,y in zip(xs,ys))/sum((x-mx)**2 for x in xs); return sl
for name,j in [('flat PSJ / A',2),('ideal-OV / A',3),('floor / A',4),('mu1 / A',5)]:
    pts=[(r[0],math.log(r[j]/r[1])) for r in rows if r[j] and r[0]>=20]
    if len(pts)>=3: print(f"slope of ln({name}) vs b over b20+: {fit([p[0] for p in pts],[p[1] for p in pts]):+.3f} per base ({len(pts)} bases)")
pts=[(r[0],math.log(r[2]/r[4])) for r in rows if r[2] and r[0]>=20]
print(f"slope of ln(PSJ/floor): {fit([p[0] for p in pts],[p[1] for p in pts]):+.3f} per base")
