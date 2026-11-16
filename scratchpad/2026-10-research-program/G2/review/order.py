import math
def P(b,m): return math.prod(1-i/b for i in range(m))
for b,R in ((62,2),(64,8)):
    import sys
    sys.path.insert(0,'..')
    from model import INFO
    A=INFO[b]['A']; W=INFO[b]['W']
    c=0.95
    # order A: digit4 innermost -> tops parents shared; bottoms re-derived per super-unit from stored depth-4 roots
    nsu=b**5
    per_su = sum(b**4*P(b,2*j)*c for j in range(4,9))  # nodes at depth 5..9 reached (each node at depth j extended by 1 fixed digit)
    # visits: each node at depth j (j=4..8) gets one visit for its fixed digit
    visitsA = nsu*per_su/A
    parents = b**9*P(b,18)*c/A
    children = b*parents
    # order B: digit 8 innermost -> bottoms once (shared tree), tops tested without parent prune
    tops_all = W/b**4/A
    tops_hier = W/b**4*{62:.2129,64:.1966}[b]/A
    print(f"b{b}: A={A:.3e} children/adm {children:.3e} parents/adm {parents:.3e}")
    print(f"  order A (tops hierarchical {tops_hier:.3e}): extra bottom re-derivation visits/adm {visitsA:.3e} = {visitsA/children:.2f} x children")
    print(f"  order B (bottom tree shared): tops tested/adm {tops_all:.3e} (x{tops_all/tops_hier:.2f}); extra cost at 0.17ns {(tops_all-tops_hier)*0.17e-9*1e15:.3f} fs")
    for cv in (1e-12,3e-12,5e-12):
        print(f"  order A extra at {cv*1e12:.0f} ps/visit: {visitsA*cv*1e15:.3f} fs")
