# Do pandigital numbers (all b-digit permutations, leading digit nonzero) cover every residue mod m?
import numpy as np, itertools, sys
b=int(sys.argv[1])
perms=np.array(list(itertools.permutations(range(b))),dtype=np.int64)
perms=perms[perms[:,0]!=0]
P=np.zeros(len(perms),dtype=np.int64)
for i in range(b): P=P*b+perms[:,i]
bad=[]
for m in range(2,1001):
    c=np.bincount(P%m,minlength=m)
    if (c==0).any(): bad.append((m,int((c==0).sum())))
print(f"b{b}: {len(P)} pandigitals; moduli 2..1000 with missing residues: {bad}")
