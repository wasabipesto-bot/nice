import itertools
M=0xffffffff
def digs(x,b,nd):
    r=[]
    for _ in range(nd): r.append(x%b); x//=b
    return r
def run(lo,hi,nd,b,e,K,opts):
    # opts: for chunk0 word1 (raw hi): q1src, q2src in {'c','lo'}, store in {'q','x'}
    v=[lo,hi]; out=[]
    nch=-(-nd//e)
    for k in range(nch):
        rem=0
        for i in reversed(range(2)):
            vi=v[i]
            c1=((rem<<16)|(vi>>16))&M
            raw = (k==0 and i==1)
            if raw and opts[0]=='lo': c1q=((rem<<16)|(lo>>16))&M
            else: c1q=c1
            q1=c1q//K; r1=(c1-q1*K)&M
            c2=((r1<<16)|(vi&0xffff))&M
            if raw and opts[1]=='lo': c2q=((r1<<16)|(lo&0xffff))&M
            elif raw and opts[1]=='lo2': c2q=(((((rem<<16)|(lo>>16))%K)<<16)|(lo&0xffff))&M
            else: c2q=c2
            q2=c2q//K; rem=(c2-q2*K)&M
            v[i]=((q1<<16)|q2)&M
        ch=rem
        for i in range(e):
            if len(out)<nd: out.append(ch%b); ch//=b
    return out
cases=[(23,795831,9,3,12167,[1, 10, 6, 11, 18, 15, 7, 4, 2]),(23,795832,9,3,12167,[18, 5, 2, 4, 1, 16, 7, 4, 2])]
for b,n,nd,e,K,got in cases:
    s=n*n; lo=s&M; hi=s>>32
    print(run(lo,hi,nd,b,e,K,('c','c'))==digs(s,b,nd))
    for o in itertools.product(['c','lo'],['c','lo','lo2']):
        r=run(lo,hi,nd,b,e,K,o)
        print(o, r, r==got)
    print("got",got)
