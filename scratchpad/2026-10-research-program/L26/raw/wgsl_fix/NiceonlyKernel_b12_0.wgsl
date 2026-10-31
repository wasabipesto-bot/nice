
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
var a_135: array<u32, 1>;

var a_138: array<u32, 2>;

var l_mut_119: bool;
var l_mut_16: u32;
var l_mut_46: u32;
var l_mut_94: u32;
var l_mut_166: u32;
var l_mut_195: u32;
var l_mut_28: u64;
var l_mut_39: u64;
var l_mut_44: u64;
var l_mut_91: u64;
var l_mut_132: u64;
var l_mut_133: u64;
var l_mut_139: u64;
var l_mut_156: i32;
var l_mut_167: i32;
var l_mut_272: i32;
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
let l_51 = l_50 % u32(19008);
l_mut_46 = l_51;
let l_52 = l_mut_46 << u32(8);
let l_53 = l_23 >> u32(16);
let l_54 = l_53 & u32(255);
let l_55 = l_52 | l_54;
let l_56 = l_55 % u32(19008);
l_mut_46 = l_56;
let l_57 = l_mut_46 << u32(8);
let l_58 = l_23 >> u32(8);
let l_59 = l_58 & u32(255);
let l_60 = l_57 | l_59;
let l_61 = l_60 % u32(19008);
l_mut_46 = l_61;
let l_62 = l_mut_46 << u32(8);
let l_63 = l_23 >> u32(0);
let l_64 = l_63 & u32(255);
let l_65 = l_62 | l_64;
let l_66 = l_65 % u32(19008);
l_mut_46 = l_66;
let l_67 = l_mut_46 << u32(8);
let l_68 = l_20 >> u32(24);
let l_69 = l_68 & u32(255);
let l_70 = l_67 | l_69;
let l_71 = l_70 % u32(19008);
l_mut_46 = l_71;
let l_72 = l_mut_46 << u32(8);
let l_73 = l_20 >> u32(16);
let l_74 = l_73 & u32(255);
let l_75 = l_72 | l_74;
let l_76 = l_75 % u32(19008);
l_mut_46 = l_76;
let l_77 = l_mut_46 << u32(8);
let l_78 = l_20 >> u32(8);
let l_79 = l_78 & u32(255);
let l_80 = l_77 | l_79;
let l_81 = l_80 % u32(19008);
l_mut_46 = l_81;
let l_82 = l_mut_46 << u32(8);
let l_83 = l_20 >> u32(0);
let l_84 = l_83 & u32(255);
let l_85 = l_82 | l_84;
let l_86 = l_85 % u32(19008);
l_mut_46 = l_86;
let l_87 = info.scalars_u32[4] + l_mut_46;
let l_88 = l_87 % u32(19008);
let l_89 = u64(l_88);
let l_90 = l_38 - l_89;
l_mut_91 = l_mut_39;
let l_92 = u64(l_88);
let l_93 = l_38 < l_92;
if l_93 {
l_mut_91 = l_mut_91 - u64(1);
}
l_mut_46 = u32(0);
l_mut_94 = u32(422);
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
let l_103 = l_mut_46 / u32(422);
let l_104 = l_103 * u32(422);
let l_105 = l_mut_46 - l_104;
let l_106 = u64(l_103);
let l_107 = u64(u32(19008));
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
a_138[u32(0)] = u32(0);
a_138[u32(1)] = u32(0);
l_mut_139 = u64(0);
let l_140 = a_135[u32(0)];
let l_141 = u64(l_140);
let l_142 = a_135[u32(0)];
let l_143 = u64(l_142);
let l_144 = l_141 * l_143;
let l_145 = a_138[u32(0)];
let l_146 = u64(l_145);
let l_147 = l_144 + l_146;
let l_148 = l_147 + l_mut_139;
let l_149 = u32(bitcast<u64>(l_148));
a_138[u32(0)] = l_149;
let l_150 = l_148 >> u32(bitcast<u64>(u64(32)));
l_mut_139 = l_150;
let l_151 = u32(bitcast<u64>(l_mut_139));
a_138[u32(1)] = l_151;
let l_152 = l_14 + u32(0);
let l_153 = a_138[u32(0)];
shared_memory_13[l_152] = l_153;
let l_154 = l_14 + u32(1);
let l_155 = a_138[u32(1)];
shared_memory_13[l_154] = l_155;
l_mut_156 = i32(1);
loop {
let l_157 = l_mut_156 >= i32(0);
let l_158 = !l_157;
if l_158 {
break;
}
let l_159 = u32(l_mut_156);
let l_160 = l_14 + l_159;
let l_161 = shared_memory_13[l_160];
let l_162 = l_161 != u32(0);
if l_162 {
break;
}
l_mut_156 = l_mut_156 - i32(1);
}
loop {
let l_163 = l_mut_156 >= i32(0);
let l_164 = l_163 && l_mut_119;
let l_165 = !l_164;
if l_165 {
break;
}
l_mut_166 = u32(0);
l_mut_167 = l_mut_156;
loop {
let l_168 = l_mut_167 >= i32(0);
let l_169 = !l_168;
if l_169 {
break;
}
let l_170 = u32(l_mut_167);
let l_171 = l_14 + l_170;
let l_172 = shared_memory_13[l_171];
let l_173 = l_mut_166 << u32(16);
let l_174 = l_172 >> u32(16);
let l_175 = l_173 | l_174;
let l_176 = l_175 / u32(20736);
let l_177 = l_176 * u32(20736);
let l_178 = l_175 - l_177;
let l_179 = l_178 << u32(16);
let l_180 = l_172 & u32(65535);
let l_181 = l_179 | l_180;
let l_182 = l_181 / u32(20736);
let l_183 = l_182 * u32(20736);
let l_184 = l_181 - l_183;
l_mut_166 = l_184;
let l_185 = u32(l_mut_167);
let l_186 = l_14 + l_185;
let l_187 = l_176 << u32(16);
let l_188 = l_187 | l_182;
shared_memory_13[l_186] = l_188;
l_mut_167 = l_mut_167 - i32(1);
}
loop {
let l_189 = l_mut_156 >= i32(0);
let l_190 = !l_189;
if l_190 {
break;
}
let l_191 = u32(l_mut_156);
let l_192 = l_14 + l_191;
let l_193 = shared_memory_13[l_192];
let l_194 = l_193 != u32(0);
if l_194 {
break;
}
l_mut_156 = l_mut_156 - i32(1);
}
l_mut_195 = l_mut_166;
l_mut_139 = u64(0);
let l_196 = l_mut_156 >= i32(0);
if l_196 {
let l_197 = l_mut_195 / u32(12);
let l_198 = l_197 * u32(12);
let l_199 = l_mut_195 - l_198;
l_mut_195 = l_197;
let l_200 = u64(l_199);
let l_201 = u64(1) << u32(bitcast<u64>(l_200));
let l_202 = l_mut_132 & l_201;
l_mut_139 = l_mut_139 | l_202;
l_mut_132 = l_mut_132 | l_201;
let l_203 = l_mut_195 / u32(12);
let l_204 = l_203 * u32(12);
let l_205 = l_mut_195 - l_204;
l_mut_195 = l_203;
let l_206 = u64(l_205);
let l_207 = u64(1) << u32(bitcast<u64>(l_206));
let l_208 = l_mut_132 & l_207;
l_mut_139 = l_mut_139 | l_208;
l_mut_132 = l_mut_132 | l_207;
let l_209 = l_mut_195 / u32(12);
let l_210 = l_209 * u32(12);
let l_211 = l_mut_195 - l_210;
l_mut_195 = l_209;
let l_212 = u64(l_211);
let l_213 = u64(1) << u32(bitcast<u64>(l_212));
let l_214 = l_mut_132 & l_213;
l_mut_139 = l_mut_139 | l_214;
l_mut_132 = l_mut_132 | l_213;
let l_215 = l_mut_195 / u32(12);
let l_216 = l_215 * u32(12);
let l_217 = l_mut_195 - l_216;
l_mut_195 = l_215;
let l_218 = u64(l_217);
let l_219 = u64(1) << u32(bitcast<u64>(l_218));
let l_220 = l_mut_132 & l_219;
l_mut_139 = l_mut_139 | l_220;
l_mut_132 = l_mut_132 | l_219;
} else {
loop {
let l_221 = l_mut_195 != u32(0);
let l_222 = !l_221;
if l_222 {
break;
}
let l_223 = l_mut_195 / u32(12);
let l_224 = l_223 * u32(12);
let l_225 = l_mut_195 - l_224;
l_mut_195 = l_223;
let l_226 = u64(l_225);
let l_227 = u64(1) << u32(bitcast<u64>(l_226));
let l_228 = l_mut_132 & l_227;
l_mut_139 = l_mut_139 | l_228;
l_mut_132 = l_mut_132 | l_227;
}
}
let l_229 = l_mut_139 != u64(0);
if l_229 {
l_mut_119 = bool(false);
}
}
if l_mut_119 {
let l_230 = l_14 + u32(0);
shared_memory_13[l_230] = u32(0);
let l_231 = l_14 + u32(1);
shared_memory_13[l_231] = u32(0);
let l_232 = l_14 + u32(2);
shared_memory_13[l_232] = u32(0);
l_mut_139 = u64(0);
let l_233 = a_138[u32(0)];
let l_234 = u64(l_233);
let l_235 = a_135[u32(0)];
let l_236 = u64(l_235);
let l_237 = l_234 * l_236;
let l_238 = l_14 + u32(0);
let l_239 = shared_memory_13[l_238];
let l_240 = u64(l_239);
let l_241 = l_237 + l_240;
let l_242 = l_241 + l_mut_139;
let l_243 = l_14 + u32(0);
let l_244 = u32(bitcast<u64>(l_242));
shared_memory_13[l_243] = l_244;
let l_245 = l_242 >> u32(bitcast<u64>(u64(32)));
l_mut_139 = l_245;
let l_246 = l_14 + u32(1);
let l_247 = u32(bitcast<u64>(l_mut_139));
shared_memory_13[l_246] = l_247;
l_mut_139 = u64(0);
let l_248 = a_138[u32(1)];
let l_249 = u64(l_248);
let l_250 = a_135[u32(0)];
let l_251 = u64(l_250);
let l_252 = l_249 * l_251;
let l_253 = l_14 + u32(1);
let l_254 = shared_memory_13[l_253];
let l_255 = u64(l_254);
let l_256 = l_252 + l_255;
let l_257 = l_256 + l_mut_139;
let l_258 = l_14 + u32(1);
let l_259 = u32(bitcast<u64>(l_257));
shared_memory_13[l_258] = l_259;
let l_260 = l_257 >> u32(bitcast<u64>(u64(32)));
l_mut_139 = l_260;
let l_261 = l_14 + u32(2);
let l_262 = u32(bitcast<u64>(l_mut_139));
shared_memory_13[l_261] = l_262;
l_mut_167 = i32(2);
loop {
let l_263 = l_mut_167 >= i32(0);
let l_264 = !l_263;
if l_264 {
break;
}
let l_265 = u32(l_mut_167);
let l_266 = l_14 + l_265;
let l_267 = shared_memory_13[l_266];
let l_268 = l_267 != u32(0);
if l_268 {
break;
}
l_mut_167 = l_mut_167 - i32(1);
}
loop {
let l_269 = l_mut_167 >= i32(0);
let l_270 = l_269 && l_mut_119;
let l_271 = !l_270;
if l_271 {
break;
}
l_mut_195 = u32(0);
l_mut_272 = l_mut_167;
loop {
let l_273 = l_mut_272 >= i32(0);
let l_274 = !l_273;
if l_274 {
break;
}
let l_275 = u32(l_mut_272);
let l_276 = l_14 + l_275;
let l_277 = shared_memory_13[l_276];
let l_278 = l_mut_195 << u32(16);
let l_279 = l_277 >> u32(16);
let l_280 = l_278 | l_279;
let l_281 = l_280 / u32(20736);
let l_282 = l_281 * u32(20736);
let l_283 = l_280 - l_282;
let l_284 = l_283 << u32(16);
let l_285 = l_277 & u32(65535);
let l_286 = l_284 | l_285;
let l_287 = l_286 / u32(20736);
let l_288 = l_287 * u32(20736);
let l_289 = l_286 - l_288;
l_mut_195 = l_289;
let l_290 = u32(l_mut_272);
let l_291 = l_14 + l_290;
let l_292 = l_281 << u32(16);
let l_293 = l_292 | l_287;
shared_memory_13[l_291] = l_293;
l_mut_272 = l_mut_272 - i32(1);
}
loop {
let l_294 = l_mut_167 >= i32(0);
let l_295 = !l_294;
if l_295 {
break;
}
let l_296 = u32(l_mut_167);
let l_297 = l_14 + l_296;
let l_298 = shared_memory_13[l_297];
let l_299 = l_298 != u32(0);
if l_299 {
break;
}
l_mut_167 = l_mut_167 - i32(1);
}
l_mut_166 = l_mut_195;
l_mut_139 = u64(0);
let l_300 = l_mut_167 >= i32(0);
if l_300 {
let l_301 = l_mut_166 / u32(12);
let l_302 = l_301 * u32(12);
let l_303 = l_mut_166 - l_302;
l_mut_166 = l_301;
let l_304 = u64(l_303);
let l_305 = u64(1) << u32(bitcast<u64>(l_304));
let l_306 = l_mut_132 & l_305;
l_mut_139 = l_mut_139 | l_306;
l_mut_132 = l_mut_132 | l_305;
let l_307 = l_mut_166 / u32(12);
let l_308 = l_307 * u32(12);
let l_309 = l_mut_166 - l_308;
l_mut_166 = l_307;
let l_310 = u64(l_309);
let l_311 = u64(1) << u32(bitcast<u64>(l_310));
let l_312 = l_mut_132 & l_311;
l_mut_139 = l_mut_139 | l_312;
l_mut_132 = l_mut_132 | l_311;
let l_313 = l_mut_166 / u32(12);
let l_314 = l_313 * u32(12);
let l_315 = l_mut_166 - l_314;
l_mut_166 = l_313;
let l_316 = u64(l_315);
let l_317 = u64(1) << u32(bitcast<u64>(l_316));
let l_318 = l_mut_132 & l_317;
l_mut_139 = l_mut_139 | l_318;
l_mut_132 = l_mut_132 | l_317;
let l_319 = l_mut_166 / u32(12);
let l_320 = l_319 * u32(12);
let l_321 = l_mut_166 - l_320;
l_mut_166 = l_319;
let l_322 = u64(l_321);
let l_323 = u64(1) << u32(bitcast<u64>(l_322));
let l_324 = l_mut_132 & l_323;
l_mut_139 = l_mut_139 | l_324;
l_mut_132 = l_mut_132 | l_323;
} else {
loop {
let l_325 = l_mut_166 != u32(0);
let l_326 = !l_325;
if l_326 {
break;
}
let l_327 = l_mut_166 / u32(12);
let l_328 = l_327 * u32(12);
let l_329 = l_mut_166 - l_328;
l_mut_166 = l_327;
let l_330 = u64(l_329);
let l_331 = u64(1) << u32(bitcast<u64>(l_330));
let l_332 = l_mut_132 & l_331;
l_mut_139 = l_mut_139 | l_332;
l_mut_132 = l_mut_132 | l_331;
}
}
let l_333 = l_mut_139 != u64(0);
if l_333 {
l_mut_119 = bool(false);
}
}
}
}
if l_mut_119 {
let l_334 = u32(bitcast<u64>(l_mut_132));
let l_335 = countOneBits(l_334);
let l_336 = l_mut_132 >> u32(bitcast<u64>(u64(32)));
let l_337 = u32(bitcast<u64>(l_336));
let l_338 = countOneBits(l_337);
let l_339 = l_335 + l_338;
l_mut_195 = l_339;
let l_340 = l_mut_195 == u32(12);
let l_341 = bool(false) || l_340;
if l_341 {
let l_342 = &buffer_4_global[u32(0)];
let l_343 = atomicAdd(l_342, u32(1));let l_344 = l_343 < info.scalars_u32[6];
if l_344 {
let l_345 = u32(4) * l_343;
let l_346 = u32(bitcast<u64>(l_112));
buffer_3_global[l_345] = l_346;
let l_347 = l_345 + u32(1);
let l_348 = l_112 >> u32(bitcast<u64>(u64(32)));
let l_349 = u32(bitcast<u64>(l_348));
buffer_3_global[l_347] = l_349;
let l_350 = l_345 + u32(2);
let l_351 = u32(bitcast<u64>(l_mut_39));
buffer_3_global[l_350] = l_351;
let l_352 = l_345 + u32(3);
let l_353 = l_mut_39 >> u32(bitcast<u64>(u64(32)));
let l_354 = u32(bitcast<u64>(l_353));
buffer_3_global[l_352] = l_354;
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
