
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

var a_413: array<u32, 3>;

var a_272: array<u32, 1>;

var a_273: array<u32, 1>;

var a_275: array<u32, 2>;

var l_mut_47: bool;
var l_mut_48: bool;
var l_mut_49: bool;
var l_mut_50: bool;
var l_mut_312: bool;
var l_mut_313: bool;
var l_mut_704: bool;
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
var l_mut_483: u64;
var l_mut_669: u64;
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
l_mut_307 = u32(4);
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
let l_333 = l_mut_317 < u32(1);
if l_333 {
l_mut_317 = u32(1);
}
l_mut_334 = u64(0);
l_mut_45 = u32(0);
l_mut_335 = u32(1);
l_mut_336 = u32(0);
let l_337 = a_73[u32(3)];
let l_338 = l_337 << u32(16);
let l_339 = a_73[u32(2)];
let l_340 = l_338 | l_339;
let l_341 = l_340 / u32(10000);
let l_342 = l_341 * u32(10000);
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
let l_351 = l_350 / u32(10000);
let l_352 = l_351 * u32(10000);
let l_353 = l_350 - l_352;
l_mut_354 = l_353;
let l_355 = l_351 >> u32(16);
a_74[u32(3)] = l_355;
let l_356 = l_351 & u32(65535);
a_74[u32(2)] = l_356;
let l_357 = l_mut_344 << u32(16);
let l_358 = a_73[u32(1)];
let l_359 = l_357 | l_358;
let l_360 = l_359 / u32(10000);
let l_361 = l_360 * u32(10000);
let l_362 = l_359 - l_361;
l_mut_344 = l_362;
a_73[u32(1)] = l_360;
let l_363 = l_mut_354 << u32(16);
let l_364 = a_74[u32(1)];
let l_365 = l_363 | l_364;
let l_366 = l_365 / u32(10000);
let l_367 = l_366 * u32(10000);
let l_368 = l_365 - l_367;
l_mut_354 = l_368;
a_74[u32(1)] = l_366;
let l_369 = l_mut_344 << u32(16);
let l_370 = a_73[u32(0)];
let l_371 = l_369 | l_370;
let l_372 = l_371 / u32(10000);
let l_373 = l_372 * u32(10000);
let l_374 = l_371 - l_373;
l_mut_344 = l_374;
a_73[u32(0)] = l_372;
let l_375 = l_mut_354 << u32(16);
let l_376 = a_74[u32(0)];
let l_377 = l_375 | l_376;
let l_378 = l_377 / u32(10000);
let l_379 = l_378 * u32(10000);
let l_380 = l_377 - l_379;
l_mut_354 = l_380;
a_74[u32(0)] = l_378;
let l_381 = l_mut_344 % u32(10);
l_mut_344 = l_mut_344 / u32(10);
let l_382 = l_mut_354 % u32(10);
l_mut_354 = l_mut_354 / u32(10);
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
let l_389 = l_mut_344 % u32(10);
l_mut_344 = l_mut_344 / u32(10);
let l_390 = l_mut_354 % u32(10);
l_mut_354 = l_mut_354 / u32(10);
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
let l_397 = l_mut_344 % u32(10);
l_mut_344 = l_mut_344 / u32(10);
let l_398 = l_mut_354 % u32(10);
l_mut_354 = l_mut_354 / u32(10);
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
let l_405 = l_mut_344 % u32(10);
l_mut_344 = l_mut_344 / u32(10);
let l_406 = l_mut_354 % u32(10);
l_mut_354 = l_mut_354 / u32(10);
let l_407 = u32(3) >= l_mut_317;
if l_407 {
let l_408 = l_405 == l_406;
if l_408 {
let l_409 = u64(l_405);
let l_410 = u64(1) << u32(bitcast<u64>(l_409));
let l_411 = l_mut_334 & l_410;
let l_412 = l_411 != u64(0);
if l_412 {
l_mut_45 = u32(1);
}
l_mut_334 = l_mut_334 | l_410;
} else {
l_mut_334 = u64(0);
l_mut_45 = u32(0);
l_mut_335 = l_405;
l_mut_336 = l_406;
}
}
a_270[u32(0)] = l_mut_317;
a_271[u32(0)] = l_mut_45;
a_274[u32(0)] = l_mut_335;
a_274[u32(1)] = l_mut_336;
l_mut_354 = u32(0);
let l_414 = a_141[u32(0)];
let l_415 = a_141[u32(1)];
let l_416 = l_415 << u32(16);
let l_417 = l_414 | l_416;
let l_418 = a_140[u32(0)];
let l_419 = a_140[u32(1)];
let l_420 = l_419 << u32(16);
let l_421 = l_418 | l_420;
let l_422 = l_417 - l_421;
let l_423 = l_422 - l_mut_354;
l_mut_344 = u32(0);
let l_424 = l_417 < l_421;
let l_425 = l_417 == l_421;
let l_426 = l_mut_354 != u32(0);
let l_427 = l_425 && l_426;
let l_428 = l_424 || l_427;
if l_428 {
l_mut_344 = u32(1);
}
a_413[u32(0)] = l_423;
l_mut_354 = l_mut_344;
let l_429 = a_141[u32(2)];
let l_430 = a_141[u32(3)];
let l_431 = l_430 << u32(16);
let l_432 = l_429 | l_431;
let l_433 = a_140[u32(2)];
let l_434 = a_140[u32(3)];
let l_435 = l_434 << u32(16);
let l_436 = l_433 | l_435;
let l_437 = l_432 - l_436;
let l_438 = l_437 - l_mut_354;
l_mut_344 = u32(0);
let l_439 = l_432 < l_436;
let l_440 = l_432 == l_436;
let l_441 = l_mut_354 != u32(0);
let l_442 = l_440 && l_441;
let l_443 = l_439 || l_442;
if l_443 {
l_mut_344 = u32(1);
}
a_413[u32(1)] = l_438;
l_mut_354 = l_mut_344;
let l_444 = a_141[u32(4)];
let l_445 = a_141[u32(5)];
let l_446 = l_445 << u32(16);
let l_447 = l_444 | l_446;
let l_448 = a_140[u32(4)];
let l_449 = a_140[u32(5)];
let l_450 = l_449 << u32(16);
let l_451 = l_448 | l_450;
let l_452 = l_447 - l_451;
let l_453 = l_452 - l_mut_354;
l_mut_344 = u32(0);
let l_454 = l_447 < l_451;
let l_455 = l_447 == l_451;
let l_456 = l_mut_354 != u32(0);
let l_457 = l_455 && l_456;
let l_458 = l_454 || l_457;
if l_458 {
l_mut_344 = u32(1);
}
a_413[u32(2)] = l_453;
l_mut_354 = l_mut_344;
l_mut_344 = u32(0);
l_mut_336 = u32(6);
loop {
let l_459 = l_mut_344 < l_mut_336;
let l_460 = !l_459;
if l_460 {
break;
}
let l_461 = l_mut_344 + l_mut_336;
let l_462 = l_461 >> u32(1);
l_mut_313 = bool(false);
l_mut_312 = bool(true);
let l_463 = l_462 * u32(3);
let l_464 = l_463 + u32(2);
let l_465 = buffer_3_global[l_464];
l_mut_335 = u32(0);
let l_466 = a_413[u32(2)];
l_mut_335 = l_466;
if l_mut_312 {
let l_467 = l_mut_335 < l_465;
if l_467 {
l_mut_313 = bool(true);
l_mut_312 = bool(false);
} else {
let l_468 = l_mut_335 > l_465;
if l_468 {
l_mut_312 = bool(false);
}
}
}
let l_469 = l_462 * u32(3);
let l_470 = l_469 + u32(1);
let l_471 = buffer_3_global[l_470];
l_mut_335 = u32(0);
let l_472 = a_413[u32(1)];
l_mut_335 = l_472;
if l_mut_312 {
let l_473 = l_mut_335 < l_471;
if l_473 {
l_mut_313 = bool(true);
l_mut_312 = bool(false);
} else {
let l_474 = l_mut_335 > l_471;
if l_474 {
l_mut_312 = bool(false);
}
}
}
let l_475 = l_462 * u32(3);
let l_476 = l_475 + u32(0);
let l_477 = buffer_3_global[l_476];
l_mut_335 = u32(0);
let l_478 = a_413[u32(0)];
l_mut_335 = l_478;
if l_mut_312 {
let l_479 = l_mut_335 < l_477;
if l_479 {
l_mut_313 = bool(true);
l_mut_312 = bool(false);
} else {
let l_480 = l_mut_335 > l_477;
if l_480 {
l_mut_312 = bool(false);
}
}
}
if l_mut_313 {
l_mut_336 = l_462;
} else {
let l_481 = l_462 + u32(1);
l_mut_344 = l_481;
}
}
l_mut_335 = l_mut_344;
let l_482 = l_mut_335 < u32(1);
if l_482 {
l_mut_335 = u32(1);
}
l_mut_483 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = u32(1);
l_mut_307 = u32(0);
let l_484 = a_140[u32(5)];
let l_485 = l_484 << u32(16);
let l_486 = a_140[u32(4)];
let l_487 = l_485 | l_486;
let l_488 = l_487 / u32(10000);
let l_489 = l_488 * u32(10000);
let l_490 = l_487 - l_489;
l_mut_75 = l_490;
let l_491 = l_488 >> u32(16);
a_140[u32(5)] = l_491;
let l_492 = l_488 & u32(65535);
a_140[u32(4)] = l_492;
let l_493 = a_141[u32(5)];
let l_494 = l_493 << u32(16);
let l_495 = a_141[u32(4)];
let l_496 = l_494 | l_495;
let l_497 = l_496 / u32(10000);
let l_498 = l_497 * u32(10000);
let l_499 = l_496 - l_498;
l_mut_45 = l_499;
let l_500 = l_497 >> u32(16);
a_141[u32(5)] = l_500;
let l_501 = l_497 & u32(65535);
a_141[u32(4)] = l_501;
let l_502 = l_mut_75 << u32(16);
let l_503 = a_140[u32(3)];
let l_504 = l_502 | l_503;
let l_505 = l_504 / u32(10000);
let l_506 = l_505 * u32(10000);
let l_507 = l_504 - l_506;
l_mut_75 = l_507;
a_140[u32(3)] = l_505;
let l_508 = l_mut_45 << u32(16);
let l_509 = a_141[u32(3)];
let l_510 = l_508 | l_509;
let l_511 = l_510 / u32(10000);
let l_512 = l_511 * u32(10000);
let l_513 = l_510 - l_512;
l_mut_45 = l_513;
a_141[u32(3)] = l_511;
let l_514 = l_mut_75 << u32(16);
let l_515 = a_140[u32(2)];
let l_516 = l_514 | l_515;
let l_517 = l_516 / u32(10000);
let l_518 = l_517 * u32(10000);
let l_519 = l_516 - l_518;
l_mut_75 = l_519;
a_140[u32(2)] = l_517;
let l_520 = l_mut_45 << u32(16);
let l_521 = a_141[u32(2)];
let l_522 = l_520 | l_521;
let l_523 = l_522 / u32(10000);
let l_524 = l_523 * u32(10000);
let l_525 = l_522 - l_524;
l_mut_45 = l_525;
a_141[u32(2)] = l_523;
let l_526 = l_mut_75 << u32(16);
let l_527 = a_140[u32(1)];
let l_528 = l_526 | l_527;
let l_529 = l_528 / u32(10000);
let l_530 = l_529 * u32(10000);
let l_531 = l_528 - l_530;
l_mut_75 = l_531;
a_140[u32(1)] = l_529;
let l_532 = l_mut_45 << u32(16);
let l_533 = a_141[u32(1)];
let l_534 = l_532 | l_533;
let l_535 = l_534 / u32(10000);
let l_536 = l_535 * u32(10000);
let l_537 = l_534 - l_536;
l_mut_45 = l_537;
a_141[u32(1)] = l_535;
let l_538 = l_mut_75 << u32(16);
let l_539 = a_140[u32(0)];
let l_540 = l_538 | l_539;
let l_541 = l_540 / u32(10000);
let l_542 = l_541 * u32(10000);
let l_543 = l_540 - l_542;
l_mut_75 = l_543;
a_140[u32(0)] = l_541;
let l_544 = l_mut_45 << u32(16);
let l_545 = a_141[u32(0)];
let l_546 = l_544 | l_545;
let l_547 = l_546 / u32(10000);
let l_548 = l_547 * u32(10000);
let l_549 = l_546 - l_548;
l_mut_45 = l_549;
a_141[u32(0)] = l_547;
let l_550 = l_mut_75 % u32(10);
l_mut_75 = l_mut_75 / u32(10);
let l_551 = l_mut_45 % u32(10);
l_mut_45 = l_mut_45 / u32(10);
let l_552 = u32(0) >= l_mut_335;
if l_552 {
let l_553 = l_550 == l_551;
if l_553 {
let l_554 = u64(l_550);
let l_555 = u64(1) << u32(bitcast<u64>(l_554));
let l_556 = l_mut_483 & l_555;
let l_557 = l_556 != u64(0);
if l_557 {
l_mut_344 = u32(1);
}
l_mut_483 = l_mut_483 | l_555;
} else {
l_mut_483 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_550;
l_mut_307 = l_551;
}
}
let l_558 = l_mut_75 % u32(10);
l_mut_75 = l_mut_75 / u32(10);
let l_559 = l_mut_45 % u32(10);
l_mut_45 = l_mut_45 / u32(10);
let l_560 = u32(1) >= l_mut_335;
if l_560 {
let l_561 = l_558 == l_559;
if l_561 {
let l_562 = u64(l_558);
let l_563 = u64(1) << u32(bitcast<u64>(l_562));
let l_564 = l_mut_483 & l_563;
let l_565 = l_564 != u64(0);
if l_565 {
l_mut_344 = u32(1);
}
l_mut_483 = l_mut_483 | l_563;
} else {
l_mut_483 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_558;
l_mut_307 = l_559;
}
}
let l_566 = l_mut_75 % u32(10);
l_mut_75 = l_mut_75 / u32(10);
let l_567 = l_mut_45 % u32(10);
l_mut_45 = l_mut_45 / u32(10);
let l_568 = u32(2) >= l_mut_335;
if l_568 {
let l_569 = l_566 == l_567;
if l_569 {
let l_570 = u64(l_566);
let l_571 = u64(1) << u32(bitcast<u64>(l_570));
let l_572 = l_mut_483 & l_571;
let l_573 = l_572 != u64(0);
if l_573 {
l_mut_344 = u32(1);
}
l_mut_483 = l_mut_483 | l_571;
} else {
l_mut_483 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_566;
l_mut_307 = l_567;
}
}
let l_574 = l_mut_75 % u32(10);
l_mut_75 = l_mut_75 / u32(10);
let l_575 = l_mut_45 % u32(10);
l_mut_45 = l_mut_45 / u32(10);
let l_576 = u32(3) >= l_mut_335;
if l_576 {
let l_577 = l_574 == l_575;
if l_577 {
let l_578 = u64(l_574);
let l_579 = u64(1) << u32(bitcast<u64>(l_578));
let l_580 = l_mut_483 & l_579;
let l_581 = l_580 != u64(0);
if l_581 {
l_mut_344 = u32(1);
}
l_mut_483 = l_mut_483 | l_579;
} else {
l_mut_483 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_574;
l_mut_307 = l_575;
}
}
let l_582 = a_140[u32(5)];
let l_583 = l_582 << u32(16);
let l_584 = a_140[u32(4)];
let l_585 = l_583 | l_584;
let l_586 = l_585 / u32(10000);
let l_587 = l_586 * u32(10000);
let l_588 = l_585 - l_587;
l_mut_75 = l_588;
let l_589 = l_586 >> u32(16);
a_140[u32(5)] = l_589;
let l_590 = l_586 & u32(65535);
a_140[u32(4)] = l_590;
let l_591 = a_141[u32(5)];
let l_592 = l_591 << u32(16);
let l_593 = a_141[u32(4)];
let l_594 = l_592 | l_593;
let l_595 = l_594 / u32(10000);
let l_596 = l_595 * u32(10000);
let l_597 = l_594 - l_596;
l_mut_45 = l_597;
let l_598 = l_595 >> u32(16);
a_141[u32(5)] = l_598;
let l_599 = l_595 & u32(65535);
a_141[u32(4)] = l_599;
let l_600 = l_mut_75 << u32(16);
let l_601 = a_140[u32(3)];
let l_602 = l_600 | l_601;
let l_603 = l_602 / u32(10000);
let l_604 = l_603 * u32(10000);
let l_605 = l_602 - l_604;
l_mut_75 = l_605;
a_140[u32(3)] = l_603;
let l_606 = l_mut_45 << u32(16);
let l_607 = a_141[u32(3)];
let l_608 = l_606 | l_607;
let l_609 = l_608 / u32(10000);
let l_610 = l_609 * u32(10000);
let l_611 = l_608 - l_610;
l_mut_45 = l_611;
a_141[u32(3)] = l_609;
let l_612 = l_mut_75 << u32(16);
let l_613 = a_140[u32(2)];
let l_614 = l_612 | l_613;
let l_615 = l_614 / u32(10000);
let l_616 = l_615 * u32(10000);
let l_617 = l_614 - l_616;
l_mut_75 = l_617;
a_140[u32(2)] = l_615;
let l_618 = l_mut_45 << u32(16);
let l_619 = a_141[u32(2)];
let l_620 = l_618 | l_619;
let l_621 = l_620 / u32(10000);
let l_622 = l_621 * u32(10000);
let l_623 = l_620 - l_622;
l_mut_45 = l_623;
a_141[u32(2)] = l_621;
let l_624 = l_mut_75 << u32(16);
let l_625 = a_140[u32(1)];
let l_626 = l_624 | l_625;
let l_627 = l_626 / u32(10000);
let l_628 = l_627 * u32(10000);
let l_629 = l_626 - l_628;
l_mut_75 = l_629;
a_140[u32(1)] = l_627;
let l_630 = l_mut_45 << u32(16);
let l_631 = a_141[u32(1)];
let l_632 = l_630 | l_631;
let l_633 = l_632 / u32(10000);
let l_634 = l_633 * u32(10000);
let l_635 = l_632 - l_634;
l_mut_45 = l_635;
a_141[u32(1)] = l_633;
let l_636 = l_mut_75 << u32(16);
let l_637 = a_140[u32(0)];
let l_638 = l_636 | l_637;
let l_639 = l_638 / u32(10000);
let l_640 = l_639 * u32(10000);
let l_641 = l_638 - l_640;
l_mut_75 = l_641;
a_140[u32(0)] = l_639;
let l_642 = l_mut_45 << u32(16);
let l_643 = a_141[u32(0)];
let l_644 = l_642 | l_643;
let l_645 = l_644 / u32(10000);
let l_646 = l_645 * u32(10000);
let l_647 = l_644 - l_646;
l_mut_45 = l_647;
a_141[u32(0)] = l_645;
let l_648 = l_mut_75 % u32(10);
l_mut_75 = l_mut_75 / u32(10);
let l_649 = l_mut_45 % u32(10);
l_mut_45 = l_mut_45 / u32(10);
let l_650 = u32(4) >= l_mut_335;
if l_650 {
let l_651 = l_648 == l_649;
if l_651 {
let l_652 = u64(l_648);
let l_653 = u64(1) << u32(bitcast<u64>(l_652));
let l_654 = l_mut_483 & l_653;
let l_655 = l_654 != u64(0);
if l_655 {
l_mut_344 = u32(1);
}
l_mut_483 = l_mut_483 | l_653;
} else {
l_mut_483 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_648;
l_mut_307 = l_649;
}
}
let l_656 = l_mut_75 % u32(10);
l_mut_75 = l_mut_75 / u32(10);
let l_657 = l_mut_45 % u32(10);
l_mut_45 = l_mut_45 / u32(10);
let l_658 = u32(5) >= l_mut_335;
if l_658 {
let l_659 = l_656 == l_657;
if l_659 {
let l_660 = u64(l_656);
let l_661 = u64(1) << u32(bitcast<u64>(l_660));
let l_662 = l_mut_483 & l_661;
let l_663 = l_662 != u64(0);
if l_663 {
l_mut_344 = u32(1);
}
l_mut_483 = l_mut_483 | l_661;
} else {
l_mut_483 = u64(0);
l_mut_344 = u32(0);
l_mut_317 = l_656;
l_mut_307 = l_657;
}
}
let l_664 = l_mut_75 % u32(10);
l_mut_75 = l_mut_75 / u32(10);
let l_665 = l_mut_45 % u32(10);
l_mut_45 = l_mut_45 / u32(10);
let l_666 = l_mut_75 % u32(10);
l_mut_75 = l_mut_75 / u32(10);
let l_667 = l_mut_45 % u32(10);
l_mut_45 = l_mut_45 / u32(10);
a_272[u32(0)] = l_mut_335;
a_273[u32(0)] = l_mut_344;
a_275[u32(0)] = l_mut_317;
a_275[u32(1)] = l_mut_307;
let l_668 = l_mut_334 | l_mut_483;
l_mut_669 = l_668;
let l_670 = a_271[u32(0)];
let l_671 = l_670 == u32(0);
let l_672 = a_273[u32(0)];
let l_673 = l_672 == u32(0);
let l_674 = l_671 && l_673;
let l_675 = l_mut_334 & l_mut_483;
let l_676 = l_675 == u64(0);
let l_677 = l_674 && l_676;
l_mut_313 = l_677;
let l_678 = a_274[u32(0)];
let l_679 = a_274[u32(1)];
l_mut_483 = u64(0);
let l_680 = l_679 >= l_678;
if l_680 {
let l_681 = l_679 - l_678;
let l_682 = l_681 + u32(1);
let l_683 = l_682 >= u32(64);
if l_683 {
let l_684 = u64(l_678);
let l_685 = bitcast<u64>(i64(-1)) << u32(bitcast<u64>(l_684));
l_mut_483 = l_685;
} else {
let l_686 = u64(l_682);
let l_687 = u64(1) << u32(bitcast<u64>(l_686));
let l_688 = l_687 - u64(1);
let l_689 = u64(l_678);
let l_690 = l_688 << u32(bitcast<u64>(l_689));
l_mut_483 = l_690;
}
}
let l_691 = a_275[u32(0)];
let l_692 = a_275[u32(1)];
l_mut_334 = u64(0);
let l_693 = l_692 >= l_691;
if l_693 {
let l_694 = l_692 - l_691;
let l_695 = l_694 + u32(1);
let l_696 = l_695 >= u32(64);
if l_696 {
let l_697 = u64(l_691);
let l_698 = bitcast<u64>(i64(-1)) << u32(bitcast<u64>(l_697));
l_mut_334 = l_698;
} else {
let l_699 = u64(l_695);
let l_700 = u64(1) << u32(bitcast<u64>(l_699));
let l_701 = l_700 - u64(1);
let l_702 = u64(l_691);
let l_703 = l_701 << u32(bitcast<u64>(l_702));
l_mut_334 = l_703;
}
}
l_mut_312 = bool(false);
l_mut_704 = bool(false);
let l_705 = l_mut_483 != u64(0);
let l_706 = l_mut_313 && l_705;
if l_706 {
let l_707 = ~l_mut_669;
let l_708 = l_mut_483 & l_707;
let l_709 = l_708 == u64(0);
if l_709 {
l_mut_313 = bool(false);
} else {
let l_710 = l_708 - u64(1);
let l_711 = l_708 & l_710;
let l_712 = l_711 == u64(0);
if l_712 {
l_mut_669 = l_mut_669 | l_708;
l_mut_312 = bool(true);
}
}
}
let l_713 = l_mut_334 != u64(0);
let l_714 = l_mut_313 && l_713;
if l_714 {
let l_715 = ~l_mut_669;
let l_716 = l_mut_334 & l_715;
let l_717 = l_716 == u64(0);
if l_717 {
l_mut_313 = bool(false);
} else {
let l_718 = l_716 - u64(1);
let l_719 = l_716 & l_718;
let l_720 = l_719 == u64(0);
if l_720 {
l_mut_669 = l_mut_669 | l_716;
l_mut_704 = bool(true);
}
}
}
let l_721 = l_mut_483 != u64(0);
let l_722 = l_mut_313 && l_721;
let l_723 = !l_mut_312;
let l_724 = l_722 && l_723;
let l_725 = l_724 && l_mut_704;
if l_725 {
let l_726 = ~l_mut_669;
let l_727 = l_mut_483 & l_726;
let l_728 = l_727 == u64(0);
if l_728 {
l_mut_313 = bool(false);
} else {
let l_729 = l_727 - u64(1);
let l_730 = l_727 & l_729;
let l_731 = l_730 == u64(0);
if l_731 {
l_mut_669 = l_mut_669 | l_727;
}
}
}
if l_mut_313 {
let l_732 = a_270[u32(0)];
l_mut_354 = l_732;
let l_733 = a_272[u32(0)];
let l_734 = l_733 < l_mut_354;
if l_734 {
let l_735 = a_272[u32(0)];
l_mut_354 = l_735;
}
let l_736 = !l_mut_47;
let l_737 = !l_mut_48;
let l_738 = l_736 && l_737;
if l_738 {
l_mut_354 = info.scalars_u32[5];
}
let l_739 = &buffer_10_global[workgroup_id.y];
let l_740 = atomicAdd(l_739, u32(1));let l_741 = workgroup_id.y * info.scalars_u32[0];
let l_742 = l_741 + l_740;
let l_743 = u32(2) * l_742;
let l_744 = u32(bitcast<u64>(l_14));
buffer_5_global[l_743] = l_744;
let l_745 = u32(2) * l_742;
let l_746 = l_745 + u32(1);
let l_747 = l_14 >> u32(bitcast<u64>(u64(32)));
let l_748 = u32(bitcast<u64>(l_747));
buffer_5_global[l_746] = l_748;
let l_749 = u32(2) * l_742;
let l_750 = u32(bitcast<u64>(l_mut_669));
buffer_6_global[l_749] = l_750;
let l_751 = u32(2) * l_742;
let l_752 = l_751 + u32(1);
let l_753 = l_mut_669 >> u32(bitcast<u64>(u64(32)));
let l_754 = u32(bitcast<u64>(l_753));
buffer_6_global[l_752] = l_754;
let l_755 = u32(2) * l_742;
let l_756 = a_39[u32(0)];
let l_757 = l_756 - l_38;
buffer_7_global[l_755] = l_757;
let l_758 = u32(2) * l_742;
let l_759 = l_758 + u32(1);
let l_760 = a_40[u32(0)];
let l_761 = l_760 - l_38;
let l_762 = l_761 + u32(1);
buffer_7_global[l_759] = l_762;
let l_763 = u32(5) * global_id.x;
let l_764 = l_763 + u32(4);
let l_765 = buffer_0_global[l_764];
let l_766 = l_765 * info.scalars_u32[3];
let l_767 = l_766 + l_10;
let l_768 = u32(2) * l_742;
buffer_8_global[l_768] = l_767;
l_mut_344 = u32(0);
let l_769 = l_mut_354 >= u32(3);
if l_769 {
l_mut_344 = u32(1);
}
let l_770 = u32(2) * l_742;
let l_771 = l_770 + u32(1);
buffer_8_global[l_771] = l_mut_344;
let l_772 = u32(5) * global_id.x;
let l_773 = l_772 + u32(2);
let l_774 = buffer_0_global[l_773];
let l_775 = l_774 * info.scalars_u32[4];
let l_776 = l_775 + l_10;
let l_777 = l_776 % u32(9);
l_mut_354 = u32(0);
let l_778 = u32(5) * global_id.x;
let l_779 = l_778 + u32(3);
let l_780 = buffer_0_global[l_779];
l_mut_354 = l_780;
let l_781 = l_mut_354 << u32(8);
let l_782 = l_777 | l_781;
buffer_9_global[l_742] = l_782;
l_mut_344 = u32(0);
loop {
let l_783 = l_mut_344 < info.scalars_u32[1];
let l_784 = !l_783;
if l_784 {
break;
}
let l_785 = buffer_4_global[l_mut_344];
let l_786 = l_785 + u32(9);
let l_787 = l_786 - l_777;
let l_788 = l_787 % u32(9);
let l_789 = workgroup_id.y * u32(90);
let l_790 = l_mut_354 * u32(9);
let l_791 = l_789 + l_790;
let l_792 = l_791 + l_788;
let l_793 = &buffer_11_global[l_792];
let l_794 = atomicAdd(l_793, u32(1));l_mut_344 = l_mut_344 + u32(1);
}
}
}
}
workgroupBarrier();
let l_795 = local_invocation_id.x == u32(0);
if l_795 {
let l_796 = &buffer_12_global[u32(0)];
let l_797 = atomicAdd(l_796, u32(1));}
}
```
