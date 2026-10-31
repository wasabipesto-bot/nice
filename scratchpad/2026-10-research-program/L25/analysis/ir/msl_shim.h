// Compile naga's MSL as C++ (host clang -O2) to see which divisions reach the
// backend with a half-width-shift dividend after generic LLVM optimisation.
// Only integer semantics matter; device/threadgroup/simd ops are opaque.
#include <cstdint>
#include <cstring>
#define kernel extern "C"
#define device
#define threadgroup
#define thread
#define constant const
typedef unsigned long ulong;
namespace metal {
typedef unsigned int uint;
struct bool3 { bool x, y, z; };
struct uint3 {
  uint x, y, z;
  uint3() = default;
  explicit uint3(uint v) : x(v), y(v), z(v) {}
  uint3(uint a, uint b, uint c) : x(a), y(b), z(c) {}
};
inline bool3 operator==(uint3 a, uint3 b) { return {a.x == b.x, a.y == b.y, a.z == b.z}; }
struct bool2 { bool x, y; };
inline bool all(bool3 v) { return v.x && v.y && v.z; }
inline bool all(bool2 v) { return v.x && v.y; }
struct atomic_uint { uint v; };
enum memory_order { memory_order_relaxed };
enum class mem_flags { mem_none, mem_threadgroup, mem_device };
extern "C" uint opaque_fetch_add(atomic_uint *, uint);
extern "C" uint opaque_load(const atomic_uint *);
extern "C" void opaque_store(atomic_uint *, uint);
inline uint atomic_fetch_add_explicit(atomic_uint *p, uint v, memory_order) { return opaque_fetch_add(p, v); }
inline uint atomic_load_explicit(const atomic_uint *p, memory_order) { return opaque_load(p); }
inline void atomic_store_explicit(atomic_uint *p, uint v, memory_order) { opaque_store(p, v); }
extern "C" void threadgroup_barrier(mem_flags);
extern "C" bool simd_any(bool);
extern "C" bool simd_all(bool);
extern "C" uint simd_sum(uint);
extern "C" uint simd_prefix_exclusive_sum(uint);
template <class T> inline T select(T a, T b, bool c) { return c ? b : a; }
inline uint ctz(uint x) { return x ? __builtin_ctz(x) : 32u; }
inline uint popcount(uint x) { return __builtin_popcount(x); }
inline uint clz(uint x) { return x ? __builtin_clz(x) : 32u; }
}  // namespace metal
struct uint2 {
  metal::uint x, y;
  uint2() = default;
  explicit uint2(metal::uint v) : x(v), y(v) {}
  uint2(metal::uint a, metal::uint b) : x(a), y(b) {}
  uint2 &operator-=(uint2 o) { x -= o.x; y -= o.y; return *this; }
};
inline metal::bool2 operator==(uint2 a, uint2 b) { return {a.x == b.x, a.y == b.y}; }
template <class T, class U> inline T as_type(U u) { static_assert(sizeof(T) == sizeof(U)); T t; std::memcpy(&t, &u, sizeof t); return t; }
