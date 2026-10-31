
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

var<workgroup> shared_memory_17: array<u32, 256>;

var<workgroup> shared_memory_18: array<u32, 256>;

var<workgroup> shared_memory_15: array<u64, 512>;

var<workgroup> shared_memory_16: array<u64, 512>;

var<workgroup> shared_memory_13: array<u32, 1792>;

const WORKGROUP_SIZE_X = 256u;
const WORKGROUP_SIZE_Y = 1u;
const WORKGROUP_SIZE_Z = 1u;

@compute
@workgroup_size(256, 1, 1)
fn niceonly_kernel(
    @builtin(global_invocation_id) global_id: vec3<u32>,
    @builtin(local_invocation_id) local_invocation_id: vec3<u32>,
    @builtin(num_workgroups) num_workgroups: vec3<u32>,
    @builtin(subgroup_size) subgroup_size: u32,
    @builtin(subgroup_invocation_id) subgroup_invocation_id: u32,
) {
var a_168: array<u32, 2>;

var a_173: array<u32, 3>;

var a_252: array<u32, 3>;

var a_301: array<u32, 3>;

var a_400: array<u32, 2>;

var a_405: array<u32, 4>;

var l_mut_22: u32;
var l_mut_31: u32;
var l_mut_32: u32;
var l_mut_58: u32;
var l_mut_105: u32;
var l_mut_151: u32;
var l_mut_152: u32;
var l_mut_355: u32;
var l_mut_26: u64;
var l_mut_27: u64;
var l_mut_28: u64;
var l_mut_29: u64;
var l_mut_30: u64;
var l_mut_52: u64;
var l_mut_114: u64;
var l_mut_125: u64;
var l_mut_24: bool;
var l_mut_25: bool;
var l_mut_133: bool;
var l_mut_167: bool;
var l_mut_460: i32;
var l_mut_470: i32;
var l_mut_653: i32;
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
let l_14 = local_invocation_id.x * u32(7);
let l_19 = local_invocation_id.x / subgroup_size;
let l_20 = WORKGROUP_SIZE_X / subgroup_size;
let l_21 = global_id.x >> info.scalars_u32[7];
l_mut_22 = l_21;
let l_23 = l_mut_22 < info.scalars_u32[5];
l_mut_24 = l_23;
l_mut_25 = l_mut_24;
l_mut_26 = u64(0);
l_mut_27 = u64(0);
l_mut_28 = u64(0);
l_mut_29 = u64(0);
l_mut_30 = u64(0);
l_mut_31 = u32(0);
l_mut_32 = u32(0);
loop {
if l_mut_25 {
l_mut_25 = bool(false);
let l_33 = u32(2) * l_mut_22;
let l_34 = buffer_1_global[l_33];
let l_35 = u32(2) * l_mut_22;
let l_36 = l_35 + u32(1);
let l_37 = buffer_1_global[l_36];
let l_38 = u64(l_37);
let l_39 = l_38 << u32(bitcast<u64>(u64(32)));
let l_40 = u64(l_34);
let l_41 = l_39 | l_40;
l_mut_26 = u64(0);
let l_42 = u32(2) * l_mut_22;
let l_43 = l_42 + u32(1);
let l_44 = buffer_6_global[l_43];
let l_45 = u64(l_44);
let l_46 = l_45 << u32(bitcast<u64>(u64(32)));
let l_47 = u32(2) * l_mut_22;
let l_48 = buffer_6_global[l_47];
let l_49 = u64(l_48);
let l_50 = l_46 | l_49;
l_mut_26 = l_50;
let l_51 = l_8 + l_41;
l_mut_52 = l_12;
let l_53 = l_51 < l_8;
if l_53 {
l_mut_52 = l_mut_52 + u64(1);
}
let l_54 = buffer_2_global[l_mut_22];
let l_55 = u64(l_54);
let l_56 = l_51 + l_55;
l_mut_27 = l_56;
l_mut_28 = l_mut_52;
let l_57 = l_mut_27 < l_51;
if l_57 {
l_mut_28 = l_mut_28 + u64(1);
}
l_mut_58 = u32(0);
let l_59 = l_mut_58 << u32(8);
let l_60 = l_37 >> u32(24);
let l_61 = l_60 & u32(255);
let l_62 = l_59 | l_61;
let l_63 = l_62 % u32(2496000);
l_mut_58 = l_63;
let l_64 = l_mut_58 << u32(8);
let l_65 = l_37 >> u32(16);
let l_66 = l_65 & u32(255);
let l_67 = l_64 | l_66;
let l_68 = l_67 % u32(2496000);
l_mut_58 = l_68;
let l_69 = l_mut_58 << u32(8);
let l_70 = l_37 >> u32(8);
let l_71 = l_70 & u32(255);
let l_72 = l_69 | l_71;
let l_73 = l_72 % u32(2496000);
l_mut_58 = l_73;
let l_74 = l_mut_58 << u32(8);
let l_75 = l_37 >> u32(0);
let l_76 = l_75 & u32(255);
let l_77 = l_74 | l_76;
let l_78 = l_77 % u32(2496000);
l_mut_58 = l_78;
let l_79 = l_mut_58 << u32(8);
let l_80 = l_34 >> u32(24);
let l_81 = l_80 & u32(255);
let l_82 = l_79 | l_81;
let l_83 = l_82 % u32(2496000);
l_mut_58 = l_83;
let l_84 = l_mut_58 << u32(8);
let l_85 = l_34 >> u32(16);
let l_86 = l_85 & u32(255);
let l_87 = l_84 | l_86;
let l_88 = l_87 % u32(2496000);
l_mut_58 = l_88;
let l_89 = l_mut_58 << u32(8);
let l_90 = l_34 >> u32(8);
let l_91 = l_90 & u32(255);
let l_92 = l_89 | l_91;
let l_93 = l_92 % u32(2496000);
l_mut_58 = l_93;
let l_94 = l_mut_58 << u32(8);
let l_95 = l_34 >> u32(0);
let l_96 = l_95 & u32(255);
let l_97 = l_94 | l_96;
let l_98 = l_97 % u32(2496000);
l_mut_58 = l_98;
let l_99 = info.scalars_u32[4] + l_mut_58;
let l_100 = l_99 % u32(2496000);
let l_101 = u64(l_100);
let l_102 = l_51 - l_101;
l_mut_29 = l_102;
l_mut_30 = l_mut_52;
let l_103 = u64(l_100);
let l_104 = l_51 < l_103;
if l_104 {
l_mut_30 = l_mut_30 - u64(1);
}
l_mut_58 = u32(0);
l_mut_105 = u32(144064);
loop {
let l_106 = l_mut_58 < l_mut_105;
let l_107 = !l_106;
if l_107 {
break;
}
let l_108 = l_mut_58 + l_mut_105;
let l_109 = l_108 >> u32(1);
let l_110 = buffer_0_global[l_109];
let l_111 = l_110 < l_100;
if l_111 {
let l_112 = l_109 + u32(1);
l_mut_58 = l_112;
} else {
l_mut_105 = l_109;
}
}
let l_113 = l_mut_58 + l_2;
l_mut_31 = l_113;
}
l_mut_105 = u32(0);
l_mut_52 = u64(0);
l_mut_114 = u64(0);
if l_mut_24 {
let l_115 = l_mut_31 / u32(144064);
let l_116 = l_115 * u32(144064);
let l_117 = l_mut_31 - l_116;
let l_118 = u64(l_115);
let l_119 = u64(u32(2496000));
let l_120 = l_118 * l_119;
let l_121 = buffer_0_global[l_117];
let l_122 = u64(l_121);
let l_123 = l_120 + l_122;
let l_124 = l_mut_29 + l_123;
l_mut_125 = l_mut_30;
let l_126 = l_124 < l_mut_29;
if l_126 {
l_mut_125 = l_mut_125 + u64(1);
}
let l_127 = l_mut_125 > l_mut_28;
let l_128 = l_mut_125 == l_mut_28;
let l_129 = l_124 >= l_mut_27;
let l_130 = l_128 && l_129;
let l_131 = l_127 || l_130;
if l_131 {
l_mut_22 = l_mut_22 + l_4;
let l_132 = l_mut_22 < info.scalars_u32[5];
if l_132 {
l_mut_25 = bool(true);
} else {
l_mut_24 = bool(false);
}
} else {
l_mut_133 = bool(false);
let l_134 = u32(2) * l_117;
let l_135 = l_134 + u32(1);
let l_136 = buffer_5_global[l_135];
let l_137 = u64(l_136);
let l_138 = l_137 << u32(bitcast<u64>(u64(32)));
let l_139 = u32(2) * l_117;
let l_140 = buffer_5_global[l_139];
let l_141 = u64(l_140);
let l_142 = l_138 | l_141;
let l_143 = l_142 & l_mut_26;
let l_144 = l_143 != u64(0);
if l_144 {
l_mut_133 = bool(true);
}
let l_145 = !l_mut_133;
if l_145 {
l_mut_105 = u32(1);
l_mut_52 = l_124;
l_mut_114 = l_mut_125;
}
l_mut_31 = l_mut_31 + l_0;
}
}
let l_146 = subgroupExclusiveAdd(l_mut_105);
let l_147 = subgroupAdd(l_mut_105);
let l_148 = !l_mut_24;
let l_149 = subgroupAll(l_148);
let l_150 = subgroup_invocation_id == u32(0);
if l_150 {
shared_memory_17[l_19] = l_147;
l_mut_58 = u32(0);
if l_149 {
l_mut_58 = u32(1);
}
shared_memory_18[l_19] = l_mut_58;
}
workgroupBarrier();
l_mut_58 = l_mut_32;
l_mut_151 = u32(0);
l_mut_133 = bool(true);
l_mut_152 = u32(0);
loop {
let l_153 = l_mut_152 < l_20;
let l_154 = !l_153;
if l_154 {
break;
}
let l_155 = shared_memory_17[l_mut_152];
let l_156 = l_mut_152 < l_19;
if l_156 {
l_mut_58 = l_mut_58 + l_155;
}
l_mut_151 = l_mut_151 + l_155;
let l_157 = shared_memory_18[l_mut_152];
let l_158 = l_157 == u32(0);
if l_158 {
l_mut_133 = bool(false);
}
l_mut_152 = l_mut_152 + u32(1);
}
let l_159 = l_mut_105 != u32(0);
if l_159 {
let l_160 = l_mut_58 + l_146;
shared_memory_15[l_160] = l_mut_52;
shared_memory_16[l_160] = l_mut_114;
}
l_mut_32 = l_mut_32 + l_mut_151;
workgroupBarrier();
l_mut_151 = u32(0);
let l_161 = l_mut_32 >= WORKGROUP_SIZE_X;
if l_161 {
l_mut_151 = WORKGROUP_SIZE_X;
} else {
if l_mut_133 {
l_mut_151 = l_mut_32;
}
}
let l_162 = local_invocation_id.x < l_mut_151;
if l_162 {
let l_163 = l_mut_32 - l_mut_151;
let l_164 = l_163 + local_invocation_id.x;
let l_165 = shared_memory_15[l_164];
let l_166 = shared_memory_16[l_164];
l_mut_167 = bool(true);
if l_mut_167 {
let l_169 = l_165 >> u32(bitcast<u64>(u64(0)));
let l_170 = u32(bitcast<u64>(l_169));
a_168[u32(0)] = l_170;
let l_171 = l_165 >> u32(bitcast<u64>(u64(32)));
let l_172 = u32(bitcast<u64>(l_171));
a_168[u32(1)] = l_172;
l_mut_105 = u32(0);
let l_174 = a_168[u32(1)];
let l_175 = l_mut_105 << u32(16);
let l_176 = l_174 >> u32(16);
let l_177 = l_175 | l_176;
let l_178 = l_177 / u32(64000);
let l_179 = l_177 % u32(64000);
let l_180 = l_179 << u32(16);
let l_181 = l_174 & u32(65535);
let l_182 = l_180 | l_181;
let l_183 = l_182 % u32(64000);
l_mut_105 = l_183;
let l_184 = l_178 << u32(16);
let l_185 = l_182 / u32(64000);
let l_186 = l_184 | l_185;
a_168[u32(1)] = l_186;
let l_187 = a_168[u32(0)];
let l_188 = l_mut_105 << u32(16);
let l_189 = l_187 >> u32(16);
let l_190 = l_188 | l_189;
let l_191 = l_190 / u32(64000);
let l_192 = l_190 % u32(64000);
let l_193 = l_192 << u32(16);
let l_194 = l_187 & u32(65535);
let l_195 = l_193 | l_194;
let l_196 = l_195 % u32(64000);
l_mut_105 = l_196;
let l_197 = l_191 << u32(16);
let l_198 = l_195 / u32(64000);
let l_199 = l_197 | l_198;
a_168[u32(0)] = l_199;
a_173[u32(0)] = l_mut_105;
l_mut_105 = u32(0);
let l_200 = a_168[u32(1)];
let l_201 = l_mut_105 << u32(16);
let l_202 = l_200 >> u32(16);
let l_203 = l_201 | l_202;
let l_204 = l_203 / u32(64000);
let l_205 = l_203 % u32(64000);
let l_206 = l_205 << u32(16);
let l_207 = l_200 & u32(65535);
let l_208 = l_206 | l_207;
let l_209 = l_208 % u32(64000);
l_mut_105 = l_209;
let l_210 = l_204 << u32(16);
let l_211 = l_208 / u32(64000);
let l_212 = l_210 | l_211;
a_168[u32(1)] = l_212;
let l_213 = a_168[u32(0)];
let l_214 = l_mut_105 << u32(16);
let l_215 = l_213 >> u32(16);
let l_216 = l_214 | l_215;
let l_217 = l_216 / u32(64000);
let l_218 = l_216 % u32(64000);
let l_219 = l_218 << u32(16);
let l_220 = l_213 & u32(65535);
let l_221 = l_219 | l_220;
let l_222 = l_221 % u32(64000);
l_mut_105 = l_222;
let l_223 = l_217 << u32(16);
let l_224 = l_221 / u32(64000);
let l_225 = l_223 | l_224;
a_168[u32(0)] = l_225;
a_173[u32(1)] = l_mut_105;
l_mut_105 = u32(0);
let l_226 = a_168[u32(1)];
let l_227 = l_mut_105 << u32(16);
let l_228 = l_226 >> u32(16);
let l_229 = l_227 | l_228;
let l_230 = l_229 / u32(64000);
let l_231 = l_229 % u32(64000);
let l_232 = l_231 << u32(16);
let l_233 = l_226 & u32(65535);
let l_234 = l_232 | l_233;
let l_235 = l_234 % u32(64000);
l_mut_105 = l_235;
let l_236 = l_230 << u32(16);
let l_237 = l_234 / u32(64000);
let l_238 = l_236 | l_237;
a_168[u32(1)] = l_238;
let l_239 = a_168[u32(0)];
let l_240 = l_mut_105 << u32(16);
let l_241 = l_239 >> u32(16);
let l_242 = l_240 | l_241;
let l_243 = l_242 / u32(64000);
let l_244 = l_242 % u32(64000);
let l_245 = l_244 << u32(16);
let l_246 = l_239 & u32(65535);
let l_247 = l_245 | l_246;
let l_248 = l_247 % u32(64000);
l_mut_105 = l_248;
let l_249 = l_243 << u32(16);
let l_250 = l_247 / u32(64000);
let l_251 = l_249 | l_250;
a_168[u32(0)] = l_251;
a_173[u32(2)] = l_mut_105;
a_252[u32(0)] = u32(0);
a_252[u32(1)] = u32(0);
a_252[u32(2)] = u32(0);
l_mut_105 = u32(0);
let l_253 = a_173[u32(0)];
let l_254 = a_173[u32(0)];
let l_255 = l_253 * l_254;
let l_256 = a_252[u32(0)];
let l_257 = l_255 + l_256;
let l_258 = l_257 + l_mut_105;
let l_259 = l_258 % u32(64000);
a_252[u32(0)] = l_259;
let l_260 = l_258 / u32(64000);
l_mut_105 = l_260;
let l_261 = a_173[u32(0)];
let l_262 = a_173[u32(1)];
let l_263 = l_261 * l_262;
let l_264 = a_252[u32(1)];
let l_265 = l_263 + l_264;
let l_266 = l_265 + l_mut_105;
let l_267 = l_266 % u32(64000);
a_252[u32(1)] = l_267;
let l_268 = l_266 / u32(64000);
l_mut_105 = l_268;
let l_269 = a_173[u32(0)];
let l_270 = a_173[u32(2)];
let l_271 = l_269 * l_270;
let l_272 = a_252[u32(2)];
let l_273 = l_271 + l_272;
let l_274 = l_273 + l_mut_105;
let l_275 = l_274 % u32(64000);
a_252[u32(2)] = l_275;
let l_276 = l_274 / u32(64000);
l_mut_105 = l_276;
l_mut_105 = u32(0);
let l_277 = a_173[u32(1)];
let l_278 = a_173[u32(0)];
let l_279 = l_277 * l_278;
let l_280 = a_252[u32(1)];
let l_281 = l_279 + l_280;
let l_282 = l_281 + l_mut_105;
let l_283 = l_282 % u32(64000);
a_252[u32(1)] = l_283;
let l_284 = l_282 / u32(64000);
l_mut_105 = l_284;
let l_285 = a_173[u32(1)];
let l_286 = a_173[u32(1)];
let l_287 = l_285 * l_286;
let l_288 = a_252[u32(2)];
let l_289 = l_287 + l_288;
let l_290 = l_289 + l_mut_105;
let l_291 = l_290 % u32(64000);
a_252[u32(2)] = l_291;
let l_292 = l_290 / u32(64000);
l_mut_105 = l_292;
l_mut_105 = u32(0);
let l_293 = a_173[u32(2)];
let l_294 = a_173[u32(0)];
let l_295 = l_293 * l_294;
let l_296 = a_252[u32(2)];
let l_297 = l_295 + l_296;
let l_298 = l_297 + l_mut_105;
let l_299 = l_298 % u32(64000);
a_252[u32(2)] = l_299;
let l_300 = l_298 / u32(64000);
l_mut_105 = l_300;
a_301[u32(0)] = u32(0);
a_301[u32(1)] = u32(0);
a_301[u32(2)] = u32(0);
l_mut_105 = u32(0);
let l_302 = a_252[u32(0)];
let l_303 = a_173[u32(0)];
let l_304 = l_302 * l_303;
let l_305 = a_301[u32(0)];
let l_306 = l_304 + l_305;
let l_307 = l_306 + l_mut_105;
let l_308 = l_307 % u32(64000);
a_301[u32(0)] = l_308;
let l_309 = l_307 / u32(64000);
l_mut_105 = l_309;
let l_310 = a_252[u32(0)];
let l_311 = a_173[u32(1)];
let l_312 = l_310 * l_311;
let l_313 = a_301[u32(1)];
let l_314 = l_312 + l_313;
let l_315 = l_314 + l_mut_105;
let l_316 = l_315 % u32(64000);
a_301[u32(1)] = l_316;
let l_317 = l_315 / u32(64000);
l_mut_105 = l_317;
let l_318 = a_252[u32(0)];
let l_319 = a_173[u32(2)];
let l_320 = l_318 * l_319;
let l_321 = a_301[u32(2)];
let l_322 = l_320 + l_321;
let l_323 = l_322 + l_mut_105;
let l_324 = l_323 % u32(64000);
a_301[u32(2)] = l_324;
let l_325 = l_323 / u32(64000);
l_mut_105 = l_325;
l_mut_105 = u32(0);
let l_326 = a_252[u32(1)];
let l_327 = a_173[u32(0)];
let l_328 = l_326 * l_327;
let l_329 = a_301[u32(1)];
let l_330 = l_328 + l_329;
let l_331 = l_330 + l_mut_105;
let l_332 = l_331 % u32(64000);
a_301[u32(1)] = l_332;
let l_333 = l_331 / u32(64000);
l_mut_105 = l_333;
let l_334 = a_252[u32(1)];
let l_335 = a_173[u32(1)];
let l_336 = l_334 * l_335;
let l_337 = a_301[u32(2)];
let l_338 = l_336 + l_337;
let l_339 = l_338 + l_mut_105;
let l_340 = l_339 % u32(64000);
a_301[u32(2)] = l_340;
let l_341 = l_339 / u32(64000);
l_mut_105 = l_341;
l_mut_105 = u32(0);
let l_342 = a_252[u32(2)];
let l_343 = a_173[u32(0)];
let l_344 = l_342 * l_343;
let l_345 = a_301[u32(2)];
let l_346 = l_344 + l_345;
let l_347 = l_346 + l_mut_105;
let l_348 = l_347 % u32(64000);
a_301[u32(2)] = l_348;
let l_349 = l_347 / u32(64000);
l_mut_105 = l_349;
l_mut_125 = u64(0);
l_mut_114 = u64(0);
l_mut_52 = u64(0);
l_mut_105 = u32(0);
loop {
let l_350 = l_mut_105 < u32(2);
let l_351 = !l_350;
if l_351 {
break;
}
let l_352 = l_mut_105 == u32(0);
if l_352 {
let l_353 = a_252[u32(0)];
l_mut_58 = l_353;
} else {
let l_354 = a_301[u32(0)];
l_mut_58 = l_354;
}
l_mut_355 = l_mut_58;
let l_356 = l_mut_355 % u32(40);
l_mut_355 = l_mut_355 / u32(40);
let l_357 = u64(l_356);
let l_358 = u64(1) << u32(bitcast<u64>(l_357));
let l_359 = l_mut_125 & l_358;
l_mut_52 = l_mut_52 | l_359;
l_mut_125 = l_mut_125 | l_358;
let l_360 = l_mut_355 % u32(40);
l_mut_355 = l_mut_355 / u32(40);
let l_361 = u64(l_360);
let l_362 = u64(1) << u32(bitcast<u64>(l_361));
let l_363 = l_mut_125 & l_362;
l_mut_52 = l_mut_52 | l_363;
l_mut_125 = l_mut_125 | l_362;
let l_364 = l_mut_355 % u32(40);
l_mut_355 = l_mut_355 / u32(40);
let l_365 = u64(l_364);
let l_366 = u64(1) << u32(bitcast<u64>(l_365));
let l_367 = l_mut_125 & l_366;
l_mut_52 = l_mut_52 | l_367;
l_mut_125 = l_mut_125 | l_366;
let l_368 = l_mut_105 == u32(0);
if l_368 {
let l_369 = a_252[u32(1)];
l_mut_355 = l_369;
} else {
let l_370 = a_301[u32(1)];
l_mut_355 = l_370;
}
l_mut_58 = l_mut_355;
let l_371 = l_mut_58 % u32(40);
l_mut_58 = l_mut_58 / u32(40);
let l_372 = u64(l_371);
let l_373 = u64(1) << u32(bitcast<u64>(l_372));
let l_374 = l_mut_125 & l_373;
l_mut_52 = l_mut_52 | l_374;
l_mut_125 = l_mut_125 | l_373;
let l_375 = l_mut_58 % u32(40);
l_mut_58 = l_mut_58 / u32(40);
let l_376 = u64(l_375);
let l_377 = u64(1) << u32(bitcast<u64>(l_376));
let l_378 = l_mut_125 & l_377;
l_mut_52 = l_mut_52 | l_378;
l_mut_125 = l_mut_125 | l_377;
let l_379 = l_mut_58 % u32(40);
l_mut_58 = l_mut_58 / u32(40);
let l_380 = u64(l_379);
let l_381 = u64(1) << u32(bitcast<u64>(l_380));
let l_382 = l_mut_125 & l_381;
l_mut_52 = l_mut_52 | l_382;
l_mut_125 = l_mut_125 | l_381;
let l_383 = l_mut_105 == u32(0);
if l_383 {
let l_384 = a_252[u32(2)];
l_mut_355 = l_384;
} else {
let l_385 = a_301[u32(2)];
l_mut_355 = l_385;
}
l_mut_58 = l_mut_355;
let l_386 = l_mut_58 % u32(40);
l_mut_58 = l_mut_58 / u32(40);
let l_387 = u64(l_386);
let l_388 = u64(1) << u32(bitcast<u64>(l_387));
let l_389 = l_mut_125 & l_388;
l_mut_52 = l_mut_52 | l_389;
l_mut_125 = l_mut_125 | l_388;
let l_390 = l_mut_58 % u32(40);
l_mut_58 = l_mut_58 / u32(40);
let l_391 = u64(l_390);
let l_392 = u64(1) << u32(bitcast<u64>(l_391));
let l_393 = l_mut_125 & l_392;
l_mut_52 = l_mut_52 | l_393;
l_mut_125 = l_mut_125 | l_392;
let l_394 = l_mut_58 % u32(40);
l_mut_58 = l_mut_58 / u32(40);
let l_395 = u64(l_394);
let l_396 = u64(1) << u32(bitcast<u64>(l_395));
let l_397 = l_mut_125 & l_396;
l_mut_52 = l_mut_52 | l_397;
l_mut_125 = l_mut_125 | l_396;
l_mut_105 = l_mut_105 + u32(1);
}
let l_398 = l_mut_52 != u64(0);
if l_398 {
l_mut_167 = bool(false);
}
}
l_mut_125 = u64(0);
l_mut_114 = u64(0);
let l_399 = l_mut_167 && bool(false);
if l_399 {
let l_401 = l_165 >> u32(bitcast<u64>(u64(0)));
let l_402 = u32(bitcast<u64>(l_401));
a_400[u32(0)] = l_402;
let l_403 = l_165 >> u32(bitcast<u64>(u64(32)));
let l_404 = u32(bitcast<u64>(l_403));
a_400[u32(1)] = l_404;
a_405[u32(0)] = u32(0);
a_405[u32(1)] = u32(0);
a_405[u32(2)] = u32(0);
a_405[u32(3)] = u32(0);
l_mut_52 = u64(0);
let l_406 = a_400[u32(0)];
let l_407 = u64(l_406);
let l_408 = a_400[u32(0)];
let l_409 = u64(l_408);
let l_410 = l_407 * l_409;
let l_411 = a_405[u32(0)];
let l_412 = u64(l_411);
let l_413 = l_410 + l_412;
let l_414 = l_413 + l_mut_52;
let l_415 = u32(bitcast<u64>(l_414));
a_405[u32(0)] = l_415;
let l_416 = l_414 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_416;
let l_417 = a_400[u32(0)];
let l_418 = u64(l_417);
let l_419 = a_400[u32(1)];
let l_420 = u64(l_419);
let l_421 = l_418 * l_420;
let l_422 = a_405[u32(1)];
let l_423 = u64(l_422);
let l_424 = l_421 + l_423;
let l_425 = l_424 + l_mut_52;
let l_426 = u32(bitcast<u64>(l_425));
a_405[u32(1)] = l_426;
let l_427 = l_425 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_427;
let l_428 = u32(bitcast<u64>(l_mut_52));
a_405[u32(2)] = l_428;
l_mut_52 = u64(0);
let l_429 = a_400[u32(1)];
let l_430 = u64(l_429);
let l_431 = a_400[u32(0)];
let l_432 = u64(l_431);
let l_433 = l_430 * l_432;
let l_434 = a_405[u32(1)];
let l_435 = u64(l_434);
let l_436 = l_433 + l_435;
let l_437 = l_436 + l_mut_52;
let l_438 = u32(bitcast<u64>(l_437));
a_405[u32(1)] = l_438;
let l_439 = l_437 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_439;
let l_440 = a_400[u32(1)];
let l_441 = u64(l_440);
let l_442 = a_400[u32(1)];
let l_443 = u64(l_442);
let l_444 = l_441 * l_443;
let l_445 = a_405[u32(2)];
let l_446 = u64(l_445);
let l_447 = l_444 + l_446;
let l_448 = l_447 + l_mut_52;
let l_449 = u32(bitcast<u64>(l_448));
a_405[u32(2)] = l_449;
let l_450 = l_448 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_450;
let l_451 = u32(bitcast<u64>(l_mut_52));
a_405[u32(3)] = l_451;
let l_452 = l_14 + u32(0);
let l_453 = a_405[u32(0)];
shared_memory_13[l_452] = l_453;
let l_454 = l_14 + u32(1);
let l_455 = a_405[u32(1)];
shared_memory_13[l_454] = l_455;
let l_456 = l_14 + u32(2);
let l_457 = a_405[u32(2)];
shared_memory_13[l_456] = l_457;
let l_458 = l_14 + u32(3);
let l_459 = a_405[u32(3)];
shared_memory_13[l_458] = l_459;
l_mut_460 = i32(3);
loop {
let l_461 = l_mut_460 >= i32(0);
let l_462 = !l_461;
if l_462 {
break;
}
let l_463 = u32(l_mut_460);
let l_464 = l_14 + l_463;
let l_465 = shared_memory_13[l_464];
let l_466 = l_465 != u32(0);
if l_466 {
break;
}
l_mut_460 = l_mut_460 - i32(1);
}
loop {
let l_467 = l_mut_460 >= i32(0);
let l_468 = l_467 && l_mut_167;
let l_469 = !l_468;
if l_469 {
break;
}
l_mut_355 = u32(0);
l_mut_470 = l_mut_460;
loop {
let l_471 = l_mut_470 >= i32(0);
let l_472 = !l_471;
if l_472 {
break;
}
let l_473 = u32(l_mut_470);
let l_474 = l_14 + l_473;
let l_475 = shared_memory_13[l_474];
let l_476 = l_mut_355 << u32(16);
let l_477 = l_475 >> u32(16);
let l_478 = l_476 | l_477;
let l_479 = l_478 / u32(64000);
let l_480 = l_479 * u32(64000);
let l_481 = l_478 - l_480;
let l_482 = l_481 << u32(16);
let l_483 = l_475 & u32(65535);
let l_484 = l_482 | l_483;
let l_485 = l_484 / u32(64000);
let l_486 = l_485 * u32(64000);
let l_487 = l_484 - l_486;
l_mut_355 = l_487;
let l_488 = u32(l_mut_470);
let l_489 = l_14 + l_488;
let l_490 = l_479 << u32(16);
let l_491 = l_490 | l_485;
shared_memory_13[l_489] = l_491;
l_mut_470 = l_mut_470 - i32(1);
}
loop {
let l_492 = l_mut_460 >= i32(0);
let l_493 = !l_492;
if l_493 {
break;
}
let l_494 = u32(l_mut_460);
let l_495 = l_14 + l_494;
let l_496 = shared_memory_13[l_495];
let l_497 = l_496 != u32(0);
if l_497 {
break;
}
l_mut_460 = l_mut_460 - i32(1);
}
l_mut_105 = l_mut_355;
l_mut_52 = u64(0);
let l_498 = l_mut_460 >= i32(0);
if l_498 {
let l_499 = l_mut_105 / u32(40);
let l_500 = l_499 * u32(40);
let l_501 = l_mut_105 - l_500;
l_mut_105 = l_499;
let l_502 = u64(l_501);
let l_503 = u64(1) << u32(bitcast<u64>(l_502));
let l_504 = l_mut_125 & l_503;
l_mut_52 = l_mut_52 | l_504;
l_mut_125 = l_mut_125 | l_503;
let l_505 = l_mut_105 / u32(40);
let l_506 = l_505 * u32(40);
let l_507 = l_mut_105 - l_506;
l_mut_105 = l_505;
let l_508 = u64(l_507);
let l_509 = u64(1) << u32(bitcast<u64>(l_508));
let l_510 = l_mut_125 & l_509;
l_mut_52 = l_mut_52 | l_510;
l_mut_125 = l_mut_125 | l_509;
let l_511 = l_mut_105 / u32(40);
let l_512 = l_511 * u32(40);
let l_513 = l_mut_105 - l_512;
l_mut_105 = l_511;
let l_514 = u64(l_513);
let l_515 = u64(1) << u32(bitcast<u64>(l_514));
let l_516 = l_mut_125 & l_515;
l_mut_52 = l_mut_52 | l_516;
l_mut_125 = l_mut_125 | l_515;
} else {
loop {
let l_517 = l_mut_105 != u32(0);
let l_518 = !l_517;
if l_518 {
break;
}
let l_519 = l_mut_105 / u32(40);
let l_520 = l_519 * u32(40);
let l_521 = l_mut_105 - l_520;
l_mut_105 = l_519;
let l_522 = u64(l_521);
let l_523 = u64(1) << u32(bitcast<u64>(l_522));
let l_524 = l_mut_125 & l_523;
l_mut_52 = l_mut_52 | l_524;
l_mut_125 = l_mut_125 | l_523;
}
}
let l_525 = l_mut_52 != u64(0);
if l_525 {
l_mut_167 = bool(false);
}
}
if l_mut_167 {
let l_526 = l_14 + u32(0);
shared_memory_13[l_526] = u32(0);
let l_527 = l_14 + u32(1);
shared_memory_13[l_527] = u32(0);
let l_528 = l_14 + u32(2);
shared_memory_13[l_528] = u32(0);
let l_529 = l_14 + u32(3);
shared_memory_13[l_529] = u32(0);
let l_530 = l_14 + u32(4);
shared_memory_13[l_530] = u32(0);
let l_531 = l_14 + u32(5);
shared_memory_13[l_531] = u32(0);
l_mut_52 = u64(0);
let l_532 = a_405[u32(0)];
let l_533 = u64(l_532);
let l_534 = a_400[u32(0)];
let l_535 = u64(l_534);
let l_536 = l_533 * l_535;
let l_537 = l_14 + u32(0);
let l_538 = shared_memory_13[l_537];
let l_539 = u64(l_538);
let l_540 = l_536 + l_539;
let l_541 = l_540 + l_mut_52;
let l_542 = l_14 + u32(0);
let l_543 = u32(bitcast<u64>(l_541));
shared_memory_13[l_542] = l_543;
let l_544 = l_541 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_544;
let l_545 = a_405[u32(0)];
let l_546 = u64(l_545);
let l_547 = a_400[u32(1)];
let l_548 = u64(l_547);
let l_549 = l_546 * l_548;
let l_550 = l_14 + u32(1);
let l_551 = shared_memory_13[l_550];
let l_552 = u64(l_551);
let l_553 = l_549 + l_552;
let l_554 = l_553 + l_mut_52;
let l_555 = l_14 + u32(1);
let l_556 = u32(bitcast<u64>(l_554));
shared_memory_13[l_555] = l_556;
let l_557 = l_554 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_557;
let l_558 = l_14 + u32(2);
let l_559 = u32(bitcast<u64>(l_mut_52));
shared_memory_13[l_558] = l_559;
l_mut_52 = u64(0);
let l_560 = a_405[u32(1)];
let l_561 = u64(l_560);
let l_562 = a_400[u32(0)];
let l_563 = u64(l_562);
let l_564 = l_561 * l_563;
let l_565 = l_14 + u32(1);
let l_566 = shared_memory_13[l_565];
let l_567 = u64(l_566);
let l_568 = l_564 + l_567;
let l_569 = l_568 + l_mut_52;
let l_570 = l_14 + u32(1);
let l_571 = u32(bitcast<u64>(l_569));
shared_memory_13[l_570] = l_571;
let l_572 = l_569 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_572;
let l_573 = a_405[u32(1)];
let l_574 = u64(l_573);
let l_575 = a_400[u32(1)];
let l_576 = u64(l_575);
let l_577 = l_574 * l_576;
let l_578 = l_14 + u32(2);
let l_579 = shared_memory_13[l_578];
let l_580 = u64(l_579);
let l_581 = l_577 + l_580;
let l_582 = l_581 + l_mut_52;
let l_583 = l_14 + u32(2);
let l_584 = u32(bitcast<u64>(l_582));
shared_memory_13[l_583] = l_584;
let l_585 = l_582 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_585;
let l_586 = l_14 + u32(3);
let l_587 = u32(bitcast<u64>(l_mut_52));
shared_memory_13[l_586] = l_587;
l_mut_52 = u64(0);
let l_588 = a_405[u32(2)];
let l_589 = u64(l_588);
let l_590 = a_400[u32(0)];
let l_591 = u64(l_590);
let l_592 = l_589 * l_591;
let l_593 = l_14 + u32(2);
let l_594 = shared_memory_13[l_593];
let l_595 = u64(l_594);
let l_596 = l_592 + l_595;
let l_597 = l_596 + l_mut_52;
let l_598 = l_14 + u32(2);
let l_599 = u32(bitcast<u64>(l_597));
shared_memory_13[l_598] = l_599;
let l_600 = l_597 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_600;
let l_601 = a_405[u32(2)];
let l_602 = u64(l_601);
let l_603 = a_400[u32(1)];
let l_604 = u64(l_603);
let l_605 = l_602 * l_604;
let l_606 = l_14 + u32(3);
let l_607 = shared_memory_13[l_606];
let l_608 = u64(l_607);
let l_609 = l_605 + l_608;
let l_610 = l_609 + l_mut_52;
let l_611 = l_14 + u32(3);
let l_612 = u32(bitcast<u64>(l_610));
shared_memory_13[l_611] = l_612;
let l_613 = l_610 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_613;
let l_614 = l_14 + u32(4);
let l_615 = u32(bitcast<u64>(l_mut_52));
shared_memory_13[l_614] = l_615;
l_mut_52 = u64(0);
let l_616 = a_405[u32(3)];
let l_617 = u64(l_616);
let l_618 = a_400[u32(0)];
let l_619 = u64(l_618);
let l_620 = l_617 * l_619;
let l_621 = l_14 + u32(3);
let l_622 = shared_memory_13[l_621];
let l_623 = u64(l_622);
let l_624 = l_620 + l_623;
let l_625 = l_624 + l_mut_52;
let l_626 = l_14 + u32(3);
let l_627 = u32(bitcast<u64>(l_625));
shared_memory_13[l_626] = l_627;
let l_628 = l_625 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_628;
let l_629 = a_405[u32(3)];
let l_630 = u64(l_629);
let l_631 = a_400[u32(1)];
let l_632 = u64(l_631);
let l_633 = l_630 * l_632;
let l_634 = l_14 + u32(4);
let l_635 = shared_memory_13[l_634];
let l_636 = u64(l_635);
let l_637 = l_633 + l_636;
let l_638 = l_637 + l_mut_52;
let l_639 = l_14 + u32(4);
let l_640 = u32(bitcast<u64>(l_638));
shared_memory_13[l_639] = l_640;
let l_641 = l_638 >> u32(bitcast<u64>(u64(32)));
l_mut_52 = l_641;
let l_642 = l_14 + u32(5);
let l_643 = u32(bitcast<u64>(l_mut_52));
shared_memory_13[l_642] = l_643;
l_mut_470 = i32(5);
loop {
let l_644 = l_mut_470 >= i32(0);
let l_645 = !l_644;
if l_645 {
break;
}
let l_646 = u32(l_mut_470);
let l_647 = l_14 + l_646;
let l_648 = shared_memory_13[l_647];
let l_649 = l_648 != u32(0);
if l_649 {
break;
}
l_mut_470 = l_mut_470 - i32(1);
}
loop {
let l_650 = l_mut_470 >= i32(0);
let l_651 = l_650 && l_mut_167;
let l_652 = !l_651;
if l_652 {
break;
}
l_mut_355 = u32(0);
l_mut_653 = l_mut_470;
loop {
let l_654 = l_mut_653 >= i32(0);
let l_655 = !l_654;
if l_655 {
break;
}
let l_656 = u32(l_mut_653);
let l_657 = l_14 + l_656;
let l_658 = shared_memory_13[l_657];
let l_659 = l_mut_355 << u32(16);
let l_660 = l_658 >> u32(16);
let l_661 = l_659 | l_660;
let l_662 = l_661 / u32(64000);
let l_663 = l_662 * u32(64000);
let l_664 = l_661 - l_663;
let l_665 = l_664 << u32(16);
let l_666 = l_658 & u32(65535);
let l_667 = l_665 | l_666;
let l_668 = l_667 / u32(64000);
let l_669 = l_668 * u32(64000);
let l_670 = l_667 - l_669;
l_mut_355 = l_670;
let l_671 = u32(l_mut_653);
let l_672 = l_14 + l_671;
let l_673 = l_662 << u32(16);
let l_674 = l_673 | l_668;
shared_memory_13[l_672] = l_674;
l_mut_653 = l_mut_653 - i32(1);
}
loop {
let l_675 = l_mut_470 >= i32(0);
let l_676 = !l_675;
if l_676 {
break;
}
let l_677 = u32(l_mut_470);
let l_678 = l_14 + l_677;
let l_679 = shared_memory_13[l_678];
let l_680 = l_679 != u32(0);
if l_680 {
break;
}
l_mut_470 = l_mut_470 - i32(1);
}
l_mut_105 = l_mut_355;
l_mut_52 = u64(0);
let l_681 = l_mut_470 >= i32(0);
if l_681 {
let l_682 = l_mut_105 / u32(40);
let l_683 = l_682 * u32(40);
let l_684 = l_mut_105 - l_683;
l_mut_105 = l_682;
let l_685 = u64(l_684);
let l_686 = u64(1) << u32(bitcast<u64>(l_685));
let l_687 = l_mut_125 & l_686;
l_mut_52 = l_mut_52 | l_687;
l_mut_125 = l_mut_125 | l_686;
let l_688 = l_mut_105 / u32(40);
let l_689 = l_688 * u32(40);
let l_690 = l_mut_105 - l_689;
l_mut_105 = l_688;
let l_691 = u64(l_690);
let l_692 = u64(1) << u32(bitcast<u64>(l_691));
let l_693 = l_mut_125 & l_692;
l_mut_52 = l_mut_52 | l_693;
l_mut_125 = l_mut_125 | l_692;
let l_694 = l_mut_105 / u32(40);
let l_695 = l_694 * u32(40);
let l_696 = l_mut_105 - l_695;
l_mut_105 = l_694;
let l_697 = u64(l_696);
let l_698 = u64(1) << u32(bitcast<u64>(l_697));
let l_699 = l_mut_125 & l_698;
l_mut_52 = l_mut_52 | l_699;
l_mut_125 = l_mut_125 | l_698;
} else {
loop {
let l_700 = l_mut_105 != u32(0);
let l_701 = !l_700;
if l_701 {
break;
}
let l_702 = l_mut_105 / u32(40);
let l_703 = l_702 * u32(40);
let l_704 = l_mut_105 - l_703;
l_mut_105 = l_702;
let l_705 = u64(l_704);
let l_706 = u64(1) << u32(bitcast<u64>(l_705));
let l_707 = l_mut_125 & l_706;
l_mut_52 = l_mut_52 | l_707;
l_mut_125 = l_mut_125 | l_706;
}
}
let l_708 = l_mut_52 != u64(0);
if l_708 {
l_mut_167 = bool(false);
}
}
}
}
if l_mut_167 {
let l_709 = u32(bitcast<u64>(l_mut_125));
let l_710 = countOneBits(l_709);
let l_711 = l_mut_125 >> u32(bitcast<u64>(u64(32)));
let l_712 = u32(bitcast<u64>(l_711));
let l_713 = countOneBits(l_712);
let l_714 = l_710 + l_713;
l_mut_355 = l_714;
let l_715 = l_mut_355 == u32(40);
let l_716 = bool(true) || l_715;
if l_716 {
let l_717 = &buffer_4_global[u32(0)];
let l_718 = atomicAdd(l_717, u32(1));let l_719 = l_718 < info.scalars_u32[6];
if l_719 {
let l_720 = u32(4) * l_718;
let l_721 = u32(bitcast<u64>(l_165));
buffer_3_global[l_720] = l_721;
let l_722 = l_720 + u32(1);
let l_723 = l_165 >> u32(bitcast<u64>(u64(32)));
let l_724 = u32(bitcast<u64>(l_723));
buffer_3_global[l_722] = l_724;
let l_725 = l_720 + u32(2);
let l_726 = u32(bitcast<u64>(l_166));
buffer_3_global[l_725] = l_726;
let l_727 = l_720 + u32(3);
let l_728 = l_166 >> u32(bitcast<u64>(u64(32)));
let l_729 = u32(bitcast<u64>(l_728));
buffer_3_global[l_727] = l_729;
}
}
}
}
l_mut_32 = l_mut_32 - l_mut_151;
let l_730 = l_mut_32 == u32(0);
let l_731 = l_mut_133 && l_730;
if l_731 {
break;
}
}
}
```
