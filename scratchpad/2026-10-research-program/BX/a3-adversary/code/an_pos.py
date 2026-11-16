import json, sys, math
b=int(sys.argv[1]); s=json.load(open('data/b%d_stats.json'%b))
H=s['hist_e_mid']; k=s['k']; l2=s['l2']; l3=s['l3']
tot=sum(sum(r) for r in H); ebar=sum(e*sum(r) for e,r in enumerate(H))/tot
print("b",b,"L",s['L'],"t",s['t'],"k",k,"l2",l2,"l3",l3,"Eclean",tot,"mean e",round(ebar,2),"E-hit model e/b=%.4f"%(ebar/b))
for w,name,ln in [(0,'n^2',l2),(1,'n^3',l3)]:
    print(name)
    for i in range(ln):
        m=s['pos_mid'][w][i]
        if m==0: continue
        inE=s['pos_inE'][w][i]/m; col=s['pos_coll'][w][i]/m
        dig=s['pos_digit'][w][i][:b]
        # chi2 for digit uniformity
        ex=m/b; chi=sum((d-ex)**2/ex for d in dig)
        print(f"  pos {i:2d} mid {m:9d} P(inE) {inE:.4f} ({(inE-ebar/b)/math.sqrt(ebar/b*(1-ebar/b)/m):+6.1f}sd) P(coll) {col:.4f}  digit chi2/{b-1}: {chi/(b-1):7.2f}")
