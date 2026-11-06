#!/usr/bin/env python3
"""L45: the runtime's own JIT (cuModuleLoadDataEx, as CubeCL's cuModuleLoadData but with the info log on) of PTX files:
the driver ptxas's 'Used N registers, X bytes spill stores' line, the function attributes, and the cubin the JIT cached
(CUDA_CACHE_PATH set by the caller), if it can be found.  python3 jitlog.py PTX..."""
import ctypes, re, sys
cu = ctypes.CDLL('libcuda.so.1'); assert cu.cuInit(0) == 0
dev = ctypes.c_int(); cu.cuDeviceGet(ctypes.byref(dev), 0)
ctx = ctypes.c_void_p(); cu.cuDevicePrimaryCtxRetain(ctypes.byref(ctx), dev); cu.cuCtxSetCurrent(ctx)
for p in sys.argv[1:]:
    ptx = open(p, 'rb').read().rstrip(b'\0') + b'\0'
    name = re.search(rb'\.entry\s+(\w+)', ptx).group(1)
    info = ctypes.create_string_buffer(1 << 16); err = ctypes.create_string_buffer(1 << 16)
    # CU_JIT_INFO_LOG_BUFFER 3, _SIZE 4, CU_JIT_ERROR_LOG_BUFFER 5, _SIZE 6, CU_JIT_LOG_VERBOSE 12
    opts = (ctypes.c_int * 5)(3, 4, 5, 6, 12)
    vals = (ctypes.c_void_p * 5)(ctypes.cast(info, ctypes.c_void_p), ctypes.c_void_p(1 << 16),
                                 ctypes.cast(err, ctypes.c_void_p), ctypes.c_void_p(1 << 16), ctypes.c_void_p(1))
    mod = ctypes.c_void_p(); r = cu.cuModuleLoadDataEx(ctypes.byref(mod), ptx, 5, opts, vals)
    f = ctypes.c_void_p(); cu.cuModuleGetFunction(ctypes.byref(f), mod, name)
    a = {}
    for k, i in [('regs', 4), ('local', 3), ('shared', 1), ('maxthreads', 0)]:
        v = ctypes.c_int(); cu.cuFuncGetAttribute(ctypes.byref(v), i, f); a[k] = v.value
    lines = [l for l in info.value.decode(errors='replace').splitlines() if 'Used' in l or 'spill' in l or 'stack' in l]
    print(p, f'rc={r}', a, '|', ' / '.join(l.strip() for l in lines), err.value.decode(errors='replace')[:200])
    cu.cuModuleUnload(mod)
