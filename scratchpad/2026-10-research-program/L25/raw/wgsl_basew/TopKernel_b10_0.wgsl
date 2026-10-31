
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

var a_290: array<u32, 3>;

var a_143: array<u32, 1>;

var a_144: array<u32, 1>;

var a_146: array<u32, 2>;

var l_mut_42: u32;
var l_mut_45: u32;
var l_mut_152: u32;
var l_mut_167: u32;
var l_mut_177: u32;
var l_mut_194: u32;
var l_mut_195: u32;
var l_mut_196: u32;
var l_mut_197: u32;
var l_mut_47: bool;
var l_mut_48: bool;
var l_mut_49: bool;
var l_mut_50: bool;
var l_mut_172: bool;
var l_mut_173: bool;
var l_mut_610: bool;
var l_mut_65: u64;
var l_mut_66: u64;
var l_mut_575: u64;
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
l_mut_167 = u32(4);
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
let l_193 = l_mut_177 < u32(1);
if l_193 {
l_mut_177 = u32(1);
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
let l_202 = l_201 / u32(10000);
let l_203 = l_202 * u32(10000);
let l_204 = l_201 - l_203;
let l_205 = l_204 << u32(16);
let l_206 = l_198 & u32(65535);
let l_207 = l_205 | l_206;
let l_208 = l_207 / u32(10000);
let l_209 = l_208 * u32(10000);
let l_210 = l_207 - l_209;
l_mut_196 = l_210;
let l_211 = l_202 << u32(16);
let l_212 = l_211 | l_208;
a_63[u32(1)] = l_212;
let l_213 = a_64[u32(1)];
let l_214 = l_mut_197 << u32(16);
let l_215 = l_213 >> u32(16);
let l_216 = l_214 | l_215;
let l_217 = l_216 / u32(10000);
let l_218 = l_217 * u32(10000);
let l_219 = l_216 - l_218;
let l_220 = l_219 << u32(16);
let l_221 = l_213 & u32(65535);
let l_222 = l_220 | l_221;
let l_223 = l_222 / u32(10000);
let l_224 = l_223 * u32(10000);
let l_225 = l_222 - l_224;
l_mut_197 = l_225;
let l_226 = l_217 << u32(16);
let l_227 = l_226 | l_223;
a_64[u32(1)] = l_227;
let l_228 = a_63[u32(0)];
let l_229 = l_mut_196 << u32(16);
let l_230 = l_228 >> u32(16);
let l_231 = l_229 | l_230;
let l_232 = l_231 / u32(10000);
let l_233 = l_232 * u32(10000);
let l_234 = l_231 - l_233;
let l_235 = l_234 << u32(16);
let l_236 = l_228 & u32(65535);
let l_237 = l_235 | l_236;
let l_238 = l_237 / u32(10000);
let l_239 = l_238 * u32(10000);
let l_240 = l_237 - l_239;
l_mut_196 = l_240;
let l_241 = l_232 << u32(16);
let l_242 = l_241 | l_238;
a_63[u32(0)] = l_242;
let l_243 = a_64[u32(0)];
let l_244 = l_mut_197 << u32(16);
let l_245 = l_243 >> u32(16);
let l_246 = l_244 | l_245;
let l_247 = l_246 / u32(10000);
let l_248 = l_247 * u32(10000);
let l_249 = l_246 - l_248;
let l_250 = l_249 << u32(16);
let l_251 = l_243 & u32(65535);
let l_252 = l_250 | l_251;
let l_253 = l_252 / u32(10000);
let l_254 = l_253 * u32(10000);
let l_255 = l_252 - l_254;
l_mut_197 = l_255;
let l_256 = l_247 << u32(16);
let l_257 = l_256 | l_253;
a_64[u32(0)] = l_257;
let l_258 = l_mut_196 % u32(10);
l_mut_196 = l_mut_196 / u32(10);
let l_259 = l_mut_197 % u32(10);
l_mut_197 = l_mut_197 / u32(10);
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
let l_266 = l_mut_196 % u32(10);
l_mut_196 = l_mut_196 / u32(10);
let l_267 = l_mut_197 % u32(10);
l_mut_197 = l_mut_197 / u32(10);
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
let l_274 = l_mut_196 % u32(10);
l_mut_196 = l_mut_196 / u32(10);
let l_275 = l_mut_197 % u32(10);
l_mut_197 = l_mut_197 / u32(10);
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
let l_282 = l_mut_196 % u32(10);
l_mut_196 = l_mut_196 / u32(10);
let l_283 = l_mut_197 % u32(10);
l_mut_197 = l_mut_197 / u32(10);
let l_284 = u32(3) >= l_mut_177;
if l_284 {
let l_285 = l_282 == l_283;
if l_285 {
let l_286 = u64(l_282);
let l_287 = u64(1) << u32(bitcast<u64>(l_286));
let l_288 = l_mut_66 & l_287;
let l_289 = l_288 != u64(0);
if l_289 {
l_mut_152 = u32(1);
}
l_mut_66 = l_mut_66 | l_287;
} else {
l_mut_66 = u64(0);
l_mut_152 = u32(0);
l_mut_194 = l_282;
l_mut_195 = l_283;
}
}
a_141[u32(0)] = l_mut_177;
a_142[u32(0)] = l_mut_152;
a_145[u32(0)] = l_mut_194;
a_145[u32(1)] = l_mut_195;
l_mut_197 = u32(0);
let l_291 = a_92[u32(0)];
let l_292 = a_91[u32(0)];
let l_293 = l_291 - l_292;
let l_294 = l_293 - l_mut_197;
l_mut_196 = u32(0);
let l_295 = l_291 < l_292;
let l_296 = l_291 == l_292;
let l_297 = l_mut_197 != u32(0);
let l_298 = l_296 && l_297;
let l_299 = l_295 || l_298;
if l_299 {
l_mut_196 = u32(1);
}
a_290[u32(0)] = l_294;
l_mut_197 = l_mut_196;
let l_300 = a_92[u32(1)];
let l_301 = a_91[u32(1)];
let l_302 = l_300 - l_301;
let l_303 = l_302 - l_mut_197;
l_mut_196 = u32(0);
let l_304 = l_300 < l_301;
let l_305 = l_300 == l_301;
let l_306 = l_mut_197 != u32(0);
let l_307 = l_305 && l_306;
let l_308 = l_304 || l_307;
if l_308 {
l_mut_196 = u32(1);
}
a_290[u32(1)] = l_303;
l_mut_197 = l_mut_196;
let l_309 = a_92[u32(2)];
let l_310 = a_91[u32(2)];
let l_311 = l_309 - l_310;
let l_312 = l_311 - l_mut_197;
l_mut_196 = u32(0);
let l_313 = l_309 < l_310;
let l_314 = l_309 == l_310;
let l_315 = l_mut_197 != u32(0);
let l_316 = l_314 && l_315;
let l_317 = l_313 || l_316;
if l_317 {
l_mut_196 = u32(1);
}
a_290[u32(2)] = l_312;
l_mut_197 = l_mut_196;
l_mut_196 = u32(0);
l_mut_195 = u32(6);
loop {
let l_318 = l_mut_196 < l_mut_195;
let l_319 = !l_318;
if l_319 {
break;
}
let l_320 = l_mut_196 + l_mut_195;
let l_321 = l_320 >> u32(1);
l_mut_173 = bool(false);
l_mut_172 = bool(true);
let l_322 = l_321 * u32(3);
let l_323 = l_322 + u32(2);
let l_324 = buffer_3_global[l_323];
l_mut_194 = u32(0);
let l_325 = a_290[u32(2)];
l_mut_194 = l_325;
if l_mut_172 {
let l_326 = l_mut_194 < l_324;
if l_326 {
l_mut_173 = bool(true);
l_mut_172 = bool(false);
} else {
let l_327 = l_mut_194 > l_324;
if l_327 {
l_mut_172 = bool(false);
}
}
}
let l_328 = l_321 * u32(3);
let l_329 = l_328 + u32(1);
let l_330 = buffer_3_global[l_329];
l_mut_194 = u32(0);
let l_331 = a_290[u32(1)];
l_mut_194 = l_331;
if l_mut_172 {
let l_332 = l_mut_194 < l_330;
if l_332 {
l_mut_173 = bool(true);
l_mut_172 = bool(false);
} else {
let l_333 = l_mut_194 > l_330;
if l_333 {
l_mut_172 = bool(false);
}
}
}
let l_334 = l_321 * u32(3);
let l_335 = l_334 + u32(0);
let l_336 = buffer_3_global[l_335];
l_mut_194 = u32(0);
let l_337 = a_290[u32(0)];
l_mut_194 = l_337;
if l_mut_172 {
let l_338 = l_mut_194 < l_336;
if l_338 {
l_mut_173 = bool(true);
l_mut_172 = bool(false);
} else {
let l_339 = l_mut_194 > l_336;
if l_339 {
l_mut_172 = bool(false);
}
}
}
if l_mut_173 {
l_mut_195 = l_321;
} else {
let l_340 = l_321 + u32(1);
l_mut_196 = l_340;
}
}
l_mut_194 = l_mut_196;
let l_341 = l_mut_194 < u32(1);
if l_341 {
l_mut_194 = u32(1);
}
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = u32(1);
l_mut_167 = u32(0);
l_mut_152 = u32(0);
l_mut_45 = u32(0);
let l_342 = a_91[u32(2)];
let l_343 = l_mut_152 << u32(16);
let l_344 = l_342 >> u32(16);
let l_345 = l_343 | l_344;
let l_346 = l_345 / u32(10000);
let l_347 = l_346 * u32(10000);
let l_348 = l_345 - l_347;
let l_349 = l_348 << u32(16);
let l_350 = l_342 & u32(65535);
let l_351 = l_349 | l_350;
let l_352 = l_351 / u32(10000);
let l_353 = l_352 * u32(10000);
let l_354 = l_351 - l_353;
l_mut_152 = l_354;
let l_355 = l_346 << u32(16);
let l_356 = l_355 | l_352;
a_91[u32(2)] = l_356;
let l_357 = a_92[u32(2)];
let l_358 = l_mut_45 << u32(16);
let l_359 = l_357 >> u32(16);
let l_360 = l_358 | l_359;
let l_361 = l_360 / u32(10000);
let l_362 = l_361 * u32(10000);
let l_363 = l_360 - l_362;
let l_364 = l_363 << u32(16);
let l_365 = l_357 & u32(65535);
let l_366 = l_364 | l_365;
let l_367 = l_366 / u32(10000);
let l_368 = l_367 * u32(10000);
let l_369 = l_366 - l_368;
l_mut_45 = l_369;
let l_370 = l_361 << u32(16);
let l_371 = l_370 | l_367;
a_92[u32(2)] = l_371;
let l_372 = a_91[u32(1)];
let l_373 = l_mut_152 << u32(16);
let l_374 = l_372 >> u32(16);
let l_375 = l_373 | l_374;
let l_376 = l_375 / u32(10000);
let l_377 = l_376 * u32(10000);
let l_378 = l_375 - l_377;
let l_379 = l_378 << u32(16);
let l_380 = l_372 & u32(65535);
let l_381 = l_379 | l_380;
let l_382 = l_381 / u32(10000);
let l_383 = l_382 * u32(10000);
let l_384 = l_381 - l_383;
l_mut_152 = l_384;
let l_385 = l_376 << u32(16);
let l_386 = l_385 | l_382;
a_91[u32(1)] = l_386;
let l_387 = a_92[u32(1)];
let l_388 = l_mut_45 << u32(16);
let l_389 = l_387 >> u32(16);
let l_390 = l_388 | l_389;
let l_391 = l_390 / u32(10000);
let l_392 = l_391 * u32(10000);
let l_393 = l_390 - l_392;
let l_394 = l_393 << u32(16);
let l_395 = l_387 & u32(65535);
let l_396 = l_394 | l_395;
let l_397 = l_396 / u32(10000);
let l_398 = l_397 * u32(10000);
let l_399 = l_396 - l_398;
l_mut_45 = l_399;
let l_400 = l_391 << u32(16);
let l_401 = l_400 | l_397;
a_92[u32(1)] = l_401;
let l_402 = a_91[u32(0)];
let l_403 = l_mut_152 << u32(16);
let l_404 = l_402 >> u32(16);
let l_405 = l_403 | l_404;
let l_406 = l_405 / u32(10000);
let l_407 = l_406 * u32(10000);
let l_408 = l_405 - l_407;
let l_409 = l_408 << u32(16);
let l_410 = l_402 & u32(65535);
let l_411 = l_409 | l_410;
let l_412 = l_411 / u32(10000);
let l_413 = l_412 * u32(10000);
let l_414 = l_411 - l_413;
l_mut_152 = l_414;
let l_415 = l_406 << u32(16);
let l_416 = l_415 | l_412;
a_91[u32(0)] = l_416;
let l_417 = a_92[u32(0)];
let l_418 = l_mut_45 << u32(16);
let l_419 = l_417 >> u32(16);
let l_420 = l_418 | l_419;
let l_421 = l_420 / u32(10000);
let l_422 = l_421 * u32(10000);
let l_423 = l_420 - l_422;
let l_424 = l_423 << u32(16);
let l_425 = l_417 & u32(65535);
let l_426 = l_424 | l_425;
let l_427 = l_426 / u32(10000);
let l_428 = l_427 * u32(10000);
let l_429 = l_426 - l_428;
l_mut_45 = l_429;
let l_430 = l_421 << u32(16);
let l_431 = l_430 | l_427;
a_92[u32(0)] = l_431;
let l_432 = l_mut_152 % u32(10);
l_mut_152 = l_mut_152 / u32(10);
let l_433 = l_mut_45 % u32(10);
l_mut_45 = l_mut_45 / u32(10);
let l_434 = u32(0) >= l_mut_194;
if l_434 {
let l_435 = l_432 == l_433;
if l_435 {
let l_436 = u64(l_432);
let l_437 = u64(1) << u32(bitcast<u64>(l_436));
let l_438 = l_mut_65 & l_437;
let l_439 = l_438 != u64(0);
if l_439 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_437;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_432;
l_mut_167 = l_433;
}
}
let l_440 = l_mut_152 % u32(10);
l_mut_152 = l_mut_152 / u32(10);
let l_441 = l_mut_45 % u32(10);
l_mut_45 = l_mut_45 / u32(10);
let l_442 = u32(1) >= l_mut_194;
if l_442 {
let l_443 = l_440 == l_441;
if l_443 {
let l_444 = u64(l_440);
let l_445 = u64(1) << u32(bitcast<u64>(l_444));
let l_446 = l_mut_65 & l_445;
let l_447 = l_446 != u64(0);
if l_447 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_445;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_440;
l_mut_167 = l_441;
}
}
let l_448 = l_mut_152 % u32(10);
l_mut_152 = l_mut_152 / u32(10);
let l_449 = l_mut_45 % u32(10);
l_mut_45 = l_mut_45 / u32(10);
let l_450 = u32(2) >= l_mut_194;
if l_450 {
let l_451 = l_448 == l_449;
if l_451 {
let l_452 = u64(l_448);
let l_453 = u64(1) << u32(bitcast<u64>(l_452));
let l_454 = l_mut_65 & l_453;
let l_455 = l_454 != u64(0);
if l_455 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_453;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_448;
l_mut_167 = l_449;
}
}
let l_456 = l_mut_152 % u32(10);
l_mut_152 = l_mut_152 / u32(10);
let l_457 = l_mut_45 % u32(10);
l_mut_45 = l_mut_45 / u32(10);
let l_458 = u32(3) >= l_mut_194;
if l_458 {
let l_459 = l_456 == l_457;
if l_459 {
let l_460 = u64(l_456);
let l_461 = u64(1) << u32(bitcast<u64>(l_460));
let l_462 = l_mut_65 & l_461;
let l_463 = l_462 != u64(0);
if l_463 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_461;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_456;
l_mut_167 = l_457;
}
}
l_mut_152 = u32(0);
l_mut_45 = u32(0);
let l_464 = a_91[u32(2)];
let l_465 = l_mut_152 << u32(16);
let l_466 = l_464 >> u32(16);
let l_467 = l_465 | l_466;
let l_468 = l_467 / u32(10000);
let l_469 = l_468 * u32(10000);
let l_470 = l_467 - l_469;
let l_471 = l_470 << u32(16);
let l_472 = l_464 & u32(65535);
let l_473 = l_471 | l_472;
let l_474 = l_473 / u32(10000);
let l_475 = l_474 * u32(10000);
let l_476 = l_473 - l_475;
l_mut_152 = l_476;
let l_477 = l_468 << u32(16);
let l_478 = l_477 | l_474;
a_91[u32(2)] = l_478;
let l_479 = a_92[u32(2)];
let l_480 = l_mut_45 << u32(16);
let l_481 = l_479 >> u32(16);
let l_482 = l_480 | l_481;
let l_483 = l_482 / u32(10000);
let l_484 = l_483 * u32(10000);
let l_485 = l_482 - l_484;
let l_486 = l_485 << u32(16);
let l_487 = l_479 & u32(65535);
let l_488 = l_486 | l_487;
let l_489 = l_488 / u32(10000);
let l_490 = l_489 * u32(10000);
let l_491 = l_488 - l_490;
l_mut_45 = l_491;
let l_492 = l_483 << u32(16);
let l_493 = l_492 | l_489;
a_92[u32(2)] = l_493;
let l_494 = a_91[u32(1)];
let l_495 = l_mut_152 << u32(16);
let l_496 = l_494 >> u32(16);
let l_497 = l_495 | l_496;
let l_498 = l_497 / u32(10000);
let l_499 = l_498 * u32(10000);
let l_500 = l_497 - l_499;
let l_501 = l_500 << u32(16);
let l_502 = l_494 & u32(65535);
let l_503 = l_501 | l_502;
let l_504 = l_503 / u32(10000);
let l_505 = l_504 * u32(10000);
let l_506 = l_503 - l_505;
l_mut_152 = l_506;
let l_507 = l_498 << u32(16);
let l_508 = l_507 | l_504;
a_91[u32(1)] = l_508;
let l_509 = a_92[u32(1)];
let l_510 = l_mut_45 << u32(16);
let l_511 = l_509 >> u32(16);
let l_512 = l_510 | l_511;
let l_513 = l_512 / u32(10000);
let l_514 = l_513 * u32(10000);
let l_515 = l_512 - l_514;
let l_516 = l_515 << u32(16);
let l_517 = l_509 & u32(65535);
let l_518 = l_516 | l_517;
let l_519 = l_518 / u32(10000);
let l_520 = l_519 * u32(10000);
let l_521 = l_518 - l_520;
l_mut_45 = l_521;
let l_522 = l_513 << u32(16);
let l_523 = l_522 | l_519;
a_92[u32(1)] = l_523;
let l_524 = a_91[u32(0)];
let l_525 = l_mut_152 << u32(16);
let l_526 = l_524 >> u32(16);
let l_527 = l_525 | l_526;
let l_528 = l_527 / u32(10000);
let l_529 = l_528 * u32(10000);
let l_530 = l_527 - l_529;
let l_531 = l_530 << u32(16);
let l_532 = l_524 & u32(65535);
let l_533 = l_531 | l_532;
let l_534 = l_533 / u32(10000);
let l_535 = l_534 * u32(10000);
let l_536 = l_533 - l_535;
l_mut_152 = l_536;
let l_537 = l_528 << u32(16);
let l_538 = l_537 | l_534;
a_91[u32(0)] = l_538;
let l_539 = a_92[u32(0)];
let l_540 = l_mut_45 << u32(16);
let l_541 = l_539 >> u32(16);
let l_542 = l_540 | l_541;
let l_543 = l_542 / u32(10000);
let l_544 = l_543 * u32(10000);
let l_545 = l_542 - l_544;
let l_546 = l_545 << u32(16);
let l_547 = l_539 & u32(65535);
let l_548 = l_546 | l_547;
let l_549 = l_548 / u32(10000);
let l_550 = l_549 * u32(10000);
let l_551 = l_548 - l_550;
l_mut_45 = l_551;
let l_552 = l_543 << u32(16);
let l_553 = l_552 | l_549;
a_92[u32(0)] = l_553;
let l_554 = l_mut_152 % u32(10);
l_mut_152 = l_mut_152 / u32(10);
let l_555 = l_mut_45 % u32(10);
l_mut_45 = l_mut_45 / u32(10);
let l_556 = u32(4) >= l_mut_194;
if l_556 {
let l_557 = l_554 == l_555;
if l_557 {
let l_558 = u64(l_554);
let l_559 = u64(1) << u32(bitcast<u64>(l_558));
let l_560 = l_mut_65 & l_559;
let l_561 = l_560 != u64(0);
if l_561 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_559;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_554;
l_mut_167 = l_555;
}
}
let l_562 = l_mut_152 % u32(10);
l_mut_152 = l_mut_152 / u32(10);
let l_563 = l_mut_45 % u32(10);
l_mut_45 = l_mut_45 / u32(10);
let l_564 = u32(5) >= l_mut_194;
if l_564 {
let l_565 = l_562 == l_563;
if l_565 {
let l_566 = u64(l_562);
let l_567 = u64(1) << u32(bitcast<u64>(l_566));
let l_568 = l_mut_65 & l_567;
let l_569 = l_568 != u64(0);
if l_569 {
l_mut_196 = u32(1);
}
l_mut_65 = l_mut_65 | l_567;
} else {
l_mut_65 = u64(0);
l_mut_196 = u32(0);
l_mut_177 = l_562;
l_mut_167 = l_563;
}
}
let l_570 = l_mut_152 % u32(10);
l_mut_152 = l_mut_152 / u32(10);
let l_571 = l_mut_45 % u32(10);
l_mut_45 = l_mut_45 / u32(10);
let l_572 = l_mut_152 % u32(10);
l_mut_152 = l_mut_152 / u32(10);
let l_573 = l_mut_45 % u32(10);
l_mut_45 = l_mut_45 / u32(10);
a_143[u32(0)] = l_mut_194;
a_144[u32(0)] = l_mut_196;
a_146[u32(0)] = l_mut_177;
a_146[u32(1)] = l_mut_167;
let l_574 = l_mut_66 | l_mut_65;
l_mut_575 = l_574;
let l_576 = a_142[u32(0)];
let l_577 = l_576 == u32(0);
let l_578 = a_144[u32(0)];
let l_579 = l_578 == u32(0);
let l_580 = l_577 && l_579;
let l_581 = l_mut_66 & l_mut_65;
let l_582 = l_581 == u64(0);
let l_583 = l_580 && l_582;
l_mut_173 = l_583;
let l_584 = a_145[u32(0)];
let l_585 = a_145[u32(1)];
l_mut_66 = u64(0);
let l_586 = l_585 >= l_584;
if l_586 {
let l_587 = l_585 - l_584;
let l_588 = l_587 + u32(1);
let l_589 = l_588 >= u32(64);
if l_589 {
let l_590 = u64(l_584);
let l_591 = bitcast<u64>(i64(-1)) << u32(bitcast<u64>(l_590));
l_mut_66 = l_591;
} else {
let l_592 = u64(l_588);
let l_593 = u64(1) << u32(bitcast<u64>(l_592));
let l_594 = l_593 - u64(1);
let l_595 = u64(l_584);
let l_596 = l_594 << u32(bitcast<u64>(l_595));
l_mut_66 = l_596;
}
}
let l_597 = a_146[u32(0)];
let l_598 = a_146[u32(1)];
l_mut_65 = u64(0);
let l_599 = l_598 >= l_597;
if l_599 {
let l_600 = l_598 - l_597;
let l_601 = l_600 + u32(1);
let l_602 = l_601 >= u32(64);
if l_602 {
let l_603 = u64(l_597);
let l_604 = bitcast<u64>(i64(-1)) << u32(bitcast<u64>(l_603));
l_mut_65 = l_604;
} else {
let l_605 = u64(l_601);
let l_606 = u64(1) << u32(bitcast<u64>(l_605));
let l_607 = l_606 - u64(1);
let l_608 = u64(l_597);
let l_609 = l_607 << u32(bitcast<u64>(l_608));
l_mut_65 = l_609;
}
}
l_mut_172 = bool(false);
l_mut_610 = bool(false);
let l_611 = l_mut_66 != u64(0);
let l_612 = l_mut_173 && l_611;
if l_612 {
let l_613 = ~l_mut_575;
let l_614 = l_mut_66 & l_613;
let l_615 = l_614 == u64(0);
if l_615 {
l_mut_173 = bool(false);
} else {
let l_616 = l_614 - u64(1);
let l_617 = l_614 & l_616;
let l_618 = l_617 == u64(0);
if l_618 {
l_mut_575 = l_mut_575 | l_614;
l_mut_172 = bool(true);
}
}
}
let l_619 = l_mut_65 != u64(0);
let l_620 = l_mut_173 && l_619;
if l_620 {
let l_621 = ~l_mut_575;
let l_622 = l_mut_65 & l_621;
let l_623 = l_622 == u64(0);
if l_623 {
l_mut_173 = bool(false);
} else {
let l_624 = l_622 - u64(1);
let l_625 = l_622 & l_624;
let l_626 = l_625 == u64(0);
if l_626 {
l_mut_575 = l_mut_575 | l_622;
l_mut_610 = bool(true);
}
}
}
let l_627 = l_mut_66 != u64(0);
let l_628 = l_mut_173 && l_627;
let l_629 = !l_mut_172;
let l_630 = l_628 && l_629;
let l_631 = l_630 && l_mut_610;
if l_631 {
let l_632 = ~l_mut_575;
let l_633 = l_mut_66 & l_632;
let l_634 = l_633 == u64(0);
if l_634 {
l_mut_173 = bool(false);
} else {
let l_635 = l_633 - u64(1);
let l_636 = l_633 & l_635;
let l_637 = l_636 == u64(0);
if l_637 {
l_mut_575 = l_mut_575 | l_633;
}
}
}
if l_mut_173 {
let l_638 = a_141[u32(0)];
l_mut_197 = l_638;
let l_639 = a_143[u32(0)];
let l_640 = l_639 < l_mut_197;
if l_640 {
let l_641 = a_143[u32(0)];
l_mut_197 = l_641;
}
let l_642 = !l_mut_47;
let l_643 = !l_mut_48;
let l_644 = l_642 && l_643;
if l_644 {
l_mut_197 = info.scalars_u32[5];
}
let l_645 = &buffer_10_global[workgroup_id.y];
let l_646 = atomicAdd(l_645, u32(1));let l_647 = workgroup_id.y * info.scalars_u32[0];
let l_648 = l_647 + l_646;
let l_649 = u32(2) * l_648;
let l_650 = u32(bitcast<u64>(l_14));
buffer_5_global[l_649] = l_650;
let l_651 = u32(2) * l_648;
let l_652 = l_651 + u32(1);
let l_653 = l_14 >> u32(bitcast<u64>(u64(32)));
let l_654 = u32(bitcast<u64>(l_653));
buffer_5_global[l_652] = l_654;
let l_655 = u32(2) * l_648;
let l_656 = u32(bitcast<u64>(l_mut_575));
buffer_6_global[l_655] = l_656;
let l_657 = u32(2) * l_648;
let l_658 = l_657 + u32(1);
let l_659 = l_mut_575 >> u32(bitcast<u64>(u64(32)));
let l_660 = u32(bitcast<u64>(l_659));
buffer_6_global[l_658] = l_660;
let l_661 = u32(2) * l_648;
let l_662 = a_39[u32(0)];
let l_663 = l_662 - l_38;
buffer_7_global[l_661] = l_663;
let l_664 = u32(2) * l_648;
let l_665 = l_664 + u32(1);
let l_666 = a_40[u32(0)];
let l_667 = l_666 - l_38;
let l_668 = l_667 + u32(1);
buffer_7_global[l_665] = l_668;
let l_669 = u32(5) * global_id.x;
let l_670 = l_669 + u32(4);
let l_671 = buffer_0_global[l_670];
let l_672 = l_671 * info.scalars_u32[3];
let l_673 = l_672 + l_10;
let l_674 = u32(2) * l_648;
buffer_8_global[l_674] = l_673;
l_mut_196 = u32(0);
let l_675 = l_mut_197 >= u32(3);
if l_675 {
l_mut_196 = u32(1);
}
let l_676 = u32(2) * l_648;
let l_677 = l_676 + u32(1);
buffer_8_global[l_677] = l_mut_196;
let l_678 = u32(5) * global_id.x;
let l_679 = l_678 + u32(2);
let l_680 = buffer_0_global[l_679];
let l_681 = l_680 * info.scalars_u32[4];
let l_682 = l_681 + l_10;
let l_683 = l_682 % u32(9);
l_mut_197 = u32(0);
let l_684 = u32(5) * global_id.x;
let l_685 = l_684 + u32(3);
let l_686 = buffer_0_global[l_685];
l_mut_197 = l_686;
let l_687 = l_mut_197 << u32(8);
let l_688 = l_683 | l_687;
buffer_9_global[l_648] = l_688;
l_mut_196 = u32(0);
loop {
let l_689 = l_mut_196 < info.scalars_u32[1];
let l_690 = !l_689;
if l_690 {
break;
}
let l_691 = buffer_4_global[l_mut_196];
let l_692 = l_691 + u32(9);
let l_693 = l_692 - l_683;
let l_694 = l_693 % u32(9);
let l_695 = workgroup_id.y * u32(90);
let l_696 = l_mut_197 * u32(9);
let l_697 = l_695 + l_696;
let l_698 = l_697 + l_694;
let l_699 = &buffer_11_global[l_698];
let l_700 = atomicAdd(l_699, u32(1));l_mut_196 = l_mut_196 + u32(1);
}
}
}
}
workgroupBarrier();
let l_701 = local_invocation_id.x == u32(0);
if l_701 {
let l_702 = &buffer_12_global[u32(0)];
let l_703 = atomicAdd(l_702, u32(1));}
}
```
