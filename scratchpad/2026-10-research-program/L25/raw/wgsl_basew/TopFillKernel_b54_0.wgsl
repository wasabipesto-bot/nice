
```wgsl
@group(0)
@binding(0)
var<storage, read_write> buffer_0_global: array<u32>;

@group(0)
@binding(1)
var<storage, read_write> buffer_1_global: array<atomic<u32>>;

@group(0)
@binding(2)
var<storage, read_write> buffer_2_global: array<u32>;

@group(0)
@binding(3)
var<storage, read_write> buffer_3_global: array<atomic<u32>>;

@group(0)
@binding(4)
var<storage, read_write> buffer_4_global: array<u32>;

@group(0)
@binding(5)
var<storage, read_write> buffer_5_global: array<atomic<u32>>;

struct info_st {
   scalars_u32: array<u32, 2>,
   static_meta: array<u32, 12>,
}

@group(0)
@binding(6)
var<storage, read> info: info_st;

const WORKGROUP_SIZE_X = 256u;
const WORKGROUP_SIZE_Y = 1u;
const WORKGROUP_SIZE_Z = 1u;

@compute
@workgroup_size(256, 1, 1)
fn top_fill_kernel(
    @builtin(global_invocation_id) global_id: vec3<u32>,
    @builtin(local_invocation_id) local_invocation_id: vec3<u32>,
    @builtin(workgroup_id) workgroup_id: vec3<u32>,
) {
var l_mut_8: u32;
let l_0 = &buffer_1_global[workgroup_id.y];
let l_1 = atomicLoad(l_0);
let l_2 = global_id.x < l_1;
if l_2 {
let l_3 = workgroup_id.y * info.scalars_u32[0];
let l_4 = l_3 + global_id.x;
let l_5 = buffer_0_global[l_4];
let l_6 = l_5 & u32(255);
let l_7 = l_5 >> u32(8);
l_mut_8 = u32(0);
loop {
let l_9 = l_mut_8 < info.scalars_u32[1];
let l_10 = !l_9;
if l_10 {
break;
}
let l_11 = buffer_2_global[l_mut_8];
let l_12 = l_11 + u32(53);
let l_13 = l_12 - l_6;
let l_14 = l_13 % u32(53);
let l_15 = workgroup_id.y * u32(53);
let l_16 = l_7 * u32(53);
let l_17 = l_15 + l_16;
let l_18 = l_17 + l_14;
let l_19 = &buffer_3_global[l_18];
let l_20 = atomicAdd(l_19, u32(1));buffer_4_global[l_20] = l_4;
l_mut_8 = l_mut_8 + u32(1);
}
}
workgroupBarrier();
let l_21 = local_invocation_id.x == u32(0);
if l_21 {
let l_22 = &buffer_5_global[u32(2)];
let l_23 = atomicAdd(l_22, u32(1));}
}
```
