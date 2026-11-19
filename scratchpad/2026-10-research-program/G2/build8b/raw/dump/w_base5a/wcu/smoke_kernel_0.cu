// ---- body
extern "C" __global__ void __launch_bounds__(1)smoke_kernel (
    uint32* buffer_0, const __grid_constant__ info_st info
) {
uint3 absoluteIdx = make_uint3(
    blockIdx.x * blockDim.x + threadIdx.x,
    blockIdx.y * blockDim.y + threadIdx.y,
    blockIdx.z * blockDim.z + threadIdx.z
);
const bool V0 = absoluteIdx.x == uint32(0);
if (V0) {
buffer_0[uint32(0)] = uint32(42);
}

}
```
[END_KERNEL_COMPILATION]

[START_KERNEL_COMPILATION]
name: nice_common::midout::gpu_wide::wp::wtops5_kernel::Wtops5Kernel<
    cubecl_cuda::runtime::CudaRuntime,
>
id: KernelId {
    type: nice_common::midout::gpu_wide::wp::wtops5_kernel::Wtops5Kernel<cubecl_cuda::runtime::CudaRuntime>,
    address_type: U32,
    cube_dim: CubeDim {
        x: 256,
        y: 1,
        z: 1,
    },
    mode: Unchecked,
    info: Wtops5KernelInfo {
        w: 32,
        b: 65,
        f0: 4,
        k: 10,
        l: 13,
        s2: 26,
        s3: 39,
        list: ArrayCompilationArg {
            inplace: None,
        },
        l5n: ArrayCompilationArg {
            inplace: None,
        },
        pipd: ArrayCompilationArg {
            inplace: None,
        },
        ends: ArrayCompilationArg {
            inplace: None,
        },
        ntest: (),
        nlead: (),
        hlo: (),
        plo_lo: (),
        plo_hi: (),
        phi_lo: (),
        phi_hi: (),
    },
}
source:
```cpp
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

struct __align__(16) uint32_4 {
    uint32 i_0;
    uint32 i_1;
    uint32 i_2;
    uint32 i_3;
};
struct info_st {
    uint32 scalars_uint32[8];uint32 static_meta[8];
};

