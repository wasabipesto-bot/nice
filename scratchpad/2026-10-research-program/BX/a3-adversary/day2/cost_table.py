# Pairing-term cost (fs per admissible n) per scheme and super-unit under three GPU unit-cost points.
import re, sys
rows=[]
for line in open('raw/all_schemes.txt'):
    m=re.match(r'(\S+) (\S+) blocks.*children/adm (\S+) flat (\S+) kept (\S+) .*touch (\S+) pack (\S+) .*lookups/kept (\S+) visits/adm (\S+)', line)
    if m:
        u,s=m.group(1),m.group(2); ch,flat,kept,touch,pack,L,vis=map(float,m.group(3,4,5,6,7,8,9))
        rows.append((u,s,ch,flat,kept,touch,pack,L,vis))
# cost points: (word base B0, ps per lookup, skip test, bucket visit, per-child partition/sort for unit-specific orders)
pts={'low':(3,0.64,0.5,0.5,2,20),'central':(7,0.9,1,1,5,60),'high':(15.1,1.29,2,2,20,150)}
def cost(r,p):
    u,s,ch,flat,kept,touch,pack,L,vis=r; B0,lk,sk,vi,part,sort=p
    c=kept*(B0+lk*L)+flat*sk
    if s.startswith('bucket') or s.startswith('parbucket'): c+=vis*vi
    if s.startswith('bucket'): c+=ch*part          # unit-specific 2^d-way stable partition of children
    if s=='fullblock': c+=ch*sort                    # unit-specific full sort of children
    return c*1e3  # ps/adm -> fs/adm
print("| unit | scheme | kept words/adm | lookups/word | low | central | high | ratio vs G2 (low/central/high) |")
print("|---|---|---|---|---|---|---|---|")
base={}
for r in rows:
    if r[1]=='g2': base[r[0]]={k:cost(r,p) for k,p in pts.items()}
for r in rows:
    c={k:cost(r,p) for k,p in pts.items()}
    rat='/'.join(f"{base[r[0]][k]/c[k]:.2f}" for k in pts)
    print(f"| {r[0]} | {r[1]} | {r[4]:.3e} | {r[7]:.2f} | {c['low']:.3f} | {c['central']:.3f} | {c['high']:.3f} | {rat} |")
print()
print("| unit | G2 kept | touched words (ideal, G2 chunks) | packed words (ideal) | kept/touch | kept/pack | G2 central fs | ideal-touch central fs (L full) |")
print("|---|---|---|---|---|---|---|---|")
for r in rows:
    if r[1]=='g2':
        u,s,ch,flat,kept,touch,pack,L,vis=r
        print(f"| {u} | {kept:.3e} | {touch:.3e} | {pack:.3e} | {kept/touch:.1f} | {kept/pack:.0f} | {base[u]['central']:.3f} | {touch*(7+0.9*L)*1e3:.3f} |")
