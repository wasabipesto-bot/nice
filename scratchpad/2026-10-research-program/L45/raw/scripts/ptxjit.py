#!/usr/bin/env python3
"""L45: JIT every kernel image in CubeCL PTX cache chunks the way the runtime does (cuModuleLoadDataEx, i.e. CubeCL's
cuModuleLoadData plus the info log) and report the driver ptxas's registers / spill bytes, the function attributes, and
the SASS of the cubin the driver JIT produced (taken from a private CUDA_CACHE_PATH): instruction, STL and LDL counts.
python3 ptxjit.py [--only join] [--sass DIR] PTX_DIR...   (PTX_DIR = a run's /root/l45/ptx/<name>; entries in compile
order). An entry whose image is already a cubin (pins built by pin.py --replace) is loaded as such."""
import ctypes, re, sys, os, subprocess, hashlib, glob, tempfile
JC = tempfile.mkdtemp(prefix='l45jc_'); os.environ['CUDA_CACHE_PATH'] = JC; os.environ['CUDA_CACHE_DISABLE'] = '0'
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cbor_min import entries
args = sys.argv[1:]
only = None; sassdir = None
while args and args[0].startswith('--'):
    if args[0] == '--only': only = args[1]; args = args[2:]
    elif args[0] == '--sass': sassdir = args[1]; args = args[2:]
cu = ctypes.CDLL('libcuda.so.1')
def ck(r, what):
    if r != 0: raise RuntimeError(f'{what} -> CUresult {r}')
ck(cu.cuInit(0), 'cuInit')
dev = ctypes.c_int(); ck(cu.cuDeviceGet(ctypes.byref(dev), 0), 'cuDeviceGet')
ctx = ctypes.c_void_p(); ck(cu.cuDevicePrimaryCtxRetain(ctypes.byref(ctx), dev), 'retain'); ck(cu.cuCtxSetCurrent(ctx), 'setcur')
def attr(f, a):
    v = ctypes.c_int(); ck(cu.cuFuncGetAttribute(ctypes.byref(v), a, f), 'attr'); return v.value
seen = set(); SASS = {}
def new_cubins():
    out = []
    for p in glob.glob(f'{JC}/**/*', recursive=True):
        if os.path.isfile(p) and not p.endswith('index') and p not in seen:
            seen.add(p); d = open(p, 'rb').read(); i = d.find(b'\x7fELF')
            if i >= 0: out.append(d[i:])
    return out
def sass_of(cubin):
    tmp = f'/tmp/ptxjit_{os.getpid()}.cubin'; open(tmp, 'wb').write(cubin)
    return subprocess.run(['/usr/local/cuda/bin/cuobjdump', '-sass', tmp], capture_output=True, text=True).stdout
for root in args:
    tag = os.path.basename(root.rstrip('/'))
    for chunk in sorted(glob.glob(f'{root}/cuda/*/ptx/chunk*.cbor')):
        for i, (s, e, ent) in enumerate(entries(open(chunk, 'rb').read())):
            v = ent['value']; name = v['entrypoint_name']
            img = bytes((x & 0xFF) for x in v['ptx'])
            is_cubin = img[:4] == b'\x7fELF'
            if not is_cubin: img = img.rstrip(b'\0') + b'\0'
            if only and only not in name: continue
            info = ctypes.create_string_buffer(1 << 16)
            opts = (ctypes.c_int * 3)(3, 4, 12)
            vals = (ctypes.c_void_p * 3)(ctypes.cast(info, ctypes.c_void_p), ctypes.c_void_p(1 << 16), ctypes.c_void_p(1))
            new_cubins()
            mod = ctypes.c_void_p(); ck(cu.cuModuleLoadDataEx(ctypes.byref(mod), img, 3, opts, vals), 'load')
            f = ctypes.c_void_p(); ck(cu.cuModuleGetFunction(ctypes.byref(f), mod, name.encode()), 'getfn')
            regs, local = attr(f, 4), attr(f, 3)
            log = info.value.decode(errors='replace')
            mi = re.search(r'(\d+) bytes stack frame, (\d+) bytes spill stores, (\d+) bytes spill loads', log)
            spill = f'spillst={mi.group(2)} spillld={mi.group(3)}' if mi else ('spillst=cubin spillld=cubin' if is_cubin else 'spillst=? spillld=?')
            cu.cuModuleUnload(mod)
            ph = hashlib.md5(img).hexdigest()[:8]
            cubs = [img] if is_cubin else new_cubins()
            sass = sass_of(cubs[0]) if cubs else SASS.get(ph, '')
            SASS[ph] = sass
            ins = re.findall(r'^\s+/\*[0-9a-f]{4,}\*/\s+(.*?)\s*;', sass, re.M)
            stl = sum(1 for t in ins if re.search(r'\bSTL', t)); ldl = sum(1 for t in ins if re.search(r'\bLDL', t))
            ph = hashlib.md5(img).hexdigest()[:8]
            if sassdir and sass:
                os.makedirs(sassdir, exist_ok=True)
                open(f'{sassdir}/{tag}_{i}_{ph}.sass', 'w').write(sass)
            print(f'/ptx/{tag}/ #{i} {name[:70]} ptx={ph} regs={regs} local={local} sass={len(ins)} stl={stl} ldl={ldl} {spill} '
                  f'image={"cubin" if is_cubin else "ptx"} variant={"SPILL" if (stl or ldl or local) else "nospill"} key={ent["key"]}', flush=True)
