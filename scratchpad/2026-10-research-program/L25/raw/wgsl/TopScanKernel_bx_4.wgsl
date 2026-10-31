
```wgsl
@group(0)
@binding(0)
var<storage, read_write> buffer_0_global: array<atomic<u32>>;

@group(0)
@binding(1)
var<storage, read_write> buffer_1_global: array<atomic<u32>>;

@group(0)
@binding(2)
var<storage, read_write> buffer_2_global: array<u32>;

@group(0)
@binding(3)
var<storage, read_write> buffer_3_global: array<atomic<u32>>;

struct info_st {
   scalars_u32: array<u32, 2>,
   static_meta: array<u32, 8>,
}

@group(0)
@binding(4)
var<storage, read> info: info_st;

var<workgroup> shared_memory_0: array<u32, 256>;

const WORKGROUP_SIZE_X = 256u;
const WORKGROUP_SIZE_Y = 1u;
const WORKGROUP_SIZE_Z = 1u;

@compute
@workgroup_size(256, 1, 1)
fn top_scan_kernel(
    @builtin(local_invocation_id) local_invocation_id: vec3<u32>,
    @builtin(workgroup_id) workgroup_id: vec3<u32>,
) {
var l_mut_2: u32;
var l_mut_100: u32;
let l_1 = local_invocation_id.x * u32(16);
l_mut_2 = u32(0);
let l_3 = l_1 + u32(0);
let l_4 = l_3 < u32(4032);
if l_4 {
let l_5 = workgroup_id.x * u32(4032);
let l_6 = l_5 + l_3;
let l_7 = &buffer_0_global[l_6];
let l_8 = atomicLoad(l_7);
l_mut_2 = l_mut_2 + l_8;
}
let l_9 = l_1 + u32(1);
let l_10 = l_9 < u32(4032);
if l_10 {
let l_11 = workgroup_id.x * u32(4032);
let l_12 = l_11 + l_9;
let l_13 = &buffer_0_global[l_12];
let l_14 = atomicLoad(l_13);
l_mut_2 = l_mut_2 + l_14;
}
let l_15 = l_1 + u32(2);
let l_16 = l_15 < u32(4032);
if l_16 {
let l_17 = workgroup_id.x * u32(4032);
let l_18 = l_17 + l_15;
let l_19 = &buffer_0_global[l_18];
let l_20 = atomicLoad(l_19);
l_mut_2 = l_mut_2 + l_20;
}
let l_21 = l_1 + u32(3);
let l_22 = l_21 < u32(4032);
if l_22 {
let l_23 = workgroup_id.x * u32(4032);
let l_24 = l_23 + l_21;
let l_25 = &buffer_0_global[l_24];
let l_26 = atomicLoad(l_25);
l_mut_2 = l_mut_2 + l_26;
}
let l_27 = l_1 + u32(4);
let l_28 = l_27 < u32(4032);
if l_28 {
let l_29 = workgroup_id.x * u32(4032);
let l_30 = l_29 + l_27;
let l_31 = &buffer_0_global[l_30];
let l_32 = atomicLoad(l_31);
l_mut_2 = l_mut_2 + l_32;
}
let l_33 = l_1 + u32(5);
let l_34 = l_33 < u32(4032);
if l_34 {
let l_35 = workgroup_id.x * u32(4032);
let l_36 = l_35 + l_33;
let l_37 = &buffer_0_global[l_36];
let l_38 = atomicLoad(l_37);
l_mut_2 = l_mut_2 + l_38;
}
let l_39 = l_1 + u32(6);
let l_40 = l_39 < u32(4032);
if l_40 {
let l_41 = workgroup_id.x * u32(4032);
let l_42 = l_41 + l_39;
let l_43 = &buffer_0_global[l_42];
let l_44 = atomicLoad(l_43);
l_mut_2 = l_mut_2 + l_44;
}
let l_45 = l_1 + u32(7);
let l_46 = l_45 < u32(4032);
if l_46 {
let l_47 = workgroup_id.x * u32(4032);
let l_48 = l_47 + l_45;
let l_49 = &buffer_0_global[l_48];
let l_50 = atomicLoad(l_49);
l_mut_2 = l_mut_2 + l_50;
}
let l_51 = l_1 + u32(8);
let l_52 = l_51 < u32(4032);
if l_52 {
let l_53 = workgroup_id.x * u32(4032);
let l_54 = l_53 + l_51;
let l_55 = &buffer_0_global[l_54];
let l_56 = atomicLoad(l_55);
l_mut_2 = l_mut_2 + l_56;
}
let l_57 = l_1 + u32(9);
let l_58 = l_57 < u32(4032);
if l_58 {
let l_59 = workgroup_id.x * u32(4032);
let l_60 = l_59 + l_57;
let l_61 = &buffer_0_global[l_60];
let l_62 = atomicLoad(l_61);
l_mut_2 = l_mut_2 + l_62;
}
let l_63 = l_1 + u32(10);
let l_64 = l_63 < u32(4032);
if l_64 {
let l_65 = workgroup_id.x * u32(4032);
let l_66 = l_65 + l_63;
let l_67 = &buffer_0_global[l_66];
let l_68 = atomicLoad(l_67);
l_mut_2 = l_mut_2 + l_68;
}
let l_69 = l_1 + u32(11);
let l_70 = l_69 < u32(4032);
if l_70 {
let l_71 = workgroup_id.x * u32(4032);
let l_72 = l_71 + l_69;
let l_73 = &buffer_0_global[l_72];
let l_74 = atomicLoad(l_73);
l_mut_2 = l_mut_2 + l_74;
}
let l_75 = l_1 + u32(12);
let l_76 = l_75 < u32(4032);
if l_76 {
let l_77 = workgroup_id.x * u32(4032);
let l_78 = l_77 + l_75;
let l_79 = &buffer_0_global[l_78];
let l_80 = atomicLoad(l_79);
l_mut_2 = l_mut_2 + l_80;
}
let l_81 = l_1 + u32(13);
let l_82 = l_81 < u32(4032);
if l_82 {
let l_83 = workgroup_id.x * u32(4032);
let l_84 = l_83 + l_81;
let l_85 = &buffer_0_global[l_84];
let l_86 = atomicLoad(l_85);
l_mut_2 = l_mut_2 + l_86;
}
let l_87 = l_1 + u32(14);
let l_88 = l_87 < u32(4032);
if l_88 {
let l_89 = workgroup_id.x * u32(4032);
let l_90 = l_89 + l_87;
let l_91 = &buffer_0_global[l_90];
let l_92 = atomicLoad(l_91);
l_mut_2 = l_mut_2 + l_92;
}
let l_93 = l_1 + u32(15);
let l_94 = l_93 < u32(4032);
if l_94 {
let l_95 = workgroup_id.x * u32(4032);
let l_96 = l_95 + l_93;
let l_97 = &buffer_0_global[l_96];
let l_98 = atomicLoad(l_97);
l_mut_2 = l_mut_2 + l_98;
}
shared_memory_0[local_invocation_id.x] = l_mut_2;
workgroupBarrier();
let l_99 = local_invocation_id.x == u32(0);
if l_99 {
l_mut_2 = u32(0);
l_mut_100 = u32(0);
loop {
let l_101 = l_mut_100 < WORKGROUP_SIZE_X;
let l_102 = !l_101;
if l_102 {
break;
}
let l_103 = shared_memory_0[l_mut_100];
shared_memory_0[l_mut_100] = l_mut_2;
l_mut_2 = l_mut_2 + l_103;
l_mut_100 = l_mut_100 + u32(1);
}
}
workgroupBarrier();
let l_104 = shared_memory_0[local_invocation_id.x];
let l_105 = workgroup_id.x * info.scalars_u32[0];
let l_106 = l_104 + l_105;
l_mut_100 = l_106;
let l_107 = l_1 + u32(0);
let l_108 = l_107 < u32(4032);
if l_108 {
let l_109 = workgroup_id.x * u32(4032);
let l_110 = l_109 + l_107;
let l_111 = &buffer_0_global[l_110];
let l_112 = atomicLoad(l_111);
let l_113 = workgroup_id.x * u32(4032);
let l_114 = l_113 + l_107;
let l_115 = &buffer_1_global[l_114];
atomicStore(l_115,l_mut_100);
let l_116 = workgroup_id.x * u32(4032);
let l_117 = l_116 + l_107;
let l_118 = u32(4) * l_117;
buffer_2_global[l_118] = workgroup_id.x;
let l_119 = u32(4) * l_117;
let l_120 = l_119 + u32(1);
buffer_2_global[l_120] = l_107;
let l_121 = u32(4) * l_117;
let l_122 = l_121 + u32(2);
buffer_2_global[l_122] = l_mut_100;
let l_123 = u32(4) * l_117;
let l_124 = l_123 + u32(3);
let l_125 = l_mut_100 + l_112;
buffer_2_global[l_124] = l_125;
l_mut_100 = l_mut_100 + l_112;
}
let l_126 = l_1 + u32(1);
let l_127 = l_126 < u32(4032);
if l_127 {
let l_128 = workgroup_id.x * u32(4032);
let l_129 = l_128 + l_126;
let l_130 = &buffer_0_global[l_129];
let l_131 = atomicLoad(l_130);
let l_132 = workgroup_id.x * u32(4032);
let l_133 = l_132 + l_126;
let l_134 = &buffer_1_global[l_133];
atomicStore(l_134,l_mut_100);
let l_135 = workgroup_id.x * u32(4032);
let l_136 = l_135 + l_126;
let l_137 = u32(4) * l_136;
buffer_2_global[l_137] = workgroup_id.x;
let l_138 = u32(4) * l_136;
let l_139 = l_138 + u32(1);
buffer_2_global[l_139] = l_126;
let l_140 = u32(4) * l_136;
let l_141 = l_140 + u32(2);
buffer_2_global[l_141] = l_mut_100;
let l_142 = u32(4) * l_136;
let l_143 = l_142 + u32(3);
let l_144 = l_mut_100 + l_131;
buffer_2_global[l_143] = l_144;
l_mut_100 = l_mut_100 + l_131;
}
let l_145 = l_1 + u32(2);
let l_146 = l_145 < u32(4032);
if l_146 {
let l_147 = workgroup_id.x * u32(4032);
let l_148 = l_147 + l_145;
let l_149 = &buffer_0_global[l_148];
let l_150 = atomicLoad(l_149);
let l_151 = workgroup_id.x * u32(4032);
let l_152 = l_151 + l_145;
let l_153 = &buffer_1_global[l_152];
atomicStore(l_153,l_mut_100);
let l_154 = workgroup_id.x * u32(4032);
let l_155 = l_154 + l_145;
let l_156 = u32(4) * l_155;
buffer_2_global[l_156] = workgroup_id.x;
let l_157 = u32(4) * l_155;
let l_158 = l_157 + u32(1);
buffer_2_global[l_158] = l_145;
let l_159 = u32(4) * l_155;
let l_160 = l_159 + u32(2);
buffer_2_global[l_160] = l_mut_100;
let l_161 = u32(4) * l_155;
let l_162 = l_161 + u32(3);
let l_163 = l_mut_100 + l_150;
buffer_2_global[l_162] = l_163;
l_mut_100 = l_mut_100 + l_150;
}
let l_164 = l_1 + u32(3);
let l_165 = l_164 < u32(4032);
if l_165 {
let l_166 = workgroup_id.x * u32(4032);
let l_167 = l_166 + l_164;
let l_168 = &buffer_0_global[l_167];
let l_169 = atomicLoad(l_168);
let l_170 = workgroup_id.x * u32(4032);
let l_171 = l_170 + l_164;
let l_172 = &buffer_1_global[l_171];
atomicStore(l_172,l_mut_100);
let l_173 = workgroup_id.x * u32(4032);
let l_174 = l_173 + l_164;
let l_175 = u32(4) * l_174;
buffer_2_global[l_175] = workgroup_id.x;
let l_176 = u32(4) * l_174;
let l_177 = l_176 + u32(1);
buffer_2_global[l_177] = l_164;
let l_178 = u32(4) * l_174;
let l_179 = l_178 + u32(2);
buffer_2_global[l_179] = l_mut_100;
let l_180 = u32(4) * l_174;
let l_181 = l_180 + u32(3);
let l_182 = l_mut_100 + l_169;
buffer_2_global[l_181] = l_182;
l_mut_100 = l_mut_100 + l_169;
}
let l_183 = l_1 + u32(4);
let l_184 = l_183 < u32(4032);
if l_184 {
let l_185 = workgroup_id.x * u32(4032);
let l_186 = l_185 + l_183;
let l_187 = &buffer_0_global[l_186];
let l_188 = atomicLoad(l_187);
let l_189 = workgroup_id.x * u32(4032);
let l_190 = l_189 + l_183;
let l_191 = &buffer_1_global[l_190];
atomicStore(l_191,l_mut_100);
let l_192 = workgroup_id.x * u32(4032);
let l_193 = l_192 + l_183;
let l_194 = u32(4) * l_193;
buffer_2_global[l_194] = workgroup_id.x;
let l_195 = u32(4) * l_193;
let l_196 = l_195 + u32(1);
buffer_2_global[l_196] = l_183;
let l_197 = u32(4) * l_193;
let l_198 = l_197 + u32(2);
buffer_2_global[l_198] = l_mut_100;
let l_199 = u32(4) * l_193;
let l_200 = l_199 + u32(3);
let l_201 = l_mut_100 + l_188;
buffer_2_global[l_200] = l_201;
l_mut_100 = l_mut_100 + l_188;
}
let l_202 = l_1 + u32(5);
let l_203 = l_202 < u32(4032);
if l_203 {
let l_204 = workgroup_id.x * u32(4032);
let l_205 = l_204 + l_202;
let l_206 = &buffer_0_global[l_205];
let l_207 = atomicLoad(l_206);
let l_208 = workgroup_id.x * u32(4032);
let l_209 = l_208 + l_202;
let l_210 = &buffer_1_global[l_209];
atomicStore(l_210,l_mut_100);
let l_211 = workgroup_id.x * u32(4032);
let l_212 = l_211 + l_202;
let l_213 = u32(4) * l_212;
buffer_2_global[l_213] = workgroup_id.x;
let l_214 = u32(4) * l_212;
let l_215 = l_214 + u32(1);
buffer_2_global[l_215] = l_202;
let l_216 = u32(4) * l_212;
let l_217 = l_216 + u32(2);
buffer_2_global[l_217] = l_mut_100;
let l_218 = u32(4) * l_212;
let l_219 = l_218 + u32(3);
let l_220 = l_mut_100 + l_207;
buffer_2_global[l_219] = l_220;
l_mut_100 = l_mut_100 + l_207;
}
let l_221 = l_1 + u32(6);
let l_222 = l_221 < u32(4032);
if l_222 {
let l_223 = workgroup_id.x * u32(4032);
let l_224 = l_223 + l_221;
let l_225 = &buffer_0_global[l_224];
let l_226 = atomicLoad(l_225);
let l_227 = workgroup_id.x * u32(4032);
let l_228 = l_227 + l_221;
let l_229 = &buffer_1_global[l_228];
atomicStore(l_229,l_mut_100);
let l_230 = workgroup_id.x * u32(4032);
let l_231 = l_230 + l_221;
let l_232 = u32(4) * l_231;
buffer_2_global[l_232] = workgroup_id.x;
let l_233 = u32(4) * l_231;
let l_234 = l_233 + u32(1);
buffer_2_global[l_234] = l_221;
let l_235 = u32(4) * l_231;
let l_236 = l_235 + u32(2);
buffer_2_global[l_236] = l_mut_100;
let l_237 = u32(4) * l_231;
let l_238 = l_237 + u32(3);
let l_239 = l_mut_100 + l_226;
buffer_2_global[l_238] = l_239;
l_mut_100 = l_mut_100 + l_226;
}
let l_240 = l_1 + u32(7);
let l_241 = l_240 < u32(4032);
if l_241 {
let l_242 = workgroup_id.x * u32(4032);
let l_243 = l_242 + l_240;
let l_244 = &buffer_0_global[l_243];
let l_245 = atomicLoad(l_244);
let l_246 = workgroup_id.x * u32(4032);
let l_247 = l_246 + l_240;
let l_248 = &buffer_1_global[l_247];
atomicStore(l_248,l_mut_100);
let l_249 = workgroup_id.x * u32(4032);
let l_250 = l_249 + l_240;
let l_251 = u32(4) * l_250;
buffer_2_global[l_251] = workgroup_id.x;
let l_252 = u32(4) * l_250;
let l_253 = l_252 + u32(1);
buffer_2_global[l_253] = l_240;
let l_254 = u32(4) * l_250;
let l_255 = l_254 + u32(2);
buffer_2_global[l_255] = l_mut_100;
let l_256 = u32(4) * l_250;
let l_257 = l_256 + u32(3);
let l_258 = l_mut_100 + l_245;
buffer_2_global[l_257] = l_258;
l_mut_100 = l_mut_100 + l_245;
}
let l_259 = l_1 + u32(8);
let l_260 = l_259 < u32(4032);
if l_260 {
let l_261 = workgroup_id.x * u32(4032);
let l_262 = l_261 + l_259;
let l_263 = &buffer_0_global[l_262];
let l_264 = atomicLoad(l_263);
let l_265 = workgroup_id.x * u32(4032);
let l_266 = l_265 + l_259;
let l_267 = &buffer_1_global[l_266];
atomicStore(l_267,l_mut_100);
let l_268 = workgroup_id.x * u32(4032);
let l_269 = l_268 + l_259;
let l_270 = u32(4) * l_269;
buffer_2_global[l_270] = workgroup_id.x;
let l_271 = u32(4) * l_269;
let l_272 = l_271 + u32(1);
buffer_2_global[l_272] = l_259;
let l_273 = u32(4) * l_269;
let l_274 = l_273 + u32(2);
buffer_2_global[l_274] = l_mut_100;
let l_275 = u32(4) * l_269;
let l_276 = l_275 + u32(3);
let l_277 = l_mut_100 + l_264;
buffer_2_global[l_276] = l_277;
l_mut_100 = l_mut_100 + l_264;
}
let l_278 = l_1 + u32(9);
let l_279 = l_278 < u32(4032);
if l_279 {
let l_280 = workgroup_id.x * u32(4032);
let l_281 = l_280 + l_278;
let l_282 = &buffer_0_global[l_281];
let l_283 = atomicLoad(l_282);
let l_284 = workgroup_id.x * u32(4032);
let l_285 = l_284 + l_278;
let l_286 = &buffer_1_global[l_285];
atomicStore(l_286,l_mut_100);
let l_287 = workgroup_id.x * u32(4032);
let l_288 = l_287 + l_278;
let l_289 = u32(4) * l_288;
buffer_2_global[l_289] = workgroup_id.x;
let l_290 = u32(4) * l_288;
let l_291 = l_290 + u32(1);
buffer_2_global[l_291] = l_278;
let l_292 = u32(4) * l_288;
let l_293 = l_292 + u32(2);
buffer_2_global[l_293] = l_mut_100;
let l_294 = u32(4) * l_288;
let l_295 = l_294 + u32(3);
let l_296 = l_mut_100 + l_283;
buffer_2_global[l_295] = l_296;
l_mut_100 = l_mut_100 + l_283;
}
let l_297 = l_1 + u32(10);
let l_298 = l_297 < u32(4032);
if l_298 {
let l_299 = workgroup_id.x * u32(4032);
let l_300 = l_299 + l_297;
let l_301 = &buffer_0_global[l_300];
let l_302 = atomicLoad(l_301);
let l_303 = workgroup_id.x * u32(4032);
let l_304 = l_303 + l_297;
let l_305 = &buffer_1_global[l_304];
atomicStore(l_305,l_mut_100);
let l_306 = workgroup_id.x * u32(4032);
let l_307 = l_306 + l_297;
let l_308 = u32(4) * l_307;
buffer_2_global[l_308] = workgroup_id.x;
let l_309 = u32(4) * l_307;
let l_310 = l_309 + u32(1);
buffer_2_global[l_310] = l_297;
let l_311 = u32(4) * l_307;
let l_312 = l_311 + u32(2);
buffer_2_global[l_312] = l_mut_100;
let l_313 = u32(4) * l_307;
let l_314 = l_313 + u32(3);
let l_315 = l_mut_100 + l_302;
buffer_2_global[l_314] = l_315;
l_mut_100 = l_mut_100 + l_302;
}
let l_316 = l_1 + u32(11);
let l_317 = l_316 < u32(4032);
if l_317 {
let l_318 = workgroup_id.x * u32(4032);
let l_319 = l_318 + l_316;
let l_320 = &buffer_0_global[l_319];
let l_321 = atomicLoad(l_320);
let l_322 = workgroup_id.x * u32(4032);
let l_323 = l_322 + l_316;
let l_324 = &buffer_1_global[l_323];
atomicStore(l_324,l_mut_100);
let l_325 = workgroup_id.x * u32(4032);
let l_326 = l_325 + l_316;
let l_327 = u32(4) * l_326;
buffer_2_global[l_327] = workgroup_id.x;
let l_328 = u32(4) * l_326;
let l_329 = l_328 + u32(1);
buffer_2_global[l_329] = l_316;
let l_330 = u32(4) * l_326;
let l_331 = l_330 + u32(2);
buffer_2_global[l_331] = l_mut_100;
let l_332 = u32(4) * l_326;
let l_333 = l_332 + u32(3);
let l_334 = l_mut_100 + l_321;
buffer_2_global[l_333] = l_334;
l_mut_100 = l_mut_100 + l_321;
}
let l_335 = l_1 + u32(12);
let l_336 = l_335 < u32(4032);
if l_336 {
let l_337 = workgroup_id.x * u32(4032);
let l_338 = l_337 + l_335;
let l_339 = &buffer_0_global[l_338];
let l_340 = atomicLoad(l_339);
let l_341 = workgroup_id.x * u32(4032);
let l_342 = l_341 + l_335;
let l_343 = &buffer_1_global[l_342];
atomicStore(l_343,l_mut_100);
let l_344 = workgroup_id.x * u32(4032);
let l_345 = l_344 + l_335;
let l_346 = u32(4) * l_345;
buffer_2_global[l_346] = workgroup_id.x;
let l_347 = u32(4) * l_345;
let l_348 = l_347 + u32(1);
buffer_2_global[l_348] = l_335;
let l_349 = u32(4) * l_345;
let l_350 = l_349 + u32(2);
buffer_2_global[l_350] = l_mut_100;
let l_351 = u32(4) * l_345;
let l_352 = l_351 + u32(3);
let l_353 = l_mut_100 + l_340;
buffer_2_global[l_352] = l_353;
l_mut_100 = l_mut_100 + l_340;
}
let l_354 = l_1 + u32(13);
let l_355 = l_354 < u32(4032);
if l_355 {
let l_356 = workgroup_id.x * u32(4032);
let l_357 = l_356 + l_354;
let l_358 = &buffer_0_global[l_357];
let l_359 = atomicLoad(l_358);
let l_360 = workgroup_id.x * u32(4032);
let l_361 = l_360 + l_354;
let l_362 = &buffer_1_global[l_361];
atomicStore(l_362,l_mut_100);
let l_363 = workgroup_id.x * u32(4032);
let l_364 = l_363 + l_354;
let l_365 = u32(4) * l_364;
buffer_2_global[l_365] = workgroup_id.x;
let l_366 = u32(4) * l_364;
let l_367 = l_366 + u32(1);
buffer_2_global[l_367] = l_354;
let l_368 = u32(4) * l_364;
let l_369 = l_368 + u32(2);
buffer_2_global[l_369] = l_mut_100;
let l_370 = u32(4) * l_364;
let l_371 = l_370 + u32(3);
let l_372 = l_mut_100 + l_359;
buffer_2_global[l_371] = l_372;
l_mut_100 = l_mut_100 + l_359;
}
let l_373 = l_1 + u32(14);
let l_374 = l_373 < u32(4032);
if l_374 {
let l_375 = workgroup_id.x * u32(4032);
let l_376 = l_375 + l_373;
let l_377 = &buffer_0_global[l_376];
let l_378 = atomicLoad(l_377);
let l_379 = workgroup_id.x * u32(4032);
let l_380 = l_379 + l_373;
let l_381 = &buffer_1_global[l_380];
atomicStore(l_381,l_mut_100);
let l_382 = workgroup_id.x * u32(4032);
let l_383 = l_382 + l_373;
let l_384 = u32(4) * l_383;
buffer_2_global[l_384] = workgroup_id.x;
let l_385 = u32(4) * l_383;
let l_386 = l_385 + u32(1);
buffer_2_global[l_386] = l_373;
let l_387 = u32(4) * l_383;
let l_388 = l_387 + u32(2);
buffer_2_global[l_388] = l_mut_100;
let l_389 = u32(4) * l_383;
let l_390 = l_389 + u32(3);
let l_391 = l_mut_100 + l_378;
buffer_2_global[l_390] = l_391;
l_mut_100 = l_mut_100 + l_378;
}
let l_392 = l_1 + u32(15);
let l_393 = l_392 < u32(4032);
if l_393 {
let l_394 = workgroup_id.x * u32(4032);
let l_395 = l_394 + l_392;
let l_396 = &buffer_0_global[l_395];
let l_397 = atomicLoad(l_396);
let l_398 = workgroup_id.x * u32(4032);
let l_399 = l_398 + l_392;
let l_400 = &buffer_1_global[l_399];
atomicStore(l_400,l_mut_100);
let l_401 = workgroup_id.x * u32(4032);
let l_402 = l_401 + l_392;
let l_403 = u32(4) * l_402;
buffer_2_global[l_403] = workgroup_id.x;
let l_404 = u32(4) * l_402;
let l_405 = l_404 + u32(1);
buffer_2_global[l_405] = l_392;
let l_406 = u32(4) * l_402;
let l_407 = l_406 + u32(2);
buffer_2_global[l_407] = l_mut_100;
let l_408 = u32(4) * l_402;
let l_409 = l_408 + u32(3);
let l_410 = l_mut_100 + l_397;
buffer_2_global[l_409] = l_410;
l_mut_100 = l_mut_100 + l_397;
}
workgroupBarrier();
let l_411 = local_invocation_id.x == u32(0);
if l_411 {
let l_412 = &buffer_3_global[u32(1)];
let l_413 = atomicAdd(l_412, u32(1));}
}
```
