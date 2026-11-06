#!/usr/bin/env python3
"""L45: JIT every kernel PTX in CubeCL PTX cache chunks with the driver (the runtime's own path: NVRTC PTX ->
cuModuleLoadData) and report registers, local (spill) bytes and, from the linked cubin, SASS instruction / STL / LDL
counts.  python3 ptxjit.py [--only join] [--sass DIR] PTX_DIR...   (PTX_DIR = a run's /root/l45/ptx/<name>)
Chunk entries are in compile order."""
import ctypes, re, sys, os, subprocess, hashlib, glob
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
for root in args:
    tag = os.path.basename(root.rstrip('/'))
    for chunk in sorted(glob.glob(f'{root}/cuda/*/ptx/chunk*.cbor')):
        for i, (s, e, ent) in enumerate(entries(open(chunk, 'rb').read())):
            v = ent['value']; name = v['entrypoint_name']
            ptx = bytes((x & 0xFF) for x in v['ptx']).rstrip(b'\0') + b'\0'
            m = re.search(rb'\.entry\s+(\w+)', ptx); ename = m.group(1).decode() if m else name
            if only and only not in name and only not in ename: continue
            mod = ctypes.c_void_p(); ck(cu.cuModuleLoadData(ctypes.byref(mod), ptx), 'load')
            f = ctypes.c_void_p(); ck(cu.cuModuleGetFunction(ctypes.byref(f), mod, ename.encode()), 'getfn')
            regs, local = attr(f, 4), attr(f, 3)
            # the driver JIT's own ptxas info log (CU_JIT_INFO_LOG_BUFFER=3, _SIZE_BYTES=4, CU_JIT_LOG_VERBOSE=12)
            logbuf = ctypes.create_string_buffer(65536)
            opts = (ctypes.c_int * 3)(3, 4, 12)
            vals = (ctypes.c_void_p * 3)(ctypes.cast(logbuf, ctypes.c_void_p), ctypes.c_void_p(65536), ctypes.c_void_p(1))
            st = ctypes.c_void_p(); ck(cu.cuLinkCreate_v2(3, opts, vals, ctypes.byref(st)), 'linkcreate')
            ck(cu.cuLinkAddData_v2(st, 1, ptx, len(ptx), b'k.ptx', 0, None, None), 'linkadd')
            cub = ctypes.c_void_p(); sz = ctypes.c_size_t()
            ck(cu.cuLinkComplete(st, ctypes.byref(cub), ctypes.byref(sz)), 'linkcomplete')
            cubin = ctypes.string_at(cub, sz.value)
            info = logbuf.value.decode(errors='replace')
            mi = re.search(r'(\d+) bytes stack frame, (\d+) bytes spill stores, (\d+) bytes spill loads', info)
            spill = f'frame={mi.group(1)} spillst={mi.group(2)}B spillld={mi.group(3)}B' if mi else 'frame=? spill=?'
            cu.cuLinkDestroy(st); cu.cuModuleUnload(mod)
            tmp = f'/tmp/ptxjit_{os.getpid()}.cubin'; open(tmp, 'wb').write(cubin)
            sass = subprocess.run(['/usr/local/cuda/bin/cuobjdump', '-sass', tmp], capture_output=True, text=True).stdout
            ins = re.findall(r'^\s+/\*[0-9a-f]{4,}\*/\s+(.*?)\s*;', sass, re.M)
            stl = sum(1 for t in ins if re.search(r'\bSTL', t)); ldl = sum(1 for t in ins if re.search(r'\bLDL', t))
            ph = hashlib.md5(ptx).hexdigest()[:8]
            if sassdir:
                os.makedirs(sassdir, exist_ok=True)
                open(f'{sassdir}/{tag}_{i}_{ph}.sass', 'w').write(sass)
                open(f'{sassdir}/{tag}_{i}_{ph}.ptx', 'wb').write(ptx[:-1])
            print(f'/ptx/{tag}/ #{i} {name[:70]} ptx={ph} regs={regs} local={local} sass={len(ins)} stl={stl} ldl={ldl} {spill} '
                  f'variant={"SPILL" if (stl or ldl) else "nospill"} key={ent["key"]}', flush=True)
