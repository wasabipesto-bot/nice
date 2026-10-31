
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

var l_mut_28: u64;
var l_mut_34: u64;
var l_mut_35: u64;
var l_mut_43: u64;
var l_mut_4: u32;
var l_mut_7: u32;
var l_mut_108: u32;
var l_mut_137: u32;
var l_mut_33: bool;
var l_mut_98: i32;
var l_mut_109: i32;
var l_mut_293: i32;
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
let l_118 = l_117 / u32(39304);
let l_119 = l_118 * u32(39304);
let l_120 = l_117 - l_119;
let l_121 = l_120 << u32(16);
let l_122 = l_114 & u32(65535);
let l_123 = l_121 | l_122;
let l_124 = l_123 / u32(39304);
let l_125 = l_124 * u32(39304);
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
let l_139 = l_mut_137 / u32(34);
let l_140 = l_139 * u32(34);
let l_141 = l_mut_137 - l_140;
l_mut_137 = l_139;
let l_142 = u64(l_141);
let l_143 = u64(1) << u32(bitcast<u64>(l_142));
let l_144 = l_mut_34 & l_143;
l_mut_43 = l_mut_43 | l_144;
l_mut_34 = l_mut_34 | l_143;
let l_145 = l_mut_137 / u32(34);
let l_146 = l_145 * u32(34);
let l_147 = l_mut_137 - l_146;
l_mut_137 = l_145;
let l_148 = u64(l_147);
let l_149 = u64(1) << u32(bitcast<u64>(l_148));
let l_150 = l_mut_34 & l_149;
l_mut_43 = l_mut_43 | l_150;
l_mut_34 = l_mut_34 | l_149;
let l_151 = l_mut_137 / u32(34);
let l_152 = l_151 * u32(34);
let l_153 = l_mut_137 - l_152;
l_mut_137 = l_151;
let l_154 = u64(l_153);
let l_155 = u64(1) << u32(bitcast<u64>(l_154));
let l_156 = l_mut_34 & l_155;
l_mut_43 = l_mut_43 | l_156;
l_mut_34 = l_mut_34 | l_155;
} else {
loop {
let l_157 = l_mut_137 != u32(0);
let l_158 = !l_157;
if l_158 {
break;
}
let l_159 = l_mut_137 / u32(34);
let l_160 = l_159 * u32(34);
let l_161 = l_mut_137 - l_160;
l_mut_137 = l_159;
let l_162 = u64(l_161);
let l_163 = u64(1) << u32(bitcast<u64>(l_162));
let l_164 = l_mut_34 & l_163;
l_mut_43 = l_mut_43 | l_164;
l_mut_34 = l_mut_34 | l_163;
}
}
let l_165 = l_mut_43 != u64(0);
if l_165 {
l_mut_33 = bool(false);
}
}
if l_mut_33 {
let l_166 = l_1 + u32(0);
shared_memory_0[l_166] = u32(0);
let l_167 = l_1 + u32(1);
shared_memory_0[l_167] = u32(0);
let l_168 = l_1 + u32(2);
shared_memory_0[l_168] = u32(0);
let l_169 = l_1 + u32(3);
shared_memory_0[l_169] = u32(0);
let l_170 = l_1 + u32(4);
shared_memory_0[l_170] = u32(0);
let l_171 = l_1 + u32(5);
shared_memory_0[l_171] = u32(0);
l_mut_43 = u64(0);
let l_172 = a_42[u32(0)];
let l_173 = u64(l_172);
let l_174 = a_37[u32(0)];
let l_175 = u64(l_174);
let l_176 = l_173 * l_175;
let l_177 = l_1 + u32(0);
let l_178 = shared_memory_0[l_177];
let l_179 = u64(l_178);
let l_180 = l_176 + l_179;
let l_181 = l_180 + l_mut_43;
let l_182 = l_1 + u32(0);
let l_183 = u32(bitcast<u64>(l_181));
shared_memory_0[l_182] = l_183;
let l_184 = l_181 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_184;
let l_185 = a_42[u32(0)];
let l_186 = u64(l_185);
let l_187 = a_37[u32(1)];
let l_188 = u64(l_187);
let l_189 = l_186 * l_188;
let l_190 = l_1 + u32(1);
let l_191 = shared_memory_0[l_190];
let l_192 = u64(l_191);
let l_193 = l_189 + l_192;
let l_194 = l_193 + l_mut_43;
let l_195 = l_1 + u32(1);
let l_196 = u32(bitcast<u64>(l_194));
shared_memory_0[l_195] = l_196;
let l_197 = l_194 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_197;
let l_198 = l_1 + u32(2);
let l_199 = u32(bitcast<u64>(l_mut_43));
shared_memory_0[l_198] = l_199;
l_mut_43 = u64(0);
let l_200 = a_42[u32(1)];
let l_201 = u64(l_200);
let l_202 = a_37[u32(0)];
let l_203 = u64(l_202);
let l_204 = l_201 * l_203;
let l_205 = l_1 + u32(1);
let l_206 = shared_memory_0[l_205];
let l_207 = u64(l_206);
let l_208 = l_204 + l_207;
let l_209 = l_208 + l_mut_43;
let l_210 = l_1 + u32(1);
let l_211 = u32(bitcast<u64>(l_209));
shared_memory_0[l_210] = l_211;
let l_212 = l_209 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_212;
let l_213 = a_42[u32(1)];
let l_214 = u64(l_213);
let l_215 = a_37[u32(1)];
let l_216 = u64(l_215);
let l_217 = l_214 * l_216;
let l_218 = l_1 + u32(2);
let l_219 = shared_memory_0[l_218];
let l_220 = u64(l_219);
let l_221 = l_217 + l_220;
let l_222 = l_221 + l_mut_43;
let l_223 = l_1 + u32(2);
let l_224 = u32(bitcast<u64>(l_222));
shared_memory_0[l_223] = l_224;
let l_225 = l_222 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_225;
let l_226 = l_1 + u32(3);
let l_227 = u32(bitcast<u64>(l_mut_43));
shared_memory_0[l_226] = l_227;
l_mut_43 = u64(0);
let l_228 = a_42[u32(2)];
let l_229 = u64(l_228);
let l_230 = a_37[u32(0)];
let l_231 = u64(l_230);
let l_232 = l_229 * l_231;
let l_233 = l_1 + u32(2);
let l_234 = shared_memory_0[l_233];
let l_235 = u64(l_234);
let l_236 = l_232 + l_235;
let l_237 = l_236 + l_mut_43;
let l_238 = l_1 + u32(2);
let l_239 = u32(bitcast<u64>(l_237));
shared_memory_0[l_238] = l_239;
let l_240 = l_237 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_240;
let l_241 = a_42[u32(2)];
let l_242 = u64(l_241);
let l_243 = a_37[u32(1)];
let l_244 = u64(l_243);
let l_245 = l_242 * l_244;
let l_246 = l_1 + u32(3);
let l_247 = shared_memory_0[l_246];
let l_248 = u64(l_247);
let l_249 = l_245 + l_248;
let l_250 = l_249 + l_mut_43;
let l_251 = l_1 + u32(3);
let l_252 = u32(bitcast<u64>(l_250));
shared_memory_0[l_251] = l_252;
let l_253 = l_250 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_253;
let l_254 = l_1 + u32(4);
let l_255 = u32(bitcast<u64>(l_mut_43));
shared_memory_0[l_254] = l_255;
l_mut_43 = u64(0);
let l_256 = a_42[u32(3)];
let l_257 = u64(l_256);
let l_258 = a_37[u32(0)];
let l_259 = u64(l_258);
let l_260 = l_257 * l_259;
let l_261 = l_1 + u32(3);
let l_262 = shared_memory_0[l_261];
let l_263 = u64(l_262);
let l_264 = l_260 + l_263;
let l_265 = l_264 + l_mut_43;
let l_266 = l_1 + u32(3);
let l_267 = u32(bitcast<u64>(l_265));
shared_memory_0[l_266] = l_267;
let l_268 = l_265 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_268;
let l_269 = a_42[u32(3)];
let l_270 = u64(l_269);
let l_271 = a_37[u32(1)];
let l_272 = u64(l_271);
let l_273 = l_270 * l_272;
let l_274 = l_1 + u32(4);
let l_275 = shared_memory_0[l_274];
let l_276 = u64(l_275);
let l_277 = l_273 + l_276;
let l_278 = l_277 + l_mut_43;
let l_279 = l_1 + u32(4);
let l_280 = u32(bitcast<u64>(l_278));
shared_memory_0[l_279] = l_280;
let l_281 = l_278 >> u32(bitcast<u64>(u64(32)));
l_mut_43 = l_281;
let l_282 = l_1 + u32(5);
let l_283 = u32(bitcast<u64>(l_mut_43));
shared_memory_0[l_282] = l_283;
l_mut_109 = i32(5);
loop {
let l_284 = l_mut_109 >= i32(0);
let l_285 = !l_284;
if l_285 {
break;
}
let l_286 = u32(l_mut_109);
let l_287 = l_1 + l_286;
let l_288 = shared_memory_0[l_287];
let l_289 = l_288 != u32(0);
if l_289 {
break;
}
l_mut_109 = l_mut_109 - i32(1);
}
loop {
let l_290 = l_mut_109 >= i32(0);
let l_291 = l_290 && l_mut_33;
let l_292 = !l_291;
if l_292 {
break;
}
l_mut_137 = u32(0);
l_mut_293 = l_mut_109;
loop {
let l_294 = l_mut_293 >= i32(0);
let l_295 = !l_294;
if l_295 {
break;
}
let l_296 = u32(l_mut_293);
let l_297 = l_1 + l_296;
let l_298 = shared_memory_0[l_297];
let l_299 = l_mut_137 << u32(16);
let l_300 = l_298 >> u32(16);
let l_301 = l_299 | l_300;
let l_302 = l_301 / u32(39304);
let l_303 = l_302 * u32(39304);
let l_304 = l_301 - l_303;
let l_305 = l_304 << u32(16);
let l_306 = l_298 & u32(65535);
let l_307 = l_305 | l_306;
let l_308 = l_307 / u32(39304);
let l_309 = l_308 * u32(39304);
let l_310 = l_307 - l_309;
l_mut_137 = l_310;
let l_311 = u32(l_mut_293);
let l_312 = l_1 + l_311;
let l_313 = l_302 << u32(16);
let l_314 = l_313 | l_308;
shared_memory_0[l_312] = l_314;
l_mut_293 = l_mut_293 - i32(1);
}
loop {
let l_315 = l_mut_109 >= i32(0);
let l_316 = !l_315;
if l_316 {
break;
}
let l_317 = u32(l_mut_109);
let l_318 = l_1 + l_317;
let l_319 = shared_memory_0[l_318];
let l_320 = l_319 != u32(0);
if l_320 {
break;
}
l_mut_109 = l_mut_109 - i32(1);
}
l_mut_108 = l_mut_137;
l_mut_43 = u64(0);
let l_321 = l_mut_109 >= i32(0);
if l_321 {
let l_322 = l_mut_108 / u32(34);
let l_323 = l_322 * u32(34);
let l_324 = l_mut_108 - l_323;
l_mut_108 = l_322;
let l_325 = u64(l_324);
let l_326 = u64(1) << u32(bitcast<u64>(l_325));
let l_327 = l_mut_34 & l_326;
l_mut_43 = l_mut_43 | l_327;
l_mut_34 = l_mut_34 | l_326;
let l_328 = l_mut_108 / u32(34);
let l_329 = l_328 * u32(34);
let l_330 = l_mut_108 - l_329;
l_mut_108 = l_328;
let l_331 = u64(l_330);
let l_332 = u64(1) << u32(bitcast<u64>(l_331));
let l_333 = l_mut_34 & l_332;
l_mut_43 = l_mut_43 | l_333;
l_mut_34 = l_mut_34 | l_332;
let l_334 = l_mut_108 / u32(34);
let l_335 = l_334 * u32(34);
let l_336 = l_mut_108 - l_335;
l_mut_108 = l_334;
let l_337 = u64(l_336);
let l_338 = u64(1) << u32(bitcast<u64>(l_337));
let l_339 = l_mut_34 & l_338;
l_mut_43 = l_mut_43 | l_339;
l_mut_34 = l_mut_34 | l_338;
} else {
loop {
let l_340 = l_mut_108 != u32(0);
let l_341 = !l_340;
if l_341 {
break;
}
let l_342 = l_mut_108 / u32(34);
let l_343 = l_342 * u32(34);
let l_344 = l_mut_108 - l_343;
l_mut_108 = l_342;
let l_345 = u64(l_344);
let l_346 = u64(1) << u32(bitcast<u64>(l_345));
let l_347 = l_mut_34 & l_346;
l_mut_43 = l_mut_43 | l_347;
l_mut_34 = l_mut_34 | l_346;
}
}
let l_348 = l_mut_43 != u64(0);
if l_348 {
l_mut_33 = bool(false);
}
}
}
}
if l_mut_33 {
let l_349 = u32(bitcast<u64>(l_mut_34));
let l_350 = countOneBits(l_349);
let l_351 = l_mut_34 >> u32(bitcast<u64>(u64(32)));
let l_352 = u32(bitcast<u64>(l_351));
let l_353 = countOneBits(l_352);
let l_354 = l_350 + l_353;
l_mut_137 = l_354;
let l_355 = l_mut_137 == u32(34);
let l_356 = bool(false) || l_355;
if l_356 {
let l_357 = &buffer_4_global[u32(0)];
let l_358 = atomicAdd(l_357, u32(1));let l_359 = l_358 < info.scalars_u32[1];
if l_359 {
let l_360 = u32(4) * l_358;
let l_361 = u32(bitcast<u64>(l_31));
buffer_3_global[l_360] = l_361;
let l_362 = l_360 + u32(1);
let l_363 = l_31 >> u32(bitcast<u64>(u64(32)));
let l_364 = u32(bitcast<u64>(l_363));
buffer_3_global[l_362] = l_364;
let l_365 = l_360 + u32(2);
let l_366 = u32(bitcast<u64>(l_mut_28));
buffer_3_global[l_365] = l_366;
let l_367 = l_360 + u32(3);
let l_368 = l_mut_28 >> u32(bitcast<u64>(u64(32)));
let l_369 = u32(bitcast<u64>(l_368));
buffer_3_global[l_367] = l_369;
}
}
}
l_mut_7 = l_mut_7 + l_6;
}
workgroupBarrier();
let l_370 = local_invocation_id.x == u32(0);
if l_370 {
let l_371 = &buffer_5_global[u32(5)];
let l_372 = atomicAdd(l_371, u32(1));}
}
```
