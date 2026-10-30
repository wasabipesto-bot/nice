import sys,glob,os
M=0xffffffff
P={}
exec(open(__import__('os').path.join(__import__('os').path.dirname(__file__),'params.py')).read().split('import math')[0])
def chunk16(b):
    e=0;d=1
    while d*b < 1<<16: d*=b; e+=1
    return e,d
import math
def exact_trace(sq, nlimbs, ls, b, e, K):
    v=list(sq)+[0]*(nlimbs-len(sq)); tr=[]
    for k in range(-(-ls//e)):
        rem=0; rec={}
        for i in reversed(range(nlimbs)):
            vi=v[i]
            c1=(rem<<16)|(vi>>16); q1=c1//K; r1=c1-q1*K
            c2=(r1<<16)|(vi&0xffff); q2=c2//K; rem=c2-q2*K
            v[i]=(q1<<16)|q2
            rec[i]=(q1,q2,c1,c2)
        tr.append((rec,rem))
    return tr
d=__import__('os').path.join(__import__('os').path.dirname(__file__),'..','dumps')
for f in sorted(glob.glob(d+'/probe_*_t1.txt')):
    b=int(os.path.basename(f).split('_')[1][1:])
    ls,lc,lo,hi=plan(b); nmax=hi-1; limbs=max(1,math.ceil(nmax.bit_length()/32)); nl=2*limbs
    e,K=chunk16(b)
    firsts={}
    for line in open(f):
        parts=line.split(); n=int(parts[0]); r=[int(x,16) for x in parts[1:]]
        s=n*n; sq=[(s>>(32*i))&M for i in range(nl)]
        tr=exact_trace(sq,nl,ls,b,e,K)
        found=None
        for k,(rec,rem) in enumerate(tr):
            base_at=64+k*(2*nl+1)
            for i in reversed(range(nl)):
                gq1=r[base_at+2*i]; gq2=r[base_at+2*i+1]
                q1,q2,c1,c2=rec[i]
                if gq1!=q1: found=(k,i,'q1',gq1,q1,c1); break
                if gq2!=q2: found=(k,i,'q2',gq2,q2,c2); break
            if found: break
            if r[base_at+2*nl]!=rem: found=(k,'rem'); break
        key=found[:3] if found else None
        firsts.setdefault(key,[]).append((n,found))
    print(f"b{b} K={K} sq_limbs={nl}:", {k:len(v) for k,v in firsts.items()})
    for k,v in firsts.items():
        if k: 
            n,fd=v[0]; s=n*n
            print("    e.g. n=",n,"first wrong (chunk,limb,which,got,want,dividend)=",fd, "sq limbs", [hex((s>>(32*i))&M) for i in range(nl)])
