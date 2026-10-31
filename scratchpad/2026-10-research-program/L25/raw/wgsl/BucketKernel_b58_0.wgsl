
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
var a_31: array<u32, 6>;

var a_39: array<u32, 6>;

var a_117: array<u32, 6>;

var l_mut_17: u32;
var l_mut_32: u32;
var l_mut_36: u32;
var l_mut_40: u32;
var l_mut_41: u32;
var l_mut_243: u32;
var l_mut_244: u32;
var l_mut_247: u32;
var l_mut_248: u32;
var l_mut_30: u64;
var l_mut_193: bool;
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
let l_11 = workgroup_id.y * u32(58);
let l_12 = l_11 * info.scalars_u32[0];
let l_13 = u32(58) * l_7;
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
let l_33 = l_mut_32 % u32(58);
a_31[u32(0)] = l_33;
l_mut_32 = l_mut_32 / u32(58);
let l_34 = l_mut_32 % u32(58);
a_31[u32(1)] = l_34;
l_mut_32 = l_mut_32 / u32(58);
let l_35 = l_mut_32 % u32(58);
a_31[u32(2)] = l_35;
l_mut_32 = l_mut_32 / u32(58);
l_mut_36 = l_15;
let l_37 = l_mut_36 % u32(58);
a_31[u32(3)] = l_37;
l_mut_36 = l_mut_36 / u32(58);
let l_38 = l_mut_36 % u32(58);
a_31[u32(4)] = l_38;
l_mut_36 = l_mut_36 / u32(58);
a_31[u32(5)] = u32(0);
l_mut_40 = u32(0);
l_mut_41 = l_mut_40;
let l_42 = a_31[u32(0)];
let l_43 = a_31[u32(0)];
let l_44 = l_42 * l_43;
l_mut_41 = l_mut_41 + l_44;
let l_45 = l_mut_41 % u32(58);
a_39[u32(0)] = l_45;
let l_46 = l_mut_41 / u32(58);
l_mut_40 = l_46;
l_mut_41 = l_mut_40;
let l_47 = a_31[u32(0)];
let l_48 = a_31[u32(1)];
let l_49 = l_47 * l_48;
l_mut_41 = l_mut_41 + l_49;
let l_50 = a_31[u32(1)];
let l_51 = a_31[u32(0)];
let l_52 = l_50 * l_51;
l_mut_41 = l_mut_41 + l_52;
let l_53 = l_mut_41 % u32(58);
a_39[u32(1)] = l_53;
let l_54 = l_mut_41 / u32(58);
l_mut_40 = l_54;
l_mut_41 = l_mut_40;
let l_55 = a_31[u32(0)];
let l_56 = a_31[u32(2)];
let l_57 = l_55 * l_56;
l_mut_41 = l_mut_41 + l_57;
let l_58 = a_31[u32(1)];
let l_59 = a_31[u32(1)];
let l_60 = l_58 * l_59;
l_mut_41 = l_mut_41 + l_60;
let l_61 = a_31[u32(2)];
let l_62 = a_31[u32(0)];
let l_63 = l_61 * l_62;
l_mut_41 = l_mut_41 + l_63;
let l_64 = l_mut_41 % u32(58);
a_39[u32(2)] = l_64;
let l_65 = l_mut_41 / u32(58);
l_mut_40 = l_65;
l_mut_41 = l_mut_40;
let l_66 = a_31[u32(0)];
let l_67 = a_31[u32(3)];
let l_68 = l_66 * l_67;
l_mut_41 = l_mut_41 + l_68;
let l_69 = a_31[u32(1)];
let l_70 = a_31[u32(2)];
let l_71 = l_69 * l_70;
l_mut_41 = l_mut_41 + l_71;
let l_72 = a_31[u32(2)];
let l_73 = a_31[u32(1)];
let l_74 = l_72 * l_73;
l_mut_41 = l_mut_41 + l_74;
let l_75 = a_31[u32(3)];
let l_76 = a_31[u32(0)];
let l_77 = l_75 * l_76;
l_mut_41 = l_mut_41 + l_77;
let l_78 = l_mut_41 % u32(58);
a_39[u32(3)] = l_78;
let l_79 = l_mut_41 / u32(58);
l_mut_40 = l_79;
l_mut_41 = l_mut_40;
let l_80 = a_31[u32(0)];
let l_81 = a_31[u32(4)];
let l_82 = l_80 * l_81;
l_mut_41 = l_mut_41 + l_82;
let l_83 = a_31[u32(1)];
let l_84 = a_31[u32(3)];
let l_85 = l_83 * l_84;
l_mut_41 = l_mut_41 + l_85;
let l_86 = a_31[u32(2)];
let l_87 = a_31[u32(2)];
let l_88 = l_86 * l_87;
l_mut_41 = l_mut_41 + l_88;
let l_89 = a_31[u32(3)];
let l_90 = a_31[u32(1)];
let l_91 = l_89 * l_90;
l_mut_41 = l_mut_41 + l_91;
let l_92 = a_31[u32(4)];
let l_93 = a_31[u32(0)];
let l_94 = l_92 * l_93;
l_mut_41 = l_mut_41 + l_94;
let l_95 = l_mut_41 % u32(58);
a_39[u32(4)] = l_95;
let l_96 = l_mut_41 / u32(58);
l_mut_40 = l_96;
l_mut_41 = l_mut_40;
let l_97 = a_31[u32(0)];
let l_98 = a_31[u32(5)];
let l_99 = l_97 * l_98;
l_mut_41 = l_mut_41 + l_99;
let l_100 = a_31[u32(1)];
let l_101 = a_31[u32(4)];
let l_102 = l_100 * l_101;
l_mut_41 = l_mut_41 + l_102;
let l_103 = a_31[u32(2)];
let l_104 = a_31[u32(3)];
let l_105 = l_103 * l_104;
l_mut_41 = l_mut_41 + l_105;
let l_106 = a_31[u32(3)];
let l_107 = a_31[u32(2)];
let l_108 = l_106 * l_107;
l_mut_41 = l_mut_41 + l_108;
let l_109 = a_31[u32(4)];
let l_110 = a_31[u32(1)];
let l_111 = l_109 * l_110;
l_mut_41 = l_mut_41 + l_111;
let l_112 = a_31[u32(5)];
let l_113 = a_31[u32(0)];
let l_114 = l_112 * l_113;
l_mut_41 = l_mut_41 + l_114;
let l_115 = l_mut_41 % u32(58);
a_39[u32(5)] = l_115;
let l_116 = l_mut_41 / u32(58);
l_mut_40 = l_116;
l_mut_40 = u32(0);
l_mut_41 = l_mut_40;
let l_118 = a_39[u32(0)];
let l_119 = a_31[u32(0)];
let l_120 = l_118 * l_119;
l_mut_41 = l_mut_41 + l_120;
let l_121 = l_mut_41 % u32(58);
a_117[u32(0)] = l_121;
let l_122 = l_mut_41 / u32(58);
l_mut_40 = l_122;
l_mut_41 = l_mut_40;
let l_123 = a_39[u32(0)];
let l_124 = a_31[u32(1)];
let l_125 = l_123 * l_124;
l_mut_41 = l_mut_41 + l_125;
let l_126 = a_39[u32(1)];
let l_127 = a_31[u32(0)];
let l_128 = l_126 * l_127;
l_mut_41 = l_mut_41 + l_128;
let l_129 = l_mut_41 % u32(58);
a_117[u32(1)] = l_129;
let l_130 = l_mut_41 / u32(58);
l_mut_40 = l_130;
l_mut_41 = l_mut_40;
let l_131 = a_39[u32(0)];
let l_132 = a_31[u32(2)];
let l_133 = l_131 * l_132;
l_mut_41 = l_mut_41 + l_133;
let l_134 = a_39[u32(1)];
let l_135 = a_31[u32(1)];
let l_136 = l_134 * l_135;
l_mut_41 = l_mut_41 + l_136;
let l_137 = a_39[u32(2)];
let l_138 = a_31[u32(0)];
let l_139 = l_137 * l_138;
l_mut_41 = l_mut_41 + l_139;
let l_140 = l_mut_41 % u32(58);
a_117[u32(2)] = l_140;
let l_141 = l_mut_41 / u32(58);
l_mut_40 = l_141;
l_mut_41 = l_mut_40;
let l_142 = a_39[u32(0)];
let l_143 = a_31[u32(3)];
let l_144 = l_142 * l_143;
l_mut_41 = l_mut_41 + l_144;
let l_145 = a_39[u32(1)];
let l_146 = a_31[u32(2)];
let l_147 = l_145 * l_146;
l_mut_41 = l_mut_41 + l_147;
let l_148 = a_39[u32(2)];
let l_149 = a_31[u32(1)];
let l_150 = l_148 * l_149;
l_mut_41 = l_mut_41 + l_150;
let l_151 = a_39[u32(3)];
let l_152 = a_31[u32(0)];
let l_153 = l_151 * l_152;
l_mut_41 = l_mut_41 + l_153;
let l_154 = l_mut_41 % u32(58);
a_117[u32(3)] = l_154;
let l_155 = l_mut_41 / u32(58);
l_mut_40 = l_155;
l_mut_41 = l_mut_40;
let l_156 = a_39[u32(0)];
let l_157 = a_31[u32(4)];
let l_158 = l_156 * l_157;
l_mut_41 = l_mut_41 + l_158;
let l_159 = a_39[u32(1)];
let l_160 = a_31[u32(3)];
let l_161 = l_159 * l_160;
l_mut_41 = l_mut_41 + l_161;
let l_162 = a_39[u32(2)];
let l_163 = a_31[u32(2)];
let l_164 = l_162 * l_163;
l_mut_41 = l_mut_41 + l_164;
let l_165 = a_39[u32(3)];
let l_166 = a_31[u32(1)];
let l_167 = l_165 * l_166;
l_mut_41 = l_mut_41 + l_167;
let l_168 = a_39[u32(4)];
let l_169 = a_31[u32(0)];
let l_170 = l_168 * l_169;
l_mut_41 = l_mut_41 + l_170;
let l_171 = l_mut_41 % u32(58);
a_117[u32(4)] = l_171;
let l_172 = l_mut_41 / u32(58);
l_mut_40 = l_172;
l_mut_41 = l_mut_40;
let l_173 = a_39[u32(0)];
let l_174 = a_31[u32(5)];
let l_175 = l_173 * l_174;
l_mut_41 = l_mut_41 + l_175;
let l_176 = a_39[u32(1)];
let l_177 = a_31[u32(4)];
let l_178 = l_176 * l_177;
l_mut_41 = l_mut_41 + l_178;
let l_179 = a_39[u32(2)];
let l_180 = a_31[u32(3)];
let l_181 = l_179 * l_180;
l_mut_41 = l_mut_41 + l_181;
let l_182 = a_39[u32(3)];
let l_183 = a_31[u32(2)];
let l_184 = l_182 * l_183;
l_mut_41 = l_mut_41 + l_184;
let l_185 = a_39[u32(4)];
let l_186 = a_31[u32(1)];
let l_187 = l_185 * l_186;
l_mut_41 = l_mut_41 + l_187;
let l_188 = a_39[u32(5)];
let l_189 = a_31[u32(0)];
let l_190 = l_188 * l_189;
l_mut_41 = l_mut_41 + l_190;
let l_191 = l_mut_41 % u32(58);
a_117[u32(5)] = l_191;
let l_192 = l_mut_41 / u32(58);
l_mut_40 = l_192;
l_mut_193 = bool(true);
let l_194 = a_39[u32(3)];
let l_195 = a_117[u32(3)];
let l_196 = u64(l_194);
let l_197 = u64(1) << u32(bitcast<u64>(l_196));
let l_198 = u64(l_195);
let l_199 = u64(1) << u32(bitcast<u64>(l_198));
let l_200 = l_197 | l_199;
let l_201 = l_194 == l_195;
let l_202 = l_mut_30 | l_3;
let l_203 = l_202 & l_200;
let l_204 = l_203 != u64(0);
let l_205 = l_201 || l_204;
if l_205 {
l_mut_193 = bool(false);
}
l_mut_30 = l_mut_30 | l_200;
let l_206 = a_39[u32(4)];
let l_207 = a_117[u32(4)];
let l_208 = u64(l_206);
let l_209 = u64(1) << u32(bitcast<u64>(l_208));
let l_210 = u64(l_207);
let l_211 = u64(1) << u32(bitcast<u64>(l_210));
let l_212 = l_209 | l_211;
let l_213 = l_206 == l_207;
let l_214 = l_mut_30 | l_3;
let l_215 = l_214 & l_212;
let l_216 = l_215 != u64(0);
let l_217 = l_213 || l_216;
if l_217 {
l_mut_193 = bool(false);
}
l_mut_30 = l_mut_30 | l_212;
let l_218 = !l_mut_193;
if l_218 {
l_mut_30 = bitcast<u64>(i64(-1));
}
let l_219 = l_mut_30 | l_3;
let l_220 = workgroup_id.y * info.scalars_u32[0];
let l_221 = l_220 + l_mut_17;
let l_222 = u32(2) * l_221;
let l_223 = u32(bitcast<u64>(l_mut_30));
buffer_4_global[l_222] = l_223;
let l_224 = u32(2) * l_221;
let l_225 = l_224 + u32(1);
let l_226 = l_mut_30 >> u32(bitcast<u64>(u64(32)));
let l_227 = u32(bitcast<u64>(l_226));
buffer_4_global[l_225] = l_227;
let l_228 = a_39[u32(5)];
let l_229 = a_117[u32(5)];
let l_230 = a_31[u32(0)];
let l_231 = u32(2) * l_230;
let l_232 = l_231 % u32(58);
let l_233 = l_230 * l_230;
let l_234 = l_233 % u32(58);
let l_235 = u32(3) * l_234;
let l_236 = l_235 % u32(58);
let l_237 = l_229 << u32(8);
let l_238 = l_228 | l_237;
let l_239 = l_232 << u32(16);
let l_240 = l_238 | l_239;
let l_241 = l_236 << u32(24);
let l_242 = l_240 | l_241;
buffer_5_global[l_221] = l_242;
if l_mut_193 {
l_mut_41 = l_228;
l_mut_243 = l_229;
l_mut_244 = u32(0);
loop {
let l_245 = l_mut_244 < u32(58);
let l_246 = !l_245;
if l_246 {
break;
}
l_mut_247 = l_mut_41;
l_mut_248 = l_mut_243;
let l_249 = u64(l_mut_247);
let l_250 = u64(1) << u32(bitcast<u64>(l_249));
let l_251 = u64(l_mut_248);
let l_252 = u64(1) << u32(bitcast<u64>(l_251));
let l_253 = l_250 | l_252;
let l_254 = l_mut_247 != l_mut_248;
let l_255 = l_219 & l_253;
let l_256 = l_255 == u64(0);
let l_257 = l_254 && l_256;
if l_257 {
let l_258 = &shared_memory_4[l_mut_244];
let l_259 = atomicAdd(l_258, u32(1));let l_260 = l_mut_244 * l_10;
let l_261 = l_14 + l_260;
let l_262 = l_261 + l_259;
buffer_6_global[l_262] = l_mut_17;
}
l_mut_41 = l_mut_41 + l_232;
let l_263 = l_mut_41 >= u32(58);
if l_263 {
l_mut_41 = l_mut_41 - u32(58);
}
l_mut_243 = l_mut_243 + l_236;
let l_264 = l_mut_243 >= u32(58);
if l_264 {
l_mut_243 = l_mut_243 - u32(58);
}
l_mut_244 = l_mut_244 + u32(1);
}
}
l_mut_17 = l_mut_17 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_265 = local_invocation_id.x < u32(58);
if l_265 {
let l_266 = workgroup_id.y * u32(58);
let l_267 = l_266 + local_invocation_id.x;
let l_268 = l_267 * u32(57);
let l_269 = l_268 + workgroup_id.x;
let l_270 = &shared_memory_4[local_invocation_id.x];
let l_271 = atomicLoad(l_270);
buffer_7_global[l_269] = l_271;
}
workgroupBarrier();
let l_272 = local_invocation_id.x == u32(0);
if l_272 {
let l_273 = &buffer_8_global[u32(3)];
let l_274 = atomicAdd(l_273, u32(1));}
}
```
