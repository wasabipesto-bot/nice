
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

var<workgroup> shared_memory_0: array<u32, 1792>;

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
var a_37: array<u32, 2>;

var a_42: array<u32, 4>;

var l_mut_98: i32;
var l_mut_109: i32;
var l_mut_287: i32;
var l_mut_4: u32;
var l_mut_7: u32;
var l_mut_108: u32;
var l_mut_137: u32;
var l_mut_33: bool;
var l_mut_28: u64;
var l_mut_34: u64;
var l_mut_35: u64;
var l_mut_43: u64;
let l_1 = local_invocation_id.x * u32(7);
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
a_42[u32(0)] = u32(0);
a_42[u32(1)] = u32(0);
a_42[u32(2)] = u32(0);
a_42[u32(3)] = u32(0);
l_mut_43 = u64(0);
let l_44 = a_37[u32(0)];
let l_45 = u64(l_44);
let l_46 = a_37[u32(0)];
let l_47 = u64(l_46);
let l_48 = l_45 * l_47;
let l_49 = a_42[u32(0)];
let l_50 = u64(l_49);
let l_51 = l_48 + l_50;
let l_52 = l_51 + l_mut_43;
let l_53 = u32(bitcast<u64>(l_52));
a_42[u32(0)] = l_53;
let l_54 = l_52 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_54;
let l_55 = a_37[u32(0)];
let l_56 = u64(l_55);
let l_57 = a_37[u32(1)];
let l_58 = u64(l_57);
let l_59 = l_56 * l_58;
let l_60 = a_42[u32(1)];
let l_61 = u64(l_60);
let l_62 = l_59 + l_61;
let l_63 = l_62 + l_mut_43;
let l_64 = u32(bitcast<u64>(l_63));
a_42[u32(1)] = l_64;
let l_65 = l_63 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_65;
let l_66 = u32(bitcast<u64>(l_mut_43));
a_42[u32(2)] = l_66;
l_mut_43 = u64(0);
let l_67 = a_37[u32(1)];
let l_68 = u64(l_67);
let l_69 = a_37[u32(0)];
let l_70 = u64(l_69);
let l_71 = l_68 * l_70;
let l_72 = a_42[u32(1)];
let l_73 = u64(l_72);
let l_74 = l_71 + l_73;
let l_75 = l_74 + l_mut_43;
let l_76 = u32(bitcast<u64>(l_75));
a_42[u32(1)] = l_76;
let l_77 = l_75 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_77;
let l_78 = a_37[u32(1)];
let l_79 = u64(l_78);
let l_80 = a_37[u32(1)];
let l_81 = u64(l_80);
let l_82 = l_79 * l_81;
let l_83 = a_42[u32(2)];
let l_84 = u64(l_83);
let l_85 = l_82 + l_84;
let l_86 = l_85 + l_mut_43;
let l_87 = u32(bitcast<u64>(l_86));
a_42[u32(2)] = l_87;
let l_88 = l_86 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_88;
let l_89 = u32(bitcast<u64>(l_mut_43));
a_42[u32(3)] = l_89;
let l_90 = l_1 + u32(0);
let l_91 = a_42[u32(0)];
shared_memory_0[l_90] = l_91;
let l_92 = l_1 + u32(1);
let l_93 = a_42[u32(1)];
shared_memory_0[l_92] = l_93;
let l_94 = l_1 + u32(2);
let l_95 = a_42[u32(2)];
shared_memory_0[l_94] = l_95;
let l_96 = l_1 + u32(3);
let l_97 = a_42[u32(3)];
shared_memory_0[l_96] = l_97;
l_mut_98 = i32(3);
loop {
let l_99 = l_mut_98 >= i32(0);
let l_100 = !l_99;
if l_100 {
break;
}
let l_101 = u32(l_mut_98);
let l_102 = l_1 + l_101;
let l_103 = shared_memory_0[l_102];
let l_104 = l_103 != u32(0);
if l_104 {
break;
}
l_mut_98 = l_mut_98 - i32(1);
}
loop {
let l_105 = l_mut_98 >= i32(0);
let l_106 = l_105 && l_mut_33;
let l_107 = !l_106;
if l_107 {
break;
}
l_mut_108 = u32(0);
l_mut_109 = l_mut_98;
loop {
let l_110 = l_mut_109 >= i32(0);
let l_111 = !l_110;
if l_111 {
break;
}
let l_112 = u32(l_mut_109);
let l_113 = l_1 + l_112;
let l_114 = shared_memory_0[l_113];
let l_115 = l_mut_108 << u32(16);
let l_116 = l_114 >> u32(16);
let l_117 = l_115 | l_116;
let l_118 = l_117 / u32(2500);
let l_119 = l_118 * u32(2500);
let l_120 = l_117 - l_119;
let l_121 = l_120 << u32(16);
let l_122 = l_114 & u32(65535);
let l_123 = l_121 | l_122;
let l_124 = l_123 / u32(2500);
let l_125 = l_124 * u32(2500);
let l_126 = l_123 - l_125;
l_mut_108 = l_126;
let l_127 = u32(l_mut_109);
let l_128 = l_1 + l_127;
let l_129 = l_118 << u32(16);
let l_130 = l_129 | l_124;
shared_memory_0[l_128] = l_130;
l_mut_109 = l_mut_109 - i32(1);
}
loop {
let l_131 = l_mut_98 >= i32(0);
let l_132 = !l_131;
if l_132 {
break;
}
let l_133 = u32(l_mut_98);
let l_134 = l_1 + l_133;
let l_135 = shared_memory_0[l_134];
let l_136 = l_135 != u32(0);
if l_136 {
break;
}
l_mut_98 = l_mut_98 - i32(1);
}
l_mut_137 = l_mut_108;
l_mut_43 = u64(0);
let l_138 = l_mut_98 >= i32(0);
if l_138 {
let l_139 = l_mut_137 / u32(50);
let l_140 = l_139 * u32(50);
let l_141 = l_mut_137 - l_140;
l_mut_137 = l_139;
let l_142 = u64(l_141);
let l_143 = u64(1) << u32(bitcast<u64>(l_142));
let l_144 = l_mut_34 & l_143;
l_mut_43 = l_mut_43 | l_144;
l_mut_34 = l_mut_34 | l_143;
let l_145 = l_mut_137 / u32(50);
let l_146 = l_145 * u32(50);
let l_147 = l_mut_137 - l_146;
l_mut_137 = l_145;
let l_148 = u64(l_147);
let l_149 = u64(1) << u32(bitcast<u64>(l_148));
let l_150 = l_mut_34 & l_149;
l_mut_43 = l_mut_43 | l_150;
l_mut_34 = l_mut_34 | l_149;
} else {
loop {
let l_151 = l_mut_137 != u32(0);
let l_152 = !l_151;
if l_152 {
break;
}
let l_153 = l_mut_137 / u32(50);
let l_154 = l_153 * u32(50);
let l_155 = l_mut_137 - l_154;
l_mut_137 = l_153;
let l_156 = u64(l_155);
let l_157 = u64(1) << u32(bitcast<u64>(l_156));
let l_158 = l_mut_34 & l_157;
l_mut_43 = l_mut_43 | l_158;
l_mut_34 = l_mut_34 | l_157;
}
}
let l_159 = l_mut_43 != u64(0);
if l_159 {
l_mut_33 = bool(false);
}
}
if l_mut_33 {
let l_160 = l_1 + u32(0);
shared_memory_0[l_160] = u32(0);
let l_161 = l_1 + u32(1);
shared_memory_0[l_161] = u32(0);
let l_162 = l_1 + u32(2);
shared_memory_0[l_162] = u32(0);
let l_163 = l_1 + u32(3);
shared_memory_0[l_163] = u32(0);
let l_164 = l_1 + u32(4);
shared_memory_0[l_164] = u32(0);
let l_165 = l_1 + u32(5);
shared_memory_0[l_165] = u32(0);
l_mut_43 = u64(0);
let l_166 = a_42[u32(0)];
let l_167 = u64(l_166);
let l_168 = a_37[u32(0)];
let l_169 = u64(l_168);
let l_170 = l_167 * l_169;
let l_171 = l_1 + u32(0);
let l_172 = shared_memory_0[l_171];
let l_173 = u64(l_172);
let l_174 = l_170 + l_173;
let l_175 = l_174 + l_mut_43;
let l_176 = l_1 + u32(0);
let l_177 = u32(bitcast<u64>(l_175));
shared_memory_0[l_176] = l_177;
let l_178 = l_175 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_178;
let l_179 = a_42[u32(0)];
let l_180 = u64(l_179);
let l_181 = a_37[u32(1)];
let l_182 = u64(l_181);
let l_183 = l_180 * l_182;
let l_184 = l_1 + u32(1);
let l_185 = shared_memory_0[l_184];
let l_186 = u64(l_185);
let l_187 = l_183 + l_186;
let l_188 = l_187 + l_mut_43;
let l_189 = l_1 + u32(1);
let l_190 = u32(bitcast<u64>(l_188));
shared_memory_0[l_189] = l_190;
let l_191 = l_188 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_191;
let l_192 = l_1 + u32(2);
let l_193 = u32(bitcast<u64>(l_mut_43));
shared_memory_0[l_192] = l_193;
l_mut_43 = u64(0);
let l_194 = a_42[u32(1)];
let l_195 = u64(l_194);
let l_196 = a_37[u32(0)];
let l_197 = u64(l_196);
let l_198 = l_195 * l_197;
let l_199 = l_1 + u32(1);
let l_200 = shared_memory_0[l_199];
let l_201 = u64(l_200);
let l_202 = l_198 + l_201;
let l_203 = l_202 + l_mut_43;
let l_204 = l_1 + u32(1);
let l_205 = u32(bitcast<u64>(l_203));
shared_memory_0[l_204] = l_205;
let l_206 = l_203 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_206;
let l_207 = a_42[u32(1)];
let l_208 = u64(l_207);
let l_209 = a_37[u32(1)];
let l_210 = u64(l_209);
let l_211 = l_208 * l_210;
let l_212 = l_1 + u32(2);
let l_213 = shared_memory_0[l_212];
let l_214 = u64(l_213);
let l_215 = l_211 + l_214;
let l_216 = l_215 + l_mut_43;
let l_217 = l_1 + u32(2);
let l_218 = u32(bitcast<u64>(l_216));
shared_memory_0[l_217] = l_218;
let l_219 = l_216 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_219;
let l_220 = l_1 + u32(3);
let l_221 = u32(bitcast<u64>(l_mut_43));
shared_memory_0[l_220] = l_221;
l_mut_43 = u64(0);
let l_222 = a_42[u32(2)];
let l_223 = u64(l_222);
let l_224 = a_37[u32(0)];
let l_225 = u64(l_224);
let l_226 = l_223 * l_225;
let l_227 = l_1 + u32(2);
let l_228 = shared_memory_0[l_227];
let l_229 = u64(l_228);
let l_230 = l_226 + l_229;
let l_231 = l_230 + l_mut_43;
let l_232 = l_1 + u32(2);
let l_233 = u32(bitcast<u64>(l_231));
shared_memory_0[l_232] = l_233;
let l_234 = l_231 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_234;
let l_235 = a_42[u32(2)];
let l_236 = u64(l_235);
let l_237 = a_37[u32(1)];
let l_238 = u64(l_237);
let l_239 = l_236 * l_238;
let l_240 = l_1 + u32(3);
let l_241 = shared_memory_0[l_240];
let l_242 = u64(l_241);
let l_243 = l_239 + l_242;
let l_244 = l_243 + l_mut_43;
let l_245 = l_1 + u32(3);
let l_246 = u32(bitcast<u64>(l_244));
shared_memory_0[l_245] = l_246;
let l_247 = l_244 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_247;
let l_248 = l_1 + u32(4);
let l_249 = u32(bitcast<u64>(l_mut_43));
shared_memory_0[l_248] = l_249;
l_mut_43 = u64(0);
let l_250 = a_42[u32(3)];
let l_251 = u64(l_250);
let l_252 = a_37[u32(0)];
let l_253 = u64(l_252);
let l_254 = l_251 * l_253;
let l_255 = l_1 + u32(3);
let l_256 = shared_memory_0[l_255];
let l_257 = u64(l_256);
let l_258 = l_254 + l_257;
let l_259 = l_258 + l_mut_43;
let l_260 = l_1 + u32(3);
let l_261 = u32(bitcast<u64>(l_259));
shared_memory_0[l_260] = l_261;
let l_262 = l_259 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_262;
let l_263 = a_42[u32(3)];
let l_264 = u64(l_263);
let l_265 = a_37[u32(1)];
let l_266 = u64(l_265);
let l_267 = l_264 * l_266;
let l_268 = l_1 + u32(4);
let l_269 = shared_memory_0[l_268];
let l_270 = u64(l_269);
let l_271 = l_267 + l_270;
let l_272 = l_271 + l_mut_43;
let l_273 = l_1 + u32(4);
let l_274 = u32(bitcast<u64>(l_272));
shared_memory_0[l_273] = l_274;
let l_275 = l_272 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_275;
let l_276 = l_1 + u32(5);
let l_277 = u32(bitcast<u64>(l_mut_43));
shared_memory_0[l_276] = l_277;
l_mut_109 = i32(5);
loop {
let l_278 = l_mut_109 >= i32(0);
let l_279 = !l_278;
if l_279 {
break;
}
let l_280 = u32(l_mut_109);
let l_281 = l_1 + l_280;
let l_282 = shared_memory_0[l_281];
let l_283 = l_282 != u32(0);
if l_283 {
break;
}
l_mut_109 = l_mut_109 - i32(1);
}
loop {
let l_284 = l_mut_109 >= i32(0);
let l_285 = l_284 && l_mut_33;
let l_286 = !l_285;
if l_286 {
break;
}
l_mut_137 = u32(0);
l_mut_287 = l_mut_109;
loop {
let l_288 = l_mut_287 >= i32(0);
let l_289 = !l_288;
if l_289 {
break;
}
let l_290 = u32(l_mut_287);
let l_291 = l_1 + l_290;
let l_292 = shared_memory_0[l_291];
let l_293 = l_mut_137 << u32(16);
let l_294 = l_292 >> u32(16);
let l_295 = l_293 | l_294;
let l_296 = l_295 / u32(2500);
let l_297 = l_296 * u32(2500);
let l_298 = l_295 - l_297;
let l_299 = l_298 << u32(16);
let l_300 = l_292 & u32(65535);
let l_301 = l_299 | l_300;
let l_302 = l_301 / u32(2500);
let l_303 = l_302 * u32(2500);
let l_304 = l_301 - l_303;
l_mut_137 = l_304;
let l_305 = u32(l_mut_287);
let l_306 = l_1 + l_305;
let l_307 = l_296 << u32(16);
let l_308 = l_307 | l_302;
shared_memory_0[l_306] = l_308;
l_mut_287 = l_mut_287 - i32(1);
}
loop {
let l_309 = l_mut_109 >= i32(0);
let l_310 = !l_309;
if l_310 {
break;
}
let l_311 = u32(l_mut_109);
let l_312 = l_1 + l_311;
let l_313 = shared_memory_0[l_312];
let l_314 = l_313 != u32(0);
if l_314 {
break;
}
l_mut_109 = l_mut_109 - i32(1);
}
l_mut_108 = l_mut_137;
l_mut_43 = u64(0);
let l_315 = l_mut_109 >= i32(0);
if l_315 {
let l_316 = l_mut_108 / u32(50);
let l_317 = l_316 * u32(50);
let l_318 = l_mut_108 - l_317;
l_mut_108 = l_316;
let l_319 = u64(l_318);
let l_320 = u64(1) << u32(bitcast<u64>(l_319));
let l_321 = l_mut_34 & l_320;
l_mut_43 = l_mut_43 | l_321;
l_mut_34 = l_mut_34 | l_320;
let l_322 = l_mut_108 / u32(50);
let l_323 = l_322 * u32(50);
let l_324 = l_mut_108 - l_323;
l_mut_108 = l_322;
let l_325 = u64(l_324);
let l_326 = u64(1) << u32(bitcast<u64>(l_325));
let l_327 = l_mut_34 & l_326;
l_mut_43 = l_mut_43 | l_327;
l_mut_34 = l_mut_34 | l_326;
} else {
loop {
let l_328 = l_mut_108 != u32(0);
let l_329 = !l_328;
if l_329 {
break;
}
let l_330 = l_mut_108 / u32(50);
let l_331 = l_330 * u32(50);
let l_332 = l_mut_108 - l_331;
l_mut_108 = l_330;
let l_333 = u64(l_332);
let l_334 = u64(1) << u32(bitcast<u64>(l_333));
let l_335 = l_mut_34 & l_334;
l_mut_43 = l_mut_43 | l_335;
l_mut_34 = l_mut_34 | l_334;
}
}
let l_336 = l_mut_43 != u64(0);
if l_336 {
l_mut_33 = bool(false);
}
}
}
}
if l_mut_33 {
let l_337 = u32(bitcast<u64>(l_mut_34));
let l_338 = countOneBits(l_337);
let l_339 = l_mut_34 >> u32(bitcast<u64>(u64(32)));
let l_340 = u32(bitcast<u64>(l_339));
let l_341 = countOneBits(l_340);
let l_342 = l_338 + l_341;
l_mut_137 = l_342;
let l_343 = l_mut_137 == u32(50);
let l_344 = bool(false) || l_343;
if l_344 {
let l_345 = &buffer_4_global[u32(0)];
let l_346 = atomicAdd(l_345, u32(1));let l_347 = l_346 < info.scalars_u32[1];
if l_347 {
let l_348 = u32(4) * l_346;
let l_349 = u32(bitcast<u64>(l_31));
buffer_3_global[l_348] = l_349;
let l_350 = l_348 + u32(1);
let l_351 = l_31 >> u32(bitcast<u64>(u64(32)));
let l_352 = u32(bitcast<u64>(l_351));
buffer_3_global[l_350] = l_352;
let l_353 = l_348 + u32(2);
let l_354 = u32(bitcast<u64>(l_mut_28));
buffer_3_global[l_353] = l_354;
let l_355 = l_348 + u32(3);
let l_356 = l_mut_28 >> u32(bitcast<u64>(u64(32)));
let l_357 = u32(bitcast<u64>(l_356));
buffer_3_global[l_355] = l_357;
}
}
}
l_mut_7 = l_mut_7 + l_6;
}
workgroupBarrier();
let l_358 = local_invocation_id.x == u32(0);
if l_358 {
let l_359 = &buffer_5_global[u32(5)];
let l_360 = atomicAdd(l_359, u32(1));}
}
```
