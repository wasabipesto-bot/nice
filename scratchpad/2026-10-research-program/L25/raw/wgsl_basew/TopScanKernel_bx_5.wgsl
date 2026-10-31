
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
var l_mut_28: u32;
let l_1 = local_invocation_id.x * u32(4);
l_mut_2 = u32(0);
let l_3 = l_1 + u32(0);
let l_4 = l_3 < u32(870);
if l_4 {
let l_5 = workgroup_id.x * u32(870);
let l_6 = l_5 + l_3;
let l_7 = &buffer_0_global[l_6];
let l_8 = atomicLoad(l_7);
l_mut_2 = l_mut_2 + l_8;
}
let l_9 = l_1 + u32(1);
let l_10 = l_9 < u32(870);
if l_10 {
let l_11 = workgroup_id.x * u32(870);
let l_12 = l_11 + l_9;
let l_13 = &buffer_0_global[l_12];
let l_14 = atomicLoad(l_13);
l_mut_2 = l_mut_2 + l_14;
}
let l_15 = l_1 + u32(2);
let l_16 = l_15 < u32(870);
if l_16 {
let l_17 = workgroup_id.x * u32(870);
let l_18 = l_17 + l_15;
let l_19 = &buffer_0_global[l_18];
let l_20 = atomicLoad(l_19);
l_mut_2 = l_mut_2 + l_20;
}
let l_21 = l_1 + u32(3);
let l_22 = l_21 < u32(870);
if l_22 {
let l_23 = workgroup_id.x * u32(870);
let l_24 = l_23 + l_21;
let l_25 = &buffer_0_global[l_24];
let l_26 = atomicLoad(l_25);
l_mut_2 = l_mut_2 + l_26;
}
shared_memory_0[local_invocation_id.x] = l_mut_2;
workgroupBarrier();
let l_27 = local_invocation_id.x == u32(0);
if l_27 {
l_mut_2 = u32(0);
l_mut_28 = u32(0);
loop {
let l_29 = l_mut_28 < WORKGROUP_SIZE_X;
let l_30 = !l_29;
if l_30 {
break;
}
let l_31 = shared_memory_0[l_mut_28];
shared_memory_0[l_mut_28] = l_mut_2;
l_mut_2 = l_mut_2 + l_31;
l_mut_28 = l_mut_28 + u32(1);
}
}
workgroupBarrier();
let l_32 = shared_memory_0[local_invocation_id.x];
let l_33 = workgroup_id.x * info.scalars_u32[0];
let l_34 = l_32 + l_33;
l_mut_28 = l_34;
let l_35 = l_1 + u32(0);
let l_36 = l_35 < u32(870);
if l_36 {
let l_37 = workgroup_id.x * u32(870);
let l_38 = l_37 + l_35;
let l_39 = &buffer_0_global[l_38];
let l_40 = atomicLoad(l_39);
let l_41 = workgroup_id.x * u32(870);
let l_42 = l_41 + l_35;
let l_43 = &buffer_1_global[l_42];
atomicStore(l_43,l_mut_28);
let l_44 = workgroup_id.x * u32(870);
let l_45 = l_44 + l_35;
let l_46 = u32(4) * l_45;
buffer_2_global[l_46] = workgroup_id.x;
let l_47 = u32(4) * l_45;
let l_48 = l_47 + u32(1);
buffer_2_global[l_48] = l_35;
let l_49 = u32(4) * l_45;
let l_50 = l_49 + u32(2);
buffer_2_global[l_50] = l_mut_28;
let l_51 = u32(4) * l_45;
let l_52 = l_51 + u32(3);
let l_53 = l_mut_28 + l_40;
buffer_2_global[l_52] = l_53;
l_mut_28 = l_mut_28 + l_40;
}
let l_54 = l_1 + u32(1);
let l_55 = l_54 < u32(870);
if l_55 {
let l_56 = workgroup_id.x * u32(870);
let l_57 = l_56 + l_54;
let l_58 = &buffer_0_global[l_57];
let l_59 = atomicLoad(l_58);
let l_60 = workgroup_id.x * u32(870);
let l_61 = l_60 + l_54;
let l_62 = &buffer_1_global[l_61];
atomicStore(l_62,l_mut_28);
let l_63 = workgroup_id.x * u32(870);
let l_64 = l_63 + l_54;
let l_65 = u32(4) * l_64;
buffer_2_global[l_65] = workgroup_id.x;
let l_66 = u32(4) * l_64;
let l_67 = l_66 + u32(1);
buffer_2_global[l_67] = l_54;
let l_68 = u32(4) * l_64;
let l_69 = l_68 + u32(2);
buffer_2_global[l_69] = l_mut_28;
let l_70 = u32(4) * l_64;
let l_71 = l_70 + u32(3);
let l_72 = l_mut_28 + l_59;
buffer_2_global[l_71] = l_72;
l_mut_28 = l_mut_28 + l_59;
}
let l_73 = l_1 + u32(2);
let l_74 = l_73 < u32(870);
if l_74 {
let l_75 = workgroup_id.x * u32(870);
let l_76 = l_75 + l_73;
let l_77 = &buffer_0_global[l_76];
let l_78 = atomicLoad(l_77);
let l_79 = workgroup_id.x * u32(870);
let l_80 = l_79 + l_73;
let l_81 = &buffer_1_global[l_80];
atomicStore(l_81,l_mut_28);
let l_82 = workgroup_id.x * u32(870);
let l_83 = l_82 + l_73;
let l_84 = u32(4) * l_83;
buffer_2_global[l_84] = workgroup_id.x;
let l_85 = u32(4) * l_83;
let l_86 = l_85 + u32(1);
buffer_2_global[l_86] = l_73;
let l_87 = u32(4) * l_83;
let l_88 = l_87 + u32(2);
buffer_2_global[l_88] = l_mut_28;
let l_89 = u32(4) * l_83;
let l_90 = l_89 + u32(3);
let l_91 = l_mut_28 + l_78;
buffer_2_global[l_90] = l_91;
l_mut_28 = l_mut_28 + l_78;
}
let l_92 = l_1 + u32(3);
let l_93 = l_92 < u32(870);
if l_93 {
let l_94 = workgroup_id.x * u32(870);
let l_95 = l_94 + l_92;
let l_96 = &buffer_0_global[l_95];
let l_97 = atomicLoad(l_96);
let l_98 = workgroup_id.x * u32(870);
let l_99 = l_98 + l_92;
let l_100 = &buffer_1_global[l_99];
atomicStore(l_100,l_mut_28);
let l_101 = workgroup_id.x * u32(870);
let l_102 = l_101 + l_92;
let l_103 = u32(4) * l_102;
buffer_2_global[l_103] = workgroup_id.x;
let l_104 = u32(4) * l_102;
let l_105 = l_104 + u32(1);
buffer_2_global[l_105] = l_92;
let l_106 = u32(4) * l_102;
let l_107 = l_106 + u32(2);
buffer_2_global[l_107] = l_mut_28;
let l_108 = u32(4) * l_102;
let l_109 = l_108 + u32(3);
let l_110 = l_mut_28 + l_97;
buffer_2_global[l_109] = l_110;
l_mut_28 = l_mut_28 + l_97;
}
workgroupBarrier();
let l_111 = local_invocation_id.x == u32(0);
if l_111 {
let l_112 = &buffer_3_global[u32(1)];
let l_113 = atomicAdd(l_112, u32(1));}
}
```
