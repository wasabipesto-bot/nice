
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
var l_mut_94: u32;
let l_1 = local_invocation_id.x * u32(15);
l_mut_2 = u32(0);
let l_3 = l_1 + u32(0);
let l_4 = l_3 < u32(3782);
if l_4 {
let l_5 = workgroup_id.x * u32(3782);
let l_6 = l_5 + l_3;
let l_7 = &buffer_0_global[l_6];
let l_8 = atomicLoad(l_7);
l_mut_2 = l_mut_2 + l_8;
}
let l_9 = l_1 + u32(1);
let l_10 = l_9 < u32(3782);
if l_10 {
let l_11 = workgroup_id.x * u32(3782);
let l_12 = l_11 + l_9;
let l_13 = &buffer_0_global[l_12];
let l_14 = atomicLoad(l_13);
l_mut_2 = l_mut_2 + l_14;
}
let l_15 = l_1 + u32(2);
let l_16 = l_15 < u32(3782);
if l_16 {
let l_17 = workgroup_id.x * u32(3782);
let l_18 = l_17 + l_15;
let l_19 = &buffer_0_global[l_18];
let l_20 = atomicLoad(l_19);
l_mut_2 = l_mut_2 + l_20;
}
let l_21 = l_1 + u32(3);
let l_22 = l_21 < u32(3782);
if l_22 {
let l_23 = workgroup_id.x * u32(3782);
let l_24 = l_23 + l_21;
let l_25 = &buffer_0_global[l_24];
let l_26 = atomicLoad(l_25);
l_mut_2 = l_mut_2 + l_26;
}
let l_27 = l_1 + u32(4);
let l_28 = l_27 < u32(3782);
if l_28 {
let l_29 = workgroup_id.x * u32(3782);
let l_30 = l_29 + l_27;
let l_31 = &buffer_0_global[l_30];
let l_32 = atomicLoad(l_31);
l_mut_2 = l_mut_2 + l_32;
}
let l_33 = l_1 + u32(5);
let l_34 = l_33 < u32(3782);
if l_34 {
let l_35 = workgroup_id.x * u32(3782);
let l_36 = l_35 + l_33;
let l_37 = &buffer_0_global[l_36];
let l_38 = atomicLoad(l_37);
l_mut_2 = l_mut_2 + l_38;
}
let l_39 = l_1 + u32(6);
let l_40 = l_39 < u32(3782);
if l_40 {
let l_41 = workgroup_id.x * u32(3782);
let l_42 = l_41 + l_39;
let l_43 = &buffer_0_global[l_42];
let l_44 = atomicLoad(l_43);
l_mut_2 = l_mut_2 + l_44;
}
let l_45 = l_1 + u32(7);
let l_46 = l_45 < u32(3782);
if l_46 {
let l_47 = workgroup_id.x * u32(3782);
let l_48 = l_47 + l_45;
let l_49 = &buffer_0_global[l_48];
let l_50 = atomicLoad(l_49);
l_mut_2 = l_mut_2 + l_50;
}
let l_51 = l_1 + u32(8);
let l_52 = l_51 < u32(3782);
if l_52 {
let l_53 = workgroup_id.x * u32(3782);
let l_54 = l_53 + l_51;
let l_55 = &buffer_0_global[l_54];
let l_56 = atomicLoad(l_55);
l_mut_2 = l_mut_2 + l_56;
}
let l_57 = l_1 + u32(9);
let l_58 = l_57 < u32(3782);
if l_58 {
let l_59 = workgroup_id.x * u32(3782);
let l_60 = l_59 + l_57;
let l_61 = &buffer_0_global[l_60];
let l_62 = atomicLoad(l_61);
l_mut_2 = l_mut_2 + l_62;
}
let l_63 = l_1 + u32(10);
let l_64 = l_63 < u32(3782);
if l_64 {
let l_65 = workgroup_id.x * u32(3782);
let l_66 = l_65 + l_63;
let l_67 = &buffer_0_global[l_66];
let l_68 = atomicLoad(l_67);
l_mut_2 = l_mut_2 + l_68;
}
let l_69 = l_1 + u32(11);
let l_70 = l_69 < u32(3782);
if l_70 {
let l_71 = workgroup_id.x * u32(3782);
let l_72 = l_71 + l_69;
let l_73 = &buffer_0_global[l_72];
let l_74 = atomicLoad(l_73);
l_mut_2 = l_mut_2 + l_74;
}
let l_75 = l_1 + u32(12);
let l_76 = l_75 < u32(3782);
if l_76 {
let l_77 = workgroup_id.x * u32(3782);
let l_78 = l_77 + l_75;
let l_79 = &buffer_0_global[l_78];
let l_80 = atomicLoad(l_79);
l_mut_2 = l_mut_2 + l_80;
}
let l_81 = l_1 + u32(13);
let l_82 = l_81 < u32(3782);
if l_82 {
let l_83 = workgroup_id.x * u32(3782);
let l_84 = l_83 + l_81;
let l_85 = &buffer_0_global[l_84];
let l_86 = atomicLoad(l_85);
l_mut_2 = l_mut_2 + l_86;
}
let l_87 = l_1 + u32(14);
let l_88 = l_87 < u32(3782);
if l_88 {
let l_89 = workgroup_id.x * u32(3782);
let l_90 = l_89 + l_87;
let l_91 = &buffer_0_global[l_90];
let l_92 = atomicLoad(l_91);
l_mut_2 = l_mut_2 + l_92;
}
shared_memory_0[local_invocation_id.x] = l_mut_2;
workgroupBarrier();
let l_93 = local_invocation_id.x == u32(0);
if l_93 {
l_mut_2 = u32(0);
l_mut_94 = u32(0);
loop {
let l_95 = l_mut_94 < WORKGROUP_SIZE_X;
let l_96 = !l_95;
if l_96 {
break;
}
let l_97 = shared_memory_0[l_mut_94];
shared_memory_0[l_mut_94] = l_mut_2;
l_mut_2 = l_mut_2 + l_97;
l_mut_94 = l_mut_94 + u32(1);
}
}
workgroupBarrier();
let l_98 = shared_memory_0[local_invocation_id.x];
let l_99 = workgroup_id.x * info.scalars_u32[0];
let l_100 = l_98 + l_99;
l_mut_94 = l_100;
let l_101 = l_1 + u32(0);
let l_102 = l_101 < u32(3782);
if l_102 {
let l_103 = workgroup_id.x * u32(3782);
let l_104 = l_103 + l_101;
let l_105 = &buffer_0_global[l_104];
let l_106 = atomicLoad(l_105);
let l_107 = workgroup_id.x * u32(3782);
let l_108 = l_107 + l_101;
let l_109 = &buffer_1_global[l_108];
atomicStore(l_109,l_mut_94);
let l_110 = workgroup_id.x * u32(3782);
let l_111 = l_110 + l_101;
let l_112 = u32(4) * l_111;
buffer_2_global[l_112] = workgroup_id.x;
let l_113 = u32(4) * l_111;
let l_114 = l_113 + u32(1);
buffer_2_global[l_114] = l_101;
let l_115 = u32(4) * l_111;
let l_116 = l_115 + u32(2);
buffer_2_global[l_116] = l_mut_94;
let l_117 = u32(4) * l_111;
let l_118 = l_117 + u32(3);
let l_119 = l_mut_94 + l_106;
buffer_2_global[l_118] = l_119;
l_mut_94 = l_mut_94 + l_106;
}
let l_120 = l_1 + u32(1);
let l_121 = l_120 < u32(3782);
if l_121 {
let l_122 = workgroup_id.x * u32(3782);
let l_123 = l_122 + l_120;
let l_124 = &buffer_0_global[l_123];
let l_125 = atomicLoad(l_124);
let l_126 = workgroup_id.x * u32(3782);
let l_127 = l_126 + l_120;
let l_128 = &buffer_1_global[l_127];
atomicStore(l_128,l_mut_94);
let l_129 = workgroup_id.x * u32(3782);
let l_130 = l_129 + l_120;
let l_131 = u32(4) * l_130;
buffer_2_global[l_131] = workgroup_id.x;
let l_132 = u32(4) * l_130;
let l_133 = l_132 + u32(1);
buffer_2_global[l_133] = l_120;
let l_134 = u32(4) * l_130;
let l_135 = l_134 + u32(2);
buffer_2_global[l_135] = l_mut_94;
let l_136 = u32(4) * l_130;
let l_137 = l_136 + u32(3);
let l_138 = l_mut_94 + l_125;
buffer_2_global[l_137] = l_138;
l_mut_94 = l_mut_94 + l_125;
}
let l_139 = l_1 + u32(2);
let l_140 = l_139 < u32(3782);
if l_140 {
let l_141 = workgroup_id.x * u32(3782);
let l_142 = l_141 + l_139;
let l_143 = &buffer_0_global[l_142];
let l_144 = atomicLoad(l_143);
let l_145 = workgroup_id.x * u32(3782);
let l_146 = l_145 + l_139;
let l_147 = &buffer_1_global[l_146];
atomicStore(l_147,l_mut_94);
let l_148 = workgroup_id.x * u32(3782);
let l_149 = l_148 + l_139;
let l_150 = u32(4) * l_149;
buffer_2_global[l_150] = workgroup_id.x;
let l_151 = u32(4) * l_149;
let l_152 = l_151 + u32(1);
buffer_2_global[l_152] = l_139;
let l_153 = u32(4) * l_149;
let l_154 = l_153 + u32(2);
buffer_2_global[l_154] = l_mut_94;
let l_155 = u32(4) * l_149;
let l_156 = l_155 + u32(3);
let l_157 = l_mut_94 + l_144;
buffer_2_global[l_156] = l_157;
l_mut_94 = l_mut_94 + l_144;
}
let l_158 = l_1 + u32(3);
let l_159 = l_158 < u32(3782);
if l_159 {
let l_160 = workgroup_id.x * u32(3782);
let l_161 = l_160 + l_158;
let l_162 = &buffer_0_global[l_161];
let l_163 = atomicLoad(l_162);
let l_164 = workgroup_id.x * u32(3782);
let l_165 = l_164 + l_158;
let l_166 = &buffer_1_global[l_165];
atomicStore(l_166,l_mut_94);
let l_167 = workgroup_id.x * u32(3782);
let l_168 = l_167 + l_158;
let l_169 = u32(4) * l_168;
buffer_2_global[l_169] = workgroup_id.x;
let l_170 = u32(4) * l_168;
let l_171 = l_170 + u32(1);
buffer_2_global[l_171] = l_158;
let l_172 = u32(4) * l_168;
let l_173 = l_172 + u32(2);
buffer_2_global[l_173] = l_mut_94;
let l_174 = u32(4) * l_168;
let l_175 = l_174 + u32(3);
let l_176 = l_mut_94 + l_163;
buffer_2_global[l_175] = l_176;
l_mut_94 = l_mut_94 + l_163;
}
let l_177 = l_1 + u32(4);
let l_178 = l_177 < u32(3782);
if l_178 {
let l_179 = workgroup_id.x * u32(3782);
let l_180 = l_179 + l_177;
let l_181 = &buffer_0_global[l_180];
let l_182 = atomicLoad(l_181);
let l_183 = workgroup_id.x * u32(3782);
let l_184 = l_183 + l_177;
let l_185 = &buffer_1_global[l_184];
atomicStore(l_185,l_mut_94);
let l_186 = workgroup_id.x * u32(3782);
let l_187 = l_186 + l_177;
let l_188 = u32(4) * l_187;
buffer_2_global[l_188] = workgroup_id.x;
let l_189 = u32(4) * l_187;
let l_190 = l_189 + u32(1);
buffer_2_global[l_190] = l_177;
let l_191 = u32(4) * l_187;
let l_192 = l_191 + u32(2);
buffer_2_global[l_192] = l_mut_94;
let l_193 = u32(4) * l_187;
let l_194 = l_193 + u32(3);
let l_195 = l_mut_94 + l_182;
buffer_2_global[l_194] = l_195;
l_mut_94 = l_mut_94 + l_182;
}
let l_196 = l_1 + u32(5);
let l_197 = l_196 < u32(3782);
if l_197 {
let l_198 = workgroup_id.x * u32(3782);
let l_199 = l_198 + l_196;
let l_200 = &buffer_0_global[l_199];
let l_201 = atomicLoad(l_200);
let l_202 = workgroup_id.x * u32(3782);
let l_203 = l_202 + l_196;
let l_204 = &buffer_1_global[l_203];
atomicStore(l_204,l_mut_94);
let l_205 = workgroup_id.x * u32(3782);
let l_206 = l_205 + l_196;
let l_207 = u32(4) * l_206;
buffer_2_global[l_207] = workgroup_id.x;
let l_208 = u32(4) * l_206;
let l_209 = l_208 + u32(1);
buffer_2_global[l_209] = l_196;
let l_210 = u32(4) * l_206;
let l_211 = l_210 + u32(2);
buffer_2_global[l_211] = l_mut_94;
let l_212 = u32(4) * l_206;
let l_213 = l_212 + u32(3);
let l_214 = l_mut_94 + l_201;
buffer_2_global[l_213] = l_214;
l_mut_94 = l_mut_94 + l_201;
}
let l_215 = l_1 + u32(6);
let l_216 = l_215 < u32(3782);
if l_216 {
let l_217 = workgroup_id.x * u32(3782);
let l_218 = l_217 + l_215;
let l_219 = &buffer_0_global[l_218];
let l_220 = atomicLoad(l_219);
let l_221 = workgroup_id.x * u32(3782);
let l_222 = l_221 + l_215;
let l_223 = &buffer_1_global[l_222];
atomicStore(l_223,l_mut_94);
let l_224 = workgroup_id.x * u32(3782);
let l_225 = l_224 + l_215;
let l_226 = u32(4) * l_225;
buffer_2_global[l_226] = workgroup_id.x;
let l_227 = u32(4) * l_225;
let l_228 = l_227 + u32(1);
buffer_2_global[l_228] = l_215;
let l_229 = u32(4) * l_225;
let l_230 = l_229 + u32(2);
buffer_2_global[l_230] = l_mut_94;
let l_231 = u32(4) * l_225;
let l_232 = l_231 + u32(3);
let l_233 = l_mut_94 + l_220;
buffer_2_global[l_232] = l_233;
l_mut_94 = l_mut_94 + l_220;
}
let l_234 = l_1 + u32(7);
let l_235 = l_234 < u32(3782);
if l_235 {
let l_236 = workgroup_id.x * u32(3782);
let l_237 = l_236 + l_234;
let l_238 = &buffer_0_global[l_237];
let l_239 = atomicLoad(l_238);
let l_240 = workgroup_id.x * u32(3782);
let l_241 = l_240 + l_234;
let l_242 = &buffer_1_global[l_241];
atomicStore(l_242,l_mut_94);
let l_243 = workgroup_id.x * u32(3782);
let l_244 = l_243 + l_234;
let l_245 = u32(4) * l_244;
buffer_2_global[l_245] = workgroup_id.x;
let l_246 = u32(4) * l_244;
let l_247 = l_246 + u32(1);
buffer_2_global[l_247] = l_234;
let l_248 = u32(4) * l_244;
let l_249 = l_248 + u32(2);
buffer_2_global[l_249] = l_mut_94;
let l_250 = u32(4) * l_244;
let l_251 = l_250 + u32(3);
let l_252 = l_mut_94 + l_239;
buffer_2_global[l_251] = l_252;
l_mut_94 = l_mut_94 + l_239;
}
let l_253 = l_1 + u32(8);
let l_254 = l_253 < u32(3782);
if l_254 {
let l_255 = workgroup_id.x * u32(3782);
let l_256 = l_255 + l_253;
let l_257 = &buffer_0_global[l_256];
let l_258 = atomicLoad(l_257);
let l_259 = workgroup_id.x * u32(3782);
let l_260 = l_259 + l_253;
let l_261 = &buffer_1_global[l_260];
atomicStore(l_261,l_mut_94);
let l_262 = workgroup_id.x * u32(3782);
let l_263 = l_262 + l_253;
let l_264 = u32(4) * l_263;
buffer_2_global[l_264] = workgroup_id.x;
let l_265 = u32(4) * l_263;
let l_266 = l_265 + u32(1);
buffer_2_global[l_266] = l_253;
let l_267 = u32(4) * l_263;
let l_268 = l_267 + u32(2);
buffer_2_global[l_268] = l_mut_94;
let l_269 = u32(4) * l_263;
let l_270 = l_269 + u32(3);
let l_271 = l_mut_94 + l_258;
buffer_2_global[l_270] = l_271;
l_mut_94 = l_mut_94 + l_258;
}
let l_272 = l_1 + u32(9);
let l_273 = l_272 < u32(3782);
if l_273 {
let l_274 = workgroup_id.x * u32(3782);
let l_275 = l_274 + l_272;
let l_276 = &buffer_0_global[l_275];
let l_277 = atomicLoad(l_276);
let l_278 = workgroup_id.x * u32(3782);
let l_279 = l_278 + l_272;
let l_280 = &buffer_1_global[l_279];
atomicStore(l_280,l_mut_94);
let l_281 = workgroup_id.x * u32(3782);
let l_282 = l_281 + l_272;
let l_283 = u32(4) * l_282;
buffer_2_global[l_283] = workgroup_id.x;
let l_284 = u32(4) * l_282;
let l_285 = l_284 + u32(1);
buffer_2_global[l_285] = l_272;
let l_286 = u32(4) * l_282;
let l_287 = l_286 + u32(2);
buffer_2_global[l_287] = l_mut_94;
let l_288 = u32(4) * l_282;
let l_289 = l_288 + u32(3);
let l_290 = l_mut_94 + l_277;
buffer_2_global[l_289] = l_290;
l_mut_94 = l_mut_94 + l_277;
}
let l_291 = l_1 + u32(10);
let l_292 = l_291 < u32(3782);
if l_292 {
let l_293 = workgroup_id.x * u32(3782);
let l_294 = l_293 + l_291;
let l_295 = &buffer_0_global[l_294];
let l_296 = atomicLoad(l_295);
let l_297 = workgroup_id.x * u32(3782);
let l_298 = l_297 + l_291;
let l_299 = &buffer_1_global[l_298];
atomicStore(l_299,l_mut_94);
let l_300 = workgroup_id.x * u32(3782);
let l_301 = l_300 + l_291;
let l_302 = u32(4) * l_301;
buffer_2_global[l_302] = workgroup_id.x;
let l_303 = u32(4) * l_301;
let l_304 = l_303 + u32(1);
buffer_2_global[l_304] = l_291;
let l_305 = u32(4) * l_301;
let l_306 = l_305 + u32(2);
buffer_2_global[l_306] = l_mut_94;
let l_307 = u32(4) * l_301;
let l_308 = l_307 + u32(3);
let l_309 = l_mut_94 + l_296;
buffer_2_global[l_308] = l_309;
l_mut_94 = l_mut_94 + l_296;
}
let l_310 = l_1 + u32(11);
let l_311 = l_310 < u32(3782);
if l_311 {
let l_312 = workgroup_id.x * u32(3782);
let l_313 = l_312 + l_310;
let l_314 = &buffer_0_global[l_313];
let l_315 = atomicLoad(l_314);
let l_316 = workgroup_id.x * u32(3782);
let l_317 = l_316 + l_310;
let l_318 = &buffer_1_global[l_317];
atomicStore(l_318,l_mut_94);
let l_319 = workgroup_id.x * u32(3782);
let l_320 = l_319 + l_310;
let l_321 = u32(4) * l_320;
buffer_2_global[l_321] = workgroup_id.x;
let l_322 = u32(4) * l_320;
let l_323 = l_322 + u32(1);
buffer_2_global[l_323] = l_310;
let l_324 = u32(4) * l_320;
let l_325 = l_324 + u32(2);
buffer_2_global[l_325] = l_mut_94;
let l_326 = u32(4) * l_320;
let l_327 = l_326 + u32(3);
let l_328 = l_mut_94 + l_315;
buffer_2_global[l_327] = l_328;
l_mut_94 = l_mut_94 + l_315;
}
let l_329 = l_1 + u32(12);
let l_330 = l_329 < u32(3782);
if l_330 {
let l_331 = workgroup_id.x * u32(3782);
let l_332 = l_331 + l_329;
let l_333 = &buffer_0_global[l_332];
let l_334 = atomicLoad(l_333);
let l_335 = workgroup_id.x * u32(3782);
let l_336 = l_335 + l_329;
let l_337 = &buffer_1_global[l_336];
atomicStore(l_337,l_mut_94);
let l_338 = workgroup_id.x * u32(3782);
let l_339 = l_338 + l_329;
let l_340 = u32(4) * l_339;
buffer_2_global[l_340] = workgroup_id.x;
let l_341 = u32(4) * l_339;
let l_342 = l_341 + u32(1);
buffer_2_global[l_342] = l_329;
let l_343 = u32(4) * l_339;
let l_344 = l_343 + u32(2);
buffer_2_global[l_344] = l_mut_94;
let l_345 = u32(4) * l_339;
let l_346 = l_345 + u32(3);
let l_347 = l_mut_94 + l_334;
buffer_2_global[l_346] = l_347;
l_mut_94 = l_mut_94 + l_334;
}
let l_348 = l_1 + u32(13);
let l_349 = l_348 < u32(3782);
if l_349 {
let l_350 = workgroup_id.x * u32(3782);
let l_351 = l_350 + l_348;
let l_352 = &buffer_0_global[l_351];
let l_353 = atomicLoad(l_352);
let l_354 = workgroup_id.x * u32(3782);
let l_355 = l_354 + l_348;
let l_356 = &buffer_1_global[l_355];
atomicStore(l_356,l_mut_94);
let l_357 = workgroup_id.x * u32(3782);
let l_358 = l_357 + l_348;
let l_359 = u32(4) * l_358;
buffer_2_global[l_359] = workgroup_id.x;
let l_360 = u32(4) * l_358;
let l_361 = l_360 + u32(1);
buffer_2_global[l_361] = l_348;
let l_362 = u32(4) * l_358;
let l_363 = l_362 + u32(2);
buffer_2_global[l_363] = l_mut_94;
let l_364 = u32(4) * l_358;
let l_365 = l_364 + u32(3);
let l_366 = l_mut_94 + l_353;
buffer_2_global[l_365] = l_366;
l_mut_94 = l_mut_94 + l_353;
}
let l_367 = l_1 + u32(14);
let l_368 = l_367 < u32(3782);
if l_368 {
let l_369 = workgroup_id.x * u32(3782);
let l_370 = l_369 + l_367;
let l_371 = &buffer_0_global[l_370];
let l_372 = atomicLoad(l_371);
let l_373 = workgroup_id.x * u32(3782);
let l_374 = l_373 + l_367;
let l_375 = &buffer_1_global[l_374];
atomicStore(l_375,l_mut_94);
let l_376 = workgroup_id.x * u32(3782);
let l_377 = l_376 + l_367;
let l_378 = u32(4) * l_377;
buffer_2_global[l_378] = workgroup_id.x;
let l_379 = u32(4) * l_377;
let l_380 = l_379 + u32(1);
buffer_2_global[l_380] = l_367;
let l_381 = u32(4) * l_377;
let l_382 = l_381 + u32(2);
buffer_2_global[l_382] = l_mut_94;
let l_383 = u32(4) * l_377;
let l_384 = l_383 + u32(3);
let l_385 = l_mut_94 + l_372;
buffer_2_global[l_384] = l_385;
l_mut_94 = l_mut_94 + l_372;
}
workgroupBarrier();
let l_386 = local_invocation_id.x == u32(0);
if l_386 {
let l_387 = &buffer_3_global[u32(1)];
let l_388 = atomicAdd(l_387, u32(1));}
}
```
