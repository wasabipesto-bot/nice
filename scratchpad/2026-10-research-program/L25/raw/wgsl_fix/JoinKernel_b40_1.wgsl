
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

var a_152: array<u32, 2>;

var a_266: array<u32, 6>;

var a_275: array<u32, 6>;

var a_541: array<u32, 6>;

var a_548: array<u32, 6>;

var l_mut_86: u64;
var l_mut_12: u32;
var l_mut_45: u32;
var l_mut_49: u32;
var l_mut_64: u32;
var l_mut_94: u32;
var l_mut_101: u32;
var l_mut_153: u32;
var l_mut_154: u32;
var l_mut_180: u32;
var l_mut_241: u32;
var l_mut_245: u32;
var l_mut_246: u32;
var l_mut_247: u32;
var l_mut_267: u32;
var l_mut_269: u32;
var l_mut_276: u32;
var l_mut_277: u32;
var l_mut_353: bool;
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
let l_26 = l_19 / u32(39);
let l_27 = l_26 * u32(39);
let l_28 = l_19 - l_27;
let l_29 = buffer_3_global[l_28];
let l_30 = l_28 + u32(1);
let l_31 = buffer_3_global[l_30];
let l_32 = l_31 - l_29;
let l_33 = l_16 * u32(40);
let l_34 = l_33 + l_26;
let l_35 = l_34 * u32(39);
let l_36 = l_35 + l_28;
let l_37 = buffer_5_global[l_36];
let l_38 = l_16 * u32(40);
let l_39 = l_38 * info.scalars_u32[1];
let l_40 = u32(40) * l_29;
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
let l_93 = l_92 % u32(40);
l_mut_94 = l_93;
let l_95 = l_87 >> u32(8);
let l_96 = l_95 & u32(255);
let l_97 = l_87 >> u32(24);
let l_98 = l_26 * l_97;
let l_99 = l_96 + l_98;
let l_100 = l_99 % u32(40);
l_mut_101 = l_100;
let l_102 = u64(l_mut_94);
let l_103 = u64(1) << u32(bitcast<u64>(l_102));
let l_104 = u64(l_mut_101);
let l_105 = u64(1) << u32(bitcast<u64>(l_104));
let l_106 = l_103 | l_105;
l_mut_86 = l_mut_86 | l_106;
let l_107 = u32(bitcast<u64>(l_mut_86));
a_67[u32(0)] = l_107;
let l_108 = l_mut_86 >> u32(bitcast<u64>(u64(32)));
let l_109 = u32(bitcast<u64>(l_108));
a_68[u32(0)] = l_109;
let l_110 = buffer_2_global[l_75];
a_69[u32(0)] = l_110;
}
let l_111 = l_mut_64 + local_invocation_id.x;
let l_112 = l_111 + u32(256);
a_67[u32(1)] = u32(4294967295);
a_68[u32(1)] = u32(4294967295);
a_69[u32(1)] = u32(0);
a_70[u32(1)] = u32(0);
let l_113 = l_112 < l_37;
if l_113 {
a_70[u32(1)] = u32(4294967295);
let l_114 = l_43 + l_112;
let l_115 = buffer_4_global[l_114];
let l_116 = l_44 + l_115;
let l_117 = u32(2) * l_116;
let l_118 = l_117 + u32(1);
let l_119 = buffer_0_global[l_118];
let l_120 = u64(l_119);
let l_121 = l_120 << u32(bitcast<u64>(u64(32)));
let l_122 = u32(2) * l_116;
let l_123 = buffer_0_global[l_122];
let l_124 = u64(l_123);
let l_125 = l_121 | l_124;
l_mut_86 = l_125;
let l_126 = buffer_1_global[l_116];
let l_127 = l_126 & u32(255);
let l_128 = l_126 >> u32(16);
let l_129 = l_128 & u32(255);
let l_130 = l_26 * l_129;
let l_131 = l_127 + l_130;
let l_132 = l_131 % u32(40);
l_mut_101 = l_132;
let l_133 = l_126 >> u32(8);
let l_134 = l_133 & u32(255);
let l_135 = l_126 >> u32(24);
let l_136 = l_26 * l_135;
let l_137 = l_134 + l_136;
let l_138 = l_137 % u32(40);
l_mut_94 = l_138;
let l_139 = u64(l_mut_101);
let l_140 = u64(1) << u32(bitcast<u64>(l_139));
let l_141 = u64(l_mut_94);
let l_142 = u64(1) << u32(bitcast<u64>(l_141));
let l_143 = l_140 | l_142;
l_mut_86 = l_mut_86 | l_143;
let l_144 = u32(bitcast<u64>(l_mut_86));
a_67[u32(1)] = l_144;
let l_145 = l_mut_86 >> u32(bitcast<u64>(u64(32)));
let l_146 = u32(bitcast<u64>(l_145));
a_68[u32(1)] = l_146;
let l_147 = buffer_2_global[l_115];
a_69[u32(1)] = l_147;
}
l_mut_101 = u32(0);
loop {
let l_148 = l_mut_101 < l_mut_49;
let l_149 = !l_148;
if l_149 {
break;
}
let l_150 = l_mut_101 + u32(32);
l_mut_94 = l_150;
let l_151 = l_mut_94 > l_mut_49;
if l_151 {
l_mut_94 = l_mut_49;
}
a_152[u32(0)] = u32(0);
a_152[u32(1)] = u32(0);
l_mut_153 = l_mut_101;
l_mut_154 = u32(1);
loop {
let l_155 = l_mut_153 < l_mut_94;
let l_156 = !l_155;
if l_156 {
break;
}
let l_157 = shared_memory_1[l_mut_153];
let l_158 = shared_memory_2[l_mut_153];
let l_159 = a_67[u32(0)];
let l_160 = l_159 & l_157;
let l_161 = a_68[u32(0)];
let l_162 = l_161 & l_158;
let l_163 = l_160 | l_162;
let l_164 = l_163 == u32(0);
let l_165 = select(u32(0), l_mut_154, l_164);
let l_166 = a_152[u32(0)];
let l_167 = l_166 | l_165;
a_152[u32(0)] = l_167;
let l_168 = a_67[u32(1)];
let l_169 = l_168 & l_157;
let l_170 = a_68[u32(1)];
let l_171 = l_170 & l_158;
let l_172 = l_169 | l_171;
let l_173 = l_172 == u32(0);
let l_174 = select(u32(0), l_mut_154, l_173);
let l_175 = a_152[u32(1)];
let l_176 = l_175 | l_174;
a_152[u32(1)] = l_176;
l_mut_154 = l_mut_154 << u32(1);
l_mut_153 = l_mut_153 + u32(1);
}
let l_177 = a_152[u32(0)];
let l_178 = a_70[u32(0)];
let l_179 = l_177 & l_178;
l_mut_180 = l_179;
let l_181 = a_69[u32(0)];
loop {
let l_182 = l_mut_180 != u32(0);
let l_183 = subgroupAny(l_182);
let l_184 = !l_183;
if l_184 {
break;
}
let l_185 = l_mut_180 != u32(0);
if l_185 {
let l_186 = countTrailingZeros(l_mut_180);
let l_187 = l_mut_101 + l_186;
let l_188 = l_mut_180 - u32(1);
l_mut_180 = l_mut_180 & l_188;
let l_189 = shared_memory_3[l_187];
let l_190 = l_181 >= l_189;
let l_191 = shared_memory_4[l_187];
let l_192 = l_181 < l_191;
let l_193 = l_190 && l_192;
if l_193 {
let l_194 = &shared_memory_8[u32(0)];
let l_195 = atomicAdd(l_194, u32(1));let l_196 = l_195 < u32(1024);
if l_196 {
let l_197 = shared_memory_5[l_187];
shared_memory_6[l_195] = l_197;
shared_memory_7[l_195] = l_181;
} else {
let l_198 = &buffer_11_global[u32(0)];
let l_199 = atomicAdd(l_198, u32(1));let l_200 = l_199 < info.scalars_u32[2];
if l_200 {
let l_201 = u32(2) * l_199;
let l_202 = shared_memory_5[l_187];
buffer_10_global[l_201] = l_202;
let l_203 = u32(2) * l_199;
let l_204 = l_203 + u32(1);
buffer_10_global[l_204] = l_181;
}
}
}
}
}
let l_205 = a_152[u32(1)];
let l_206 = a_70[u32(1)];
let l_207 = l_205 & l_206;
l_mut_180 = l_207;
let l_208 = a_69[u32(1)];
loop {
let l_209 = l_mut_180 != u32(0);
let l_210 = subgroupAny(l_209);
let l_211 = !l_210;
if l_211 {
break;
}
let l_212 = l_mut_180 != u32(0);
if l_212 {
let l_213 = countTrailingZeros(l_mut_180);
let l_214 = l_mut_101 + l_213;
let l_215 = l_mut_180 - u32(1);
l_mut_180 = l_mut_180 & l_215;
let l_216 = shared_memory_3[l_214];
let l_217 = l_208 >= l_216;
let l_218 = shared_memory_4[l_214];
let l_219 = l_208 < l_218;
let l_220 = l_217 && l_219;
if l_220 {
let l_221 = &shared_memory_8[u32(0)];
let l_222 = atomicAdd(l_221, u32(1));let l_223 = l_222 < u32(1024);
if l_223 {
let l_224 = shared_memory_5[l_214];
shared_memory_6[l_222] = l_224;
shared_memory_7[l_222] = l_208;
} else {
let l_225 = &buffer_11_global[u32(0)];
let l_226 = atomicAdd(l_225, u32(1));let l_227 = l_226 < info.scalars_u32[2];
if l_227 {
let l_228 = u32(2) * l_226;
let l_229 = shared_memory_5[l_214];
buffer_10_global[l_228] = l_229;
let l_230 = u32(2) * l_226;
let l_231 = l_230 + u32(1);
buffer_10_global[l_231] = l_208;
}
}
}
}
}
workgroupBarrier();
let l_232 = &shared_memory_8[u32(0)];
let l_233 = atomicLoad(l_232);
workgroupBarrier();
let l_234 = l_233 >= u32(512);
if l_234 {
l_mut_180 = l_233;
let l_235 = l_mut_180 > u32(1024);
if l_235 {
l_mut_180 = u32(1024);
}
let l_236 = local_invocation_id.x == u32(0);
if l_236 {
let l_237 = &buffer_13_global[u32(0)];
let l_238 = atomicAdd(l_237, l_mut_180);}
let l_239 = local_invocation_id.x / subgroup_size;
let l_240 = WORKGROUP_SIZE_X / subgroup_size;
l_mut_241 = u32(0);
loop {
let l_242 = l_mut_241 < l_mut_180;
let l_243 = !l_242;
if l_243 {
break;
}
let l_244 = l_mut_241 + local_invocation_id.x;
l_mut_245 = u32(0);
l_mut_246 = u32(0);
l_mut_247 = u32(0);
let l_248 = l_244 < l_mut_180;
if l_248 {
let l_249 = shared_memory_6[l_244];
l_mut_246 = l_249;
let l_250 = shared_memory_7[l_244];
l_mut_247 = l_250;
let l_251 = u32(2) * l_mut_246;
let l_252 = buffer_12_global[l_251];
l_mut_86 = u64(0);
let l_253 = u32(2) * l_mut_246;
let l_254 = l_253 + u32(1);
let l_255 = buffer_12_global[l_254];
let l_256 = l_255 != u32(0);
if l_256 {
let l_257 = u32(2) * l_mut_246;
let l_258 = l_257 + u32(1);
let l_259 = buffer_8_global[l_258];
let l_260 = u64(l_259);
let l_261 = l_260 << u32(bitcast<u64>(u64(32)));
let l_262 = u32(2) * l_mut_246;
let l_263 = buffer_8_global[l_262];
let l_264 = u64(l_263);
let l_265 = l_261 | l_264;
l_mut_86 = l_265;
}
l_mut_267 = l_mut_247;
let l_268 = l_mut_267 % u32(40);
a_266[u32(0)] = l_268;
l_mut_267 = l_mut_267 / u32(40);
l_mut_269 = l_252;
let l_270 = l_mut_269 % u32(40);
a_266[u32(1)] = l_270;
l_mut_269 = l_mut_269 / u32(40);
let l_271 = l_mut_269 % u32(40);
a_266[u32(2)] = l_271;
l_mut_269 = l_mut_269 / u32(40);
let l_272 = l_mut_269 % u32(40);
a_266[u32(3)] = l_272;
l_mut_269 = l_mut_269 / u32(40);
let l_273 = l_mut_269 % u32(40);
a_266[u32(4)] = l_273;
l_mut_269 = l_mut_269 / u32(40);
let l_274 = l_mut_269 % u32(40);
a_266[u32(5)] = l_274;
l_mut_269 = l_mut_269 / u32(40);
l_mut_276 = u32(0);
l_mut_277 = l_mut_276;
let l_278 = a_266[u32(0)];
let l_279 = a_266[u32(0)];
let l_280 = l_278 * l_279;
l_mut_277 = l_mut_277 + l_280;
let l_281 = l_mut_277 % u32(40);
a_275[u32(0)] = l_281;
let l_282 = l_mut_277 / u32(40);
l_mut_276 = l_282;
l_mut_277 = l_mut_276;
let l_283 = a_266[u32(0)];
let l_284 = a_266[u32(1)];
let l_285 = l_283 * l_284;
l_mut_277 = l_mut_277 + l_285;
let l_286 = a_266[u32(1)];
let l_287 = a_266[u32(0)];
let l_288 = l_286 * l_287;
l_mut_277 = l_mut_277 + l_288;
let l_289 = l_mut_277 % u32(40);
a_275[u32(1)] = l_289;
let l_290 = l_mut_277 / u32(40);
l_mut_276 = l_290;
l_mut_277 = l_mut_276;
let l_291 = a_266[u32(0)];
let l_292 = a_266[u32(2)];
let l_293 = l_291 * l_292;
l_mut_277 = l_mut_277 + l_293;
let l_294 = a_266[u32(1)];
let l_295 = a_266[u32(1)];
let l_296 = l_294 * l_295;
l_mut_277 = l_mut_277 + l_296;
let l_297 = a_266[u32(2)];
let l_298 = a_266[u32(0)];
let l_299 = l_297 * l_298;
l_mut_277 = l_mut_277 + l_299;
let l_300 = l_mut_277 % u32(40);
a_275[u32(2)] = l_300;
let l_301 = l_mut_277 / u32(40);
l_mut_276 = l_301;
l_mut_277 = l_mut_276;
let l_302 = a_266[u32(0)];
let l_303 = a_266[u32(3)];
let l_304 = l_302 * l_303;
l_mut_277 = l_mut_277 + l_304;
let l_305 = a_266[u32(1)];
let l_306 = a_266[u32(2)];
let l_307 = l_305 * l_306;
l_mut_277 = l_mut_277 + l_307;
let l_308 = a_266[u32(2)];
let l_309 = a_266[u32(1)];
let l_310 = l_308 * l_309;
l_mut_277 = l_mut_277 + l_310;
let l_311 = a_266[u32(3)];
let l_312 = a_266[u32(0)];
let l_313 = l_311 * l_312;
l_mut_277 = l_mut_277 + l_313;
let l_314 = l_mut_277 % u32(40);
a_275[u32(3)] = l_314;
let l_315 = l_mut_277 / u32(40);
l_mut_276 = l_315;
l_mut_277 = l_mut_276;
let l_316 = a_266[u32(0)];
let l_317 = a_266[u32(4)];
let l_318 = l_316 * l_317;
l_mut_277 = l_mut_277 + l_318;
let l_319 = a_266[u32(1)];
let l_320 = a_266[u32(3)];
let l_321 = l_319 * l_320;
l_mut_277 = l_mut_277 + l_321;
let l_322 = a_266[u32(2)];
let l_323 = a_266[u32(2)];
let l_324 = l_322 * l_323;
l_mut_277 = l_mut_277 + l_324;
let l_325 = a_266[u32(3)];
let l_326 = a_266[u32(1)];
let l_327 = l_325 * l_326;
l_mut_277 = l_mut_277 + l_327;
let l_328 = a_266[u32(4)];
let l_329 = a_266[u32(0)];
let l_330 = l_328 * l_329;
l_mut_277 = l_mut_277 + l_330;
let l_331 = l_mut_277 % u32(40);
a_275[u32(4)] = l_331;
let l_332 = l_mut_277 / u32(40);
l_mut_276 = l_332;
l_mut_277 = l_mut_276;
let l_333 = a_266[u32(0)];
let l_334 = a_266[u32(5)];
let l_335 = l_333 * l_334;
l_mut_277 = l_mut_277 + l_335;
let l_336 = a_266[u32(1)];
let l_337 = a_266[u32(4)];
let l_338 = l_336 * l_337;
l_mut_277 = l_mut_277 + l_338;
let l_339 = a_266[u32(2)];
let l_340 = a_266[u32(3)];
let l_341 = l_339 * l_340;
l_mut_277 = l_mut_277 + l_341;
let l_342 = a_266[u32(3)];
let l_343 = a_266[u32(2)];
let l_344 = l_342 * l_343;
l_mut_277 = l_mut_277 + l_344;
let l_345 = a_266[u32(4)];
let l_346 = a_266[u32(1)];
let l_347 = l_345 * l_346;
l_mut_277 = l_mut_277 + l_347;
let l_348 = a_266[u32(5)];
let l_349 = a_266[u32(0)];
let l_350 = l_348 * l_349;
l_mut_277 = l_mut_277 + l_350;
let l_351 = l_mut_277 % u32(40);
a_275[u32(5)] = l_351;
let l_352 = l_mut_277 / u32(40);
l_mut_276 = l_352;
l_mut_353 = bool(true);
l_mut_276 = u32(0);
l_mut_277 = l_mut_276;
let l_354 = a_275[u32(0)];
let l_355 = a_266[u32(0)];
let l_356 = l_354 * l_355;
l_mut_277 = l_mut_277 + l_356;
let l_357 = l_mut_277 % u32(40);
let l_358 = l_mut_277 / u32(40);
l_mut_276 = l_358;
let l_359 = a_275[u32(0)];
let l_360 = u64(l_359);
let l_361 = u64(1) << u32(bitcast<u64>(l_360));
let l_362 = u64(l_357);
let l_363 = u64(1) << u32(bitcast<u64>(l_362));
let l_364 = l_361 | l_363;
let l_365 = l_359 == l_357;
let l_366 = l_mut_86 & l_364;
let l_367 = l_366 != u64(0);
let l_368 = l_365 || l_367;
if l_368 {
l_mut_353 = bool(false);
}
l_mut_86 = l_mut_86 | l_364;
l_mut_277 = l_mut_276;
let l_369 = a_275[u32(0)];
let l_370 = a_266[u32(1)];
let l_371 = l_369 * l_370;
l_mut_277 = l_mut_277 + l_371;
let l_372 = a_275[u32(1)];
let l_373 = a_266[u32(0)];
let l_374 = l_372 * l_373;
l_mut_277 = l_mut_277 + l_374;
let l_375 = l_mut_277 % u32(40);
let l_376 = l_mut_277 / u32(40);
l_mut_276 = l_376;
let l_377 = a_275[u32(1)];
let l_378 = u64(l_377);
let l_379 = u64(1) << u32(bitcast<u64>(l_378));
let l_380 = u64(l_375);
let l_381 = u64(1) << u32(bitcast<u64>(l_380));
let l_382 = l_379 | l_381;
let l_383 = l_377 == l_375;
let l_384 = l_mut_86 & l_382;
let l_385 = l_384 != u64(0);
let l_386 = l_383 || l_385;
if l_386 {
l_mut_353 = bool(false);
}
l_mut_86 = l_mut_86 | l_382;
l_mut_277 = l_mut_276;
let l_387 = a_275[u32(0)];
let l_388 = a_266[u32(2)];
let l_389 = l_387 * l_388;
l_mut_277 = l_mut_277 + l_389;
let l_390 = a_275[u32(1)];
let l_391 = a_266[u32(1)];
let l_392 = l_390 * l_391;
l_mut_277 = l_mut_277 + l_392;
let l_393 = a_275[u32(2)];
let l_394 = a_266[u32(0)];
let l_395 = l_393 * l_394;
l_mut_277 = l_mut_277 + l_395;
let l_396 = l_mut_277 % u32(40);
let l_397 = l_mut_277 / u32(40);
l_mut_276 = l_397;
let l_398 = a_275[u32(2)];
let l_399 = u64(l_398);
let l_400 = u64(1) << u32(bitcast<u64>(l_399));
let l_401 = u64(l_396);
let l_402 = u64(1) << u32(bitcast<u64>(l_401));
let l_403 = l_400 | l_402;
let l_404 = l_398 == l_396;
let l_405 = l_mut_86 & l_403;
let l_406 = l_405 != u64(0);
let l_407 = l_404 || l_406;
if l_407 {
l_mut_353 = bool(false);
}
l_mut_86 = l_mut_86 | l_403;
l_mut_277 = l_mut_276;
let l_408 = a_275[u32(0)];
let l_409 = a_266[u32(3)];
let l_410 = l_408 * l_409;
l_mut_277 = l_mut_277 + l_410;
let l_411 = a_275[u32(1)];
let l_412 = a_266[u32(2)];
let l_413 = l_411 * l_412;
l_mut_277 = l_mut_277 + l_413;
let l_414 = a_275[u32(2)];
let l_415 = a_266[u32(1)];
let l_416 = l_414 * l_415;
l_mut_277 = l_mut_277 + l_416;
let l_417 = a_275[u32(3)];
let l_418 = a_266[u32(0)];
let l_419 = l_417 * l_418;
l_mut_277 = l_mut_277 + l_419;
let l_420 = l_mut_277 % u32(40);
let l_421 = l_mut_277 / u32(40);
l_mut_276 = l_421;
let l_422 = a_275[u32(3)];
let l_423 = u64(l_422);
let l_424 = u64(1) << u32(bitcast<u64>(l_423));
let l_425 = u64(l_420);
let l_426 = u64(1) << u32(bitcast<u64>(l_425));
let l_427 = l_424 | l_426;
let l_428 = l_422 == l_420;
let l_429 = l_mut_86 & l_427;
let l_430 = l_429 != u64(0);
let l_431 = l_428 || l_430;
if l_431 {
l_mut_353 = bool(false);
}
l_mut_86 = l_mut_86 | l_427;
l_mut_277 = l_mut_276;
let l_432 = a_275[u32(0)];
let l_433 = a_266[u32(4)];
let l_434 = l_432 * l_433;
l_mut_277 = l_mut_277 + l_434;
let l_435 = a_275[u32(1)];
let l_436 = a_266[u32(3)];
let l_437 = l_435 * l_436;
l_mut_277 = l_mut_277 + l_437;
let l_438 = a_275[u32(2)];
let l_439 = a_266[u32(2)];
let l_440 = l_438 * l_439;
l_mut_277 = l_mut_277 + l_440;
let l_441 = a_275[u32(3)];
let l_442 = a_266[u32(1)];
let l_443 = l_441 * l_442;
l_mut_277 = l_mut_277 + l_443;
let l_444 = a_275[u32(4)];
let l_445 = a_266[u32(0)];
let l_446 = l_444 * l_445;
l_mut_277 = l_mut_277 + l_446;
let l_447 = l_mut_277 % u32(40);
let l_448 = l_mut_277 / u32(40);
l_mut_276 = l_448;
let l_449 = a_275[u32(4)];
let l_450 = u64(l_449);
let l_451 = u64(1) << u32(bitcast<u64>(l_450));
let l_452 = u64(l_447);
let l_453 = u64(1) << u32(bitcast<u64>(l_452));
let l_454 = l_451 | l_453;
let l_455 = l_449 == l_447;
let l_456 = l_mut_86 & l_454;
let l_457 = l_456 != u64(0);
let l_458 = l_455 || l_457;
if l_458 {
l_mut_353 = bool(false);
}
l_mut_86 = l_mut_86 | l_454;
l_mut_277 = l_mut_276;
let l_459 = a_275[u32(0)];
let l_460 = a_266[u32(5)];
let l_461 = l_459 * l_460;
l_mut_277 = l_mut_277 + l_461;
let l_462 = a_275[u32(1)];
let l_463 = a_266[u32(4)];
let l_464 = l_462 * l_463;
l_mut_277 = l_mut_277 + l_464;
let l_465 = a_275[u32(2)];
let l_466 = a_266[u32(3)];
let l_467 = l_465 * l_466;
l_mut_277 = l_mut_277 + l_467;
let l_468 = a_275[u32(3)];
let l_469 = a_266[u32(2)];
let l_470 = l_468 * l_469;
l_mut_277 = l_mut_277 + l_470;
let l_471 = a_275[u32(4)];
let l_472 = a_266[u32(1)];
let l_473 = l_471 * l_472;
l_mut_277 = l_mut_277 + l_473;
let l_474 = a_275[u32(5)];
let l_475 = a_266[u32(0)];
let l_476 = l_474 * l_475;
l_mut_277 = l_mut_277 + l_476;
let l_477 = l_mut_277 % u32(40);
let l_478 = l_mut_277 / u32(40);
l_mut_276 = l_478;
let l_479 = a_275[u32(5)];
let l_480 = u64(l_479);
let l_481 = u64(1) << u32(bitcast<u64>(l_480));
let l_482 = u64(l_477);
let l_483 = u64(1) << u32(bitcast<u64>(l_482));
let l_484 = l_481 | l_483;
let l_485 = l_479 == l_477;
let l_486 = l_mut_86 & l_484;
let l_487 = l_486 != u64(0);
let l_488 = l_485 || l_487;
if l_488 {
l_mut_353 = bool(false);
}
l_mut_86 = l_mut_86 | l_484;
if l_mut_353 {
l_mut_245 = u32(1);
}
}
let l_489 = subgroupExclusiveAdd(l_mut_245);
let l_490 = subgroupAdd(l_mut_245);
let l_491 = subgroup_invocation_id == u32(0);
if l_491 {
shared_memory_0[l_239] = l_490;
}
workgroupBarrier();
l_mut_277 = u32(0);
l_mut_276 = u32(0);
l_mut_269 = u32(0);
loop {
let l_492 = l_mut_269 < l_240;
let l_493 = !l_492;
if l_493 {
break;
}
let l_494 = shared_memory_0[l_mut_269];
let l_495 = l_mut_269 < l_239;
if l_495 {
l_mut_277 = l_mut_277 + l_494;
}
l_mut_276 = l_mut_276 + l_494;
l_mut_269 = l_mut_269 + u32(1);
}
let l_496 = local_invocation_id.x == u32(0);
let l_497 = l_mut_276 > u32(0);
let l_498 = l_496 && l_497;
if l_498 {
let l_499 = &buffer_11_global[u32(0)];
let l_500 = atomicAdd(l_499, l_mut_276);shared_memory_9[u32(0)] = l_500;
}
workgroupBarrier();
let l_501 = l_mut_245 != u32(0);
if l_501 {
let l_502 = shared_memory_9[u32(0)];
let l_503 = l_502 + l_mut_277;
let l_504 = l_503 + l_489;
let l_505 = l_504 < info.scalars_u32[2];
if l_505 {
let l_506 = u32(2) * l_504;
buffer_10_global[l_506] = l_mut_246;
let l_507 = u32(2) * l_504;
let l_508 = l_507 + u32(1);
buffer_10_global[l_508] = l_mut_247;
}
}
l_mut_241 = l_mut_241 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_509 = local_invocation_id.x == u32(0);
if l_509 {
let l_510 = &shared_memory_8[u32(0)];
atomicStore(l_510,u32(0));
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
let l_511 = &shared_memory_8[u32(0)];
let l_512 = atomicLoad(l_511);
let l_513 = l_512 > u32(0);
if l_513 {
l_mut_277 = l_512;
let l_514 = l_mut_277 > u32(1024);
if l_514 {
l_mut_277 = u32(1024);
}
let l_515 = local_invocation_id.x == u32(0);
if l_515 {
let l_516 = &buffer_13_global[u32(0)];
let l_517 = atomicAdd(l_516, l_mut_277);}
let l_518 = local_invocation_id.x / subgroup_size;
let l_519 = WORKGROUP_SIZE_X / subgroup_size;
l_mut_276 = u32(0);
loop {
let l_520 = l_mut_276 < l_mut_277;
let l_521 = !l_520;
if l_521 {
break;
}
let l_522 = l_mut_276 + local_invocation_id.x;
l_mut_269 = u32(0);
l_mut_267 = u32(0);
l_mut_247 = u32(0);
let l_523 = l_522 < l_mut_277;
if l_523 {
let l_524 = shared_memory_6[l_522];
l_mut_267 = l_524;
let l_525 = shared_memory_7[l_522];
l_mut_247 = l_525;
let l_526 = u32(2) * l_mut_267;
let l_527 = buffer_12_global[l_526];
l_mut_86 = u64(0);
let l_528 = u32(2) * l_mut_267;
let l_529 = l_528 + u32(1);
let l_530 = buffer_12_global[l_529];
let l_531 = l_530 != u32(0);
if l_531 {
let l_532 = u32(2) * l_mut_267;
let l_533 = l_532 + u32(1);
let l_534 = buffer_8_global[l_533];
let l_535 = u64(l_534);
let l_536 = l_535 << u32(bitcast<u64>(u64(32)));
let l_537 = u32(2) * l_mut_267;
let l_538 = buffer_8_global[l_537];
let l_539 = u64(l_538);
let l_540 = l_536 | l_539;
l_mut_86 = l_540;
}
l_mut_246 = l_mut_247;
let l_542 = l_mut_246 % u32(40);
a_541[u32(0)] = l_542;
l_mut_246 = l_mut_246 / u32(40);
l_mut_245 = l_527;
let l_543 = l_mut_245 % u32(40);
a_541[u32(1)] = l_543;
l_mut_245 = l_mut_245 / u32(40);
let l_544 = l_mut_245 % u32(40);
a_541[u32(2)] = l_544;
l_mut_245 = l_mut_245 / u32(40);
let l_545 = l_mut_245 % u32(40);
a_541[u32(3)] = l_545;
l_mut_245 = l_mut_245 / u32(40);
let l_546 = l_mut_245 % u32(40);
a_541[u32(4)] = l_546;
l_mut_245 = l_mut_245 / u32(40);
let l_547 = l_mut_245 % u32(40);
a_541[u32(5)] = l_547;
l_mut_245 = l_mut_245 / u32(40);
l_mut_241 = u32(0);
l_mut_180 = l_mut_241;
let l_549 = a_541[u32(0)];
let l_550 = a_541[u32(0)];
let l_551 = l_549 * l_550;
l_mut_180 = l_mut_180 + l_551;
let l_552 = l_mut_180 % u32(40);
a_548[u32(0)] = l_552;
let l_553 = l_mut_180 / u32(40);
l_mut_241 = l_553;
l_mut_180 = l_mut_241;
let l_554 = a_541[u32(0)];
let l_555 = a_541[u32(1)];
let l_556 = l_554 * l_555;
l_mut_180 = l_mut_180 + l_556;
let l_557 = a_541[u32(1)];
let l_558 = a_541[u32(0)];
let l_559 = l_557 * l_558;
l_mut_180 = l_mut_180 + l_559;
let l_560 = l_mut_180 % u32(40);
a_548[u32(1)] = l_560;
let l_561 = l_mut_180 / u32(40);
l_mut_241 = l_561;
l_mut_180 = l_mut_241;
let l_562 = a_541[u32(0)];
let l_563 = a_541[u32(2)];
let l_564 = l_562 * l_563;
l_mut_180 = l_mut_180 + l_564;
let l_565 = a_541[u32(1)];
let l_566 = a_541[u32(1)];
let l_567 = l_565 * l_566;
l_mut_180 = l_mut_180 + l_567;
let l_568 = a_541[u32(2)];
let l_569 = a_541[u32(0)];
let l_570 = l_568 * l_569;
l_mut_180 = l_mut_180 + l_570;
let l_571 = l_mut_180 % u32(40);
a_548[u32(2)] = l_571;
let l_572 = l_mut_180 / u32(40);
l_mut_241 = l_572;
l_mut_180 = l_mut_241;
let l_573 = a_541[u32(0)];
let l_574 = a_541[u32(3)];
let l_575 = l_573 * l_574;
l_mut_180 = l_mut_180 + l_575;
let l_576 = a_541[u32(1)];
let l_577 = a_541[u32(2)];
let l_578 = l_576 * l_577;
l_mut_180 = l_mut_180 + l_578;
let l_579 = a_541[u32(2)];
let l_580 = a_541[u32(1)];
let l_581 = l_579 * l_580;
l_mut_180 = l_mut_180 + l_581;
let l_582 = a_541[u32(3)];
let l_583 = a_541[u32(0)];
let l_584 = l_582 * l_583;
l_mut_180 = l_mut_180 + l_584;
let l_585 = l_mut_180 % u32(40);
a_548[u32(3)] = l_585;
let l_586 = l_mut_180 / u32(40);
l_mut_241 = l_586;
l_mut_180 = l_mut_241;
let l_587 = a_541[u32(0)];
let l_588 = a_541[u32(4)];
let l_589 = l_587 * l_588;
l_mut_180 = l_mut_180 + l_589;
let l_590 = a_541[u32(1)];
let l_591 = a_541[u32(3)];
let l_592 = l_590 * l_591;
l_mut_180 = l_mut_180 + l_592;
let l_593 = a_541[u32(2)];
let l_594 = a_541[u32(2)];
let l_595 = l_593 * l_594;
l_mut_180 = l_mut_180 + l_595;
let l_596 = a_541[u32(3)];
let l_597 = a_541[u32(1)];
let l_598 = l_596 * l_597;
l_mut_180 = l_mut_180 + l_598;
let l_599 = a_541[u32(4)];
let l_600 = a_541[u32(0)];
let l_601 = l_599 * l_600;
l_mut_180 = l_mut_180 + l_601;
let l_602 = l_mut_180 % u32(40);
a_548[u32(4)] = l_602;
let l_603 = l_mut_180 / u32(40);
l_mut_241 = l_603;
l_mut_180 = l_mut_241;
let l_604 = a_541[u32(0)];
let l_605 = a_541[u32(5)];
let l_606 = l_604 * l_605;
l_mut_180 = l_mut_180 + l_606;
let l_607 = a_541[u32(1)];
let l_608 = a_541[u32(4)];
let l_609 = l_607 * l_608;
l_mut_180 = l_mut_180 + l_609;
let l_610 = a_541[u32(2)];
let l_611 = a_541[u32(3)];
let l_612 = l_610 * l_611;
l_mut_180 = l_mut_180 + l_612;
let l_613 = a_541[u32(3)];
let l_614 = a_541[u32(2)];
let l_615 = l_613 * l_614;
l_mut_180 = l_mut_180 + l_615;
let l_616 = a_541[u32(4)];
let l_617 = a_541[u32(1)];
let l_618 = l_616 * l_617;
l_mut_180 = l_mut_180 + l_618;
let l_619 = a_541[u32(5)];
let l_620 = a_541[u32(0)];
let l_621 = l_619 * l_620;
l_mut_180 = l_mut_180 + l_621;
let l_622 = l_mut_180 % u32(40);
a_548[u32(5)] = l_622;
let l_623 = l_mut_180 / u32(40);
l_mut_241 = l_623;
l_mut_353 = bool(true);
l_mut_241 = u32(0);
l_mut_180 = l_mut_241;
let l_624 = a_548[u32(0)];
let l_625 = a_541[u32(0)];
let l_626 = l_624 * l_625;
l_mut_180 = l_mut_180 + l_626;
let l_627 = l_mut_180 % u32(40);
let l_628 = l_mut_180 / u32(40);
l_mut_241 = l_628;
let l_629 = a_548[u32(0)];
let l_630 = u64(l_629);
let l_631 = u64(1) << u32(bitcast<u64>(l_630));
let l_632 = u64(l_627);
let l_633 = u64(1) << u32(bitcast<u64>(l_632));
let l_634 = l_631 | l_633;
let l_635 = l_629 == l_627;
let l_636 = l_mut_86 & l_634;
let l_637 = l_636 != u64(0);
let l_638 = l_635 || l_637;
if l_638 {
l_mut_353 = bool(false);
}
l_mut_86 = l_mut_86 | l_634;
l_mut_180 = l_mut_241;
let l_639 = a_548[u32(0)];
let l_640 = a_541[u32(1)];
let l_641 = l_639 * l_640;
l_mut_180 = l_mut_180 + l_641;
let l_642 = a_548[u32(1)];
let l_643 = a_541[u32(0)];
let l_644 = l_642 * l_643;
l_mut_180 = l_mut_180 + l_644;
let l_645 = l_mut_180 % u32(40);
let l_646 = l_mut_180 / u32(40);
l_mut_241 = l_646;
let l_647 = a_548[u32(1)];
let l_648 = u64(l_647);
let l_649 = u64(1) << u32(bitcast<u64>(l_648));
let l_650 = u64(l_645);
let l_651 = u64(1) << u32(bitcast<u64>(l_650));
let l_652 = l_649 | l_651;
let l_653 = l_647 == l_645;
let l_654 = l_mut_86 & l_652;
let l_655 = l_654 != u64(0);
let l_656 = l_653 || l_655;
if l_656 {
l_mut_353 = bool(false);
}
l_mut_86 = l_mut_86 | l_652;
l_mut_180 = l_mut_241;
let l_657 = a_548[u32(0)];
let l_658 = a_541[u32(2)];
let l_659 = l_657 * l_658;
l_mut_180 = l_mut_180 + l_659;
let l_660 = a_548[u32(1)];
let l_661 = a_541[u32(1)];
let l_662 = l_660 * l_661;
l_mut_180 = l_mut_180 + l_662;
let l_663 = a_548[u32(2)];
let l_664 = a_541[u32(0)];
let l_665 = l_663 * l_664;
l_mut_180 = l_mut_180 + l_665;
let l_666 = l_mut_180 % u32(40);
let l_667 = l_mut_180 / u32(40);
l_mut_241 = l_667;
let l_668 = a_548[u32(2)];
let l_669 = u64(l_668);
let l_670 = u64(1) << u32(bitcast<u64>(l_669));
let l_671 = u64(l_666);
let l_672 = u64(1) << u32(bitcast<u64>(l_671));
let l_673 = l_670 | l_672;
let l_674 = l_668 == l_666;
let l_675 = l_mut_86 & l_673;
let l_676 = l_675 != u64(0);
let l_677 = l_674 || l_676;
if l_677 {
l_mut_353 = bool(false);
}
l_mut_86 = l_mut_86 | l_673;
l_mut_180 = l_mut_241;
let l_678 = a_548[u32(0)];
let l_679 = a_541[u32(3)];
let l_680 = l_678 * l_679;
l_mut_180 = l_mut_180 + l_680;
let l_681 = a_548[u32(1)];
let l_682 = a_541[u32(2)];
let l_683 = l_681 * l_682;
l_mut_180 = l_mut_180 + l_683;
let l_684 = a_548[u32(2)];
let l_685 = a_541[u32(1)];
let l_686 = l_684 * l_685;
l_mut_180 = l_mut_180 + l_686;
let l_687 = a_548[u32(3)];
let l_688 = a_541[u32(0)];
let l_689 = l_687 * l_688;
l_mut_180 = l_mut_180 + l_689;
let l_690 = l_mut_180 % u32(40);
let l_691 = l_mut_180 / u32(40);
l_mut_241 = l_691;
let l_692 = a_548[u32(3)];
let l_693 = u64(l_692);
let l_694 = u64(1) << u32(bitcast<u64>(l_693));
let l_695 = u64(l_690);
let l_696 = u64(1) << u32(bitcast<u64>(l_695));
let l_697 = l_694 | l_696;
let l_698 = l_692 == l_690;
let l_699 = l_mut_86 & l_697;
let l_700 = l_699 != u64(0);
let l_701 = l_698 || l_700;
if l_701 {
l_mut_353 = bool(false);
}
l_mut_86 = l_mut_86 | l_697;
l_mut_180 = l_mut_241;
let l_702 = a_548[u32(0)];
let l_703 = a_541[u32(4)];
let l_704 = l_702 * l_703;
l_mut_180 = l_mut_180 + l_704;
let l_705 = a_548[u32(1)];
let l_706 = a_541[u32(3)];
let l_707 = l_705 * l_706;
l_mut_180 = l_mut_180 + l_707;
let l_708 = a_548[u32(2)];
let l_709 = a_541[u32(2)];
let l_710 = l_708 * l_709;
l_mut_180 = l_mut_180 + l_710;
let l_711 = a_548[u32(3)];
let l_712 = a_541[u32(1)];
let l_713 = l_711 * l_712;
l_mut_180 = l_mut_180 + l_713;
let l_714 = a_548[u32(4)];
let l_715 = a_541[u32(0)];
let l_716 = l_714 * l_715;
l_mut_180 = l_mut_180 + l_716;
let l_717 = l_mut_180 % u32(40);
let l_718 = l_mut_180 / u32(40);
l_mut_241 = l_718;
let l_719 = a_548[u32(4)];
let l_720 = u64(l_719);
let l_721 = u64(1) << u32(bitcast<u64>(l_720));
let l_722 = u64(l_717);
let l_723 = u64(1) << u32(bitcast<u64>(l_722));
let l_724 = l_721 | l_723;
let l_725 = l_719 == l_717;
let l_726 = l_mut_86 & l_724;
let l_727 = l_726 != u64(0);
let l_728 = l_725 || l_727;
if l_728 {
l_mut_353 = bool(false);
}
l_mut_86 = l_mut_86 | l_724;
l_mut_180 = l_mut_241;
let l_729 = a_548[u32(0)];
let l_730 = a_541[u32(5)];
let l_731 = l_729 * l_730;
l_mut_180 = l_mut_180 + l_731;
let l_732 = a_548[u32(1)];
let l_733 = a_541[u32(4)];
let l_734 = l_732 * l_733;
l_mut_180 = l_mut_180 + l_734;
let l_735 = a_548[u32(2)];
let l_736 = a_541[u32(3)];
let l_737 = l_735 * l_736;
l_mut_180 = l_mut_180 + l_737;
let l_738 = a_548[u32(3)];
let l_739 = a_541[u32(2)];
let l_740 = l_738 * l_739;
l_mut_180 = l_mut_180 + l_740;
let l_741 = a_548[u32(4)];
let l_742 = a_541[u32(1)];
let l_743 = l_741 * l_742;
l_mut_180 = l_mut_180 + l_743;
let l_744 = a_548[u32(5)];
let l_745 = a_541[u32(0)];
let l_746 = l_744 * l_745;
l_mut_180 = l_mut_180 + l_746;
let l_747 = l_mut_180 % u32(40);
let l_748 = l_mut_180 / u32(40);
l_mut_241 = l_748;
let l_749 = a_548[u32(5)];
let l_750 = u64(l_749);
let l_751 = u64(1) << u32(bitcast<u64>(l_750));
let l_752 = u64(l_747);
let l_753 = u64(1) << u32(bitcast<u64>(l_752));
let l_754 = l_751 | l_753;
let l_755 = l_749 == l_747;
let l_756 = l_mut_86 & l_754;
let l_757 = l_756 != u64(0);
let l_758 = l_755 || l_757;
if l_758 {
l_mut_353 = bool(false);
}
l_mut_86 = l_mut_86 | l_754;
if l_mut_353 {
l_mut_269 = u32(1);
}
}
let l_759 = subgroupExclusiveAdd(l_mut_269);
let l_760 = subgroupAdd(l_mut_269);
let l_761 = subgroup_invocation_id == u32(0);
if l_761 {
shared_memory_0[l_518] = l_760;
}
workgroupBarrier();
l_mut_246 = u32(0);
l_mut_245 = u32(0);
l_mut_241 = u32(0);
loop {
let l_762 = l_mut_241 < l_519;
let l_763 = !l_762;
if l_763 {
break;
}
let l_764 = shared_memory_0[l_mut_241];
let l_765 = l_mut_241 < l_518;
if l_765 {
l_mut_246 = l_mut_246 + l_764;
}
l_mut_245 = l_mut_245 + l_764;
l_mut_241 = l_mut_241 + u32(1);
}
let l_766 = local_invocation_id.x == u32(0);
let l_767 = l_mut_245 > u32(0);
let l_768 = l_766 && l_767;
if l_768 {
let l_769 = &buffer_11_global[u32(0)];
let l_770 = atomicAdd(l_769, l_mut_245);shared_memory_9[u32(0)] = l_770;
}
workgroupBarrier();
let l_771 = l_mut_269 != u32(0);
if l_771 {
let l_772 = shared_memory_9[u32(0)];
let l_773 = l_772 + l_mut_246;
let l_774 = l_773 + l_759;
let l_775 = l_774 < info.scalars_u32[2];
if l_775 {
let l_776 = u32(2) * l_774;
buffer_10_global[l_776] = l_mut_267;
let l_777 = u32(2) * l_774;
let l_778 = l_777 + u32(1);
buffer_10_global[l_778] = l_mut_247;
}
}
l_mut_276 = l_mut_276 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_779 = local_invocation_id.x == u32(0);
if l_779 {
let l_780 = &shared_memory_8[u32(0)];
atomicStore(l_780,u32(0));
}
}
workgroupBarrier();
let l_781 = local_invocation_id.x == u32(0);
if l_781 {
let l_782 = &buffer_14_global[u32(4)];
let l_783 = atomicAdd(l_782, u32(1));}
}
```
