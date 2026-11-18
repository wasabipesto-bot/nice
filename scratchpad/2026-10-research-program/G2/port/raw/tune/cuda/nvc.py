"""nvc.py SRC.cu OUTBASE [name-expression...]: NVRTC (sm_86, -lineinfo, as CubeCL's cubecl-cuda) -> OUTBASE.ptx and
OUTBASE.cubin; then ptxas -v resource usage (from the PTX) and nvdisasm SASS with line info. G2 tuning 2026-11-18."""
import ctypes, sys, os, subprocess, glob
V = os.path.dirname(os.path.abspath(__file__)) + '/venv/lib/python3.13/site-packages/nvidia'
nv = ctypes.CDLL(V + '/cuda_nvrtc/lib/libnvrtc.so.12')
src, out = sys.argv[1], sys.argv[2]
names = sys.argv[3:]
code = open(src).read().replace('#include <cuda_runtime.h>', '')
prog = ctypes.c_void_p()
assert nv.nvrtcCreateProgram(ctypes.byref(prog), code.encode(), b'k.cu', 0, None, None) == 0
for n in names:
    assert nv.nvrtcAddNameExpression(prog, n.encode()) == 0
opts = [b'--gpu-architecture=sm_86', b'-lineinfo', b'-std=c++17']
arr = (ctypes.c_char_p * len(opts))(*opts)
r = nv.nvrtcCompileProgram(prog, len(opts), arr)
ls = ctypes.c_size_t(); nv.nvrtcGetProgramLogSize(prog, ctypes.byref(ls)); log = ctypes.create_string_buffer(ls.value); nv.nvrtcGetProgramLog(prog, log)
if log.value.strip(): print(log.value.decode()[:3000])
assert r == 0, f'nvrtc {r}'
for get, size, ext in ((nv.nvrtcGetPTX, nv.nvrtcGetPTXSize, '.ptx'), (nv.nvrtcGetCUBIN, nv.nvrtcGetCUBINSize, '.cubin')):
    s = ctypes.c_size_t(); size(prog, ctypes.byref(s)); b = ctypes.create_string_buffer(s.value); get(prog, b)
    open(out + ext, 'wb').write(b.raw[:s.value] if ext == '.cubin' else b.value)
for n in names:
    p = ctypes.c_char_p(); nv.nvrtcGetLoweredName(prog, n.encode(), ctypes.byref(p)); print('lowered', n, p.value.decode())
ptxas = V + '/cuda_nvcc/bin/ptxas'
print(subprocess.run([ptxas, '-arch=sm_86', '-v', '-O3', out + '.ptx', '-o', '/dev/null'], capture_output=True, text=True).stderr)
nd = glob.glob(V + '/cu13/bin/nvdisasm')[0]
r = subprocess.run([nd, '-c', '-g', out + '.cubin'], capture_output=True, text=True)
open(out + '.sass', 'w').write(r.stdout); print(r.stderr[:500], 'sass lines', r.stdout.count('\n'))
