#!/bin/bash
# nvrtc_vs_nvcc.sh CU...: compile CubeCL's CUDA source of a join kernel three ways and report registers / spills:
# (1) nvcc -cubin -O3 -Xptxas -v (L41's offline method); (2) NVRTC with CubeCL's options -> PTX -> offline ptxas -v;
# (3) the same NVRTC PTX -> the driver JIT (the runtime path; ptxjit-style attributes + SASS STL/LDL).
export PATH=/usr/local/cuda/bin:$PATH
for cu in "$@"; do
  echo "== $cu"
  echo -n "nvcc -cubin: "; nice -n 19 nvcc -cubin -arch=sm_86 -O3 -Xptxas -v -o /tmp/nv.cubin $cu 2>&1 | grep -o "Used [0-9]* registers\|[0-9]* bytes spill stores" | tr '\n' ' '; echo
  echo -n "nvcc -ptx | ptxas: "; nice -n 19 nvcc -ptx -arch=sm_86 -o /tmp/nv.ptx $cu && nice -n 19 ptxas -arch=sm_86 -v -o /tmp/nv2.cubin /tmp/nv.ptx 2>&1 | grep -o "Used [0-9]* registers\|[0-9]* bytes spill stores" | tr '\n' ' '; echo
  nice -n 19 python3 - $cu <<'PY'
import ctypes, sys, re, subprocess
src = open(sys.argv[1], 'rb').read() + b'\0'
nv = ctypes.CDLL('/usr/local/cuda/lib64/libnvrtc.so')
prog = ctypes.c_void_p()
assert nv.nvrtcCreateProgram(ctypes.byref(prog), src, None, 0, None, None) == 0
opts = [b'--gpu-architecture=sm_86', b'--include-path=/usr/local/cuda/include', b'-lineinfo']
arr = (ctypes.c_char_p * len(opts))(*opts)
r = nv.nvrtcCompileProgram(prog, len(opts), arr)
if r != 0:
    n = ctypes.c_size_t(); nv.nvrtcGetProgramLogSize(prog, ctypes.byref(n)); b = ctypes.create_string_buffer(n.value); nv.nvrtcGetProgramLog(prog, b); print('NVRTC FAIL', b.value.decode()[:2000]); sys.exit()
n = ctypes.c_size_t(); nv.nvrtcGetPTXSize(prog, ctypes.byref(n)); b = ctypes.create_string_buffer(n.value); nv.nvrtcGetPTX(prog, b)
ptx = b.raw.rstrip(b'\0') + b'\0'
open('/tmp/nvrtc.ptx', 'wb').write(ptx[:-1])
out = subprocess.run(['/usr/local/cuda/bin/ptxas', '-arch=sm_86', '-v', '-o', '/tmp/nvrtc.cubin', '/tmp/nvrtc.ptx'], capture_output=True, text=True).stderr
print('NVRTC | ptxas:', ' '.join(re.findall(r'Used \d+ registers|\d+ bytes spill stores', out)))
cu = ctypes.CDLL('libcuda.so.1'); cu.cuInit(0); dev = ctypes.c_int(); cu.cuDeviceGet(ctypes.byref(dev), 0)
ctx = ctypes.c_void_p(); cu.cuDevicePrimaryCtxRetain(ctypes.byref(ctx), dev); cu.cuCtxSetCurrent(ctx)
st = ctypes.c_void_p(); cu.cuLinkCreate_v2(0, None, None, ctypes.byref(st))
assert cu.cuLinkAddData_v2(st, 1, ptx, len(ptx), b'k.ptx', 0, None, None) == 0
cub = ctypes.c_void_p(); sz = ctypes.c_size_t(); assert cu.cuLinkComplete(st, ctypes.byref(cub), ctypes.byref(sz)) == 0
open('/tmp/jit.cubin', 'wb').write(ctypes.string_at(cub, sz.value))
res = subprocess.run(['/usr/local/cuda/bin/cuobjdump', '-res-usage', '/tmp/jit.cubin'], capture_output=True, text=True).stdout
sass = subprocess.run(['/usr/local/cuda/bin/cuobjdump', '-sass', '/tmp/jit.cubin'], capture_output=True, text=True).stdout
print('NVRTC | driver JIT:', ' '.join(re.findall(r'REG:\d+|STACK:\d+|LOCAL:\d+', res)), 'STL', len(re.findall(r'\bSTL', sass)), 'LDL', len(re.findall(r'\bLDL', sass)))
PY
done
