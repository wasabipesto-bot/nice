
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
var l_mut_88: u32;
let l_1 = local_invocation_id.x * u32(14);
l_mut_2 = u32(0);
let l_3 = l_1 + u32(0);
let l_4 = l_3 < u32(3540);
if l_4 {
let l_5 = workgroup_id.x * u32(3540);
let l_6 = l_5 + l_3;
let l_7 = &buffer_0_global[l_6];
let l_8 = atomicLoad(l_7);
l_mut_2 = l_mut_2 + l_8;
}
let l_9 = l_1 + u32(1);
let l_10 = l_9 < u32(3540);
if l_10 {
let l_11 = workgroup_id.x * u32(3540);
let l_12 = l_11 + l_9;
let l_13 = &buffer_0_global[l_12];
let l_14 = atomicLoad(l_13);
l_mut_2 = l_mut_2 + l_14;
}
let l_15 = l_1 + u32(2);
let l_16 = l_15 < u32(3540);
if l_16 {
let l_17 = workgroup_id.x * u32(3540);
let l_18 = l_17 + l_15;
let l_19 = &buffer_0_global[l_18];
let l_20 = atomicLoad(l_19);
l_mut_2 = l_mut_2 + l_20;
}
let l_21 = l_1 + u32(3);
let l_22 = l_21 < u32(3540);
if l_22 {
let l_23 = workgroup_id.x * u32(3540);
let l_24 = l_23 + l_21;
let l_25 = &buffer_0_global[l_24];
let l_26 = atomicLoad(l_25);
l_mut_2 = l_mut_2 + l_26;
}
let l_27 = l_1 + u32(4);
let l_28 = l_27 < u32(3540);
if l_28 {
let l_29 = workgroup_id.x * u32(3540);
let l_30 = l_29 + l_27;
let l_31 = &buffer_0_global[l_30];
let l_32 = atomicLoad(l_31);
l_mut_2 = l_mut_2 + l_32;
}
let l_33 = l_1 + u32(5);
let l_34 = l_33 < u32(3540);
if l_34 {
let l_35 = workgroup_id.x * u32(3540);
let l_36 = l_35 + l_33;
let l_37 = &buffer_0_global[l_36];
let l_38 = atomicLoad(l_37);
l_mut_2 = l_mut_2 + l_38;
}
let l_39 = l_1 + u32(6);
let l_40 = l_39 < u32(3540);
if l_40 {
let l_41 = workgroup_id.x * u32(3540);
let l_42 = l_41 + l_39;
let l_43 = &buffer_0_global[l_42];
let l_44 = atomicLoad(l_43);
l_mut_2 = l_mut_2 + l_44;
}
let l_45 = l_1 + u32(7);
let l_46 = l_45 < u32(3540);
if l_46 {
let l_47 = workgroup_id.x * u32(3540);
let l_48 = l_47 + l_45;
let l_49 = &buffer_0_global[l_48];
let l_50 = atomicLoad(l_49);
l_mut_2 = l_mut_2 + l_50;
}
let l_51 = l_1 + u32(8);
let l_52 = l_51 < u32(3540);
if l_52 {
let l_53 = workgroup_id.x * u32(3540);
let l_54 = l_53 + l_51;
let l_55 = &buffer_0_global[l_54];
let l_56 = atomicLoad(l_55);
l_mut_2 = l_mut_2 + l_56;
}
let l_57 = l_1 + u32(9);
let l_58 = l_57 < u32(3540);
if l_58 {
let l_59 = workgroup_id.x * u32(3540);
let l_60 = l_59 + l_57;
let l_61 = &buffer_0_global[l_60];
let l_62 = atomicLoad(l_61);
l_mut_2 = l_mut_2 + l_62;
}
let l_63 = l_1 + u32(10);
let l_64 = l_63 < u32(3540);
if l_64 {
let l_65 = workgroup_id.x * u32(3540);
let l_66 = l_65 + l_63;
let l_67 = &buffer_0_global[l_66];
let l_68 = atomicLoad(l_67);
l_mut_2 = l_mut_2 + l_68;
}
let l_69 = l_1 + u32(11);
let l_70 = l_69 < u32(3540);
if l_70 {
let l_71 = workgroup_id.x * u32(3540);
let l_72 = l_71 + l_69;
let l_73 = &buffer_0_global[l_72];
let l_74 = atomicLoad(l_73);
l_mut_2 = l_mut_2 + l_74;
}
let l_75 = l_1 + u32(12);
let l_76 = l_75 < u32(3540);
if l_76 {
let l_77 = workgroup_id.x * u32(3540);
let l_78 = l_77 + l_75;
let l_79 = &buffer_0_global[l_78];
let l_80 = atomicLoad(l_79);
l_mut_2 = l_mut_2 + l_80;
}
let l_81 = l_1 + u32(13);
let l_82 = l_81 < u32(3540);
if l_82 {
let l_83 = workgroup_id.x * u32(3540);
let l_84 = l_83 + l_81;
let l_85 = &buffer_0_global[l_84];
let l_86 = atomicLoad(l_85);
l_mut_2 = l_mut_2 + l_86;
}
shared_memory_0[local_invocation_id.x] = l_mut_2;
workgroupBarrier();
let l_87 = local_invocation_id.x == u32(0);
if l_87 {
l_mut_2 = u32(0);
l_mut_88 = u32(0);
loop {
let l_89 = l_mut_88 < WORKGROUP_SIZE_X;
let l_90 = !l_89;
if l_90 {
break;
}
let l_91 = shared_memory_0[l_mut_88];
shared_memory_0[l_mut_88] = l_mut_2;
l_mut_2 = l_mut_2 + l_91;
l_mut_88 = l_mut_88 + u32(1);
}
}
workgroupBarrier();
let l_92 = shared_memory_0[local_invocation_id.x];
let l_93 = workgroup_id.x * info.scalars_u32[0];
let l_94 = l_92 + l_93;
l_mut_88 = l_94;
let l_95 = l_1 + u32(0);
let l_96 = l_95 < u32(3540);
if l_96 {
let l_97 = workgroup_id.x * u32(3540);
let l_98 = l_97 + l_95;
let l_99 = &buffer_0_global[l_98];
let l_100 = atomicLoad(l_99);
let l_101 = workgroup_id.x * u32(3540);
let l_102 = l_101 + l_95;
let l_103 = &buffer_1_global[l_102];
atomicStore(l_103,l_mut_88);
let l_104 = workgroup_id.x * u32(3540);
let l_105 = l_104 + l_95;
let l_106 = u32(4) * l_105;
buffer_2_global[l_106] = workgroup_id.x;
let l_107 = u32(4) * l_105;
let l_108 = l_107 + u32(1);
buffer_2_global[l_108] = l_95;
let l_109 = u32(4) * l_105;
let l_110 = l_109 + u32(2);
buffer_2_global[l_110] = l_mut_88;
let l_111 = u32(4) * l_105;
let l_112 = l_111 + u32(3);
let l_113 = l_mut_88 + l_100;
buffer_2_global[l_112] = l_113;
l_mut_88 = l_mut_88 + l_100;
}
let l_114 = l_1 + u32(1);
let l_115 = l_114 < u32(3540);
if l_115 {
let l_116 = workgroup_id.x * u32(3540);
let l_117 = l_116 + l_114;
let l_118 = &buffer_0_global[l_117];
let l_119 = atomicLoad(l_118);
let l_120 = workgroup_id.x * u32(3540);
let l_121 = l_120 + l_114;
let l_122 = &buffer_1_global[l_121];
atomicStore(l_122,l_mut_88);
let l_123 = workgroup_id.x * u32(3540);
let l_124 = l_123 + l_114;
let l_125 = u32(4) * l_124;
buffer_2_global[l_125] = workgroup_id.x;
let l_126 = u32(4) * l_124;
let l_127 = l_126 + u32(1);
buffer_2_global[l_127] = l_114;
let l_128 = u32(4) * l_124;
let l_129 = l_128 + u32(2);
buffer_2_global[l_129] = l_mut_88;
let l_130 = u32(4) * l_124;
let l_131 = l_130 + u32(3);
let l_132 = l_mut_88 + l_119;
buffer_2_global[l_131] = l_132;
l_mut_88 = l_mut_88 + l_119;
}
let l_133 = l_1 + u32(2);
let l_134 = l_133 < u32(3540);
if l_134 {
let l_135 = workgroup_id.x * u32(3540);
let l_136 = l_135 + l_133;
let l_137 = &buffer_0_global[l_136];
let l_138 = atomicLoad(l_137);
let l_139 = workgroup_id.x * u32(3540);
let l_140 = l_139 + l_133;
let l_141 = &buffer_1_global[l_140];
atomicStore(l_141,l_mut_88);
let l_142 = workgroup_id.x * u32(3540);
let l_143 = l_142 + l_133;
let l_144 = u32(4) * l_143;
buffer_2_global[l_144] = workgroup_id.x;
let l_145 = u32(4) * l_143;
let l_146 = l_145 + u32(1);
buffer_2_global[l_146] = l_133;
let l_147 = u32(4) * l_143;
let l_148 = l_147 + u32(2);
buffer_2_global[l_148] = l_mut_88;
let l_149 = u32(4) * l_143;
let l_150 = l_149 + u32(3);
let l_151 = l_mut_88 + l_138;
buffer_2_global[l_150] = l_151;
l_mut_88 = l_mut_88 + l_138;
}
let l_152 = l_1 + u32(3);
let l_153 = l_152 < u32(3540);
if l_153 {
let l_154 = workgroup_id.x * u32(3540);
let l_155 = l_154 + l_152;
let l_156 = &buffer_0_global[l_155];
let l_157 = atomicLoad(l_156);
let l_158 = workgroup_id.x * u32(3540);
let l_159 = l_158 + l_152;
let l_160 = &buffer_1_global[l_159];
atomicStore(l_160,l_mut_88);
let l_161 = workgroup_id.x * u32(3540);
let l_162 = l_161 + l_152;
let l_163 = u32(4) * l_162;
buffer_2_global[l_163] = workgroup_id.x;
let l_164 = u32(4) * l_162;
let l_165 = l_164 + u32(1);
buffer_2_global[l_165] = l_152;
let l_166 = u32(4) * l_162;
let l_167 = l_166 + u32(2);
buffer_2_global[l_167] = l_mut_88;
let l_168 = u32(4) * l_162;
let l_169 = l_168 + u32(3);
let l_170 = l_mut_88 + l_157;
buffer_2_global[l_169] = l_170;
l_mut_88 = l_mut_88 + l_157;
}
let l_171 = l_1 + u32(4);
let l_172 = l_171 < u32(3540);
if l_172 {
let l_173 = workgroup_id.x * u32(3540);
let l_174 = l_173 + l_171;
let l_175 = &buffer_0_global[l_174];
let l_176 = atomicLoad(l_175);
let l_177 = workgroup_id.x * u32(3540);
let l_178 = l_177 + l_171;
let l_179 = &buffer_1_global[l_178];
atomicStore(l_179,l_mut_88);
let l_180 = workgroup_id.x * u32(3540);
let l_181 = l_180 + l_171;
let l_182 = u32(4) * l_181;
buffer_2_global[l_182] = workgroup_id.x;
let l_183 = u32(4) * l_181;
let l_184 = l_183 + u32(1);
buffer_2_global[l_184] = l_171;
let l_185 = u32(4) * l_181;
let l_186 = l_185 + u32(2);
buffer_2_global[l_186] = l_mut_88;
let l_187 = u32(4) * l_181;
let l_188 = l_187 + u32(3);
let l_189 = l_mut_88 + l_176;
buffer_2_global[l_188] = l_189;
l_mut_88 = l_mut_88 + l_176;
}
let l_190 = l_1 + u32(5);
let l_191 = l_190 < u32(3540);
if l_191 {
let l_192 = workgroup_id.x * u32(3540);
let l_193 = l_192 + l_190;
let l_194 = &buffer_0_global[l_193];
let l_195 = atomicLoad(l_194);
let l_196 = workgroup_id.x * u32(3540);
let l_197 = l_196 + l_190;
let l_198 = &buffer_1_global[l_197];
atomicStore(l_198,l_mut_88);
let l_199 = workgroup_id.x * u32(3540);
let l_200 = l_199 + l_190;
let l_201 = u32(4) * l_200;
buffer_2_global[l_201] = workgroup_id.x;
let l_202 = u32(4) * l_200;
let l_203 = l_202 + u32(1);
buffer_2_global[l_203] = l_190;
let l_204 = u32(4) * l_200;
let l_205 = l_204 + u32(2);
buffer_2_global[l_205] = l_mut_88;
let l_206 = u32(4) * l_200;
let l_207 = l_206 + u32(3);
let l_208 = l_mut_88 + l_195;
buffer_2_global[l_207] = l_208;
l_mut_88 = l_mut_88 + l_195;
}
let l_209 = l_1 + u32(6);
let l_210 = l_209 < u32(3540);
if l_210 {
let l_211 = workgroup_id.x * u32(3540);
let l_212 = l_211 + l_209;
let l_213 = &buffer_0_global[l_212];
let l_214 = atomicLoad(l_213);
let l_215 = workgroup_id.x * u32(3540);
let l_216 = l_215 + l_209;
let l_217 = &buffer_1_global[l_216];
atomicStore(l_217,l_mut_88);
let l_218 = workgroup_id.x * u32(3540);
let l_219 = l_218 + l_209;
let l_220 = u32(4) * l_219;
buffer_2_global[l_220] = workgroup_id.x;
let l_221 = u32(4) * l_219;
let l_222 = l_221 + u32(1);
buffer_2_global[l_222] = l_209;
let l_223 = u32(4) * l_219;
let l_224 = l_223 + u32(2);
buffer_2_global[l_224] = l_mut_88;
let l_225 = u32(4) * l_219;
let l_226 = l_225 + u32(3);
let l_227 = l_mut_88 + l_214;
buffer_2_global[l_226] = l_227;
l_mut_88 = l_mut_88 + l_214;
}
let l_228 = l_1 + u32(7);
let l_229 = l_228 < u32(3540);
if l_229 {
let l_230 = workgroup_id.x * u32(3540);
let l_231 = l_230 + l_228;
let l_232 = &buffer_0_global[l_231];
let l_233 = atomicLoad(l_232);
let l_234 = workgroup_id.x * u32(3540);
let l_235 = l_234 + l_228;
let l_236 = &buffer_1_global[l_235];
atomicStore(l_236,l_mut_88);
let l_237 = workgroup_id.x * u32(3540);
let l_238 = l_237 + l_228;
let l_239 = u32(4) * l_238;
buffer_2_global[l_239] = workgroup_id.x;
let l_240 = u32(4) * l_238;
let l_241 = l_240 + u32(1);
buffer_2_global[l_241] = l_228;
let l_242 = u32(4) * l_238;
let l_243 = l_242 + u32(2);
buffer_2_global[l_243] = l_mut_88;
let l_244 = u32(4) * l_238;
let l_245 = l_244 + u32(3);
let l_246 = l_mut_88 + l_233;
buffer_2_global[l_245] = l_246;
l_mut_88 = l_mut_88 + l_233;
}
let l_247 = l_1 + u32(8);
let l_248 = l_247 < u32(3540);
if l_248 {
let l_249 = workgroup_id.x * u32(3540);
let l_250 = l_249 + l_247;
let l_251 = &buffer_0_global[l_250];
let l_252 = atomicLoad(l_251);
let l_253 = workgroup_id.x * u32(3540);
let l_254 = l_253 + l_247;
let l_255 = &buffer_1_global[l_254];
atomicStore(l_255,l_mut_88);
let l_256 = workgroup_id.x * u32(3540);
let l_257 = l_256 + l_247;
let l_258 = u32(4) * l_257;
buffer_2_global[l_258] = workgroup_id.x;
let l_259 = u32(4) * l_257;
let l_260 = l_259 + u32(1);
buffer_2_global[l_260] = l_247;
let l_261 = u32(4) * l_257;
let l_262 = l_261 + u32(2);
buffer_2_global[l_262] = l_mut_88;
let l_263 = u32(4) * l_257;
let l_264 = l_263 + u32(3);
let l_265 = l_mut_88 + l_252;
buffer_2_global[l_264] = l_265;
l_mut_88 = l_mut_88 + l_252;
}
let l_266 = l_1 + u32(9);
let l_267 = l_266 < u32(3540);
if l_267 {
let l_268 = workgroup_id.x * u32(3540);
let l_269 = l_268 + l_266;
let l_270 = &buffer_0_global[l_269];
let l_271 = atomicLoad(l_270);
let l_272 = workgroup_id.x * u32(3540);
let l_273 = l_272 + l_266;
let l_274 = &buffer_1_global[l_273];
atomicStore(l_274,l_mut_88);
let l_275 = workgroup_id.x * u32(3540);
let l_276 = l_275 + l_266;
let l_277 = u32(4) * l_276;
buffer_2_global[l_277] = workgroup_id.x;
let l_278 = u32(4) * l_276;
let l_279 = l_278 + u32(1);
buffer_2_global[l_279] = l_266;
let l_280 = u32(4) * l_276;
let l_281 = l_280 + u32(2);
buffer_2_global[l_281] = l_mut_88;
let l_282 = u32(4) * l_276;
let l_283 = l_282 + u32(3);
let l_284 = l_mut_88 + l_271;
buffer_2_global[l_283] = l_284;
l_mut_88 = l_mut_88 + l_271;
}
let l_285 = l_1 + u32(10);
let l_286 = l_285 < u32(3540);
if l_286 {
let l_287 = workgroup_id.x * u32(3540);
let l_288 = l_287 + l_285;
let l_289 = &buffer_0_global[l_288];
let l_290 = atomicLoad(l_289);
let l_291 = workgroup_id.x * u32(3540);
let l_292 = l_291 + l_285;
let l_293 = &buffer_1_global[l_292];
atomicStore(l_293,l_mut_88);
let l_294 = workgroup_id.x * u32(3540);
let l_295 = l_294 + l_285;
let l_296 = u32(4) * l_295;
buffer_2_global[l_296] = workgroup_id.x;
let l_297 = u32(4) * l_295;
let l_298 = l_297 + u32(1);
buffer_2_global[l_298] = l_285;
let l_299 = u32(4) * l_295;
let l_300 = l_299 + u32(2);
buffer_2_global[l_300] = l_mut_88;
let l_301 = u32(4) * l_295;
let l_302 = l_301 + u32(3);
let l_303 = l_mut_88 + l_290;
buffer_2_global[l_302] = l_303;
l_mut_88 = l_mut_88 + l_290;
}
let l_304 = l_1 + u32(11);
let l_305 = l_304 < u32(3540);
if l_305 {
let l_306 = workgroup_id.x * u32(3540);
let l_307 = l_306 + l_304;
let l_308 = &buffer_0_global[l_307];
let l_309 = atomicLoad(l_308);
let l_310 = workgroup_id.x * u32(3540);
let l_311 = l_310 + l_304;
let l_312 = &buffer_1_global[l_311];
atomicStore(l_312,l_mut_88);
let l_313 = workgroup_id.x * u32(3540);
let l_314 = l_313 + l_304;
let l_315 = u32(4) * l_314;
buffer_2_global[l_315] = workgroup_id.x;
let l_316 = u32(4) * l_314;
let l_317 = l_316 + u32(1);
buffer_2_global[l_317] = l_304;
let l_318 = u32(4) * l_314;
let l_319 = l_318 + u32(2);
buffer_2_global[l_319] = l_mut_88;
let l_320 = u32(4) * l_314;
let l_321 = l_320 + u32(3);
let l_322 = l_mut_88 + l_309;
buffer_2_global[l_321] = l_322;
l_mut_88 = l_mut_88 + l_309;
}
let l_323 = l_1 + u32(12);
let l_324 = l_323 < u32(3540);
if l_324 {
let l_325 = workgroup_id.x * u32(3540);
let l_326 = l_325 + l_323;
let l_327 = &buffer_0_global[l_326];
let l_328 = atomicLoad(l_327);
let l_329 = workgroup_id.x * u32(3540);
let l_330 = l_329 + l_323;
let l_331 = &buffer_1_global[l_330];
atomicStore(l_331,l_mut_88);
let l_332 = workgroup_id.x * u32(3540);
let l_333 = l_332 + l_323;
let l_334 = u32(4) * l_333;
buffer_2_global[l_334] = workgroup_id.x;
let l_335 = u32(4) * l_333;
let l_336 = l_335 + u32(1);
buffer_2_global[l_336] = l_323;
let l_337 = u32(4) * l_333;
let l_338 = l_337 + u32(2);
buffer_2_global[l_338] = l_mut_88;
let l_339 = u32(4) * l_333;
let l_340 = l_339 + u32(3);
let l_341 = l_mut_88 + l_328;
buffer_2_global[l_340] = l_341;
l_mut_88 = l_mut_88 + l_328;
}
let l_342 = l_1 + u32(13);
let l_343 = l_342 < u32(3540);
if l_343 {
let l_344 = workgroup_id.x * u32(3540);
let l_345 = l_344 + l_342;
let l_346 = &buffer_0_global[l_345];
let l_347 = atomicLoad(l_346);
let l_348 = workgroup_id.x * u32(3540);
let l_349 = l_348 + l_342;
let l_350 = &buffer_1_global[l_349];
atomicStore(l_350,l_mut_88);
let l_351 = workgroup_id.x * u32(3540);
let l_352 = l_351 + l_342;
let l_353 = u32(4) * l_352;
buffer_2_global[l_353] = workgroup_id.x;
let l_354 = u32(4) * l_352;
let l_355 = l_354 + u32(1);
buffer_2_global[l_355] = l_342;
let l_356 = u32(4) * l_352;
let l_357 = l_356 + u32(2);
buffer_2_global[l_357] = l_mut_88;
let l_358 = u32(4) * l_352;
let l_359 = l_358 + u32(3);
let l_360 = l_mut_88 + l_347;
buffer_2_global[l_359] = l_360;
l_mut_88 = l_mut_88 + l_347;
}
workgroupBarrier();
let l_361 = local_invocation_id.x == u32(0);
if l_361 {
let l_362 = &buffer_3_global[u32(1)];
let l_363 = atomicAdd(l_362, u32(1));}
}
```
