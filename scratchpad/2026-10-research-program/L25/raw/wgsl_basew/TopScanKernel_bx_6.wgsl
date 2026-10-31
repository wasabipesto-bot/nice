
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
var l_mut_34: u32;
let l_1 = local_invocation_id.x * u32(5);
l_mut_2 = u32(0);
let l_3 = l_1 + u32(0);
let l_4 = l_3 < u32(1122);
if l_4 {
let l_5 = workgroup_id.x * u32(1122);
let l_6 = l_5 + l_3;
let l_7 = &buffer_0_global[l_6];
let l_8 = atomicLoad(l_7);
l_mut_2 = l_mut_2 + l_8;
}
let l_9 = l_1 + u32(1);
let l_10 = l_9 < u32(1122);
if l_10 {
let l_11 = workgroup_id.x * u32(1122);
let l_12 = l_11 + l_9;
let l_13 = &buffer_0_global[l_12];
let l_14 = atomicLoad(l_13);
l_mut_2 = l_mut_2 + l_14;
}
let l_15 = l_1 + u32(2);
let l_16 = l_15 < u32(1122);
if l_16 {
let l_17 = workgroup_id.x * u32(1122);
let l_18 = l_17 + l_15;
let l_19 = &buffer_0_global[l_18];
let l_20 = atomicLoad(l_19);
l_mut_2 = l_mut_2 + l_20;
}
let l_21 = l_1 + u32(3);
let l_22 = l_21 < u32(1122);
if l_22 {
let l_23 = workgroup_id.x * u32(1122);
let l_24 = l_23 + l_21;
let l_25 = &buffer_0_global[l_24];
let l_26 = atomicLoad(l_25);
l_mut_2 = l_mut_2 + l_26;
}
let l_27 = l_1 + u32(4);
let l_28 = l_27 < u32(1122);
if l_28 {
let l_29 = workgroup_id.x * u32(1122);
let l_30 = l_29 + l_27;
let l_31 = &buffer_0_global[l_30];
let l_32 = atomicLoad(l_31);
l_mut_2 = l_mut_2 + l_32;
}
shared_memory_0[local_invocation_id.x] = l_mut_2;
workgroupBarrier();
let l_33 = local_invocation_id.x == u32(0);
if l_33 {
l_mut_2 = u32(0);
l_mut_34 = u32(0);
loop {
let l_35 = l_mut_34 < WORKGROUP_SIZE_X;
let l_36 = !l_35;
if l_36 {
break;
}
let l_37 = shared_memory_0[l_mut_34];
shared_memory_0[l_mut_34] = l_mut_2;
l_mut_2 = l_mut_2 + l_37;
l_mut_34 = l_mut_34 + u32(1);
}
}
workgroupBarrier();
let l_38 = shared_memory_0[local_invocation_id.x];
let l_39 = workgroup_id.x * info.scalars_u32[0];
let l_40 = l_38 + l_39;
l_mut_34 = l_40;
let l_41 = l_1 + u32(0);
let l_42 = l_41 < u32(1122);
if l_42 {
let l_43 = workgroup_id.x * u32(1122);
let l_44 = l_43 + l_41;
let l_45 = &buffer_0_global[l_44];
let l_46 = atomicLoad(l_45);
let l_47 = workgroup_id.x * u32(1122);
let l_48 = l_47 + l_41;
let l_49 = &buffer_1_global[l_48];
atomicStore(l_49,l_mut_34);
let l_50 = workgroup_id.x * u32(1122);
let l_51 = l_50 + l_41;
let l_52 = u32(4) * l_51;
buffer_2_global[l_52] = workgroup_id.x;
let l_53 = u32(4) * l_51;
let l_54 = l_53 + u32(1);
buffer_2_global[l_54] = l_41;
let l_55 = u32(4) * l_51;
let l_56 = l_55 + u32(2);
buffer_2_global[l_56] = l_mut_34;
let l_57 = u32(4) * l_51;
let l_58 = l_57 + u32(3);
let l_59 = l_mut_34 + l_46;
buffer_2_global[l_58] = l_59;
l_mut_34 = l_mut_34 + l_46;
}
let l_60 = l_1 + u32(1);
let l_61 = l_60 < u32(1122);
if l_61 {
let l_62 = workgroup_id.x * u32(1122);
let l_63 = l_62 + l_60;
let l_64 = &buffer_0_global[l_63];
let l_65 = atomicLoad(l_64);
let l_66 = workgroup_id.x * u32(1122);
let l_67 = l_66 + l_60;
let l_68 = &buffer_1_global[l_67];
atomicStore(l_68,l_mut_34);
let l_69 = workgroup_id.x * u32(1122);
let l_70 = l_69 + l_60;
let l_71 = u32(4) * l_70;
buffer_2_global[l_71] = workgroup_id.x;
let l_72 = u32(4) * l_70;
let l_73 = l_72 + u32(1);
buffer_2_global[l_73] = l_60;
let l_74 = u32(4) * l_70;
let l_75 = l_74 + u32(2);
buffer_2_global[l_75] = l_mut_34;
let l_76 = u32(4) * l_70;
let l_77 = l_76 + u32(3);
let l_78 = l_mut_34 + l_65;
buffer_2_global[l_77] = l_78;
l_mut_34 = l_mut_34 + l_65;
}
let l_79 = l_1 + u32(2);
let l_80 = l_79 < u32(1122);
if l_80 {
let l_81 = workgroup_id.x * u32(1122);
let l_82 = l_81 + l_79;
let l_83 = &buffer_0_global[l_82];
let l_84 = atomicLoad(l_83);
let l_85 = workgroup_id.x * u32(1122);
let l_86 = l_85 + l_79;
let l_87 = &buffer_1_global[l_86];
atomicStore(l_87,l_mut_34);
let l_88 = workgroup_id.x * u32(1122);
let l_89 = l_88 + l_79;
let l_90 = u32(4) * l_89;
buffer_2_global[l_90] = workgroup_id.x;
let l_91 = u32(4) * l_89;
let l_92 = l_91 + u32(1);
buffer_2_global[l_92] = l_79;
let l_93 = u32(4) * l_89;
let l_94 = l_93 + u32(2);
buffer_2_global[l_94] = l_mut_34;
let l_95 = u32(4) * l_89;
let l_96 = l_95 + u32(3);
let l_97 = l_mut_34 + l_84;
buffer_2_global[l_96] = l_97;
l_mut_34 = l_mut_34 + l_84;
}
let l_98 = l_1 + u32(3);
let l_99 = l_98 < u32(1122);
if l_99 {
let l_100 = workgroup_id.x * u32(1122);
let l_101 = l_100 + l_98;
let l_102 = &buffer_0_global[l_101];
let l_103 = atomicLoad(l_102);
let l_104 = workgroup_id.x * u32(1122);
let l_105 = l_104 + l_98;
let l_106 = &buffer_1_global[l_105];
atomicStore(l_106,l_mut_34);
let l_107 = workgroup_id.x * u32(1122);
let l_108 = l_107 + l_98;
let l_109 = u32(4) * l_108;
buffer_2_global[l_109] = workgroup_id.x;
let l_110 = u32(4) * l_108;
let l_111 = l_110 + u32(1);
buffer_2_global[l_111] = l_98;
let l_112 = u32(4) * l_108;
let l_113 = l_112 + u32(2);
buffer_2_global[l_113] = l_mut_34;
let l_114 = u32(4) * l_108;
let l_115 = l_114 + u32(3);
let l_116 = l_mut_34 + l_103;
buffer_2_global[l_115] = l_116;
l_mut_34 = l_mut_34 + l_103;
}
let l_117 = l_1 + u32(4);
let l_118 = l_117 < u32(1122);
if l_118 {
let l_119 = workgroup_id.x * u32(1122);
let l_120 = l_119 + l_117;
let l_121 = &buffer_0_global[l_120];
let l_122 = atomicLoad(l_121);
let l_123 = workgroup_id.x * u32(1122);
let l_124 = l_123 + l_117;
let l_125 = &buffer_1_global[l_124];
atomicStore(l_125,l_mut_34);
let l_126 = workgroup_id.x * u32(1122);
let l_127 = l_126 + l_117;
let l_128 = u32(4) * l_127;
buffer_2_global[l_128] = workgroup_id.x;
let l_129 = u32(4) * l_127;
let l_130 = l_129 + u32(1);
buffer_2_global[l_130] = l_117;
let l_131 = u32(4) * l_127;
let l_132 = l_131 + u32(2);
buffer_2_global[l_132] = l_mut_34;
let l_133 = u32(4) * l_127;
let l_134 = l_133 + u32(3);
let l_135 = l_mut_34 + l_122;
buffer_2_global[l_134] = l_135;
l_mut_34 = l_mut_34 + l_122;
}
workgroupBarrier();
let l_136 = local_invocation_id.x == u32(0);
if l_136 {
let l_137 = &buffer_3_global[u32(1)];
let l_138 = atomicAdd(l_137, u32(1));}
}
```
