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

var<workgroup> shared_memory_0: array<atomic<u32>, 44>;

var<workgroup> shared_memory_5: array<u32, 768>;

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

var a_28: array<u32, 2>;

var a_35: array<u32, 4>;

var a_158: array<u32, 6>;

var l_mut_1: u32;
var l_mut_10: u32;
var l_mut_18: u32;
var l_mut_68: u32;
var l_mut_69: u32;
var l_mut_70: u32;
var l_mut_90: u32;
var l_mut_119: u32;
var l_mut_81: i32;
var l_mut_91: i32;
var l_mut_246: i32;
l_mut_1 = local_invocation_id.x;
loop {
let l_2 = l_mut_1 < u32(44);
let l_3 = !l_2;
if l_3 {
break;
}
let l_4 = &shared_memory_0[l_mut_1];
atomicStore(l_4,u32(0));
l_mut_1 = l_mut_1 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_6 = local_invocation_id.x * u32(3);
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
a_35[u32(0)] = u32(0);
a_35[u32(1)] = u32(0);
a_35[u32(2)] = u32(0);
a_35[u32(3)] = u32(0);
l_mut_18 = u32(0);
let l_36 = a_28[u32(0)];
let l_37 = a_28[u32(0)];
let l_38 = l_36 * l_37;
let l_39 = a_35[u32(0)];
let l_40 = l_38 + l_39;
let l_41 = l_40 + l_mut_18;
let l_42 = l_41 & u32(65535);
a_35[u32(0)] = l_42;
let l_43 = l_41 >> u32(16);
l_mut_18 = l_43;
let l_44 = a_28[u32(0)];
let l_45 = a_28[u32(1)];
let l_46 = l_44 * l_45;
let l_47 = a_35[u32(1)];
let l_48 = l_46 + l_47;
let l_49 = l_48 + l_mut_18;
let l_50 = l_49 & u32(65535);
a_35[u32(1)] = l_50;
let l_51 = l_49 >> u32(16);
l_mut_18 = l_51;
a_35[u32(2)] = l_mut_18;
l_mut_18 = u32(0);
let l_52 = a_28[u32(1)];
let l_53 = a_28[u32(0)];
let l_54 = l_52 * l_53;
let l_55 = a_35[u32(1)];
let l_56 = l_54 + l_55;
let l_57 = l_56 + l_mut_18;
let l_58 = l_57 & u32(65535);
a_35[u32(1)] = l_58;
let l_59 = l_57 >> u32(16);
l_mut_18 = l_59;
let l_60 = a_28[u32(1)];
let l_61 = a_28[u32(1)];
let l_62 = l_60 * l_61;
let l_63 = a_35[u32(2)];
let l_64 = l_62 + l_63;
let l_65 = l_64 + l_mut_18;
let l_66 = l_65 & u32(65535);
a_35[u32(2)] = l_66;
let l_67 = l_65 >> u32(16);
l_mut_18 = l_67;
a_35[u32(3)] = l_mut_18;
l_mut_18 = u32(0);
l_mut_68 = u32(0);
l_mut_69 = u32(0);
l_mut_70 = u32(0);
let l_71 = l_6 + u32(0);
let l_72 = a_35[u32(0)];
let l_73 = a_35[u32(1)];
let l_74 = l_73 << u32(16);
let l_75 = l_72 | l_74;
shared_memory_5[l_71] = l_75;
let l_76 = l_6 + u32(1);
let l_77 = a_35[u32(2)];
let l_78 = a_35[u32(3)];
let l_79 = l_78 << u32(16);
let l_80 = l_77 | l_79;
shared_memory_5[l_76] = l_80;
l_mut_81 = i32(1);
loop {
let l_82 = l_mut_81 >= i32(0);
let l_83 = !l_82;
if l_83 {
break;
}
let l_84 = u32(l_mut_81);
let l_85 = l_6 + l_84;
let l_86 = shared_memory_5[l_85];
let l_87 = l_86 != u32(0);
if l_87 {
break;
}
l_mut_81 = l_mut_81 - i32(1);
}
loop {
let l_88 = l_mut_81 >= i32(0);
let l_89 = !l_88;
if l_89 {
break;
}
l_mut_90 = u32(0);
l_mut_91 = l_mut_81;
loop {
let l_92 = l_mut_91 >= i32(0);
let l_93 = !l_92;
if l_93 {
break;
}
let l_94 = u32(l_mut_91);
let l_95 = l_6 + l_94;
let l_96 = shared_memory_5[l_95];
let l_97 = l_mut_90 << u32(16);
let l_98 = l_96 >> u32(16);
let l_99 = l_97 | l_98;
let l_100 = l_99 / u32(10000);
let l_101 = l_100 * u32(10000);
let l_102 = l_99 - l_101;
let l_103 = l_102 << u32(16);
let l_104 = l_96 & u32(65535);
let l_105 = l_103 | l_104;
let l_106 = l_105 / u32(10000);
let l_107 = l_106 * u32(10000);
let l_108 = l_105 - l_107;
l_mut_90 = l_108;
let l_109 = u32(l_mut_91);
let l_110 = l_6 + l_109;
let l_111 = l_100 << u32(16);
let l_112 = l_111 | l_106;
shared_memory_5[l_110] = l_112;
l_mut_91 = l_mut_91 - i32(1);
}
loop {
let l_113 = l_mut_81 >= i32(0);
let l_114 = !l_113;
if l_114 {
break;
}
let l_115 = u32(l_mut_81);
let l_116 = l_6 + l_115;
let l_117 = shared_memory_5[l_116];
let l_118 = l_117 != u32(0);
if l_118 {
break;
}
l_mut_81 = l_mut_81 - i32(1);
}
l_mut_119 = l_mut_90;
let l_120 = l_mut_81 >= i32(0);
if l_120 {
let l_121 = l_mut_119 / u32(10);
let l_122 = l_121 * u32(10);
let l_123 = l_mut_119 - l_122;
l_mut_119 = l_121;
let l_124 = l_123 < u32(32);
if l_124 {
let l_125 = u32(1) << l_123;
l_mut_18 = l_mut_18 | l_125;
} else {
let l_126 = l_123 - u32(32);
let l_127 = u32(1) << l_126;
l_mut_68 = l_mut_68 | l_127;
}
let l_128 = l_mut_119 / u32(10);
let l_129 = l_128 * u32(10);
let l_130 = l_mut_119 - l_129;
l_mut_119 = l_128;
let l_131 = l_130 < u32(32);
if l_131 {
let l_132 = u32(1) << l_130;
l_mut_18 = l_mut_18 | l_132;
} else {
let l_133 = l_130 - u32(32);
let l_134 = u32(1) << l_133;
l_mut_68 = l_mut_68 | l_134;
}
let l_135 = l_mut_119 / u32(10);
let l_136 = l_135 * u32(10);
let l_137 = l_mut_119 - l_136;
l_mut_119 = l_135;
let l_138 = l_137 < u32(32);
if l_138 {
let l_139 = u32(1) << l_137;
l_mut_18 = l_mut_18 | l_139;
} else {
let l_140 = l_137 - u32(32);
let l_141 = u32(1) << l_140;
l_mut_68 = l_mut_68 | l_141;
}
let l_142 = l_mut_119 / u32(10);
let l_143 = l_142 * u32(10);
let l_144 = l_mut_119 - l_143;
l_mut_119 = l_142;
let l_145 = l_144 < u32(32);
if l_145 {
let l_146 = u32(1) << l_144;
l_mut_18 = l_mut_18 | l_146;
} else {
let l_147 = l_144 - u32(32);
let l_148 = u32(1) << l_147;
l_mut_68 = l_mut_68 | l_148;
}
} else {
loop {
let l_149 = l_mut_119 != u32(0);
let l_150 = !l_149;
if l_150 {
break;
}
let l_151 = l_mut_119 / u32(10);
let l_152 = l_151 * u32(10);
let l_153 = l_mut_119 - l_152;
l_mut_119 = l_151;
let l_154 = l_153 < u32(32);
if l_154 {
let l_155 = u32(1) << l_153;
l_mut_18 = l_mut_18 | l_155;
} else {
let l_156 = l_153 - u32(32);
let l_157 = u32(1) << l_156;
l_mut_68 = l_mut_68 | l_157;
}
}
}
}
a_158[u32(0)] = u32(0);
a_158[u32(1)] = u32(0);
a_158[u32(2)] = u32(0);
a_158[u32(3)] = u32(0);
a_158[u32(4)] = u32(0);
a_158[u32(5)] = u32(0);
l_mut_119 = u32(0);
let l_159 = a_35[u32(0)];
let l_160 = a_28[u32(0)];
let l_161 = l_159 * l_160;
let l_162 = a_158[u32(0)];
let l_163 = l_161 + l_162;
let l_164 = l_163 + l_mut_119;
let l_165 = l_164 & u32(65535);
a_158[u32(0)] = l_165;
let l_166 = l_164 >> u32(16);
l_mut_119 = l_166;
let l_167 = a_35[u32(0)];
let l_168 = a_28[u32(1)];
let l_169 = l_167 * l_168;
let l_170 = a_158[u32(1)];
let l_171 = l_169 + l_170;
let l_172 = l_171 + l_mut_119;
let l_173 = l_172 & u32(65535);
a_158[u32(1)] = l_173;
let l_174 = l_172 >> u32(16);
l_mut_119 = l_174;
a_158[u32(2)] = l_mut_119;
l_mut_119 = u32(0);
let l_175 = a_35[u32(1)];
let l_176 = a_28[u32(0)];
let l_177 = l_175 * l_176;
let l_178 = a_158[u32(1)];
let l_179 = l_177 + l_178;
let l_180 = l_179 + l_mut_119;
let l_181 = l_180 & u32(65535);
a_158[u32(1)] = l_181;
let l_182 = l_180 >> u32(16);
l_mut_119 = l_182;
let l_183 = a_35[u32(1)];
let l_184 = a_28[u32(1)];
let l_185 = l_183 * l_184;
let l_186 = a_158[u32(2)];
let l_187 = l_185 + l_186;
let l_188 = l_187 + l_mut_119;
let l_189 = l_188 & u32(65535);
a_158[u32(2)] = l_189;
let l_190 = l_188 >> u32(16);
l_mut_119 = l_190;
a_158[u32(3)] = l_mut_119;
l_mut_119 = u32(0);
let l_191 = a_35[u32(2)];
let l_192 = a_28[u32(0)];
let l_193 = l_191 * l_192;
let l_194 = a_158[u32(2)];
let l_195 = l_193 + l_194;
let l_196 = l_195 + l_mut_119;
let l_197 = l_196 & u32(65535);
a_158[u32(2)] = l_197;
let l_198 = l_196 >> u32(16);
l_mut_119 = l_198;
let l_199 = a_35[u32(2)];
let l_200 = a_28[u32(1)];
let l_201 = l_199 * l_200;
let l_202 = a_158[u32(3)];
let l_203 = l_201 + l_202;
let l_204 = l_203 + l_mut_119;
let l_205 = l_204 & u32(65535);
a_158[u32(3)] = l_205;
let l_206 = l_204 >> u32(16);
l_mut_119 = l_206;
a_158[u32(4)] = l_mut_119;
l_mut_119 = u32(0);
let l_207 = a_35[u32(3)];
let l_208 = a_28[u32(0)];
let l_209 = l_207 * l_208;
let l_210 = a_158[u32(3)];
let l_211 = l_209 + l_210;
let l_212 = l_211 + l_mut_119;
let l_213 = l_212 & u32(65535);
a_158[u32(3)] = l_213;
let l_214 = l_212 >> u32(16);
l_mut_119 = l_214;
let l_215 = a_35[u32(3)];
let l_216 = a_28[u32(1)];
let l_217 = l_215 * l_216;
let l_218 = a_158[u32(4)];
let l_219 = l_217 + l_218;
let l_220 = l_219 + l_mut_119;
let l_221 = l_220 & u32(65535);
a_158[u32(4)] = l_221;
let l_222 = l_220 >> u32(16);
l_mut_119 = l_222;
a_158[u32(5)] = l_mut_119;
let l_223 = l_6 + u32(0);
let l_224 = a_158[u32(0)];
let l_225 = a_158[u32(1)];
let l_226 = l_225 << u32(16);
let l_227 = l_224 | l_226;
shared_memory_5[l_223] = l_227;
let l_228 = l_6 + u32(1);
let l_229 = a_158[u32(2)];
let l_230 = a_158[u32(3)];
let l_231 = l_230 << u32(16);
let l_232 = l_229 | l_231;
shared_memory_5[l_228] = l_232;
let l_233 = l_6 + u32(2);
let l_234 = a_158[u32(4)];
let l_235 = a_158[u32(5)];
let l_236 = l_235 << u32(16);
let l_237 = l_234 | l_236;
shared_memory_5[l_233] = l_237;
l_mut_91 = i32(2);
loop {
let l_238 = l_mut_91 >= i32(0);
let l_239 = !l_238;
if l_239 {
break;
}
let l_240 = u32(l_mut_91);
let l_241 = l_6 + l_240;
let l_242 = shared_memory_5[l_241];
let l_243 = l_242 != u32(0);
if l_243 {
break;
}
l_mut_91 = l_mut_91 - i32(1);
}
loop {
let l_244 = l_mut_91 >= i32(0);
let l_245 = !l_244;
if l_245 {
break;
}
l_mut_119 = u32(0);
l_mut_246 = l_mut_91;
loop {
let l_247 = l_mut_246 >= i32(0);
let l_248 = !l_247;
if l_248 {
break;
}
let l_249 = u32(l_mut_246);
let l_250 = l_6 + l_249;
let l_251 = shared_memory_5[l_250];
let l_252 = l_mut_119 << u32(16);
let l_253 = l_251 >> u32(16);
let l_254 = l_252 | l_253;
let l_255 = l_254 / u32(10000);
let l_256 = l_255 * u32(10000);
let l_257 = l_254 - l_256;
let l_258 = l_257 << u32(16);
let l_259 = l_251 & u32(65535);
let l_260 = l_258 | l_259;
let l_261 = l_260 / u32(10000);
let l_262 = l_261 * u32(10000);
let l_263 = l_260 - l_262;
l_mut_119 = l_263;
let l_264 = u32(l_mut_246);
let l_265 = l_6 + l_264;
let l_266 = l_255 << u32(16);
let l_267 = l_266 | l_261;
shared_memory_5[l_265] = l_267;
l_mut_246 = l_mut_246 - i32(1);
}
loop {
let l_268 = l_mut_91 >= i32(0);
let l_269 = !l_268;
if l_269 {
break;
}
let l_270 = u32(l_mut_91);
let l_271 = l_6 + l_270;
let l_272 = shared_memory_5[l_271];
let l_273 = l_272 != u32(0);
if l_273 {
break;
}
l_mut_91 = l_mut_91 - i32(1);
}
l_mut_90 = l_mut_119;
let l_274 = l_mut_91 >= i32(0);
if l_274 {
let l_275 = l_mut_90 / u32(10);
let l_276 = l_275 * u32(10);
let l_277 = l_mut_90 - l_276;
l_mut_90 = l_275;
let l_278 = l_277 < u32(32);
if l_278 {
let l_279 = u32(1) << l_277;
l_mut_18 = l_mut_18 | l_279;
} else {
let l_280 = l_277 - u32(32);
let l_281 = u32(1) << l_280;
l_mut_68 = l_mut_68 | l_281;
}
let l_282 = l_mut_90 / u32(10);
let l_283 = l_282 * u32(10);
let l_284 = l_mut_90 - l_283;
l_mut_90 = l_282;
let l_285 = l_284 < u32(32);
if l_285 {
let l_286 = u32(1) << l_284;
l_mut_18 = l_mut_18 | l_286;
} else {
let l_287 = l_284 - u32(32);
let l_288 = u32(1) << l_287;
l_mut_68 = l_mut_68 | l_288;
}
let l_289 = l_mut_90 / u32(10);
let l_290 = l_289 * u32(10);
let l_291 = l_mut_90 - l_290;
l_mut_90 = l_289;
let l_292 = l_291 < u32(32);
if l_292 {
let l_293 = u32(1) << l_291;
l_mut_18 = l_mut_18 | l_293;
} else {
let l_294 = l_291 - u32(32);
let l_295 = u32(1) << l_294;
l_mut_68 = l_mut_68 | l_295;
}
let l_296 = l_mut_90 / u32(10);
let l_297 = l_296 * u32(10);
let l_298 = l_mut_90 - l_297;
l_mut_90 = l_296;
let l_299 = l_298 < u32(32);
if l_299 {
let l_300 = u32(1) << l_298;
l_mut_18 = l_mut_18 | l_300;
} else {
let l_301 = l_298 - u32(32);
let l_302 = u32(1) << l_301;
l_mut_68 = l_mut_68 | l_302;
}
} else {
loop {
let l_303 = l_mut_90 != u32(0);
let l_304 = !l_303;
if l_304 {
break;
}
let l_305 = l_mut_90 / u32(10);
let l_306 = l_305 * u32(10);
let l_307 = l_mut_90 - l_306;
l_mut_90 = l_305;
let l_308 = l_307 < u32(32);
if l_308 {
let l_309 = u32(1) << l_307;
l_mut_18 = l_mut_18 | l_309;
} else {
let l_310 = l_307 - u32(32);
let l_311 = u32(1) << l_310;
l_mut_68 = l_mut_68 | l_311;
}
}
}
}
let l_312 = countOneBits(l_mut_18);
let l_313 = countOneBits(l_mut_68);
let l_314 = l_312 + l_313;
let l_315 = countOneBits(l_mut_69);
let l_316 = l_314 + l_315;
let l_317 = countOneBits(l_mut_70);
let l_318 = l_316 + l_317;
let l_319 = l_8 * u32(11);
let l_320 = l_319 + l_318;
let l_321 = &shared_memory_0[l_320];
let l_322 = atomicAdd(l_321, u32(1));let l_323 = l_318 > u32(9);
if l_323 {
let l_324 = &buffer_1_global[u32(0)];
let l_325 = atomicAdd(l_324, u32(1));let l_326 = l_325 < info.scalars_u32[5];
if l_326 {
let l_327 = u32(5) * l_325;
let l_328 = a_13[u32(0)];
buffer_2_global[l_327] = l_328;
let l_329 = l_327 + u32(1);
let l_330 = a_13[u32(1)];
buffer_2_global[l_329] = l_330;
let l_331 = l_327 + u32(2);
let l_332 = a_13[u32(2)];
buffer_2_global[l_331] = l_332;
let l_333 = l_327 + u32(3);
let l_334 = a_13[u32(3)];
buffer_2_global[l_333] = l_334;
let l_335 = l_327 + u32(4);
buffer_2_global[l_335] = l_318;
}
}
l_mut_10 = l_mut_10 + l_9;
}
workgroupBarrier();
l_mut_119 = local_invocation_id.x;
loop {
let l_336 = l_mut_119 < u32(11);
let l_337 = !l_336;
if l_337 {
break;
}
l_mut_90 = u32(0);
let l_338 = u32(0) + l_mut_119;
let l_339 = &shared_memory_0[l_338];
let l_340 = atomicLoad(l_339);
l_mut_90 = l_mut_90 + l_340;
let l_341 = u32(11) + l_mut_119;
let l_342 = &shared_memory_0[l_341];
let l_343 = atomicLoad(l_342);
l_mut_90 = l_mut_90 + l_343;
let l_344 = u32(22) + l_mut_119;
let l_345 = &shared_memory_0[l_344];
let l_346 = atomicLoad(l_345);
l_mut_90 = l_mut_90 + l_346;
let l_347 = u32(33) + l_mut_119;
let l_348 = &shared_memory_0[l_347];
let l_349 = atomicLoad(l_348);
l_mut_90 = l_mut_90 + l_349;
let l_350 = l_mut_90 != u32(0);
if l_350 {
let l_351 = &buffer_0_global[l_mut_119];
let l_352 = atomicAdd(l_351, l_mut_90);}
l_mut_119 = l_mut_119 + WORKGROUP_SIZE_X;
}
}