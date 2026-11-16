def model(b,e):
    m=b-e
    p=[0.0]*(m+1); p[0]=1.0
    for _ in range(m):
        q=[0.0]*(m+1)
        for s,v in enumerate(p):
            if v==0: continue
            q[s]+=v*(e+s)/b
            if s<m: q[s+1]+=v*(b-e-s)/b
        p=q
    return p
