
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
var<storage, read_write> buffer_10_global: array<u32>;

@group(0)
@binding(11)
var<storage, read_write> buffer_11_global: array<atomic<u32>>;

@group(0)
@binding(12)
var<storage, read_write> buffer_12_global: array<u32>;

@group(0)
@binding(13)
var<storage, read_write> buffer_13_global: array<atomic<u32>>;

@group(0)
@binding(14)
var<storage, read_write> buffer_14_global: array<atomic<u32>>;

struct info_st {
   scalars_u32: array<u32, 4>,
   static_meta: array<u32, 30>,
}

@group(0)
@binding(15)
var<storage, read> info: info_st;

var<workgroup> shared_memory_8: array<atomic<u32>, 1>;

var<workgroup> shared_memory_1: array<u32, 256>;

var<workgroup> shared_memory_2: array<u32, 256>;

var<workgroup> shared_memory_3: array<u32, 256>;

var<workgroup> shared_memory_4: array<u32, 256>;

var<workgroup> shared_memory_5: array<u32, 256>;

var<workgroup> shared_memory_6: array<u32, 1024>;

var<workgroup> shared_memory_7: array<u32, 1024>;

var<workgroup> shared_memory_0: array<u32, 256>;

var<workgroup> shared_memory_9: array<u32, 1>;

const WORKGROUP_SIZE_X = 256u;
const WORKGROUP_SIZE_Y = 1u;
const WORKGROUP_SIZE_Z = 1u;

@compute
@workgroup_size(256, 1, 1)
fn join_kernel(
    @builtin(local_invocation_id) local_invocation_id: vec3<u32>,
    @builtin(num_workgroups) num_workgroups: vec3<u32>,
    @builtin(workgroup_id) workgroup_id: vec3<u32>,
    @builtin(subgroup_size) subgroup_size: u32,
    @builtin(subgroup_invocation_id) subgroup_invocation_id: u32,
) {
var a_67: array<u32, 2>;

var a_68: array<u32, 2>;

var a_69: array<u32, 2>;

var a_70: array<u32, 2>;

var a_160: array<u32, 2>;

var a_274: array<u32, 3>;

var a_280: array<u32, 3>;

var a_414: array<u32, 3>;

var a_418: array<u32, 3>;

var l_mut_12: u32;
var l_mut_45: u32;
var l_mut_49: u32;
var l_mut_64: u32;
var l_mut_94: u32;
var l_mut_101: u32;
var l_mut_161: u32;
var l_mut_162: u32;
var l_mut_188: u32;
var l_mut_249: u32;
var l_mut_253: u32;
var l_mut_254: u32;
var l_mut_255: u32;
var l_mut_275: u32;
var l_mut_276: u32;
var l_mut_281: u32;
var l_mut_282: u32;
var l_mut_86: u64;
var l_mut_307: bool;
let l_10 = local_invocation_id.x == u32(0);
if l_10 {
let l_11 = &shared_memory_8[u32(0)];
atomicStore(l_11,u32(0));
}
workgroupBarrier();
l_mut_12 = workgroup_id.x;
loop {
let l_13 = l_mut_12 < info.scalars_u32[0];
let l_14 = !l_13;
if l_14 {
break;
}
let l_15 = u32(4) * l_mut_12;
let l_16 = buffer_6_global[l_15];
let l_17 = u32(4) * l_mut_12;
let l_18 = l_17 + u32(1);
let l_19 = buffer_6_global[l_18];
let l_20 = u32(4) * l_mut_12;
let l_21 = l_20 + u32(2);
let l_22 = buffer_6_global[l_21];
let l_23 = u32(4) * l_mut_12;
let l_24 = l_23 + u32(3);
let l_25 = buffer_6_global[l_24];
let l_26 = l_19 / u32(9);
let l_27 = l_26 * u32(9);
let l_28 = l_19 - l_27;
let l_29 = buffer_3_global[l_28];
let l_30 = l_28 + u32(1);
let l_31 = buffer_3_global[l_30];
let l_32 = l_31 - l_29;
let l_33 = l_16 * u32(10);
let l_34 = l_33 + l_26;
let l_35 = l_34 * u32(9);
let l_36 = l_35 + l_28;
let l_37 = buffer_5_global[l_36];
let l_38 = l_16 * u32(10);
let l_39 = l_38 * info.scalars_u32[1];
let l_40 = u32(10) * l_29;
let l_41 = l_39 + l_40;
let l_42 = l_26 * l_32;
let l_43 = l_41 + l_42;
let l_44 = l_16 * info.scalars_u32[1];
l_mut_45 = l_22;
loop {
let l_46 = l_mut_45 < l_25;
let l_47 = !l_46;
if l_47 {
break;
}
let l_48 = l_25 - l_mut_45;
l_mut_49 = l_48;
let l_50 = l_mut_49 > u32(256);
if l_50 {
l_mut_49 = u32(256);
}
let l_51 = local_invocation_id.x < l_mut_49;
if l_51 {
let l_52 = l_mut_45 + local_invocation_id.x;
let l_53 = buffer_7_global[l_52];
let l_54 = u32(2) * l_53;
let l_55 = buffer_8_global[l_54];
shared_memory_1[local_invocation_id.x] = l_55;
let l_56 = u32(2) * l_53;
let l_57 = l_56 + u32(1);
let l_58 = buffer_8_global[l_57];
shared_memory_2[local_invocation_id.x] = l_58;
let l_59 = u32(2) * l_53;
let l_60 = buffer_9_global[l_59];
shared_memory_3[local_invocation_id.x] = l_60;
let l_61 = u32(2) * l_53;
let l_62 = l_61 + u32(1);
let l_63 = buffer_9_global[l_62];
shared_memory_4[local_invocation_id.x] = l_63;
shared_memory_5[local_invocation_id.x] = l_53;
}
workgroupBarrier();
l_mut_64 = u32(0);
loop {
let l_65 = l_mut_64 < l_37;
let l_66 = !l_65;
if l_66 {
break;
}
let l_71 = l_mut_64 + local_invocation_id.x;
let l_72 = l_71 + u32(0);
a_67[u32(0)] = u32(4294967295);
a_68[u32(0)] = u32(4294967295);
a_69[u32(0)] = u32(0);
a_70[u32(0)] = u32(0);
let l_73 = l_72 < l_37;
if l_73 {
a_70[u32(0)] = u32(4294967295);
let l_74 = l_43 + l_72;
let l_75 = buffer_4_global[l_74];
let l_76 = l_44 + l_75;
let l_77 = u32(2) * l_76;
let l_78 = l_77 + u32(1);
let l_79 = buffer_0_global[l_78];
let l_80 = u64(l_79);
let l_81 = l_80 << u32(bitcast<u64>(u64(32)));
let l_82 = u32(2) * l_76;
let l_83 = buffer_0_global[l_82];
let l_84 = u64(l_83);
let l_85 = l_81 | l_84;
l_mut_86 = l_85;
let l_87 = buffer_1_global[l_76];
let l_88 = l_87 & u32(255);
let l_89 = l_87 >> u32(16);
let l_90 = l_89 & u32(255);
let l_91 = l_26 * l_90;
let l_92 = l_88 + l_91;
let l_93 = l_92 % u32(10);
l_mut_94 = l_93;
let l_95 = l_87 >> u32(8);
let l_96 = l_95 & u32(255);
let l_97 = l_87 >> u32(24);
let l_98 = l_26 * l_97;
let l_99 = l_96 + l_98;
let l_100 = l_99 % u32(10);
l_mut_101 = l_100;
let l_102 = l_26 * l_26;
let l_103 = l_102 % u32(10);
l_mut_94 = l_103;
let l_104 = l_mut_94 * l_26;
let l_105 = l_104 % u32(10);
l_mut_101 = l_105;
let l_106 = u64(l_mut_94);
let l_107 = u64(1) << u32(bitcast<u64>(l_106));
let l_108 = u64(l_mut_101);
let l_109 = u64(1) << u32(bitcast<u64>(l_108));
let l_110 = l_107 | l_109;
l_mut_86 = l_mut_86 | l_110;
let l_111 = u32(bitcast<u64>(l_mut_86));
a_67[u32(0)] = l_111;
let l_112 = l_mut_86 >> u32(bitcast<u64>(u64(32)));
let l_113 = u32(bitcast<u64>(l_112));
a_68[u32(0)] = l_113;
let l_114 = buffer_2_global[l_75];
a_69[u32(0)] = l_114;
}
let l_115 = l_mut_64 + local_invocation_id.x;
let l_116 = l_115 + u32(256);
a_67[u32(1)] = u32(4294967295);
a_68[u32(1)] = u32(4294967295);
a_69[u32(1)] = u32(0);
a_70[u32(1)] = u32(0);
let l_117 = l_116 < l_37;
if l_117 {
a_70[u32(1)] = u32(4294967295);
let l_118 = l_43 + l_116;
let l_119 = buffer_4_global[l_118];
let l_120 = l_44 + l_119;
let l_121 = u32(2) * l_120;
let l_122 = l_121 + u32(1);
let l_123 = buffer_0_global[l_122];
let l_124 = u64(l_123);
let l_125 = l_124 << u32(bitcast<u64>(u64(32)));
let l_126 = u32(2) * l_120;
let l_127 = buffer_0_global[l_126];
let l_128 = u64(l_127);
let l_129 = l_125 | l_128;
l_mut_86 = l_129;
let l_130 = buffer_1_global[l_120];
let l_131 = l_130 & u32(255);
let l_132 = l_130 >> u32(16);
let l_133 = l_132 & u32(255);
let l_134 = l_26 * l_133;
let l_135 = l_131 + l_134;
let l_136 = l_135 % u32(10);
l_mut_101 = l_136;
let l_137 = l_130 >> u32(8);
let l_138 = l_137 & u32(255);
let l_139 = l_130 >> u32(24);
let l_140 = l_26 * l_139;
let l_141 = l_138 + l_140;
let l_142 = l_141 % u32(10);
l_mut_94 = l_142;
let l_143 = l_26 * l_26;
let l_144 = l_143 % u32(10);
l_mut_101 = l_144;
let l_145 = l_mut_101 * l_26;
let l_146 = l_145 % u32(10);
l_mut_94 = l_146;
let l_147 = u64(l_mut_101);
let l_148 = u64(1) << u32(bitcast<u64>(l_147));
let l_149 = u64(l_mut_94);
let l_150 = u64(1) << u32(bitcast<u64>(l_149));
let l_151 = l_148 | l_150;
l_mut_86 = l_mut_86 | l_151;
let l_152 = u32(bitcast<u64>(l_mut_86));
a_67[u32(1)] = l_152;
let l_153 = l_mut_86 >> u32(bitcast<u64>(u64(32)));
let l_154 = u32(bitcast<u64>(l_153));
a_68[u32(1)] = l_154;
let l_155 = buffer_2_global[l_119];
a_69[u32(1)] = l_155;
}
l_mut_101 = u32(0);
loop {
let l_156 = l_mut_101 < l_mut_49;
let l_157 = !l_156;
if l_157 {
break;
}
let l_158 = l_mut_101 + u32(32);
l_mut_94 = l_158;
let l_159 = l_mut_94 > l_mut_49;
if l_159 {
l_mut_94 = l_mut_49;
}
a_160[u32(0)] = u32(0);
a_160[u32(1)] = u32(0);
l_mut_161 = l_mut_101;
l_mut_162 = u32(1);
loop {
let l_163 = l_mut_161 < l_mut_94;
let l_164 = !l_163;
if l_164 {
break;
}
let l_165 = shared_memory_1[l_mut_161];
let l_166 = shared_memory_2[l_mut_161];
let l_167 = a_67[u32(0)];
let l_168 = l_167 & l_165;
let l_169 = a_68[u32(0)];
let l_170 = l_169 & l_166;
let l_171 = l_168 | l_170;
let l_172 = l_171 == u32(0);
let l_173 = select(u32(0), l_mut_162, l_172);
let l_174 = a_160[u32(0)];
let l_175 = l_174 | l_173;
a_160[u32(0)] = l_175;
let l_176 = a_67[u32(1)];
let l_177 = l_176 & l_165;
let l_178 = a_68[u32(1)];
let l_179 = l_178 & l_166;
let l_180 = l_177 | l_179;
let l_181 = l_180 == u32(0);
let l_182 = select(u32(0), l_mut_162, l_181);
let l_183 = a_160[u32(1)];
let l_184 = l_183 | l_182;
a_160[u32(1)] = l_184;
l_mut_162 = l_mut_162 << u32(1);
l_mut_161 = l_mut_161 + u32(1);
}
let l_185 = a_160[u32(0)];
let l_186 = a_70[u32(0)];
let l_187 = l_185 & l_186;
l_mut_188 = l_187;
let l_189 = a_69[u32(0)];
loop {
let l_190 = l_mut_188 != u32(0);
let l_191 = subgroupAny(l_190);
let l_192 = !l_191;
if l_192 {
break;
}
let l_193 = l_mut_188 != u32(0);
if l_193 {
let l_194 = countTrailingZeros(l_mut_188);
let l_195 = l_mut_101 + l_194;
let l_196 = l_mut_188 - u32(1);
l_mut_188 = l_mut_188 & l_196;
let l_197 = shared_memory_3[l_195];
let l_198 = l_189 >= l_197;
let l_199 = shared_memory_4[l_195];
let l_200 = l_189 < l_199;
let l_201 = l_198 && l_200;
if l_201 {
let l_202 = &shared_memory_8[u32(0)];
let l_203 = atomicAdd(l_202, u32(1));let l_204 = l_203 < u32(1024);
if l_204 {
let l_205 = shared_memory_5[l_195];
shared_memory_6[l_203] = l_205;
shared_memory_7[l_203] = l_189;
} else {
let l_206 = &buffer_11_global[u32(0)];
let l_207 = atomicAdd(l_206, u32(1));let l_208 = l_207 < info.scalars_u32[2];
if l_208 {
let l_209 = u32(2) * l_207;
let l_210 = shared_memory_5[l_195];
buffer_10_global[l_209] = l_210;
let l_211 = u32(2) * l_207;
let l_212 = l_211 + u32(1);
buffer_10_global[l_212] = l_189;
}
}
}
}
}
let l_213 = a_160[u32(1)];
let l_214 = a_70[u32(1)];
let l_215 = l_213 & l_214;
l_mut_188 = l_215;
let l_216 = a_69[u32(1)];
loop {
let l_217 = l_mut_188 != u32(0);
let l_218 = subgroupAny(l_217);
let l_219 = !l_218;
if l_219 {
break;
}
let l_220 = l_mut_188 != u32(0);
if l_220 {
let l_221 = countTrailingZeros(l_mut_188);
let l_222 = l_mut_101 + l_221;
let l_223 = l_mut_188 - u32(1);
l_mut_188 = l_mut_188 & l_223;
let l_224 = shared_memory_3[l_222];
let l_225 = l_216 >= l_224;
let l_226 = shared_memory_4[l_222];
let l_227 = l_216 < l_226;
let l_228 = l_225 && l_227;
if l_228 {
let l_229 = &shared_memory_8[u32(0)];
let l_230 = atomicAdd(l_229, u32(1));let l_231 = l_230 < u32(1024);
if l_231 {
let l_232 = shared_memory_5[l_222];
shared_memory_6[l_230] = l_232;
shared_memory_7[l_230] = l_216;
} else {
let l_233 = &buffer_11_global[u32(0)];
let l_234 = atomicAdd(l_233, u32(1));let l_235 = l_234 < info.scalars_u32[2];
if l_235 {
let l_236 = u32(2) * l_234;
let l_237 = shared_memory_5[l_222];
buffer_10_global[l_236] = l_237;
let l_238 = u32(2) * l_234;
let l_239 = l_238 + u32(1);
buffer_10_global[l_239] = l_216;
}
}
}
}
}
workgroupBarrier();
let l_240 = &shared_memory_8[u32(0)];
let l_241 = atomicLoad(l_240);
workgroupBarrier();
let l_242 = l_241 >= u32(512);
if l_242 {
l_mut_188 = l_241;
let l_243 = l_mut_188 > u32(1024);
if l_243 {
l_mut_188 = u32(1024);
}
let l_244 = local_invocation_id.x == u32(0);
if l_244 {
let l_245 = &buffer_13_global[u32(0)];
let l_246 = atomicAdd(l_245, l_mut_188);}
let l_247 = local_invocation_id.x / subgroup_size;
let l_248 = WORKGROUP_SIZE_X / subgroup_size;
l_mut_249 = u32(0);
loop {
let l_250 = l_mut_249 < l_mut_188;
let l_251 = !l_250;
if l_251 {
break;
}
let l_252 = l_mut_249 + local_invocation_id.x;
l_mut_253 = u32(0);
l_mut_254 = u32(0);
l_mut_255 = u32(0);
let l_256 = l_252 < l_mut_188;
if l_256 {
let l_257 = shared_memory_6[l_252];
l_mut_254 = l_257;
let l_258 = shared_memory_7[l_252];
l_mut_255 = l_258;
let l_259 = u32(2) * l_mut_254;
let l_260 = buffer_12_global[l_259];
l_mut_86 = u64(0);
let l_261 = u32(2) * l_mut_254;
let l_262 = l_261 + u32(1);
let l_263 = buffer_12_global[l_262];
let l_264 = l_263 != u32(0);
if l_264 {
let l_265 = u32(2) * l_mut_254;
let l_266 = l_265 + u32(1);
let l_267 = buffer_8_global[l_266];
let l_268 = u64(l_267);
let l_269 = l_268 << u32(bitcast<u64>(u64(32)));
let l_270 = u32(2) * l_mut_254;
let l_271 = buffer_8_global[l_270];
let l_272 = u64(l_271);
let l_273 = l_269 | l_272;
l_mut_86 = l_273;
}
l_mut_275 = l_mut_255;
l_mut_276 = l_260;
let l_277 = l_mut_276 % u32(10);
a_274[u32(0)] = l_277;
l_mut_276 = l_mut_276 / u32(10);
let l_278 = l_mut_276 % u32(10);
a_274[u32(1)] = l_278;
l_mut_276 = l_mut_276 / u32(10);
let l_279 = l_mut_276 % u32(10);
a_274[u32(2)] = l_279;
l_mut_276 = l_mut_276 / u32(10);
l_mut_281 = u32(0);
l_mut_282 = l_mut_281;
let l_283 = a_274[u32(0)];
let l_284 = a_274[u32(0)];
let l_285 = l_283 * l_284;
l_mut_282 = l_mut_282 + l_285;
let l_286 = l_mut_282 % u32(10);
a_280[u32(0)] = l_286;
let l_287 = l_mut_282 / u32(10);
l_mut_281 = l_287;
l_mut_282 = l_mut_281;
let l_288 = a_274[u32(0)];
let l_289 = a_274[u32(1)];
let l_290 = l_288 * l_289;
l_mut_282 = l_mut_282 + l_290;
let l_291 = a_274[u32(1)];
let l_292 = a_274[u32(0)];
let l_293 = l_291 * l_292;
l_mut_282 = l_mut_282 + l_293;
let l_294 = l_mut_282 % u32(10);
a_280[u32(1)] = l_294;
let l_295 = l_mut_282 / u32(10);
l_mut_281 = l_295;
l_mut_282 = l_mut_281;
let l_296 = a_274[u32(0)];
let l_297 = a_274[u32(2)];
let l_298 = l_296 * l_297;
l_mut_282 = l_mut_282 + l_298;
let l_299 = a_274[u32(1)];
let l_300 = a_274[u32(1)];
let l_301 = l_299 * l_300;
l_mut_282 = l_mut_282 + l_301;
let l_302 = a_274[u32(2)];
let l_303 = a_274[u32(0)];
let l_304 = l_302 * l_303;
l_mut_282 = l_mut_282 + l_304;
let l_305 = l_mut_282 % u32(10);
a_280[u32(2)] = l_305;
let l_306 = l_mut_282 / u32(10);
l_mut_281 = l_306;
l_mut_307 = bool(true);
l_mut_281 = u32(0);
l_mut_282 = l_mut_281;
let l_308 = a_280[u32(0)];
let l_309 = a_274[u32(0)];
let l_310 = l_308 * l_309;
l_mut_282 = l_mut_282 + l_310;
let l_311 = l_mut_282 % u32(10);
let l_312 = l_mut_282 / u32(10);
l_mut_281 = l_312;
let l_313 = a_280[u32(0)];
let l_314 = u64(l_313);
let l_315 = u64(1) << u32(bitcast<u64>(l_314));
let l_316 = u64(l_311);
let l_317 = u64(1) << u32(bitcast<u64>(l_316));
let l_318 = l_315 | l_317;
let l_319 = l_313 == l_311;
let l_320 = l_mut_86 & l_318;
let l_321 = l_320 != u64(0);
let l_322 = l_319 || l_321;
if l_322 {
l_mut_307 = bool(false);
}
l_mut_86 = l_mut_86 | l_318;
l_mut_282 = l_mut_281;
let l_323 = a_280[u32(0)];
let l_324 = a_274[u32(1)];
let l_325 = l_323 * l_324;
l_mut_282 = l_mut_282 + l_325;
let l_326 = a_280[u32(1)];
let l_327 = a_274[u32(0)];
let l_328 = l_326 * l_327;
l_mut_282 = l_mut_282 + l_328;
let l_329 = l_mut_282 % u32(10);
let l_330 = l_mut_282 / u32(10);
l_mut_281 = l_330;
let l_331 = a_280[u32(1)];
let l_332 = u64(l_331);
let l_333 = u64(1) << u32(bitcast<u64>(l_332));
let l_334 = u64(l_329);
let l_335 = u64(1) << u32(bitcast<u64>(l_334));
let l_336 = l_333 | l_335;
let l_337 = l_331 == l_329;
let l_338 = l_mut_86 & l_336;
let l_339 = l_338 != u64(0);
let l_340 = l_337 || l_339;
if l_340 {
l_mut_307 = bool(false);
}
l_mut_86 = l_mut_86 | l_336;
l_mut_282 = l_mut_281;
let l_341 = a_280[u32(0)];
let l_342 = a_274[u32(2)];
let l_343 = l_341 * l_342;
l_mut_282 = l_mut_282 + l_343;
let l_344 = a_280[u32(1)];
let l_345 = a_274[u32(1)];
let l_346 = l_344 * l_345;
l_mut_282 = l_mut_282 + l_346;
let l_347 = a_280[u32(2)];
let l_348 = a_274[u32(0)];
let l_349 = l_347 * l_348;
l_mut_282 = l_mut_282 + l_349;
let l_350 = l_mut_282 % u32(10);
let l_351 = l_mut_282 / u32(10);
l_mut_281 = l_351;
let l_352 = a_280[u32(2)];
let l_353 = u64(l_352);
let l_354 = u64(1) << u32(bitcast<u64>(l_353));
let l_355 = u64(l_350);
let l_356 = u64(1) << u32(bitcast<u64>(l_355));
let l_357 = l_354 | l_356;
let l_358 = l_352 == l_350;
let l_359 = l_mut_86 & l_357;
let l_360 = l_359 != u64(0);
let l_361 = l_358 || l_360;
if l_361 {
l_mut_307 = bool(false);
}
l_mut_86 = l_mut_86 | l_357;
if l_mut_307 {
l_mut_253 = u32(1);
}
}
let l_362 = subgroupExclusiveAdd(l_mut_253);
let l_363 = subgroupAdd(l_mut_253);
let l_364 = subgroup_invocation_id == u32(0);
if l_364 {
shared_memory_0[l_247] = l_363;
}
workgroupBarrier();
l_mut_282 = u32(0);
l_mut_281 = u32(0);
l_mut_276 = u32(0);
loop {
let l_365 = l_mut_276 < l_248;
let l_366 = !l_365;
if l_366 {
break;
}
let l_367 = shared_memory_0[l_mut_276];
let l_368 = l_mut_276 < l_247;
if l_368 {
l_mut_282 = l_mut_282 + l_367;
}
l_mut_281 = l_mut_281 + l_367;
l_mut_276 = l_mut_276 + u32(1);
}
let l_369 = local_invocation_id.x == u32(0);
let l_370 = l_mut_281 > u32(0);
let l_371 = l_369 && l_370;
if l_371 {
let l_372 = &buffer_11_global[u32(0)];
let l_373 = atomicAdd(l_372, l_mut_281);shared_memory_9[u32(0)] = l_373;
}
workgroupBarrier();
let l_374 = l_mut_253 != u32(0);
if l_374 {
let l_375 = shared_memory_9[u32(0)];
let l_376 = l_375 + l_mut_282;
let l_377 = l_376 + l_362;
let l_378 = l_377 < info.scalars_u32[2];
if l_378 {
let l_379 = u32(2) * l_377;
buffer_10_global[l_379] = l_mut_254;
let l_380 = u32(2) * l_377;
let l_381 = l_380 + u32(1);
buffer_10_global[l_381] = l_mut_255;
}
}
l_mut_249 = l_mut_249 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_382 = local_invocation_id.x == u32(0);
if l_382 {
let l_383 = &shared_memory_8[u32(0)];
atomicStore(l_383,u32(0));
}
workgroupBarrier();
}
l_mut_101 = l_mut_101 + u32(32);
}
l_mut_64 = l_mut_64 + u32(512);
}
l_mut_45 = l_mut_45 + u32(256);
workgroupBarrier();
}
l_mut_12 = l_mut_12 + num_workgroups.x;
}
workgroupBarrier();
let l_384 = &shared_memory_8[u32(0)];
let l_385 = atomicLoad(l_384);
let l_386 = l_385 > u32(0);
if l_386 {
l_mut_282 = l_385;
let l_387 = l_mut_282 > u32(1024);
if l_387 {
l_mut_282 = u32(1024);
}
let l_388 = local_invocation_id.x == u32(0);
if l_388 {
let l_389 = &buffer_13_global[u32(0)];
let l_390 = atomicAdd(l_389, l_mut_282);}
let l_391 = local_invocation_id.x / subgroup_size;
let l_392 = WORKGROUP_SIZE_X / subgroup_size;
l_mut_281 = u32(0);
loop {
let l_393 = l_mut_281 < l_mut_282;
let l_394 = !l_393;
if l_394 {
break;
}
let l_395 = l_mut_281 + local_invocation_id.x;
l_mut_276 = u32(0);
l_mut_275 = u32(0);
l_mut_255 = u32(0);
let l_396 = l_395 < l_mut_282;
if l_396 {
let l_397 = shared_memory_6[l_395];
l_mut_275 = l_397;
let l_398 = shared_memory_7[l_395];
l_mut_255 = l_398;
let l_399 = u32(2) * l_mut_275;
let l_400 = buffer_12_global[l_399];
l_mut_86 = u64(0);
let l_401 = u32(2) * l_mut_275;
let l_402 = l_401 + u32(1);
let l_403 = buffer_12_global[l_402];
let l_404 = l_403 != u32(0);
if l_404 {
let l_405 = u32(2) * l_mut_275;
let l_406 = l_405 + u32(1);
let l_407 = buffer_8_global[l_406];
let l_408 = u64(l_407);
let l_409 = l_408 << u32(bitcast<u64>(u64(32)));
let l_410 = u32(2) * l_mut_275;
let l_411 = buffer_8_global[l_410];
let l_412 = u64(l_411);
let l_413 = l_409 | l_412;
l_mut_86 = l_413;
}
l_mut_254 = l_mut_255;
l_mut_253 = l_400;
let l_415 = l_mut_253 % u32(10);
a_414[u32(0)] = l_415;
l_mut_253 = l_mut_253 / u32(10);
let l_416 = l_mut_253 % u32(10);
a_414[u32(1)] = l_416;
l_mut_253 = l_mut_253 / u32(10);
let l_417 = l_mut_253 % u32(10);
a_414[u32(2)] = l_417;
l_mut_253 = l_mut_253 / u32(10);
l_mut_249 = u32(0);
l_mut_188 = l_mut_249;
let l_419 = a_414[u32(0)];
let l_420 = a_414[u32(0)];
let l_421 = l_419 * l_420;
l_mut_188 = l_mut_188 + l_421;
let l_422 = l_mut_188 % u32(10);
a_418[u32(0)] = l_422;
let l_423 = l_mut_188 / u32(10);
l_mut_249 = l_423;
l_mut_188 = l_mut_249;
let l_424 = a_414[u32(0)];
let l_425 = a_414[u32(1)];
let l_426 = l_424 * l_425;
l_mut_188 = l_mut_188 + l_426;
let l_427 = a_414[u32(1)];
let l_428 = a_414[u32(0)];
let l_429 = l_427 * l_428;
l_mut_188 = l_mut_188 + l_429;
let l_430 = l_mut_188 % u32(10);
a_418[u32(1)] = l_430;
let l_431 = l_mut_188 / u32(10);
l_mut_249 = l_431;
l_mut_188 = l_mut_249;
let l_432 = a_414[u32(0)];
let l_433 = a_414[u32(2)];
let l_434 = l_432 * l_433;
l_mut_188 = l_mut_188 + l_434;
let l_435 = a_414[u32(1)];
let l_436 = a_414[u32(1)];
let l_437 = l_435 * l_436;
l_mut_188 = l_mut_188 + l_437;
let l_438 = a_414[u32(2)];
let l_439 = a_414[u32(0)];
let l_440 = l_438 * l_439;
l_mut_188 = l_mut_188 + l_440;
let l_441 = l_mut_188 % u32(10);
a_418[u32(2)] = l_441;
let l_442 = l_mut_188 / u32(10);
l_mut_249 = l_442;
l_mut_307 = bool(true);
l_mut_249 = u32(0);
l_mut_188 = l_mut_249;
let l_443 = a_418[u32(0)];
let l_444 = a_414[u32(0)];
let l_445 = l_443 * l_444;
l_mut_188 = l_mut_188 + l_445;
let l_446 = l_mut_188 % u32(10);
let l_447 = l_mut_188 / u32(10);
l_mut_249 = l_447;
let l_448 = a_418[u32(0)];
let l_449 = u64(l_448);
let l_450 = u64(1) << u32(bitcast<u64>(l_449));
let l_451 = u64(l_446);
let l_452 = u64(1) << u32(bitcast<u64>(l_451));
let l_453 = l_450 | l_452;
let l_454 = l_448 == l_446;
let l_455 = l_mut_86 & l_453;
let l_456 = l_455 != u64(0);
let l_457 = l_454 || l_456;
if l_457 {
l_mut_307 = bool(false);
}
l_mut_86 = l_mut_86 | l_453;
l_mut_188 = l_mut_249;
let l_458 = a_418[u32(0)];
let l_459 = a_414[u32(1)];
let l_460 = l_458 * l_459;
l_mut_188 = l_mut_188 + l_460;
let l_461 = a_418[u32(1)];
let l_462 = a_414[u32(0)];
let l_463 = l_461 * l_462;
l_mut_188 = l_mut_188 + l_463;
let l_464 = l_mut_188 % u32(10);
let l_465 = l_mut_188 / u32(10);
l_mut_249 = l_465;
let l_466 = a_418[u32(1)];
let l_467 = u64(l_466);
let l_468 = u64(1) << u32(bitcast<u64>(l_467));
let l_469 = u64(l_464);
let l_470 = u64(1) << u32(bitcast<u64>(l_469));
let l_471 = l_468 | l_470;
let l_472 = l_466 == l_464;
let l_473 = l_mut_86 & l_471;
let l_474 = l_473 != u64(0);
let l_475 = l_472 || l_474;
if l_475 {
l_mut_307 = bool(false);
}
l_mut_86 = l_mut_86 | l_471;
l_mut_188 = l_mut_249;
let l_476 = a_418[u32(0)];
let l_477 = a_414[u32(2)];
let l_478 = l_476 * l_477;
l_mut_188 = l_mut_188 + l_478;
let l_479 = a_418[u32(1)];
let l_480 = a_414[u32(1)];
let l_481 = l_479 * l_480;
l_mut_188 = l_mut_188 + l_481;
let l_482 = a_418[u32(2)];
let l_483 = a_414[u32(0)];
let l_484 = l_482 * l_483;
l_mut_188 = l_mut_188 + l_484;
let l_485 = l_mut_188 % u32(10);
let l_486 = l_mut_188 / u32(10);
l_mut_249 = l_486;
let l_487 = a_418[u32(2)];
let l_488 = u64(l_487);
let l_489 = u64(1) << u32(bitcast<u64>(l_488));
let l_490 = u64(l_485);
let l_491 = u64(1) << u32(bitcast<u64>(l_490));
let l_492 = l_489 | l_491;
let l_493 = l_487 == l_485;
let l_494 = l_mut_86 & l_492;
let l_495 = l_494 != u64(0);
let l_496 = l_493 || l_495;
if l_496 {
l_mut_307 = bool(false);
}
l_mut_86 = l_mut_86 | l_492;
if l_mut_307 {
l_mut_276 = u32(1);
}
}
let l_497 = subgroupExclusiveAdd(l_mut_276);
let l_498 = subgroupAdd(l_mut_276);
let l_499 = subgroup_invocation_id == u32(0);
if l_499 {
shared_memory_0[l_391] = l_498;
}
workgroupBarrier();
l_mut_254 = u32(0);
l_mut_253 = u32(0);
l_mut_249 = u32(0);
loop {
let l_500 = l_mut_249 < l_392;
let l_501 = !l_500;
if l_501 {
break;
}
let l_502 = shared_memory_0[l_mut_249];
let l_503 = l_mut_249 < l_391;
if l_503 {
l_mut_254 = l_mut_254 + l_502;
}
l_mut_253 = l_mut_253 + l_502;
l_mut_249 = l_mut_249 + u32(1);
}
let l_504 = local_invocation_id.x == u32(0);
let l_505 = l_mut_253 > u32(0);
let l_506 = l_504 && l_505;
if l_506 {
let l_507 = &buffer_11_global[u32(0)];
let l_508 = atomicAdd(l_507, l_mut_253);shared_memory_9[u32(0)] = l_508;
}
workgroupBarrier();
let l_509 = l_mut_276 != u32(0);
if l_509 {
let l_510 = shared_memory_9[u32(0)];
let l_511 = l_510 + l_mut_254;
let l_512 = l_511 + l_497;
let l_513 = l_512 < info.scalars_u32[2];
if l_513 {
let l_514 = u32(2) * l_512;
buffer_10_global[l_514] = l_mut_275;
let l_515 = u32(2) * l_512;
let l_516 = l_515 + u32(1);
buffer_10_global[l_516] = l_mut_255;
}
}
l_mut_281 = l_mut_281 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_517 = local_invocation_id.x == u32(0);
if l_517 {
let l_518 = &shared_memory_8[u32(0)];
atomicStore(l_518,u32(0));
}
}
workgroupBarrier();
let l_519 = local_invocation_id.x == u32(0);
if l_519 {
let l_520 = &buffer_14_global[u32(4)];
let l_521 = atomicAdd(l_520, u32(1));}
}
```
