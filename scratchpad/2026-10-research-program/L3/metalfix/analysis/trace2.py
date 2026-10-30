import glob,os,math
M=0xffffffff
exec(open(__import__('os').path.join(__import__('os').path.dirname(__file__),'params.py')).read().split('import math')[0])
def chunk16(b):
    e=0;d=1
    while d*b < 1<<16: d*=b; e+=1
    return e,d
d=__import__('os').path.join(__import__('os').path.dirname(__file__),'..','dumps')
for f in sorted(glob.glob(d+'/probe_*_t1.txt')):
    b=int(os.path.basename(f).split('_')[1][1:])
    ls,lc,lo_,hi_=plan(b); nmax=hi_-1; limbs=max(1,math.ceil(nmax.bit_length()/32)); nl=2*limbs
    e,K=chunk16(b)
    rows=[]
    for line in open(f):
        parts=line.split(); n=int(parts[0]); r=[int(x,16) for x in parts[1:]]
        rows.append((n,r[64+2*(nl-1)]))   # chunk0, top limb, q1
    # candidate formulas
    cands={}
    for s in range(0,64):
        cands[f'(lo>>{s})/K']=lambda n,s=s: (((n*n)&M)>>s)//K
        cands[f'(p>>{s})/K mod2^32']=lambda n,s=s: (((n*n)>>s)//K)&M
        cands[f'((p>>{s})&M)/K']=lambda n,s=s: (((n*n)>>s)&M)//K
    if limbs==1:
        pass
    ok=[name for name,fn in cands.items() if all(fn(n)==g for n,g in rows)]
    print(f"b{b} K={K} limbs={limbs}: got q1 sample {[g for _,g in rows[:8]]}  matching: {ok[:6]}")
