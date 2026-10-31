
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

var<workgroup> shared_memory_13: array<u32, 768>;

const WORKGROUP_SIZE_X = 256u;
const WORKGROUP_SIZE_Y = 1u;
const WORKGROUP_SIZE_Z = 1u;

@compute
@workgroup_size(256, 1, 1)
fn niceonly_kernel(
    @builtin(global_invocation_id) global_id: vec3<u32>,
    @builtin(local_invocation_id) local_invocation_id: vec3<u32>,
    @builtin(num_workgroups) num_workgroups: vec3<u32>,
) {
var a_132: array<u32, 2>;

var a_137: array<u32, 3>;

var a_172: array<u32, 3>;

var a_221: array<u32, 3>;

var a_324: array<u32, 1>;

var a_327: array<u32, 2>;

var l_mut_119: bool;
var l_mut_344: i32;
var l_mut_354: i32;
var l_mut_452: i32;
var l_mut_16: u32;
var l_mut_46: u32;
var l_mut_94: u32;
var l_mut_145: u32;
var l_mut_277: u32;
var l_mut_279: u32;
var l_mut_28: u64;
var l_mut_39: u64;
var l_mut_44: u64;
var l_mut_91: u64;
var l_mut_270: u64;
var l_mut_271: u64;
var l_mut_272: u64;
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
let l_14 = local_invocation_id.x * u32(3);
let l_15 = global_id.x >> info.scalars_u32[7];
l_mut_16 = l_15;
loop {
let l_17 = l_mut_16 < info.scalars_u32[5];
let l_18 = !l_17;
if l_18 {
break;
}
let l_19 = u32(2) * l_mut_16;
let l_20 = buffer_1_global[l_19];
let l_21 = u32(2) * l_mut_16;
let l_22 = l_21 + u32(1);
let l_23 = buffer_1_global[l_22];
let l_24 = u64(l_23);
let l_25 = l_24 << u32(bitcast<u64>(u64(32)));
let l_26 = u64(l_20);
let l_27 = l_25 | l_26;
l_mut_28 = u64(0);
let l_29 = u32(2) * l_mut_16;
let l_30 = l_29 + u32(1);
let l_31 = buffer_6_global[l_30];
let l_32 = u64(l_31);
let l_33 = l_32 << u32(bitcast<u64>(u64(32)));
let l_34 = u32(2) * l_mut_16;
let l_35 = buffer_6_global[l_34];
let l_36 = u64(l_35);
let l_37 = l_33 | l_36;
l_mut_28 = l_37;
let l_38 = l_8 + l_27;
l_mut_39 = l_12;
let l_40 = l_38 < l_8;
if l_40 {
l_mut_39 = l_mut_39 + u64(1);
}
let l_41 = buffer_2_global[l_mut_16];
let l_42 = u64(l_41);
let l_43 = l_38 + l_42;
l_mut_44 = l_mut_39;
let l_45 = l_43 < l_38;
if l_45 {
l_mut_44 = l_mut_44 + u64(1);
}
l_mut_46 = u32(0);
let l_47 = l_mut_46 << u32(8);
let l_48 = l_23 >> u32(24);
let l_49 = l_48 & u32(255);
let l_50 = l_47 | l_49;
let l_51 = l_50 % u32(783000);
l_mut_46 = l_51;
let l_52 = l_mut_46 << u32(8);
let l_53 = l_23 >> u32(16);
let l_54 = l_53 & u32(255);
let l_55 = l_52 | l_54;
let l_56 = l_55 % u32(783000);
l_mut_46 = l_56;
let l_57 = l_mut_46 << u32(8);
let l_58 = l_23 >> u32(8);
let l_59 = l_58 & u32(255);
let l_60 = l_57 | l_59;
let l_61 = l_60 % u32(783000);
l_mut_46 = l_61;
let l_62 = l_mut_46 << u32(8);
let l_63 = l_23 >> u32(0);
let l_64 = l_63 & u32(255);
let l_65 = l_62 | l_64;
let l_66 = l_65 % u32(783000);
l_mut_46 = l_66;
let l_67 = l_mut_46 << u32(8);
let l_68 = l_20 >> u32(24);
let l_69 = l_68 & u32(255);
let l_70 = l_67 | l_69;
let l_71 = l_70 % u32(783000);
l_mut_46 = l_71;
let l_72 = l_mut_46 << u32(8);
let l_73 = l_20 >> u32(16);
let l_74 = l_73 & u32(255);
let l_75 = l_72 | l_74;
let l_76 = l_75 % u32(783000);
l_mut_46 = l_76;
let l_77 = l_mut_46 << u32(8);
let l_78 = l_20 >> u32(8);
let l_79 = l_78 & u32(255);
let l_80 = l_77 | l_79;
let l_81 = l_80 % u32(783000);
l_mut_46 = l_81;
let l_82 = l_mut_46 << u32(8);
let l_83 = l_20 >> u32(0);
let l_84 = l_83 & u32(255);
let l_85 = l_82 | l_84;
let l_86 = l_85 % u32(783000);
l_mut_46 = l_86;
let l_87 = info.scalars_u32[4] + l_mut_46;
let l_88 = l_87 % u32(783000);
let l_89 = u64(l_88);
let l_90 = l_38 - l_89;
l_mut_91 = l_mut_39;
let l_92 = u64(l_88);
let l_93 = l_38 < l_92;
if l_93 {
l_mut_91 = l_mut_91 - u64(1);
}
l_mut_46 = u32(0);
l_mut_94 = u32(24908);
loop {
let l_95 = l_mut_46 < l_mut_94;
let l_96 = !l_95;
if l_96 {
break;
}
let l_97 = l_mut_46 + l_mut_94;
let l_98 = l_97 >> u32(1);
let l_99 = buffer_0_global[l_98];
let l_100 = l_99 < l_88;
if l_100 {
let l_101 = l_98 + u32(1);
l_mut_46 = l_101;
} else {
l_mut_94 = l_98;
}
}
let l_102 = l_mut_46 + l_2;
l_mut_46 = l_102;
loop {
let l_103 = l_mut_46 / u32(24908);
let l_104 = l_103 * u32(24908);
let l_105 = l_mut_46 - l_104;
let l_106 = u64(l_103);
let l_107 = u64(u32(783000));
let l_108 = l_106 * l_107;
let l_109 = buffer_0_global[l_105];
let l_110 = u64(l_109);
let l_111 = l_108 + l_110;
let l_112 = l_90 + l_111;
l_mut_39 = l_mut_91;
let l_113 = l_112 < l_90;
if l_113 {
l_mut_39 = l_mut_39 + u64(1);
}
let l_114 = l_mut_39 > l_mut_44;
let l_115 = l_mut_39 == l_mut_44;
let l_116 = l_112 >= l_43;
let l_117 = l_115 && l_116;
let l_118 = l_114 || l_117;
if l_118 {
break;
}
l_mut_119 = bool(false);
let l_120 = u32(2) * l_105;
let l_121 = l_120 + u32(1);
let l_122 = buffer_5_global[l_121];
let l_123 = u64(l_122);
let l_124 = l_123 << u32(bitcast<u64>(u64(32)));
let l_125 = u32(2) * l_105;
let l_126 = buffer_5_global[l_125];
let l_127 = u64(l_126);
let l_128 = l_124 | l_127;
let l_129 = l_128 & l_mut_28;
let l_130 = l_129 != u64(0);
if l_130 {
l_mut_119 = bool(true);
}
let l_131 = !l_mut_119;
if l_131 {
l_mut_119 = bool(true);
if l_mut_119 {
let l_133 = l_112 >> u32(bitcast<u64>(u64(0)));
let l_134 = u32(bitcast<u64>(l_133));
let l_135 = l_134 & u32(65535);
a_132[u32(0)] = l_135;
let l_136 = l_134 >> u32(16);
a_132[u32(1)] = l_136;
let l_138 = a_132[u32(1)];
let l_139 = l_138 * u32(11536);
let l_140 = a_132[u32(0)];
let l_141 = l_139 + l_140;
let l_142 = l_141 / u32(27000);
let l_143 = l_142 * u32(27000);
let l_144 = l_141 - l_143;
l_mut_145 = l_144;
let l_146 = l_138 * u32(2);
let l_147 = l_146 + l_142;
let l_148 = l_147 >> u32(16);
a_132[u32(1)] = l_148;
let l_149 = l_147 & u32(65535);
a_132[u32(0)] = l_149;
a_137[u32(0)] = l_mut_145;
let l_150 = a_132[u32(1)];
let l_151 = l_150 * u32(11536);
let l_152 = a_132[u32(0)];
let l_153 = l_151 + l_152;
let l_154 = l_153 / u32(27000);
let l_155 = l_154 * u32(27000);
let l_156 = l_153 - l_155;
l_mut_145 = l_156;
let l_157 = l_150 * u32(2);
let l_158 = l_157 + l_154;
let l_159 = l_158 >> u32(16);
a_132[u32(1)] = l_159;
let l_160 = l_158 & u32(65535);
a_132[u32(0)] = l_160;
a_137[u32(1)] = l_mut_145;
let l_161 = a_132[u32(1)];
let l_162 = l_161 * u32(11536);
let l_163 = a_132[u32(0)];
let l_164 = l_162 + l_163;
let l_165 = l_164 / u32(27000);
let l_166 = l_165 * u32(27000);
let l_167 = l_164 - l_166;
l_mut_145 = l_167;
let l_168 = l_161 * u32(2);
let l_169 = l_168 + l_165;
let l_170 = l_169 >> u32(16);
a_132[u32(1)] = l_170;
let l_171 = l_169 & u32(65535);
a_132[u32(0)] = l_171;
a_137[u32(2)] = l_mut_145;
a_172[u32(0)] = u32(0);
a_172[u32(1)] = u32(0);
a_172[u32(2)] = u32(0);
l_mut_145 = u32(0);
let l_173 = a_137[u32(0)];
let l_174 = a_137[u32(0)];
let l_175 = l_173 * l_174;
let l_176 = a_172[u32(0)];
let l_177 = l_175 + l_176;
let l_178 = l_177 + l_mut_145;
let l_179 = l_178 % u32(27000);
a_172[u32(0)] = l_179;
let l_180 = l_178 / u32(27000);
l_mut_145 = l_180;
let l_181 = a_137[u32(0)];
let l_182 = a_137[u32(1)];
let l_183 = l_181 * l_182;
let l_184 = a_172[u32(1)];
let l_185 = l_183 + l_184;
let l_186 = l_185 + l_mut_145;
let l_187 = l_186 % u32(27000);
a_172[u32(1)] = l_187;
let l_188 = l_186 / u32(27000);
l_mut_145 = l_188;
let l_189 = a_137[u32(0)];
let l_190 = a_137[u32(2)];
let l_191 = l_189 * l_190;
let l_192 = a_172[u32(2)];
let l_193 = l_191 + l_192;
let l_194 = l_193 + l_mut_145;
let l_195 = l_194 % u32(27000);
a_172[u32(2)] = l_195;
let l_196 = l_194 / u32(27000);
l_mut_145 = l_196;
l_mut_145 = u32(0);
let l_197 = a_137[u32(1)];
let l_198 = a_137[u32(0)];
let l_199 = l_197 * l_198;
let l_200 = a_172[u32(1)];
let l_201 = l_199 + l_200;
let l_202 = l_201 + l_mut_145;
let l_203 = l_202 % u32(27000);
a_172[u32(1)] = l_203;
let l_204 = l_202 / u32(27000);
l_mut_145 = l_204;
let l_205 = a_137[u32(1)];
let l_206 = a_137[u32(1)];
let l_207 = l_205 * l_206;
let l_208 = a_172[u32(2)];
let l_209 = l_207 + l_208;
let l_210 = l_209 + l_mut_145;
let l_211 = l_210 % u32(27000);
a_172[u32(2)] = l_211;
let l_212 = l_210 / u32(27000);
l_mut_145 = l_212;
l_mut_145 = u32(0);
let l_213 = a_137[u32(2)];
let l_214 = a_137[u32(0)];
let l_215 = l_213 * l_214;
let l_216 = a_172[u32(2)];
let l_217 = l_215 + l_216;
let l_218 = l_217 + l_mut_145;
let l_219 = l_218 % u32(27000);
a_172[u32(2)] = l_219;
let l_220 = l_218 / u32(27000);
l_mut_145 = l_220;
a_221[u32(0)] = u32(0);
a_221[u32(1)] = u32(0);
a_221[u32(2)] = u32(0);
l_mut_145 = u32(0);
let l_222 = a_172[u32(0)];
let l_223 = a_137[u32(0)];
let l_224 = l_222 * l_223;
let l_225 = a_221[u32(0)];
let l_226 = l_224 + l_225;
let l_227 = l_226 + l_mut_145;
let l_228 = l_227 % u32(27000);
a_221[u32(0)] = l_228;
let l_229 = l_227 / u32(27000);
l_mut_145 = l_229;
let l_230 = a_172[u32(0)];
let l_231 = a_137[u32(1)];
let l_232 = l_230 * l_231;
let l_233 = a_221[u32(1)];
let l_234 = l_232 + l_233;
let l_235 = l_234 + l_mut_145;
let l_236 = l_235 % u32(27000);
a_221[u32(1)] = l_236;
let l_237 = l_235 / u32(27000);
l_mut_145 = l_237;
let l_238 = a_172[u32(0)];
let l_239 = a_137[u32(2)];
let l_240 = l_238 * l_239;
let l_241 = a_221[u32(2)];
let l_242 = l_240 + l_241;
let l_243 = l_242 + l_mut_145;
let l_244 = l_243 % u32(27000);
a_221[u32(2)] = l_244;
let l_245 = l_243 / u32(27000);
l_mut_145 = l_245;
l_mut_145 = u32(0);
let l_246 = a_172[u32(1)];
let l_247 = a_137[u32(0)];
let l_248 = l_246 * l_247;
let l_249 = a_221[u32(1)];
let l_250 = l_248 + l_249;
let l_251 = l_250 + l_mut_145;
let l_252 = l_251 % u32(27000);
a_221[u32(1)] = l_252;
let l_253 = l_251 / u32(27000);
l_mut_145 = l_253;
let l_254 = a_172[u32(1)];
let l_255 = a_137[u32(1)];
let l_256 = l_254 * l_255;
let l_257 = a_221[u32(2)];
let l_258 = l_256 + l_257;
let l_259 = l_258 + l_mut_145;
let l_260 = l_259 % u32(27000);
a_221[u32(2)] = l_260;
let l_261 = l_259 / u32(27000);
l_mut_145 = l_261;
l_mut_145 = u32(0);
let l_262 = a_172[u32(2)];
let l_263 = a_137[u32(0)];
let l_264 = l_262 * l_263;
let l_265 = a_221[u32(2)];
let l_266 = l_264 + l_265;
let l_267 = l_266 + l_mut_145;
let l_268 = l_267 % u32(27000);
a_221[u32(2)] = l_268;
let l_269 = l_267 / u32(27000);
l_mut_145 = l_269;
l_mut_270 = u64(0);
l_mut_271 = u64(0);
l_mut_272 = u64(0);
l_mut_145 = u32(0);
loop {
let l_273 = l_mut_145 < u32(2);
let l_274 = !l_273;
if l_274 {
break;
}
let l_275 = l_mut_145 == u32(0);
if l_275 {
let l_276 = a_172[u32(0)];
l_mut_277 = l_276;
} else {
let l_278 = a_221[u32(0)];
l_mut_277 = l_278;
}
l_mut_279 = l_mut_277;
let l_280 = l_mut_279 % u32(30);
l_mut_279 = l_mut_279 / u32(30);
let l_281 = u64(l_280);
let l_282 = u64(1) << u32(bitcast<u64>(l_281));
let l_283 = l_mut_270 & l_282;
l_mut_272 = l_mut_272 | l_283;
l_mut_270 = l_mut_270 | l_282;
let l_284 = l_mut_279 % u32(30);
l_mut_279 = l_mut_279 / u32(30);
let l_285 = u64(l_284);
let l_286 = u64(1) << u32(bitcast<u64>(l_285));
let l_287 = l_mut_270 & l_286;
l_mut_272 = l_mut_272 | l_287;
l_mut_270 = l_mut_270 | l_286;
let l_288 = l_mut_279 % u32(30);
l_mut_279 = l_mut_279 / u32(30);
let l_289 = u64(l_288);
let l_290 = u64(1) << u32(bitcast<u64>(l_289));
let l_291 = l_mut_270 & l_290;
l_mut_272 = l_mut_272 | l_291;
l_mut_270 = l_mut_270 | l_290;
let l_292 = l_mut_145 == u32(0);
if l_292 {
let l_293 = a_172[u32(1)];
l_mut_279 = l_293;
} else {
let l_294 = a_221[u32(1)];
l_mut_279 = l_294;
}
l_mut_277 = l_mut_279;
let l_295 = l_mut_277 % u32(30);
l_mut_277 = l_mut_277 / u32(30);
let l_296 = u64(l_295);
let l_297 = u64(1) << u32(bitcast<u64>(l_296));
let l_298 = l_mut_270 & l_297;
l_mut_272 = l_mut_272 | l_298;
l_mut_270 = l_mut_270 | l_297;
let l_299 = l_mut_277 % u32(30);
l_mut_277 = l_mut_277 / u32(30);
let l_300 = u64(l_299);
let l_301 = u64(1) << u32(bitcast<u64>(l_300));
let l_302 = l_mut_270 & l_301;
l_mut_272 = l_mut_272 | l_302;
l_mut_270 = l_mut_270 | l_301;
let l_303 = l_mut_277 % u32(30);
l_mut_277 = l_mut_277 / u32(30);
let l_304 = u64(l_303);
let l_305 = u64(1) << u32(bitcast<u64>(l_304));
let l_306 = l_mut_270 & l_305;
l_mut_272 = l_mut_272 | l_306;
l_mut_270 = l_mut_270 | l_305;
let l_307 = l_mut_145 == u32(0);
if l_307 {
let l_308 = a_172[u32(2)];
l_mut_279 = l_308;
} else {
let l_309 = a_221[u32(2)];
l_mut_279 = l_309;
}
l_mut_277 = l_mut_279;
let l_310 = l_mut_277 % u32(30);
l_mut_277 = l_mut_277 / u32(30);
let l_311 = u64(l_310);
let l_312 = u64(1) << u32(bitcast<u64>(l_311));
let l_313 = l_mut_270 & l_312;
l_mut_272 = l_mut_272 | l_313;
l_mut_270 = l_mut_270 | l_312;
let l_314 = l_mut_277 % u32(30);
l_mut_277 = l_mut_277 / u32(30);
let l_315 = u64(l_314);
let l_316 = u64(1) << u32(bitcast<u64>(l_315));
let l_317 = l_mut_270 & l_316;
l_mut_272 = l_mut_272 | l_317;
l_mut_270 = l_mut_270 | l_316;
let l_318 = l_mut_277 % u32(30);
l_mut_277 = l_mut_277 / u32(30);
let l_319 = u64(l_318);
let l_320 = u64(1) << u32(bitcast<u64>(l_319));
let l_321 = l_mut_270 & l_320;
l_mut_272 = l_mut_272 | l_321;
l_mut_270 = l_mut_270 | l_320;
l_mut_145 = l_mut_145 + u32(1);
}
let l_322 = l_mut_272 != u64(0);
if l_322 {
l_mut_119 = bool(false);
}
}
l_mut_272 = u64(0);
l_mut_271 = u64(0);
let l_323 = l_mut_119 && bool(false);
if l_323 {
let l_325 = l_112 >> u32(bitcast<u64>(u64(0)));
let l_326 = u32(bitcast<u64>(l_325));
a_324[u32(0)] = l_326;
a_327[u32(0)] = u32(0);
a_327[u32(1)] = u32(0);
l_mut_270 = u64(0);
let l_328 = a_324[u32(0)];
let l_329 = u64(l_328);
let l_330 = a_324[u32(0)];
let l_331 = u64(l_330);
let l_332 = l_329 * l_331;
let l_333 = a_327[u32(0)];
let l_334 = u64(l_333);
let l_335 = l_332 + l_334;
let l_336 = l_335 + l_mut_270;
let l_337 = u32(bitcast<u64>(l_336));
a_327[u32(0)] = l_337;
let l_338 = l_336 >> u32(bitcast<u64>(u64(32)));
l_mut_270 = l_338;
let l_339 = u32(bitcast<u64>(l_mut_270));
a_327[u32(1)] = l_339;
let l_340 = l_14 + u32(0);
let l_341 = a_327[u32(0)];
shared_memory_13[l_340] = l_341;
let l_342 = l_14 + u32(1);
let l_343 = a_327[u32(1)];
shared_memory_13[l_342] = l_343;
l_mut_344 = i32(1);
loop {
let l_345 = l_mut_344 >= i32(0);
let l_346 = !l_345;
if l_346 {
break;
}
let l_347 = u32(l_mut_344);
let l_348 = l_14 + l_347;
let l_349 = shared_memory_13[l_348];
let l_350 = l_349 != u32(0);
if l_350 {
break;
}
l_mut_344 = l_mut_344 - i32(1);
}
loop {
let l_351 = l_mut_344 >= i32(0);
let l_352 = l_351 && l_mut_119;
let l_353 = !l_352;
if l_353 {
break;
}
l_mut_279 = u32(0);
l_mut_354 = l_mut_344;
loop {
let l_355 = l_mut_354 >= i32(0);
let l_356 = !l_355;
if l_356 {
break;
}
let l_357 = u32(l_mut_354);
let l_358 = l_14 + l_357;
let l_359 = shared_memory_13[l_358];
let l_360 = l_mut_279 << u32(16);
let l_361 = l_359 >> u32(16);
let l_362 = l_360 | l_361;
let l_363 = l_362 / u32(27000);
let l_364 = l_363 * u32(27000);
let l_365 = l_362 - l_364;
let l_366 = l_365 << u32(16);
let l_367 = l_359 & u32(65535);
let l_368 = l_366 | l_367;
let l_369 = l_368 / u32(27000);
let l_370 = l_369 * u32(27000);
let l_371 = l_368 - l_370;
l_mut_279 = l_371;
let l_372 = u32(l_mut_354);
let l_373 = l_14 + l_372;
let l_374 = l_363 << u32(16);
let l_375 = l_374 | l_369;
shared_memory_13[l_373] = l_375;
l_mut_354 = l_mut_354 - i32(1);
}
loop {
let l_376 = l_mut_344 >= i32(0);
let l_377 = !l_376;
if l_377 {
break;
}
let l_378 = u32(l_mut_344);
let l_379 = l_14 + l_378;
let l_380 = shared_memory_13[l_379];
let l_381 = l_380 != u32(0);
if l_381 {
break;
}
l_mut_344 = l_mut_344 - i32(1);
}
l_mut_277 = l_mut_279;
l_mut_270 = u64(0);
let l_382 = l_mut_344 >= i32(0);
if l_382 {
let l_383 = l_mut_277 / u32(30);
let l_384 = l_383 * u32(30);
let l_385 = l_mut_277 - l_384;
l_mut_277 = l_383;
let l_386 = u64(l_385);
let l_387 = u64(1) << u32(bitcast<u64>(l_386));
let l_388 = l_mut_272 & l_387;
l_mut_270 = l_mut_270 | l_388;
l_mut_272 = l_mut_272 | l_387;
let l_389 = l_mut_277 / u32(30);
let l_390 = l_389 * u32(30);
let l_391 = l_mut_277 - l_390;
l_mut_277 = l_389;
let l_392 = u64(l_391);
let l_393 = u64(1) << u32(bitcast<u64>(l_392));
let l_394 = l_mut_272 & l_393;
l_mut_270 = l_mut_270 | l_394;
l_mut_272 = l_mut_272 | l_393;
let l_395 = l_mut_277 / u32(30);
let l_396 = l_395 * u32(30);
let l_397 = l_mut_277 - l_396;
l_mut_277 = l_395;
let l_398 = u64(l_397);
let l_399 = u64(1) << u32(bitcast<u64>(l_398));
let l_400 = l_mut_272 & l_399;
l_mut_270 = l_mut_270 | l_400;
l_mut_272 = l_mut_272 | l_399;
} else {
loop {
let l_401 = l_mut_277 != u32(0);
let l_402 = !l_401;
if l_402 {
break;
}
let l_403 = l_mut_277 / u32(30);
let l_404 = l_403 * u32(30);
let l_405 = l_mut_277 - l_404;
l_mut_277 = l_403;
let l_406 = u64(l_405);
let l_407 = u64(1) << u32(bitcast<u64>(l_406));
let l_408 = l_mut_272 & l_407;
l_mut_270 = l_mut_270 | l_408;
l_mut_272 = l_mut_272 | l_407;
}
}
let l_409 = l_mut_270 != u64(0);
if l_409 {
l_mut_119 = bool(false);
}
}
if l_mut_119 {
let l_410 = l_14 + u32(0);
shared_memory_13[l_410] = u32(0);
let l_411 = l_14 + u32(1);
shared_memory_13[l_411] = u32(0);
let l_412 = l_14 + u32(2);
shared_memory_13[l_412] = u32(0);
l_mut_270 = u64(0);
let l_413 = a_327[u32(0)];
let l_414 = u64(l_413);
let l_415 = a_324[u32(0)];
let l_416 = u64(l_415);
let l_417 = l_414 * l_416;
let l_418 = l_14 + u32(0);
let l_419 = shared_memory_13[l_418];
let l_420 = u64(l_419);
let l_421 = l_417 + l_420;
let l_422 = l_421 + l_mut_270;
let l_423 = l_14 + u32(0);
let l_424 = u32(bitcast<u64>(l_422));
shared_memory_13[l_423] = l_424;
let l_425 = l_422 >> u32(bitcast<u64>(u64(32)));
l_mut_270 = l_425;
let l_426 = l_14 + u32(1);
let l_427 = u32(bitcast<u64>(l_mut_270));
shared_memory_13[l_426] = l_427;
l_mut_270 = u64(0);
let l_428 = a_327[u32(1)];
let l_429 = u64(l_428);
let l_430 = a_324[u32(0)];
let l_431 = u64(l_430);
let l_432 = l_429 * l_431;
let l_433 = l_14 + u32(1);
let l_434 = shared_memory_13[l_433];
let l_435 = u64(l_434);
let l_436 = l_432 + l_435;
let l_437 = l_436 + l_mut_270;
let l_438 = l_14 + u32(1);
let l_439 = u32(bitcast<u64>(l_437));
shared_memory_13[l_438] = l_439;
let l_440 = l_437 >> u32(bitcast<u64>(u64(32)));
l_mut_270 = l_440;
let l_441 = l_14 + u32(2);
let l_442 = u32(bitcast<u64>(l_mut_270));
shared_memory_13[l_441] = l_442;
l_mut_354 = i32(2);
loop {
let l_443 = l_mut_354 >= i32(0);
let l_444 = !l_443;
if l_444 {
break;
}
let l_445 = u32(l_mut_354);
let l_446 = l_14 + l_445;
let l_447 = shared_memory_13[l_446];
let l_448 = l_447 != u32(0);
if l_448 {
break;
}
l_mut_354 = l_mut_354 - i32(1);
}
loop {
let l_449 = l_mut_354 >= i32(0);
let l_450 = l_449 && l_mut_119;
let l_451 = !l_450;
if l_451 {
break;
}
l_mut_279 = u32(0);
l_mut_452 = l_mut_354;
loop {
let l_453 = l_mut_452 >= i32(0);
let l_454 = !l_453;
if l_454 {
break;
}
let l_455 = u32(l_mut_452);
let l_456 = l_14 + l_455;
let l_457 = shared_memory_13[l_456];
let l_458 = l_mut_279 << u32(16);
let l_459 = l_457 >> u32(16);
let l_460 = l_458 | l_459;
let l_461 = l_460 / u32(27000);
let l_462 = l_461 * u32(27000);
let l_463 = l_460 - l_462;
let l_464 = l_463 << u32(16);
let l_465 = l_457 & u32(65535);
let l_466 = l_464 | l_465;
let l_467 = l_466 / u32(27000);
let l_468 = l_467 * u32(27000);
let l_469 = l_466 - l_468;
l_mut_279 = l_469;
let l_470 = u32(l_mut_452);
let l_471 = l_14 + l_470;
let l_472 = l_461 << u32(16);
let l_473 = l_472 | l_467;
shared_memory_13[l_471] = l_473;
l_mut_452 = l_mut_452 - i32(1);
}
loop {
let l_474 = l_mut_354 >= i32(0);
let l_475 = !l_474;
if l_475 {
break;
}
let l_476 = u32(l_mut_354);
let l_477 = l_14 + l_476;
let l_478 = shared_memory_13[l_477];
let l_479 = l_478 != u32(0);
if l_479 {
break;
}
l_mut_354 = l_mut_354 - i32(1);
}
l_mut_277 = l_mut_279;
l_mut_270 = u64(0);
let l_480 = l_mut_354 >= i32(0);
if l_480 {
let l_481 = l_mut_277 / u32(30);
let l_482 = l_481 * u32(30);
let l_483 = l_mut_277 - l_482;
l_mut_277 = l_481;
let l_484 = u64(l_483);
let l_485 = u64(1) << u32(bitcast<u64>(l_484));
let l_486 = l_mut_272 & l_485;
l_mut_270 = l_mut_270 | l_486;
l_mut_272 = l_mut_272 | l_485;
let l_487 = l_mut_277 / u32(30);
let l_488 = l_487 * u32(30);
let l_489 = l_mut_277 - l_488;
l_mut_277 = l_487;
let l_490 = u64(l_489);
let l_491 = u64(1) << u32(bitcast<u64>(l_490));
let l_492 = l_mut_272 & l_491;
l_mut_270 = l_mut_270 | l_492;
l_mut_272 = l_mut_272 | l_491;
let l_493 = l_mut_277 / u32(30);
let l_494 = l_493 * u32(30);
let l_495 = l_mut_277 - l_494;
l_mut_277 = l_493;
let l_496 = u64(l_495);
let l_497 = u64(1) << u32(bitcast<u64>(l_496));
let l_498 = l_mut_272 & l_497;
l_mut_270 = l_mut_270 | l_498;
l_mut_272 = l_mut_272 | l_497;
} else {
loop {
let l_499 = l_mut_277 != u32(0);
let l_500 = !l_499;
if l_500 {
break;
}
let l_501 = l_mut_277 / u32(30);
let l_502 = l_501 * u32(30);
let l_503 = l_mut_277 - l_502;
l_mut_277 = l_501;
let l_504 = u64(l_503);
let l_505 = u64(1) << u32(bitcast<u64>(l_504));
let l_506 = l_mut_272 & l_505;
l_mut_270 = l_mut_270 | l_506;
l_mut_272 = l_mut_272 | l_505;
}
}
let l_507 = l_mut_270 != u64(0);
if l_507 {
l_mut_119 = bool(false);
}
}
}
}
if l_mut_119 {
let l_508 = u32(bitcast<u64>(l_mut_272));
let l_509 = countOneBits(l_508);
let l_510 = l_mut_272 >> u32(bitcast<u64>(u64(32)));
let l_511 = u32(bitcast<u64>(l_510));
let l_512 = countOneBits(l_511);
let l_513 = l_509 + l_512;
l_mut_279 = l_513;
let l_514 = l_mut_279 == u32(30);
let l_515 = bool(true) || l_514;
if l_515 {
let l_516 = &buffer_4_global[u32(0)];
let l_517 = atomicAdd(l_516, u32(1));let l_518 = l_517 < info.scalars_u32[6];
if l_518 {
let l_519 = u32(4) * l_517;
let l_520 = u32(bitcast<u64>(l_112));
buffer_3_global[l_519] = l_520;
let l_521 = l_519 + u32(1);
let l_522 = l_112 >> u32(bitcast<u64>(u64(32)));
let l_523 = u32(bitcast<u64>(l_522));
buffer_3_global[l_521] = l_523;
let l_524 = l_519 + u32(2);
let l_525 = u32(bitcast<u64>(l_mut_39));
buffer_3_global[l_524] = l_525;
let l_526 = l_519 + u32(3);
let l_527 = l_mut_39 >> u32(bitcast<u64>(u64(32)));
let l_528 = u32(bitcast<u64>(l_527));
buffer_3_global[l_526] = l_528;
}
}
}
}
l_mut_46 = l_mut_46 + l_0;
}
l_mut_16 = l_mut_16 + l_4;
}
}
```
