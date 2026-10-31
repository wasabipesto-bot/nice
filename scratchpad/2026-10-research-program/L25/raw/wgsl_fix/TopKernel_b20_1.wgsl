
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

var a_73: array<u32, 4>;

var a_74: array<u32, 4>;

var a_140: array<u32, 6>;

var a_141: array<u32, 6>;

var a_276: array<u32, 2>;

var a_270: array<u32, 1>;

var a_271: array<u32, 1>;

var a_274: array<u32, 2>;

var a_531: array<u32, 3>;

var a_272: array<u32, 1>;

var a_273: array<u32, 1>;

var a_275: array<u32, 2>;

var l_mut_47: bool;
var l_mut_48: bool;
var l_mut_49: bool;
var l_mut_50: bool;
var l_mut_312: bool;
var l_mut_313: bool;
var l_mut_998: bool;
var l_mut_42: u32;
var l_mut_45: u32;
var l_mut_75: u32;
var l_mut_307: u32;
var l_mut_317: u32;
var l_mut_335: u32;
var l_mut_336: u32;
var l_mut_344: u32;
var l_mut_354: u32;
var l_mut_334: u64;
var l_mut_601: u64;
var l_mut_963: u64;
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
let l_65 = a_39[u32(0)];
let l_66 = l_65 & u32(65535);
a_63[u32(0)] = l_66;
let l_67 = a_39[u32(0)];
let l_68 = l_67 >> u32(16);
a_63[u32(1)] = l_68;
let l_69 = a_40[u32(0)];
let l_70 = l_69 & u32(65535);
a_64[u32(0)] = l_70;
let l_71 = a_40[u32(0)];
let l_72 = l_71 >> u32(16);
a_64[u32(1)] = l_72;
a_73[u32(0)] = u32(0);
a_74[u32(0)] = u32(0);
a_73[u32(1)] = u32(0);
a_74[u32(1)] = u32(0);
a_73[u32(2)] = u32(0);
a_74[u32(2)] = u32(0);
a_73[u32(3)] = u32(0);
a_74[u32(3)] = u32(0);
l_mut_45 = u32(0);
l_mut_75 = u32(0);
let l_76 = a_63[u32(0)];
let l_77 = a_63[u32(0)];
let l_78 = l_76 * l_77;
let l_79 = a_73[u32(0)];
let l_80 = l_78 + l_79;
let l_81 = l_80 + l_mut_45;
let l_82 = l_81 & u32(65535);
a_73[u32(0)] = l_82;
let l_83 = l_81 >> u32(16);
l_mut_45 = l_83;
let l_84 = a_64[u32(0)];
let l_85 = a_64[u32(0)];
let l_86 = l_84 * l_85;
let l_87 = a_74[u32(0)];
let l_88 = l_86 + l_87;
let l_89 = l_88 + l_mut_75;
let l_90 = l_89 & u32(65535);
a_74[u32(0)] = l_90;
let l_91 = l_89 >> u32(16);
l_mut_75 = l_91;
let l_92 = a_63[u32(0)];
let l_93 = a_63[u32(1)];
let l_94 = l_92 * l_93;
let l_95 = a_73[u32(1)];
let l_96 = l_94 + l_95;
let l_97 = l_96 + l_mut_45;
let l_98 = l_97 & u32(65535);
a_73[u32(1)] = l_98;
let l_99 = l_97 >> u32(16);
l_mut_45 = l_99;
let l_100 = a_64[u32(0)];
let l_101 = a_64[u32(1)];
let l_102 = l_100 * l_101;
let l_103 = a_74[u32(1)];
let l_104 = l_102 + l_103;
let l_105 = l_104 + l_mut_75;
let l_106 = l_105 & u32(65535);
a_74[u32(1)] = l_106;
let l_107 = l_105 >> u32(16);
l_mut_75 = l_107;
a_73[u32(2)] = l_mut_45;
a_74[u32(2)] = l_mut_75;
l_mut_75 = u32(0);
l_mut_45 = u32(0);
let l_108 = a_63[u32(1)];
let l_109 = a_63[u32(0)];
let l_110 = l_108 * l_109;
let l_111 = a_73[u32(1)];
let l_112 = l_110 + l_111;
let l_113 = l_112 + l_mut_75;
let l_114 = l_113 & u32(65535);
a_73[u32(1)] = l_114;
let l_115 = l_113 >> u32(16);
l_mut_75 = l_115;
let l_116 = a_64[u32(1)];
let l_117 = a_64[u32(0)];
let l_118 = l_116 * l_117;
let l_119 = a_74[u32(1)];
let l_120 = l_118 + l_119;
let l_121 = l_120 + l_mut_45;
let l_122 = l_121 & u32(65535);
a_74[u32(1)] = l_122;
let l_123 = l_121 >> u32(16);
l_mut_45 = l_123;
let l_124 = a_63[u32(1)];
let l_125 = a_63[u32(1)];
let l_126 = l_124 * l_125;
let l_127 = a_73[u32(2)];
let l_128 = l_126 + l_127;
let l_129 = l_128 + l_mut_75;
let l_130 = l_129 & u32(65535);
a_73[u32(2)] = l_130;
let l_131 = l_129 >> u32(16);
l_mut_75 = l_131;
let l_132 = a_64[u32(1)];
let l_133 = a_64[u32(1)];
let l_134 = l_132 * l_133;
let l_135 = a_74[u32(2)];
let l_136 = l_134 + l_135;
let l_137 = l_136 + l_mut_45;
let l_138 = l_137 & u32(65535);
a_74[u32(2)] = l_138;
let l_139 = l_137 >> u32(16);
l_mut_45 = l_139;
a_73[u32(3)] = l_mut_75;
a_74[u32(3)] = l_mut_45;
a_140[u32(0)] = u32(0);
a_141[u32(0)] = u32(0);
a_140[u32(1)] = u32(0);
a_141[u32(1)] = u32(0);
a_140[u32(2)] = u32(0);
a_141[u32(2)] = u32(0);
a_140[u32(3)] = u32(0);
a_141[u32(3)] = u32(0);
a_140[u32(4)] = u32(0);
a_141[u32(4)] = u32(0);
a_140[u32(5)] = u32(0);
a_141[u32(5)] = u32(0);
l_mut_75 = u32(0);
l_mut_45 = u32(0);
let l_142 = a_73[u32(0)];
let l_143 = a_63[u32(0)];
let l_144 = l_142 * l_143;
let l_145 = a_140[u32(0)];
let l_146 = l_144 + l_145;
let l_147 = l_146 + l_mut_75;
let l_148 = l_147 & u32(65535);
a_140[u32(0)] = l_148;
let l_149 = l_147 >> u32(16);
l_mut_75 = l_149;
let l_150 = a_74[u32(0)];
let l_151 = a_64[u32(0)];
let l_152 = l_150 * l_151;
let l_153 = a_141[u32(0)];
let l_154 = l_152 + l_153;
let l_155 = l_154 + l_mut_45;
let l_156 = l_155 & u32(65535);
a_141[u32(0)] = l_156;
let l_157 = l_155 >> u32(16);
l_mut_45 = l_157;
let l_158 = a_73[u32(0)];
let l_159 = a_63[u32(1)];
let l_160 = l_158 * l_159;
let l_161 = a_140[u32(1)];
let l_162 = l_160 + l_161;
let l_163 = l_162 + l_mut_75;
let l_164 = l_163 & u32(65535);
a_140[u32(1)] = l_164;
let l_165 = l_163 >> u32(16);
l_mut_75 = l_165;
let l_166 = a_74[u32(0)];
let l_167 = a_64[u32(1)];
let l_168 = l_166 * l_167;
let l_169 = a_141[u32(1)];
let l_170 = l_168 + l_169;
let l_171 = l_170 + l_mut_45;
let l_172 = l_171 & u32(65535);
a_141[u32(1)] = l_172;
let l_173 = l_171 >> u32(16);
l_mut_45 = l_173;
a_140[u32(2)] = l_mut_75;
a_141[u32(2)] = l_mut_45;
l_mut_75 = u32(0);
l_mut_45 = u32(0);
let l_174 = a_73[u32(1)];
let l_175 = a_63[u32(0)];
let l_176 = l_174 * l_175;
let l_177 = a_140[u32(1)];
let l_178 = l_176 + l_177;
let l_179 = l_178 + l_mut_75;
let l_180 = l_179 & u32(65535);
a_140[u32(1)] = l_180;
let l_181 = l_179 >> u32(16);
l_mut_75 = l_181;
let l_182 = a_74[u32(1)];
let l_183 = a_64[u32(0)];
let l_184 = l_182 * l_183;
let l_185 = a_141[u32(1)];
let l_186 = l_184 + l_185;
let l_187 = l_186 + l_mut_45;
let l_188 = l_187 & u32(65535);
a_141[u32(1)] = l_188;
let l_189 = l_187 >> u32(16);
l_mut_45 = l_189;
let l_190 = a_73[u32(1)];
let l_191 = a_63[u32(1)];
let l_192 = l_190 * l_191;
let l_193 = a_140[u32(2)];
let l_194 = l_192 + l_193;
let l_195 = l_194 + l_mut_75;
let l_196 = l_195 & u32(65535);
a_140[u32(2)] = l_196;
let l_197 = l_195 >> u32(16);
l_mut_75 = l_197;
let l_198 = a_74[u32(1)];
let l_199 = a_64[u32(1)];
let l_200 = l_198 * l_199;
let l_201 = a_141[u32(2)];
let l_202 = l_200 + l_201;
let l_203 = l_202 + l_mut_45;
let l_204 = l_203 & u32(65535);
a_141[u32(2)] = l_204;
let l_205 = l_203 >> u32(16);
l_mut_45 = l_205;
a_140[u32(3)] = l_mut_75;
a_141[u32(3)] = l_mut_45;
l_mut_75 = u32(0);
l_mut_45 = u32(0);
let l_206 = a_73[u32(2)];
let l_207 = a_63[u32(0)];
let l_208 = l_206 * l_207;
let l_209 = a_140[u32(2)];
let l_210 = l_208 + l_209;
let l_211 = l_210 + l_mut_75;
let l_212 = l_211 & u32(65535);
a_140[u32(2)] = l_212;
let l_213 = l_211 >> u32(16);
l_mut_75 = l_213;
let l_214 = a_74[u32(2)];
let l_215 = a_64[u32(0)];
let l_216 = l_214 * l_215;
let l_217 = a_141[u32(2)];
let l_218 = l_216 + l_217;
let l_219 = l_218 + l_mut_45;
let l_220 = l_219 & u32(65535);
a_141[u32(2)] = l_220;
let l_221 = l_219 >> u32(16);
l_mut_45 = l_221;
let l_222 = a_73[u32(2)];
let l_223 = a_63[u32(1)];
let l_224 = l_222 * l_223;
let l_225 = a_140[u32(3)];
let l_226 = l_224 + l_225;
let l_227 = l_226 + l_mut_75;
let l_228 = l_227 & u32(65535);
a_140[u32(3)] = l_228;
let l_229 = l_227 >> u32(16);
l_mut_75 = l_229;
let l_230 = a_74[u32(2)];
let l_231 = a_64[u32(1)];
let l_232 = l_230 * l_231;
let l_233 = a_141[u32(3)];
let l_234 = l_232 + l_233;
let l_235 = l_234 + l_mut_45;
let l_236 = l_235 & u32(65535);
a_141[u32(3)] = l_236;
let l_237 = l_235 >> u32(16);
l_mut_45 = l_237;
a_140[u32(4)] = l_mut_75;
a_141[u32(4)] = l_mut_45;
l_mut_75 = u32(0);
l_mut_45 = u32(0);
let l_238 = a_73[u32(3)];
let l_239 = a_63[u32(0)];
let l_240 = l_238 * l_239;
let l_241 = a_140[u32(3)];
let l_242 = l_240 + l_241;
let l_243 = l_242 + l_mut_75;
let l_244 = l_243 & u32(65535);
a_140[u32(3)] = l_244;
let l_245 = l_243 >> u32(16);
l_mut_75 = l_245;
let l_246 = a_74[u32(3)];
let l_247 = a_64[u32(0)];
let l_248 = l_246 * l_247;
let l_249 = a_141[u32(3)];
let l_250 = l_248 + l_249;
let l_251 = l_250 + l_mut_45;
let l_252 = l_251 & u32(65535);
a_141[u32(3)] = l_252;
let l_253 = l_251 >> u32(16);
l_mut_45 = l_253;
let l_254 = a_73[u32(3)];
let l_255 = a_63[u32(1)];
let l_256 = l_254 * l_255;
let l_257 = a_140[u32(4)];
let l_258 = l_256 + l_257;
let l_259 = l_258 + l_mut_75;
let l_260 = l_259 & u32(65535);
a_140[u32(4)] = l_260;
let l_261 = l_259 >> u32(16);
l_mut_75 = l_261;
let l_262 = a_74[u32(3)];
let l_263 = a_64[u32(1)];
let l_264 = l_262 * l_263;
let l_265 = a_141[u32(4)];
let l_266 = l_264 + l_265;
let l_267 = l_266 + l_mut_45;
let l_268 = l_267 & u32(65535);
a_141[u32(4)] = l_268;
let l_269 = l_267 >> u32(16);
l_mut_45 = l_269;
a_140[u32(5)] = l_mut_75;
a_141[u32(5)] = l_mut_45;
l_mut_75 = u32(0);
let l_277 = a_74[u32(0)];
let l_278 = a_74[u32(1)];
let l_279 = l_278 << u32(16);
let l_280 = l_277 | l_279;
let l_281 = a_73[u32(0)];
let l_282 = a_73[u32(1)];
let l_283 = l_282 << u32(16);
let l_284 = l_281 | l_283;
let l_285 = l_280 - l_284;
let l_286 = l_285 - l_mut_75;
l_mut_45 = u32(0);
let l_287 = l_280 < l_284;
let l_288 = l_280 == l_284;
let l_289 = l_mut_75 != u32(0);
let l_290 = l_288 && l_289;
let l_291 = l_287 || l_290;
if l_291 {
l_mut_45 = u32(1);
}
a_276[u32(0)] = l_286;
l_mut_75 = l_mut_45;
let l_292 = a_74[u32(2)];
let l_293 = a_74[u32(3)];
let l_294 = l_293 << u32(16);
let l_295 = l_292 | l_294;
let l_296 = a_73[u32(2)];
let l_297 = a_73[u32(3)];
let l_298 = l_297 << u32(16);
let l_299 = l_296 | l_298;
let l_300 = l_295 - l_299;
let l_301 = l_300 - l_mut_75;
l_mut_45 = u32(0);
let l_302 = l_295 < l_299;
let l_303 = l_295 == l_299;
let l_304 = l_mut_75 != u32(0);
let l_305 = l_303 && l_304;
let l_306 = l_302 || l_305;
if l_306 {
l_mut_45 = u32(1);
}
a_276[u32(1)] = l_301;
l_mut_75 = l_mut_45;
l_mut_45 = u32(0);
l_mut_307 = u32(8);
loop {
let l_308 = l_mut_45 < l_mut_307;
let l_309 = !l_308;
if l_309 {
break;
}
let l_310 = l_mut_45 + l_mut_307;
let l_311 = l_310 >> u32(1);
l_mut_312 = bool(false);
l_mut_313 = bool(true);
let l_314 = l_311 * u32(3);
let l_315 = l_314 + u32(2);
let l_316 = buffer_3_global[l_315];
l_mut_317 = u32(0);
if l_mut_313 {
let l_318 = l_mut_317 < l_316;
if l_318 {
l_mut_312 = bool(true);
l_mut_313 = bool(false);
} else {
let l_319 = l_mut_317 > l_316;
if l_319 {
l_mut_313 = bool(false);
}
}
}
let l_320 = l_311 * u32(3);
let l_321 = l_320 + u32(1);
let l_322 = buffer_3_global[l_321];
l_mut_317 = u32(0);
let l_323 = a_276[u32(1)];
l_mut_317 = l_323;
if l_mut_313 {
let l_324 = l_mut_317 < l_322;
if l_324 {
l_mut_312 = bool(true);
l_mut_313 = bool(false);
} else {
let l_325 = l_mut_317 > l_322;
if l_325 {
l_mut_313 = bool(false);
}
}
}
let l_326 = l_311 * u32(3);
let l_327 = l_326 + u32(0);
let l_328 = buffer_3_global[l_327];
l_mut_317 = u32(0);
let l_329 = a_276[u32(0)];
l_mut_317 = l_329;
if l_mut_313 {
let l_330 = l_mut_317 < l_328;
if l_330 {
l_mut_312 = bool(true);
l_mut_313 = bool(false);
} else {
let l_331 = l_mut_317 > l_328;
if l_331 {
l_mut_313 = bool(false);
}
}
}
if l_mut_312 {
l_mut_307 = l_311;
} else {
let l_332 = l_311 + u32(1);
l_mut_45 = l_332;
}
}
l_mut_317 = l_mut_45;
let l_333 = l_mut_317 < u32(3);
if l_333 {
l_mut_317 = u32(3);
}
l_mut_334 = u64(0);
l_mut_45 = u32(0);
l_mut_335 = u32(1);
l_mut_336 = u32(0);
let l_337 = a_73[u32(3)];
let l_338 = l_337 << u32(16);
let l_339 = a_73[u32(2)];
let l_340 = l_338 | l_339;
let l_341 = l_340 / u32(8000);
let l_342 = l_341 * u32(8000);
let l_343 = l_340 - l_342;
l_mut_344 = l_343;
let l_345 = l_341 >> u32(16);
a_73[u32(3)] = l_345;
let l_346 = l_341 & u32(65535);
a_73[u32(2)] = l_346;
let l_347 = a_74[u32(3)];
let l_348 = l_347 << u32(16);
let l_349 = a_74[u32(2)];
let l_350 = l_348 | l_349;
let l_351 = l_350 / u32(8000);
let l_352 = l_351 * u32(8000);
let l_353 = l_350 - l_352;
l_mut_354 = l_353;
let l_355 = l_351 >> u32(16);
a_74[u32(3)] = l_355;
let l_356 = l_351 & u32(65535);
a_74[u32(2)] = l_356;
let l_357 = l_mut_344 << u32(16);
let l_358 = a_73[u32(1)];
let l_359 = l_357 | l_358;
let l_360 = l_359 / u32(8000);
let l_361 = l_360 * u32(8000);
let l_362 = l_359 - l_361;
l_mut_344 = l_362;
a_73[u32(1)] = l_360;
let l_363 = l_mut_354 << u32(16);
let l_364 = a_74[u32(1)];
let l_365 = l_363 | l_364;
let l_366 = l_365 / u32(8000);
let l_367 = l_366 * u32(8000);
let l_368 = l_365 - l_367;
l_mut_354 = l_368;
a_74[u32(1)] = l_366;
let l_369 = l_mut_344 << u32(16);
let l_370 = a_73[u32(0)];
let l_371 = l_369 | l_370;
let l_372 = l_371 / u32(8000);
let l_373 = l_372 * u32(8000);
let l_374 = l_371 - l_373;
l_mut_344 = l_374;
a_73[u32(0)] = l_372;
let l_375 = l_mut_354 << u32(16);
let l_376 = a_74[u32(0)];
let l_377 = l_375 | l_376;
let l_378 = l_377 / u32(8000);
let l_379 = l_378 * u32(8000);
let l_380 = l_377 - l_379;
l_mut_354 = l_380;
a_74[u32(0)] = l_378;
let l_381 = l_mut_344 % u32(20);
l_mut_344 = l_mut_344 / u32(20);
let l_382 = l_mut_354 % u32(20);
l_mut_354 = l_mut_354 / u32(20);
let l_383 = u32(0) >= l_mut_317;
if l_383 {
let l_384 = l_381 == l_382;
if l_384 {
let l_385 = u64(l_381);
let l_386 = u64(1) << u32(bitcast<u64>(l_385));
let l_387 = l_mut_334 & l_386;
let l_388 = l_387 != u64(0);
if l_388 {
l_mut_45 = u32(1);
}
l_mut_334 = l_mut_334 | l_386;
} else {
l_mut_334 = u64(0);
l_mut_45 = u32(0);
l_mut_335 = l_381;
l_mut_336 = l_382;
}
}
let l_389 = l_mut_344 % u32(20);
l_mut_344 = l_mut_344 / u32(20);
let l_390 = l_mut_354 % u32(20);
l_mut_354 = l_mut_354 / u32(20);
let l_391 = u32(1) >= l_mut_317;
if l_391 {
let l_392 = l_389 == l_390;
if l_392 {
let l_393 = u64(l_389);
let l_394 = u64(1) << u32(bitcast<u64>(l_393));
let l_395 = l_mut_334 & l_394;
let l_396 = l_395 != u64(0);
if l_396 {
l_mut_45 = u32(1);
}
l_mut_334 = l_mut_334 | l_394;
} else {
l_mut_334 = u64(0);
l_mut_45 = u32(0);
l_mut_335 = l_389;
l_mut_336 = l_390;
}
}
let l_397 = l_mut_344 % u32(20);
l_mut_344 = l_mut_344 / u32(20);
let l_398 = l_mut_354 % u32(20);
l_mut_354 = l_mut_354 / u32(20);
let l_399 = u32(2) >= l_mut_317;
if l_399 {
let l_400 = l_397 == l_398;
if l_400 {
let l_401 = u64(l_397);
let l_402 = u64(1) << u32(bitcast<u64>(l_401));
let l_403 = l_mut_334 & l_402;
let l_404 = l_403 != u64(0);
if l_404 {
l_mut_45 = u32(1);
}
l_mut_334 = l_mut_334 | l_402;
} else {
l_mut_334 = u64(0);
l_mut_45 = u32(0);
l_mut_335 = l_397;
l_mut_336 = l_398;
}
}
let l_405 = a_73[u32(3)];
let l_406 = l_405 << u32(16);
let l_407 = a_73[u32(2)];
let l_408 = l_406 | l_407;
let l_409 = l_408 / u32(8000);
let l_410 = l_409 * u32(8000);
let l_411 = l_408 - l_410;
l_mut_354 = l_411;
let l_412 = l_409 >> u32(16);
a_73[u32(3)] = l_412;
let l_413 = l_409 & u32(65535);
a_73[u32(2)] = l_413;
let l_414 = a_74[u32(3)];
let l_415 = l_414 << u32(16);
let l_416 = a_74[u32(2)];
let l_417 = l_415 | l_416;
let l_418 = l_417 / u32(8000);
let l_419 = l_418 * u32(8000);
let l_420 = l_417 - l_419;
l_mut_344 = l_420;
let l_421 = l_418 >> u32(16);
a_74[u32(3)] = l_421;
let l_422 = l_418 & u32(65535);
a_74[u32(2)] = l_422;
let l_423 = l_mut_354 << u32(16);
let l_424 = a_73[u32(1)];
let l_425 = l_423 | l_424;
let l_426 = l_425 / u32(8000);
let l_427 = l_426 * u32(8000);
let l_428 = l_425 - l_427;
l_mut_354 = l_428;
a_73[u32(1)] = l_426;
let l_429 = l_mut_344 << u32(16);
let l_430 = a_74[u32(1)];
let l_431 = l_429 | l_430;
let l_432 = l_431 / u32(8000);
let l_433 = l_432 * u32(8000);
let l_434 = l_431 - l_433;
l_mut_344 = l_434;
a_74[u32(1)] = l_432;
let l_435 = l_mut_354 << u32(16);
let l_436 = a_73[u32(0)];
let l_437 = l_435 | l_436;
let l_438 = l_437 / u32(8000);
let l_439 = l_438 * u32(8000);
let l_440 = l_437 - l_439;
l_mut_354 = l_440;
a_73[u32(0)] = l_438;
let l_441 = l_mut_344 << u32(16);
let l_442 = a_74[u32(0)];
let l_443 = l_441 | l_442;
let l_444 = l_443 / u32(8000);
let l_445 = l_444 * u32(8000);
let l_446 = l_443 - l_445;
l_mut_344 = l_446;
a_74[u32(0)] = l_444;
let l_447 = l_mut_354 % u32(20);
l_mut_354 = l_mut_354 / u32(20);
let l_448 = l_mut_344 % u32(20);
l_mut_344 = l_mut_344 / u32(20);
let l_449 = u32(3) >= l_mut_317;
if l_449 {
let l_450 = l_447 == l_448;
if l_450 {
let l_451 = u64(l_447);
let l_452 = u64(1) << u32(bitcast<u64>(l_451));
let l_453 = l_mut_334 & l_452;
let l_454 = l_453 != u64(0);
if l_454 {
l_mut_45 = u32(1);
}
l_mut_334 = l_mut_334 | l_452;
} else {
l_mut_334 = u64(0);
l_mut_45 = u32(0);
l_mut_335 = l_447;
l_mut_336 = l_448;
}
}
let l_455 = l_mut_354 % u32(20);
l_mut_354 = l_mut_354 / u32(20);
let l_456 = l_mut_344 % u32(20);
l_mut_344 = l_mut_344 / u32(20);
let l_457 = u32(4) >= l_mut_317;
if l_457 {
let l_458 = l_455 == l_456;
if l_458 {
let l_459 = u64(l_455);
let l_460 = u64(1) << u32(bitcast<u64>(l_459));
let l_461 = l_mut_334 & l_460;
let l_462 = l_461 != u64(0);
if l_462 {
l_mut_45 = u32(1);
}
l_mut_334 = l_mut_334 | l_460;
} else {
l_mut_334 = u64(0);
l_mut_45 = u32(0);
l_mut_335 = l_455;
l_mut_336 = l_456;
}
}
let l_463 = l_mut_354 % u32(20);
l_mut_354 = l_mut_354 / u32(20);
let l_464 = l_mut_344 % u32(20);
l_mut_344 = l_mut_344 / u32(20);
let l_465 = u32(5) >= l_mut_317;
if l_465 {
let l_466 = l_463 == l_464;
if l_466 {
let l_467 = u64(l_463);
let l_468 = u64(1) << u32(bitcast<u64>(l_467));
let l_469 = l_mut_334 & l_468;
let l_470 = l_469 != u64(0);
if l_470 {
l_mut_45 = u32(1);
}
l_mut_334 = l_mut_334 | l_468;
} else {
l_mut_334 = u64(0);
l_mut_45 = u32(0);
l_mut_335 = l_463;
l_mut_336 = l_464;
}
}
let l_471 = a_73[u32(3)];
let l_472 = l_471 << u32(16);
let l_473 = a_73[u32(2)];
let l_474 = l_472 | l_473;
let l_475 = l_474 / u32(8000);
let l_476 = l_475 * u32(8000);
let l_477 = l_474 - l_476;
l_mut_354 = l_477;
let l_478 = l_475 >> u32(16);
a_73[u32(3)] = l_478;
let l_479 = l_475 & u32(65535);
a_73[u32(2)] = l_479;
let l_480 = a_74[u32(3)];
let l_481 = l_480 << u32(16);
let l_482 = a_74[u32(2)];
let l_483 = l_481 | l_482;
let l_484 = l_483 / u32(8000);
let l_485 = l_484 * u32(8000);
let l_486 = l_483 - l_485;
l_mut_344 = l_486;
let l_487 = l_484 >> u32(16);
a_74[u32(3)] = l_487;
let l_488 = l_484 & u32(65535);
a_74[u32(2)] = l_488;
let l_489 = l_mut_354 << u32(16);
let l_490 = a_73[u32(1)];
let l_491 = l_489 | l_490;
let l_492 = l_491 / u32(8000);
let l_493 = l_492 * u32(8000);
let l_494 = l_491 - l_493;
l_mut_354 = l_494;
a_73[u32(1)] = l_492;
let l_495 = l_mut_344 << u32(16);
let l_496 = a_74[u32(1)];
let l_497 = l_495 | l_496;
let l_498 = l_497 / u32(8000);
let l_499 = l_498 * u32(8000);
let l_500 = l_497 - l_499;
l_mut_344 = l_500;
a_74[u32(1)] = l_498;
let l_501 = l_mut_354 << u32(16);
let l_502 = a_73[u32(0)];
let l_503 = l_501 | l_502;
let l_504 = l_503 / u32(8000);
let l_505 = l_504 * u32(8000);
let l_506 = l_503 - l_505;
l_mut_354 = l_506;
a_73[u32(0)] = l_504;
let l_507 = l_mut_344 << u32(16);
let l_508 = a_74[u32(0)];
let l_509 = l_507 | l_508;
let l_510 = l_509 / u32(8000);
let l_511 = l_510 * u32(8000);
let l_512 = l_509 - l_511;
l_mut_344 = l_512;
a_74[u32(0)] = l_510;
let l_513 = l_mut_354 % u32(20);
l_mut_354 = l_mut_354 / u32(20);
let l_514 = l_mut_344 % u32(20);
l_mut_344 = l_mut_344 / u32(20);
let l_515 = u32(6) >= l_mut_317;
if l_515 {
let l_516 = l_513 == l_514;
if l_516 {
let l_517 = u64(l_513);
let l_518 = u64(1) << u32(bitcast<u64>(l_517));
let l_519 = l_mut_334 & l_518;
let l_520 = l_519 != u64(0);
if l_520 {
l_mut_45 = u32(1);
}
l_mut_334 = l_mut_334 | l_518;
} else {
l_mut_334 = u64(0);
l_mut_45 = u32(0);
l_mut_335 = l_513;
l_mut_336 = l_514;
}
}
let l_521 = l_mut_354 % u32(20);
l_mut_354 = l_mut_354 / u32(20);
let l_522 = l_mut_344 % u32(20);
l_mut_344 = l_mut_344 / u32(20);
let l_523 = u32(7) >= l_mut_317;
if l_523 {
let l_524 = l_521 == l_522;
if l_524 {
let l_525 = u64(l_521);
let l_526 = u64(1) << u32(bitcast<u64>(l_525));
let l_527 = l_mut_334 & l_526;
let l_528 = l_527 != u64(0);
if l_528 {
l_mut_45 = u32(1);
}
l_mut_334 = l_mut_334 | l_526;
} else {
l_mut_334 = u64(0);
l_mut_45 = u32(0);
l_mut_335 = l_521;
l_mut_336 = l_522;
}
}
let l_529 = l_mut_354 % u32(20);
l_mut_354 = l_mut_354 / u32(20);
let l_530 = l_mut_344 % u32(20);
l_mut_344 = l_mut_344 / u32(20);
a_270[u32(0)] = l_mut_317;
a_271[u32(0)] = l_mut_45;
a_274[u32(0)] = l_mut_335;
a_274[u32(1)] = l_mut_336;
l_mut_354 = u32(0);
let l_532 = a_141[u32(0)];
let l_533 = a_141[u32(1)];
let l_534 = l_533 << u32(16);
let l_535 = l_532 | l_534;
let l_536 = a_140[u32(0)];
let l_537 = a_140[u32(1)];
let l_538 = l_537 << u32(16);
let l_539 = l_536 | l_538;
let l_540 = l_535 - l_539;
let l_541 = l_540 - l_mut_354;
l_mut_344 = u32(0);
let l_542 = l_535 < l_539;
let l_543 = l_535 == l_539;
let l_544 = l_mut_354 != u32(0);
let l_545 = l_543 && l_544;
let l_546 = l_542 || l_545;
if l_546 {
l_mut_344 = u32(1);
}
a_531[u32(0)] = l_541;
l_mut_354 = l_mut_344;
let l_547 = a_141[u32(2)];
let l_548 = a_141[u32(3)];
let l_549 = l_548 << u32(16);
let l_550 = l_547 | l_549;
let l_551 = a_140[u32(2)];
let l_552 = a_140[u32(3)];
let l_553 = l_552 << u32(16);
let l_554 = l_551 | l_553;
let l_555 = l_550 - l_554;
let l_556 = l_555 - l_mut_354;
l_mut_344 = u32(0);
let l_557 = l_550 < l_554;
let l_558 = l_550 == l_554;
let l_559 = l_mut_354 != u32(0);
let l_560 = l_558 && l_559;
let l_561 = l_557 || l_560;
if l_561 {
l_mut_344 = u32(1);
}
a_531[u32(1)] = l_556;
l_mut_354 = l_mut_344;
let l_562 = a_141[u32(4)];
let l_563 = a_141[u32(5)];
let l_564 = l_563 << u32(16);
let l_565 = l_562 | l_564;
let l_566 = a_140[u32(4)];
let l_567 = a_140[u32(5)];
let l_568 = l_567 << u32(16);
let l_569 = l_566 | l_568;
let l_570 = l_565 - l_569;
let l_571 = l_570 - l_mut_354;
l_mut_344 = u32(0);
let l_572 = l_565 < l_569;
let l_573 = l_565 == l_569;
let l_574 = l_mut_354 != u32(0);
let l_575 = l_573 && l_574;
let l_576 = l_572 || l_575;
if l_576 {
l_mut_344 = u32(1);
}
a_531[u32(2)] = l_571;
l_mut_354 = l_mut_344;
l_mut_344 = u32(0);
l_mut_336 = u32(12);
loop {
let l_577 = l_mut_344 < l_mut_336;
let l_578 = !l_577;
if l_578 {
break;
}
let l_579 = l_mut_344 + l_mut_336;
let l_580 = l_579 >> u32(1);
l_mut_313 = bool(false);
l_mut_312 = bool(true);
let l_581 = l_580 * u32(3);
let l_582 = l_581 + u32(2);
let l_583 = buffer_3_global[l_582];
l_mut_335 = u32(0);
let l_584 = a_531[u32(2)];
l_mut_335 = l_584;
if l_mut_312 {
let l_585 = l_mut_335 < l_583;
if l_585 {
l_mut_313 = bool(true);
l_mut_312 = bool(false);
} else {
let l_586 = l_mut_335 > l_583;
if l_586 {
l_mut_312 = bool(false);
}
}
}
let l_587 = l_580 * u32(3);
let l_588 = l_587 + u32(1);
let l_589 = buffer_3_global[l_588];
l_mut_335 = u32(0);
let l_590 = a_531[u32(1)];
l_mut_335 = l_590;
if l_mut_312 {
let l_591 = l_mut_335 < l_589;
if l_591 {
l_mut_313 = bool(true);
l_mut_312 = bool(false);
} else {
let l_592 = l_mut_335 > l_589;
if l_592 {
l_mut_312 = bool(false);
}
}
}
let l_593 = l_580 * u32(3);
let l_594 = l_593 + u32(0);
let l_595 = buffer_3_global[l_594];
l_mut_335 = u32(0);
let l_596 = a_531[u32(0)];
l_mut_335 = l_596;
if l_mut_312 {
let l_597 = l_mut_335 < l_595;
if l_597 {
l_mut_313 = bool(true);
l_mut_312 = bool(false);
} else {
let l_598 = l_mut_335 > l_595;
if l_598 {
l_mut_312 = bool(false);
}
}
}
if l_mut_313 {
l_mut_336 = l_580;
} else {
let l_599 = l_580 + u32(1);
l_mut_344 = l_599;
}
}
l_mut_335 = l_mut_344;
let l_600 = l_mut_335 < u32(3);
if l_600 {
l_mut_335 = u32(3);
}
l_mut_601 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = u32(1);
l_mut_307 = u32(0);
let l_602 = a_140[u32(5)];
let l_603 = l_602 << u32(16);
let l_604 = a_140[u32(4)];
let l_605 = l_603 | l_604;
let l_606 = l_605 / u32(8000);
let l_607 = l_606 * u32(8000);
let l_608 = l_605 - l_607;
l_mut_75 = l_608;
let l_609 = l_606 >> u32(16);
a_140[u32(5)] = l_609;
let l_610 = l_606 & u32(65535);
a_140[u32(4)] = l_610;
let l_611 = a_141[u32(5)];
let l_612 = l_611 << u32(16);
let l_613 = a_141[u32(4)];
let l_614 = l_612 | l_613;
let l_615 = l_614 / u32(8000);
let l_616 = l_615 * u32(8000);
let l_617 = l_614 - l_616;
l_mut_45 = l_617;
let l_618 = l_615 >> u32(16);
a_141[u32(5)] = l_618;
let l_619 = l_615 & u32(65535);
a_141[u32(4)] = l_619;
let l_620 = l_mut_75 << u32(16);
let l_621 = a_140[u32(3)];
let l_622 = l_620 | l_621;
let l_623 = l_622 / u32(8000);
let l_624 = l_623 * u32(8000);
let l_625 = l_622 - l_624;
l_mut_75 = l_625;
a_140[u32(3)] = l_623;
let l_626 = l_mut_45 << u32(16);
let l_627 = a_141[u32(3)];
let l_628 = l_626 | l_627;
let l_629 = l_628 / u32(8000);
let l_630 = l_629 * u32(8000);
let l_631 = l_628 - l_630;
l_mut_45 = l_631;
a_141[u32(3)] = l_629;
let l_632 = l_mut_75 << u32(16);
let l_633 = a_140[u32(2)];
let l_634 = l_632 | l_633;
let l_635 = l_634 / u32(8000);
let l_636 = l_635 * u32(8000);
let l_637 = l_634 - l_636;
l_mut_75 = l_637;
a_140[u32(2)] = l_635;
let l_638 = l_mut_45 << u32(16);
let l_639 = a_141[u32(2)];
let l_640 = l_638 | l_639;
let l_641 = l_640 / u32(8000);
let l_642 = l_641 * u32(8000);
let l_643 = l_640 - l_642;
l_mut_45 = l_643;
a_141[u32(2)] = l_641;
let l_644 = l_mut_75 << u32(16);
let l_645 = a_140[u32(1)];
let l_646 = l_644 | l_645;
let l_647 = l_646 / u32(8000);
let l_648 = l_647 * u32(8000);
let l_649 = l_646 - l_648;
l_mut_75 = l_649;
a_140[u32(1)] = l_647;
let l_650 = l_mut_45 << u32(16);
let l_651 = a_141[u32(1)];
let l_652 = l_650 | l_651;
let l_653 = l_652 / u32(8000);
let l_654 = l_653 * u32(8000);
let l_655 = l_652 - l_654;
l_mut_45 = l_655;
a_141[u32(1)] = l_653;
let l_656 = l_mut_75 << u32(16);
let l_657 = a_140[u32(0)];
let l_658 = l_656 | l_657;
let l_659 = l_658 / u32(8000);
let l_660 = l_659 * u32(8000);
let l_661 = l_658 - l_660;
l_mut_75 = l_661;
a_140[u32(0)] = l_659;
let l_662 = l_mut_45 << u32(16);
let l_663 = a_141[u32(0)];
let l_664 = l_662 | l_663;
let l_665 = l_664 / u32(8000);
let l_666 = l_665 * u32(8000);
let l_667 = l_664 - l_666;
l_mut_45 = l_667;
a_141[u32(0)] = l_665;
let l_668 = l_mut_75 % u32(20);
l_mut_75 = l_mut_75 / u32(20);
let l_669 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_670 = u32(0) >= l_mut_335;
if l_670 {
let l_671 = l_668 == l_669;
if l_671 {
let l_672 = u64(l_668);
let l_673 = u64(1) << u32(bitcast<u64>(l_672));
let l_674 = l_mut_601 & l_673;
let l_675 = l_674 != u64(0);
if l_675 {
l_mut_344 = u32(1);
}
l_mut_601 = l_mut_601 | l_673;
} else {
l_mut_601 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_668;
l_mut_307 = l_669;
}
}
let l_676 = l_mut_75 % u32(20);
l_mut_75 = l_mut_75 / u32(20);
let l_677 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_678 = u32(1) >= l_mut_335;
if l_678 {
let l_679 = l_676 == l_677;
if l_679 {
let l_680 = u64(l_676);
let l_681 = u64(1) << u32(bitcast<u64>(l_680));
let l_682 = l_mut_601 & l_681;
let l_683 = l_682 != u64(0);
if l_683 {
l_mut_344 = u32(1);
}
l_mut_601 = l_mut_601 | l_681;
} else {
l_mut_601 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_676;
l_mut_307 = l_677;
}
}
let l_684 = l_mut_75 % u32(20);
l_mut_75 = l_mut_75 / u32(20);
let l_685 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_686 = u32(2) >= l_mut_335;
if l_686 {
let l_687 = l_684 == l_685;
if l_687 {
let l_688 = u64(l_684);
let l_689 = u64(1) << u32(bitcast<u64>(l_688));
let l_690 = l_mut_601 & l_689;
let l_691 = l_690 != u64(0);
if l_691 {
l_mut_344 = u32(1);
}
l_mut_601 = l_mut_601 | l_689;
} else {
l_mut_601 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_684;
l_mut_307 = l_685;
}
}
let l_692 = a_140[u32(5)];
let l_693 = l_692 << u32(16);
let l_694 = a_140[u32(4)];
let l_695 = l_693 | l_694;
let l_696 = l_695 / u32(8000);
let l_697 = l_696 * u32(8000);
let l_698 = l_695 - l_697;
l_mut_75 = l_698;
let l_699 = l_696 >> u32(16);
a_140[u32(5)] = l_699;
let l_700 = l_696 & u32(65535);
a_140[u32(4)] = l_700;
let l_701 = a_141[u32(5)];
let l_702 = l_701 << u32(16);
let l_703 = a_141[u32(4)];
let l_704 = l_702 | l_703;
let l_705 = l_704 / u32(8000);
let l_706 = l_705 * u32(8000);
let l_707 = l_704 - l_706;
l_mut_45 = l_707;
let l_708 = l_705 >> u32(16);
a_141[u32(5)] = l_708;
let l_709 = l_705 & u32(65535);
a_141[u32(4)] = l_709;
let l_710 = l_mut_75 << u32(16);
let l_711 = a_140[u32(3)];
let l_712 = l_710 | l_711;
let l_713 = l_712 / u32(8000);
let l_714 = l_713 * u32(8000);
let l_715 = l_712 - l_714;
l_mut_75 = l_715;
a_140[u32(3)] = l_713;
let l_716 = l_mut_45 << u32(16);
let l_717 = a_141[u32(3)];
let l_718 = l_716 | l_717;
let l_719 = l_718 / u32(8000);
let l_720 = l_719 * u32(8000);
let l_721 = l_718 - l_720;
l_mut_45 = l_721;
a_141[u32(3)] = l_719;
let l_722 = l_mut_75 << u32(16);
let l_723 = a_140[u32(2)];
let l_724 = l_722 | l_723;
let l_725 = l_724 / u32(8000);
let l_726 = l_725 * u32(8000);
let l_727 = l_724 - l_726;
l_mut_75 = l_727;
a_140[u32(2)] = l_725;
let l_728 = l_mut_45 << u32(16);
let l_729 = a_141[u32(2)];
let l_730 = l_728 | l_729;
let l_731 = l_730 / u32(8000);
let l_732 = l_731 * u32(8000);
let l_733 = l_730 - l_732;
l_mut_45 = l_733;
a_141[u32(2)] = l_731;
let l_734 = l_mut_75 << u32(16);
let l_735 = a_140[u32(1)];
let l_736 = l_734 | l_735;
let l_737 = l_736 / u32(8000);
let l_738 = l_737 * u32(8000);
let l_739 = l_736 - l_738;
l_mut_75 = l_739;
a_140[u32(1)] = l_737;
let l_740 = l_mut_45 << u32(16);
let l_741 = a_141[u32(1)];
let l_742 = l_740 | l_741;
let l_743 = l_742 / u32(8000);
let l_744 = l_743 * u32(8000);
let l_745 = l_742 - l_744;
l_mut_45 = l_745;
a_141[u32(1)] = l_743;
let l_746 = l_mut_75 << u32(16);
let l_747 = a_140[u32(0)];
let l_748 = l_746 | l_747;
let l_749 = l_748 / u32(8000);
let l_750 = l_749 * u32(8000);
let l_751 = l_748 - l_750;
l_mut_75 = l_751;
a_140[u32(0)] = l_749;
let l_752 = l_mut_45 << u32(16);
let l_753 = a_141[u32(0)];
let l_754 = l_752 | l_753;
let l_755 = l_754 / u32(8000);
let l_756 = l_755 * u32(8000);
let l_757 = l_754 - l_756;
l_mut_45 = l_757;
a_141[u32(0)] = l_755;
let l_758 = l_mut_75 % u32(20);
l_mut_75 = l_mut_75 / u32(20);
let l_759 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_760 = u32(3) >= l_mut_335;
if l_760 {
let l_761 = l_758 == l_759;
if l_761 {
let l_762 = u64(l_758);
let l_763 = u64(1) << u32(bitcast<u64>(l_762));
let l_764 = l_mut_601 & l_763;
let l_765 = l_764 != u64(0);
if l_765 {
l_mut_344 = u32(1);
}
l_mut_601 = l_mut_601 | l_763;
} else {
l_mut_601 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_758;
l_mut_307 = l_759;
}
}
let l_766 = l_mut_75 % u32(20);
l_mut_75 = l_mut_75 / u32(20);
let l_767 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_768 = u32(4) >= l_mut_335;
if l_768 {
let l_769 = l_766 == l_767;
if l_769 {
let l_770 = u64(l_766);
let l_771 = u64(1) << u32(bitcast<u64>(l_770));
let l_772 = l_mut_601 & l_771;
let l_773 = l_772 != u64(0);
if l_773 {
l_mut_344 = u32(1);
}
l_mut_601 = l_mut_601 | l_771;
} else {
l_mut_601 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_766;
l_mut_307 = l_767;
}
}
let l_774 = l_mut_75 % u32(20);
l_mut_75 = l_mut_75 / u32(20);
let l_775 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_776 = u32(5) >= l_mut_335;
if l_776 {
let l_777 = l_774 == l_775;
if l_777 {
let l_778 = u64(l_774);
let l_779 = u64(1) << u32(bitcast<u64>(l_778));
let l_780 = l_mut_601 & l_779;
let l_781 = l_780 != u64(0);
if l_781 {
l_mut_344 = u32(1);
}
l_mut_601 = l_mut_601 | l_779;
} else {
l_mut_601 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_774;
l_mut_307 = l_775;
}
}
let l_782 = a_140[u32(5)];
let l_783 = l_782 << u32(16);
let l_784 = a_140[u32(4)];
let l_785 = l_783 | l_784;
let l_786 = l_785 / u32(8000);
let l_787 = l_786 * u32(8000);
let l_788 = l_785 - l_787;
l_mut_75 = l_788;
let l_789 = l_786 >> u32(16);
a_140[u32(5)] = l_789;
let l_790 = l_786 & u32(65535);
a_140[u32(4)] = l_790;
let l_791 = a_141[u32(5)];
let l_792 = l_791 << u32(16);
let l_793 = a_141[u32(4)];
let l_794 = l_792 | l_793;
let l_795 = l_794 / u32(8000);
let l_796 = l_795 * u32(8000);
let l_797 = l_794 - l_796;
l_mut_45 = l_797;
let l_798 = l_795 >> u32(16);
a_141[u32(5)] = l_798;
let l_799 = l_795 & u32(65535);
a_141[u32(4)] = l_799;
let l_800 = l_mut_75 << u32(16);
let l_801 = a_140[u32(3)];
let l_802 = l_800 | l_801;
let l_803 = l_802 / u32(8000);
let l_804 = l_803 * u32(8000);
let l_805 = l_802 - l_804;
l_mut_75 = l_805;
a_140[u32(3)] = l_803;
let l_806 = l_mut_45 << u32(16);
let l_807 = a_141[u32(3)];
let l_808 = l_806 | l_807;
let l_809 = l_808 / u32(8000);
let l_810 = l_809 * u32(8000);
let l_811 = l_808 - l_810;
l_mut_45 = l_811;
a_141[u32(3)] = l_809;
let l_812 = l_mut_75 << u32(16);
let l_813 = a_140[u32(2)];
let l_814 = l_812 | l_813;
let l_815 = l_814 / u32(8000);
let l_816 = l_815 * u32(8000);
let l_817 = l_814 - l_816;
l_mut_75 = l_817;
a_140[u32(2)] = l_815;
let l_818 = l_mut_45 << u32(16);
let l_819 = a_141[u32(2)];
let l_820 = l_818 | l_819;
let l_821 = l_820 / u32(8000);
let l_822 = l_821 * u32(8000);
let l_823 = l_820 - l_822;
l_mut_45 = l_823;
a_141[u32(2)] = l_821;
let l_824 = l_mut_75 << u32(16);
let l_825 = a_140[u32(1)];
let l_826 = l_824 | l_825;
let l_827 = l_826 / u32(8000);
let l_828 = l_827 * u32(8000);
let l_829 = l_826 - l_828;
l_mut_75 = l_829;
a_140[u32(1)] = l_827;
let l_830 = l_mut_45 << u32(16);
let l_831 = a_141[u32(1)];
let l_832 = l_830 | l_831;
let l_833 = l_832 / u32(8000);
let l_834 = l_833 * u32(8000);
let l_835 = l_832 - l_834;
l_mut_45 = l_835;
a_141[u32(1)] = l_833;
let l_836 = l_mut_75 << u32(16);
let l_837 = a_140[u32(0)];
let l_838 = l_836 | l_837;
let l_839 = l_838 / u32(8000);
let l_840 = l_839 * u32(8000);
let l_841 = l_838 - l_840;
l_mut_75 = l_841;
a_140[u32(0)] = l_839;
let l_842 = l_mut_45 << u32(16);
let l_843 = a_141[u32(0)];
let l_844 = l_842 | l_843;
let l_845 = l_844 / u32(8000);
let l_846 = l_845 * u32(8000);
let l_847 = l_844 - l_846;
l_mut_45 = l_847;
a_141[u32(0)] = l_845;
let l_848 = l_mut_75 % u32(20);
l_mut_75 = l_mut_75 / u32(20);
let l_849 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_850 = u32(6) >= l_mut_335;
if l_850 {
let l_851 = l_848 == l_849;
if l_851 {
let l_852 = u64(l_848);
let l_853 = u64(1) << u32(bitcast<u64>(l_852));
let l_854 = l_mut_601 & l_853;
let l_855 = l_854 != u64(0);
if l_855 {
l_mut_344 = u32(1);
}
l_mut_601 = l_mut_601 | l_853;
} else {
l_mut_601 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_848;
l_mut_307 = l_849;
}
}
let l_856 = l_mut_75 % u32(20);
l_mut_75 = l_mut_75 / u32(20);
let l_857 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_858 = u32(7) >= l_mut_335;
if l_858 {
let l_859 = l_856 == l_857;
if l_859 {
let l_860 = u64(l_856);
let l_861 = u64(1) << u32(bitcast<u64>(l_860));
let l_862 = l_mut_601 & l_861;
let l_863 = l_862 != u64(0);
if l_863 {
l_mut_344 = u32(1);
}
l_mut_601 = l_mut_601 | l_861;
} else {
l_mut_601 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_856;
l_mut_307 = l_857;
}
}
let l_864 = l_mut_75 % u32(20);
l_mut_75 = l_mut_75 / u32(20);
let l_865 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_866 = u32(8) >= l_mut_335;
if l_866 {
let l_867 = l_864 == l_865;
if l_867 {
let l_868 = u64(l_864);
let l_869 = u64(1) << u32(bitcast<u64>(l_868));
let l_870 = l_mut_601 & l_869;
let l_871 = l_870 != u64(0);
if l_871 {
l_mut_344 = u32(1);
}
l_mut_601 = l_mut_601 | l_869;
} else {
l_mut_601 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_864;
l_mut_307 = l_865;
}
}
let l_872 = a_140[u32(5)];
let l_873 = l_872 << u32(16);
let l_874 = a_140[u32(4)];
let l_875 = l_873 | l_874;
let l_876 = l_875 / u32(8000);
let l_877 = l_876 * u32(8000);
let l_878 = l_875 - l_877;
l_mut_75 = l_878;
let l_879 = l_876 >> u32(16);
a_140[u32(5)] = l_879;
let l_880 = l_876 & u32(65535);
a_140[u32(4)] = l_880;
let l_881 = a_141[u32(5)];
let l_882 = l_881 << u32(16);
let l_883 = a_141[u32(4)];
let l_884 = l_882 | l_883;
let l_885 = l_884 / u32(8000);
let l_886 = l_885 * u32(8000);
let l_887 = l_884 - l_886;
l_mut_45 = l_887;
let l_888 = l_885 >> u32(16);
a_141[u32(5)] = l_888;
let l_889 = l_885 & u32(65535);
a_141[u32(4)] = l_889;
let l_890 = l_mut_75 << u32(16);
let l_891 = a_140[u32(3)];
let l_892 = l_890 | l_891;
let l_893 = l_892 / u32(8000);
let l_894 = l_893 * u32(8000);
let l_895 = l_892 - l_894;
l_mut_75 = l_895;
a_140[u32(3)] = l_893;
let l_896 = l_mut_45 << u32(16);
let l_897 = a_141[u32(3)];
let l_898 = l_896 | l_897;
let l_899 = l_898 / u32(8000);
let l_900 = l_899 * u32(8000);
let l_901 = l_898 - l_900;
l_mut_45 = l_901;
a_141[u32(3)] = l_899;
let l_902 = l_mut_75 << u32(16);
let l_903 = a_140[u32(2)];
let l_904 = l_902 | l_903;
let l_905 = l_904 / u32(8000);
let l_906 = l_905 * u32(8000);
let l_907 = l_904 - l_906;
l_mut_75 = l_907;
a_140[u32(2)] = l_905;
let l_908 = l_mut_45 << u32(16);
let l_909 = a_141[u32(2)];
let l_910 = l_908 | l_909;
let l_911 = l_910 / u32(8000);
let l_912 = l_911 * u32(8000);
let l_913 = l_910 - l_912;
l_mut_45 = l_913;
a_141[u32(2)] = l_911;
let l_914 = l_mut_75 << u32(16);
let l_915 = a_140[u32(1)];
let l_916 = l_914 | l_915;
let l_917 = l_916 / u32(8000);
let l_918 = l_917 * u32(8000);
let l_919 = l_916 - l_918;
l_mut_75 = l_919;
a_140[u32(1)] = l_917;
let l_920 = l_mut_45 << u32(16);
let l_921 = a_141[u32(1)];
let l_922 = l_920 | l_921;
let l_923 = l_922 / u32(8000);
let l_924 = l_923 * u32(8000);
let l_925 = l_922 - l_924;
l_mut_45 = l_925;
a_141[u32(1)] = l_923;
let l_926 = l_mut_75 << u32(16);
let l_927 = a_140[u32(0)];
let l_928 = l_926 | l_927;
let l_929 = l_928 / u32(8000);
let l_930 = l_929 * u32(8000);
let l_931 = l_928 - l_930;
l_mut_75 = l_931;
a_140[u32(0)] = l_929;
let l_932 = l_mut_45 << u32(16);
let l_933 = a_141[u32(0)];
let l_934 = l_932 | l_933;
let l_935 = l_934 / u32(8000);
let l_936 = l_935 * u32(8000);
let l_937 = l_934 - l_936;
l_mut_45 = l_937;
a_141[u32(0)] = l_935;
let l_938 = l_mut_75 % u32(20);
l_mut_75 = l_mut_75 / u32(20);
let l_939 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_940 = u32(9) >= l_mut_335;
if l_940 {
let l_941 = l_938 == l_939;
if l_941 {
let l_942 = u64(l_938);
let l_943 = u64(1) << u32(bitcast<u64>(l_942));
let l_944 = l_mut_601 & l_943;
let l_945 = l_944 != u64(0);
if l_945 {
l_mut_344 = u32(1);
}
l_mut_601 = l_mut_601 | l_943;
} else {
l_mut_601 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_938;
l_mut_307 = l_939;
}
}
let l_946 = l_mut_75 % u32(20);
l_mut_75 = l_mut_75 / u32(20);
let l_947 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_948 = u32(10) >= l_mut_335;
if l_948 {
let l_949 = l_946 == l_947;
if l_949 {
let l_950 = u64(l_946);
let l_951 = u64(1) << u32(bitcast<u64>(l_950));
let l_952 = l_mut_601 & l_951;
let l_953 = l_952 != u64(0);
if l_953 {
l_mut_344 = u32(1);
}
l_mut_601 = l_mut_601 | l_951;
} else {
l_mut_601 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_946;
l_mut_307 = l_947;
}
}
let l_954 = l_mut_75 % u32(20);
l_mut_75 = l_mut_75 / u32(20);
let l_955 = l_mut_45 % u32(20);
l_mut_45 = l_mut_45 / u32(20);
let l_956 = u32(11) >= l_mut_335;
if l_956 {
let l_957 = l_954 == l_955;
if l_957 {
let l_958 = u64(l_954);
let l_959 = u64(1) << u32(bitcast<u64>(l_958));
let l_960 = l_mut_601 & l_959;
let l_961 = l_960 != u64(0);
if l_961 {
l_mut_344 = u32(1);
}
l_mut_601 = l_mut_601 | l_959;
} else {
l_mut_601 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_954;
l_mut_307 = l_955;
}
}
a_272[u32(0)] = l_mut_335;
a_273[u32(0)] = l_mut_344;
a_275[u32(0)] = l_mut_317;
a_275[u32(1)] = l_mut_307;
let l_962 = l_mut_334 | l_mut_601;
l_mut_963 = l_962;
let l_964 = a_271[u32(0)];
let l_965 = l_964 == u32(0);
let l_966 = a_273[u32(0)];
let l_967 = l_966 == u32(0);
let l_968 = l_965 && l_967;
let l_969 = l_mut_334 & l_mut_601;
let l_970 = l_969 == u64(0);
let l_971 = l_968 && l_970;
l_mut_313 = l_971;
let l_972 = a_274[u32(0)];
let l_973 = a_274[u32(1)];
l_mut_601 = u64(0);
let l_974 = l_973 >= l_972;
if l_974 {
let l_975 = l_973 - l_972;
let l_976 = l_975 + u32(1);
let l_977 = l_976 >= u32(64);
if l_977 {
let l_978 = u64(l_972);
let l_979 = bitcast<u64>(i64(-1)) << u32(bitcast<u64>(l_978));
l_mut_601 = l_979;
} else {
let l_980 = u64(l_976);
let l_981 = u64(1) << u32(bitcast<u64>(l_980));
let l_982 = l_981 - u64(1);
let l_983 = u64(l_972);
let l_984 = l_982 << u32(bitcast<u64>(l_983));
l_mut_601 = l_984;
}
}
let l_985 = a_275[u32(0)];
let l_986 = a_275[u32(1)];
l_mut_334 = u64(0);
let l_987 = l_986 >= l_985;
if l_987 {
let l_988 = l_986 - l_985;
let l_989 = l_988 + u32(1);
let l_990 = l_989 >= u32(64);
if l_990 {
let l_991 = u64(l_985);
let l_992 = bitcast<u64>(i64(-1)) << u32(bitcast<u64>(l_991));
l_mut_334 = l_992;
} else {
let l_993 = u64(l_989);
let l_994 = u64(1) << u32(bitcast<u64>(l_993));
let l_995 = l_994 - u64(1);
let l_996 = u64(l_985);
let l_997 = l_995 << u32(bitcast<u64>(l_996));
l_mut_334 = l_997;
}
}
l_mut_312 = bool(false);
l_mut_998 = bool(false);
let l_999 = l_mut_601 != u64(0);
let l_1000 = l_mut_313 && l_999;
if l_1000 {
let l_1001 = ~l_mut_963;
let l_1002 = l_mut_601 & l_1001;
let l_1003 = l_1002 == u64(0);
if l_1003 {
l_mut_313 = bool(false);
} else {
let l_1004 = l_1002 - u64(1);
let l_1005 = l_1002 & l_1004;
let l_1006 = l_1005 == u64(0);
if l_1006 {
l_mut_963 = l_mut_963 | l_1002;
l_mut_312 = bool(true);
}
}
}
let l_1007 = l_mut_334 != u64(0);
let l_1008 = l_mut_313 && l_1007;
if l_1008 {
let l_1009 = ~l_mut_963;
let l_1010 = l_mut_334 & l_1009;
let l_1011 = l_1010 == u64(0);
if l_1011 {
l_mut_313 = bool(false);
} else {
let l_1012 = l_1010 - u64(1);
let l_1013 = l_1010 & l_1012;
let l_1014 = l_1013 == u64(0);
if l_1014 {
l_mut_963 = l_mut_963 | l_1010;
l_mut_998 = bool(true);
}
}
}
let l_1015 = l_mut_601 != u64(0);
let l_1016 = l_mut_313 && l_1015;
let l_1017 = !l_mut_312;
let l_1018 = l_1016 && l_1017;
let l_1019 = l_1018 && l_mut_998;
if l_1019 {
let l_1020 = ~l_mut_963;
let l_1021 = l_mut_601 & l_1020;
let l_1022 = l_1021 == u64(0);
if l_1022 {
l_mut_313 = bool(false);
} else {
let l_1023 = l_1021 - u64(1);
let l_1024 = l_1021 & l_1023;
let l_1025 = l_1024 == u64(0);
if l_1025 {
l_mut_963 = l_mut_963 | l_1021;
}
}
}
if l_mut_313 {
let l_1026 = a_270[u32(0)];
l_mut_354 = l_1026;
let l_1027 = a_272[u32(0)];
let l_1028 = l_1027 < l_mut_354;
if l_1028 {
let l_1029 = a_272[u32(0)];
l_mut_354 = l_1029;
}
let l_1030 = !l_mut_47;
let l_1031 = !l_mut_48;
let l_1032 = l_1030 && l_1031;
if l_1032 {
l_mut_354 = info.scalars_u32[5];
}
let l_1033 = &buffer_10_global[workgroup_id.y];
let l_1034 = atomicAdd(l_1033, u32(1));let l_1035 = workgroup_id.y * info.scalars_u32[0];
let l_1036 = l_1035 + l_1034;
let l_1037 = u32(2) * l_1036;
let l_1038 = u32(bitcast<u64>(l_14));
buffer_5_global[l_1037] = l_1038;
let l_1039 = u32(2) * l_1036;
let l_1040 = l_1039 + u32(1);
let l_1041 = l_14 >> u32(bitcast<u64>(u64(32)));
let l_1042 = u32(bitcast<u64>(l_1041));
buffer_5_global[l_1040] = l_1042;
let l_1043 = u32(2) * l_1036;
let l_1044 = u32(bitcast<u64>(l_mut_963));
buffer_6_global[l_1043] = l_1044;
let l_1045 = u32(2) * l_1036;
let l_1046 = l_1045 + u32(1);
let l_1047 = l_mut_963 >> u32(bitcast<u64>(u64(32)));
let l_1048 = u32(bitcast<u64>(l_1047));
buffer_6_global[l_1046] = l_1048;
let l_1049 = u32(2) * l_1036;
let l_1050 = a_39[u32(0)];
let l_1051 = l_1050 - l_38;
buffer_7_global[l_1049] = l_1051;
let l_1052 = u32(2) * l_1036;
let l_1053 = l_1052 + u32(1);
let l_1054 = a_40[u32(0)];
let l_1055 = l_1054 - l_38;
let l_1056 = l_1055 + u32(1);
buffer_7_global[l_1053] = l_1056;
let l_1057 = u32(5) * global_id.x;
let l_1058 = l_1057 + u32(4);
let l_1059 = buffer_0_global[l_1058];
let l_1060 = l_1059 * info.scalars_u32[3];
let l_1061 = l_1060 + l_10;
let l_1062 = u32(2) * l_1036;
buffer_8_global[l_1062] = l_1061;
l_mut_344 = u32(0);
let l_1063 = l_mut_354 >= u32(5);
if l_1063 {
l_mut_344 = u32(1);
}
let l_1064 = u32(2) * l_1036;
let l_1065 = l_1064 + u32(1);
buffer_8_global[l_1065] = l_mut_344;
let l_1066 = u32(5) * global_id.x;
let l_1067 = l_1066 + u32(2);
let l_1068 = buffer_0_global[l_1067];
let l_1069 = l_1068 * info.scalars_u32[4];
let l_1070 = l_1069 + l_10;
let l_1071 = l_1070 % u32(19);
l_mut_354 = u32(0);
let l_1072 = l_mut_354 << u32(8);
let l_1073 = l_1071 | l_1072;
buffer_9_global[l_1036] = l_1073;
l_mut_344 = u32(0);
loop {
let l_1074 = l_mut_344 < info.scalars_u32[1];
let l_1075 = !l_1074;
if l_1075 {
break;
}
let l_1076 = buffer_4_global[l_mut_344];
let l_1077 = l_1076 + u32(19);
let l_1078 = l_1077 - l_1071;
let l_1079 = l_1078 % u32(19);
let l_1080 = workgroup_id.y * u32(19);
let l_1081 = l_mut_354 * u32(19);
let l_1082 = l_1080 + l_1081;
let l_1083 = l_1082 + l_1079;
let l_1084 = &buffer_11_global[l_1083];
let l_1085 = atomicAdd(l_1084, u32(1));l_mut_344 = l_mut_344 + u32(1);
}
}
}
}
workgroupBarrier();
let l_1086 = local_invocation_id.x == u32(0);
if l_1086 {
let l_1087 = &buffer_12_global[u32(0)];
let l_1088 = atomicAdd(l_1087, u32(1));}
}
```
