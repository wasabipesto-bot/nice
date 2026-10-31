
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
var l_mut_16: u32;
let l_1 = local_invocation_id.x * u32(2);
l_mut_2 = u32(0);
let l_3 = l_1 + u32(0);
let l_4 = l_3 < u32(380);
if l_4 {
let l_5 = workgroup_id.x * u32(380);
let l_6 = l_5 + l_3;
let l_7 = &buffer_0_global[l_6];
let l_8 = atomicLoad(l_7);
l_mut_2 = l_mut_2 + l_8;
}
let l_9 = l_1 + u32(1);
let l_10 = l_9 < u32(380);
if l_10 {
let l_11 = workgroup_id.x * u32(380);
let l_12 = l_11 + l_9;
let l_13 = &buffer_0_global[l_12];
let l_14 = atomicLoad(l_13);
l_mut_2 = l_mut_2 + l_14;
}
shared_memory_0[local_invocation_id.x] = l_mut_2;
workgroupBarrier();
let l_15 = local_invocation_id.x == u32(0);
if l_15 {
l_mut_2 = u32(0);
l_mut_16 = u32(0);
loop {
let l_17 = l_mut_16 < WORKGROUP_SIZE_X;
let l_18 = !l_17;
if l_18 {
break;
}
let l_19 = shared_memory_0[l_mut_16];
shared_memory_0[l_mut_16] = l_mut_2;
l_mut_2 = l_mut_2 + l_19;
l_mut_16 = l_mut_16 + u32(1);
}
}
workgroupBarrier();
let l_20 = shared_memory_0[local_invocation_id.x];
let l_21 = workgroup_id.x * info.scalars_u32[0];
let l_22 = l_20 + l_21;
l_mut_16 = l_22;
let l_23 = l_1 + u32(0);
let l_24 = l_23 < u32(380);
if l_24 {
let l_25 = workgroup_id.x * u32(380);
let l_26 = l_25 + l_23;
let l_27 = &buffer_0_global[l_26];
let l_28 = atomicLoad(l_27);
let l_29 = workgroup_id.x * u32(380);
let l_30 = l_29 + l_23;
let l_31 = &buffer_1_global[l_30];
atomicStore(l_31,l_mut_16);
let l_32 = workgroup_id.x * u32(380);
let l_33 = l_32 + l_23;
let l_34 = u32(4) * l_33;
buffer_2_global[l_34] = workgroup_id.x;
let l_35 = u32(4) * l_33;
let l_36 = l_35 + u32(1);
buffer_2_global[l_36] = l_23;
let l_37 = u32(4) * l_33;
let l_38 = l_37 + u32(2);
buffer_2_global[l_38] = l_mut_16;
let l_39 = u32(4) * l_33;
let l_40 = l_39 + u32(3);
let l_41 = l_mut_16 + l_28;
buffer_2_global[l_40] = l_41;
l_mut_16 = l_mut_16 + l_28;
}
let l_42 = l_1 + u32(1);
let l_43 = l_42 < u32(380);
if l_43 {
let l_44 = workgroup_id.x * u32(380);
let l_45 = l_44 + l_42;
let l_46 = &buffer_0_global[l_45];
let l_47 = atomicLoad(l_46);
let l_48 = workgroup_id.x * u32(380);
let l_49 = l_48 + l_42;
let l_50 = &buffer_1_global[l_49];
atomicStore(l_50,l_mut_16);
let l_51 = workgroup_id.x * u32(380);
let l_52 = l_51 + l_42;
let l_53 = u32(4) * l_52;
buffer_2_global[l_53] = workgroup_id.x;
let l_54 = u32(4) * l_52;
let l_55 = l_54 + u32(1);
buffer_2_global[l_55] = l_42;
let l_56 = u32(4) * l_52;
let l_57 = l_56 + u32(2);
buffer_2_global[l_57] = l_mut_16;
let l_58 = u32(4) * l_52;
let l_59 = l_58 + u32(3);
let l_60 = l_mut_16 + l_47;
buffer_2_global[l_59] = l_60;
l_mut_16 = l_mut_16 + l_47;
}
workgroupBarrier();
let l_61 = local_invocation_id.x == u32(0);
if l_61 {
let l_62 = &buffer_3_global[u32(1)];
let l_63 = atomicAdd(l_62, u32(1));}
}
```
