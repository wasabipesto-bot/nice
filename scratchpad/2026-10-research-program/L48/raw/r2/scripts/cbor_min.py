"""L45: minimal CBOR reader for CubeCL's PTX cache chunks (ciborium `Entry { key: u128, value: PtxCacheEntry }`).
entries(data) -> list of (start, end, obj) in file order."""
import struct
def _item(d, i):
    b = d[i]; mt, ai = b >> 5, b & 31; i += 1
    if ai < 24: n = ai
    elif ai == 24: n = d[i]; i += 1
    elif ai == 25: n = struct.unpack('>H', d[i:i + 2])[0]; i += 2
    elif ai == 26: n = struct.unpack('>I', d[i:i + 4])[0]; i += 4
    elif ai == 27: n = struct.unpack('>Q', d[i:i + 8])[0]; i += 8
    elif ai == 31: n = None
    else: raise ValueError(f'bad ai {ai} at {i}')
    if mt == 0: return n, i
    if mt == 1: return -1 - n, i
    if mt in (2, 3):
        if n is None:
            parts = []
            while d[i] != 0xFF:
                v, i = _item(d, i); parts.append(v)
            return (b''.join(parts) if mt == 2 else ''.join(parts)), i + 1
        v = bytes(d[i:i + n]); return (v if mt == 2 else v.decode()), i + n
    if mt == 4:
        out = []
        if n is None:
            while d[i] != 0xFF:
                v, i = _item(d, i); out.append(v)
            return out, i + 1
        for _ in range(n):
            v, i = _item(d, i); out.append(v)
        return out, i
    if mt == 5:
        out = {}
        cnt = 0
        while (n is None and d[i] != 0xFF) or (n is not None and cnt < n):
            k, i = _item(d, i); v, i = _item(d, i); out[k] = v; cnt += 1
        if n is None: i += 1
        return out, i
    if mt == 6:
        v, i = _item(d, i)
        if n in (2, 3) and isinstance(v, bytes):
            x = int.from_bytes(v, 'big'); return (x if n == 2 else -1 - x), i
        return ('tag', n, v), i
    if mt == 7:
        if ai == 20: return False, i
        if ai == 21: return True, i
        if ai == 22: return None, i
        return ('simple', n), i
def entries(data):
    out = []; i = 0
    while i < len(data):
        s = i; v, i = _item(data, i); out.append((s, i, v))
    return out
def _head(mt, n):
    if n < 24: return bytes([(mt << 5) | n])
    if n < 256: return bytes([(mt << 5) | 24, n])
    if n < 65536: return bytes([(mt << 5) | 25]) + struct.pack('>H', n)
    if n < 2 ** 32: return bytes([(mt << 5) | 26]) + struct.pack('>I', n)
    return bytes([(mt << 5) | 27]) + struct.pack('>Q', n)
def enc(v):
    """Encode str / non-negative or negative int (< 2^64) / list / dict (insertion order)."""
    if isinstance(v, bool): return bytes([0xF5 if v else 0xF4])
    if isinstance(v, int):
        return _head(0, v) if v >= 0 else _head(1, -1 - v)
    if isinstance(v, str):
        b = v.encode(); return _head(3, len(b)) + b
    if isinstance(v, list): return _head(4, len(v)) + b''.join(enc(x) for x in v)
    if isinstance(v, dict): return _head(5, len(v)) + b''.join(enc(k) + enc(x) for k, x in v.items())
    raise TypeError(type(v))
def key_raw(data, s):
    """Raw bytes of the 'key' item of the Entry map starting at s (map header, then 'key' text, then the item)."""
    i = s
    _, i = _item(data, i - 0) if False else (None, i)
    b = data[i]; ai = b & 31; i += 1 + {24: 1, 25: 2, 26: 4, 27: 8}.get(ai, 0)  # map header
    k, i = _item(data, i); assert k == 'key', k
    j = _item(data, i)[1]
    return data[i:j]
