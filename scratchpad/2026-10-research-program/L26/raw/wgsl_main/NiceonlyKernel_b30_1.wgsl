
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
var a_132: array<u32, 1>;

var a_135: array<u32, 3>;

var a_176: array<u32, 3>;

var a_225: array<u32, 3>;

var a_328: array<u32, 1>;

var a_331: array<u32, 2>;

var l_mut_348: i32;
var l_mut_358: i32;
var l_mut_456: i32;
var l_mut_28: u64;
var l_mut_39: u64;
var l_mut_44: u64;
var l_mut_91: u64;
var l_mut_274: u64;
var l_mut_275: u64;
var l_mut_276: u64;
var l_mut_16: u32;
var l_mut_46: u32;
var l_mut_94: u32;
var l_mut_136: u32;
var l_mut_281: u32;
var l_mut_283: u32;
var l_mut_119: bool;
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
a_132[u32(0)] = l_134;
l_mut_136 = u32(0);
let l_137 = a_132[u32(0)];
let l_138 = l_mut_136 << u32(16);
let l_139 = l_137 >> u32(16);
let l_140 = l_138 | l_139;
let l_141 = l_140 / u32(27000);
let l_142 = l_140 % u32(27000);
let l_143 = l_142 << u32(16);
let l_144 = l_137 & u32(65535);
let l_145 = l_143 | l_144;
let l_146 = l_145 % u32(27000);
l_mut_136 = l_146;
let l_147 = l_141 << u32(16);
let l_148 = l_145 / u32(27000);
let l_149 = l_147 | l_148;
a_132[u32(0)] = l_149;
a_135[u32(0)] = l_mut_136;
l_mut_136 = u32(0);
let l_150 = a_132[u32(0)];
let l_151 = l_mut_136 << u32(16);
let l_152 = l_150 >> u32(16);
let l_153 = l_151 | l_152;
let l_154 = l_153 / u32(27000);
let l_155 = l_153 % u32(27000);
let l_156 = l_155 << u32(16);
let l_157 = l_150 & u32(65535);
let l_158 = l_156 | l_157;
let l_159 = l_158 % u32(27000);
l_mut_136 = l_159;
let l_160 = l_154 << u32(16);
let l_161 = l_158 / u32(27000);
let l_162 = l_160 | l_161;
a_132[u32(0)] = l_162;
a_135[u32(1)] = l_mut_136;
l_mut_136 = u32(0);
let l_163 = a_132[u32(0)];
let l_164 = l_mut_136 << u32(16);
let l_165 = l_163 >> u32(16);
let l_166 = l_164 | l_165;
let l_167 = l_166 / u32(27000);
let l_168 = l_166 % u32(27000);
let l_169 = l_168 << u32(16);
let l_170 = l_163 & u32(65535);
let l_171 = l_169 | l_170;
let l_172 = l_171 % u32(27000);
l_mut_136 = l_172;
let l_173 = l_167 << u32(16);
let l_174 = l_171 / u32(27000);
let l_175 = l_173 | l_174;
a_132[u32(0)] = l_175;
a_135[u32(2)] = l_mut_136;
a_176[u32(0)] = u32(0);
a_176[u32(1)] = u32(0);
a_176[u32(2)] = u32(0);
l_mut_136 = u32(0);
let l_177 = a_135[u32(0)];
let l_178 = a_135[u32(0)];
let l_179 = l_177 * l_178;
let l_180 = a_176[u32(0)];
let l_181 = l_179 + l_180;
let l_182 = l_181 + l_mut_136;
let l_183 = l_182 % u32(27000);
a_176[u32(0)] = l_183;
let l_184 = l_182 / u32(27000);
l_mut_136 = l_184;
let l_185 = a_135[u32(0)];
let l_186 = a_135[u32(1)];
let l_187 = l_185 * l_186;
let l_188 = a_176[u32(1)];
let l_189 = l_187 + l_188;
let l_190 = l_189 + l_mut_136;
let l_191 = l_190 % u32(27000);
a_176[u32(1)] = l_191;
let l_192 = l_190 / u32(27000);
l_mut_136 = l_192;
let l_193 = a_135[u32(0)];
let l_194 = a_135[u32(2)];
let l_195 = l_193 * l_194;
let l_196 = a_176[u32(2)];
let l_197 = l_195 + l_196;
let l_198 = l_197 + l_mut_136;
let l_199 = l_198 % u32(27000);
a_176[u32(2)] = l_199;
let l_200 = l_198 / u32(27000);
l_mut_136 = l_200;
l_mut_136 = u32(0);
let l_201 = a_135[u32(1)];
let l_202 = a_135[u32(0)];
let l_203 = l_201 * l_202;
let l_204 = a_176[u32(1)];
let l_205 = l_203 + l_204;
let l_206 = l_205 + l_mut_136;
let l_207 = l_206 % u32(27000);
a_176[u32(1)] = l_207;
let l_208 = l_206 / u32(27000);
l_mut_136 = l_208;
let l_209 = a_135[u32(1)];
let l_210 = a_135[u32(1)];
let l_211 = l_209 * l_210;
let l_212 = a_176[u32(2)];
let l_213 = l_211 + l_212;
let l_214 = l_213 + l_mut_136;
let l_215 = l_214 % u32(27000);
a_176[u32(2)] = l_215;
let l_216 = l_214 / u32(27000);
l_mut_136 = l_216;
l_mut_136 = u32(0);
let l_217 = a_135[u32(2)];
let l_218 = a_135[u32(0)];
let l_219 = l_217 * l_218;
let l_220 = a_176[u32(2)];
let l_221 = l_219 + l_220;
let l_222 = l_221 + l_mut_136;
let l_223 = l_222 % u32(27000);
a_176[u32(2)] = l_223;
let l_224 = l_222 / u32(27000);
l_mut_136 = l_224;
a_225[u32(0)] = u32(0);
a_225[u32(1)] = u32(0);
a_225[u32(2)] = u32(0);
l_mut_136 = u32(0);
let l_226 = a_176[u32(0)];
let l_227 = a_135[u32(0)];
let l_228 = l_226 * l_227;
let l_229 = a_225[u32(0)];
let l_230 = l_228 + l_229;
let l_231 = l_230 + l_mut_136;
let l_232 = l_231 % u32(27000);
a_225[u32(0)] = l_232;
let l_233 = l_231 / u32(27000);
l_mut_136 = l_233;
let l_234 = a_176[u32(0)];
let l_235 = a_135[u32(1)];
let l_236 = l_234 * l_235;
let l_237 = a_225[u32(1)];
let l_238 = l_236 + l_237;
let l_239 = l_238 + l_mut_136;
let l_240 = l_239 % u32(27000);
a_225[u32(1)] = l_240;
let l_241 = l_239 / u32(27000);
l_mut_136 = l_241;
let l_242 = a_176[u32(0)];
let l_243 = a_135[u32(2)];
let l_244 = l_242 * l_243;
let l_245 = a_225[u32(2)];
let l_246 = l_244 + l_245;
let l_247 = l_246 + l_mut_136;
let l_248 = l_247 % u32(27000);
a_225[u32(2)] = l_248;
let l_249 = l_247 / u32(27000);
l_mut_136 = l_249;
l_mut_136 = u32(0);
let l_250 = a_176[u32(1)];
let l_251 = a_135[u32(0)];
let l_252 = l_250 * l_251;
let l_253 = a_225[u32(1)];
let l_254 = l_252 + l_253;
let l_255 = l_254 + l_mut_136;
let l_256 = l_255 % u32(27000);
a_225[u32(1)] = l_256;
let l_257 = l_255 / u32(27000);
l_mut_136 = l_257;
let l_258 = a_176[u32(1)];
let l_259 = a_135[u32(1)];
let l_260 = l_258 * l_259;
let l_261 = a_225[u32(2)];
let l_262 = l_260 + l_261;
let l_263 = l_262 + l_mut_136;
let l_264 = l_263 % u32(27000);
a_225[u32(2)] = l_264;
let l_265 = l_263 / u32(27000);
l_mut_136 = l_265;
l_mut_136 = u32(0);
let l_266 = a_176[u32(2)];
let l_267 = a_135[u32(0)];
let l_268 = l_266 * l_267;
let l_269 = a_225[u32(2)];
let l_270 = l_268 + l_269;
let l_271 = l_270 + l_mut_136;
let l_272 = l_271 % u32(27000);
a_225[u32(2)] = l_272;
let l_273 = l_271 / u32(27000);
l_mut_136 = l_273;
l_mut_274 = u64(0);
l_mut_275 = u64(0);
l_mut_276 = u64(0);
l_mut_136 = u32(0);
loop {
let l_277 = l_mut_136 < u32(2);
let l_278 = !l_277;
if l_278 {
break;
}
let l_279 = l_mut_136 == u32(0);
if l_279 {
let l_280 = a_176[u32(0)];
l_mut_281 = l_280;
} else {
let l_282 = a_225[u32(0)];
l_mut_281 = l_282;
}
l_mut_283 = l_mut_281;
let l_284 = l_mut_283 % u32(30);
l_mut_283 = l_mut_283 / u32(30);
let l_285 = u64(l_284);
let l_286 = u64(1) << u32(bitcast<u64>(l_285));
let l_287 = l_mut_274 & l_286;
l_mut_276 = l_mut_276 | l_287;
l_mut_274 = l_mut_274 | l_286;
let l_288 = l_mut_283 % u32(30);
l_mut_283 = l_mut_283 / u32(30);
let l_289 = u64(l_288);
let l_290 = u64(1) << u32(bitcast<u64>(l_289));
let l_291 = l_mut_274 & l_290;
l_mut_276 = l_mut_276 | l_291;
l_mut_274 = l_mut_274 | l_290;
let l_292 = l_mut_283 % u32(30);
l_mut_283 = l_mut_283 / u32(30);
let l_293 = u64(l_292);
let l_294 = u64(1) << u32(bitcast<u64>(l_293));
let l_295 = l_mut_274 & l_294;
l_mut_276 = l_mut_276 | l_295;
l_mut_274 = l_mut_274 | l_294;
let l_296 = l_mut_136 == u32(0);
if l_296 {
let l_297 = a_176[u32(1)];
l_mut_283 = l_297;
} else {
let l_298 = a_225[u32(1)];
l_mut_283 = l_298;
}
l_mut_281 = l_mut_283;
let l_299 = l_mut_281 % u32(30);
l_mut_281 = l_mut_281 / u32(30);
let l_300 = u64(l_299);
let l_301 = u64(1) << u32(bitcast<u64>(l_300));
let l_302 = l_mut_274 & l_301;
l_mut_276 = l_mut_276 | l_302;
l_mut_274 = l_mut_274 | l_301;
let l_303 = l_mut_281 % u32(30);
l_mut_281 = l_mut_281 / u32(30);
let l_304 = u64(l_303);
let l_305 = u64(1) << u32(bitcast<u64>(l_304));
let l_306 = l_mut_274 & l_305;
l_mut_276 = l_mut_276 | l_306;
l_mut_274 = l_mut_274 | l_305;
let l_307 = l_mut_281 % u32(30);
l_mut_281 = l_mut_281 / u32(30);
let l_308 = u64(l_307);
let l_309 = u64(1) << u32(bitcast<u64>(l_308));
let l_310 = l_mut_274 & l_309;
l_mut_276 = l_mut_276 | l_310;
l_mut_274 = l_mut_274 | l_309;
let l_311 = l_mut_136 == u32(0);
if l_311 {
let l_312 = a_176[u32(2)];
l_mut_283 = l_312;
} else {
let l_313 = a_225[u32(2)];
l_mut_283 = l_313;
}
l_mut_281 = l_mut_283;
let l_314 = l_mut_281 % u32(30);
l_mut_281 = l_mut_281 / u32(30);
let l_315 = u64(l_314);
let l_316 = u64(1) << u32(bitcast<u64>(l_315));
let l_317 = l_mut_274 & l_316;
l_mut_276 = l_mut_276 | l_317;
l_mut_274 = l_mut_274 | l_316;
let l_318 = l_mut_281 % u32(30);
l_mut_281 = l_mut_281 / u32(30);
let l_319 = u64(l_318);
let l_320 = u64(1) << u32(bitcast<u64>(l_319));
let l_321 = l_mut_274 & l_320;
l_mut_276 = l_mut_276 | l_321;
l_mut_274 = l_mut_274 | l_320;
let l_322 = l_mut_281 % u32(30);
l_mut_281 = l_mut_281 / u32(30);
let l_323 = u64(l_322);
let l_324 = u64(1) << u32(bitcast<u64>(l_323));
let l_325 = l_mut_274 & l_324;
l_mut_276 = l_mut_276 | l_325;
l_mut_274 = l_mut_274 | l_324;
l_mut_136 = l_mut_136 + u32(1);
}
let l_326 = l_mut_276 != u64(0);
if l_326 {
l_mut_119 = bool(false);
}
}
l_mut_276 = u64(0);
l_mut_275 = u64(0);
let l_327 = l_mut_119 && bool(false);
if l_327 {
let l_329 = l_112 >> u32(bitcast<u64>(u64(0)));
let l_330 = u32(bitcast<u64>(l_329));
a_328[u32(0)] = l_330;
a_331[u32(0)] = u32(0);
a_331[u32(1)] = u32(0);
l_mut_274 = u64(0);
let l_332 = a_328[u32(0)];
let l_333 = u64(l_332);
let l_334 = a_328[u32(0)];
let l_335 = u64(l_334);
let l_336 = l_333 * l_335;
let l_337 = a_331[u32(0)];
let l_338 = u64(l_337);
let l_339 = l_336 + l_338;
let l_340 = l_339 + l_mut_274;
let l_341 = u32(bitcast<u64>(l_340));
a_331[u32(0)] = l_341;
let l_342 = l_340 >> u32(bitcast<u64>(u64(32)));
l_mut_274 = l_342;
let l_343 = u32(bitcast<u64>(l_mut_274));
a_331[u32(1)] = l_343;
let l_344 = l_14 + u32(0);
let l_345 = a_331[u32(0)];
shared_memory_13[l_344] = l_345;
let l_346 = l_14 + u32(1);
let l_347 = a_331[u32(1)];
shared_memory_13[l_346] = l_347;
l_mut_348 = i32(1);
loop {
let l_349 = l_mut_348 >= i32(0);
let l_350 = !l_349;
if l_350 {
break;
}
let l_351 = u32(l_mut_348);
let l_352 = l_14 + l_351;
let l_353 = shared_memory_13[l_352];
let l_354 = l_353 != u32(0);
if l_354 {
break;
}
l_mut_348 = l_mut_348 - i32(1);
}
loop {
let l_355 = l_mut_348 >= i32(0);
let l_356 = l_355 && l_mut_119;
let l_357 = !l_356;
if l_357 {
break;
}
l_mut_283 = u32(0);
l_mut_358 = l_mut_348;
loop {
let l_359 = l_mut_358 >= i32(0);
let l_360 = !l_359;
if l_360 {
break;
}
let l_361 = u32(l_mut_358);
let l_362 = l_14 + l_361;
let l_363 = shared_memory_13[l_362];
let l_364 = l_mut_283 << u32(16);
let l_365 = l_363 >> u32(16);
let l_366 = l_364 | l_365;
let l_367 = l_366 / u32(27000);
let l_368 = l_367 * u32(27000);
let l_369 = l_366 - l_368;
let l_370 = l_369 << u32(16);
let l_371 = l_363 & u32(65535);
let l_372 = l_370 | l_371;
let l_373 = l_372 / u32(27000);
let l_374 = l_373 * u32(27000);
let l_375 = l_372 - l_374;
l_mut_283 = l_375;
let l_376 = u32(l_mut_358);
let l_377 = l_14 + l_376;
let l_378 = l_367 << u32(16);
let l_379 = l_378 | l_373;
shared_memory_13[l_377] = l_379;
l_mut_358 = l_mut_358 - i32(1);
}
loop {
let l_380 = l_mut_348 >= i32(0);
let l_381 = !l_380;
if l_381 {
break;
}
let l_382 = u32(l_mut_348);
let l_383 = l_14 + l_382;
let l_384 = shared_memory_13[l_383];
let l_385 = l_384 != u32(0);
if l_385 {
break;
}
l_mut_348 = l_mut_348 - i32(1);
}
l_mut_281 = l_mut_283;
l_mut_274 = u64(0);
let l_386 = l_mut_348 >= i32(0);
if l_386 {
let l_387 = l_mut_281 / u32(30);
let l_388 = l_387 * u32(30);
let l_389 = l_mut_281 - l_388;
l_mut_281 = l_387;
let l_390 = u64(l_389);
let l_391 = u64(1) << u32(bitcast<u64>(l_390));
let l_392 = l_mut_276 & l_391;
l_mut_274 = l_mut_274 | l_392;
l_mut_276 = l_mut_276 | l_391;
let l_393 = l_mut_281 / u32(30);
let l_394 = l_393 * u32(30);
let l_395 = l_mut_281 - l_394;
l_mut_281 = l_393;
let l_396 = u64(l_395);
let l_397 = u64(1) << u32(bitcast<u64>(l_396));
let l_398 = l_mut_276 & l_397;
l_mut_274 = l_mut_274 | l_398;
l_mut_276 = l_mut_276 | l_397;
let l_399 = l_mut_281 / u32(30);
let l_400 = l_399 * u32(30);
let l_401 = l_mut_281 - l_400;
l_mut_281 = l_399;
let l_402 = u64(l_401);
let l_403 = u64(1) << u32(bitcast<u64>(l_402));
let l_404 = l_mut_276 & l_403;
l_mut_274 = l_mut_274 | l_404;
l_mut_276 = l_mut_276 | l_403;
} else {
loop {
let l_405 = l_mut_281 != u32(0);
let l_406 = !l_405;
if l_406 {
break;
}
let l_407 = l_mut_281 / u32(30);
let l_408 = l_407 * u32(30);
let l_409 = l_mut_281 - l_408;
l_mut_281 = l_407;
let l_410 = u64(l_409);
let l_411 = u64(1) << u32(bitcast<u64>(l_410));
let l_412 = l_mut_276 & l_411;
l_mut_274 = l_mut_274 | l_412;
l_mut_276 = l_mut_276 | l_411;
}
}
let l_413 = l_mut_274 != u64(0);
if l_413 {
l_mut_119 = bool(false);
}
}
if l_mut_119 {
let l_414 = l_14 + u32(0);
shared_memory_13[l_414] = u32(0);
let l_415 = l_14 + u32(1);
shared_memory_13[l_415] = u32(0);
let l_416 = l_14 + u32(2);
shared_memory_13[l_416] = u32(0);
l_mut_274 = u64(0);
let l_417 = a_331[u32(0)];
let l_418 = u64(l_417);
let l_419 = a_328[u32(0)];
let l_420 = u64(l_419);
let l_421 = l_418 * l_420;
let l_422 = l_14 + u32(0);
let l_423 = shared_memory_13[l_422];
let l_424 = u64(l_423);
let l_425 = l_421 + l_424;
let l_426 = l_425 + l_mut_274;
let l_427 = l_14 + u32(0);
let l_428 = u32(bitcast<u64>(l_426));
shared_memory_13[l_427] = l_428;
let l_429 = l_426 >> u32(bitcast<u64>(u64(32)));
l_mut_274 = l_429;
let l_430 = l_14 + u32(1);
let l_431 = u32(bitcast<u64>(l_mut_274));
shared_memory_13[l_430] = l_431;
l_mut_274 = u64(0);
let l_432 = a_331[u32(1)];
let l_433 = u64(l_432);
let l_434 = a_328[u32(0)];
let l_435 = u64(l_434);
let l_436 = l_433 * l_435;
let l_437 = l_14 + u32(1);
let l_438 = shared_memory_13[l_437];
let l_439 = u64(l_438);
let l_440 = l_436 + l_439;
let l_441 = l_440 + l_mut_274;
let l_442 = l_14 + u32(1);
let l_443 = u32(bitcast<u64>(l_441));
shared_memory_13[l_442] = l_443;
let l_444 = l_441 >> u32(bitcast<u64>(u64(32)));
l_mut_274 = l_444;
let l_445 = l_14 + u32(2);
let l_446 = u32(bitcast<u64>(l_mut_274));
shared_memory_13[l_445] = l_446;
l_mut_358 = i32(2);
loop {
let l_447 = l_mut_358 >= i32(0);
let l_448 = !l_447;
if l_448 {
break;
}
let l_449 = u32(l_mut_358);
let l_450 = l_14 + l_449;
let l_451 = shared_memory_13[l_450];
let l_452 = l_451 != u32(0);
if l_452 {
break;
}
l_mut_358 = l_mut_358 - i32(1);
}
loop {
let l_453 = l_mut_358 >= i32(0);
let l_454 = l_453 && l_mut_119;
let l_455 = !l_454;
if l_455 {
break;
}
l_mut_283 = u32(0);
l_mut_456 = l_mut_358;
loop {
let l_457 = l_mut_456 >= i32(0);
let l_458 = !l_457;
if l_458 {
break;
}
let l_459 = u32(l_mut_456);
let l_460 = l_14 + l_459;
let l_461 = shared_memory_13[l_460];
let l_462 = l_mut_283 << u32(16);
let l_463 = l_461 >> u32(16);
let l_464 = l_462 | l_463;
let l_465 = l_464 / u32(27000);
let l_466 = l_465 * u32(27000);
let l_467 = l_464 - l_466;
let l_468 = l_467 << u32(16);
let l_469 = l_461 & u32(65535);
let l_470 = l_468 | l_469;
let l_471 = l_470 / u32(27000);
let l_472 = l_471 * u32(27000);
let l_473 = l_470 - l_472;
l_mut_283 = l_473;
let l_474 = u32(l_mut_456);
let l_475 = l_14 + l_474;
let l_476 = l_465 << u32(16);
let l_477 = l_476 | l_471;
shared_memory_13[l_475] = l_477;
l_mut_456 = l_mut_456 - i32(1);
}
loop {
let l_478 = l_mut_358 >= i32(0);
let l_479 = !l_478;
if l_479 {
break;
}
let l_480 = u32(l_mut_358);
let l_481 = l_14 + l_480;
let l_482 = shared_memory_13[l_481];
let l_483 = l_482 != u32(0);
if l_483 {
break;
}
l_mut_358 = l_mut_358 - i32(1);
}
l_mut_281 = l_mut_283;
l_mut_274 = u64(0);
let l_484 = l_mut_358 >= i32(0);
if l_484 {
let l_485 = l_mut_281 / u32(30);
let l_486 = l_485 * u32(30);
let l_487 = l_mut_281 - l_486;
l_mut_281 = l_485;
let l_488 = u64(l_487);
let l_489 = u64(1) << u32(bitcast<u64>(l_488));
let l_490 = l_mut_276 & l_489;
l_mut_274 = l_mut_274 | l_490;
l_mut_276 = l_mut_276 | l_489;
let l_491 = l_mut_281 / u32(30);
let l_492 = l_491 * u32(30);
let l_493 = l_mut_281 - l_492;
l_mut_281 = l_491;
let l_494 = u64(l_493);
let l_495 = u64(1) << u32(bitcast<u64>(l_494));
let l_496 = l_mut_276 & l_495;
l_mut_274 = l_mut_274 | l_496;
l_mut_276 = l_mut_276 | l_495;
let l_497 = l_mut_281 / u32(30);
let l_498 = l_497 * u32(30);
let l_499 = l_mut_281 - l_498;
l_mut_281 = l_497;
let l_500 = u64(l_499);
let l_501 = u64(1) << u32(bitcast<u64>(l_500));
let l_502 = l_mut_276 & l_501;
l_mut_274 = l_mut_274 | l_502;
l_mut_276 = l_mut_276 | l_501;
} else {
loop {
let l_503 = l_mut_281 != u32(0);
let l_504 = !l_503;
if l_504 {
break;
}
let l_505 = l_mut_281 / u32(30);
let l_506 = l_505 * u32(30);
let l_507 = l_mut_281 - l_506;
l_mut_281 = l_505;
let l_508 = u64(l_507);
let l_509 = u64(1) << u32(bitcast<u64>(l_508));
let l_510 = l_mut_276 & l_509;
l_mut_274 = l_mut_274 | l_510;
l_mut_276 = l_mut_276 | l_509;
}
}
let l_511 = l_mut_274 != u64(0);
if l_511 {
l_mut_119 = bool(false);
}
}
}
}
if l_mut_119 {
let l_512 = u32(bitcast<u64>(l_mut_276));
let l_513 = countOneBits(l_512);
let l_514 = l_mut_276 >> u32(bitcast<u64>(u64(32)));
let l_515 = u32(bitcast<u64>(l_514));
let l_516 = countOneBits(l_515);
let l_517 = l_513 + l_516;
l_mut_283 = l_517;
let l_518 = l_mut_283 == u32(30);
let l_519 = bool(true) || l_518;
if l_519 {
let l_520 = &buffer_4_global[u32(0)];
let l_521 = atomicAdd(l_520, u32(1));let l_522 = l_521 < info.scalars_u32[6];
if l_522 {
let l_523 = u32(4) * l_521;
let l_524 = u32(bitcast<u64>(l_112));
buffer_3_global[l_523] = l_524;
let l_525 = l_523 + u32(1);
let l_526 = l_112 >> u32(bitcast<u64>(u64(32)));
let l_527 = u32(bitcast<u64>(l_526));
buffer_3_global[l_525] = l_527;
let l_528 = l_523 + u32(2);
let l_529 = u32(bitcast<u64>(l_mut_39));
buffer_3_global[l_528] = l_529;
let l_530 = l_523 + u32(3);
let l_531 = l_mut_39 >> u32(bitcast<u64>(u64(32)));
let l_532 = u32(bitcast<u64>(l_531));
buffer_3_global[l_530] = l_532;
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
