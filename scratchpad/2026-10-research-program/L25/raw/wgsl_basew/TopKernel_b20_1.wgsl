
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
var<storage, read_write> buffer_4_global: array<u32>;

@group(0)
@binding(5)
var<storage, read_write> buffer_5_global: array<u32>;

@group(0)
@binding(6)
var<storage, read_write> buffer_6_global: array<u32>;

@group(0)
@binding(7)
var<storage, read_write> buffer_7_global: array<u32>;

@group(0)
@binding(8)
var<storage, read_write> buffer_8_global: array<u32>;

@group(0)
@binding(9)
var<storage, read_write> buffer_9_global: array<u32>;

@group(0)
@binding(10)
var<storage, read_write> buffer_10_global: array<atomic<u32>>;

@group(0)
@binding(11)
var<storage, read_write> buffer_11_global: array<atomic<u32>>;

@group(0)
@binding(12)
var<storage, read_write> buffer_12_global: array<atomic<u32>>;

struct info_st {
   scalars_u32: array<u32, 6>,
   static_meta: array<u32, 26>,
}

@group(0)
@binding(13)
var<storage, read> info: info_st;

const WORKGROUP_SIZE_X = 256u;
const WORKGROUP_SIZE_Y = 1u;
const WORKGROUP_SIZE_Z = 1u;

@compute
@workgroup_size(256, 1, 1)
fn top_kernel(
    @builtin(global_invocation_id) global_id: vec3<u32>,
    @builtin(local_invocation_id) local_invocation_id: vec3<u32>,
    @builtin(workgroup_id) workgroup_id: vec3<u32>,
) {
var a_39: array<u32, 1>;

var a_40: array<u32, 1>;

var a_63: array<u32, 2>;

var a_64: array<u32, 2>;

var a_91: array<u32, 3>;

var a_92: array<u32, 3>;

var a_147: array<u32, 2>;

var a_141: array<u32, 1>;

var a_142: array<u32, 1>;

var a_145: array<u32, 2>;

var a_444: array<u32, 3>;

var a_143: array<u32, 1>;

var a_144: array<u32, 1>;

var a_146: array<u32, 2>;

var l_mut_47: bool;
var l_mut_48: bool;
var l_mut_49: bool;
var l_mut_50: bool;
var l_mut_172: bool;
var l_mut_173: bool;
var l_mut_988: bool;
var l_mut_42: u32;
var l_mut_45: u32;
var l_mut_152: u32;
var l_mut_167: u32;
var l_mut_177: u32;
var l_mut_194: u32;
var l_mut_195: u32;
var l_mut_196: u32;
var l_mut_197: u32;
var l_mut_65: u64;
var l_mut_66: u64;
var l_mut_953: u64;
let l_0 = global_id.x < info.scalars_u32[0];
if l_0 {
let l_1 = u32(5) * global_id.x;
let l_2 = l_1 + u32(1);
let l_3 = buffer_0_global[l_2];
let l_4 = u64(l_3);
let l_5 = l_4 << u32(bitcast<u64>(u64(32)));
let l_6 = u32(5) * global_id.x;
let l_7 = buffer_0_global[l_6];
let l_8 = u64(l_7);
let l_9 = l_5 | l_8;
let l_10 = buffer_1_global[workgroup_id.y];
let l_11 = u64(info.scalars_u32[3]);
let l_12 = l_9 * l_11;
let l_13 = u64(l_10);
let l_14 = l_12 + l_13;
let l_15 = buffer_2_global[u32(7)];
let l_16 = u64(l_15);
let l_17 = l_16 << u32(bitcast<u64>(u64(32)));
let l_18 = buffer_2_global[u32(6)];
let l_19 = u64(l_18);
let l_20 = l_17 | l_19;
let l_21 = buffer_2_global[u32(9)];
let l_22 = u64(l_21);
let l_23 = l_22 << u32(bitcast<u64>(u64(32)));
let l_24 = buffer_2_global[u32(8)];
let l_25 = u64(l_24);
let l_26 = l_23 | l_25;
let l_27 = l_14 >= l_20;
let l_28 = l_14 <= l_26;
let l_29 = l_27 && l_28;
if l_29 {
let l_30 = l_14 & u64(4294967295);
let l_31 = u64(info.scalars_u32[2]);
let l_32 = l_30 * l_31;
let l_33 = l_14 >> u32(bitcast<u64>(u64(32)));
let l_34 = u64(info.scalars_u32[2]);
let l_35 = l_33 * l_34;
let l_36 = l_32 >> u32(bitcast<u64>(u64(32)));
let l_37 = l_35 + l_36;
let l_38 = u32(bitcast<u64>(l_32));
a_39[u32(0)] = l_38;
let l_41 = info.scalars_u32[2] - u32(1);
l_mut_42 = l_41;
let l_43 = a_39[u32(0)];
let l_44 = l_43 + l_mut_42;
l_mut_45 = u32(0);
let l_46 = l_44 < l_mut_42;
if l_46 {
l_mut_45 = u32(1);
}
a_40[u32(0)] = l_44;
l_mut_42 = l_mut_45;
l_mut_47 = bool(false);
l_mut_48 = bool(false);
l_mut_49 = bool(true);
l_mut_50 = bool(true);
let l_51 = buffer_2_global[u32(0)];
let l_52 = buffer_2_global[u32(3)];
if l_mut_49 {
let l_53 = a_39[u32(0)];
let l_54 = l_53 < l_51;
if l_54 {
l_mut_47 = bool(true);
l_mut_49 = bool(false);
} else {
let l_55 = a_39[u32(0)];
let l_56 = l_55 > l_51;
if l_56 {
l_mut_49 = bool(false);
}
}
}
if l_mut_50 {
let l_57 = a_40[u32(0)];
let l_58 = l_57 > l_52;
if l_58 {
l_mut_48 = bool(true);
l_mut_50 = bool(false);
} else {
let l_59 = a_40[u32(0)];
let l_60 = l_59 < l_52;
if l_60 {
l_mut_50 = bool(false);
}
}
}
if l_mut_47 {
let l_61 = buffer_2_global[u32(0)];
a_39[u32(0)] = l_61;
}
if l_mut_48 {
let l_62 = buffer_2_global[u32(3)];
a_40[u32(0)] = l_62;
}
a_63[u32(0)] = u32(0);
a_64[u32(0)] = u32(0);
a_63[u32(1)] = u32(0);
a_64[u32(1)] = u32(0);
l_mut_65 = u64(0);
l_mut_66 = u64(0);
let l_67 = a_39[u32(0)];
let l_68 = u64(l_67);
let l_69 = a_39[u32(0)];
let l_70 = u64(l_69);
let l_71 = l_68 * l_70;
let l_72 = a_63[u32(0)];
let l_73 = u64(l_72);
let l_74 = l_71 + l_73;
let l_75 = l_74 + l_mut_65;
let l_76 = u32(bitcast<u64>(l_75));
a_63[u32(0)] = l_76;
let l_77 = l_75 >> u32(bitcast<u64>(u64(32)));
l_mut_65 = l_77;
let l_78 = a_40[u32(0)];
let l_79 = u64(l_78);
let l_80 = a_40[u32(0)];
let l_81 = u64(l_80);
let l_82 = l_79 * l_81;
let l_83 = a_64[u32(0)];
let l_84 = u64(l_83);
let l_85 = l_82 + l_84;
let l_86 = l_85 + l_mut_66;
let l_87 = u32(bitcast<u64>(l_86));
a_64[u32(0)] = l_87;
let l_88 = l_86 >> u32(bitcast<u64>(u64(32)));
l_mut_66 = l_88;
let l_89 = u32(bitcast<u64>(l_mut_65));
a_63[u32(1)] = l_89;
let l_90 = u32(bitcast<u64>(l_mut_66));
a_64[u32(1)] = l_90;
a_91[u32(0)] = u32(0);
a_92[u32(0)] = u32(0);
a_91[u32(1)] = u32(0);
a_92[u32(1)] = u32(0);
a_91[u32(2)] = u32(0);
a_92[u32(2)] = u32(0);
l_mut_66 = u64(0);
l_mut_65 = u64(0);
let l_93 = a_63[u32(0)];
let l_94 = u64(l_93);
let l_95 = a_39[u32(0)];
let l_96 = u64(l_95);
let l_97 = l_94 * l_96;
let l_98 = a_91[u32(0)];
let l_99 = u64(l_98);
let l_100 = l_97 + l_99;
let l_101 = l_100 + l_mut_66;
let l_102 = u32(bitcast<u64>(l_101));
a_91[u32(0)] = l_102;
let l_103 = l_101 >> u32(bitcast<u64>(u64(32)));
l_mut_66 = l_103;
let l_104 = a_64[u32(0)];
let l_105 = u64(l_104);
let l_106 = a_40[u32(0)];
let l_107 = u64(l_106);
let l_108 = l_105 * l_107;
let l_109 = a_92[u32(0)];
let l_110 = u64(l_109);
let l_111 = l_108 + l_110;
let l_112 = l_111 + l_mut_65;
let l_113 = u32(bitcast<u64>(l_112));
a_92[u32(0)] = l_113;
let l_114 = l_112 >> u32(bitcast<u64>(u64(32)));
l_mut_65 = l_114;
let l_115 = u32(bitcast<u64>(l_mut_66));
a_91[u32(1)] = l_115;
let l_116 = u32(bitcast<u64>(l_mut_65));
a_92[u32(1)] = l_116;
l_mut_66 = u64(0);
l_mut_65 = u64(0);
let l_117 = a_63[u32(1)];
let l_118 = u64(l_117);
let l_119 = a_39[u32(0)];
let l_120 = u64(l_119);
let l_121 = l_118 * l_120;
let l_122 = a_91[u32(1)];
let l_123 = u64(l_122);
let l_124 = l_121 + l_123;
let l_125 = l_124 + l_mut_66;
let l_126 = u32(bitcast<u64>(l_125));
a_91[u32(1)] = l_126;
let l_127 = l_125 >> u32(bitcast<u64>(u64(32)));
l_mut_66 = l_127;
let l_128 = a_64[u32(1)];
let l_129 = u64(l_128);
let l_130 = a_40[u32(0)];
let l_131 = u64(l_130);
let l_132 = l_129 * l_131;
let l_133 = a_92[u32(1)];
let l_134 = u64(l_133);
let l_135 = l_132 + l_134;
let l_136 = l_135 + l_mut_65;
let l_137 = u32(bitcast<u64>(l_136));
a_92[u32(1)] = l_137;
let l_138 = l_136 >> u32(bitcast<u64>(u64(32)));
l_mut_65 = l_138;
let l_139 = u32(bitcast<u64>(l_mut_66));
a_91[u32(2)] = l_139;
let l_140 = u32(bitcast<u64>(l_mut_65));
a_92[u32(2)] = l_140;
l_mut_45 = u32(0);
let l_148 = a_64[u32(0)];
let l_149 = a_63[u32(0)];
let l_150 = l_148 - l_149;
let l_151 = l_150 - l_mut_45;
l_mut_152 = u32(0);
let l_153 = l_148 < l_149;
let l_154 = l_148 == l_149;
let l_155 = l_mut_45 != u32(0);
let l_156 = l_154 && l_155;
let l_157 = l_153 || l_156;
if l_157 {
l_mut_152 = u32(1);
}
a_147[u32(0)] = l_151;
l_mut_45 = l_mut_152;
let l_158 = a_64[u32(1)];
let l_159 = a_63[u32(1)];
let l_160 = l_158 - l_159;
let l_161 = l_160 - l_mut_45;
l_mut_152 = u32(0);
let l_162 = l_158 < l_159;
let l_163 = l_158 == l_159;
let l_164 = l_mut_45 != u32(0);
let l_165 = l_163 && l_164;
let l_166 = l_162 || l_165;
if l_166 {
l_mut_152 = u32(1);
}
a_147[u32(1)] = l_161;
l_mut_45 = l_mut_152;
l_mut_152 = u32(0);
l_mut_167 = u32(8);
loop {
let l_168 = l_mut_152 < l_mut_167;
let l_169 = !l_168;
if l_169 {
break;
}
let l_170 = l_mut_152 + l_mut_167;
let l_171 = l_170 >> u32(1);
l_mut_172 = bool(false);
l_mut_173 = bool(true);
let l_174 = l_171 * u32(3);
let l_175 = l_174 + u32(2);
let l_176 = buffer_3_global[l_175];
l_mut_177 = u32(0);
if l_mut_173 {
let l_178 = l_mut_177 < l_176;
if l_178 {
l_mut_172 = bool(true);
l_mut_173 = bool(false);
} else {
let l_179 = l_mut_177 > l_176;
if l_179 {
l_mut_173 = bool(false);
}
}
}
let l_180 = l_171 * u32(3);
let l_181 = l_180 + u32(1);
let l_182 = buffer_3_global[l_181];
l_mut_177 = u32(0);
let l_183 = a_147[u32(1)];
l_mut_177 = l_183;
if l_mut_173 {
let l_184 = l_mut_177 < l_182;
if l_184 {
l_mut_172 = bool(true);
l_mut_173 = bool(false);
} else {
let l_185 = l_mut_177 > l_182;
if l_185 {
l_mut_173 = bool(false);
}
}
}
let l_186 = l_171 * u32(3);
let l_187 = l_186 + u32(0);
let l_188 = buffer_3_global[l_187];
l_mut_177 = u32(0);
let l_189 = a_147[u32(0)];
l_mut_177 = l_189;
if l_mut_173 {
let l_190 = l_mut_177 < l_188;
if l_190 {
l_mut_172 = bool(true);
l_mut_173 = bool(false);
} else {
let l_191 = l_mut_177 > l_188;
if l_191 {
l_mut_173 = bool(false);
}
}
}
if l_mut_172 {
l_mut_167 = l_171;
} else {
let l_192 = l_171 + u32(1);
l_mut_152 = l_192;
}
}
l_mut_177 = l_mut_152;
let l_193 = l_mut_177 < u32(3);
if l_193 {
l_mut_177 = u32(3);
}
l_mut_66 = u64(0);
l_mut_152 = u32(0);
l_mut_194 = u32(1);
l_mut_195 = u32(0);
l_mut_196 = u32(0);
l_mut_197 = u32(0);
let l_198 = a_63[u32(1)];
let l_199 = l_mut_196 << u32(16);
let l_200 = l_198 >> u32(16);
let l_201 = l_199 | l_200;
let l_202 = l_201 / u32(8000);
let l_203 = l_202 * u32(8000);
let l_204 = l_201 - l_203;
let l_205 = l_204 << u32(16);
let l_206 = l_198 & u32(65535);
let l_207 = l_205 | l_206;
let l_208 = l_207 / u32(8000);
let l_209 = l_208 * u32(8000);
let l_210 = l_207 - l_209;
l_mut_196 = l_210;
let l_211 = l_202 << u32(16);
let l_212 = l_211 | l_208;
a_63[u32(1)] = l_212;
let l_213 = a_64[u32(1)];
let l_214 = l_mut_197 << u32(16);
let l_215 = l_213 >> u32(16);
let l_216 = l_214 | l_215;
let l_217 = l_216 / u32(8000);
let l_218 = l_217 * u32(8000);
let l_219 = l_216 - l_218;
let l_220 = l_219 << u32(16);
let l_221 = l_213 & u32(65535);
let l_222 = l_220 | l_221;
let l_223 = l_222 / u32(8000);
let l_224 = l_223 * u32(8000);
let l_225 = l_222 - l_224;
l_mut_197 = l_225;
let l_226 = l_217 << u32(16);
let l_227 = l_226 | l_223;
a_64[u32(1)] = l_227;
let l_228 = a_63[u32(0)];
let l_229 = l_mut_196 << u32(16);
let l_230 = l_228 >> u32(16);
let l_231 = l_229 | l_230;
let l_232 = l_231 / u32(8000);
let l_233 = l_232 * u32(8000);
let l_234 = l_231 - l_233;
let l_235 = l_234 << u32(16);
let l_236 = l_228 & u32(65535);
let l_237 = l_235 | l_236;
let l_238 = l_237 / u32(8000);
let l_239 = l_238 * u32(8000);
let l_240 = l_237 - l_239;
l_mut_196 = l_240;
let l_241 = l_232 << u32(16);
let l_242 = l_241 | l_238;
a_63[u32(0)] = l_242;
let l_243 = a_64[u32(0)];
let l_244 = l_mut_197 << u32(16);
let l_245 = l_243 >> u32(16);
let l_246 = l_244 | l_245;
let l_247 = l_246 / u32(8000);
let l_248 = l_247 * u32(8000);
let l_249 = l_246 - l_248;
let l_250 = l_249 << u32(16);
let l_251 = l_243 & u32(65535);
let l_252 = l_250 | l_251;
let l_253 = l_252 / u32(8000);
let l_254 = l_253 * u32(8000);
let l_255 = l_252 - l_254;
l_mut_197 = l_255;
let l_256 = l_247 << u32(16);
let l_257 = l_256 | l_253;
a_64[u32(0)] = l_257;
let l_258 = l_mut_196 % u32(20);
l_mut_196 = l_mut_196 / u32(20);
let l_259 = l_mut_197 % u32(20);
l_mut_197 = l_mut_197 / u32(20);
let l_260 = u32(0) >= l_mut_177;
if l_260 {
let l_261 = l_258 == l_259;
if l_261 {
let l_262 = u64(l_258);
let l_263 = u64(1) << u32(bitcast<u64>(l_262));
let l_264 = l_mut_66 & l_263;
let l_265 = l_264 != u64(0);
if l_265 {
l_mut_152 = u32(1);
}
l_mut_66 = l_mut_66 | l_263;
} else {
l_mut_66 = u64(0);
l_mut_152 = u32(0);
l_mut_194 = l_258;
l_mut_195 = l_259;
}
}
let l_266 = l_mut_196 % u32(20);
l_mut_196 = l_mut_196 / u32(20);
let l_267 = l_mut_197 % u32(20);
l_mut_197 = l_mut_197 / u32(20);
let l_268 = u32(1) >= l_mut_177;
if l_268 {
let l_269 = l_266 == l_267;
if l_269 {
let l_270 = u64(l_266);
let l_271 = u64(1) << u32(bitcast<u64>(l_270));
let l_272 = l_mut_66 & l_271;
let l_273 = l_272 != u64(0);
if l_273 {
l_mut_152 = u32(1);
}
l_mut_66 = l_mut_66 | l_271;
} else {
l_mut_66 = u64(0);
l_mut_152 = u32(0);
l_mut_194 = l_266;
l_mut_195 = l_267;
}
}
let l_274 = l_mut_196 % u32(20);
l_mut_196 = l_mut_196 / u32(20);
let l_275 = l_mut_197 % u32(20);
l_mut_197 = l_mut_197 / u32(20);
let l_276 = u32(2) >= l_mut_177;
if l_276 {
let l_277 = l_274 == l_275;
if l_277 {
let l_278 = u64(l_274);
let l_279 = u64(1) << u32(bitcast<u64>(l_278));
let l_280 = l_mut_66 & l_279;
let l_281 = l_280 != u64(0);
if l_281 {
l_mut_152 = u32(1);
}
l_mut_66 = l_mut_66 | l_279;
} else {
l_mut_66 = u64(0);
l_mut_152 = u32(0);
l_mut_194 = l_274;
l_mut_195 = l_275;
}
}
l_mut_197 = u32(0);
l_mut_196 = u32(0);
let l_282 = a_63[u32(1)];
let l_283 = l_mut_197 << u32(16);
let l_284 = l_282 >> u32(16);
let l_285 = l_283 | l_284;
let l_286 = l_285 / u32(8000);
let l_287 = l_286 * u32(8000);
let l_288 = l_285 - l_287;
let l_289 = l_288 << u32(16);
let l_290 = l_282 & u32(65535);
let l_291 = l_289 | l_290;
let l_292 = l_291 / u32(8000);
let l_293 = l_292 * u32(8000);
let l_294 = l_291 - l_293;
l_mut_197 = l_294;
let l_295 = l_286 << u32(16);
let l_296 = l_295 | l_292;
a_63[u32(1)] = l_296;
let l_297 = a_64[u32(1)];
let l_298 = l_mut_196 << u32(16);
let l_299 = l_297 >> u32(16);
let l_300 = l_298 | l_299;
let l_301 = l_300 / u32(8000);
let l_302 = l_301 * u32(8000);
let l_303 = l_300 - l_302;
let l_304 = l_303 << u32(16);
let l_305 = l_297 & u32(65535);
let l_306 = l_304 | l_305;
let l_307 = l_306 / u32(8000);
let l_308 = l_307 * u32(8000);
let l_309 = l_306 - l_308;
l_mut_196 = l_309;
let l_310 = l_301 << u32(16);
let l_311 = l_310 | l_307;
a_64[u32(1)] = l_311;
let l_312 = a_63[u32(0)];
let l_313 = l_mut_197 << u32(16);
let l_314 = l_312 >> u32(16);
let l_315 = l_313 | l_314;
let l_316 = l_315 / u32(8000);
let l_317 = l_316 * u32(8000);
let l_318 = l_315 - l_317;
let l_319 = l_318 << u32(16);
let l_320 = l_312 & u32(65535);
let l_321 = l_319 | l_320;
let l_322 = l_321 / u32(8000);
let l_323 = l_322 * u32(8000);
let l_324 = l_321 - l_323;
l_mut_197 = l_324;
let l_325 = l_316 << u32(16);
let l_326 = l_325 | l_322;
a_63[u32(0)] = l_326;
let l_327 = a_64[u32(0)];
let l_328 = l_mut_196 << u32(16);
let l_329 = l_327 >> u32(16);
let l_330 = l_328 | l_329;
let l_331 = l_330 / u32(8000);
let l_332 = l_331 * u32(8000);
let l_333 = l_330 - l_332;
let l_334 = l_333 << u32(16);
let l_335 = l_327 & u32(65535);
let l_336 = l_334 | l_335;
let l_337 = l_336 / u32(8000);
let l_338 = l_337 * u32(8000);
let l_339 = l_336 - l_338;
l_mut_196 = l_339;
let l_340 = l_331 << u32(16);
let l_341 = l_340 | l_337;
a_64[u32(0)] = l_341;
let l_342 = l_mut_197 % u32(20);
l_mut_197 = l_mut_197 / u32(20);
let l_343 = l_mut_196 % u32(20);
l_mut_196 = l_mut_196 / u32(20);
let l_344 = u32(3) >= l_mut_177;
if l_344 {
let l_345 = l_342 == l_343;
if l_345 {
let l_346 = u64(l_342);
let l_347 = u64(1) << u32(bitcast<u64>(l_346));
let l_348 = l_mut_66 & l_347;
let l_349 = l_348 != u64(0);
if l_349 {
l_mut_152 = u32(1);
}
l_mut_66 = l_mut_66 | l_347;
} else {
l_mut_66 = u64(0);
l_mut_152 = u32(0);
l_mut_194 = l_342;
l_mut_195 = l_343;
}
}
let l_350 = l_mut_197 % u32(20);
l_mut_197 = l_mut_197 / u32(20);
let l_351 = l_mut_196 % u32(20);
l_mut_196 = l_mut_196 / u32(20);
let l_352 = u32(4) >= l_mut_177;
if l_352 {
let l_353 = l_350 == l_351;
if l_353 {
let l_354 = u64(l_350);
let l_355 = u64(1) << u32(bitcast<u64>(l_354));
let l_356 = l_mut_66 & l_355;
let l_357 = l_356 != u64(0);
if l_357 {
l_mut_152 = u32(1);
}
l_mut_66 = l_mut_66 | l_355;
} else {
l_mut_66 = u64(0);
l_mut_152 = u32(0);
l_mut_194 = l_350;
l_mut_195 = l_351;
}
}
let l_358 = l_mut_197 % u32(20);
l_mut_197 = l_mut_197 / u32(20);
let l_359 = l_mut_196 % u32(20);
l_mut_196 = l_mut_196 / u32(20);
let l_360 = u32(5) >= l_mut_177;
if l_360 {
let l_361 = l_358 == l_359;
if l_361 {
let l_362 = u64(l_358);
let l_363 = u64(1) << u32(bitcast<u64>(l_362));
let l_364 = l_mut_66 & l_363;
let l_365 = l_364 != u64(0);
if l_365 {
l_mut_152 = u32(1);
}
l_mut_66 = l_mut_66 | l_363;
} else {
l_mut_66 = u64(0);
l_mut_152 = u32(0);
l_mut_194 = l_358;
l_mut_195 = l_359;
}
}
l_mut_197 = u32(0);
l_mut_196 = u32(0);
let l_366 = a_63[u32(1)];
let l_367 = l_mut_197 << u32(16);
let l_368 = l_366 >> u32(16);
let l_369 = l_367 | l_368;
let l_370 = l_369 / u32(8000);
let l_371 = l_370 * u32(8000);
let l_372 = l_369 - l_371;
let l_373 = l_372 << u32(16);
let l_374 = l_366 & u32(65535);
let l_375 = l_373 | l_374;
let l_376 = l_375 / u32(8000);
let l_377 = l_376 * u32(8000);
let l_378 = l_375 - l_377;
l_mut_197 = l_378;
let l_379 = l_370 << u32(16);
let l_380 = l_379 | l_376;
a_63[u32(1)] = l_380;
let l_381 = a_64[u32(1)];
let l_382 = l_mut_196 << u32(16);
let l_383 = l_381 >> u32(16);
let l_384 = l_382 | l_383;
let l_385 = l_384 / u32(8000);
let l_386 = l_385 * u32(8000);
let l_387 = l_384 - l_386;
let l_388 = l_387 << u32(16);
let l_389 = l_381 & u32(65535);
let l_390 = l_388 | l_389;
let l_391 = l_390 / u32(8000);
let l_392 = l_391 * u32(8000);
let l_393 = l_390 - l_392;
l_mut_196 = l_393;
let l_394 = l_385 << u32(16);
let l_395 = l_394 | l_391;
a_64[u32(1)] = l_395;
let l_396 = a_63[u32(0)];
let l_397 = l_mut_197 << u32(16);
let l_398 = l_396 >> u32(16);
let l_399 = l_397 | l_398;
let l_400 = l_399 / u32(8000);
let l_401 = l_400 * u32(8000);
let l_402 = l_399 - l_401;
let l_403 = l_402 << u32(16);
let l_404 = l_396 & u32(65535);
let l_405 = l_403 | l_404;
let l_406 = l_405 / u32(8000);
let l_407 = l_406 * u32(8000);
let l_408 = l_405 - l_407;
l_mut_197 = l_408;
let l_409 = l_400 << u32(16);
let l_410 = l_409 | l_406;
a_63[u32(0)] = l_410;
let l_411 = a_64[u32(0)];
let l_412 = l_mut_196 << u32(16);
let l_413 = l_411 >> u32(16);
let l_414 = l_412 | l_413;
let l_415 = l_414 / u32(8000);
let l_416 = l_415 * u32(8000);
let l_417 = l_414 - l_416;
let l_418 = l_417 << u32(16);
let l_419 = l_411 & u32(65535);
let l_420 = l_418 | l_419;
let l_421 = l_420 / u32(8000);
let l_422 = l_421 * u32(8000);
let l_423 = l_420 - l_422;
l_mut_196 = l_423;
let l_424 = l_415 << u32(16);
let l_425 = l_424 | l_421;
a_64[u32(0)] = l_425;
let l_426 = l_mut_197 % u32(20);
l_mut_197 = l_mut_197 / u32(20);
let l_427 = l_mut_196 % u32(20);
l_mut_196 = l_mut_196 / u32(20);
let l_428 = u32(6) >= l_mut_177;
if l_428 {
let l_429 = l_426 == l_427;
if l_429 {
let l_430 = u64(l_426);
let l_431 = u64(1) << u32(bitcast<u64>(l_430));
let l_432 = l_mut_66 & l_431;
let l_433 = l_432 != u64(0);
if l_433 {
l_mut_152 = u32(1);
}
l_mut_66 = l_mut_66 | l_431;
} else {
l_mut_66 = u64(0);
l_mut_152 = u32(0);
l_mut_194 = l_426;
l_mut_195 = l_427;
}
}
let l_434 = l_mut_197 % u32(20);
l_mut_197 = l_mut_197 / u32(20);
let l_435 = l_mut_196 % u32(20);
l_mut_196 = l_mut_196 / u32(20);
let l_436 = u32(7) >= l_mut_177;
if l_436 {
let l_437 = l_434 == l_435;
if l_437 {
let l_438 = u64(l_434);
let l_439 = u64(1) << u32(bitcast<u64>(l_438));
let l_440 = l_mut_66 & l_439;
let l_441 = l_440 != u64(0);
if l_441 {
l_mut_152 = u32(1);
}
l_mut_66 = l_mut_66 | l_439;
} else {
l_mut_66 = u64(0);
l_mut_152 = u32(0);
l_mut_194 = l_434;
l_mut_195 = l_435;
}
}
let l_442 = l_mut_197 % u32(20);
l_mut_197 = l_mut_197 / u32(20);
let l_443 = l_mut_196 % u32(20);
l_mut_196 = l_mut_196 / u32(20);
a_141[u32(0)] = l_mut_177;
a_142[u32(0)] = l_mut_152;
a_145[u32(0)] = l_mut_194;
a_145[u32(1)] = l_mut_195;
l_mut_197 = u32(0);
let l_445 = a_92[u32(0)];
let l_446 = a_91[u32(0)];
let l_447 = l_445 - l_446;
let l_448 = l_447 - l_mut_197;
l_mut_196 = u32(0);
let l_449 = l_445 < l_446;
let l_450 = l_445 == l_446;
let l_451 = l_mut_197 != u32(0);
let l_452 = l_450 && l_451;
let l_453 = l_449 || l_452;
if l_453 {
l_mut_196 = u32(1);
}
a_444[u32(0)] = l_448;
l_mut_197 = l_mut_196;
let l_454 = a_92[u32(1)];
let l_455 = a_91[u32(1)];
let l_456 = l_454 - l_455;
let l_457 = l_456 - l_mut_197;
l_mut_196 = u32(0);
let l_458 = l_454 < l_455;
let l_459 = l_454 == l_455;
let l_460 = l_mut_197 != u32(0);
let l_461 = l_459 && l_460;
let l_462 = l_458 || l_461;
if l_462 {
l_mut_196 = u32(1);
}
a_444[u32(1)] = l_457;
l_mut_197 = l_mut_196;
let l_463 = a_92[u32(2)];
let l_464 = a_91[u32(2)];
let l_465 = l_463 - l_464;
let l_466 = l_465 - l_mut_197;
l_mut_196 = u32(0);
let l_467 = l_463 < l_464;
let l_468 = l_463 == l_464;
let l_469 = l_mut_197 != u32(0);
let l_470 = l_468 && l_469;
let l_471 = l_467 || l_470;
if l_471 {
l_mut_196 = u32(1);
}
a_444[u32(2)] = l_466;
l_mut_197 = l_mut_196;
l_mut_196 = u32(0);
l_mut_195 = u32(12);
loop {
let l_472 = l_mut_196 < l_mut_195;
let l_473 = !l_472;
if l_473 {
break;
}
let l_474 = l_mut_196 + l_mut_195;
let l_475 = l_474 >> u32(1);
l_mut_173 = bool(false);
l_mut_172 = bool(true);
let l_476 = l_475 * u32(3);
let l_477 = l_476 + u32(2);
let l_478 = buffer_3_global[l_477];
l_mut_194 = u32(0);
let l_479 = a_444[u32(2)];
l_mut_194 = l_479;
if l_mut_172 {
let l_480 = l_mut_194 < l_478;
if l_480 {
l_mut_173 = bool(true);
l_mut_172 = bool(false);
} else {
let l_481 = l_mut_194 > l_478;
if l_481 {
l_mut_172 = bool(false);
}
}
}
let l_482 = l_475 * u32(3);
let l_483 = l_482 + u32(1);
let l_484 = buffer_3_global[l_483];
l_mut_194 = u32(0);
let l_485 = a_444[u32(1)];
l_mut_194 = l_485;
if l_mut_172 {
let l_486 = l_mut_194 < l_484;
if l_486 {
l_mut_173 = bool(true);
l_mut_172 = bool(false);
} else {
let l_487 = l_mut_194 > l_484;
if l_487 {
l_mut_172 = bool(false);
}
}
}
let l_488 = l_475 * u32(3);
let l_489 = l_488 + u32(0);
let l_490 = buffer_3_global[l_489];
l_mut_194 = u32(0);
let l_491 = a_444[u32(0)];
l_mut_194 = l_491;
if l_mut_172 {
let l_492 = l_mut_194 < l_490;
if l_492 {
l_mut_173 = bool(true);
l_mut_172 = bool(false);
} else {
let l_493 = l_mut_194 > l_490;
if l_493 {
l_mut_172 = bool(false);
}
}
}
if l_mut_173 {
l_mut_195 = l_475;
} else {
let l_494 = l_475 + u32(1);
l_mut_196 = l_494;
}
}
l_mut_194 = l_mut_196;
let l_495 = l_mut_194 < u32(3);
if l_495 {
l_mut_194 = u32(3);
}
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = u32(1);
l_mut_167 = u32(0);
l_mut_152 = u32(0);
l_mut_45 = u32(0);
let l_496 = a_91[u32(2)];
let l_497 = l_mut_152 << u32(16);
let l_498 = l_496 >> u32(16);
let l_499 = l_497 | l_498;
let l_500 = l_499 / u32(8000);
let l_501 = l_500 * u32(8000);
let l_502 = l_499 - l_501;
let l_503 = l_502 << u32(16);
let l_504 = l_496 & u32(65535);
let l_505 = l_503 | l_504;
let l_506 = l_505 / u32(8000);
let l_507 = l_506 * u32(8000);
let l_508 = l_505 - l_507;
l_mut_152 = l_508;
let l_509 = l_500 << u32(16);
let l_510 = l_509 | l_506;
a_91[u32(2)] = l_510;
let l_511 = a_92[u32(2)];
let l_512 = l_mut_45 << u32(16);
let l_513 = l_511 >> u32(16);
let l_514 = l_512 | l_513;
let l_515 = l_514 / u32(8000);
let l_516 = l_515 * u32(8000);
let l_517 = l_514 - l_516;
let l_518 = l_517 << u32(16);
let l_519 = l_511 & u32(65535);
let l_520 = l_518 | l_519;
let l_521 = l_520 / u32(8000);
let l_522 = l_521 * u32(8000);
let l_523 = l_520 - l_522;
l_mut_45 = l_523;
let l_524 = l_515 << u32(16);
let l_525 = l_524 | l_521;
a_92[u32(2)] = l_525;
let l_526 = a_91[u32(1)];
let l_527 = l_mut_152 << u32(16);
let l_528 = l_526 >> u32(16);
let l_529 = l_527 | l_528;
let l_530 = l_529 / u32(8000);
let l_531 = l_530 * u32(8000);
let l_532 = l_529 - l_531;
let l_533 = l_532 << u32(16);
let l_534 = l_526 & u32(65535);
let l_535 = l_533 | l_534;
let l_536 = l_535 / u32(8000);
let l_537 = l_536 * u32(8000);
let l_538 = l_535 - l_537;
l_mut_152 = l_538;
let l_539 = l_530 << u32(16);
let l_540 = l_539 | l_536;
a_91[u32(1)] = l_540;
let l_541 = a_92[u32(1)];
let l_542 = l_mut_45 << u32(16);
let l_543 = l_541 >> u32(16);
let l_544 = l_542 | l_543;
let l_545 = l_544 / u32(8000);
let l_546 = l_545 * u32(8000);
let l_547 = l_544 - l_546;
let l_548 = l_547 << u32(16);
let l_549 = l_541 & u32(65535);
let l_550 = l_548 | l_549;
let l_551 = l_550 / u32(8000);
let l_552 = l_551 * u32(8000);
let l_553 = l_550 - l_552;
l_mut_45 = l_553;
let l_554 = l_545 << u32(16);
let l_555 = l_554 | l_551;
a_92[u32(1)] = l_555;
let l_556 = a_91[u32(0)];
let l_557 = l_mut_152 << u32(16);
let l_558 = l_556 >> u32(16);
let l_559 = l_557 | l_558;
let l_560 = l_559 / u32(8000);
let l_561 = l_560 * u32(8000);
let l_562 = l_559 - l_561;
let l_563 = l_562 << u32(16);
let l_564 = l_556 & u32(65535);
let l_565 = l_563 | l_564;
let l_566 = l_565 / u32(8000);
let l_567 = l_566 * u32(8000);
let l_568 = l_565 - l_567;
l_mut_152 = l_568;
let l_569 = l_560 << u32(16);
let l_570 = l_569 | l_566;
a_91[u32(0)] = l_570;
let l_571 = a_92[u32(0)];
let l_572 = l_mut_45 << u32(16);
let l_573 = l_571 >> u32(16);
let l_574 = l_572 | l_573;
let l_575 = l_574 / u32(8000);
let l_576 = l_575 * u32(8000);
let l_577 = l_574 - l_576;
let l_578 = l_577 << u32(16);
let l_579 = l_571 & u32(65535);
let l_580 = l_578 | l_579;
let l_581 = l_580 / u32(8000);
let l_582 = l_581 * u32(8000);
let l_583 = l_580 - l_582;
l_mut_45 = l_583;
let l_584 = l_575 << u32(16);
let l_585 = l_584 | l_581;
a_92[u32(0)] = l_585;
let l_586 = l_mut_152 % u32(20);
l_mut_152 = l_mut_152 / u32(20);
let l_587 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_588 = u32(0) >= l_mut_194;
if l_588 {
let l_589 = l_586 == l_587;
if l_589 {
let l_590 = u64(l_586);
let l_591 = u64(1) << u32(bitcast<u64>(l_590));
let l_592 = l_mut_65 & l_591;
let l_593 = l_592 != u64(0);
if l_593 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_591;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_586;
l_mut_167 = l_587;
}
}
let l_594 = l_mut_152 % u32(20);
l_mut_152 = l_mut_152 / u32(20);
let l_595 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_596 = u32(1) >= l_mut_194;
if l_596 {
let l_597 = l_594 == l_595;
if l_597 {
let l_598 = u64(l_594);
let l_599 = u64(1) << u32(bitcast<u64>(l_598));
let l_600 = l_mut_65 & l_599;
let l_601 = l_600 != u64(0);
if l_601 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_599;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_594;
l_mut_167 = l_595;
}
}
let l_602 = l_mut_152 % u32(20);
l_mut_152 = l_mut_152 / u32(20);
let l_603 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_604 = u32(2) >= l_mut_194;
if l_604 {
let l_605 = l_602 == l_603;
if l_605 {
let l_606 = u64(l_602);
let l_607 = u64(1) << u32(bitcast<u64>(l_606));
let l_608 = l_mut_65 & l_607;
let l_609 = l_608 != u64(0);
if l_609 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_607;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_602;
l_mut_167 = l_603;
}
}
l_mut_152 = u32(0);
l_mut_45 = u32(0);
let l_610 = a_91[u32(2)];
let l_611 = l_mut_152 << u32(16);
let l_612 = l_610 >> u32(16);
let l_613 = l_611 | l_612;
let l_614 = l_613 / u32(8000);
let l_615 = l_614 * u32(8000);
let l_616 = l_613 - l_615;
let l_617 = l_616 << u32(16);
let l_618 = l_610 & u32(65535);
let l_619 = l_617 | l_618;
let l_620 = l_619 / u32(8000);
let l_621 = l_620 * u32(8000);
let l_622 = l_619 - l_621;
l_mut_152 = l_622;
let l_623 = l_614 << u32(16);
let l_624 = l_623 | l_620;
a_91[u32(2)] = l_624;
let l_625 = a_92[u32(2)];
let l_626 = l_mut_45 << u32(16);
let l_627 = l_625 >> u32(16);
let l_628 = l_626 | l_627;
let l_629 = l_628 / u32(8000);
let l_630 = l_629 * u32(8000);
let l_631 = l_628 - l_630;
let l_632 = l_631 << u32(16);
let l_633 = l_625 & u32(65535);
let l_634 = l_632 | l_633;
let l_635 = l_634 / u32(8000);
let l_636 = l_635 * u32(8000);
let l_637 = l_634 - l_636;
l_mut_45 = l_637;
let l_638 = l_629 << u32(16);
let l_639 = l_638 | l_635;
a_92[u32(2)] = l_639;
let l_640 = a_91[u32(1)];
let l_641 = l_mut_152 << u32(16);
let l_642 = l_640 >> u32(16);
let l_643 = l_641 | l_642;
let l_644 = l_643 / u32(8000);
let l_645 = l_644 * u32(8000);
let l_646 = l_643 - l_645;
let l_647 = l_646 << u32(16);
let l_648 = l_640 & u32(65535);
let l_649 = l_647 | l_648;
let l_650 = l_649 / u32(8000);
let l_651 = l_650 * u32(8000);
let l_652 = l_649 - l_651;
l_mut_152 = l_652;
let l_653 = l_644 << u32(16);
let l_654 = l_653 | l_650;
a_91[u32(1)] = l_654;
let l_655 = a_92[u32(1)];
let l_656 = l_mut_45 << u32(16);
let l_657 = l_655 >> u32(16);
let l_658 = l_656 | l_657;
let l_659 = l_658 / u32(8000);
let l_660 = l_659 * u32(8000);
let l_661 = l_658 - l_660;
let l_662 = l_661 << u32(16);
let l_663 = l_655 & u32(65535);
let l_664 = l_662 | l_663;
let l_665 = l_664 / u32(8000);
let l_666 = l_665 * u32(8000);
let l_667 = l_664 - l_666;
l_mut_45 = l_667;
let l_668 = l_659 << u32(16);
let l_669 = l_668 | l_665;
a_92[u32(1)] = l_669;
let l_670 = a_91[u32(0)];
let l_671 = l_mut_152 << u32(16);
let l_672 = l_670 >> u32(16);
let l_673 = l_671 | l_672;
let l_674 = l_673 / u32(8000);
let l_675 = l_674 * u32(8000);
let l_676 = l_673 - l_675;
let l_677 = l_676 << u32(16);
let l_678 = l_670 & u32(65535);
let l_679 = l_677 | l_678;
let l_680 = l_679 / u32(8000);
let l_681 = l_680 * u32(8000);
let l_682 = l_679 - l_681;
l_mut_152 = l_682;
let l_683 = l_674 << u32(16);
let l_684 = l_683 | l_680;
a_91[u32(0)] = l_684;
let l_685 = a_92[u32(0)];
let l_686 = l_mut_45 << u32(16);
let l_687 = l_685 >> u32(16);
let l_688 = l_686 | l_687;
let l_689 = l_688 / u32(8000);
let l_690 = l_689 * u32(8000);
let l_691 = l_688 - l_690;
let l_692 = l_691 << u32(16);
let l_693 = l_685 & u32(65535);
let l_694 = l_692 | l_693;
let l_695 = l_694 / u32(8000);
let l_696 = l_695 * u32(8000);
let l_697 = l_694 - l_696;
l_mut_45 = l_697;
let l_698 = l_689 << u32(16);
let l_699 = l_698 | l_695;
a_92[u32(0)] = l_699;
let l_700 = l_mut_152 % u32(20);
l_mut_152 = l_mut_152 / u32(20);
let l_701 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_702 = u32(3) >= l_mut_194;
if l_702 {
let l_703 = l_700 == l_701;
if l_703 {
let l_704 = u64(l_700);
let l_705 = u64(1) << u32(bitcast<u64>(l_704));
let l_706 = l_mut_65 & l_705;
let l_707 = l_706 != u64(0);
if l_707 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_705;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_700;
l_mut_167 = l_701;
}
}
let l_708 = l_mut_152 % u32(20);
l_mut_152 = l_mut_152 / u32(20);
let l_709 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_710 = u32(4) >= l_mut_194;
if l_710 {
let l_711 = l_708 == l_709;
if l_711 {
let l_712 = u64(l_708);
let l_713 = u64(1) << u32(bitcast<u64>(l_712));
let l_714 = l_mut_65 & l_713;
let l_715 = l_714 != u64(0);
if l_715 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_713;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_708;
l_mut_167 = l_709;
}
}
let l_716 = l_mut_152 % u32(20);
l_mut_152 = l_mut_152 / u32(20);
let l_717 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_718 = u32(5) >= l_mut_194;
if l_718 {
let l_719 = l_716 == l_717;
if l_719 {
let l_720 = u64(l_716);
let l_721 = u64(1) << u32(bitcast<u64>(l_720));
let l_722 = l_mut_65 & l_721;
let l_723 = l_722 != u64(0);
if l_723 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_721;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_716;
l_mut_167 = l_717;
}
}
l_mut_152 = u32(0);
l_mut_45 = u32(0);
let l_724 = a_91[u32(2)];
let l_725 = l_mut_152 << u32(16);
let l_726 = l_724 >> u32(16);
let l_727 = l_725 | l_726;
let l_728 = l_727 / u32(8000);
let l_729 = l_728 * u32(8000);
let l_730 = l_727 - l_729;
let l_731 = l_730 << u32(16);
let l_732 = l_724 & u32(65535);
let l_733 = l_731 | l_732;
let l_734 = l_733 / u32(8000);
let l_735 = l_734 * u32(8000);
let l_736 = l_733 - l_735;
l_mut_152 = l_736;
let l_737 = l_728 << u32(16);
let l_738 = l_737 | l_734;
a_91[u32(2)] = l_738;
let l_739 = a_92[u32(2)];
let l_740 = l_mut_45 << u32(16);
let l_741 = l_739 >> u32(16);
let l_742 = l_740 | l_741;
let l_743 = l_742 / u32(8000);
let l_744 = l_743 * u32(8000);
let l_745 = l_742 - l_744;
let l_746 = l_745 << u32(16);
let l_747 = l_739 & u32(65535);
let l_748 = l_746 | l_747;
let l_749 = l_748 / u32(8000);
let l_750 = l_749 * u32(8000);
let l_751 = l_748 - l_750;
l_mut_45 = l_751;
let l_752 = l_743 << u32(16);
let l_753 = l_752 | l_749;
a_92[u32(2)] = l_753;
let l_754 = a_91[u32(1)];
let l_755 = l_mut_152 << u32(16);
let l_756 = l_754 >> u32(16);
let l_757 = l_755 | l_756;
let l_758 = l_757 / u32(8000);
let l_759 = l_758 * u32(8000);
let l_760 = l_757 - l_759;
let l_761 = l_760 << u32(16);
let l_762 = l_754 & u32(65535);
let l_763 = l_761 | l_762;
let l_764 = l_763 / u32(8000);
let l_765 = l_764 * u32(8000);
let l_766 = l_763 - l_765;
l_mut_152 = l_766;
let l_767 = l_758 << u32(16);
let l_768 = l_767 | l_764;
a_91[u32(1)] = l_768;
let l_769 = a_92[u32(1)];
let l_770 = l_mut_45 << u32(16);
let l_771 = l_769 >> u32(16);
let l_772 = l_770 | l_771;
let l_773 = l_772 / u32(8000);
let l_774 = l_773 * u32(8000);
let l_775 = l_772 - l_774;
let l_776 = l_775 << u32(16);
let l_777 = l_769 & u32(65535);
let l_778 = l_776 | l_777;
let l_779 = l_778 / u32(8000);
let l_780 = l_779 * u32(8000);
let l_781 = l_778 - l_780;
l_mut_45 = l_781;
let l_782 = l_773 << u32(16);
let l_783 = l_782 | l_779;
a_92[u32(1)] = l_783;
let l_784 = a_91[u32(0)];
let l_785 = l_mut_152 << u32(16);
let l_786 = l_784 >> u32(16);
let l_787 = l_785 | l_786;
let l_788 = l_787 / u32(8000);
let l_789 = l_788 * u32(8000);
let l_790 = l_787 - l_789;
let l_791 = l_790 << u32(16);
let l_792 = l_784 & u32(65535);
let l_793 = l_791 | l_792;
let l_794 = l_793 / u32(8000);
let l_795 = l_794 * u32(8000);
let l_796 = l_793 - l_795;
l_mut_152 = l_796;
let l_797 = l_788 << u32(16);
let l_798 = l_797 | l_794;
a_91[u32(0)] = l_798;
let l_799 = a_92[u32(0)];
let l_800 = l_mut_45 << u32(16);
let l_801 = l_799 >> u32(16);
let l_802 = l_800 | l_801;
let l_803 = l_802 / u32(8000);
let l_804 = l_803 * u32(8000);
let l_805 = l_802 - l_804;
let l_806 = l_805 << u32(16);
let l_807 = l_799 & u32(65535);
let l_808 = l_806 | l_807;
let l_809 = l_808 / u32(8000);
let l_810 = l_809 * u32(8000);
let l_811 = l_808 - l_810;
l_mut_45 = l_811;
let l_812 = l_803 << u32(16);
let l_813 = l_812 | l_809;
a_92[u32(0)] = l_813;
let l_814 = l_mut_152 % u32(20);
l_mut_152 = l_mut_152 / u32(20);
let l_815 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_816 = u32(6) >= l_mut_194;
if l_816 {
let l_817 = l_814 == l_815;
if l_817 {
let l_818 = u64(l_814);
let l_819 = u64(1) << u32(bitcast<u64>(l_818));
let l_820 = l_mut_65 & l_819;
let l_821 = l_820 != u64(0);
if l_821 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_819;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_814;
l_mut_167 = l_815;
}
}
let l_822 = l_mut_152 % u32(20);
l_mut_152 = l_mut_152 / u32(20);
let l_823 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_824 = u32(7) >= l_mut_194;
if l_824 {
let l_825 = l_822 == l_823;
if l_825 {
let l_826 = u64(l_822);
let l_827 = u64(1) << u32(bitcast<u64>(l_826));
let l_828 = l_mut_65 & l_827;
let l_829 = l_828 != u64(0);
if l_829 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_827;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_822;
l_mut_167 = l_823;
}
}
let l_830 = l_mut_152 % u32(20);
l_mut_152 = l_mut_152 / u32(20);
let l_831 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_832 = u32(8) >= l_mut_194;
if l_832 {
let l_833 = l_830 == l_831;
if l_833 {
let l_834 = u64(l_830);
let l_835 = u64(1) << u32(bitcast<u64>(l_834));
let l_836 = l_mut_65 & l_835;
let l_837 = l_836 != u64(0);
if l_837 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_835;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_830;
l_mut_167 = l_831;
}
}
l_mut_152 = u32(0);
l_mut_45 = u32(0);
let l_838 = a_91[u32(2)];
let l_839 = l_mut_152 << u32(16);
let l_840 = l_838 >> u32(16);
let l_841 = l_839 | l_840;
let l_842 = l_841 / u32(8000);
let l_843 = l_842 * u32(8000);
let l_844 = l_841 - l_843;
let l_845 = l_844 << u32(16);
let l_846 = l_838 & u32(65535);
let l_847 = l_845 | l_846;
let l_848 = l_847 / u32(8000);
let l_849 = l_848 * u32(8000);
let l_850 = l_847 - l_849;
l_mut_152 = l_850;
let l_851 = l_842 << u32(16);
let l_852 = l_851 | l_848;
a_91[u32(2)] = l_852;
let l_853 = a_92[u32(2)];
let l_854 = l_mut_45 << u32(16);
let l_855 = l_853 >> u32(16);
let l_856 = l_854 | l_855;
let l_857 = l_856 / u32(8000);
let l_858 = l_857 * u32(8000);
let l_859 = l_856 - l_858;
let l_860 = l_859 << u32(16);
let l_861 = l_853 & u32(65535);
let l_862 = l_860 | l_861;
let l_863 = l_862 / u32(8000);
let l_864 = l_863 * u32(8000);
let l_865 = l_862 - l_864;
l_mut_45 = l_865;
let l_866 = l_857 << u32(16);
let l_867 = l_866 | l_863;
a_92[u32(2)] = l_867;
let l_868 = a_91[u32(1)];
let l_869 = l_mut_152 << u32(16);
let l_870 = l_868 >> u32(16);
let l_871 = l_869 | l_870;
let l_872 = l_871 / u32(8000);
let l_873 = l_872 * u32(8000);
let l_874 = l_871 - l_873;
let l_875 = l_874 << u32(16);
let l_876 = l_868 & u32(65535);
let l_877 = l_875 | l_876;
let l_878 = l_877 / u32(8000);
let l_879 = l_878 * u32(8000);
let l_880 = l_877 - l_879;
l_mut_152 = l_880;
let l_881 = l_872 << u32(16);
let l_882 = l_881 | l_878;
a_91[u32(1)] = l_882;
let l_883 = a_92[u32(1)];
let l_884 = l_mut_45 << u32(16);
let l_885 = l_883 >> u32(16);
let l_886 = l_884 | l_885;
let l_887 = l_886 / u32(8000);
let l_888 = l_887 * u32(8000);
let l_889 = l_886 - l_888;
let l_890 = l_889 << u32(16);
let l_891 = l_883 & u32(65535);
let l_892 = l_890 | l_891;
let l_893 = l_892 / u32(8000);
let l_894 = l_893 * u32(8000);
let l_895 = l_892 - l_894;
l_mut_45 = l_895;
let l_896 = l_887 << u32(16);
let l_897 = l_896 | l_893;
a_92[u32(1)] = l_897;
let l_898 = a_91[u32(0)];
let l_899 = l_mut_152 << u32(16);
let l_900 = l_898 >> u32(16);
let l_901 = l_899 | l_900;
let l_902 = l_901 / u32(8000);
let l_903 = l_902 * u32(8000);
let l_904 = l_901 - l_903;
let l_905 = l_904 << u32(16);
let l_906 = l_898 & u32(65535);
let l_907 = l_905 | l_906;
let l_908 = l_907 / u32(8000);
let l_909 = l_908 * u32(8000);
let l_910 = l_907 - l_909;
l_mut_152 = l_910;
let l_911 = l_902 << u32(16);
let l_912 = l_911 | l_908;
a_91[u32(0)] = l_912;
let l_913 = a_92[u32(0)];
let l_914 = l_mut_45 << u32(16);
let l_915 = l_913 >> u32(16);
let l_916 = l_914 | l_915;
let l_917 = l_916 / u32(8000);
let l_918 = l_917 * u32(8000);
let l_919 = l_916 - l_918;
let l_920 = l_919 << u32(16);
let l_921 = l_913 & u32(65535);
let l_922 = l_920 | l_921;
let l_923 = l_922 / u32(8000);
let l_924 = l_923 * u32(8000);
let l_925 = l_922 - l_924;
l_mut_45 = l_925;
let l_926 = l_917 << u32(16);
let l_927 = l_926 | l_923;
a_92[u32(0)] = l_927;
let l_928 = l_mut_152 % u32(20);
l_mut_152 = l_mut_152 / u32(20);
let l_929 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_930 = u32(9) >= l_mut_194;
if l_930 {
let l_931 = l_928 == l_929;
if l_931 {
let l_932 = u64(l_928);
let l_933 = u64(1) << u32(bitcast<u64>(l_932));
let l_934 = l_mut_65 & l_933;
let l_935 = l_934 != u64(0);
if l_935 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_933;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_928;
l_mut_167 = l_929;
}
}
let l_936 = l_mut_152 % u32(20);
l_mut_152 = l_mut_152 / u32(20);
let l_937 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_938 = u32(10) >= l_mut_194;
if l_938 {
let l_939 = l_936 == l_937;
if l_939 {
let l_940 = u64(l_936);
let l_941 = u64(1) << u32(bitcast<u64>(l_940));
let l_942 = l_mut_65 & l_941;
let l_943 = l_942 != u64(0);
if l_943 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_941;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_936;
l_mut_167 = l_937;
}
}
let l_944 = l_mut_152 % u32(20);
l_mut_152 = l_mut_152 / u32(20);
let l_945 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_946 = u32(11) >= l_mut_194;
if l_946 {
let l_947 = l_944 == l_945;
if l_947 {
let l_948 = u64(l_944);
let l_949 = u64(1) << u32(bitcast<u64>(l_948));
let l_950 = l_mut_65 & l_949;
let l_951 = l_950 != u64(0);
if l_951 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_949;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_944;
l_mut_167 = l_945;
}
}
a_143[u32(0)] = l_mut_194;
a_144[u32(0)] = l_mut_196;
a_146[u32(0)] = l_mut_177;
a_146[u32(1)] = l_mut_167;
let l_952 = l_mut_66 | l_mut_65;
l_mut_953 = l_952;
let l_954 = a_142[u32(0)];
let l_955 = l_954 == u32(0);
let l_956 = a_144[u32(0)];
let l_957 = l_956 == u32(0);
let l_958 = l_955 && l_957;
let l_959 = l_mut_66 & l_mut_65;
let l_960 = l_959 == u64(0);
let l_961 = l_958 && l_960;
l_mut_173 = l_961;
let l_962 = a_145[u32(0)];
let l_963 = a_145[u32(1)];
l_mut_66 = u64(0);
let l_964 = l_963 >= l_962;
if l_964 {
let l_965 = l_963 - l_962;
let l_966 = l_965 + u32(1);
let l_967 = l_966 >= u32(64);
if l_967 {
let l_968 = u64(l_962);
let l_969 = bitcast<u64>(i64(-1)) << u32(bitcast<u64>(l_968));
l_mut_66 = l_969;
} else {
let l_970 = u64(l_966);
let l_971 = u64(1) << u32(bitcast<u64>(l_970));
let l_972 = l_971 - u64(1);
let l_973 = u64(l_962);
let l_974 = l_972 << u32(bitcast<u64>(l_973));
l_mut_66 = l_974;
}
}
let l_975 = a_146[u32(0)];
let l_976 = a_146[u32(1)];
l_mut_65 = u64(0);
let l_977 = l_976 >= l_975;
if l_977 {
let l_978 = l_976 - l_975;
let l_979 = l_978 + u32(1);
let l_980 = l_979 >= u32(64);
if l_980 {
let l_981 = u64(l_975);
let l_982 = bitcast<u64>(i64(-1)) << u32(bitcast<u64>(l_981));
l_mut_65 = l_982;
} else {
let l_983 = u64(l_979);
let l_984 = u64(1) << u32(bitcast<u64>(l_983));
let l_985 = l_984 - u64(1);
let l_986 = u64(l_975);
let l_987 = l_985 << u32(bitcast<u64>(l_986));
l_mut_65 = l_987;
}
}
l_mut_172 = bool(false);
l_mut_988 = bool(false);
let l_989 = l_mut_66 != u64(0);
let l_990 = l_mut_173 && l_989;
if l_990 {
let l_991 = ~l_mut_953;
let l_992 = l_mut_66 & l_991;
let l_993 = l_992 == u64(0);
if l_993 {
l_mut_173 = bool(false);
} else {
let l_994 = l_992 - u64(1);
let l_995 = l_992 & l_994;
let l_996 = l_995 == u64(0);
if l_996 {
l_mut_953 = l_mut_953 | l_992;
l_mut_172 = bool(true);
}
}
}
let l_997 = l_mut_65 != u64(0);
let l_998 = l_mut_173 && l_997;
if l_998 {
let l_999 = ~l_mut_953;
let l_1000 = l_mut_65 & l_999;
let l_1001 = l_1000 == u64(0);
if l_1001 {
l_mut_173 = bool(false);
} else {
let l_1002 = l_1000 - u64(1);
let l_1003 = l_1000 & l_1002;
let l_1004 = l_1003 == u64(0);
if l_1004 {
l_mut_953 = l_mut_953 | l_1000;
l_mut_988 = bool(true);
}
}
}
let l_1005 = l_mut_66 != u64(0);
let l_1006 = l_mut_173 && l_1005;
let l_1007 = !l_mut_172;
let l_1008 = l_1006 && l_1007;
let l_1009 = l_1008 && l_mut_988;
if l_1009 {
let l_1010 = ~l_mut_953;
let l_1011 = l_mut_66 & l_1010;
let l_1012 = l_1011 == u64(0);
if l_1012 {
l_mut_173 = bool(false);
} else {
let l_1013 = l_1011 - u64(1);
let l_1014 = l_1011 & l_1013;
let l_1015 = l_1014 == u64(0);
if l_1015 {
l_mut_953 = l_mut_953 | l_1011;
}
}
}
if l_mut_173 {
let l_1016 = a_141[u32(0)];
l_mut_197 = l_1016;
let l_1017 = a_143[u32(0)];
let l_1018 = l_1017 < l_mut_197;
if l_1018 {
let l_1019 = a_143[u32(0)];
l_mut_197 = l_1019;
}
let l_1020 = !l_mut_47;
let l_1021 = !l_mut_48;
let l_1022 = l_1020 && l_1021;
if l_1022 {
l_mut_197 = info.scalars_u32[5];
}
let l_1023 = &buffer_10_global[workgroup_id.y];
let l_1024 = atomicAdd(l_1023, u32(1));let l_1025 = workgroup_id.y * info.scalars_u32[0];
let l_1026 = l_1025 + l_1024;
let l_1027 = u32(2) * l_1026;
let l_1028 = u32(bitcast<u64>(l_14));
buffer_5_global[l_1027] = l_1028;
let l_1029 = u32(2) * l_1026;
let l_1030 = l_1029 + u32(1);
let l_1031 = l_14 >> u32(bitcast<u64>(u64(32)));
let l_1032 = u32(bitcast<u64>(l_1031));
buffer_5_global[l_1030] = l_1032;
let l_1033 = u32(2) * l_1026;
let l_1034 = u32(bitcast<u64>(l_mut_953));
buffer_6_global[l_1033] = l_1034;
let l_1035 = u32(2) * l_1026;
let l_1036 = l_1035 + u32(1);
let l_1037 = l_mut_953 >> u32(bitcast<u64>(u64(32)));
let l_1038 = u32(bitcast<u64>(l_1037));
buffer_6_global[l_1036] = l_1038;
let l_1039 = u32(2) * l_1026;
let l_1040 = a_39[u32(0)];
let l_1041 = l_1040 - l_38;
buffer_7_global[l_1039] = l_1041;
let l_1042 = u32(2) * l_1026;
let l_1043 = l_1042 + u32(1);
let l_1044 = a_40[u32(0)];
let l_1045 = l_1044 - l_38;
let l_1046 = l_1045 + u32(1);
buffer_7_global[l_1043] = l_1046;
let l_1047 = u32(5) * global_id.x;
let l_1048 = l_1047 + u32(4);
let l_1049 = buffer_0_global[l_1048];
let l_1050 = l_1049 * info.scalars_u32[3];
let l_1051 = l_1050 + l_10;
let l_1052 = u32(2) * l_1026;
buffer_8_global[l_1052] = l_1051;
l_mut_196 = u32(0);
let l_1053 = l_mut_197 >= u32(5);
if l_1053 {
l_mut_196 = u32(1);
}
let l_1054 = u32(2) * l_1026;
let l_1055 = l_1054 + u32(1);
buffer_8_global[l_1055] = l_mut_196;
let l_1056 = u32(5) * global_id.x;
let l_1057 = l_1056 + u32(2);
let l_1058 = buffer_0_global[l_1057];
let l_1059 = l_1058 * info.scalars_u32[4];
let l_1060 = l_1059 + l_10;
let l_1061 = l_1060 % u32(19);
l_mut_197 = u32(0);
let l_1062 = l_mut_197 << u32(8);
let l_1063 = l_1061 | l_1062;
buffer_9_global[l_1026] = l_1063;
l_mut_196 = u32(0);
loop {
let l_1064 = l_mut_196 < info.scalars_u32[1];
let l_1065 = !l_1064;
if l_1065 {
break;
}
let l_1066 = buffer_4_global[l_mut_196];
let l_1067 = l_1066 + u32(19);
let l_1068 = l_1067 - l_1061;
let l_1069 = l_1068 % u32(19);
let l_1070 = workgroup_id.y * u32(19);
let l_1071 = l_mut_197 * u32(19);
let l_1072 = l_1070 + l_1071;
let l_1073 = l_1072 + l_1069;
let l_1074 = &buffer_11_global[l_1073];
let l_1075 = atomicAdd(l_1074, u32(1));l_mut_196 = l_mut_196 + u32(1);
}
}
}
}
workgroupBarrier();
let l_1076 = local_invocation_id.x == u32(0);
if l_1076 {
let l_1077 = &buffer_12_global[u32(0)];
let l_1078 = atomicAdd(l_1077, u32(1));}
}
```
