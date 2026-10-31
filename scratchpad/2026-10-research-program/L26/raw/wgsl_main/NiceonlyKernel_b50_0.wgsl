
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
var<storage, read_write> buffer_4_global: array<atomic<u32>>;

@group(0)
@binding(5)
var<storage, read_write> buffer_5_global: array<u32>;

@group(0)
@binding(6)
var<storage, read_write> buffer_6_global: array<u32>;

struct info_st {
   scalars_u32: array<u32, 8>,
   static_meta: array<u32, 14>,
}

@group(0)
@binding(7)
var<storage, read> info: info_st;

var<workgroup> shared_memory_17: array<u32, 256>;

var<workgroup> shared_memory_18: array<u32, 256>;

var<workgroup> shared_memory_15: array<u64, 512>;

var<workgroup> shared_memory_16: array<u64, 512>;

var<workgroup> shared_memory_13: array<u32, 1792>;

const WORKGROUP_SIZE_X = 256u;
const WORKGROUP_SIZE_Y = 1u;
const WORKGROUP_SIZE_Z = 1u;

@compute
@workgroup_size(256, 1, 1)
fn niceonly_kernel(
    @builtin(global_invocation_id) global_id: vec3<u32>,
    @builtin(local_invocation_id) local_invocation_id: vec3<u32>,
    @builtin(num_workgroups) num_workgroups: vec3<u32>,
    @builtin(subgroup_size) subgroup_size: u32,
    @builtin(subgroup_invocation_id) subgroup_invocation_id: u32,
) {
var a_169: array<u32, 2>;

var a_174: array<u32, 4>;

var l_mut_26: u64;
var l_mut_27: u64;
var l_mut_28: u64;
var l_mut_29: u64;
var l_mut_30: u64;
var l_mut_52: u64;
var l_mut_114: u64;
var l_mut_125: u64;
var l_mut_229: i32;
var l_mut_239: i32;
var l_mut_416: i32;
var l_mut_22: u32;
var l_mut_31: u32;
var l_mut_32: u32;
var l_mut_58: u32;
var l_mut_105: u32;
var l_mut_151: u32;
var l_mut_152: u32;
var l_mut_24: bool;
var l_mut_25: bool;
var l_mut_133: bool;
var l_mut_167: bool;
let l_0 = u32(1) << info.scalars_u32[7];
let l_1 = l_0 - u32(1);
let l_2 = global_id.x & l_1;
let l_3 = num_workgroups.x * WORKGROUP_SIZE_X;
let l_4 = l_3 >> info.scalars_u32[7];
let l_5 = u64(info.scalars_u32[1]);
let l_6 = l_5 << u32(bitcast<u64>(u64(32)));
let l_7 = u64(info.scalars_u32[0]);
let l_8 = l_6 | l_7;
let l_9 = u64(info.scalars_u32[3]);
let l_10 = l_9 << u32(bitcast<u64>(u64(32)));
let l_11 = u64(info.scalars_u32[2]);
let l_12 = l_10 | l_11;
let l_14 = local_invocation_id.x * u32(7);
let l_19 = local_invocation_id.x / subgroup_size;
let l_20 = WORKGROUP_SIZE_X / subgroup_size;
let l_21 = global_id.x >> info.scalars_u32[7];
l_mut_22 = l_21;
let l_23 = l_mut_22 < info.scalars_u32[5];
l_mut_24 = l_23;
l_mut_25 = l_mut_24;
l_mut_26 = u64(0);
l_mut_27 = u64(0);
l_mut_28 = u64(0);
l_mut_29 = u64(0);
l_mut_30 = u64(0);
l_mut_31 = u32(0);
l_mut_32 = u32(0);
loop {
if l_mut_25 {
l_mut_25 = bool(false);
let l_33 = u32(2) * l_mut_22;
let l_34 = buffer_1_global[l_33];
let l_35 = u32(2) * l_mut_22;
let l_36 = l_35 + u32(1);
let l_37 = buffer_1_global[l_36];
let l_38 = u64(l_37);
let l_39 = l_38 << u32(bitcast<u64>(u64(32)));
let l_40 = u64(l_34);
let l_41 = l_39 | l_40;
l_mut_26 = u64(0);
let l_42 = u32(2) * l_mut_22;
let l_43 = l_42 + u32(1);
let l_44 = buffer_6_global[l_43];
let l_45 = u64(l_44);
let l_46 = l_45 << u32(bitcast<u64>(u64(32)));
let l_47 = u32(2) * l_mut_22;
let l_48 = buffer_6_global[l_47];
let l_49 = u64(l_48);
let l_50 = l_46 | l_49;
l_mut_26 = l_50;
let l_51 = l_8 + l_41;
l_mut_52 = l_12;
let l_53 = l_51 < l_8;
if l_53 {
l_mut_52 = l_mut_52 + u64(1);
}
let l_54 = buffer_2_global[l_mut_22];
let l_55 = u64(l_54);
let l_56 = l_51 + l_55;
l_mut_27 = l_56;
l_mut_28 = l_mut_52;
let l_57 = l_mut_27 < l_51;
if l_57 {
l_mut_28 = l_mut_28 + u64(1);
}
l_mut_58 = u32(0);
let l_59 = l_mut_58 << u32(8);
let l_60 = l_37 >> u32(24);
let l_61 = l_60 & u32(255);
let l_62 = l_59 | l_61;
let l_63 = l_62 % u32(6125000);
l_mut_58 = l_63;
let l_64 = l_mut_58 << u32(8);
let l_65 = l_37 >> u32(16);
let l_66 = l_65 & u32(255);
let l_67 = l_64 | l_66;
let l_68 = l_67 % u32(6125000);
l_mut_58 = l_68;
let l_69 = l_mut_58 << u32(8);
let l_70 = l_37 >> u32(8);
let l_71 = l_70 & u32(255);
let l_72 = l_69 | l_71;
let l_73 = l_72 % u32(6125000);
l_mut_58 = l_73;
let l_74 = l_mut_58 << u32(8);
let l_75 = l_37 >> u32(0);
let l_76 = l_75 & u32(255);
let l_77 = l_74 | l_76;
let l_78 = l_77 % u32(6125000);
l_mut_58 = l_78;
let l_79 = l_mut_58 << u32(8);
let l_80 = l_34 >> u32(24);
let l_81 = l_80 & u32(255);
let l_82 = l_79 | l_81;
let l_83 = l_82 % u32(6125000);
l_mut_58 = l_83;
let l_84 = l_mut_58 << u32(8);
let l_85 = l_34 >> u32(16);
let l_86 = l_85 & u32(255);
let l_87 = l_84 | l_86;
let l_88 = l_87 % u32(6125000);
l_mut_58 = l_88;
let l_89 = l_mut_58 << u32(8);
let l_90 = l_34 >> u32(8);
let l_91 = l_90 & u32(255);
let l_92 = l_89 | l_91;
let l_93 = l_92 % u32(6125000);
l_mut_58 = l_93;
let l_94 = l_mut_58 << u32(8);
let l_95 = l_34 >> u32(0);
let l_96 = l_95 & u32(255);
let l_97 = l_94 | l_96;
let l_98 = l_97 % u32(6125000);
l_mut_58 = l_98;
let l_99 = info.scalars_u32[4] + l_mut_58;
let l_100 = l_99 % u32(6125000);
let l_101 = u64(l_100);
let l_102 = l_51 - l_101;
l_mut_29 = l_102;
l_mut_30 = l_mut_52;
let l_103 = u64(l_100);
let l_104 = l_51 < l_103;
if l_104 {
l_mut_30 = l_mut_30 - u64(1);
}
l_mut_58 = u32(0);
l_mut_105 = u32(568272);
loop {
let l_106 = l_mut_58 < l_mut_105;
let l_107 = !l_106;
if l_107 {
break;
}
let l_108 = l_mut_58 + l_mut_105;
let l_109 = l_108 >> u32(1);
let l_110 = buffer_0_global[l_109];
let l_111 = l_110 < l_100;
if l_111 {
let l_112 = l_109 + u32(1);
l_mut_58 = l_112;
} else {
l_mut_105 = l_109;
}
}
let l_113 = l_mut_58 + l_2;
l_mut_31 = l_113;
}
l_mut_105 = u32(0);
l_mut_52 = u64(0);
l_mut_114 = u64(0);
if l_mut_24 {
let l_115 = l_mut_31 / u32(568272);
let l_116 = l_115 * u32(568272);
let l_117 = l_mut_31 - l_116;
let l_118 = u64(l_115);
let l_119 = u64(u32(6125000));
let l_120 = l_118 * l_119;
let l_121 = buffer_0_global[l_117];
let l_122 = u64(l_121);
let l_123 = l_120 + l_122;
let l_124 = l_mut_29 + l_123;
l_mut_125 = l_mut_30;
let l_126 = l_124 < l_mut_29;
if l_126 {
l_mut_125 = l_mut_125 + u64(1);
}
let l_127 = l_mut_125 > l_mut_28;
let l_128 = l_mut_125 == l_mut_28;
let l_129 = l_124 >= l_mut_27;
let l_130 = l_128 && l_129;
let l_131 = l_127 || l_130;
if l_131 {
l_mut_22 = l_mut_22 + l_4;
let l_132 = l_mut_22 < info.scalars_u32[5];
if l_132 {
l_mut_25 = bool(true);
} else {
l_mut_24 = bool(false);
}
} else {
l_mut_133 = bool(false);
let l_134 = u32(2) * l_117;
let l_135 = l_134 + u32(1);
let l_136 = buffer_5_global[l_135];
let l_137 = u64(l_136);
let l_138 = l_137 << u32(bitcast<u64>(u64(32)));
let l_139 = u32(2) * l_117;
let l_140 = buffer_5_global[l_139];
let l_141 = u64(l_140);
let l_142 = l_138 | l_141;
let l_143 = l_142 & l_mut_26;
let l_144 = l_143 != u64(0);
if l_144 {
l_mut_133 = bool(true);
}
let l_145 = !l_mut_133;
if l_145 {
l_mut_105 = u32(1);
l_mut_52 = l_124;
l_mut_114 = l_mut_125;
}
l_mut_31 = l_mut_31 + l_0;
}
}
let l_146 = subgroupExclusiveAdd(l_mut_105);
let l_147 = subgroupAdd(l_mut_105);
let l_148 = !l_mut_24;
let l_149 = subgroupAll(l_148);
let l_150 = subgroup_invocation_id == u32(0);
if l_150 {
shared_memory_17[l_19] = l_147;
l_mut_58 = u32(0);
if l_149 {
l_mut_58 = u32(1);
}
shared_memory_18[l_19] = l_mut_58;
}
workgroupBarrier();
l_mut_58 = l_mut_32;
l_mut_151 = u32(0);
l_mut_133 = bool(true);
l_mut_152 = u32(0);
loop {
let l_153 = l_mut_152 < l_20;
let l_154 = !l_153;
if l_154 {
break;
}
let l_155 = shared_memory_17[l_mut_152];
let l_156 = l_mut_152 < l_19;
if l_156 {
l_mut_58 = l_mut_58 + l_155;
}
l_mut_151 = l_mut_151 + l_155;
let l_157 = shared_memory_18[l_mut_152];
let l_158 = l_157 == u32(0);
if l_158 {
l_mut_133 = bool(false);
}
l_mut_152 = l_mut_152 + u32(1);
}
let l_159 = l_mut_105 != u32(0);
if l_159 {
let l_160 = l_mut_58 + l_146;
shared_memory_15[l_160] = l_mut_52;
shared_memory_16[l_160] = l_mut_114;
}
l_mut_32 = l_mut_32 + l_mut_151;
workgroupBarrier();
l_mut_151 = u32(0);
let l_161 = l_mut_32 >= WORKGROUP_SIZE_X;
if l_161 {
l_mut_151 = WORKGROUP_SIZE_X;
} else {
if l_mut_133 {
l_mut_151 = l_mut_32;
}
}
let l_162 = local_invocation_id.x < l_mut_151;
if l_162 {
let l_163 = l_mut_32 - l_mut_151;
let l_164 = l_163 + local_invocation_id.x;
let l_165 = shared_memory_15[l_164];
let l_166 = shared_memory_16[l_164];
l_mut_167 = bool(true);
l_mut_125 = u64(0);
l_mut_114 = u64(0);
let l_168 = l_mut_167 && bool(false);
if l_168 {
let l_170 = l_165 >> u32(bitcast<u64>(u64(0)));
let l_171 = u32(bitcast<u64>(l_170));
a_169[u32(0)] = l_171;
let l_172 = l_165 >> u32(bitcast<u64>(u64(32)));
let l_173 = u32(bitcast<u64>(l_172));
a_169[u32(1)] = l_173;
a_174[u32(0)] = u32(0);
a_174[u32(1)] = u32(0);
a_174[u32(2)] = u32(0);
a_174[u32(3)] = u32(0);
l_mut_52 = u64(0);
let l_175 = a_169[u32(0)];
let l_176 = u64(l_175);
let l_177 = a_169[u32(0)];
let l_178 = u64(l_177);
let l_179 = l_176 * l_178;
let l_180 = a_174[u32(0)];
let l_181 = u64(l_180);
let l_182 = l_179 + l_181;
let l_183 = l_182 + l_mut_52;
let l_184 = u32(bitcast<u64>(l_183));
a_174[u32(0)] = l_184;
let l_185 = l_183 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_185;
let l_186 = a_169[u32(0)];
let l_187 = u64(l_186);
let l_188 = a_169[u32(1)];
let l_189 = u64(l_188);
let l_190 = l_187 * l_189;
let l_191 = a_174[u32(1)];
let l_192 = u64(l_191);
let l_193 = l_190 + l_192;
let l_194 = l_193 + l_mut_52;
let l_195 = u32(bitcast<u64>(l_194));
a_174[u32(1)] = l_195;
let l_196 = l_194 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_196;
let l_197 = u32(bitcast<u64>(l_mut_52));
a_174[u32(2)] = l_197;
l_mut_52 = u64(0);
let l_198 = a_169[u32(1)];
let l_199 = u64(l_198);
let l_200 = a_169[u32(0)];
let l_201 = u64(l_200);
let l_202 = l_199 * l_201;
let l_203 = a_174[u32(1)];
let l_204 = u64(l_203);
let l_205 = l_202 + l_204;
let l_206 = l_205 + l_mut_52;
let l_207 = u32(bitcast<u64>(l_206));
a_174[u32(1)] = l_207;
let l_208 = l_206 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_208;
let l_209 = a_169[u32(1)];
let l_210 = u64(l_209);
let l_211 = a_169[u32(1)];
let l_212 = u64(l_211);
let l_213 = l_210 * l_212;
let l_214 = a_174[u32(2)];
let l_215 = u64(l_214);
let l_216 = l_213 + l_215;
let l_217 = l_216 + l_mut_52;
let l_218 = u32(bitcast<u64>(l_217));
a_174[u32(2)] = l_218;
let l_219 = l_217 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_219;
let l_220 = u32(bitcast<u64>(l_mut_52));
a_174[u32(3)] = l_220;
let l_221 = l_14 + u32(0);
let l_222 = a_174[u32(0)];
shared_memory_13[l_221] = l_222;
let l_223 = l_14 + u32(1);
let l_224 = a_174[u32(1)];
shared_memory_13[l_223] = l_224;
let l_225 = l_14 + u32(2);
let l_226 = a_174[u32(2)];
shared_memory_13[l_225] = l_226;
let l_227 = l_14 + u32(3);
let l_228 = a_174[u32(3)];
shared_memory_13[l_227] = l_228;
l_mut_229 = i32(3);
loop {
let l_230 = l_mut_229 >= i32(0);
let l_231 = !l_230;
if l_231 {
break;
}
let l_232 = u32(l_mut_229);
let l_233 = l_14 + l_232;
let l_234 = shared_memory_13[l_233];
let l_235 = l_234 != u32(0);
if l_235 {
break;
}
l_mut_229 = l_mut_229 - i32(1);
}
loop {
let l_236 = l_mut_229 >= i32(0);
let l_237 = l_236 && l_mut_167;
let l_238 = !l_237;
if l_238 {
break;
}
l_mut_105 = u32(0);
l_mut_239 = l_mut_229;
loop {
let l_240 = l_mut_239 >= i32(0);
let l_241 = !l_240;
if l_241 {
break;
}
let l_242 = u32(l_mut_239);
let l_243 = l_14 + l_242;
let l_244 = shared_memory_13[l_243];
let l_245 = l_mut_105 << u32(16);
let l_246 = l_244 >> u32(16);
let l_247 = l_245 | l_246;
let l_248 = l_247 / u32(2500);
let l_249 = l_248 * u32(2500);
let l_250 = l_247 - l_249;
let l_251 = l_250 << u32(16);
let l_252 = l_244 & u32(65535);
let l_253 = l_251 | l_252;
let l_254 = l_253 / u32(2500);
let l_255 = l_254 * u32(2500);
let l_256 = l_253 - l_255;
l_mut_105 = l_256;
let l_257 = u32(l_mut_239);
let l_258 = l_14 + l_257;
let l_259 = l_248 << u32(16);
let l_260 = l_259 | l_254;
shared_memory_13[l_258] = l_260;
l_mut_239 = l_mut_239 - i32(1);
}
loop {
let l_261 = l_mut_229 >= i32(0);
let l_262 = !l_261;
if l_262 {
break;
}
let l_263 = u32(l_mut_229);
let l_264 = l_14 + l_263;
let l_265 = shared_memory_13[l_264];
let l_266 = l_265 != u32(0);
if l_266 {
break;
}
l_mut_229 = l_mut_229 - i32(1);
}
l_mut_58 = l_mut_105;
l_mut_52 = u64(0);
let l_267 = l_mut_229 >= i32(0);
if l_267 {
let l_268 = l_mut_58 / u32(50);
let l_269 = l_268 * u32(50);
let l_270 = l_mut_58 - l_269;
l_mut_58 = l_268;
let l_271 = u64(l_270);
let l_272 = u64(1) << u32(bitcast<u64>(l_271));
let l_273 = l_mut_125 & l_272;
l_mut_52 = l_mut_52 | l_273;
l_mut_125 = l_mut_125 | l_272;
let l_274 = l_mut_58 / u32(50);
let l_275 = l_274 * u32(50);
let l_276 = l_mut_58 - l_275;
l_mut_58 = l_274;
let l_277 = u64(l_276);
let l_278 = u64(1) << u32(bitcast<u64>(l_277));
let l_279 = l_mut_125 & l_278;
l_mut_52 = l_mut_52 | l_279;
l_mut_125 = l_mut_125 | l_278;
} else {
loop {
let l_280 = l_mut_58 != u32(0);
let l_281 = !l_280;
if l_281 {
break;
}
let l_282 = l_mut_58 / u32(50);
let l_283 = l_282 * u32(50);
let l_284 = l_mut_58 - l_283;
l_mut_58 = l_282;
let l_285 = u64(l_284);
let l_286 = u64(1) << u32(bitcast<u64>(l_285));
let l_287 = l_mut_125 & l_286;
l_mut_52 = l_mut_52 | l_287;
l_mut_125 = l_mut_125 | l_286;
}
}
let l_288 = l_mut_52 != u64(0);
if l_288 {
l_mut_167 = bool(false);
}
}
if l_mut_167 {
let l_289 = l_14 + u32(0);
shared_memory_13[l_289] = u32(0);
let l_290 = l_14 + u32(1);
shared_memory_13[l_290] = u32(0);
let l_291 = l_14 + u32(2);
shared_memory_13[l_291] = u32(0);
let l_292 = l_14 + u32(3);
shared_memory_13[l_292] = u32(0);
let l_293 = l_14 + u32(4);
shared_memory_13[l_293] = u32(0);
let l_294 = l_14 + u32(5);
shared_memory_13[l_294] = u32(0);
l_mut_52 = u64(0);
let l_295 = a_174[u32(0)];
let l_296 = u64(l_295);
let l_297 = a_169[u32(0)];
let l_298 = u64(l_297);
let l_299 = l_296 * l_298;
let l_300 = l_14 + u32(0);
let l_301 = shared_memory_13[l_300];
let l_302 = u64(l_301);
let l_303 = l_299 + l_302;
let l_304 = l_303 + l_mut_52;
let l_305 = l_14 + u32(0);
let l_306 = u32(bitcast<u64>(l_304));
shared_memory_13[l_305] = l_306;
let l_307 = l_304 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_307;
let l_308 = a_174[u32(0)];
let l_309 = u64(l_308);
let l_310 = a_169[u32(1)];
let l_311 = u64(l_310);
let l_312 = l_309 * l_311;
let l_313 = l_14 + u32(1);
let l_314 = shared_memory_13[l_313];
let l_315 = u64(l_314);
let l_316 = l_312 + l_315;
let l_317 = l_316 + l_mut_52;
let l_318 = l_14 + u32(1);
let l_319 = u32(bitcast<u64>(l_317));
shared_memory_13[l_318] = l_319;
let l_320 = l_317 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_320;
let l_321 = l_14 + u32(2);
let l_322 = u32(bitcast<u64>(l_mut_52));
shared_memory_13[l_321] = l_322;
l_mut_52 = u64(0);
let l_323 = a_174[u32(1)];
let l_324 = u64(l_323);
let l_325 = a_169[u32(0)];
let l_326 = u64(l_325);
let l_327 = l_324 * l_326;
let l_328 = l_14 + u32(1);
let l_329 = shared_memory_13[l_328];
let l_330 = u64(l_329);
let l_331 = l_327 + l_330;
let l_332 = l_331 + l_mut_52;
let l_333 = l_14 + u32(1);
let l_334 = u32(bitcast<u64>(l_332));
shared_memory_13[l_333] = l_334;
let l_335 = l_332 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_335;
let l_336 = a_174[u32(1)];
let l_337 = u64(l_336);
let l_338 = a_169[u32(1)];
let l_339 = u64(l_338);
let l_340 = l_337 * l_339;
let l_341 = l_14 + u32(2);
let l_342 = shared_memory_13[l_341];
let l_343 = u64(l_342);
let l_344 = l_340 + l_343;
let l_345 = l_344 + l_mut_52;
let l_346 = l_14 + u32(2);
let l_347 = u32(bitcast<u64>(l_345));
shared_memory_13[l_346] = l_347;
let l_348 = l_345 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_348;
let l_349 = l_14 + u32(3);
let l_350 = u32(bitcast<u64>(l_mut_52));
shared_memory_13[l_349] = l_350;
l_mut_52 = u64(0);
let l_351 = a_174[u32(2)];
let l_352 = u64(l_351);
let l_353 = a_169[u32(0)];
let l_354 = u64(l_353);
let l_355 = l_352 * l_354;
let l_356 = l_14 + u32(2);
let l_357 = shared_memory_13[l_356];
let l_358 = u64(l_357);
let l_359 = l_355 + l_358;
let l_360 = l_359 + l_mut_52;
let l_361 = l_14 + u32(2);
let l_362 = u32(bitcast<u64>(l_360));
shared_memory_13[l_361] = l_362;
let l_363 = l_360 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_363;
let l_364 = a_174[u32(2)];
let l_365 = u64(l_364);
let l_366 = a_169[u32(1)];
let l_367 = u64(l_366);
let l_368 = l_365 * l_367;
let l_369 = l_14 + u32(3);
let l_370 = shared_memory_13[l_369];
let l_371 = u64(l_370);
let l_372 = l_368 + l_371;
let l_373 = l_372 + l_mut_52;
let l_374 = l_14 + u32(3);
let l_375 = u32(bitcast<u64>(l_373));
shared_memory_13[l_374] = l_375;
let l_376 = l_373 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_376;
let l_377 = l_14 + u32(4);
let l_378 = u32(bitcast<u64>(l_mut_52));
shared_memory_13[l_377] = l_378;
l_mut_52 = u64(0);
let l_379 = a_174[u32(3)];
let l_380 = u64(l_379);
let l_381 = a_169[u32(0)];
let l_382 = u64(l_381);
let l_383 = l_380 * l_382;
let l_384 = l_14 + u32(3);
let l_385 = shared_memory_13[l_384];
let l_386 = u64(l_385);
let l_387 = l_383 + l_386;
let l_388 = l_387 + l_mut_52;
let l_389 = l_14 + u32(3);
let l_390 = u32(bitcast<u64>(l_388));
shared_memory_13[l_389] = l_390;
let l_391 = l_388 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_391;
let l_392 = a_174[u32(3)];
let l_393 = u64(l_392);
let l_394 = a_169[u32(1)];
let l_395 = u64(l_394);
let l_396 = l_393 * l_395;
let l_397 = l_14 + u32(4);
let l_398 = shared_memory_13[l_397];
let l_399 = u64(l_398);
let l_400 = l_396 + l_399;
let l_401 = l_400 + l_mut_52;
let l_402 = l_14 + u32(4);
let l_403 = u32(bitcast<u64>(l_401));
shared_memory_13[l_402] = l_403;
let l_404 = l_401 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_404;
let l_405 = l_14 + u32(5);
let l_406 = u32(bitcast<u64>(l_mut_52));
shared_memory_13[l_405] = l_406;
l_mut_239 = i32(5);
loop {
let l_407 = l_mut_239 >= i32(0);
let l_408 = !l_407;
if l_408 {
break;
}
let l_409 = u32(l_mut_239);
let l_410 = l_14 + l_409;
let l_411 = shared_memory_13[l_410];
let l_412 = l_411 != u32(0);
if l_412 {
break;
}
l_mut_239 = l_mut_239 - i32(1);
}
loop {
let l_413 = l_mut_239 >= i32(0);
let l_414 = l_413 && l_mut_167;
let l_415 = !l_414;
if l_415 {
break;
}
l_mut_105 = u32(0);
l_mut_416 = l_mut_239;
loop {
let l_417 = l_mut_416 >= i32(0);
let l_418 = !l_417;
if l_418 {
break;
}
let l_419 = u32(l_mut_416);
let l_420 = l_14 + l_419;
let l_421 = shared_memory_13[l_420];
let l_422 = l_mut_105 << u32(16);
let l_423 = l_421 >> u32(16);
let l_424 = l_422 | l_423;
let l_425 = l_424 / u32(2500);
let l_426 = l_425 * u32(2500);
let l_427 = l_424 - l_426;
let l_428 = l_427 << u32(16);
let l_429 = l_421 & u32(65535);
let l_430 = l_428 | l_429;
let l_431 = l_430 / u32(2500);
let l_432 = l_431 * u32(2500);
let l_433 = l_430 - l_432;
l_mut_105 = l_433;
let l_434 = u32(l_mut_416);
let l_435 = l_14 + l_434;
let l_436 = l_425 << u32(16);
let l_437 = l_436 | l_431;
shared_memory_13[l_435] = l_437;
l_mut_416 = l_mut_416 - i32(1);
}
loop {
let l_438 = l_mut_239 >= i32(0);
let l_439 = !l_438;
if l_439 {
break;
}
let l_440 = u32(l_mut_239);
let l_441 = l_14 + l_440;
let l_442 = shared_memory_13[l_441];
let l_443 = l_442 != u32(0);
if l_443 {
break;
}
l_mut_239 = l_mut_239 - i32(1);
}
l_mut_58 = l_mut_105;
l_mut_52 = u64(0);
let l_444 = l_mut_239 >= i32(0);
if l_444 {
let l_445 = l_mut_58 / u32(50);
let l_446 = l_445 * u32(50);
let l_447 = l_mut_58 - l_446;
l_mut_58 = l_445;
let l_448 = u64(l_447);
let l_449 = u64(1) << u32(bitcast<u64>(l_448));
let l_450 = l_mut_125 & l_449;
l_mut_52 = l_mut_52 | l_450;
l_mut_125 = l_mut_125 | l_449;
let l_451 = l_mut_58 / u32(50);
let l_452 = l_451 * u32(50);
let l_453 = l_mut_58 - l_452;
l_mut_58 = l_451;
let l_454 = u64(l_453);
let l_455 = u64(1) << u32(bitcast<u64>(l_454));
let l_456 = l_mut_125 & l_455;
l_mut_52 = l_mut_52 | l_456;
l_mut_125 = l_mut_125 | l_455;
} else {
loop {
let l_457 = l_mut_58 != u32(0);
let l_458 = !l_457;
if l_458 {
break;
}
let l_459 = l_mut_58 / u32(50);
let l_460 = l_459 * u32(50);
let l_461 = l_mut_58 - l_460;
l_mut_58 = l_459;
let l_462 = u64(l_461);
let l_463 = u64(1) << u32(bitcast<u64>(l_462));
let l_464 = l_mut_125 & l_463;
l_mut_52 = l_mut_52 | l_464;
l_mut_125 = l_mut_125 | l_463;
}
}
let l_465 = l_mut_52 != u64(0);
if l_465 {
l_mut_167 = bool(false);
}
}
}
}
if l_mut_167 {
let l_466 = u32(bitcast<u64>(l_mut_125));
let l_467 = countOneBits(l_466);
let l_468 = l_mut_125 >> u32(bitcast<u64>(u64(32)));
let l_469 = u32(bitcast<u64>(l_468));
let l_470 = countOneBits(l_469);
let l_471 = l_467 + l_470;
l_mut_105 = l_471;
let l_472 = l_mut_105 == u32(50);
let l_473 = bool(true) || l_472;
if l_473 {
let l_474 = &buffer_4_global[u32(0)];
let l_475 = atomicAdd(l_474, u32(1));let l_476 = l_475 < info.scalars_u32[6];
if l_476 {
let l_477 = u32(4) * l_475;
let l_478 = u32(bitcast<u64>(l_165));
buffer_3_global[l_477] = l_478;
let l_479 = l_477 + u32(1);
let l_480 = l_165 >> u32(bitcast<u64>(u64(32)));
let l_481 = u32(bitcast<u64>(l_480));
buffer_3_global[l_479] = l_481;
let l_482 = l_477 + u32(2);
let l_483 = u32(bitcast<u64>(l_166));
buffer_3_global[l_482] = l_483;
let l_484 = l_477 + u32(3);
let l_485 = l_166 >> u32(bitcast<u64>(u64(32)));
let l_486 = u32(bitcast<u64>(l_485));
buffer_3_global[l_484] = l_486;
}
}
}
}
l_mut_32 = l_mut_32 - l_mut_151;
let l_487 = l_mut_32 == u32(0);
let l_488 = l_mut_133 && l_487;
if l_488 {
break;
}
}
}
```
