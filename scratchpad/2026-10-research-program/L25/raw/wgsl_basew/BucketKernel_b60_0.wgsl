
```wgsl
@group(0)
@binding(0)
var<storage, read_write> buffer_0_global: array<u32>;

@group(0)
@binding(1)
var<storage, read_write> buffer_1_global: array<u32>;

@group(0)
@binding(2)
var<storage, read_write> buffer_2_global: array<u32>;

@group(0)
@binding(3)
var<storage, read_write> buffer_3_global: array<u32>;

@group(0)
@binding(4)
var<storage, read_write> buffer_4_global: array<u32>;

@group(0)
@binding(5)
var<storage, read_write> buffer_5_global: array<u32>;

@group(0)
@binding(6)
var<storage, read_write> buffer_6_global: array<u32>;

@group(0)
@binding(7)
var<storage, read_write> buffer_7_global: array<u32>;

@group(0)
@binding(8)
var<storage, read_write> buffer_8_global: array<atomic<u32>>;

struct info_st {
   scalars_u32: array<u32, 4>,
   static_meta: array<u32, 18>,
}

@group(0)
@binding(9)
var<storage, read> info: info_st;

var<workgroup> shared_memory_4: array<atomic<u32>, 64>;

const WORKGROUP_SIZE_X = 256u;
const WORKGROUP_SIZE_Y = 1u;
const WORKGROUP_SIZE_Z = 1u;

@compute
@workgroup_size(256, 1, 1)
fn bucket_kernel(
    @builtin(local_invocation_id) local_invocation_id: vec3<u32>,
    @builtin(workgroup_id) workgroup_id: vec3<u32>,
) {
var a_31: array<u32, 4>;

var a_38: array<u32, 4>;

var a_79: array<u32, 4>;

var l_mut_17: u32;
var l_mut_32: u32;
var l_mut_35: u32;
var l_mut_39: u32;
var l_mut_40: u32;
var l_mut_118: bool;
var l_mut_30: u64;
let l_0 = u64(info.scalars_u32[2]);
let l_1 = l_0 << u32(bitcast<u64>(u64(32)));
let l_2 = u64(info.scalars_u32[1]);
let l_3 = l_1 | l_2;
let l_5 = local_invocation_id.x < u32(64);
if l_5 {
let l_6 = &shared_memory_4[local_invocation_id.x];
atomicStore(l_6,u32(0));
}
workgroupBarrier();
let l_7 = buffer_2_global[workgroup_id.x];
let l_8 = workgroup_id.x + u32(1);
let l_9 = buffer_2_global[l_8];
let l_10 = l_9 - l_7;
let l_11 = workgroup_id.y * u32(60);
let l_12 = l_11 * info.scalars_u32[0];
let l_13 = u32(60) * l_7;
let l_14 = l_12 + l_13;
let l_15 = buffer_3_global[workgroup_id.y];
let l_16 = l_7 + local_invocation_id.x;
l_mut_17 = l_16;
loop {
let l_18 = l_mut_17 < l_9;
let l_19 = !l_18;
if l_19 {
break;
}
let l_20 = buffer_0_global[l_mut_17];
let l_21 = u32(2) * l_mut_17;
let l_22 = l_21 + u32(1);
let l_23 = buffer_1_global[l_22];
let l_24 = u64(l_23);
let l_25 = l_24 << u32(bitcast<u64>(u64(32)));
let l_26 = u32(2) * l_mut_17;
let l_27 = buffer_1_global[l_26];
let l_28 = u64(l_27);
let l_29 = l_25 | l_28;
l_mut_30 = l_29;
l_mut_32 = l_20;
let l_33 = l_mut_32 % u32(60);
a_31[u32(0)] = l_33;
l_mut_32 = l_mut_32 / u32(60);
let l_34 = l_mut_32 % u32(60);
a_31[u32(1)] = l_34;
l_mut_32 = l_mut_32 / u32(60);
l_mut_35 = l_15;
let l_36 = l_mut_35 % u32(60);
a_31[u32(2)] = l_36;
l_mut_35 = l_mut_35 / u32(60);
let l_37 = l_mut_35 % u32(60);
a_31[u32(3)] = l_37;
l_mut_35 = l_mut_35 / u32(60);
l_mut_39 = u32(0);
l_mut_40 = l_mut_39;
let l_41 = a_31[u32(0)];
let l_42 = a_31[u32(0)];
let l_43 = l_41 * l_42;
l_mut_40 = l_mut_40 + l_43;
let l_44 = l_mut_40 % u32(60);
a_38[u32(0)] = l_44;
let l_45 = l_mut_40 / u32(60);
l_mut_39 = l_45;
l_mut_40 = l_mut_39;
let l_46 = a_31[u32(0)];
let l_47 = a_31[u32(1)];
let l_48 = l_46 * l_47;
l_mut_40 = l_mut_40 + l_48;
let l_49 = a_31[u32(1)];
let l_50 = a_31[u32(0)];
let l_51 = l_49 * l_50;
l_mut_40 = l_mut_40 + l_51;
let l_52 = l_mut_40 % u32(60);
a_38[u32(1)] = l_52;
let l_53 = l_mut_40 / u32(60);
l_mut_39 = l_53;
l_mut_40 = l_mut_39;
let l_54 = a_31[u32(0)];
let l_55 = a_31[u32(2)];
let l_56 = l_54 * l_55;
l_mut_40 = l_mut_40 + l_56;
let l_57 = a_31[u32(1)];
let l_58 = a_31[u32(1)];
let l_59 = l_57 * l_58;
l_mut_40 = l_mut_40 + l_59;
let l_60 = a_31[u32(2)];
let l_61 = a_31[u32(0)];
let l_62 = l_60 * l_61;
l_mut_40 = l_mut_40 + l_62;
let l_63 = l_mut_40 % u32(60);
a_38[u32(2)] = l_63;
let l_64 = l_mut_40 / u32(60);
l_mut_39 = l_64;
l_mut_40 = l_mut_39;
let l_65 = a_31[u32(0)];
let l_66 = a_31[u32(3)];
let l_67 = l_65 * l_66;
l_mut_40 = l_mut_40 + l_67;
let l_68 = a_31[u32(1)];
let l_69 = a_31[u32(2)];
let l_70 = l_68 * l_69;
l_mut_40 = l_mut_40 + l_70;
let l_71 = a_31[u32(2)];
let l_72 = a_31[u32(1)];
let l_73 = l_71 * l_72;
l_mut_40 = l_mut_40 + l_73;
let l_74 = a_31[u32(3)];
let l_75 = a_31[u32(0)];
let l_76 = l_74 * l_75;
l_mut_40 = l_mut_40 + l_76;
let l_77 = l_mut_40 % u32(60);
a_38[u32(3)] = l_77;
let l_78 = l_mut_40 / u32(60);
l_mut_39 = l_78;
l_mut_39 = u32(0);
l_mut_40 = l_mut_39;
let l_80 = a_38[u32(0)];
let l_81 = a_31[u32(0)];
let l_82 = l_80 * l_81;
l_mut_40 = l_mut_40 + l_82;
let l_83 = l_mut_40 % u32(60);
a_79[u32(0)] = l_83;
let l_84 = l_mut_40 / u32(60);
l_mut_39 = l_84;
l_mut_40 = l_mut_39;
let l_85 = a_38[u32(0)];
let l_86 = a_31[u32(1)];
let l_87 = l_85 * l_86;
l_mut_40 = l_mut_40 + l_87;
let l_88 = a_38[u32(1)];
let l_89 = a_31[u32(0)];
let l_90 = l_88 * l_89;
l_mut_40 = l_mut_40 + l_90;
let l_91 = l_mut_40 % u32(60);
a_79[u32(1)] = l_91;
let l_92 = l_mut_40 / u32(60);
l_mut_39 = l_92;
l_mut_40 = l_mut_39;
let l_93 = a_38[u32(0)];
let l_94 = a_31[u32(2)];
let l_95 = l_93 * l_94;
l_mut_40 = l_mut_40 + l_95;
let l_96 = a_38[u32(1)];
let l_97 = a_31[u32(1)];
let l_98 = l_96 * l_97;
l_mut_40 = l_mut_40 + l_98;
let l_99 = a_38[u32(2)];
let l_100 = a_31[u32(0)];
let l_101 = l_99 * l_100;
l_mut_40 = l_mut_40 + l_101;
let l_102 = l_mut_40 % u32(60);
a_79[u32(2)] = l_102;
let l_103 = l_mut_40 / u32(60);
l_mut_39 = l_103;
l_mut_40 = l_mut_39;
let l_104 = a_38[u32(0)];
let l_105 = a_31[u32(3)];
let l_106 = l_104 * l_105;
l_mut_40 = l_mut_40 + l_106;
let l_107 = a_38[u32(1)];
let l_108 = a_31[u32(2)];
let l_109 = l_107 * l_108;
l_mut_40 = l_mut_40 + l_109;
let l_110 = a_38[u32(2)];
let l_111 = a_31[u32(1)];
let l_112 = l_110 * l_111;
l_mut_40 = l_mut_40 + l_112;
let l_113 = a_38[u32(3)];
let l_114 = a_31[u32(0)];
let l_115 = l_113 * l_114;
l_mut_40 = l_mut_40 + l_115;
let l_116 = l_mut_40 % u32(60);
a_79[u32(3)] = l_116;
let l_117 = l_mut_40 / u32(60);
l_mut_39 = l_117;
l_mut_118 = bool(true);
let l_119 = a_38[u32(2)];
let l_120 = a_79[u32(2)];
let l_121 = u64(l_119);
let l_122 = u64(1) << u32(bitcast<u64>(l_121));
let l_123 = u64(l_120);
let l_124 = u64(1) << u32(bitcast<u64>(l_123));
let l_125 = l_122 | l_124;
let l_126 = l_119 == l_120;
let l_127 = l_mut_30 | l_3;
let l_128 = l_127 & l_125;
let l_129 = l_128 != u64(0);
let l_130 = l_126 || l_129;
if l_130 {
l_mut_118 = bool(false);
}
l_mut_30 = l_mut_30 | l_125;
let l_131 = a_38[u32(3)];
let l_132 = a_79[u32(3)];
let l_133 = u64(l_131);
let l_134 = u64(1) << u32(bitcast<u64>(l_133));
let l_135 = u64(l_132);
let l_136 = u64(1) << u32(bitcast<u64>(l_135));
let l_137 = l_134 | l_136;
let l_138 = l_131 == l_132;
let l_139 = l_mut_30 | l_3;
let l_140 = l_139 & l_137;
let l_141 = l_140 != u64(0);
let l_142 = l_138 || l_141;
if l_142 {
l_mut_118 = bool(false);
}
l_mut_30 = l_mut_30 | l_137;
let l_143 = !l_mut_118;
if l_143 {
l_mut_30 = bitcast<u64>(i64(-1));
}
let l_144 = l_mut_30 | l_3;
let l_145 = workgroup_id.y * info.scalars_u32[0];
let l_146 = l_145 + l_mut_17;
let l_147 = u32(2) * l_146;
let l_148 = u32(bitcast<u64>(l_mut_30));
buffer_4_global[l_147] = l_148;
let l_149 = u32(2) * l_146;
let l_150 = l_149 + u32(1);
let l_151 = l_mut_30 >> u32(bitcast<u64>(u64(32)));
let l_152 = u32(bitcast<u64>(l_151));
buffer_4_global[l_150] = l_152;
if l_mut_118 {
let l_153 = &shared_memory_4[u32(0)];
let l_154 = atomicAdd(l_153, u32(1));let l_155 = l_14 + l_154;
buffer_6_global[l_155] = l_mut_17;
}
l_mut_17 = l_mut_17 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_156 = local_invocation_id.x < u32(1);
if l_156 {
let l_157 = workgroup_id.y * u32(1);
let l_158 = l_157 + local_invocation_id.x;
let l_159 = l_158 * u32(59);
let l_160 = l_159 + workgroup_id.x;
let l_161 = &shared_memory_4[local_invocation_id.x];
let l_162 = atomicLoad(l_161);
buffer_7_global[l_160] = l_162;
}
workgroupBarrier();
let l_163 = local_invocation_id.x == u32(0);
if l_163 {
let l_164 = &buffer_8_global[u32(3)];
let l_165 = atomicAdd(l_164, u32(1));}
}
```
