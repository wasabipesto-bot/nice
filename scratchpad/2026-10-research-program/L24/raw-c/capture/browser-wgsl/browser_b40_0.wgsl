@group(0)
@binding(0)
var<storage, read_write> buffer_0_global: array<atomic<u32>>;

@group(0)
@binding(1)
var<storage, read_write> buffer_1_global: array<atomic<u32>>;

@group(0)
@binding(2)
var<storage, read_write> buffer_2_global: array<u32>;

struct info_st {
   scalars_u32: array<u32, 6>,
   static_meta: array<u32, 6>,
}

@group(0)
@binding(3)
var<storage, read> info: info_st;

var<workgroup> shared_memory_0: array<atomic<u32>, 164>;

var<workgroup> shared_memory_5: array<u32, 1792>;

const WORKGROUP_SIZE_X = 256u;
const WORKGROUP_SIZE_Y = 1u;
const WORKGROUP_SIZE_Z = 1u;

@compute
@workgroup_size(256, 1, 1)
fn detailed_kernel_u32(
    @builtin(global_invocation_id) global_id: vec3<u32>,
    @builtin(local_invocation_id) local_invocation_id: vec3<u32>,
    @builtin(num_workgroups) num_workgroups: vec3<u32>,
) {
var a_13: array<u32, 4>;

var a_28: array<u32, 4>;

var a_41: array<u32, 8>;

var a_263: array<u32, 12>;

var l_mut_193: i32;
var l_mut_203: i32;
var l_mut_558: i32;
var l_mut_1: u32;
var l_mut_10: u32;
var l_mut_18: u32;
var l_mut_170: u32;
var l_mut_171: u32;
var l_mut_172: u32;
var l_mut_202: u32;
var l_mut_231: u32;
l_mut_1 = local_invocation_id.x;
loop {
let l_2 = l_mut_1 < u32(164);
let l_3 = !l_2;
if l_3 {
break;
}
let l_4 = &shared_memory_0[l_mut_1];
atomicStore(l_4,u32(0));
l_mut_1 = l_mut_1 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_6 = local_invocation_id.x * u32(7);
let l_7 = local_invocation_id.x >> u32(5);
let l_8 = l_7 % u32(4);
let l_9 = num_workgroups.x * WORKGROUP_SIZE_X;
l_mut_10 = global_id.x;
loop {
let l_11 = l_mut_10 < info.scalars_u32[4];
let l_12 = !l_11;
if l_12 {
break;
}
let l_14 = info.scalars_u32[0] + l_mut_10;
a_13[u32(0)] = l_14;
let l_15 = a_13[u32(0)];
let l_16 = l_15 < info.scalars_u32[0];
let l_17 = u32(l_16);
l_mut_18 = l_17;
let l_19 = info.scalars_u32[1] + l_mut_18;
a_13[u32(1)] = l_19;
let l_20 = a_13[u32(1)];
let l_21 = l_20 < l_mut_18;
let l_22 = u32(l_21);
l_mut_18 = l_22;
let l_23 = info.scalars_u32[2] + l_mut_18;
a_13[u32(2)] = l_23;
let l_24 = a_13[u32(2)];
let l_25 = l_24 < l_mut_18;
let l_26 = u32(l_25);
l_mut_18 = l_26;
let l_27 = info.scalars_u32[3] + l_mut_18;
a_13[u32(3)] = l_27;
let l_29 = a_13[u32(0)];
let l_30 = l_29 >> u32(0);
let l_31 = l_30 & u32(65535);
a_28[u32(0)] = l_31;
let l_32 = a_13[u32(0)];
let l_33 = l_32 >> u32(16);
let l_34 = l_33 & u32(65535);
a_28[u32(1)] = l_34;
let l_35 = a_13[u32(1)];
let l_36 = l_35 >> u32(0);
let l_37 = l_36 & u32(65535);
a_28[u32(2)] = l_37;
let l_38 = a_13[u32(1)];
let l_39 = l_38 >> u32(16);
let l_40 = l_39 & u32(65535);
a_28[u32(3)] = l_40;
a_41[u32(0)] = u32(0);
a_41[u32(1)] = u32(0);
a_41[u32(2)] = u32(0);
a_41[u32(3)] = u32(0);
a_41[u32(4)] = u32(0);
a_41[u32(5)] = u32(0);
a_41[u32(6)] = u32(0);
a_41[u32(7)] = u32(0);
l_mut_18 = u32(0);
let l_42 = a_28[u32(0)];
let l_43 = a_28[u32(0)];
let l_44 = l_42 * l_43;
let l_45 = a_41[u32(0)];
let l_46 = l_44 + l_45;
let l_47 = l_46 + l_mut_18;
let l_48 = l_47 & u32(65535);
a_41[u32(0)] = l_48;
let l_49 = l_47 >> u32(16);
l_mut_18 = l_49;
let l_50 = a_28[u32(0)];
let l_51 = a_28[u32(1)];
let l_52 = l_50 * l_51;
let l_53 = a_41[u32(1)];
let l_54 = l_52 + l_53;
let l_55 = l_54 + l_mut_18;
let l_56 = l_55 & u32(65535);
a_41[u32(1)] = l_56;
let l_57 = l_55 >> u32(16);
l_mut_18 = l_57;
let l_58 = a_28[u32(0)];
let l_59 = a_28[u32(2)];
let l_60 = l_58 * l_59;
let l_61 = a_41[u32(2)];
let l_62 = l_60 + l_61;
let l_63 = l_62 + l_mut_18;
let l_64 = l_63 & u32(65535);
a_41[u32(2)] = l_64;
let l_65 = l_63 >> u32(16);
l_mut_18 = l_65;
let l_66 = a_28[u32(0)];
let l_67 = a_28[u32(3)];
let l_68 = l_66 * l_67;
let l_69 = a_41[u32(3)];
let l_70 = l_68 + l_69;
let l_71 = l_70 + l_mut_18;
let l_72 = l_71 & u32(65535);
a_41[u32(3)] = l_72;
let l_73 = l_71 >> u32(16);
l_mut_18 = l_73;
a_41[u32(4)] = l_mut_18;
l_mut_18 = u32(0);
let l_74 = a_28[u32(1)];
let l_75 = a_28[u32(0)];
let l_76 = l_74 * l_75;
let l_77 = a_41[u32(1)];
let l_78 = l_76 + l_77;
let l_79 = l_78 + l_mut_18;
let l_80 = l_79 & u32(65535);
a_41[u32(1)] = l_80;
let l_81 = l_79 >> u32(16);
l_mut_18 = l_81;
let l_82 = a_28[u32(1)];
let l_83 = a_28[u32(1)];
let l_84 = l_82 * l_83;
let l_85 = a_41[u32(2)];
let l_86 = l_84 + l_85;
let l_87 = l_86 + l_mut_18;
let l_88 = l_87 & u32(65535);
a_41[u32(2)] = l_88;
let l_89 = l_87 >> u32(16);
l_mut_18 = l_89;
let l_90 = a_28[u32(1)];
let l_91 = a_28[u32(2)];
let l_92 = l_90 * l_91;
let l_93 = a_41[u32(3)];
let l_94 = l_92 + l_93;
let l_95 = l_94 + l_mut_18;
let l_96 = l_95 & u32(65535);
a_41[u32(3)] = l_96;
let l_97 = l_95 >> u32(16);
l_mut_18 = l_97;
let l_98 = a_28[u32(1)];
let l_99 = a_28[u32(3)];
let l_100 = l_98 * l_99;
let l_101 = a_41[u32(4)];
let l_102 = l_100 + l_101;
let l_103 = l_102 + l_mut_18;
let l_104 = l_103 & u32(65535);
a_41[u32(4)] = l_104;
let l_105 = l_103 >> u32(16);
l_mut_18 = l_105;
a_41[u32(5)] = l_mut_18;
l_mut_18 = u32(0);
let l_106 = a_28[u32(2)];
let l_107 = a_28[u32(0)];
let l_108 = l_106 * l_107;
let l_109 = a_41[u32(2)];
let l_110 = l_108 + l_109;
let l_111 = l_110 + l_mut_18;
let l_112 = l_111 & u32(65535);
a_41[u32(2)] = l_112;
let l_113 = l_111 >> u32(16);
l_mut_18 = l_113;
let l_114 = a_28[u32(2)];
let l_115 = a_28[u32(1)];
let l_116 = l_114 * l_115;
let l_117 = a_41[u32(3)];
let l_118 = l_116 + l_117;
let l_119 = l_118 + l_mut_18;
let l_120 = l_119 & u32(65535);
a_41[u32(3)] = l_120;
let l_121 = l_119 >> u32(16);
l_mut_18 = l_121;
let l_122 = a_28[u32(2)];
let l_123 = a_28[u32(2)];
let l_124 = l_122 * l_123;
let l_125 = a_41[u32(4)];
let l_126 = l_124 + l_125;
let l_127 = l_126 + l_mut_18;
let l_128 = l_127 & u32(65535);
a_41[u32(4)] = l_128;
let l_129 = l_127 >> u32(16);
l_mut_18 = l_129;
let l_130 = a_28[u32(2)];
let l_131 = a_28[u32(3)];
let l_132 = l_130 * l_131;
let l_133 = a_41[u32(5)];
let l_134 = l_132 + l_133;
let l_135 = l_134 + l_mut_18;
let l_136 = l_135 & u32(65535);
a_41[u32(5)] = l_136;
let l_137 = l_135 >> u32(16);
l_mut_18 = l_137;
a_41[u32(6)] = l_mut_18;
l_mut_18 = u32(0);
let l_138 = a_28[u32(3)];
let l_139 = a_28[u32(0)];
let l_140 = l_138 * l_139;
let l_141 = a_41[u32(3)];
let l_142 = l_140 + l_141;
let l_143 = l_142 + l_mut_18;
let l_144 = l_143 & u32(65535);
a_41[u32(3)] = l_144;
let l_145 = l_143 >> u32(16);
l_mut_18 = l_145;
let l_146 = a_28[u32(3)];
let l_147 = a_28[u32(1)];
let l_148 = l_146 * l_147;
let l_149 = a_41[u32(4)];
let l_150 = l_148 + l_149;
let l_151 = l_150 + l_mut_18;
let l_152 = l_151 & u32(65535);
a_41[u32(4)] = l_152;
let l_153 = l_151 >> u32(16);
l_mut_18 = l_153;
let l_154 = a_28[u32(3)];
let l_155 = a_28[u32(2)];
let l_156 = l_154 * l_155;
let l_157 = a_41[u32(5)];
let l_158 = l_156 + l_157;
let l_159 = l_158 + l_mut_18;
let l_160 = l_159 & u32(65535);
a_41[u32(5)] = l_160;
let l_161 = l_159 >> u32(16);
l_mut_18 = l_161;
let l_162 = a_28[u32(3)];
let l_163 = a_28[u32(3)];
let l_164 = l_162 * l_163;
let l_165 = a_41[u32(6)];
let l_166 = l_164 + l_165;
let l_167 = l_166 + l_mut_18;
let l_168 = l_167 & u32(65535);
a_41[u32(6)] = l_168;
let l_169 = l_167 >> u32(16);
l_mut_18 = l_169;
a_41[u32(7)] = l_mut_18;
l_mut_18 = u32(0);
l_mut_170 = u32(0);
l_mut_171 = u32(0);
l_mut_172 = u32(0);
let l_173 = l_6 + u32(0);
let l_174 = a_41[u32(0)];
let l_175 = a_41[u32(1)];
let l_176 = l_175 << u32(16);
let l_177 = l_174 | l_176;
shared_memory_5[l_173] = l_177;
let l_178 = l_6 + u32(1);
let l_179 = a_41[u32(2)];
let l_180 = a_41[u32(3)];
let l_181 = l_180 << u32(16);
let l_182 = l_179 | l_181;
shared_memory_5[l_178] = l_182;
let l_183 = l_6 + u32(2);
let l_184 = a_41[u32(4)];
let l_185 = a_41[u32(5)];
let l_186 = l_185 << u32(16);
let l_187 = l_184 | l_186;
shared_memory_5[l_183] = l_187;
let l_188 = l_6 + u32(3);
let l_189 = a_41[u32(6)];
let l_190 = a_41[u32(7)];
let l_191 = l_190 << u32(16);
let l_192 = l_189 | l_191;
shared_memory_5[l_188] = l_192;
l_mut_193 = i32(3);
loop {
let l_194 = l_mut_193 >= i32(0);
let l_195 = !l_194;
if l_195 {
break;
}
let l_196 = u32(l_mut_193);
let l_197 = l_6 + l_196;
let l_198 = shared_memory_5[l_197];
let l_199 = l_198 != u32(0);
if l_199 {
break;
}
l_mut_193 = l_mut_193 - i32(1);
}
loop {
let l_200 = l_mut_193 >= i32(0);
let l_201 = !l_200;
if l_201 {
break;
}
l_mut_202 = u32(0);
l_mut_203 = l_mut_193;
loop {
let l_204 = l_mut_203 >= i32(0);
let l_205 = !l_204;
if l_205 {
break;
}
let l_206 = u32(l_mut_203);
let l_207 = l_6 + l_206;
let l_208 = shared_memory_5[l_207];
let l_209 = l_mut_202 << u32(16);
let l_210 = l_208 >> u32(16);
let l_211 = l_209 | l_210;
let l_212 = l_211 / u32(64000);
let l_213 = l_212 * u32(64000);
let l_214 = l_211 - l_213;
let l_215 = l_214 << u32(16);
let l_216 = l_208 & u32(65535);
let l_217 = l_215 | l_216;
let l_218 = l_217 / u32(64000);
let l_219 = l_218 * u32(64000);
let l_220 = l_217 - l_219;
l_mut_202 = l_220;
let l_221 = u32(l_mut_203);
let l_222 = l_6 + l_221;
let l_223 = l_212 << u32(16);
let l_224 = l_223 | l_218;
shared_memory_5[l_222] = l_224;
l_mut_203 = l_mut_203 - i32(1);
}
loop {
let l_225 = l_mut_193 >= i32(0);
let l_226 = !l_225;
if l_226 {
break;
}
let l_227 = u32(l_mut_193);
let l_228 = l_6 + l_227;
let l_229 = shared_memory_5[l_228];
let l_230 = l_229 != u32(0);
if l_230 {
break;
}
l_mut_193 = l_mut_193 - i32(1);
}
l_mut_231 = l_mut_202;
let l_232 = l_mut_193 >= i32(0);
if l_232 {
let l_233 = l_mut_231 / u32(40);
let l_234 = l_233 * u32(40);
let l_235 = l_mut_231 - l_234;
l_mut_231 = l_233;
let l_236 = l_235 < u32(32);
if l_236 {
let l_237 = u32(1) << l_235;
l_mut_18 = l_mut_18 | l_237;
} else {
let l_238 = l_235 - u32(32);
let l_239 = u32(1) << l_238;
l_mut_170 = l_mut_170 | l_239;
}
let l_240 = l_mut_231 / u32(40);
let l_241 = l_240 * u32(40);
let l_242 = l_mut_231 - l_241;
l_mut_231 = l_240;
let l_243 = l_242 < u32(32);
if l_243 {
let l_244 = u32(1) << l_242;
l_mut_18 = l_mut_18 | l_244;
} else {
let l_245 = l_242 - u32(32);
let l_246 = u32(1) << l_245;
l_mut_170 = l_mut_170 | l_246;
}
let l_247 = l_mut_231 / u32(40);
let l_248 = l_247 * u32(40);
let l_249 = l_mut_231 - l_248;
l_mut_231 = l_247;
let l_250 = l_249 < u32(32);
if l_250 {
let l_251 = u32(1) << l_249;
l_mut_18 = l_mut_18 | l_251;
} else {
let l_252 = l_249 - u32(32);
let l_253 = u32(1) << l_252;
l_mut_170 = l_mut_170 | l_253;
}
} else {
loop {
let l_254 = l_mut_231 != u32(0);
let l_255 = !l_254;
if l_255 {
break;
}
let l_256 = l_mut_231 / u32(40);
let l_257 = l_256 * u32(40);
let l_258 = l_mut_231 - l_257;
l_mut_231 = l_256;
let l_259 = l_258 < u32(32);
if l_259 {
let l_260 = u32(1) << l_258;
l_mut_18 = l_mut_18 | l_260;
} else {
let l_261 = l_258 - u32(32);
let l_262 = u32(1) << l_261;
l_mut_170 = l_mut_170 | l_262;
}
}
}
}
a_263[u32(0)] = u32(0);
a_263[u32(1)] = u32(0);
a_263[u32(2)] = u32(0);
a_263[u32(3)] = u32(0);
a_263[u32(4)] = u32(0);
a_263[u32(5)] = u32(0);
a_263[u32(6)] = u32(0);
a_263[u32(7)] = u32(0);
a_263[u32(8)] = u32(0);
a_263[u32(9)] = u32(0);
a_263[u32(10)] = u32(0);
a_263[u32(11)] = u32(0);
l_mut_231 = u32(0);
let l_264 = a_41[u32(0)];
let l_265 = a_28[u32(0)];
let l_266 = l_264 * l_265;
let l_267 = a_263[u32(0)];
let l_268 = l_266 + l_267;
let l_269 = l_268 + l_mut_231;
let l_270 = l_269 & u32(65535);
a_263[u32(0)] = l_270;
let l_271 = l_269 >> u32(16);
l_mut_231 = l_271;
let l_272 = a_41[u32(0)];
let l_273 = a_28[u32(1)];
let l_274 = l_272 * l_273;
let l_275 = a_263[u32(1)];
let l_276 = l_274 + l_275;
let l_277 = l_276 + l_mut_231;
let l_278 = l_277 & u32(65535);
a_263[u32(1)] = l_278;
let l_279 = l_277 >> u32(16);
l_mut_231 = l_279;
let l_280 = a_41[u32(0)];
let l_281 = a_28[u32(2)];
let l_282 = l_280 * l_281;
let l_283 = a_263[u32(2)];
let l_284 = l_282 + l_283;
let l_285 = l_284 + l_mut_231;
let l_286 = l_285 & u32(65535);
a_263[u32(2)] = l_286;
let l_287 = l_285 >> u32(16);
l_mut_231 = l_287;
let l_288 = a_41[u32(0)];
let l_289 = a_28[u32(3)];
let l_290 = l_288 * l_289;
let l_291 = a_263[u32(3)];
let l_292 = l_290 + l_291;
let l_293 = l_292 + l_mut_231;
let l_294 = l_293 & u32(65535);
a_263[u32(3)] = l_294;
let l_295 = l_293 >> u32(16);
l_mut_231 = l_295;
a_263[u32(4)] = l_mut_231;
l_mut_231 = u32(0);
let l_296 = a_41[u32(1)];
let l_297 = a_28[u32(0)];
let l_298 = l_296 * l_297;
let l_299 = a_263[u32(1)];
let l_300 = l_298 + l_299;
let l_301 = l_300 + l_mut_231;
let l_302 = l_301 & u32(65535);
a_263[u32(1)] = l_302;
let l_303 = l_301 >> u32(16);
l_mut_231 = l_303;
let l_304 = a_41[u32(1)];
let l_305 = a_28[u32(1)];
let l_306 = l_304 * l_305;
let l_307 = a_263[u32(2)];
let l_308 = l_306 + l_307;
let l_309 = l_308 + l_mut_231;
let l_310 = l_309 & u32(65535);
a_263[u32(2)] = l_310;
let l_311 = l_309 >> u32(16);
l_mut_231 = l_311;
let l_312 = a_41[u32(1)];
let l_313 = a_28[u32(2)];
let l_314 = l_312 * l_313;
let l_315 = a_263[u32(3)];
let l_316 = l_314 + l_315;
let l_317 = l_316 + l_mut_231;
let l_318 = l_317 & u32(65535);
a_263[u32(3)] = l_318;
let l_319 = l_317 >> u32(16);
l_mut_231 = l_319;
let l_320 = a_41[u32(1)];
let l_321 = a_28[u32(3)];
let l_322 = l_320 * l_321;
let l_323 = a_263[u32(4)];
let l_324 = l_322 + l_323;
let l_325 = l_324 + l_mut_231;
let l_326 = l_325 & u32(65535);
a_263[u32(4)] = l_326;
let l_327 = l_325 >> u32(16);
l_mut_231 = l_327;
a_263[u32(5)] = l_mut_231;
l_mut_231 = u32(0);
let l_328 = a_41[u32(2)];
let l_329 = a_28[u32(0)];
let l_330 = l_328 * l_329;
let l_331 = a_263[u32(2)];
let l_332 = l_330 + l_331;
let l_333 = l_332 + l_mut_231;
let l_334 = l_333 & u32(65535);
a_263[u32(2)] = l_334;
let l_335 = l_333 >> u32(16);
l_mut_231 = l_335;
let l_336 = a_41[u32(2)];
let l_337 = a_28[u32(1)];
let l_338 = l_336 * l_337;
let l_339 = a_263[u32(3)];
let l_340 = l_338 + l_339;
let l_341 = l_340 + l_mut_231;
let l_342 = l_341 & u32(65535);
a_263[u32(3)] = l_342;
let l_343 = l_341 >> u32(16);
l_mut_231 = l_343;
let l_344 = a_41[u32(2)];
let l_345 = a_28[u32(2)];
let l_346 = l_344 * l_345;
let l_347 = a_263[u32(4)];
let l_348 = l_346 + l_347;
let l_349 = l_348 + l_mut_231;
let l_350 = l_349 & u32(65535);
a_263[u32(4)] = l_350;
let l_351 = l_349 >> u32(16);
l_mut_231 = l_351;
let l_352 = a_41[u32(2)];
let l_353 = a_28[u32(3)];
let l_354 = l_352 * l_353;
let l_355 = a_263[u32(5)];
let l_356 = l_354 + l_355;
let l_357 = l_356 + l_mut_231;
let l_358 = l_357 & u32(65535);
a_263[u32(5)] = l_358;
let l_359 = l_357 >> u32(16);
l_mut_231 = l_359;
a_263[u32(6)] = l_mut_231;
l_mut_231 = u32(0);
let l_360 = a_41[u32(3)];
let l_361 = a_28[u32(0)];
let l_362 = l_360 * l_361;
let l_363 = a_263[u32(3)];
let l_364 = l_362 + l_363;
let l_365 = l_364 + l_mut_231;
let l_366 = l_365 & u32(65535);
a_263[u32(3)] = l_366;
let l_367 = l_365 >> u32(16);
l_mut_231 = l_367;
let l_368 = a_41[u32(3)];
let l_369 = a_28[u32(1)];
let l_370 = l_368 * l_369;
let l_371 = a_263[u32(4)];
let l_372 = l_370 + l_371;
let l_373 = l_372 + l_mut_231;
let l_374 = l_373 & u32(65535);
a_263[u32(4)] = l_374;
let l_375 = l_373 >> u32(16);
l_mut_231 = l_375;
let l_376 = a_41[u32(3)];
let l_377 = a_28[u32(2)];
let l_378 = l_376 * l_377;
let l_379 = a_263[u32(5)];
let l_380 = l_378 + l_379;
let l_381 = l_380 + l_mut_231;
let l_382 = l_381 & u32(65535);
a_263[u32(5)] = l_382;
let l_383 = l_381 >> u32(16);
l_mut_231 = l_383;
let l_384 = a_41[u32(3)];
let l_385 = a_28[u32(3)];
let l_386 = l_384 * l_385;
let l_387 = a_263[u32(6)];
let l_388 = l_386 + l_387;
let l_389 = l_388 + l_mut_231;
let l_390 = l_389 & u32(65535);
a_263[u32(6)] = l_390;
let l_391 = l_389 >> u32(16);
l_mut_231 = l_391;
a_263[u32(7)] = l_mut_231;
l_mut_231 = u32(0);
let l_392 = a_41[u32(4)];
let l_393 = a_28[u32(0)];
let l_394 = l_392 * l_393;
let l_395 = a_263[u32(4)];
let l_396 = l_394 + l_395;
let l_397 = l_396 + l_mut_231;
let l_398 = l_397 & u32(65535);
a_263[u32(4)] = l_398;
let l_399 = l_397 >> u32(16);
l_mut_231 = l_399;
let l_400 = a_41[u32(4)];
let l_401 = a_28[u32(1)];
let l_402 = l_400 * l_401;
let l_403 = a_263[u32(5)];
let l_404 = l_402 + l_403;
let l_405 = l_404 + l_mut_231;
let l_406 = l_405 & u32(65535);
a_263[u32(5)] = l_406;
let l_407 = l_405 >> u32(16);
l_mut_231 = l_407;
let l_408 = a_41[u32(4)];
let l_409 = a_28[u32(2)];
let l_410 = l_408 * l_409;
let l_411 = a_263[u32(6)];
let l_412 = l_410 + l_411;
let l_413 = l_412 + l_mut_231;
let l_414 = l_413 & u32(65535);
a_263[u32(6)] = l_414;
let l_415 = l_413 >> u32(16);
l_mut_231 = l_415;
let l_416 = a_41[u32(4)];
let l_417 = a_28[u32(3)];
let l_418 = l_416 * l_417;
let l_419 = a_263[u32(7)];
let l_420 = l_418 + l_419;
let l_421 = l_420 + l_mut_231;
let l_422 = l_421 & u32(65535);
a_263[u32(7)] = l_422;
let l_423 = l_421 >> u32(16);
l_mut_231 = l_423;
a_263[u32(8)] = l_mut_231;
l_mut_231 = u32(0);
let l_424 = a_41[u32(5)];
let l_425 = a_28[u32(0)];
let l_426 = l_424 * l_425;
let l_427 = a_263[u32(5)];
let l_428 = l_426 + l_427;
let l_429 = l_428 + l_mut_231;
let l_430 = l_429 & u32(65535);
a_263[u32(5)] = l_430;
let l_431 = l_429 >> u32(16);
l_mut_231 = l_431;
let l_432 = a_41[u32(5)];
let l_433 = a_28[u32(1)];
let l_434 = l_432 * l_433;
let l_435 = a_263[u32(6)];
let l_436 = l_434 + l_435;
let l_437 = l_436 + l_mut_231;
let l_438 = l_437 & u32(65535);
a_263[u32(6)] = l_438;
let l_439 = l_437 >> u32(16);
l_mut_231 = l_439;
let l_440 = a_41[u32(5)];
let l_441 = a_28[u32(2)];
let l_442 = l_440 * l_441;
let l_443 = a_263[u32(7)];
let l_444 = l_442 + l_443;
let l_445 = l_444 + l_mut_231;
let l_446 = l_445 & u32(65535);
a_263[u32(7)] = l_446;
let l_447 = l_445 >> u32(16);
l_mut_231 = l_447;
let l_448 = a_41[u32(5)];
let l_449 = a_28[u32(3)];
let l_450 = l_448 * l_449;
let l_451 = a_263[u32(8)];
let l_452 = l_450 + l_451;
let l_453 = l_452 + l_mut_231;
let l_454 = l_453 & u32(65535);
a_263[u32(8)] = l_454;
let l_455 = l_453 >> u32(16);
l_mut_231 = l_455;
a_263[u32(9)] = l_mut_231;
l_mut_231 = u32(0);
let l_456 = a_41[u32(6)];
let l_457 = a_28[u32(0)];
let l_458 = l_456 * l_457;
let l_459 = a_263[u32(6)];
let l_460 = l_458 + l_459;
let l_461 = l_460 + l_mut_231;
let l_462 = l_461 & u32(65535);
a_263[u32(6)] = l_462;
let l_463 = l_461 >> u32(16);
l_mut_231 = l_463;
let l_464 = a_41[u32(6)];
let l_465 = a_28[u32(1)];
let l_466 = l_464 * l_465;
let l_467 = a_263[u32(7)];
let l_468 = l_466 + l_467;
let l_469 = l_468 + l_mut_231;
let l_470 = l_469 & u32(65535);
a_263[u32(7)] = l_470;
let l_471 = l_469 >> u32(16);
l_mut_231 = l_471;
let l_472 = a_41[u32(6)];
let l_473 = a_28[u32(2)];
let l_474 = l_472 * l_473;
let l_475 = a_263[u32(8)];
let l_476 = l_474 + l_475;
let l_477 = l_476 + l_mut_231;
let l_478 = l_477 & u32(65535);
a_263[u32(8)] = l_478;
let l_479 = l_477 >> u32(16);
l_mut_231 = l_479;
let l_480 = a_41[u32(6)];
let l_481 = a_28[u32(3)];
let l_482 = l_480 * l_481;
let l_483 = a_263[u32(9)];
let l_484 = l_482 + l_483;
let l_485 = l_484 + l_mut_231;
let l_486 = l_485 & u32(65535);
a_263[u32(9)] = l_486;
let l_487 = l_485 >> u32(16);
l_mut_231 = l_487;
a_263[u32(10)] = l_mut_231;
l_mut_231 = u32(0);
let l_488 = a_41[u32(7)];
let l_489 = a_28[u32(0)];
let l_490 = l_488 * l_489;
let l_491 = a_263[u32(7)];
let l_492 = l_490 + l_491;
let l_493 = l_492 + l_mut_231;
let l_494 = l_493 & u32(65535);
a_263[u32(7)] = l_494;
let l_495 = l_493 >> u32(16);
l_mut_231 = l_495;
let l_496 = a_41[u32(7)];
let l_497 = a_28[u32(1)];
let l_498 = l_496 * l_497;
let l_499 = a_263[u32(8)];
let l_500 = l_498 + l_499;
let l_501 = l_500 + l_mut_231;
let l_502 = l_501 & u32(65535);
a_263[u32(8)] = l_502;
let l_503 = l_501 >> u32(16);
l_mut_231 = l_503;
let l_504 = a_41[u32(7)];
let l_505 = a_28[u32(2)];
let l_506 = l_504 * l_505;
let l_507 = a_263[u32(9)];
let l_508 = l_506 + l_507;
let l_509 = l_508 + l_mut_231;
let l_510 = l_509 & u32(65535);
a_263[u32(9)] = l_510;
let l_511 = l_509 >> u32(16);
l_mut_231 = l_511;
let l_512 = a_41[u32(7)];
let l_513 = a_28[u32(3)];
let l_514 = l_512 * l_513;
let l_515 = a_263[u32(10)];
let l_516 = l_514 + l_515;
let l_517 = l_516 + l_mut_231;
let l_518 = l_517 & u32(65535);
a_263[u32(10)] = l_518;
let l_519 = l_517 >> u32(16);
l_mut_231 = l_519;
a_263[u32(11)] = l_mut_231;
let l_520 = l_6 + u32(0);
let l_521 = a_263[u32(0)];
let l_522 = a_263[u32(1)];
let l_523 = l_522 << u32(16);
let l_524 = l_521 | l_523;
shared_memory_5[l_520] = l_524;
let l_525 = l_6 + u32(1);
let l_526 = a_263[u32(2)];
let l_527 = a_263[u32(3)];
let l_528 = l_527 << u32(16);
let l_529 = l_526 | l_528;
shared_memory_5[l_525] = l_529;
let l_530 = l_6 + u32(2);
let l_531 = a_263[u32(4)];
let l_532 = a_263[u32(5)];
let l_533 = l_532 << u32(16);
let l_534 = l_531 | l_533;
shared_memory_5[l_530] = l_534;
let l_535 = l_6 + u32(3);
let l_536 = a_263[u32(6)];
let l_537 = a_263[u32(7)];
let l_538 = l_537 << u32(16);
let l_539 = l_536 | l_538;
shared_memory_5[l_535] = l_539;
let l_540 = l_6 + u32(4);
let l_541 = a_263[u32(8)];
let l_542 = a_263[u32(9)];
let l_543 = l_542 << u32(16);
let l_544 = l_541 | l_543;
shared_memory_5[l_540] = l_544;
let l_545 = l_6 + u32(5);
let l_546 = a_263[u32(10)];
let l_547 = a_263[u32(11)];
let l_548 = l_547 << u32(16);
let l_549 = l_546 | l_548;
shared_memory_5[l_545] = l_549;
l_mut_203 = i32(5);
loop {
let l_550 = l_mut_203 >= i32(0);
let l_551 = !l_550;
if l_551 {
break;
}
let l_552 = u32(l_mut_203);
let l_553 = l_6 + l_552;
let l_554 = shared_memory_5[l_553];
let l_555 = l_554 != u32(0);
if l_555 {
break;
}
l_mut_203 = l_mut_203 - i32(1);
}
loop {
let l_556 = l_mut_203 >= i32(0);
let l_557 = !l_556;
if l_557 {
break;
}
l_mut_231 = u32(0);
l_mut_558 = l_mut_203;
loop {
let l_559 = l_mut_558 >= i32(0);
let l_560 = !l_559;
if l_560 {
break;
}
let l_561 = u32(l_mut_558);
let l_562 = l_6 + l_561;
let l_563 = shared_memory_5[l_562];
let l_564 = l_mut_231 << u32(16);
let l_565 = l_563 >> u32(16);
let l_566 = l_564 | l_565;
let l_567 = l_566 / u32(64000);
let l_568 = l_567 * u32(64000);
let l_569 = l_566 - l_568;
let l_570 = l_569 << u32(16);
let l_571 = l_563 & u32(65535);
let l_572 = l_570 | l_571;
let l_573 = l_572 / u32(64000);
let l_574 = l_573 * u32(64000);
let l_575 = l_572 - l_574;
l_mut_231 = l_575;
let l_576 = u32(l_mut_558);
let l_577 = l_6 + l_576;
let l_578 = l_567 << u32(16);
let l_579 = l_578 | l_573;
shared_memory_5[l_577] = l_579;
l_mut_558 = l_mut_558 - i32(1);
}
loop {
let l_580 = l_mut_203 >= i32(0);
let l_581 = !l_580;
if l_581 {
break;
}
let l_582 = u32(l_mut_203);
let l_583 = l_6 + l_582;
let l_584 = shared_memory_5[l_583];
let l_585 = l_584 != u32(0);
if l_585 {
break;
}
l_mut_203 = l_mut_203 - i32(1);
}
l_mut_202 = l_mut_231;
let l_586 = l_mut_203 >= i32(0);
if l_586 {
let l_587 = l_mut_202 / u32(40);
let l_588 = l_587 * u32(40);
let l_589 = l_mut_202 - l_588;
l_mut_202 = l_587;
let l_590 = l_589 < u32(32);
if l_590 {
let l_591 = u32(1) << l_589;
l_mut_18 = l_mut_18 | l_591;
} else {
let l_592 = l_589 - u32(32);
let l_593 = u32(1) << l_592;
l_mut_170 = l_mut_170 | l_593;
}
let l_594 = l_mut_202 / u32(40);
let l_595 = l_594 * u32(40);
let l_596 = l_mut_202 - l_595;
l_mut_202 = l_594;
let l_597 = l_596 < u32(32);
if l_597 {
let l_598 = u32(1) << l_596;
l_mut_18 = l_mut_18 | l_598;
} else {
let l_599 = l_596 - u32(32);
let l_600 = u32(1) << l_599;
l_mut_170 = l_mut_170 | l_600;
}
let l_601 = l_mut_202 / u32(40);
let l_602 = l_601 * u32(40);
let l_603 = l_mut_202 - l_602;
l_mut_202 = l_601;
let l_604 = l_603 < u32(32);
if l_604 {
let l_605 = u32(1) << l_603;
l_mut_18 = l_mut_18 | l_605;
} else {
let l_606 = l_603 - u32(32);
let l_607 = u32(1) << l_606;
l_mut_170 = l_mut_170 | l_607;
}
} else {
loop {
let l_608 = l_mut_202 != u32(0);
let l_609 = !l_608;
if l_609 {
break;
}
let l_610 = l_mut_202 / u32(40);
let l_611 = l_610 * u32(40);
let l_612 = l_mut_202 - l_611;
l_mut_202 = l_610;
let l_613 = l_612 < u32(32);
if l_613 {
let l_614 = u32(1) << l_612;
l_mut_18 = l_mut_18 | l_614;
} else {
let l_615 = l_612 - u32(32);
let l_616 = u32(1) << l_615;
l_mut_170 = l_mut_170 | l_616;
}
}
}
}
let l_617 = countOneBits(l_mut_18);
let l_618 = countOneBits(l_mut_170);
let l_619 = l_617 + l_618;
let l_620 = countOneBits(l_mut_171);
let l_621 = l_619 + l_620;
let l_622 = countOneBits(l_mut_172);
let l_623 = l_621 + l_622;
let l_624 = l_8 * u32(41);
let l_625 = l_624 + l_623;
let l_626 = &shared_memory_0[l_625];
let l_627 = atomicAdd(l_626, u32(1));let l_628 = l_623 > u32(36);
if l_628 {
let l_629 = &buffer_1_global[u32(0)];
let l_630 = atomicAdd(l_629, u32(1));let l_631 = l_630 < info.scalars_u32[5];
if l_631 {
let l_632 = u32(5) * l_630;
let l_633 = a_13[u32(0)];
buffer_2_global[l_632] = l_633;
let l_634 = l_632 + u32(1);
let l_635 = a_13[u32(1)];
buffer_2_global[l_634] = l_635;
let l_636 = l_632 + u32(2);
let l_637 = a_13[u32(2)];
buffer_2_global[l_636] = l_637;
let l_638 = l_632 + u32(3);
let l_639 = a_13[u32(3)];
buffer_2_global[l_638] = l_639;
let l_640 = l_632 + u32(4);
buffer_2_global[l_640] = l_623;
}
}
l_mut_10 = l_mut_10 + l_9;
}
workgroupBarrier();
l_mut_231 = local_invocation_id.x;
loop {
let l_641 = l_mut_231 < u32(41);
let l_642 = !l_641;
if l_642 {
break;
}
l_mut_202 = u32(0);
let l_643 = u32(0) + l_mut_231;
let l_644 = &shared_memory_0[l_643];
let l_645 = atomicLoad(l_644);
l_mut_202 = l_mut_202 + l_645;
let l_646 = u32(41) + l_mut_231;
let l_647 = &shared_memory_0[l_646];
let l_648 = atomicLoad(l_647);
l_mut_202 = l_mut_202 + l_648;
let l_649 = u32(82) + l_mut_231;
let l_650 = &shared_memory_0[l_649];
let l_651 = atomicLoad(l_650);
l_mut_202 = l_mut_202 + l_651;
let l_652 = u32(123) + l_mut_231;
let l_653 = &shared_memory_0[l_652];
let l_654 = atomicLoad(l_653);
l_mut_202 = l_mut_202 + l_654;
let l_655 = l_mut_202 != u32(0);
if l_655 {
let l_656 = &buffer_0_global[l_mut_231];
let l_657 = atomicAdd(l_656, l_mut_202);}
l_mut_231 = l_mut_231 + WORKGROUP_SIZE_X;
}
}