
```wgsl
@group(0)
@binding(0)
var<storage, read_write> buffer_0_global: array<u32>;

@group(0)
@binding(1)
var<storage, read_write> buffer_1_global: array<atomic<u32>>;

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
var<storage, read_write> buffer_5_global: array<atomic<u32>>;

struct info_st {
   scalars_u32: array<u32, 4>,
   static_meta: array<u32, 12>,
}

@group(0)
@binding(6)
var<storage, read> info: info_st;

var<workgroup> shared_memory_0: array<u32, 2304>;

const WORKGROUP_SIZE_X = 256u;
const WORKGROUP_SIZE_Y = 1u;
const WORKGROUP_SIZE_Z = 1u;

@compute
@workgroup_size(256, 1, 1)
fn check_kernel(
    @builtin(global_invocation_id) global_id: vec3<u32>,
    @builtin(local_invocation_id) local_invocation_id: vec3<u32>,
    @builtin(num_workgroups) num_workgroups: vec3<u32>,
) {
var a_37: array<u32, 3>;

var a_44: array<u32, 6>;

var l_mut_4: u32;
var l_mut_7: u32;
var l_mut_170: u32;
var l_mut_199: u32;
var l_mut_33: bool;
var l_mut_28: u64;
var l_mut_34: u64;
var l_mut_35: u64;
var l_mut_45: u64;
var l_mut_160: i32;
var l_mut_171: i32;
var l_mut_486: i32;
let l_1 = local_invocation_id.x * u32(9);
let l_2 = &buffer_1_global[u32(0)];
let l_3 = atomicLoad(l_2);
l_mut_4 = l_3;
let l_5 = l_mut_4 > info.scalars_u32[0];
if l_5 {
l_mut_4 = info.scalars_u32[0];
}
let l_6 = num_workgroups.x * WORKGROUP_SIZE_X;
l_mut_7 = global_id.x;
loop {
let l_8 = l_mut_7 < l_mut_4;
let l_9 = !l_8;
if l_9 {
break;
}
let l_10 = u32(2) * l_mut_7;
let l_11 = buffer_0_global[l_10];
let l_12 = u32(2) * l_mut_7;
let l_13 = l_12 + u32(1);
let l_14 = buffer_0_global[l_13];
let l_15 = u32(2) * l_11;
let l_16 = buffer_2_global[l_15];
let l_17 = u64(l_16);
let l_18 = u32(2) * l_11;
let l_19 = l_18 + u32(1);
let l_20 = buffer_2_global[l_19];
let l_21 = u64(l_20);
let l_22 = u64(info.scalars_u32[2]);
let l_23 = l_17 * l_22;
let l_24 = l_21 * l_22;
let l_25 = l_24 << u32(bitcast<u64>(u64(32)));
let l_26 = l_23 + l_25;
let l_27 = l_24 >> u32(bitcast<u64>(u64(32)));
l_mut_28 = l_27;
let l_29 = l_26 < l_23;
if l_29 {
l_mut_28 = l_mut_28 + u64(1);
}
let l_30 = u64(l_14);
let l_31 = l_26 + l_30;
let l_32 = l_31 < l_26;
if l_32 {
l_mut_28 = l_mut_28 + u64(1);
}
l_mut_33 = bool(true);
l_mut_34 = u64(0);
l_mut_35 = u64(0);
let l_36 = l_mut_33 && bool(true);
if l_36 {
let l_38 = l_31 >> u32(bitcast<u64>(u64(0)));
let l_39 = u32(bitcast<u64>(l_38));
a_37[u32(0)] = l_39;
let l_40 = l_31 >> u32(bitcast<u64>(u64(32)));
let l_41 = u32(bitcast<u64>(l_40));
a_37[u32(1)] = l_41;
let l_42 = l_mut_28 >> u32(bitcast<u64>(u64(0)));
let l_43 = u32(bitcast<u64>(l_42));
a_37[u32(2)] = l_43;
a_44[u32(0)] = u32(0);
a_44[u32(1)] = u32(0);
a_44[u32(2)] = u32(0);
a_44[u32(3)] = u32(0);
a_44[u32(4)] = u32(0);
a_44[u32(5)] = u32(0);
l_mut_45 = u64(0);
let l_46 = a_37[u32(0)];
let l_47 = u64(l_46);
let l_48 = a_37[u32(0)];
let l_49 = u64(l_48);
let l_50 = l_47 * l_49;
let l_51 = a_44[u32(0)];
let l_52 = u64(l_51);
let l_53 = l_50 + l_52;
let l_54 = l_53 + l_mut_45;
let l_55 = u32(bitcast<u64>(l_54));
a_44[u32(0)] = l_55;
let l_56 = l_54 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_56;
let l_57 = a_37[u32(0)];
let l_58 = u64(l_57);
let l_59 = a_37[u32(1)];
let l_60 = u64(l_59);
let l_61 = l_58 * l_60;
let l_62 = a_44[u32(1)];
let l_63 = u64(l_62);
let l_64 = l_61 + l_63;
let l_65 = l_64 + l_mut_45;
let l_66 = u32(bitcast<u64>(l_65));
a_44[u32(1)] = l_66;
let l_67 = l_65 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_67;
let l_68 = a_37[u32(0)];
let l_69 = u64(l_68);
let l_70 = a_37[u32(2)];
let l_71 = u64(l_70);
let l_72 = l_69 * l_71;
let l_73 = a_44[u32(2)];
let l_74 = u64(l_73);
let l_75 = l_72 + l_74;
let l_76 = l_75 + l_mut_45;
let l_77 = u32(bitcast<u64>(l_76));
a_44[u32(2)] = l_77;
let l_78 = l_76 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_78;
let l_79 = u32(bitcast<u64>(l_mut_45));
a_44[u32(3)] = l_79;
l_mut_45 = u64(0);
let l_80 = a_37[u32(1)];
let l_81 = u64(l_80);
let l_82 = a_37[u32(0)];
let l_83 = u64(l_82);
let l_84 = l_81 * l_83;
let l_85 = a_44[u32(1)];
let l_86 = u64(l_85);
let l_87 = l_84 + l_86;
let l_88 = l_87 + l_mut_45;
let l_89 = u32(bitcast<u64>(l_88));
a_44[u32(1)] = l_89;
let l_90 = l_88 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_90;
let l_91 = a_37[u32(1)];
let l_92 = u64(l_91);
let l_93 = a_37[u32(1)];
let l_94 = u64(l_93);
let l_95 = l_92 * l_94;
let l_96 = a_44[u32(2)];
let l_97 = u64(l_96);
let l_98 = l_95 + l_97;
let l_99 = l_98 + l_mut_45;
let l_100 = u32(bitcast<u64>(l_99));
a_44[u32(2)] = l_100;
let l_101 = l_99 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_101;
let l_102 = a_37[u32(1)];
let l_103 = u64(l_102);
let l_104 = a_37[u32(2)];
let l_105 = u64(l_104);
let l_106 = l_103 * l_105;
let l_107 = a_44[u32(3)];
let l_108 = u64(l_107);
let l_109 = l_106 + l_108;
let l_110 = l_109 + l_mut_45;
let l_111 = u32(bitcast<u64>(l_110));
a_44[u32(3)] = l_111;
let l_112 = l_110 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_112;
let l_113 = u32(bitcast<u64>(l_mut_45));
a_44[u32(4)] = l_113;
l_mut_45 = u64(0);
let l_114 = a_37[u32(2)];
let l_115 = u64(l_114);
let l_116 = a_37[u32(0)];
let l_117 = u64(l_116);
let l_118 = l_115 * l_117;
let l_119 = a_44[u32(2)];
let l_120 = u64(l_119);
let l_121 = l_118 + l_120;
let l_122 = l_121 + l_mut_45;
let l_123 = u32(bitcast<u64>(l_122));
a_44[u32(2)] = l_123;
let l_124 = l_122 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_124;
let l_125 = a_37[u32(2)];
let l_126 = u64(l_125);
let l_127 = a_37[u32(1)];
let l_128 = u64(l_127);
let l_129 = l_126 * l_128;
let l_130 = a_44[u32(3)];
let l_131 = u64(l_130);
let l_132 = l_129 + l_131;
let l_133 = l_132 + l_mut_45;
let l_134 = u32(bitcast<u64>(l_133));
a_44[u32(3)] = l_134;
let l_135 = l_133 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_135;
let l_136 = a_37[u32(2)];
let l_137 = u64(l_136);
let l_138 = a_37[u32(2)];
let l_139 = u64(l_138);
let l_140 = l_137 * l_139;
let l_141 = a_44[u32(4)];
let l_142 = u64(l_141);
let l_143 = l_140 + l_142;
let l_144 = l_143 + l_mut_45;
let l_145 = u32(bitcast<u64>(l_144));
a_44[u32(4)] = l_145;
let l_146 = l_144 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_146;
let l_147 = u32(bitcast<u64>(l_mut_45));
a_44[u32(5)] = l_147;
let l_148 = l_1 + u32(0);
let l_149 = a_44[u32(0)];
shared_memory_0[l_148] = l_149;
let l_150 = l_1 + u32(1);
let l_151 = a_44[u32(1)];
shared_memory_0[l_150] = l_151;
let l_152 = l_1 + u32(2);
let l_153 = a_44[u32(2)];
shared_memory_0[l_152] = l_153;
let l_154 = l_1 + u32(3);
let l_155 = a_44[u32(3)];
shared_memory_0[l_154] = l_155;
let l_156 = l_1 + u32(4);
let l_157 = a_44[u32(4)];
shared_memory_0[l_156] = l_157;
let l_158 = l_1 + u32(5);
let l_159 = a_44[u32(5)];
shared_memory_0[l_158] = l_159;
l_mut_160 = i32(5);
loop {
let l_161 = l_mut_160 >= i32(0);
let l_162 = !l_161;
if l_162 {
break;
}
let l_163 = u32(l_mut_160);
let l_164 = l_1 + l_163;
let l_165 = shared_memory_0[l_164];
let l_166 = l_165 != u32(0);
if l_166 {
break;
}
l_mut_160 = l_mut_160 - i32(1);
}
loop {
let l_167 = l_mut_160 >= i32(0);
let l_168 = l_167 && l_mut_33;
let l_169 = !l_168;
if l_169 {
break;
}
l_mut_170 = u32(0);
l_mut_171 = l_mut_160;
loop {
let l_172 = l_mut_171 >= i32(0);
let l_173 = !l_172;
if l_173 {
break;
}
let l_174 = u32(l_mut_171);
let l_175 = l_1 + l_174;
let l_176 = shared_memory_0[l_175];
let l_177 = l_mut_170 << u32(16);
let l_178 = l_176 >> u32(16);
let l_179 = l_177 | l_178;
let l_180 = l_179 / u32(3249);
let l_181 = l_180 * u32(3249);
let l_182 = l_179 - l_181;
let l_183 = l_182 << u32(16);
let l_184 = l_176 & u32(65535);
let l_185 = l_183 | l_184;
let l_186 = l_185 / u32(3249);
let l_187 = l_186 * u32(3249);
let l_188 = l_185 - l_187;
l_mut_170 = l_188;
let l_189 = u32(l_mut_171);
let l_190 = l_1 + l_189;
let l_191 = l_180 << u32(16);
let l_192 = l_191 | l_186;
shared_memory_0[l_190] = l_192;
l_mut_171 = l_mut_171 - i32(1);
}
loop {
let l_193 = l_mut_160 >= i32(0);
let l_194 = !l_193;
if l_194 {
break;
}
let l_195 = u32(l_mut_160);
let l_196 = l_1 + l_195;
let l_197 = shared_memory_0[l_196];
let l_198 = l_197 != u32(0);
if l_198 {
break;
}
l_mut_160 = l_mut_160 - i32(1);
}
l_mut_199 = l_mut_170;
l_mut_45 = u64(0);
let l_200 = l_mut_160 >= i32(0);
if l_200 {
let l_201 = l_mut_199 / u32(57);
let l_202 = l_201 * u32(57);
let l_203 = l_mut_199 - l_202;
l_mut_199 = l_201;
let l_204 = u64(l_203);
let l_205 = u64(1) << u32(bitcast<u64>(l_204));
let l_206 = l_mut_34 & l_205;
l_mut_45 = l_mut_45 | l_206;
l_mut_34 = l_mut_34 | l_205;
let l_207 = l_mut_199 / u32(57);
let l_208 = l_207 * u32(57);
let l_209 = l_mut_199 - l_208;
l_mut_199 = l_207;
let l_210 = u64(l_209);
let l_211 = u64(1) << u32(bitcast<u64>(l_210));
let l_212 = l_mut_34 & l_211;
l_mut_45 = l_mut_45 | l_212;
l_mut_34 = l_mut_34 | l_211;
} else {
loop {
let l_213 = l_mut_199 != u32(0);
let l_214 = !l_213;
if l_214 {
break;
}
let l_215 = l_mut_199 / u32(57);
let l_216 = l_215 * u32(57);
let l_217 = l_mut_199 - l_216;
l_mut_199 = l_215;
let l_218 = u64(l_217);
let l_219 = u64(1) << u32(bitcast<u64>(l_218));
let l_220 = l_mut_34 & l_219;
l_mut_45 = l_mut_45 | l_220;
l_mut_34 = l_mut_34 | l_219;
}
}
let l_221 = l_mut_45 != u64(0);
if l_221 {
l_mut_33 = bool(false);
}
}
if l_mut_33 {
let l_222 = l_1 + u32(0);
shared_memory_0[l_222] = u32(0);
let l_223 = l_1 + u32(1);
shared_memory_0[l_223] = u32(0);
let l_224 = l_1 + u32(2);
shared_memory_0[l_224] = u32(0);
let l_225 = l_1 + u32(3);
shared_memory_0[l_225] = u32(0);
let l_226 = l_1 + u32(4);
shared_memory_0[l_226] = u32(0);
let l_227 = l_1 + u32(5);
shared_memory_0[l_227] = u32(0);
let l_228 = l_1 + u32(6);
shared_memory_0[l_228] = u32(0);
let l_229 = l_1 + u32(7);
shared_memory_0[l_229] = u32(0);
let l_230 = l_1 + u32(8);
shared_memory_0[l_230] = u32(0);
l_mut_45 = u64(0);
let l_231 = a_44[u32(0)];
let l_232 = u64(l_231);
let l_233 = a_37[u32(0)];
let l_234 = u64(l_233);
let l_235 = l_232 * l_234;
let l_236 = l_1 + u32(0);
let l_237 = shared_memory_0[l_236];
let l_238 = u64(l_237);
let l_239 = l_235 + l_238;
let l_240 = l_239 + l_mut_45;
let l_241 = l_1 + u32(0);
let l_242 = u32(bitcast<u64>(l_240));
shared_memory_0[l_241] = l_242;
let l_243 = l_240 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_243;
let l_244 = a_44[u32(0)];
let l_245 = u64(l_244);
let l_246 = a_37[u32(1)];
let l_247 = u64(l_246);
let l_248 = l_245 * l_247;
let l_249 = l_1 + u32(1);
let l_250 = shared_memory_0[l_249];
let l_251 = u64(l_250);
let l_252 = l_248 + l_251;
let l_253 = l_252 + l_mut_45;
let l_254 = l_1 + u32(1);
let l_255 = u32(bitcast<u64>(l_253));
shared_memory_0[l_254] = l_255;
let l_256 = l_253 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_256;
let l_257 = a_44[u32(0)];
let l_258 = u64(l_257);
let l_259 = a_37[u32(2)];
let l_260 = u64(l_259);
let l_261 = l_258 * l_260;
let l_262 = l_1 + u32(2);
let l_263 = shared_memory_0[l_262];
let l_264 = u64(l_263);
let l_265 = l_261 + l_264;
let l_266 = l_265 + l_mut_45;
let l_267 = l_1 + u32(2);
let l_268 = u32(bitcast<u64>(l_266));
shared_memory_0[l_267] = l_268;
let l_269 = l_266 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_269;
let l_270 = l_1 + u32(3);
let l_271 = u32(bitcast<u64>(l_mut_45));
shared_memory_0[l_270] = l_271;
l_mut_45 = u64(0);
let l_272 = a_44[u32(1)];
let l_273 = u64(l_272);
let l_274 = a_37[u32(0)];
let l_275 = u64(l_274);
let l_276 = l_273 * l_275;
let l_277 = l_1 + u32(1);
let l_278 = shared_memory_0[l_277];
let l_279 = u64(l_278);
let l_280 = l_276 + l_279;
let l_281 = l_280 + l_mut_45;
let l_282 = l_1 + u32(1);
let l_283 = u32(bitcast<u64>(l_281));
shared_memory_0[l_282] = l_283;
let l_284 = l_281 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_284;
let l_285 = a_44[u32(1)];
let l_286 = u64(l_285);
let l_287 = a_37[u32(1)];
let l_288 = u64(l_287);
let l_289 = l_286 * l_288;
let l_290 = l_1 + u32(2);
let l_291 = shared_memory_0[l_290];
let l_292 = u64(l_291);
let l_293 = l_289 + l_292;
let l_294 = l_293 + l_mut_45;
let l_295 = l_1 + u32(2);
let l_296 = u32(bitcast<u64>(l_294));
shared_memory_0[l_295] = l_296;
let l_297 = l_294 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_297;
let l_298 = a_44[u32(1)];
let l_299 = u64(l_298);
let l_300 = a_37[u32(2)];
let l_301 = u64(l_300);
let l_302 = l_299 * l_301;
let l_303 = l_1 + u32(3);
let l_304 = shared_memory_0[l_303];
let l_305 = u64(l_304);
let l_306 = l_302 + l_305;
let l_307 = l_306 + l_mut_45;
let l_308 = l_1 + u32(3);
let l_309 = u32(bitcast<u64>(l_307));
shared_memory_0[l_308] = l_309;
let l_310 = l_307 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_310;
let l_311 = l_1 + u32(4);
let l_312 = u32(bitcast<u64>(l_mut_45));
shared_memory_0[l_311] = l_312;
l_mut_45 = u64(0);
let l_313 = a_44[u32(2)];
let l_314 = u64(l_313);
let l_315 = a_37[u32(0)];
let l_316 = u64(l_315);
let l_317 = l_314 * l_316;
let l_318 = l_1 + u32(2);
let l_319 = shared_memory_0[l_318];
let l_320 = u64(l_319);
let l_321 = l_317 + l_320;
let l_322 = l_321 + l_mut_45;
let l_323 = l_1 + u32(2);
let l_324 = u32(bitcast<u64>(l_322));
shared_memory_0[l_323] = l_324;
let l_325 = l_322 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_325;
let l_326 = a_44[u32(2)];
let l_327 = u64(l_326);
let l_328 = a_37[u32(1)];
let l_329 = u64(l_328);
let l_330 = l_327 * l_329;
let l_331 = l_1 + u32(3);
let l_332 = shared_memory_0[l_331];
let l_333 = u64(l_332);
let l_334 = l_330 + l_333;
let l_335 = l_334 + l_mut_45;
let l_336 = l_1 + u32(3);
let l_337 = u32(bitcast<u64>(l_335));
shared_memory_0[l_336] = l_337;
let l_338 = l_335 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_338;
let l_339 = a_44[u32(2)];
let l_340 = u64(l_339);
let l_341 = a_37[u32(2)];
let l_342 = u64(l_341);
let l_343 = l_340 * l_342;
let l_344 = l_1 + u32(4);
let l_345 = shared_memory_0[l_344];
let l_346 = u64(l_345);
let l_347 = l_343 + l_346;
let l_348 = l_347 + l_mut_45;
let l_349 = l_1 + u32(4);
let l_350 = u32(bitcast<u64>(l_348));
shared_memory_0[l_349] = l_350;
let l_351 = l_348 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_351;
let l_352 = l_1 + u32(5);
let l_353 = u32(bitcast<u64>(l_mut_45));
shared_memory_0[l_352] = l_353;
l_mut_45 = u64(0);
let l_354 = a_44[u32(3)];
let l_355 = u64(l_354);
let l_356 = a_37[u32(0)];
let l_357 = u64(l_356);
let l_358 = l_355 * l_357;
let l_359 = l_1 + u32(3);
let l_360 = shared_memory_0[l_359];
let l_361 = u64(l_360);
let l_362 = l_358 + l_361;
let l_363 = l_362 + l_mut_45;
let l_364 = l_1 + u32(3);
let l_365 = u32(bitcast<u64>(l_363));
shared_memory_0[l_364] = l_365;
let l_366 = l_363 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_366;
let l_367 = a_44[u32(3)];
let l_368 = u64(l_367);
let l_369 = a_37[u32(1)];
let l_370 = u64(l_369);
let l_371 = l_368 * l_370;
let l_372 = l_1 + u32(4);
let l_373 = shared_memory_0[l_372];
let l_374 = u64(l_373);
let l_375 = l_371 + l_374;
let l_376 = l_375 + l_mut_45;
let l_377 = l_1 + u32(4);
let l_378 = u32(bitcast<u64>(l_376));
shared_memory_0[l_377] = l_378;
let l_379 = l_376 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_379;
let l_380 = a_44[u32(3)];
let l_381 = u64(l_380);
let l_382 = a_37[u32(2)];
let l_383 = u64(l_382);
let l_384 = l_381 * l_383;
let l_385 = l_1 + u32(5);
let l_386 = shared_memory_0[l_385];
let l_387 = u64(l_386);
let l_388 = l_384 + l_387;
let l_389 = l_388 + l_mut_45;
let l_390 = l_1 + u32(5);
let l_391 = u32(bitcast<u64>(l_389));
shared_memory_0[l_390] = l_391;
let l_392 = l_389 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_392;
let l_393 = l_1 + u32(6);
let l_394 = u32(bitcast<u64>(l_mut_45));
shared_memory_0[l_393] = l_394;
l_mut_45 = u64(0);
let l_395 = a_44[u32(4)];
let l_396 = u64(l_395);
let l_397 = a_37[u32(0)];
let l_398 = u64(l_397);
let l_399 = l_396 * l_398;
let l_400 = l_1 + u32(4);
let l_401 = shared_memory_0[l_400];
let l_402 = u64(l_401);
let l_403 = l_399 + l_402;
let l_404 = l_403 + l_mut_45;
let l_405 = l_1 + u32(4);
let l_406 = u32(bitcast<u64>(l_404));
shared_memory_0[l_405] = l_406;
let l_407 = l_404 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_407;
let l_408 = a_44[u32(4)];
let l_409 = u64(l_408);
let l_410 = a_37[u32(1)];
let l_411 = u64(l_410);
let l_412 = l_409 * l_411;
let l_413 = l_1 + u32(5);
let l_414 = shared_memory_0[l_413];
let l_415 = u64(l_414);
let l_416 = l_412 + l_415;
let l_417 = l_416 + l_mut_45;
let l_418 = l_1 + u32(5);
let l_419 = u32(bitcast<u64>(l_417));
shared_memory_0[l_418] = l_419;
let l_420 = l_417 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_420;
let l_421 = a_44[u32(4)];
let l_422 = u64(l_421);
let l_423 = a_37[u32(2)];
let l_424 = u64(l_423);
let l_425 = l_422 * l_424;
let l_426 = l_1 + u32(6);
let l_427 = shared_memory_0[l_426];
let l_428 = u64(l_427);
let l_429 = l_425 + l_428;
let l_430 = l_429 + l_mut_45;
let l_431 = l_1 + u32(6);
let l_432 = u32(bitcast<u64>(l_430));
shared_memory_0[l_431] = l_432;
let l_433 = l_430 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_433;
let l_434 = l_1 + u32(7);
let l_435 = u32(bitcast<u64>(l_mut_45));
shared_memory_0[l_434] = l_435;
l_mut_45 = u64(0);
let l_436 = a_44[u32(5)];
let l_437 = u64(l_436);
let l_438 = a_37[u32(0)];
let l_439 = u64(l_438);
let l_440 = l_437 * l_439;
let l_441 = l_1 + u32(5);
let l_442 = shared_memory_0[l_441];
let l_443 = u64(l_442);
let l_444 = l_440 + l_443;
let l_445 = l_444 + l_mut_45;
let l_446 = l_1 + u32(5);
let l_447 = u32(bitcast<u64>(l_445));
shared_memory_0[l_446] = l_447;
let l_448 = l_445 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_448;
let l_449 = a_44[u32(5)];
let l_450 = u64(l_449);
let l_451 = a_37[u32(1)];
let l_452 = u64(l_451);
let l_453 = l_450 * l_452;
let l_454 = l_1 + u32(6);
let l_455 = shared_memory_0[l_454];
let l_456 = u64(l_455);
let l_457 = l_453 + l_456;
let l_458 = l_457 + l_mut_45;
let l_459 = l_1 + u32(6);
let l_460 = u32(bitcast<u64>(l_458));
shared_memory_0[l_459] = l_460;
let l_461 = l_458 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_461;
let l_462 = a_44[u32(5)];
let l_463 = u64(l_462);
let l_464 = a_37[u32(2)];
let l_465 = u64(l_464);
let l_466 = l_463 * l_465;
let l_467 = l_1 + u32(7);
let l_468 = shared_memory_0[l_467];
let l_469 = u64(l_468);
let l_470 = l_466 + l_469;
let l_471 = l_470 + l_mut_45;
let l_472 = l_1 + u32(7);
let l_473 = u32(bitcast<u64>(l_471));
shared_memory_0[l_472] = l_473;
let l_474 = l_471 >> u32(bitcast<u64>(u64(32)));
l_mut_45 = l_474;
let l_475 = l_1 + u32(8);
let l_476 = u32(bitcast<u64>(l_mut_45));
shared_memory_0[l_475] = l_476;
l_mut_171 = i32(8);
loop {
let l_477 = l_mut_171 >= i32(0);
let l_478 = !l_477;
if l_478 {
break;
}
let l_479 = u32(l_mut_171);
let l_480 = l_1 + l_479;
let l_481 = shared_memory_0[l_480];
let l_482 = l_481 != u32(0);
if l_482 {
break;
}
l_mut_171 = l_mut_171 - i32(1);
}
loop {
let l_483 = l_mut_171 >= i32(0);
let l_484 = l_483 && l_mut_33;
let l_485 = !l_484;
if l_485 {
break;
}
l_mut_199 = u32(0);
l_mut_486 = l_mut_171;
loop {
let l_487 = l_mut_486 >= i32(0);
let l_488 = !l_487;
if l_488 {
break;
}
let l_489 = u32(l_mut_486);
let l_490 = l_1 + l_489;
let l_491 = shared_memory_0[l_490];
let l_492 = l_mut_199 << u32(16);
let l_493 = l_491 >> u32(16);
let l_494 = l_492 | l_493;
let l_495 = l_494 / u32(3249);
let l_496 = l_495 * u32(3249);
let l_497 = l_494 - l_496;
let l_498 = l_497 << u32(16);
let l_499 = l_491 & u32(65535);
let l_500 = l_498 | l_499;
let l_501 = l_500 / u32(3249);
let l_502 = l_501 * u32(3249);
let l_503 = l_500 - l_502;
l_mut_199 = l_503;
let l_504 = u32(l_mut_486);
let l_505 = l_1 + l_504;
let l_506 = l_495 << u32(16);
let l_507 = l_506 | l_501;
shared_memory_0[l_505] = l_507;
l_mut_486 = l_mut_486 - i32(1);
}
loop {
let l_508 = l_mut_171 >= i32(0);
let l_509 = !l_508;
if l_509 {
break;
}
let l_510 = u32(l_mut_171);
let l_511 = l_1 + l_510;
let l_512 = shared_memory_0[l_511];
let l_513 = l_512 != u32(0);
if l_513 {
break;
}
l_mut_171 = l_mut_171 - i32(1);
}
l_mut_170 = l_mut_199;
l_mut_45 = u64(0);
let l_514 = l_mut_171 >= i32(0);
if l_514 {
let l_515 = l_mut_170 / u32(57);
let l_516 = l_515 * u32(57);
let l_517 = l_mut_170 - l_516;
l_mut_170 = l_515;
let l_518 = u64(l_517);
let l_519 = u64(1) << u32(bitcast<u64>(l_518));
let l_520 = l_mut_34 & l_519;
l_mut_45 = l_mut_45 | l_520;
l_mut_34 = l_mut_34 | l_519;
let l_521 = l_mut_170 / u32(57);
let l_522 = l_521 * u32(57);
let l_523 = l_mut_170 - l_522;
l_mut_170 = l_521;
let l_524 = u64(l_523);
let l_525 = u64(1) << u32(bitcast<u64>(l_524));
let l_526 = l_mut_34 & l_525;
l_mut_45 = l_mut_45 | l_526;
l_mut_34 = l_mut_34 | l_525;
} else {
loop {
let l_527 = l_mut_170 != u32(0);
let l_528 = !l_527;
if l_528 {
break;
}
let l_529 = l_mut_170 / u32(57);
let l_530 = l_529 * u32(57);
let l_531 = l_mut_170 - l_530;
l_mut_170 = l_529;
let l_532 = u64(l_531);
let l_533 = u64(1) << u32(bitcast<u64>(l_532));
let l_534 = l_mut_34 & l_533;
l_mut_45 = l_mut_45 | l_534;
l_mut_34 = l_mut_34 | l_533;
}
}
let l_535 = l_mut_45 != u64(0);
if l_535 {
l_mut_33 = bool(false);
}
}
}
}
if l_mut_33 {
let l_536 = u32(bitcast<u64>(l_mut_34));
let l_537 = countOneBits(l_536);
let l_538 = l_mut_34 >> u32(bitcast<u64>(u64(32)));
let l_539 = u32(bitcast<u64>(l_538));
let l_540 = countOneBits(l_539);
let l_541 = l_537 + l_540;
l_mut_199 = l_541;
let l_542 = l_mut_199 == u32(57);
let l_543 = bool(false) || l_542;
if l_543 {
let l_544 = &buffer_4_global[u32(0)];
let l_545 = atomicAdd(l_544, u32(1));let l_546 = l_545 < info.scalars_u32[1];
if l_546 {
let l_547 = u32(4) * l_545;
let l_548 = u32(bitcast<u64>(l_31));
buffer_3_global[l_547] = l_548;
let l_549 = l_547 + u32(1);
let l_550 = l_31 >> u32(bitcast<u64>(u64(32)));
let l_551 = u32(bitcast<u64>(l_550));
buffer_3_global[l_549] = l_551;
let l_552 = l_547 + u32(2);
let l_553 = u32(bitcast<u64>(l_mut_28));
buffer_3_global[l_552] = l_553;
let l_554 = l_547 + u32(3);
let l_555 = l_mut_28 >> u32(bitcast<u64>(u64(32)));
let l_556 = u32(bitcast<u64>(l_555));
buffer_3_global[l_554] = l_556;
}
}
}
l_mut_7 = l_mut_7 + l_6;
}
workgroupBarrier();
let l_557 = local_invocation_id.x == u32(0);
if l_557 {
let l_558 = &buffer_5_global[u32(5)];
let l_559 = atomicAdd(l_558, u32(1));}
}
```
