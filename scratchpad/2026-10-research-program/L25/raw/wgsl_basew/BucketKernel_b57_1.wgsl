
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
var a_31: array<u32, 5>;

var a_38: array<u32, 5>;

var a_96: array<u32, 5>;

var l_mut_152: bool;
var l_mut_30: u64;
var l_mut_17: u32;
var l_mut_32: u32;
var l_mut_36: u32;
var l_mut_39: u32;
var l_mut_40: u32;
var l_mut_190: u32;
var l_mut_191: u32;
var l_mut_194: u32;
var l_mut_195: u32;
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
let l_35 = l_mut_32 % u32(57);
a_31[u32(2)] = l_35;
l_mut_32 = l_mut_32 / u32(57);
l_mut_36 = l_15;
let l_37 = l_mut_36 % u32(57);
a_31[u32(3)] = l_37;
l_mut_36 = l_mut_36 / u32(57);
a_31[u32(4)] = u32(0);
l_mut_39 = u32(0);
l_mut_40 = l_mut_39;
let l_41 = a_31[u32(0)];
let l_42 = a_31[u32(0)];
let l_43 = l_41 * l_42;
l_mut_40 = l_mut_40 + l_43;
let l_44 = l_mut_40 % u32(57);
a_38[u32(0)] = l_44;
let l_45 = l_mut_40 / u32(57);
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
let l_52 = l_mut_40 % u32(57);
a_38[u32(1)] = l_52;
let l_53 = l_mut_40 / u32(57);
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
let l_63 = l_mut_40 % u32(57);
a_38[u32(2)] = l_63;
let l_64 = l_mut_40 / u32(57);
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
let l_77 = l_mut_40 % u32(57);
a_38[u32(3)] = l_77;
let l_78 = l_mut_40 / u32(57);
l_mut_39 = l_78;
l_mut_40 = l_mut_39;
let l_79 = a_31[u32(0)];
let l_80 = a_31[u32(4)];
let l_81 = l_79 * l_80;
l_mut_40 = l_mut_40 + l_81;
let l_82 = a_31[u32(1)];
let l_83 = a_31[u32(3)];
let l_84 = l_82 * l_83;
l_mut_40 = l_mut_40 + l_84;
let l_85 = a_31[u32(2)];
let l_86 = a_31[u32(2)];
let l_87 = l_85 * l_86;
l_mut_40 = l_mut_40 + l_87;
let l_88 = a_31[u32(3)];
let l_89 = a_31[u32(1)];
let l_90 = l_88 * l_89;
l_mut_40 = l_mut_40 + l_90;
let l_91 = a_31[u32(4)];
let l_92 = a_31[u32(0)];
let l_93 = l_91 * l_92;
l_mut_40 = l_mut_40 + l_93;
let l_94 = l_mut_40 % u32(57);
a_38[u32(4)] = l_94;
let l_95 = l_mut_40 / u32(57);
l_mut_39 = l_95;
l_mut_39 = u32(0);
l_mut_40 = l_mut_39;
let l_97 = a_38[u32(0)];
let l_98 = a_31[u32(0)];
let l_99 = l_97 * l_98;
l_mut_40 = l_mut_40 + l_99;
let l_100 = l_mut_40 % u32(57);
a_96[u32(0)] = l_100;
let l_101 = l_mut_40 / u32(57);
l_mut_39 = l_101;
l_mut_40 = l_mut_39;
let l_102 = a_38[u32(0)];
let l_103 = a_31[u32(1)];
let l_104 = l_102 * l_103;
l_mut_40 = l_mut_40 + l_104;
let l_105 = a_38[u32(1)];
let l_106 = a_31[u32(0)];
let l_107 = l_105 * l_106;
l_mut_40 = l_mut_40 + l_107;
let l_108 = l_mut_40 % u32(57);
a_96[u32(1)] = l_108;
let l_109 = l_mut_40 / u32(57);
l_mut_39 = l_109;
l_mut_40 = l_mut_39;
let l_110 = a_38[u32(0)];
let l_111 = a_31[u32(2)];
let l_112 = l_110 * l_111;
l_mut_40 = l_mut_40 + l_112;
let l_113 = a_38[u32(1)];
let l_114 = a_31[u32(1)];
let l_115 = l_113 * l_114;
l_mut_40 = l_mut_40 + l_115;
let l_116 = a_38[u32(2)];
let l_117 = a_31[u32(0)];
let l_118 = l_116 * l_117;
l_mut_40 = l_mut_40 + l_118;
let l_119 = l_mut_40 % u32(57);
a_96[u32(2)] = l_119;
let l_120 = l_mut_40 / u32(57);
l_mut_39 = l_120;
l_mut_40 = l_mut_39;
let l_121 = a_38[u32(0)];
let l_122 = a_31[u32(3)];
let l_123 = l_121 * l_122;
l_mut_40 = l_mut_40 + l_123;
let l_124 = a_38[u32(1)];
let l_125 = a_31[u32(2)];
let l_126 = l_124 * l_125;
l_mut_40 = l_mut_40 + l_126;
let l_127 = a_38[u32(2)];
let l_128 = a_31[u32(1)];
let l_129 = l_127 * l_128;
l_mut_40 = l_mut_40 + l_129;
let l_130 = a_38[u32(3)];
let l_131 = a_31[u32(0)];
let l_132 = l_130 * l_131;
l_mut_40 = l_mut_40 + l_132;
let l_133 = l_mut_40 % u32(57);
a_96[u32(3)] = l_133;
let l_134 = l_mut_40 / u32(57);
l_mut_39 = l_134;
l_mut_40 = l_mut_39;
let l_135 = a_38[u32(0)];
let l_136 = a_31[u32(4)];
let l_137 = l_135 * l_136;
l_mut_40 = l_mut_40 + l_137;
let l_138 = a_38[u32(1)];
let l_139 = a_31[u32(3)];
let l_140 = l_138 * l_139;
l_mut_40 = l_mut_40 + l_140;
let l_141 = a_38[u32(2)];
let l_142 = a_31[u32(2)];
let l_143 = l_141 * l_142;
l_mut_40 = l_mut_40 + l_143;
let l_144 = a_38[u32(3)];
let l_145 = a_31[u32(1)];
let l_146 = l_144 * l_145;
l_mut_40 = l_mut_40 + l_146;
let l_147 = a_38[u32(4)];
let l_148 = a_31[u32(0)];
let l_149 = l_147 * l_148;
l_mut_40 = l_mut_40 + l_149;
let l_150 = l_mut_40 % u32(57);
a_96[u32(4)] = l_150;
let l_151 = l_mut_40 / u32(57);
l_mut_39 = l_151;
l_mut_152 = bool(true);
let l_153 = a_38[u32(3)];
let l_154 = a_96[u32(3)];
let l_155 = u64(l_153);
let l_156 = u64(1) << u32(bitcast<u64>(l_155));
let l_157 = u64(l_154);
let l_158 = u64(1) << u32(bitcast<u64>(l_157));
let l_159 = l_156 | l_158;
let l_160 = l_153 == l_154;
let l_161 = l_mut_30 | l_3;
let l_162 = l_161 & l_159;
let l_163 = l_162 != u64(0);
let l_164 = l_160 || l_163;
if l_164 {
l_mut_152 = bool(false);
}
l_mut_30 = l_mut_30 | l_159;
let l_165 = !l_mut_152;
if l_165 {
l_mut_30 = bitcast<u64>(i64(-1));
}
let l_166 = l_mut_30 | l_3;
let l_167 = workgroup_id.y * info.scalars_u32[0];
let l_168 = l_167 + l_mut_17;
let l_169 = u32(2) * l_168;
let l_170 = u32(bitcast<u64>(l_mut_30));
buffer_4_global[l_169] = l_170;
let l_171 = u32(2) * l_168;
let l_172 = l_171 + u32(1);
let l_173 = l_mut_30 >> u32(bitcast<u64>(u64(32)));
let l_174 = u32(bitcast<u64>(l_173));
buffer_4_global[l_172] = l_174;
let l_175 = a_38[u32(4)];
let l_176 = a_96[u32(4)];
let l_177 = a_31[u32(0)];
let l_178 = u32(2) * l_177;
let l_179 = l_178 % u32(57);
let l_180 = l_177 * l_177;
let l_181 = l_180 % u32(57);
let l_182 = u32(3) * l_181;
let l_183 = l_182 % u32(57);
let l_184 = l_176 << u32(8);
let l_185 = l_175 | l_184;
let l_186 = l_179 << u32(16);
let l_187 = l_185 | l_186;
let l_188 = l_183 << u32(24);
let l_189 = l_187 | l_188;
buffer_5_global[l_168] = l_189;
if l_mut_152 {
l_mut_40 = l_175;
l_mut_190 = l_176;
l_mut_191 = u32(0);
loop {
let l_192 = l_mut_191 < u32(57);
let l_193 = !l_192;
if l_193 {
break;
}
l_mut_194 = l_mut_40;
l_mut_195 = l_mut_190;
let l_196 = u64(l_mut_194);
let l_197 = u64(1) << u32(bitcast<u64>(l_196));
let l_198 = u64(l_mut_195);
let l_199 = u64(1) << u32(bitcast<u64>(l_198));
let l_200 = l_197 | l_199;
let l_201 = l_mut_194 != l_mut_195;
let l_202 = l_166 & l_200;
let l_203 = l_202 == u64(0);
let l_204 = l_201 && l_203;
if l_204 {
let l_205 = &shared_memory_4[l_mut_191];
let l_206 = atomicAdd(l_205, u32(1));let l_207 = l_mut_191 * l_10;
let l_208 = l_14 + l_207;
let l_209 = l_208 + l_206;
buffer_6_global[l_209] = l_mut_17;
}
l_mut_40 = l_mut_40 + l_179;
let l_210 = l_mut_40 >= u32(57);
if l_210 {
l_mut_40 = l_mut_40 - u32(57);
}
l_mut_190 = l_mut_190 + l_183;
let l_211 = l_mut_190 >= u32(57);
if l_211 {
l_mut_190 = l_mut_190 - u32(57);
}
l_mut_191 = l_mut_191 + u32(1);
}
}
l_mut_17 = l_mut_17 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_212 = local_invocation_id.x < u32(57);
if l_212 {
let l_213 = workgroup_id.y * u32(57);
let l_214 = l_213 + local_invocation_id.x;
let l_215 = l_214 * u32(56);
let l_216 = l_215 + workgroup_id.x;
let l_217 = &shared_memory_4[local_invocation_id.x];
let l_218 = atomicLoad(l_217);
buffer_7_global[l_216] = l_218;
}
workgroupBarrier();
let l_219 = local_invocation_id.x == u32(0);
if l_219 {
let l_220 = &buffer_8_global[u32(3)];
let l_221 = atomicAdd(l_220, u32(1));}
}
```
