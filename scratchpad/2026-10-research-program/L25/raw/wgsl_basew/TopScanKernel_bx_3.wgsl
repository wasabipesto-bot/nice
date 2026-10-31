
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
var l_mut_22: u32;
let l_1 = local_invocation_id.x * u32(3);
l_mut_2 = u32(0);
let l_3 = l_1 + u32(0);
let l_4 = l_3 < u32(600);
if l_4 {
let l_5 = workgroup_id.x * u32(600);
let l_6 = l_5 + l_3;
let l_7 = &buffer_0_global[l_6];
let l_8 = atomicLoad(l_7);
l_mut_2 = l_mut_2 + l_8;
}
let l_9 = l_1 + u32(1);
let l_10 = l_9 < u32(600);
if l_10 {
let l_11 = workgroup_id.x * u32(600);
let l_12 = l_11 + l_9;
let l_13 = &buffer_0_global[l_12];
let l_14 = atomicLoad(l_13);
l_mut_2 = l_mut_2 + l_14;
}
let l_15 = l_1 + u32(2);
let l_16 = l_15 < u32(600);
if l_16 {
let l_17 = workgroup_id.x * u32(600);
let l_18 = l_17 + l_15;
let l_19 = &buffer_0_global[l_18];
let l_20 = atomicLoad(l_19);
l_mut_2 = l_mut_2 + l_20;
}
shared_memory_0[local_invocation_id.x] = l_mut_2;
workgroupBarrier();
let l_21 = local_invocation_id.x == u32(0);
if l_21 {
l_mut_2 = u32(0);
l_mut_22 = u32(0);
loop {
let l_23 = l_mut_22 < WORKGROUP_SIZE_X;
let l_24 = !l_23;
if l_24 {
break;
}
let l_25 = shared_memory_0[l_mut_22];
shared_memory_0[l_mut_22] = l_mut_2;
l_mut_2 = l_mut_2 + l_25;
l_mut_22 = l_mut_22 + u32(1);
}
}
workgroupBarrier();
let l_26 = shared_memory_0[local_invocation_id.x];
let l_27 = workgroup_id.x * info.scalars_u32[0];
let l_28 = l_26 + l_27;
l_mut_22 = l_28;
let l_29 = l_1 + u32(0);
let l_30 = l_29 < u32(600);
if l_30 {
let l_31 = workgroup_id.x * u32(600);
let l_32 = l_31 + l_29;
let l_33 = &buffer_0_global[l_32];
let l_34 = atomicLoad(l_33);
let l_35 = workgroup_id.x * u32(600);
let l_36 = l_35 + l_29;
let l_37 = &buffer_1_global[l_36];
atomicStore(l_37,l_mut_22);
let l_38 = workgroup_id.x * u32(600);
let l_39 = l_38 + l_29;
let l_40 = u32(4) * l_39;
buffer_2_global[l_40] = workgroup_id.x;
let l_41 = u32(4) * l_39;
let l_42 = l_41 + u32(1);
buffer_2_global[l_42] = l_29;
let l_43 = u32(4) * l_39;
let l_44 = l_43 + u32(2);
buffer_2_global[l_44] = l_mut_22;
let l_45 = u32(4) * l_39;
let l_46 = l_45 + u32(3);
let l_47 = l_mut_22 + l_34;
buffer_2_global[l_46] = l_47;
l_mut_22 = l_mut_22 + l_34;
}
let l_48 = l_1 + u32(1);
let l_49 = l_48 < u32(600);
if l_49 {
let l_50 = workgroup_id.x * u32(600);
let l_51 = l_50 + l_48;
let l_52 = &buffer_0_global[l_51];
let l_53 = atomicLoad(l_52);
let l_54 = workgroup_id.x * u32(600);
let l_55 = l_54 + l_48;
let l_56 = &buffer_1_global[l_55];
atomicStore(l_56,l_mut_22);
let l_57 = workgroup_id.x * u32(600);
let l_58 = l_57 + l_48;
let l_59 = u32(4) * l_58;
buffer_2_global[l_59] = workgroup_id.x;
let l_60 = u32(4) * l_58;
let l_61 = l_60 + u32(1);
buffer_2_global[l_61] = l_48;
let l_62 = u32(4) * l_58;
let l_63 = l_62 + u32(2);
buffer_2_global[l_63] = l_mut_22;
let l_64 = u32(4) * l_58;
let l_65 = l_64 + u32(3);
let l_66 = l_mut_22 + l_53;
buffer_2_global[l_65] = l_66;
l_mut_22 = l_mut_22 + l_53;
}
let l_67 = l_1 + u32(2);
let l_68 = l_67 < u32(600);
if l_68 {
let l_69 = workgroup_id.x * u32(600);
let l_70 = l_69 + l_67;
let l_71 = &buffer_0_global[l_70];
let l_72 = atomicLoad(l_71);
let l_73 = workgroup_id.x * u32(600);
let l_74 = l_73 + l_67;
let l_75 = &buffer_1_global[l_74];
atomicStore(l_75,l_mut_22);
let l_76 = workgroup_id.x * u32(600);
let l_77 = l_76 + l_67;
let l_78 = u32(4) * l_77;
buffer_2_global[l_78] = workgroup_id.x;
let l_79 = u32(4) * l_77;
let l_80 = l_79 + u32(1);
buffer_2_global[l_80] = l_67;
let l_81 = u32(4) * l_77;
let l_82 = l_81 + u32(2);
buffer_2_global[l_82] = l_mut_22;
let l_83 = u32(4) * l_77;
let l_84 = l_83 + u32(3);
let l_85 = l_mut_22 + l_72;
buffer_2_global[l_84] = l_85;
l_mut_22 = l_mut_22 + l_72;
}
workgroupBarrier();
let l_86 = local_invocation_id.x == u32(0);
if l_86 {
let l_87 = &buffer_3_global[u32(1)];
let l_88 = atomicAdd(l_87, u32(1));}
}
```
