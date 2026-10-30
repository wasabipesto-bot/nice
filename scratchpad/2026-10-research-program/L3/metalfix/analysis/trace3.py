import glob,os,math,collections
M=0xffffffff
exec(open(__import__('os').path.join(__import__('os').path.dirname(__file__),'params.py')).read().split('import math')[0])
def chunk16(b):
    e=0;d=1
    while d*b < 1<<16: d*=b; e+=1
    return e,d
d=__import__('os').path.join(__import__('os').path.dirname(__file__),'..','dumps')
for b in [23,27,28,50]:
    f=glob.glob(d+f'/probe_b{b}_*_t1.txt')[0]
    ls,lc,lo_,hi_=plan(b); nmax=hi_-1; limbs=max(1,math.ceil(nmax.bit_length()/32)); nl=2*limbs
    e,K=chunk16(b)
    vals=collections.Counter(); tops=collections.Counter()
    lines=open(f).read().split('\n')[:-1]
    for line in lines:
        parts=line.split(); n=int(parts[0]); r=[int(x,16) for x in parts[1:]]
        s=n*n; top=(s>>(32*(nl-1)))&M
        vals[r[64+2*(nl-1)]]+=1; tops[top]+=1
    print(f"b{b} K={K}: got q1 values {dict(vals)}; top-limb values {dict(list(tops.items())[:4])}")
    # full chunk0 for first n
    parts=lines[0].split(); n=int(parts[0]); r=[int(x,16) for x in parts[1:]]
    s=n*n; v=[(s>>(32*i))&M for i in range(nl)]
    rem=0
    for i in reversed(range(nl)):
        vi=v[i]; c1=(rem<<16)|(vi>>16); q1=c1//K; r1=c1-q1*K; c2=(r1<<16)|(vi&0xffff); q2=c2//K; rem=c2-q2*K
        print(f"   limb {i}: vi={vi:#x} c1={c1} q1 want {q1} got {r[64+2*i]} | c2={c2} q2 want {q2} got {r[64+2*i+1]}")
    print(f"   rem want {rem} got {r[64+2*nl]}")
