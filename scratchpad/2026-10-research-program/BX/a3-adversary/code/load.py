import numpy as np, json
DT=np.dtype([('n','<u8'),('nice','u1'),('e','u1'),('eclean','u1'),('ndA','u1'),('ndC','u1'),('lA','u1'),('lC','u1'),('ecoll','u1'),('mA','<u8'),('mC','<u8')])
def load(b):
    s=json.load(open('data/b%d_stats.json'%b))
    smp=np.fromfile('data/b%d_sample.bin'%b,dtype=DT)
    pos=np.fromfile('data/b%d_pos.bin'%b,dtype=DT)
    return s,smp,pos
def digits(n,b,L):
    n=n.astype(np.int64).copy(); out=np.zeros((len(n),L),dtype=np.int64)
    for i in range(L):
        out[:,i]=n%b; n//=b
    return out  # little-endian
