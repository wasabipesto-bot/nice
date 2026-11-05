
#include <cuda_runtime.h>
typedef unsigned int uint;
typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned int uint32;
typedef unsigned long long int uint64;
typedef signed char int8;
typedef signed short int16;
typedef signed int int32;
typedef signed long long int int64;

struct info_st {
    uint32 scalars_uint32[2];uint32 static_meta[12];
};


extern "C" __global__ void __launch_bounds__(256)top_fill_kernel (
    const uint32* __restrict__ buffer_0, uint32* buffer_1, const uint32* __restrict__ buffer_2, uint32* buffer_3, uint32* buffer_4, uint32* buffer_5, const __grid_constant__ info_st info
) {
uint3 absoluteIdx = make_uint3(
    blockIdx.x * blockDim.x + threadIdx.x,
    blockIdx.y * blockDim.y + threadIdx.y,
    blockIdx.z * blockDim.z + threadIdx.z
);
uint32 l_mut_8;
uint32* l_0 = &buffer_1[blockIdx.y];
const uint32 l_1 = atomicAdd(l_0, uint32(0));
const bool l_2 = absoluteIdx.x < l_1;
if (l_2) {
const uint32 l_3 = blockIdx.y * info.scalars_uint32[0];
const uint32 l_4 = l_3 + absoluteIdx.x;
const uint32 l_5 = buffer_0[l_4];
const uint32 l_6 = l_5 & uint32(255);
const uint32 l_7 = l_5 >> uint32(8);
l_mut_8 = uint32(0);
while (true) {
const bool l_9 = l_mut_8 < info.scalars_uint32[1];
const bool l_10 = !l_9;
if (l_10) {
break;}
const uint32 l_11 = buffer_2[l_mut_8];
const uint32 l_12 = l_11 + uint32(59);
const uint32 l_13 = l_12 - l_6;
const uint32 l_14 = l_13 % uint32(59);
const uint32 l_15 = blockIdx.y * uint32(3540);
const uint32 l_16 = l_7 * uint32(59);
const uint32 l_17 = l_15 + l_16;
const uint32 l_18 = l_17 + l_14;
uint32* l_19 = &buffer_3[l_18];
const uint32 l_20 = atomicAdd(l_19, uint32(1));
buffer_4[l_20] = l_4;
l_mut_8 = l_mut_8 + uint32(1);
}
}
__syncthreads();

const bool l_21 = threadIdx.x == uint32(0);
if (l_21) {
uint32* l_22 = &buffer_5[uint32(2)];
const uint32 l_23 = atomicAdd(l_22, uint32(1));
}

}
