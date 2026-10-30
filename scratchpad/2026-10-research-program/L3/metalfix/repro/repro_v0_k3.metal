// language: metal3.2
#include <metal_stdlib>
#include <simd/simd.h>

using metal::uint;

struct _mslBufferSizes {
    uint size0;
    uint size1;
};

typedef uint type_1[1];
struct type_2 {
    uint inner[2];
};
struct type_3 {
    uint inner[4];
};
struct info_st {
    type_2 scalars_u32_;
    type_3 static_meta;
};
constant uint WORKGROUP_SIZE_X = 64u;
constant uint WORKGROUP_SIZE_Y = 1u;
constant uint WORKGROUP_SIZE_Z = 1u;
uint naga_div(uint lhs, uint rhs) {
    return lhs / metal::select(rhs, 1u, rhs == 0u);
}


struct hi_div_repro_kernelInput {
};
kernel void hi_div_repro_kernel(
  metal::uint3 global_id [[thread_position_in_grid]]
, device type_1 const& buffer_0_global [[user(fake0)]]
, device type_1& buffer_1_global [[user(fake0)]]
, device info_st const& info [[user(fake0)]]
, constant _mslBufferSizes& _buffer_sizes [[user(fake0)]]
) {
    uint _e5 = info.scalars_u32_.inner[0];
    bool l_0_ = global_id.x < _e5;
    if (l_0_) {
        uint l_1_ = 2u * global_id.x;
        uint l_2_ = buffer_0_global[l_1_];
        uint l_3_ = 2u * global_id.x;
        uint l_4_ = l_3_ + 1u;
        uint l_5_ = buffer_0_global[l_4_];
        ulong l_6_ = static_cast<ulong>(l_2_);
        ulong l_7_ = static_cast<ulong>(l_5_);
        ulong l_8_ = l_6_ * l_7_;
        ulong l_9_ = l_8_ >> static_cast<uint>(as_type<ulong>(32uL));
        uint l_10_ = static_cast<uint>(as_type<ulong>(l_9_));
        uint l_11_ = naga_div(l_10_, 3u);
        buffer_1_global[global_id.x] = l_11_;
        return;
    } else {
        return;
    }
}
