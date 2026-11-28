import re,difflib,sys
t=open(sys.argv[1]).read()
blks=re.findall(r"\[START_KERNEL_COMPILATION\](.*?)\[END_KERNEL_COMPILATION\]",t,re.S)
def get(n,w,e):
    for b in blks:
        if re.search(r"^name: \S+?::"+n+"<",b,re.M) and re.search(r"^        emul: "+e+",$",b,re.M) and (w is None or re.search(r"^        w: "+w+",$",b,re.M)):
            return b.partition("\nsource:")[2]
def norm(src):
    lines=[l for l in src.splitlines() if not re.match(r"^var l_",l)]
    m={}
    def r(mo):
        k=mo.group(0)
        if k not in m: m[k]=("v%d"%len(m))
        return m[k]
    return [re.sub(r"\bl_(?:mut_)?\d+\b","L",l) for l in lines]
for n,w in [("WexpandKernel",None),("WideKernel","32"),("ExpandKernel",None),("G2Kernel","32"),("WancKernel","32"),("Wtops5Kernel","32"),("Anc8Kernel","32")]:
    a=norm(get(n,w,"false")); b=norm(get(n,w,"true"))
    d=[l for l in difflib.unified_diff(a,b,lineterm='',n=0) if not l.startswith(('---','+++'))]
    print("==",n,"removed",sum(1 for l in d if l.startswith('-')),"added",sum(1 for l in d if l.startswith('+')))
    print('\n'.join(d))
