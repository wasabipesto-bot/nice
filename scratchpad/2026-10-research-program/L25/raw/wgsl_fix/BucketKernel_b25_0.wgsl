
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
var a_31: array<u32, 3>;

var a_36: array<u32, 3>;

var a_63: array<u32, 3>;

var l_mut_30: u64;
var l_mut_88: bool;
var l_mut_17: u32;
var l_mut_32: u32;
var l_mut_34: u32;
var l_mut_37: u32;
var l_mut_38: u32;
var l_mut_126: u32;
var l_mut_127: u32;
var l_mut_130: u32;
var l_mut_131: u32;
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
let l_11 = workgroup_id.y * u32(25);
let l_12 = l_11 * info.scalars_u32[0];
let l_13 = u32(25) * l_7;
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
let l_33 = l_mut_32 % u32(25);
a_31[u32(0)] = l_33;
l_mut_32 = l_mut_32 / u32(25);
l_mut_34 = l_15;
let l_35 = l_mut_34 % u32(25);
a_31[u32(1)] = l_35;
l_mut_34 = l_mut_34 / u32(25);
a_31[u32(2)] = u32(0);
l_mut_37 = u32(0);
l_mut_38 = l_mut_37;
let l_39 = a_31[u32(0)];
let l_40 = a_31[u32(0)];
let l_41 = l_39 * l_40;
l_mut_38 = l_mut_38 + l_41;
let l_42 = l_mut_38 % u32(25);
a_36[u32(0)] = l_42;
let l_43 = l_mut_38 / u32(25);
l_mut_37 = l_43;
l_mut_38 = l_mut_37;
let l_44 = a_31[u32(0)];
let l_45 = a_31[u32(1)];
let l_46 = l_44 * l_45;
l_mut_38 = l_mut_38 + l_46;
let l_47 = a_31[u32(1)];
let l_48 = a_31[u32(0)];
let l_49 = l_47 * l_48;
l_mut_38 = l_mut_38 + l_49;
let l_50 = l_mut_38 % u32(25);
a_36[u32(1)] = l_50;
let l_51 = l_mut_38 / u32(25);
l_mut_37 = l_51;
l_mut_38 = l_mut_37;
let l_52 = a_31[u32(0)];
let l_53 = a_31[u32(2)];
let l_54 = l_52 * l_53;
l_mut_38 = l_mut_38 + l_54;
let l_55 = a_31[u32(1)];
let l_56 = a_31[u32(1)];
let l_57 = l_55 * l_56;
l_mut_38 = l_mut_38 + l_57;
let l_58 = a_31[u32(2)];
let l_59 = a_31[u32(0)];
let l_60 = l_58 * l_59;
l_mut_38 = l_mut_38 + l_60;
let l_61 = l_mut_38 % u32(25);
a_36[u32(2)] = l_61;
let l_62 = l_mut_38 / u32(25);
l_mut_37 = l_62;
l_mut_37 = u32(0);
l_mut_38 = l_mut_37;
let l_64 = a_36[u32(0)];
let l_65 = a_31[u32(0)];
let l_66 = l_64 * l_65;
l_mut_38 = l_mut_38 + l_66;
let l_67 = l_mut_38 % u32(25);
a_63[u32(0)] = l_67;
let l_68 = l_mut_38 / u32(25);
l_mut_37 = l_68;
l_mut_38 = l_mut_37;
let l_69 = a_36[u32(0)];
let l_70 = a_31[u32(1)];
let l_71 = l_69 * l_70;
l_mut_38 = l_mut_38 + l_71;
let l_72 = a_36[u32(1)];
let l_73 = a_31[u32(0)];
let l_74 = l_72 * l_73;
l_mut_38 = l_mut_38 + l_74;
let l_75 = l_mut_38 % u32(25);
a_63[u32(1)] = l_75;
let l_76 = l_mut_38 / u32(25);
l_mut_37 = l_76;
l_mut_38 = l_mut_37;
let l_77 = a_36[u32(0)];
let l_78 = a_31[u32(2)];
let l_79 = l_77 * l_78;
l_mut_38 = l_mut_38 + l_79;
let l_80 = a_36[u32(1)];
let l_81 = a_31[u32(1)];
let l_82 = l_80 * l_81;
l_mut_38 = l_mut_38 + l_82;
let l_83 = a_36[u32(2)];
let l_84 = a_31[u32(0)];
let l_85 = l_83 * l_84;
l_mut_38 = l_mut_38 + l_85;
let l_86 = l_mut_38 % u32(25);
a_63[u32(2)] = l_86;
let l_87 = l_mut_38 / u32(25);
l_mut_37 = l_87;
l_mut_88 = bool(true);
let l_89 = a_36[u32(1)];
let l_90 = a_63[u32(1)];
let l_91 = u64(l_89);
let l_92 = u64(1) << u32(bitcast<u64>(l_91));
let l_93 = u64(l_90);
let l_94 = u64(1) << u32(bitcast<u64>(l_93));
let l_95 = l_92 | l_94;
let l_96 = l_89 == l_90;
let l_97 = l_mut_30 | l_3;
let l_98 = l_97 & l_95;
let l_99 = l_98 != u64(0);
let l_100 = l_96 || l_99;
if l_100 {
l_mut_88 = bool(false);
}
l_mut_30 = l_mut_30 | l_95;
let l_101 = !l_mut_88;
if l_101 {
l_mut_30 = bitcast<u64>(i64(-1));
}
let l_102 = l_mut_30 | l_3;
let l_103 = workgroup_id.y * info.scalars_u32[0];
let l_104 = l_103 + l_mut_17;
let l_105 = u32(2) * l_104;
let l_106 = u32(bitcast<u64>(l_mut_30));
buffer_4_global[l_105] = l_106;
let l_107 = u32(2) * l_104;
let l_108 = l_107 + u32(1);
let l_109 = l_mut_30 >> u32(bitcast<u64>(u64(32)));
let l_110 = u32(bitcast<u64>(l_109));
buffer_4_global[l_108] = l_110;
let l_111 = a_36[u32(2)];
let l_112 = a_63[u32(2)];
let l_113 = a_31[u32(0)];
let l_114 = u32(2) * l_113;
let l_115 = l_114 % u32(25);
let l_116 = l_113 * l_113;
let l_117 = l_116 % u32(25);
let l_118 = u32(3) * l_117;
let l_119 = l_118 % u32(25);
let l_120 = l_112 << u32(8);
let l_121 = l_111 | l_120;
let l_122 = l_115 << u32(16);
let l_123 = l_121 | l_122;
let l_124 = l_119 << u32(24);
let l_125 = l_123 | l_124;
buffer_5_global[l_104] = l_125;
if l_mut_88 {
l_mut_38 = l_111;
l_mut_126 = l_112;
l_mut_127 = u32(0);
loop {
let l_128 = l_mut_127 < u32(25);
let l_129 = !l_128;
if l_129 {
break;
}
l_mut_130 = l_mut_38;
l_mut_131 = l_mut_126;
let l_132 = u64(l_mut_130);
let l_133 = u64(1) << u32(bitcast<u64>(l_132));
let l_134 = u64(l_mut_131);
let l_135 = u64(1) << u32(bitcast<u64>(l_134));
let l_136 = l_133 | l_135;
let l_137 = l_mut_130 != l_mut_131;
let l_138 = l_102 & l_136;
let l_139 = l_138 == u64(0);
let l_140 = l_137 && l_139;
if l_140 {
let l_141 = &shared_memory_4[l_mut_127];
let l_142 = atomicAdd(l_141, u32(1));let l_143 = l_mut_127 * l_10;
let l_144 = l_14 + l_143;
let l_145 = l_144 + l_142;
buffer_6_global[l_145] = l_mut_17;
}
l_mut_38 = l_mut_38 + l_115;
let l_146 = l_mut_38 >= u32(25);
if l_146 {
l_mut_38 = l_mut_38 - u32(25);
}
l_mut_126 = l_mut_126 + l_119;
let l_147 = l_mut_126 >= u32(25);
if l_147 {
l_mut_126 = l_mut_126 - u32(25);
}
l_mut_127 = l_mut_127 + u32(1);
}
}
l_mut_17 = l_mut_17 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_148 = local_invocation_id.x < u32(25);
if l_148 {
let l_149 = workgroup_id.y * u32(25);
let l_150 = l_149 + local_invocation_id.x;
let l_151 = l_150 * u32(24);
let l_152 = l_151 + workgroup_id.x;
let l_153 = &shared_memory_4[local_invocation_id.x];
let l_154 = atomicLoad(l_153);
buffer_7_global[l_152] = l_154;
}
workgroupBarrier();
let l_155 = local_invocation_id.x == u32(0);
if l_155 {
let l_156 = &buffer_8_global[u32(3)];
let l_157 = atomicAdd(l_156, u32(1));}
}
```
