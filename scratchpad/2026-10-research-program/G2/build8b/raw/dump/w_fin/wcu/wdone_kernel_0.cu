// ---- body
extern "C" __global__ void __launch_bounds__(32)wdone_kernel (
    uint32* buffer_0, uint32* buffer_1, const __grid_constant__ info_st info
) {
uint3 absoluteIdx = make_uint3(
    blockIdx.x * blockDim.x + threadIdx.x,
    blockIdx.y * blockDim.y + threadIdx.y,
    blockIdx.z * blockDim.z + threadIdx.z
);
const bool V0 = absoluteIdx.x == uint32(0);
if (V0) {
uint32* V1 = &buffer_0[uint32(14)];
const uint32 V2 = atomicAdd(V1, uint32(1));
uint32* V3 = &buffer_1[uint32(367)];
const uint32 V4 = atomicAdd(V3, uint32(1));
}

}
```
[END_KERNEL_COMPILATION]


