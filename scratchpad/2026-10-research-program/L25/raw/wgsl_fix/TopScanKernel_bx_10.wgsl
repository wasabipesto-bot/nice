
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
var l_mut_82: u32;
let l_1 = local_invocation_id.x * u32(13);
l_mut_2 = u32(0);
let l_3 = l_1 + u32(0);
let l_4 = l_3 < u32(3192);
if l_4 {
let l_5 = workgroup_id.x * u32(3192);
let l_6 = l_5 + l_3;
let l_7 = &buffer_0_global[l_6];
let l_8 = atomicLoad(l_7);
l_mut_2 = l_mut_2 + l_8;
}
let l_9 = l_1 + u32(1);
let l_10 = l_9 < u32(3192);
if l_10 {
let l_11 = workgroup_id.x * u32(3192);
let l_12 = l_11 + l_9;
let l_13 = &buffer_0_global[l_12];
let l_14 = atomicLoad(l_13);
l_mut_2 = l_mut_2 + l_14;
}
let l_15 = l_1 + u32(2);
let l_16 = l_15 < u32(3192);
if l_16 {
let l_17 = workgroup_id.x * u32(3192);
let l_18 = l_17 + l_15;
let l_19 = &buffer_0_global[l_18];
let l_20 = atomicLoad(l_19);
l_mut_2 = l_mut_2 + l_20;
}
let l_21 = l_1 + u32(3);
let l_22 = l_21 < u32(3192);
if l_22 {
let l_23 = workgroup_id.x * u32(3192);
let l_24 = l_23 + l_21;
let l_25 = &buffer_0_global[l_24];
let l_26 = atomicLoad(l_25);
l_mut_2 = l_mut_2 + l_26;
}
let l_27 = l_1 + u32(4);
let l_28 = l_27 < u32(3192);
if l_28 {
let l_29 = workgroup_id.x * u32(3192);
let l_30 = l_29 + l_27;
let l_31 = &buffer_0_global[l_30];
let l_32 = atomicLoad(l_31);
l_mut_2 = l_mut_2 + l_32;
}
let l_33 = l_1 + u32(5);
let l_34 = l_33 < u32(3192);
if l_34 {
let l_35 = workgroup_id.x * u32(3192);
let l_36 = l_35 + l_33;
let l_37 = &buffer_0_global[l_36];
let l_38 = atomicLoad(l_37);
l_mut_2 = l_mut_2 + l_38;
}
let l_39 = l_1 + u32(6);
let l_40 = l_39 < u32(3192);
if l_40 {
let l_41 = workgroup_id.x * u32(3192);
let l_42 = l_41 + l_39;
let l_43 = &buffer_0_global[l_42];
let l_44 = atomicLoad(l_43);
l_mut_2 = l_mut_2 + l_44;
}
let l_45 = l_1 + u32(7);
let l_46 = l_45 < u32(3192);
if l_46 {
let l_47 = workgroup_id.x * u32(3192);
let l_48 = l_47 + l_45;
let l_49 = &buffer_0_global[l_48];
let l_50 = atomicLoad(l_49);
l_mut_2 = l_mut_2 + l_50;
}
let l_51 = l_1 + u32(8);
let l_52 = l_51 < u32(3192);
if l_52 {
let l_53 = workgroup_id.x * u32(3192);
let l_54 = l_53 + l_51;
let l_55 = &buffer_0_global[l_54];
let l_56 = atomicLoad(l_55);
l_mut_2 = l_mut_2 + l_56;
}
let l_57 = l_1 + u32(9);
let l_58 = l_57 < u32(3192);
if l_58 {
let l_59 = workgroup_id.x * u32(3192);
let l_60 = l_59 + l_57;
let l_61 = &buffer_0_global[l_60];
let l_62 = atomicLoad(l_61);
l_mut_2 = l_mut_2 + l_62;
}
let l_63 = l_1 + u32(10);
let l_64 = l_63 < u32(3192);
if l_64 {
let l_65 = workgroup_id.x * u32(3192);
let l_66 = l_65 + l_63;
let l_67 = &buffer_0_global[l_66];
let l_68 = atomicLoad(l_67);
l_mut_2 = l_mut_2 + l_68;
}
let l_69 = l_1 + u32(11);
let l_70 = l_69 < u32(3192);
if l_70 {
let l_71 = workgroup_id.x * u32(3192);
let l_72 = l_71 + l_69;
let l_73 = &buffer_0_global[l_72];
let l_74 = atomicLoad(l_73);
l_mut_2 = l_mut_2 + l_74;
}
let l_75 = l_1 + u32(12);
let l_76 = l_75 < u32(3192);
if l_76 {
let l_77 = workgroup_id.x * u32(3192);
let l_78 = l_77 + l_75;
let l_79 = &buffer_0_global[l_78];
let l_80 = atomicLoad(l_79);
l_mut_2 = l_mut_2 + l_80;
}
shared_memory_0[local_invocation_id.x] = l_mut_2;
workgroupBarrier();
let l_81 = local_invocation_id.x == u32(0);
if l_81 {
l_mut_2 = u32(0);
l_mut_82 = u32(0);
loop {
let l_83 = l_mut_82 < WORKGROUP_SIZE_X;
let l_84 = !l_83;
if l_84 {
break;
}
let l_85 = shared_memory_0[l_mut_82];
shared_memory_0[l_mut_82] = l_mut_2;
l_mut_2 = l_mut_2 + l_85;
l_mut_82 = l_mut_82 + u32(1);
}
}
workgroupBarrier();
let l_86 = shared_memory_0[local_invocation_id.x];
let l_87 = workgroup_id.x * info.scalars_u32[0];
let l_88 = l_86 + l_87;
l_mut_82 = l_88;
let l_89 = l_1 + u32(0);
let l_90 = l_89 < u32(3192);
if l_90 {
let l_91 = workgroup_id.x * u32(3192);
let l_92 = l_91 + l_89;
let l_93 = &buffer_0_global[l_92];
let l_94 = atomicLoad(l_93);
let l_95 = workgroup_id.x * u32(3192);
let l_96 = l_95 + l_89;
let l_97 = &buffer_1_global[l_96];
atomicStore(l_97,l_mut_82);
let l_98 = workgroup_id.x * u32(3192);
let l_99 = l_98 + l_89;
let l_100 = u32(4) * l_99;
buffer_2_global[l_100] = workgroup_id.x;
let l_101 = u32(4) * l_99;
let l_102 = l_101 + u32(1);
buffer_2_global[l_102] = l_89;
let l_103 = u32(4) * l_99;
let l_104 = l_103 + u32(2);
buffer_2_global[l_104] = l_mut_82;
let l_105 = u32(4) * l_99;
let l_106 = l_105 + u32(3);
let l_107 = l_mut_82 + l_94;
buffer_2_global[l_106] = l_107;
l_mut_82 = l_mut_82 + l_94;
}
let l_108 = l_1 + u32(1);
let l_109 = l_108 < u32(3192);
if l_109 {
let l_110 = workgroup_id.x * u32(3192);
let l_111 = l_110 + l_108;
let l_112 = &buffer_0_global[l_111];
let l_113 = atomicLoad(l_112);
let l_114 = workgroup_id.x * u32(3192);
let l_115 = l_114 + l_108;
let l_116 = &buffer_1_global[l_115];
atomicStore(l_116,l_mut_82);
let l_117 = workgroup_id.x * u32(3192);
let l_118 = l_117 + l_108;
let l_119 = u32(4) * l_118;
buffer_2_global[l_119] = workgroup_id.x;
let l_120 = u32(4) * l_118;
let l_121 = l_120 + u32(1);
buffer_2_global[l_121] = l_108;
let l_122 = u32(4) * l_118;
let l_123 = l_122 + u32(2);
buffer_2_global[l_123] = l_mut_82;
let l_124 = u32(4) * l_118;
let l_125 = l_124 + u32(3);
let l_126 = l_mut_82 + l_113;
buffer_2_global[l_125] = l_126;
l_mut_82 = l_mut_82 + l_113;
}
let l_127 = l_1 + u32(2);
let l_128 = l_127 < u32(3192);
if l_128 {
let l_129 = workgroup_id.x * u32(3192);
let l_130 = l_129 + l_127;
let l_131 = &buffer_0_global[l_130];
let l_132 = atomicLoad(l_131);
let l_133 = workgroup_id.x * u32(3192);
let l_134 = l_133 + l_127;
let l_135 = &buffer_1_global[l_134];
atomicStore(l_135,l_mut_82);
let l_136 = workgroup_id.x * u32(3192);
let l_137 = l_136 + l_127;
let l_138 = u32(4) * l_137;
buffer_2_global[l_138] = workgroup_id.x;
let l_139 = u32(4) * l_137;
let l_140 = l_139 + u32(1);
buffer_2_global[l_140] = l_127;
let l_141 = u32(4) * l_137;
let l_142 = l_141 + u32(2);
buffer_2_global[l_142] = l_mut_82;
let l_143 = u32(4) * l_137;
let l_144 = l_143 + u32(3);
let l_145 = l_mut_82 + l_132;
buffer_2_global[l_144] = l_145;
l_mut_82 = l_mut_82 + l_132;
}
let l_146 = l_1 + u32(3);
let l_147 = l_146 < u32(3192);
if l_147 {
let l_148 = workgroup_id.x * u32(3192);
let l_149 = l_148 + l_146;
let l_150 = &buffer_0_global[l_149];
let l_151 = atomicLoad(l_150);
let l_152 = workgroup_id.x * u32(3192);
let l_153 = l_152 + l_146;
let l_154 = &buffer_1_global[l_153];
atomicStore(l_154,l_mut_82);
let l_155 = workgroup_id.x * u32(3192);
let l_156 = l_155 + l_146;
let l_157 = u32(4) * l_156;
buffer_2_global[l_157] = workgroup_id.x;
let l_158 = u32(4) * l_156;
let l_159 = l_158 + u32(1);
buffer_2_global[l_159] = l_146;
let l_160 = u32(4) * l_156;
let l_161 = l_160 + u32(2);
buffer_2_global[l_161] = l_mut_82;
let l_162 = u32(4) * l_156;
let l_163 = l_162 + u32(3);
let l_164 = l_mut_82 + l_151;
buffer_2_global[l_163] = l_164;
l_mut_82 = l_mut_82 + l_151;
}
let l_165 = l_1 + u32(4);
let l_166 = l_165 < u32(3192);
if l_166 {
let l_167 = workgroup_id.x * u32(3192);
let l_168 = l_167 + l_165;
let l_169 = &buffer_0_global[l_168];
let l_170 = atomicLoad(l_169);
let l_171 = workgroup_id.x * u32(3192);
let l_172 = l_171 + l_165;
let l_173 = &buffer_1_global[l_172];
atomicStore(l_173,l_mut_82);
let l_174 = workgroup_id.x * u32(3192);
let l_175 = l_174 + l_165;
let l_176 = u32(4) * l_175;
buffer_2_global[l_176] = workgroup_id.x;
let l_177 = u32(4) * l_175;
let l_178 = l_177 + u32(1);
buffer_2_global[l_178] = l_165;
let l_179 = u32(4) * l_175;
let l_180 = l_179 + u32(2);
buffer_2_global[l_180] = l_mut_82;
let l_181 = u32(4) * l_175;
let l_182 = l_181 + u32(3);
let l_183 = l_mut_82 + l_170;
buffer_2_global[l_182] = l_183;
l_mut_82 = l_mut_82 + l_170;
}
let l_184 = l_1 + u32(5);
let l_185 = l_184 < u32(3192);
if l_185 {
let l_186 = workgroup_id.x * u32(3192);
let l_187 = l_186 + l_184;
let l_188 = &buffer_0_global[l_187];
let l_189 = atomicLoad(l_188);
let l_190 = workgroup_id.x * u32(3192);
let l_191 = l_190 + l_184;
let l_192 = &buffer_1_global[l_191];
atomicStore(l_192,l_mut_82);
let l_193 = workgroup_id.x * u32(3192);
let l_194 = l_193 + l_184;
let l_195 = u32(4) * l_194;
buffer_2_global[l_195] = workgroup_id.x;
let l_196 = u32(4) * l_194;
let l_197 = l_196 + u32(1);
buffer_2_global[l_197] = l_184;
let l_198 = u32(4) * l_194;
let l_199 = l_198 + u32(2);
buffer_2_global[l_199] = l_mut_82;
let l_200 = u32(4) * l_194;
let l_201 = l_200 + u32(3);
let l_202 = l_mut_82 + l_189;
buffer_2_global[l_201] = l_202;
l_mut_82 = l_mut_82 + l_189;
}
let l_203 = l_1 + u32(6);
let l_204 = l_203 < u32(3192);
if l_204 {
let l_205 = workgroup_id.x * u32(3192);
let l_206 = l_205 + l_203;
let l_207 = &buffer_0_global[l_206];
let l_208 = atomicLoad(l_207);
let l_209 = workgroup_id.x * u32(3192);
let l_210 = l_209 + l_203;
let l_211 = &buffer_1_global[l_210];
atomicStore(l_211,l_mut_82);
let l_212 = workgroup_id.x * u32(3192);
let l_213 = l_212 + l_203;
let l_214 = u32(4) * l_213;
buffer_2_global[l_214] = workgroup_id.x;
let l_215 = u32(4) * l_213;
let l_216 = l_215 + u32(1);
buffer_2_global[l_216] = l_203;
let l_217 = u32(4) * l_213;
let l_218 = l_217 + u32(2);
buffer_2_global[l_218] = l_mut_82;
let l_219 = u32(4) * l_213;
let l_220 = l_219 + u32(3);
let l_221 = l_mut_82 + l_208;
buffer_2_global[l_220] = l_221;
l_mut_82 = l_mut_82 + l_208;
}
let l_222 = l_1 + u32(7);
let l_223 = l_222 < u32(3192);
if l_223 {
let l_224 = workgroup_id.x * u32(3192);
let l_225 = l_224 + l_222;
let l_226 = &buffer_0_global[l_225];
let l_227 = atomicLoad(l_226);
let l_228 = workgroup_id.x * u32(3192);
let l_229 = l_228 + l_222;
let l_230 = &buffer_1_global[l_229];
atomicStore(l_230,l_mut_82);
let l_231 = workgroup_id.x * u32(3192);
let l_232 = l_231 + l_222;
let l_233 = u32(4) * l_232;
buffer_2_global[l_233] = workgroup_id.x;
let l_234 = u32(4) * l_232;
let l_235 = l_234 + u32(1);
buffer_2_global[l_235] = l_222;
let l_236 = u32(4) * l_232;
let l_237 = l_236 + u32(2);
buffer_2_global[l_237] = l_mut_82;
let l_238 = u32(4) * l_232;
let l_239 = l_238 + u32(3);
let l_240 = l_mut_82 + l_227;
buffer_2_global[l_239] = l_240;
l_mut_82 = l_mut_82 + l_227;
}
let l_241 = l_1 + u32(8);
let l_242 = l_241 < u32(3192);
if l_242 {
let l_243 = workgroup_id.x * u32(3192);
let l_244 = l_243 + l_241;
let l_245 = &buffer_0_global[l_244];
let l_246 = atomicLoad(l_245);
let l_247 = workgroup_id.x * u32(3192);
let l_248 = l_247 + l_241;
let l_249 = &buffer_1_global[l_248];
atomicStore(l_249,l_mut_82);
let l_250 = workgroup_id.x * u32(3192);
let l_251 = l_250 + l_241;
let l_252 = u32(4) * l_251;
buffer_2_global[l_252] = workgroup_id.x;
let l_253 = u32(4) * l_251;
let l_254 = l_253 + u32(1);
buffer_2_global[l_254] = l_241;
let l_255 = u32(4) * l_251;
let l_256 = l_255 + u32(2);
buffer_2_global[l_256] = l_mut_82;
let l_257 = u32(4) * l_251;
let l_258 = l_257 + u32(3);
let l_259 = l_mut_82 + l_246;
buffer_2_global[l_258] = l_259;
l_mut_82 = l_mut_82 + l_246;
}
let l_260 = l_1 + u32(9);
let l_261 = l_260 < u32(3192);
if l_261 {
let l_262 = workgroup_id.x * u32(3192);
let l_263 = l_262 + l_260;
let l_264 = &buffer_0_global[l_263];
let l_265 = atomicLoad(l_264);
let l_266 = workgroup_id.x * u32(3192);
let l_267 = l_266 + l_260;
let l_268 = &buffer_1_global[l_267];
atomicStore(l_268,l_mut_82);
let l_269 = workgroup_id.x * u32(3192);
let l_270 = l_269 + l_260;
let l_271 = u32(4) * l_270;
buffer_2_global[l_271] = workgroup_id.x;
let l_272 = u32(4) * l_270;
let l_273 = l_272 + u32(1);
buffer_2_global[l_273] = l_260;
let l_274 = u32(4) * l_270;
let l_275 = l_274 + u32(2);
buffer_2_global[l_275] = l_mut_82;
let l_276 = u32(4) * l_270;
let l_277 = l_276 + u32(3);
let l_278 = l_mut_82 + l_265;
buffer_2_global[l_277] = l_278;
l_mut_82 = l_mut_82 + l_265;
}
let l_279 = l_1 + u32(10);
let l_280 = l_279 < u32(3192);
if l_280 {
let l_281 = workgroup_id.x * u32(3192);
let l_282 = l_281 + l_279;
let l_283 = &buffer_0_global[l_282];
let l_284 = atomicLoad(l_283);
let l_285 = workgroup_id.x * u32(3192);
let l_286 = l_285 + l_279;
let l_287 = &buffer_1_global[l_286];
atomicStore(l_287,l_mut_82);
let l_288 = workgroup_id.x * u32(3192);
let l_289 = l_288 + l_279;
let l_290 = u32(4) * l_289;
buffer_2_global[l_290] = workgroup_id.x;
let l_291 = u32(4) * l_289;
let l_292 = l_291 + u32(1);
buffer_2_global[l_292] = l_279;
let l_293 = u32(4) * l_289;
let l_294 = l_293 + u32(2);
buffer_2_global[l_294] = l_mut_82;
let l_295 = u32(4) * l_289;
let l_296 = l_295 + u32(3);
let l_297 = l_mut_82 + l_284;
buffer_2_global[l_296] = l_297;
l_mut_82 = l_mut_82 + l_284;
}
let l_298 = l_1 + u32(11);
let l_299 = l_298 < u32(3192);
if l_299 {
let l_300 = workgroup_id.x * u32(3192);
let l_301 = l_300 + l_298;
let l_302 = &buffer_0_global[l_301];
let l_303 = atomicLoad(l_302);
let l_304 = workgroup_id.x * u32(3192);
let l_305 = l_304 + l_298;
let l_306 = &buffer_1_global[l_305];
atomicStore(l_306,l_mut_82);
let l_307 = workgroup_id.x * u32(3192);
let l_308 = l_307 + l_298;
let l_309 = u32(4) * l_308;
buffer_2_global[l_309] = workgroup_id.x;
let l_310 = u32(4) * l_308;
let l_311 = l_310 + u32(1);
buffer_2_global[l_311] = l_298;
let l_312 = u32(4) * l_308;
let l_313 = l_312 + u32(2);
buffer_2_global[l_313] = l_mut_82;
let l_314 = u32(4) * l_308;
let l_315 = l_314 + u32(3);
let l_316 = l_mut_82 + l_303;
buffer_2_global[l_315] = l_316;
l_mut_82 = l_mut_82 + l_303;
}
let l_317 = l_1 + u32(12);
let l_318 = l_317 < u32(3192);
if l_318 {
let l_319 = workgroup_id.x * u32(3192);
let l_320 = l_319 + l_317;
let l_321 = &buffer_0_global[l_320];
let l_322 = atomicLoad(l_321);
let l_323 = workgroup_id.x * u32(3192);
let l_324 = l_323 + l_317;
let l_325 = &buffer_1_global[l_324];
atomicStore(l_325,l_mut_82);
let l_326 = workgroup_id.x * u32(3192);
let l_327 = l_326 + l_317;
let l_328 = u32(4) * l_327;
buffer_2_global[l_328] = workgroup_id.x;
let l_329 = u32(4) * l_327;
let l_330 = l_329 + u32(1);
buffer_2_global[l_330] = l_317;
let l_331 = u32(4) * l_327;
let l_332 = l_331 + u32(2);
buffer_2_global[l_332] = l_mut_82;
let l_333 = u32(4) * l_327;
let l_334 = l_333 + u32(3);
let l_335 = l_mut_82 + l_322;
buffer_2_global[l_334] = l_335;
l_mut_82 = l_mut_82 + l_322;
}
workgroupBarrier();
let l_336 = local_invocation_id.x == u32(0);
if l_336 {
let l_337 = &buffer_3_global[u32(1)];
let l_338 = atomicAdd(l_337, u32(1));}
}
```
