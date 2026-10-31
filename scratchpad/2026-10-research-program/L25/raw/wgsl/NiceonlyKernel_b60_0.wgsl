
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

var<workgroup> shared_memory_13: array<u32, 2304>;

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
var a_135: array<u32, 3>;

var a_142: array<u32, 6>;

var l_mut_119: bool;
var l_mut_16: u32;
var l_mut_46: u32;
var l_mut_94: u32;
var l_mut_268: u32;
var l_mut_297: u32;
var l_mut_28: u64;
var l_mut_39: u64;
var l_mut_44: u64;
var l_mut_91: u64;
var l_mut_132: u64;
var l_mut_133: u64;
var l_mut_143: u64;
var l_mut_258: i32;
var l_mut_269: i32;
var l_mut_584: i32;
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
let l_14 = local_invocation_id.x * u32(9);
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
let l_51 = l_50 % u32(12744000);
l_mut_46 = l_51;
let l_52 = l_mut_46 << u32(8);
let l_53 = l_23 >> u32(16);
let l_54 = l_53 & u32(255);
let l_55 = l_52 | l_54;
let l_56 = l_55 % u32(12744000);
l_mut_46 = l_56;
let l_57 = l_mut_46 << u32(8);
let l_58 = l_23 >> u32(8);
let l_59 = l_58 & u32(255);
let l_60 = l_57 | l_59;
let l_61 = l_60 % u32(12744000);
l_mut_46 = l_61;
let l_62 = l_mut_46 << u32(8);
let l_63 = l_23 >> u32(0);
let l_64 = l_63 & u32(255);
let l_65 = l_62 | l_64;
let l_66 = l_65 % u32(12744000);
l_mut_46 = l_66;
let l_67 = l_mut_46 << u32(8);
let l_68 = l_20 >> u32(24);
let l_69 = l_68 & u32(255);
let l_70 = l_67 | l_69;
let l_71 = l_70 % u32(12744000);
l_mut_46 = l_71;
let l_72 = l_mut_46 << u32(8);
let l_73 = l_20 >> u32(16);
let l_74 = l_73 & u32(255);
let l_75 = l_72 | l_74;
let l_76 = l_75 % u32(12744000);
l_mut_46 = l_76;
let l_77 = l_mut_46 << u32(8);
let l_78 = l_20 >> u32(8);
let l_79 = l_78 & u32(255);
let l_80 = l_77 | l_79;
let l_81 = l_80 % u32(12744000);
l_mut_46 = l_81;
let l_82 = l_mut_46 << u32(8);
let l_83 = l_20 >> u32(0);
let l_84 = l_83 & u32(255);
let l_85 = l_82 | l_84;
let l_86 = l_85 % u32(12744000);
l_mut_46 = l_86;
let l_87 = info.scalars_u32[4] + l_mut_46;
let l_88 = l_87 % u32(12744000);
let l_89 = u64(l_88);
let l_90 = l_38 - l_89;
l_mut_91 = l_mut_39;
let l_92 = u64(l_88);
let l_93 = l_38 < l_92;
if l_93 {
l_mut_91 = l_mut_91 - u64(1);
}
l_mut_46 = u32(0);
l_mut_94 = u32(275550);
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
let l_103 = l_mut_46 / u32(275550);
let l_104 = l_103 * u32(275550);
let l_105 = l_mut_46 - l_104;
let l_106 = u64(l_103);
let l_107 = u64(u32(12744000));
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
let l_134 = l_mut_119 && bool(true);
if l_134 {
let l_136 = l_112 >> u32(bitcast<u64>(u64(0)));
let l_137 = u32(bitcast<u64>(l_136));
a_135[u32(0)] = l_137;
let l_138 = l_112 >> u32(bitcast<u64>(u64(32)));
let l_139 = u32(bitcast<u64>(l_138));
a_135[u32(1)] = l_139;
let l_140 = l_mut_39 >> u32(bitcast<u64>(u64(0)));
let l_141 = u32(bitcast<u64>(l_140));
a_135[u32(2)] = l_141;
a_142[u32(0)] = u32(0);
a_142[u32(1)] = u32(0);
a_142[u32(2)] = u32(0);
a_142[u32(3)] = u32(0);
a_142[u32(4)] = u32(0);
a_142[u32(5)] = u32(0);
l_mut_143 = u64(0);
let l_144 = a_135[u32(0)];
let l_145 = u64(l_144);
let l_146 = a_135[u32(0)];
let l_147 = u64(l_146);
let l_148 = l_145 * l_147;
let l_149 = a_142[u32(0)];
let l_150 = u64(l_149);
let l_151 = l_148 + l_150;
let l_152 = l_151 + l_mut_143;
let l_153 = u32(bitcast<u64>(l_152));
a_142[u32(0)] = l_153;
let l_154 = l_152 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_154;
let l_155 = a_135[u32(0)];
let l_156 = u64(l_155);
let l_157 = a_135[u32(1)];
let l_158 = u64(l_157);
let l_159 = l_156 * l_158;
let l_160 = a_142[u32(1)];
let l_161 = u64(l_160);
let l_162 = l_159 + l_161;
let l_163 = l_162 + l_mut_143;
let l_164 = u32(bitcast<u64>(l_163));
a_142[u32(1)] = l_164;
let l_165 = l_163 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_165;
let l_166 = a_135[u32(0)];
let l_167 = u64(l_166);
let l_168 = a_135[u32(2)];
let l_169 = u64(l_168);
let l_170 = l_167 * l_169;
let l_171 = a_142[u32(2)];
let l_172 = u64(l_171);
let l_173 = l_170 + l_172;
let l_174 = l_173 + l_mut_143;
let l_175 = u32(bitcast<u64>(l_174));
a_142[u32(2)] = l_175;
let l_176 = l_174 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_176;
let l_177 = u32(bitcast<u64>(l_mut_143));
a_142[u32(3)] = l_177;
l_mut_143 = u64(0);
let l_178 = a_135[u32(1)];
let l_179 = u64(l_178);
let l_180 = a_135[u32(0)];
let l_181 = u64(l_180);
let l_182 = l_179 * l_181;
let l_183 = a_142[u32(1)];
let l_184 = u64(l_183);
let l_185 = l_182 + l_184;
let l_186 = l_185 + l_mut_143;
let l_187 = u32(bitcast<u64>(l_186));
a_142[u32(1)] = l_187;
let l_188 = l_186 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_188;
let l_189 = a_135[u32(1)];
let l_190 = u64(l_189);
let l_191 = a_135[u32(1)];
let l_192 = u64(l_191);
let l_193 = l_190 * l_192;
let l_194 = a_142[u32(2)];
let l_195 = u64(l_194);
let l_196 = l_193 + l_195;
let l_197 = l_196 + l_mut_143;
let l_198 = u32(bitcast<u64>(l_197));
a_142[u32(2)] = l_198;
let l_199 = l_197 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_199;
let l_200 = a_135[u32(1)];
let l_201 = u64(l_200);
let l_202 = a_135[u32(2)];
let l_203 = u64(l_202);
let l_204 = l_201 * l_203;
let l_205 = a_142[u32(3)];
let l_206 = u64(l_205);
let l_207 = l_204 + l_206;
let l_208 = l_207 + l_mut_143;
let l_209 = u32(bitcast<u64>(l_208));
a_142[u32(3)] = l_209;
let l_210 = l_208 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_210;
let l_211 = u32(bitcast<u64>(l_mut_143));
a_142[u32(4)] = l_211;
l_mut_143 = u64(0);
let l_212 = a_135[u32(2)];
let l_213 = u64(l_212);
let l_214 = a_135[u32(0)];
let l_215 = u64(l_214);
let l_216 = l_213 * l_215;
let l_217 = a_142[u32(2)];
let l_218 = u64(l_217);
let l_219 = l_216 + l_218;
let l_220 = l_219 + l_mut_143;
let l_221 = u32(bitcast<u64>(l_220));
a_142[u32(2)] = l_221;
let l_222 = l_220 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_222;
let l_223 = a_135[u32(2)];
let l_224 = u64(l_223);
let l_225 = a_135[u32(1)];
let l_226 = u64(l_225);
let l_227 = l_224 * l_226;
let l_228 = a_142[u32(3)];
let l_229 = u64(l_228);
let l_230 = l_227 + l_229;
let l_231 = l_230 + l_mut_143;
let l_232 = u32(bitcast<u64>(l_231));
a_142[u32(3)] = l_232;
let l_233 = l_231 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_233;
let l_234 = a_135[u32(2)];
let l_235 = u64(l_234);
let l_236 = a_135[u32(2)];
let l_237 = u64(l_236);
let l_238 = l_235 * l_237;
let l_239 = a_142[u32(4)];
let l_240 = u64(l_239);
let l_241 = l_238 + l_240;
let l_242 = l_241 + l_mut_143;
let l_243 = u32(bitcast<u64>(l_242));
a_142[u32(4)] = l_243;
let l_244 = l_242 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_244;
let l_245 = u32(bitcast<u64>(l_mut_143));
a_142[u32(5)] = l_245;
let l_246 = l_14 + u32(0);
let l_247 = a_142[u32(0)];
shared_memory_13[l_246] = l_247;
let l_248 = l_14 + u32(1);
let l_249 = a_142[u32(1)];
shared_memory_13[l_248] = l_249;
let l_250 = l_14 + u32(2);
let l_251 = a_142[u32(2)];
shared_memory_13[l_250] = l_251;
let l_252 = l_14 + u32(3);
let l_253 = a_142[u32(3)];
shared_memory_13[l_252] = l_253;
let l_254 = l_14 + u32(4);
let l_255 = a_142[u32(4)];
shared_memory_13[l_254] = l_255;
let l_256 = l_14 + u32(5);
let l_257 = a_142[u32(5)];
shared_memory_13[l_256] = l_257;
l_mut_258 = i32(5);
loop {
let l_259 = l_mut_258 >= i32(0);
let l_260 = !l_259;
if l_260 {
break;
}
let l_261 = u32(l_mut_258);
let l_262 = l_14 + l_261;
let l_263 = shared_memory_13[l_262];
let l_264 = l_263 != u32(0);
if l_264 {
break;
}
l_mut_258 = l_mut_258 - i32(1);
}
loop {
let l_265 = l_mut_258 >= i32(0);
let l_266 = l_265 && l_mut_119;
let l_267 = !l_266;
if l_267 {
break;
}
l_mut_268 = u32(0);
l_mut_269 = l_mut_258;
loop {
let l_270 = l_mut_269 >= i32(0);
let l_271 = !l_270;
if l_271 {
break;
}
let l_272 = u32(l_mut_269);
let l_273 = l_14 + l_272;
let l_274 = shared_memory_13[l_273];
let l_275 = l_mut_268 << u32(16);
let l_276 = l_274 >> u32(16);
let l_277 = l_275 | l_276;
let l_278 = l_277 / u32(3600);
let l_279 = l_278 * u32(3600);
let l_280 = l_277 - l_279;
let l_281 = l_280 << u32(16);
let l_282 = l_274 & u32(65535);
let l_283 = l_281 | l_282;
let l_284 = l_283 / u32(3600);
let l_285 = l_284 * u32(3600);
let l_286 = l_283 - l_285;
l_mut_268 = l_286;
let l_287 = u32(l_mut_269);
let l_288 = l_14 + l_287;
let l_289 = l_278 << u32(16);
let l_290 = l_289 | l_284;
shared_memory_13[l_288] = l_290;
l_mut_269 = l_mut_269 - i32(1);
}
loop {
let l_291 = l_mut_258 >= i32(0);
let l_292 = !l_291;
if l_292 {
break;
}
let l_293 = u32(l_mut_258);
let l_294 = l_14 + l_293;
let l_295 = shared_memory_13[l_294];
let l_296 = l_295 != u32(0);
if l_296 {
break;
}
l_mut_258 = l_mut_258 - i32(1);
}
l_mut_297 = l_mut_268;
l_mut_143 = u64(0);
let l_298 = l_mut_258 >= i32(0);
if l_298 {
let l_299 = l_mut_297 / u32(60);
let l_300 = l_299 * u32(60);
let l_301 = l_mut_297 - l_300;
l_mut_297 = l_299;
let l_302 = u64(l_301);
let l_303 = u64(1) << u32(bitcast<u64>(l_302));
let l_304 = l_mut_132 & l_303;
l_mut_143 = l_mut_143 | l_304;
l_mut_132 = l_mut_132 | l_303;
let l_305 = l_mut_297 / u32(60);
let l_306 = l_305 * u32(60);
let l_307 = l_mut_297 - l_306;
l_mut_297 = l_305;
let l_308 = u64(l_307);
let l_309 = u64(1) << u32(bitcast<u64>(l_308));
let l_310 = l_mut_132 & l_309;
l_mut_143 = l_mut_143 | l_310;
l_mut_132 = l_mut_132 | l_309;
} else {
loop {
let l_311 = l_mut_297 != u32(0);
let l_312 = !l_311;
if l_312 {
break;
}
let l_313 = l_mut_297 / u32(60);
let l_314 = l_313 * u32(60);
let l_315 = l_mut_297 - l_314;
l_mut_297 = l_313;
let l_316 = u64(l_315);
let l_317 = u64(1) << u32(bitcast<u64>(l_316));
let l_318 = l_mut_132 & l_317;
l_mut_143 = l_mut_143 | l_318;
l_mut_132 = l_mut_132 | l_317;
}
}
let l_319 = l_mut_143 != u64(0);
if l_319 {
l_mut_119 = bool(false);
}
}
if l_mut_119 {
let l_320 = l_14 + u32(0);
shared_memory_13[l_320] = u32(0);
let l_321 = l_14 + u32(1);
shared_memory_13[l_321] = u32(0);
let l_322 = l_14 + u32(2);
shared_memory_13[l_322] = u32(0);
let l_323 = l_14 + u32(3);
shared_memory_13[l_323] = u32(0);
let l_324 = l_14 + u32(4);
shared_memory_13[l_324] = u32(0);
let l_325 = l_14 + u32(5);
shared_memory_13[l_325] = u32(0);
let l_326 = l_14 + u32(6);
shared_memory_13[l_326] = u32(0);
let l_327 = l_14 + u32(7);
shared_memory_13[l_327] = u32(0);
let l_328 = l_14 + u32(8);
shared_memory_13[l_328] = u32(0);
l_mut_143 = u64(0);
let l_329 = a_142[u32(0)];
let l_330 = u64(l_329);
let l_331 = a_135[u32(0)];
let l_332 = u64(l_331);
let l_333 = l_330 * l_332;
let l_334 = l_14 + u32(0);
let l_335 = shared_memory_13[l_334];
let l_336 = u64(l_335);
let l_337 = l_333 + l_336;
let l_338 = l_337 + l_mut_143;
let l_339 = l_14 + u32(0);
let l_340 = u32(bitcast<u64>(l_338));
shared_memory_13[l_339] = l_340;
let l_341 = l_338 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_341;
let l_342 = a_142[u32(0)];
let l_343 = u64(l_342);
let l_344 = a_135[u32(1)];
let l_345 = u64(l_344);
let l_346 = l_343 * l_345;
let l_347 = l_14 + u32(1);
let l_348 = shared_memory_13[l_347];
let l_349 = u64(l_348);
let l_350 = l_346 + l_349;
let l_351 = l_350 + l_mut_143;
let l_352 = l_14 + u32(1);
let l_353 = u32(bitcast<u64>(l_351));
shared_memory_13[l_352] = l_353;
let l_354 = l_351 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_354;
let l_355 = a_142[u32(0)];
let l_356 = u64(l_355);
let l_357 = a_135[u32(2)];
let l_358 = u64(l_357);
let l_359 = l_356 * l_358;
let l_360 = l_14 + u32(2);
let l_361 = shared_memory_13[l_360];
let l_362 = u64(l_361);
let l_363 = l_359 + l_362;
let l_364 = l_363 + l_mut_143;
let l_365 = l_14 + u32(2);
let l_366 = u32(bitcast<u64>(l_364));
shared_memory_13[l_365] = l_366;
let l_367 = l_364 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_367;
let l_368 = l_14 + u32(3);
let l_369 = u32(bitcast<u64>(l_mut_143));
shared_memory_13[l_368] = l_369;
l_mut_143 = u64(0);
let l_370 = a_142[u32(1)];
let l_371 = u64(l_370);
let l_372 = a_135[u32(0)];
let l_373 = u64(l_372);
let l_374 = l_371 * l_373;
let l_375 = l_14 + u32(1);
let l_376 = shared_memory_13[l_375];
let l_377 = u64(l_376);
let l_378 = l_374 + l_377;
let l_379 = l_378 + l_mut_143;
let l_380 = l_14 + u32(1);
let l_381 = u32(bitcast<u64>(l_379));
shared_memory_13[l_380] = l_381;
let l_382 = l_379 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_382;
let l_383 = a_142[u32(1)];
let l_384 = u64(l_383);
let l_385 = a_135[u32(1)];
let l_386 = u64(l_385);
let l_387 = l_384 * l_386;
let l_388 = l_14 + u32(2);
let l_389 = shared_memory_13[l_388];
let l_390 = u64(l_389);
let l_391 = l_387 + l_390;
let l_392 = l_391 + l_mut_143;
let l_393 = l_14 + u32(2);
let l_394 = u32(bitcast<u64>(l_392));
shared_memory_13[l_393] = l_394;
let l_395 = l_392 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_395;
let l_396 = a_142[u32(1)];
let l_397 = u64(l_396);
let l_398 = a_135[u32(2)];
let l_399 = u64(l_398);
let l_400 = l_397 * l_399;
let l_401 = l_14 + u32(3);
let l_402 = shared_memory_13[l_401];
let l_403 = u64(l_402);
let l_404 = l_400 + l_403;
let l_405 = l_404 + l_mut_143;
let l_406 = l_14 + u32(3);
let l_407 = u32(bitcast<u64>(l_405));
shared_memory_13[l_406] = l_407;
let l_408 = l_405 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_408;
let l_409 = l_14 + u32(4);
let l_410 = u32(bitcast<u64>(l_mut_143));
shared_memory_13[l_409] = l_410;
l_mut_143 = u64(0);
let l_411 = a_142[u32(2)];
let l_412 = u64(l_411);
let l_413 = a_135[u32(0)];
let l_414 = u64(l_413);
let l_415 = l_412 * l_414;
let l_416 = l_14 + u32(2);
let l_417 = shared_memory_13[l_416];
let l_418 = u64(l_417);
let l_419 = l_415 + l_418;
let l_420 = l_419 + l_mut_143;
let l_421 = l_14 + u32(2);
let l_422 = u32(bitcast<u64>(l_420));
shared_memory_13[l_421] = l_422;
let l_423 = l_420 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_423;
let l_424 = a_142[u32(2)];
let l_425 = u64(l_424);
let l_426 = a_135[u32(1)];
let l_427 = u64(l_426);
let l_428 = l_425 * l_427;
let l_429 = l_14 + u32(3);
let l_430 = shared_memory_13[l_429];
let l_431 = u64(l_430);
let l_432 = l_428 + l_431;
let l_433 = l_432 + l_mut_143;
let l_434 = l_14 + u32(3);
let l_435 = u32(bitcast<u64>(l_433));
shared_memory_13[l_434] = l_435;
let l_436 = l_433 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_436;
let l_437 = a_142[u32(2)];
let l_438 = u64(l_437);
let l_439 = a_135[u32(2)];
let l_440 = u64(l_439);
let l_441 = l_438 * l_440;
let l_442 = l_14 + u32(4);
let l_443 = shared_memory_13[l_442];
let l_444 = u64(l_443);
let l_445 = l_441 + l_444;
let l_446 = l_445 + l_mut_143;
let l_447 = l_14 + u32(4);
let l_448 = u32(bitcast<u64>(l_446));
shared_memory_13[l_447] = l_448;
let l_449 = l_446 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_449;
let l_450 = l_14 + u32(5);
let l_451 = u32(bitcast<u64>(l_mut_143));
shared_memory_13[l_450] = l_451;
l_mut_143 = u64(0);
let l_452 = a_142[u32(3)];
let l_453 = u64(l_452);
let l_454 = a_135[u32(0)];
let l_455 = u64(l_454);
let l_456 = l_453 * l_455;
let l_457 = l_14 + u32(3);
let l_458 = shared_memory_13[l_457];
let l_459 = u64(l_458);
let l_460 = l_456 + l_459;
let l_461 = l_460 + l_mut_143;
let l_462 = l_14 + u32(3);
let l_463 = u32(bitcast<u64>(l_461));
shared_memory_13[l_462] = l_463;
let l_464 = l_461 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_464;
let l_465 = a_142[u32(3)];
let l_466 = u64(l_465);
let l_467 = a_135[u32(1)];
let l_468 = u64(l_467);
let l_469 = l_466 * l_468;
let l_470 = l_14 + u32(4);
let l_471 = shared_memory_13[l_470];
let l_472 = u64(l_471);
let l_473 = l_469 + l_472;
let l_474 = l_473 + l_mut_143;
let l_475 = l_14 + u32(4);
let l_476 = u32(bitcast<u64>(l_474));
shared_memory_13[l_475] = l_476;
let l_477 = l_474 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_477;
let l_478 = a_142[u32(3)];
let l_479 = u64(l_478);
let l_480 = a_135[u32(2)];
let l_481 = u64(l_480);
let l_482 = l_479 * l_481;
let l_483 = l_14 + u32(5);
let l_484 = shared_memory_13[l_483];
let l_485 = u64(l_484);
let l_486 = l_482 + l_485;
let l_487 = l_486 + l_mut_143;
let l_488 = l_14 + u32(5);
let l_489 = u32(bitcast<u64>(l_487));
shared_memory_13[l_488] = l_489;
let l_490 = l_487 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_490;
let l_491 = l_14 + u32(6);
let l_492 = u32(bitcast<u64>(l_mut_143));
shared_memory_13[l_491] = l_492;
l_mut_143 = u64(0);
let l_493 = a_142[u32(4)];
let l_494 = u64(l_493);
let l_495 = a_135[u32(0)];
let l_496 = u64(l_495);
let l_497 = l_494 * l_496;
let l_498 = l_14 + u32(4);
let l_499 = shared_memory_13[l_498];
let l_500 = u64(l_499);
let l_501 = l_497 + l_500;
let l_502 = l_501 + l_mut_143;
let l_503 = l_14 + u32(4);
let l_504 = u32(bitcast<u64>(l_502));
shared_memory_13[l_503] = l_504;
let l_505 = l_502 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_505;
let l_506 = a_142[u32(4)];
let l_507 = u64(l_506);
let l_508 = a_135[u32(1)];
let l_509 = u64(l_508);
let l_510 = l_507 * l_509;
let l_511 = l_14 + u32(5);
let l_512 = shared_memory_13[l_511];
let l_513 = u64(l_512);
let l_514 = l_510 + l_513;
let l_515 = l_514 + l_mut_143;
let l_516 = l_14 + u32(5);
let l_517 = u32(bitcast<u64>(l_515));
shared_memory_13[l_516] = l_517;
let l_518 = l_515 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_518;
let l_519 = a_142[u32(4)];
let l_520 = u64(l_519);
let l_521 = a_135[u32(2)];
let l_522 = u64(l_521);
let l_523 = l_520 * l_522;
let l_524 = l_14 + u32(6);
let l_525 = shared_memory_13[l_524];
let l_526 = u64(l_525);
let l_527 = l_523 + l_526;
let l_528 = l_527 + l_mut_143;
let l_529 = l_14 + u32(6);
let l_530 = u32(bitcast<u64>(l_528));
shared_memory_13[l_529] = l_530;
let l_531 = l_528 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_531;
let l_532 = l_14 + u32(7);
let l_533 = u32(bitcast<u64>(l_mut_143));
shared_memory_13[l_532] = l_533;
l_mut_143 = u64(0);
let l_534 = a_142[u32(5)];
let l_535 = u64(l_534);
let l_536 = a_135[u32(0)];
let l_537 = u64(l_536);
let l_538 = l_535 * l_537;
let l_539 = l_14 + u32(5);
let l_540 = shared_memory_13[l_539];
let l_541 = u64(l_540);
let l_542 = l_538 + l_541;
let l_543 = l_542 + l_mut_143;
let l_544 = l_14 + u32(5);
let l_545 = u32(bitcast<u64>(l_543));
shared_memory_13[l_544] = l_545;
let l_546 = l_543 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_546;
let l_547 = a_142[u32(5)];
let l_548 = u64(l_547);
let l_549 = a_135[u32(1)];
let l_550 = u64(l_549);
let l_551 = l_548 * l_550;
let l_552 = l_14 + u32(6);
let l_553 = shared_memory_13[l_552];
let l_554 = u64(l_553);
let l_555 = l_551 + l_554;
let l_556 = l_555 + l_mut_143;
let l_557 = l_14 + u32(6);
let l_558 = u32(bitcast<u64>(l_556));
shared_memory_13[l_557] = l_558;
let l_559 = l_556 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_559;
let l_560 = a_142[u32(5)];
let l_561 = u64(l_560);
let l_562 = a_135[u32(2)];
let l_563 = u64(l_562);
let l_564 = l_561 * l_563;
let l_565 = l_14 + u32(7);
let l_566 = shared_memory_13[l_565];
let l_567 = u64(l_566);
let l_568 = l_564 + l_567;
let l_569 = l_568 + l_mut_143;
let l_570 = l_14 + u32(7);
let l_571 = u32(bitcast<u64>(l_569));
shared_memory_13[l_570] = l_571;
let l_572 = l_569 >> u32(bitcast<u64>(u64(32)));
l_mut_143 = l_572;
let l_573 = l_14 + u32(8);
let l_574 = u32(bitcast<u64>(l_mut_143));
shared_memory_13[l_573] = l_574;
l_mut_269 = i32(8);
loop {
let l_575 = l_mut_269 >= i32(0);
let l_576 = !l_575;
if l_576 {
break;
}
let l_577 = u32(l_mut_269);
let l_578 = l_14 + l_577;
let l_579 = shared_memory_13[l_578];
let l_580 = l_579 != u32(0);
if l_580 {
break;
}
l_mut_269 = l_mut_269 - i32(1);
}
loop {
let l_581 = l_mut_269 >= i32(0);
let l_582 = l_581 && l_mut_119;
let l_583 = !l_582;
if l_583 {
break;
}
l_mut_297 = u32(0);
l_mut_584 = l_mut_269;
loop {
let l_585 = l_mut_584 >= i32(0);
let l_586 = !l_585;
if l_586 {
break;
}
let l_587 = u32(l_mut_584);
let l_588 = l_14 + l_587;
let l_589 = shared_memory_13[l_588];
let l_590 = l_mut_297 << u32(16);
let l_591 = l_589 >> u32(16);
let l_592 = l_590 | l_591;
let l_593 = l_592 / u32(3600);
let l_594 = l_593 * u32(3600);
let l_595 = l_592 - l_594;
let l_596 = l_595 << u32(16);
let l_597 = l_589 & u32(65535);
let l_598 = l_596 | l_597;
let l_599 = l_598 / u32(3600);
let l_600 = l_599 * u32(3600);
let l_601 = l_598 - l_600;
l_mut_297 = l_601;
let l_602 = u32(l_mut_584);
let l_603 = l_14 + l_602;
let l_604 = l_593 << u32(16);
let l_605 = l_604 | l_599;
shared_memory_13[l_603] = l_605;
l_mut_584 = l_mut_584 - i32(1);
}
loop {
let l_606 = l_mut_269 >= i32(0);
let l_607 = !l_606;
if l_607 {
break;
}
let l_608 = u32(l_mut_269);
let l_609 = l_14 + l_608;
let l_610 = shared_memory_13[l_609];
let l_611 = l_610 != u32(0);
if l_611 {
break;
}
l_mut_269 = l_mut_269 - i32(1);
}
l_mut_268 = l_mut_297;
l_mut_143 = u64(0);
let l_612 = l_mut_269 >= i32(0);
if l_612 {
let l_613 = l_mut_268 / u32(60);
let l_614 = l_613 * u32(60);
let l_615 = l_mut_268 - l_614;
l_mut_268 = l_613;
let l_616 = u64(l_615);
let l_617 = u64(1) << u32(bitcast<u64>(l_616));
let l_618 = l_mut_132 & l_617;
l_mut_143 = l_mut_143 | l_618;
l_mut_132 = l_mut_132 | l_617;
let l_619 = l_mut_268 / u32(60);
let l_620 = l_619 * u32(60);
let l_621 = l_mut_268 - l_620;
l_mut_268 = l_619;
let l_622 = u64(l_621);
let l_623 = u64(1) << u32(bitcast<u64>(l_622));
let l_624 = l_mut_132 & l_623;
l_mut_143 = l_mut_143 | l_624;
l_mut_132 = l_mut_132 | l_623;
} else {
loop {
let l_625 = l_mut_268 != u32(0);
let l_626 = !l_625;
if l_626 {
break;
}
let l_627 = l_mut_268 / u32(60);
let l_628 = l_627 * u32(60);
let l_629 = l_mut_268 - l_628;
l_mut_268 = l_627;
let l_630 = u64(l_629);
let l_631 = u64(1) << u32(bitcast<u64>(l_630));
let l_632 = l_mut_132 & l_631;
l_mut_143 = l_mut_143 | l_632;
l_mut_132 = l_mut_132 | l_631;
}
}
let l_633 = l_mut_143 != u64(0);
if l_633 {
l_mut_119 = bool(false);
}
}
}
}
if l_mut_119 {
let l_634 = u32(bitcast<u64>(l_mut_132));
let l_635 = countOneBits(l_634);
let l_636 = l_mut_132 >> u32(bitcast<u64>(u64(32)));
let l_637 = u32(bitcast<u64>(l_636));
let l_638 = countOneBits(l_637);
let l_639 = l_635 + l_638;
l_mut_297 = l_639;
let l_640 = l_mut_297 == u32(60);
let l_641 = bool(false) || l_640;
if l_641 {
let l_642 = &buffer_4_global[u32(0)];
let l_643 = atomicAdd(l_642, u32(1));let l_644 = l_643 < info.scalars_u32[6];
if l_644 {
let l_645 = u32(4) * l_643;
let l_646 = u32(bitcast<u64>(l_112));
buffer_3_global[l_645] = l_646;
let l_647 = l_645 + u32(1);
let l_648 = l_112 >> u32(bitcast<u64>(u64(32)));
let l_649 = u32(bitcast<u64>(l_648));
buffer_3_global[l_647] = l_649;
let l_650 = l_645 + u32(2);
let l_651 = u32(bitcast<u64>(l_mut_39));
buffer_3_global[l_650] = l_651;
let l_652 = l_645 + u32(3);
let l_653 = l_mut_39 >> u32(bitcast<u64>(u64(32)));
let l_654 = u32(bitcast<u64>(l_653));
buffer_3_global[l_652] = l_654;
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
