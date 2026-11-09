#!/usr/bin/env python3
"""nvrtc.py FILE.cu...: compile with NVRTC exactly as CubeCL 0.10 does (--gpu-architecture=sm_86,
--include-path=$CUDA/include, -lineinfo; libnvrtc of the toolkit) -> FILE.ptx (NUL-free)."""
import ctypes, sys, os
lib = None
for n in ('libnvrtc.so', 'libnvrtc.so.12', '/usr/local/cuda/lib64/libnvrtc.so'):
    try: lib = ctypes.CDLL(n); break
    except OSError: pass
assert lib, 'no libnvrtc'
inc = os.environ.get('CUDA_PATH', '/usr/local/cuda') + '/include'
for f in sys.argv[1:]:
    src = open(f, 'rb').read() + b'\0'
    prog = ctypes.c_void_p()
    assert lib.nvrtcCreateProgram(ctypes.byref(prog), src, None, 0, None, None) == 0
    opts = [b'--gpu-architecture=sm_86', b'--include-path=' + inc.encode(), b'-lineinfo'] + [o.encode() for o in os.environ.get('NVRTC_EXTRA', '').split()]
    arr = (ctypes.c_char_p * len(opts))(*opts)
    r = lib.nvrtcCompileProgram(prog, len(opts), arr)
    n = ctypes.c_size_t(); lib.nvrtcGetProgramLogSize(prog, ctypes.byref(n))
    log = ctypes.create_string_buffer(n.value); lib.nvrtcGetProgramLog(prog, log)
    errs = [l for l in log.value.decode(errors='replace').splitlines() if 'error' in l]
    if r != 0: print(f, 'NVRTC FAILED', r, '\n'.join(errs[:20])); continue
    lib.nvrtcGetPTXSize(prog, ctypes.byref(n)); ptx = ctypes.create_string_buffer(n.value); lib.nvrtcGetPTX(prog, ptx)
    open(f[:-3] + '.ptx', 'wb').write(ptx.value)
    v1 = ctypes.c_int(); v2 = ctypes.c_int(); lib.nvrtcVersion(ctypes.byref(v1), ctypes.byref(v2))
    print(f, f'nvrtc {v1.value}.{v2.value} ok')
