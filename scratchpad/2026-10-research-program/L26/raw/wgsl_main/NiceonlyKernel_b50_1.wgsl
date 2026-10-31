
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
) {
var a_135: array<u32, 2>;

var a_140: array<u32, 4>;

var l_mut_28: u64;
var l_mut_39: u64;
var l_mut_44: u64;
var l_mut_91: u64;
var l_mut_132: u64;
var l_mut_133: u64;
var l_mut_141: u64;
var l_mut_196: i32;
var l_mut_207: i32;
var l_mut_385: i32;
var l_mut_119: bool;
var l_mut_16: u32;
var l_mut_46: u32;
var l_mut_94: u32;
var l_mut_206: u32;
var l_mut_235: u32;
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
let l_51 = l_50 % u32(6125000);
l_mut_46 = l_51;
let l_52 = l_mut_46 << u32(8);
let l_53 = l_23 >> u32(16);
let l_54 = l_53 & u32(255);
let l_55 = l_52 | l_54;
let l_56 = l_55 % u32(6125000);
l_mut_46 = l_56;
let l_57 = l_mut_46 << u32(8);
let l_58 = l_23 >> u32(8);
let l_59 = l_58 & u32(255);
let l_60 = l_57 | l_59;
let l_61 = l_60 % u32(6125000);
l_mut_46 = l_61;
let l_62 = l_mut_46 << u32(8);
let l_63 = l_23 >> u32(0);
let l_64 = l_63 & u32(255);
let l_65 = l_62 | l_64;
let l_66 = l_65 % u32(6125000);
l_mut_46 = l_66;
let l_67 = l_mut_46 << u32(8);
let l_68 = l_20 >> u32(24);
let l_69 = l_68 & u32(255);
let l_70 = l_67 | l_69;
let l_71 = l_70 % u32(6125000);
l_mut_46 = l_71;
let l_72 = l_mut_46 << u32(8);
let l_73 = l_20 >> u32(16);
let l_74 = l_73 & u32(255);
let l_75 = l_72 | l_74;
let l_76 = l_75 % u32(6125000);
l_mut_46 = l_76;
let l_77 = l_mut_46 << u32(8);
let l_78 = l_20 >> u32(8);
let l_79 = l_78 & u32(255);
let l_80 = l_77 | l_79;
let l_81 = l_80 % u32(6125000);
l_mut_46 = l_81;
let l_82 = l_mut_46 << u32(8);
let l_83 = l_20 >> u32(0);
let l_84 = l_83 & u32(255);
let l_85 = l_82 | l_84;
let l_86 = l_85 % u32(6125000);
l_mut_46 = l_86;
let l_87 = info.scalars_u32[4] + l_mut_46;
let l_88 = l_87 % u32(6125000);
let l_89 = u64(l_88);
let l_90 = l_38 - l_89;
l_mut_91 = l_mut_39;
let l_92 = u64(l_88);
let l_93 = l_38 < l_92;
if l_93 {
l_mut_91 = l_mut_91 - u64(1);
}
l_mut_46 = u32(0);
l_mut_94 = u32(568272);
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
let l_103 = l_mut_46 / u32(568272);
let l_104 = l_103 * u32(568272);
let l_105 = l_mut_46 - l_104;
let l_106 = u64(l_103);
let l_107 = u64(u32(6125000));
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
l_mut_132 = u64(0);
l_mut_133 = u64(0);
let l_134 = l_mut_119 && bool(false);
if l_134 {
let l_136 = l_112 >> u32(bitcast<u64>(u64(0)));
let l_137 = u32(bitcast<u64>(l_136));
a_135[u32(0)] = l_137;
let l_138 = l_112 >> u32(bitcast<u64>(u64(32)));
let l_139 = u32(bitcast<u64>(l_138));
a_135[u32(1)] = l_139;
a_140[u32(0)] = u32(0);
a_140[u32(1)] = u32(0);
a_140[u32(2)] = u32(0);
a_140[u32(3)] = u32(0);
l_mut_141 = u64(0);
let l_142 = a_135[u32(0)];
let l_143 = u64(l_142);
let l_144 = a_135[u32(0)];
let l_145 = u64(l_144);
let l_146 = l_143 * l_145;
let l_147 = a_140[u32(0)];
let l_148 = u64(l_147);
let l_149 = l_146 + l_148;
let l_150 = l_149 + l_mut_141;
let l_151 = u32(bitcast<u64>(l_150));
a_140[u32(0)] = l_151;
let l_152 = l_150 >> u32(bitcast<u64>(u64(32)));
l_mut_141 = l_152;
let l_153 = a_135[u32(0)];
let l_154 = u64(l_153);
let l_155 = a_135[u32(1)];
let l_156 = u64(l_155);
let l_157 = l_154 * l_156;
let l_158 = a_140[u32(1)];
let l_159 = u64(l_158);
let l_160 = l_157 + l_159;
let l_161 = l_160 + l_mut_141;
let l_162 = u32(bitcast<u64>(l_161));
a_140[u32(1)] = l_162;
let l_163 = l_161 >> u32(bitcast<u64>(u64(32)));
l_mut_141 = l_163;
let l_164 = u32(bitcast<u64>(l_mut_141));
a_140[u32(2)] = l_164;
l_mut_141 = u64(0);
let l_165 = a_135[u32(1)];
let l_166 = u64(l_165);
let l_167 = a_135[u32(0)];
let l_168 = u64(l_167);
let l_169 = l_166 * l_168;
let l_170 = a_140[u32(1)];
let l_171 = u64(l_170);
let l_172 = l_169 + l_171;
let l_173 = l_172 + l_mut_141;
let l_174 = u32(bitcast<u64>(l_173));
a_140[u32(1)] = l_174;
let l_175 = l_173 >> u32(bitcast<u64>(u64(32)));
l_mut_141 = l_175;
let l_176 = a_135[u32(1)];
let l_177 = u64(l_176);
let l_178 = a_135[u32(1)];
let l_179 = u64(l_178);
let l_180 = l_177 * l_179;
let l_181 = a_140[u32(2)];
let l_182 = u64(l_181);
let l_183 = l_180 + l_182;
let l_184 = l_183 + l_mut_141;
let l_185 = u32(bitcast<u64>(l_184));
a_140[u32(2)] = l_185;
let l_186 = l_184 >> u32(bitcast<u64>(u64(32)));
l_mut_141 = l_186;
let l_187 = u32(bitcast<u64>(l_mut_141));
a_140[u32(3)] = l_187;
let l_188 = l_14 + u32(0);
let l_189 = a_140[u32(0)];
shared_memory_13[l_188] = l_189;
let l_190 = l_14 + u32(1);
let l_191 = a_140[u32(1)];
shared_memory_13[l_190] = l_191;
let l_192 = l_14 + u32(2);
let l_193 = a_140[u32(2)];
shared_memory_13[l_192] = l_193;
let l_194 = l_14 + u32(3);
let l_195 = a_140[u32(3)];
shared_memory_13[l_194] = l_195;
l_mut_196 = i32(3);
loop {
let l_197 = l_mut_196 >= i32(0);
let l_198 = !l_197;
if l_198 {
break;
}
let l_199 = u32(l_mut_196);
let l_200 = l_14 + l_199;
let l_201 = shared_memory_13[l_200];
let l_202 = l_201 != u32(0);
if l_202 {
break;
}
l_mut_196 = l_mut_196 - i32(1);
}
loop {
let l_203 = l_mut_196 >= i32(0);
let l_204 = l_203 && l_mut_119;
let l_205 = !l_204;
if l_205 {
break;
}
l_mut_206 = u32(0);
l_mut_207 = l_mut_196;
loop {
let l_208 = l_mut_207 >= i32(0);
let l_209 = !l_208;
if l_209 {
break;
}
let l_210 = u32(l_mut_207);
let l_211 = l_14 + l_210;
let l_212 = shared_memory_13[l_211];
let l_213 = l_mut_206 << u32(16);
let l_214 = l_212 >> u32(16);
let l_215 = l_213 | l_214;
let l_216 = l_215 / u32(2500);
let l_217 = l_216 * u32(2500);
let l_218 = l_215 - l_217;
let l_219 = l_218 << u32(16);
let l_220 = l_212 & u32(65535);
let l_221 = l_219 | l_220;
let l_222 = l_221 / u32(2500);
let l_223 = l_222 * u32(2500);
let l_224 = l_221 - l_223;
l_mut_206 = l_224;
let l_225 = u32(l_mut_207);
let l_226 = l_14 + l_225;
let l_227 = l_216 << u32(16);
let l_228 = l_227 | l_222;
shared_memory_13[l_226] = l_228;
l_mut_207 = l_mut_207 - i32(1);
}
loop {
let l_229 = l_mut_196 >= i32(0);
let l_230 = !l_229;
if l_230 {
break;
}
let l_231 = u32(l_mut_196);
let l_232 = l_14 + l_231;
let l_233 = shared_memory_13[l_232];
let l_234 = l_233 != u32(0);
if l_234 {
break;
}
l_mut_196 = l_mut_196 - i32(1);
}
l_mut_235 = l_mut_206;
l_mut_141 = u64(0);
let l_236 = l_mut_196 >= i32(0);
if l_236 {
let l_237 = l_mut_235 / u32(50);
let l_238 = l_237 * u32(50);
let l_239 = l_mut_235 - l_238;
l_mut_235 = l_237;
let l_240 = u64(l_239);
let l_241 = u64(1) << u32(bitcast<u64>(l_240));
let l_242 = l_mut_132 & l_241;
l_mut_141 = l_mut_141 | l_242;
l_mut_132 = l_mut_132 | l_241;
let l_243 = l_mut_235 / u32(50);
let l_244 = l_243 * u32(50);
let l_245 = l_mut_235 - l_244;
l_mut_235 = l_243;
let l_246 = u64(l_245);
let l_247 = u64(1) << u32(bitcast<u64>(l_246));
let l_248 = l_mut_132 & l_247;
l_mut_141 = l_mut_141 | l_248;
l_mut_132 = l_mut_132 | l_247;
} else {
loop {
let l_249 = l_mut_235 != u32(0);
let l_250 = !l_249;
if l_250 {
break;
}
let l_251 = l_mut_235 / u32(50);
let l_252 = l_251 * u32(50);
let l_253 = l_mut_235 - l_252;
l_mut_235 = l_251;
let l_254 = u64(l_253);
let l_255 = u64(1) << u32(bitcast<u64>(l_254));
let l_256 = l_mut_132 & l_255;
l_mut_141 = l_mut_141 | l_256;
l_mut_132 = l_mut_132 | l_255;
}
}
let l_257 = l_mut_141 != u64(0);
if l_257 {
l_mut_119 = bool(false);
}
}
if l_mut_119 {
let l_258 = l_14 + u32(0);
shared_memory_13[l_258] = u32(0);
let l_259 = l_14 + u32(1);
shared_memory_13[l_259] = u32(0);
let l_260 = l_14 + u32(2);
shared_memory_13[l_260] = u32(0);
let l_261 = l_14 + u32(3);
shared_memory_13[l_261] = u32(0);
let l_262 = l_14 + u32(4);
shared_memory_13[l_262] = u32(0);
let l_263 = l_14 + u32(5);
shared_memory_13[l_263] = u32(0);
l_mut_141 = u64(0);
let l_264 = a_140[u32(0)];
let l_265 = u64(l_264);
let l_266 = a_135[u32(0)];
let l_267 = u64(l_266);
let l_268 = l_265 * l_267;
let l_269 = l_14 + u32(0);
let l_270 = shared_memory_13[l_269];
let l_271 = u64(l_270);
let l_272 = l_268 + l_271;
let l_273 = l_272 + l_mut_141;
let l_274 = l_14 + u32(0);
let l_275 = u32(bitcast<u64>(l_273));
shared_memory_13[l_274] = l_275;
let l_276 = l_273 >> u32(bitcast<u64>(u64(32)));
l_mut_141 = l_276;
let l_277 = a_140[u32(0)];
let l_278 = u64(l_277);
let l_279 = a_135[u32(1)];
let l_280 = u64(l_279);
let l_281 = l_278 * l_280;
let l_282 = l_14 + u32(1);
let l_283 = shared_memory_13[l_282];
let l_284 = u64(l_283);
let l_285 = l_281 + l_284;
let l_286 = l_285 + l_mut_141;
let l_287 = l_14 + u32(1);
let l_288 = u32(bitcast<u64>(l_286));
shared_memory_13[l_287] = l_288;
let l_289 = l_286 >> u32(bitcast<u64>(u64(32)));
l_mut_141 = l_289;
let l_290 = l_14 + u32(2);
let l_291 = u32(bitcast<u64>(l_mut_141));
shared_memory_13[l_290] = l_291;
l_mut_141 = u64(0);
let l_292 = a_140[u32(1)];
let l_293 = u64(l_292);
let l_294 = a_135[u32(0)];
let l_295 = u64(l_294);
let l_296 = l_293 * l_295;
let l_297 = l_14 + u32(1);
let l_298 = shared_memory_13[l_297];
let l_299 = u64(l_298);
let l_300 = l_296 + l_299;
let l_301 = l_300 + l_mut_141;
let l_302 = l_14 + u32(1);
let l_303 = u32(bitcast<u64>(l_301));
shared_memory_13[l_302] = l_303;
let l_304 = l_301 >> u32(bitcast<u64>(u64(32)));
l_mut_141 = l_304;
let l_305 = a_140[u32(1)];
let l_306 = u64(l_305);
let l_307 = a_135[u32(1)];
let l_308 = u64(l_307);
let l_309 = l_306 * l_308;
let l_310 = l_14 + u32(2);
let l_311 = shared_memory_13[l_310];
let l_312 = u64(l_311);
let l_313 = l_309 + l_312;
let l_314 = l_313 + l_mut_141;
let l_315 = l_14 + u32(2);
let l_316 = u32(bitcast<u64>(l_314));
shared_memory_13[l_315] = l_316;
let l_317 = l_314 >> u32(bitcast<u64>(u64(32)));
l_mut_141 = l_317;
let l_318 = l_14 + u32(3);
let l_319 = u32(bitcast<u64>(l_mut_141));
shared_memory_13[l_318] = l_319;
l_mut_141 = u64(0);
let l_320 = a_140[u32(2)];
let l_321 = u64(l_320);
let l_322 = a_135[u32(0)];
let l_323 = u64(l_322);
let l_324 = l_321 * l_323;
let l_325 = l_14 + u32(2);
let l_326 = shared_memory_13[l_325];
let l_327 = u64(l_326);
let l_328 = l_324 + l_327;
let l_329 = l_328 + l_mut_141;
let l_330 = l_14 + u32(2);
let l_331 = u32(bitcast<u64>(l_329));
shared_memory_13[l_330] = l_331;
let l_332 = l_329 >> u32(bitcast<u64>(u64(32)));
l_mut_141 = l_332;
let l_333 = a_140[u32(2)];
let l_334 = u64(l_333);
let l_335 = a_135[u32(1)];
let l_336 = u64(l_335);
let l_337 = l_334 * l_336;
let l_338 = l_14 + u32(3);
let l_339 = shared_memory_13[l_338];
let l_340 = u64(l_339);
let l_341 = l_337 + l_340;
let l_342 = l_341 + l_mut_141;
let l_343 = l_14 + u32(3);
let l_344 = u32(bitcast<u64>(l_342));
shared_memory_13[l_343] = l_344;
let l_345 = l_342 >> u32(bitcast<u64>(u64(32)));
l_mut_141 = l_345;
let l_346 = l_14 + u32(4);
let l_347 = u32(bitcast<u64>(l_mut_141));
shared_memory_13[l_346] = l_347;
l_mut_141 = u64(0);
let l_348 = a_140[u32(3)];
let l_349 = u64(l_348);
let l_350 = a_135[u32(0)];
let l_351 = u64(l_350);
let l_352 = l_349 * l_351;
let l_353 = l_14 + u32(3);
let l_354 = shared_memory_13[l_353];
let l_355 = u64(l_354);
let l_356 = l_352 + l_355;
let l_357 = l_356 + l_mut_141;
let l_358 = l_14 + u32(3);
let l_359 = u32(bitcast<u64>(l_357));
shared_memory_13[l_358] = l_359;
let l_360 = l_357 >> u32(bitcast<u64>(u64(32)));
l_mut_141 = l_360;
let l_361 = a_140[u32(3)];
let l_362 = u64(l_361);
let l_363 = a_135[u32(1)];
let l_364 = u64(l_363);
let l_365 = l_362 * l_364;
let l_366 = l_14 + u32(4);
let l_367 = shared_memory_13[l_366];
let l_368 = u64(l_367);
let l_369 = l_365 + l_368;
let l_370 = l_369 + l_mut_141;
let l_371 = l_14 + u32(4);
let l_372 = u32(bitcast<u64>(l_370));
shared_memory_13[l_371] = l_372;
let l_373 = l_370 >> u32(bitcast<u64>(u64(32)));
l_mut_141 = l_373;
let l_374 = l_14 + u32(5);
let l_375 = u32(bitcast<u64>(l_mut_141));
shared_memory_13[l_374] = l_375;
l_mut_207 = i32(5);
loop {
let l_376 = l_mut_207 >= i32(0);
let l_377 = !l_376;
if l_377 {
break;
}
let l_378 = u32(l_mut_207);
let l_379 = l_14 + l_378;
let l_380 = shared_memory_13[l_379];
let l_381 = l_380 != u32(0);
if l_381 {
break;
}
l_mut_207 = l_mut_207 - i32(1);
}
loop {
let l_382 = l_mut_207 >= i32(0);
let l_383 = l_382 && l_mut_119;
let l_384 = !l_383;
if l_384 {
break;
}
l_mut_235 = u32(0);
l_mut_385 = l_mut_207;
loop {
let l_386 = l_mut_385 >= i32(0);
let l_387 = !l_386;
if l_387 {
break;
}
let l_388 = u32(l_mut_385);
let l_389 = l_14 + l_388;
let l_390 = shared_memory_13[l_389];
let l_391 = l_mut_235 << u32(16);
let l_392 = l_390 >> u32(16);
let l_393 = l_391 | l_392;
let l_394 = l_393 / u32(2500);
let l_395 = l_394 * u32(2500);
let l_396 = l_393 - l_395;
let l_397 = l_396 << u32(16);
let l_398 = l_390 & u32(65535);
let l_399 = l_397 | l_398;
let l_400 = l_399 / u32(2500);
let l_401 = l_400 * u32(2500);
let l_402 = l_399 - l_401;
l_mut_235 = l_402;
let l_403 = u32(l_mut_385);
let l_404 = l_14 + l_403;
let l_405 = l_394 << u32(16);
let l_406 = l_405 | l_400;
shared_memory_13[l_404] = l_406;
l_mut_385 = l_mut_385 - i32(1);
}
loop {
let l_407 = l_mut_207 >= i32(0);
let l_408 = !l_407;
if l_408 {
break;
}
let l_409 = u32(l_mut_207);
let l_410 = l_14 + l_409;
let l_411 = shared_memory_13[l_410];
let l_412 = l_411 != u32(0);
if l_412 {
break;
}
l_mut_207 = l_mut_207 - i32(1);
}
l_mut_206 = l_mut_235;
l_mut_141 = u64(0);
let l_413 = l_mut_207 >= i32(0);
if l_413 {
let l_414 = l_mut_206 / u32(50);
let l_415 = l_414 * u32(50);
let l_416 = l_mut_206 - l_415;
l_mut_206 = l_414;
let l_417 = u64(l_416);
let l_418 = u64(1) << u32(bitcast<u64>(l_417));
let l_419 = l_mut_132 & l_418;
l_mut_141 = l_mut_141 | l_419;
l_mut_132 = l_mut_132 | l_418;
let l_420 = l_mut_206 / u32(50);
let l_421 = l_420 * u32(50);
let l_422 = l_mut_206 - l_421;
l_mut_206 = l_420;
let l_423 = u64(l_422);
let l_424 = u64(1) << u32(bitcast<u64>(l_423));
let l_425 = l_mut_132 & l_424;
l_mut_141 = l_mut_141 | l_425;
l_mut_132 = l_mut_132 | l_424;
} else {
loop {
let l_426 = l_mut_206 != u32(0);
let l_427 = !l_426;
if l_427 {
break;
}
let l_428 = l_mut_206 / u32(50);
let l_429 = l_428 * u32(50);
let l_430 = l_mut_206 - l_429;
l_mut_206 = l_428;
let l_431 = u64(l_430);
let l_432 = u64(1) << u32(bitcast<u64>(l_431));
let l_433 = l_mut_132 & l_432;
l_mut_141 = l_mut_141 | l_433;
l_mut_132 = l_mut_132 | l_432;
}
}
let l_434 = l_mut_141 != u64(0);
if l_434 {
l_mut_119 = bool(false);
}
}
}
}
if l_mut_119 {
let l_435 = u32(bitcast<u64>(l_mut_132));
let l_436 = countOneBits(l_435);
let l_437 = l_mut_132 >> u32(bitcast<u64>(u64(32)));
let l_438 = u32(bitcast<u64>(l_437));
let l_439 = countOneBits(l_438);
let l_440 = l_436 + l_439;
l_mut_235 = l_440;
let l_441 = l_mut_235 == u32(50);
let l_442 = bool(true) || l_441;
if l_442 {
let l_443 = &buffer_4_global[u32(0)];
let l_444 = atomicAdd(l_443, u32(1));let l_445 = l_444 < info.scalars_u32[6];
if l_445 {
let l_446 = u32(4) * l_444;
let l_447 = u32(bitcast<u64>(l_112));
buffer_3_global[l_446] = l_447;
let l_448 = l_446 + u32(1);
let l_449 = l_112 >> u32(bitcast<u64>(u64(32)));
let l_450 = u32(bitcast<u64>(l_449));
buffer_3_global[l_448] = l_450;
let l_451 = l_446 + u32(2);
let l_452 = u32(bitcast<u64>(l_mut_39));
buffer_3_global[l_451] = l_452;
let l_453 = l_446 + u32(3);
let l_454 = l_mut_39 >> u32(bitcast<u64>(u64(32)));
let l_455 = u32(bitcast<u64>(l_454));
buffer_3_global[l_453] = l_455;
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
