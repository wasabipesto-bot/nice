
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

var a_37: array<u32, 4>;

var a_78: array<u32, 4>;

var l_mut_17: u32;
var l_mut_32: u32;
var l_mut_35: u32;
var l_mut_38: u32;
var l_mut_39: u32;
var l_mut_155: u32;
var l_mut_156: u32;
var l_mut_159: u32;
var l_mut_160: u32;
var l_mut_30: u64;
var l_mut_117: bool;
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
let l_11 = workgroup_id.y * u32(57);
let l_12 = l_11 * info.scalars_u32[0];
let l_13 = u32(57) * l_7;
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
let l_33 = l_mut_32 % u32(57);
a_31[u32(0)] = l_33;
l_mut_32 = l_mut_32 / u32(57);
let l_34 = l_mut_32 % u32(57);
a_31[u32(1)] = l_34;
l_mut_32 = l_mut_32 / u32(57);
l_mut_35 = l_15;
let l_36 = l_mut_35 % u32(57);
a_31[u32(2)] = l_36;
l_mut_35 = l_mut_35 / u32(57);
a_31[u32(3)] = u32(0);
l_mut_38 = u32(0);
l_mut_39 = l_mut_38;
let l_40 = a_31[u32(0)];
let l_41 = a_31[u32(0)];
let l_42 = l_40 * l_41;
l_mut_39 = l_mut_39 + l_42;
let l_43 = l_mut_39 % u32(57);
a_37[u32(0)] = l_43;
let l_44 = l_mut_39 / u32(57);
l_mut_38 = l_44;
l_mut_39 = l_mut_38;
let l_45 = a_31[u32(0)];
let l_46 = a_31[u32(1)];
let l_47 = l_45 * l_46;
l_mut_39 = l_mut_39 + l_47;
let l_48 = a_31[u32(1)];
let l_49 = a_31[u32(0)];
let l_50 = l_48 * l_49;
l_mut_39 = l_mut_39 + l_50;
let l_51 = l_mut_39 % u32(57);
a_37[u32(1)] = l_51;
let l_52 = l_mut_39 / u32(57);
l_mut_38 = l_52;
l_mut_39 = l_mut_38;
let l_53 = a_31[u32(0)];
let l_54 = a_31[u32(2)];
let l_55 = l_53 * l_54;
l_mut_39 = l_mut_39 + l_55;
let l_56 = a_31[u32(1)];
let l_57 = a_31[u32(1)];
let l_58 = l_56 * l_57;
l_mut_39 = l_mut_39 + l_58;
let l_59 = a_31[u32(2)];
let l_60 = a_31[u32(0)];
let l_61 = l_59 * l_60;
l_mut_39 = l_mut_39 + l_61;
let l_62 = l_mut_39 % u32(57);
a_37[u32(2)] = l_62;
let l_63 = l_mut_39 / u32(57);
l_mut_38 = l_63;
l_mut_39 = l_mut_38;
let l_64 = a_31[u32(0)];
let l_65 = a_31[u32(3)];
let l_66 = l_64 * l_65;
l_mut_39 = l_mut_39 + l_66;
let l_67 = a_31[u32(1)];
let l_68 = a_31[u32(2)];
let l_69 = l_67 * l_68;
l_mut_39 = l_mut_39 + l_69;
let l_70 = a_31[u32(2)];
let l_71 = a_31[u32(1)];
let l_72 = l_70 * l_71;
l_mut_39 = l_mut_39 + l_72;
let l_73 = a_31[u32(3)];
let l_74 = a_31[u32(0)];
let l_75 = l_73 * l_74;
l_mut_39 = l_mut_39 + l_75;
let l_76 = l_mut_39 % u32(57);
a_37[u32(3)] = l_76;
let l_77 = l_mut_39 / u32(57);
l_mut_38 = l_77;
l_mut_38 = u32(0);
l_mut_39 = l_mut_38;
let l_79 = a_37[u32(0)];
let l_80 = a_31[u32(0)];
let l_81 = l_79 * l_80;
l_mut_39 = l_mut_39 + l_81;
let l_82 = l_mut_39 % u32(57);
a_78[u32(0)] = l_82;
let l_83 = l_mut_39 / u32(57);
l_mut_38 = l_83;
l_mut_39 = l_mut_38;
let l_84 = a_37[u32(0)];
let l_85 = a_31[u32(1)];
let l_86 = l_84 * l_85;
l_mut_39 = l_mut_39 + l_86;
let l_87 = a_37[u32(1)];
let l_88 = a_31[u32(0)];
let l_89 = l_87 * l_88;
l_mut_39 = l_mut_39 + l_89;
let l_90 = l_mut_39 % u32(57);
a_78[u32(1)] = l_90;
let l_91 = l_mut_39 / u32(57);
l_mut_38 = l_91;
l_mut_39 = l_mut_38;
let l_92 = a_37[u32(0)];
let l_93 = a_31[u32(2)];
let l_94 = l_92 * l_93;
l_mut_39 = l_mut_39 + l_94;
let l_95 = a_37[u32(1)];
let l_96 = a_31[u32(1)];
let l_97 = l_95 * l_96;
l_mut_39 = l_mut_39 + l_97;
let l_98 = a_37[u32(2)];
let l_99 = a_31[u32(0)];
let l_100 = l_98 * l_99;
l_mut_39 = l_mut_39 + l_100;
let l_101 = l_mut_39 % u32(57);
a_78[u32(2)] = l_101;
let l_102 = l_mut_39 / u32(57);
l_mut_38 = l_102;
l_mut_39 = l_mut_38;
let l_103 = a_37[u32(0)];
let l_104 = a_31[u32(3)];
let l_105 = l_103 * l_104;
l_mut_39 = l_mut_39 + l_105;
let l_106 = a_37[u32(1)];
let l_107 = a_31[u32(2)];
let l_108 = l_106 * l_107;
l_mut_39 = l_mut_39 + l_108;
let l_109 = a_37[u32(2)];
let l_110 = a_31[u32(1)];
let l_111 = l_109 * l_110;
l_mut_39 = l_mut_39 + l_111;
let l_112 = a_37[u32(3)];
let l_113 = a_31[u32(0)];
let l_114 = l_112 * l_113;
l_mut_39 = l_mut_39 + l_114;
let l_115 = l_mut_39 % u32(57);
a_78[u32(3)] = l_115;
let l_116 = l_mut_39 / u32(57);
l_mut_38 = l_116;
l_mut_117 = bool(true);
let l_118 = a_37[u32(2)];
let l_119 = a_78[u32(2)];
let l_120 = u64(l_118);
let l_121 = u64(1) << u32(bitcast<u64>(l_120));
let l_122 = u64(l_119);
let l_123 = u64(1) << u32(bitcast<u64>(l_122));
let l_124 = l_121 | l_123;
let l_125 = l_118 == l_119;
let l_126 = l_mut_30 | l_3;
let l_127 = l_126 & l_124;
let l_128 = l_127 != u64(0);
let l_129 = l_125 || l_128;
if l_129 {
l_mut_117 = bool(false);
}
l_mut_30 = l_mut_30 | l_124;
let l_130 = !l_mut_117;
if l_130 {
l_mut_30 = bitcast<u64>(i64(-1));
}
let l_131 = l_mut_30 | l_3;
let l_132 = workgroup_id.y * info.scalars_u32[0];
let l_133 = l_132 + l_mut_17;
let l_134 = u32(2) * l_133;
let l_135 = u32(bitcast<u64>(l_mut_30));
buffer_4_global[l_134] = l_135;
let l_136 = u32(2) * l_133;
let l_137 = l_136 + u32(1);
let l_138 = l_mut_30 >> u32(bitcast<u64>(u64(32)));
let l_139 = u32(bitcast<u64>(l_138));
buffer_4_global[l_137] = l_139;
let l_140 = a_37[u32(3)];
let l_141 = a_78[u32(3)];
let l_142 = a_31[u32(0)];
let l_143 = u32(2) * l_142;
let l_144 = l_143 % u32(57);
let l_145 = l_142 * l_142;
let l_146 = l_145 % u32(57);
let l_147 = u32(3) * l_146;
let l_148 = l_147 % u32(57);
let l_149 = l_141 << u32(8);
let l_150 = l_140 | l_149;
let l_151 = l_144 << u32(16);
let l_152 = l_150 | l_151;
let l_153 = l_148 << u32(24);
let l_154 = l_152 | l_153;
buffer_5_global[l_133] = l_154;
if l_mut_117 {
l_mut_39 = l_140;
l_mut_155 = l_141;
l_mut_156 = u32(0);
loop {
let l_157 = l_mut_156 < u32(57);
let l_158 = !l_157;
if l_158 {
break;
}
l_mut_159 = l_mut_39;
l_mut_160 = l_mut_155;
let l_161 = u64(l_mut_159);
let l_162 = u64(1) << u32(bitcast<u64>(l_161));
let l_163 = u64(l_mut_160);
let l_164 = u64(1) << u32(bitcast<u64>(l_163));
let l_165 = l_162 | l_164;
let l_166 = l_mut_159 != l_mut_160;
let l_167 = l_131 & l_165;
let l_168 = l_167 == u64(0);
let l_169 = l_166 && l_168;
if l_169 {
let l_170 = &shared_memory_4[l_mut_156];
let l_171 = atomicAdd(l_170, u32(1));let l_172 = l_mut_156 * l_10;
let l_173 = l_14 + l_172;
let l_174 = l_173 + l_171;
buffer_6_global[l_174] = l_mut_17;
}
l_mut_39 = l_mut_39 + l_144;
let l_175 = l_mut_39 >= u32(57);
if l_175 {
l_mut_39 = l_mut_39 - u32(57);
}
l_mut_155 = l_mut_155 + l_148;
let l_176 = l_mut_155 >= u32(57);
if l_176 {
l_mut_155 = l_mut_155 - u32(57);
}
l_mut_156 = l_mut_156 + u32(1);
}
}
l_mut_17 = l_mut_17 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_177 = local_invocation_id.x < u32(57);
if l_177 {
let l_178 = workgroup_id.y * u32(57);
let l_179 = l_178 + local_invocation_id.x;
let l_180 = l_179 * u32(56);
let l_181 = l_180 + workgroup_id.x;
let l_182 = &shared_memory_4[local_invocation_id.x];
let l_183 = atomicLoad(l_182);
buffer_7_global[l_181] = l_183;
}
workgroupBarrier();
let l_184 = local_invocation_id.x == u32(0);
if l_184 {
let l_185 = &buffer_8_global[u32(3)];
let l_186 = atomicAdd(l_185, u32(1));}
}
```
