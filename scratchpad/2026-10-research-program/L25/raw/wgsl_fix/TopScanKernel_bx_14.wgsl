
```wgsl
@group(0)
@binding(0)
var<storage, read_write> buffer_0_global: array<atomic<u32>>;

@group(0)
@binding(1)
var<storage, read_write> buffer_1_global: array<atomic<u32>>;

@group(0)
@binding(2)
var<storage, read_write> buffer_2_global: array<u32>;

@group(0)
@binding(3)
var<storage, read_write> buffer_3_global: array<atomic<u32>>;

struct info_st {
   scalars_u32: array<u32, 2>,
   static_meta: array<u32, 8>,
}

@group(0)
@binding(4)
var<storage, read> info: info_st;

var<workgroup> shared_memory_0: array<u32, 256>;

const WORKGROUP_SIZE_X = 256u;
const WORKGROUP_SIZE_Y = 1u;
const WORKGROUP_SIZE_Z = 1u;

@compute
@workgroup_size(256, 1, 1)
fn top_scan_kernel(
    @builtin(local_invocation_id) local_invocation_id: vec3<u32>,
    @builtin(workgroup_id) workgroup_id: vec3<u32>,
) {
var l_mut_2: u32;
var l_mut_10: u32;
let l_1 = local_invocation_id.x * u32(1);
l_mut_2 = u32(0);
let l_3 = l_1 + u32(0);
let l_4 = l_3 < u32(63);
if l_4 {
let l_5 = workgroup_id.x * u32(63);
let l_6 = l_5 + l_3;
let l_7 = &buffer_0_global[l_6];
let l_8 = atomicLoad(l_7);
l_mut_2 = l_mut_2 + l_8;
}
shared_memory_0[local_invocation_id.x] = l_mut_2;
workgroupBarrier();
let l_9 = local_invocation_id.x == u32(0);
if l_9 {
l_mut_2 = u32(0);
l_mut_10 = u32(0);
loop {
let l_11 = l_mut_10 < WORKGROUP_SIZE_X;
let l_12 = !l_11;
if l_12 {
break;
}
let l_13 = shared_memory_0[l_mut_10];
shared_memory_0[l_mut_10] = l_mut_2;
l_mut_2 = l_mut_2 + l_13;
l_mut_10 = l_mut_10 + u32(1);
}
}
workgroupBarrier();
let l_14 = shared_memory_0[local_invocation_id.x];
let l_15 = workgroup_id.x * info.scalars_u32[0];
let l_16 = l_14 + l_15;
l_mut_10 = l_16;
let l_17 = l_1 + u32(0);
let l_18 = l_17 < u32(63);
if l_18 {
let l_19 = workgroup_id.x * u32(63);
let l_20 = l_19 + l_17;
let l_21 = &buffer_0_global[l_20];
let l_22 = atomicLoad(l_21);
let l_23 = workgroup_id.x * u32(63);
let l_24 = l_23 + l_17;
let l_25 = &buffer_1_global[l_24];
atomicStore(l_25,l_mut_10);
let l_26 = workgroup_id.x * u32(63);
let l_27 = l_26 + l_17;
let l_28 = u32(4) * l_27;
buffer_2_global[l_28] = workgroup_id.x;
let l_29 = u32(4) * l_27;
let l_30 = l_29 + u32(1);
buffer_2_global[l_30] = l_17;
let l_31 = u32(4) * l_27;
let l_32 = l_31 + u32(2);
buffer_2_global[l_32] = l_mut_10;
let l_33 = u32(4) * l_27;
let l_34 = l_33 + u32(3);
let l_35 = l_mut_10 + l_22;
buffer_2_global[l_34] = l_35;
l_mut_10 = l_mut_10 + l_22;
}
workgroupBarrier();
let l_36 = local_invocation_id.x == u32(0);
if l_36 {
let l_37 = &buffer_3_global[u32(1)];
let l_38 = atomicAdd(l_37, u32(1));}
}
```
