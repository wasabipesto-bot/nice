
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

var a_266: array<u32, 4>;

var a_273: array<u32, 4>;

var a_445: array<u32, 4>;

var a_450: array<u32, 4>;

var l_mut_314: bool;
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
var l_mut_274: u32;
var l_mut_275: u32;
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
let l_26 = l_19 / u32(19);
let l_27 = l_26 * u32(19);
let l_28 = l_19 - l_27;
let l_29 = buffer_3_global[l_28];
let l_30 = l_28 + u32(1);
let l_31 = buffer_3_global[l_30];
let l_32 = l_31 - l_29;
let l_33 = l_16 * u32(20);
let l_34 = l_33 + l_26;
let l_35 = l_34 * u32(19);
let l_36 = l_35 + l_28;
let l_37 = buffer_5_global[l_36];
let l_38 = l_16 * u32(20);
let l_39 = l_38 * info.scalars_u32[1];
let l_40 = u32(20) * l_29;
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
let l_93 = l_92 % u32(20);
l_mut_94 = l_93;
let l_95 = l_87 >> u32(8);
let l_96 = l_95 & u32(255);
let l_97 = l_87 >> u32(24);
let l_98 = l_26 * l_97;
let l_99 = l_96 + l_98;
let l_100 = l_99 % u32(20);
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
let l_132 = l_131 % u32(20);
l_mut_101 = l_132;
let l_133 = l_126 >> u32(8);
let l_134 = l_133 & u32(255);
let l_135 = l_126 >> u32(24);
let l_136 = l_26 * l_135;
let l_137 = l_134 + l_136;
let l_138 = l_137 % u32(20);
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
let l_268 = l_mut_267 % u32(20);
a_266[u32(0)] = l_268;
l_mut_267 = l_mut_267 / u32(20);
l_mut_269 = l_252;
let l_270 = l_mut_269 % u32(20);
a_266[u32(1)] = l_270;
l_mut_269 = l_mut_269 / u32(20);
let l_271 = l_mut_269 % u32(20);
a_266[u32(2)] = l_271;
l_mut_269 = l_mut_269 / u32(20);
let l_272 = l_mut_269 % u32(20);
a_266[u32(3)] = l_272;
l_mut_269 = l_mut_269 / u32(20);
l_mut_274 = u32(0);
l_mut_275 = l_mut_274;
let l_276 = a_266[u32(0)];
let l_277 = a_266[u32(0)];
let l_278 = l_276 * l_277;
l_mut_275 = l_mut_275 + l_278;
let l_279 = l_mut_275 % u32(20);
a_273[u32(0)] = l_279;
let l_280 = l_mut_275 / u32(20);
l_mut_274 = l_280;
l_mut_275 = l_mut_274;
let l_281 = a_266[u32(0)];
let l_282 = a_266[u32(1)];
let l_283 = l_281 * l_282;
l_mut_275 = l_mut_275 + l_283;
let l_284 = a_266[u32(1)];
let l_285 = a_266[u32(0)];
let l_286 = l_284 * l_285;
l_mut_275 = l_mut_275 + l_286;
let l_287 = l_mut_275 % u32(20);
a_273[u32(1)] = l_287;
let l_288 = l_mut_275 / u32(20);
l_mut_274 = l_288;
l_mut_275 = l_mut_274;
let l_289 = a_266[u32(0)];
let l_290 = a_266[u32(2)];
let l_291 = l_289 * l_290;
l_mut_275 = l_mut_275 + l_291;
let l_292 = a_266[u32(1)];
let l_293 = a_266[u32(1)];
let l_294 = l_292 * l_293;
l_mut_275 = l_mut_275 + l_294;
let l_295 = a_266[u32(2)];
let l_296 = a_266[u32(0)];
let l_297 = l_295 * l_296;
l_mut_275 = l_mut_275 + l_297;
let l_298 = l_mut_275 % u32(20);
a_273[u32(2)] = l_298;
let l_299 = l_mut_275 / u32(20);
l_mut_274 = l_299;
l_mut_275 = l_mut_274;
let l_300 = a_266[u32(0)];
let l_301 = a_266[u32(3)];
let l_302 = l_300 * l_301;
l_mut_275 = l_mut_275 + l_302;
let l_303 = a_266[u32(1)];
let l_304 = a_266[u32(2)];
let l_305 = l_303 * l_304;
l_mut_275 = l_mut_275 + l_305;
let l_306 = a_266[u32(2)];
let l_307 = a_266[u32(1)];
let l_308 = l_306 * l_307;
l_mut_275 = l_mut_275 + l_308;
let l_309 = a_266[u32(3)];
let l_310 = a_266[u32(0)];
let l_311 = l_309 * l_310;
l_mut_275 = l_mut_275 + l_311;
let l_312 = l_mut_275 % u32(20);
a_273[u32(3)] = l_312;
let l_313 = l_mut_275 / u32(20);
l_mut_274 = l_313;
l_mut_314 = bool(true);
l_mut_274 = u32(0);
l_mut_275 = l_mut_274;
let l_315 = a_273[u32(0)];
let l_316 = a_266[u32(0)];
let l_317 = l_315 * l_316;
l_mut_275 = l_mut_275 + l_317;
let l_318 = l_mut_275 % u32(20);
let l_319 = l_mut_275 / u32(20);
l_mut_274 = l_319;
let l_320 = a_273[u32(0)];
let l_321 = u64(l_320);
let l_322 = u64(1) << u32(bitcast<u64>(l_321));
let l_323 = u64(l_318);
let l_324 = u64(1) << u32(bitcast<u64>(l_323));
let l_325 = l_322 | l_324;
let l_326 = l_320 == l_318;
let l_327 = l_mut_86 & l_325;
let l_328 = l_327 != u64(0);
let l_329 = l_326 || l_328;
if l_329 {
l_mut_314 = bool(false);
}
l_mut_86 = l_mut_86 | l_325;
l_mut_275 = l_mut_274;
let l_330 = a_273[u32(0)];
let l_331 = a_266[u32(1)];
let l_332 = l_330 * l_331;
l_mut_275 = l_mut_275 + l_332;
let l_333 = a_273[u32(1)];
let l_334 = a_266[u32(0)];
let l_335 = l_333 * l_334;
l_mut_275 = l_mut_275 + l_335;
let l_336 = l_mut_275 % u32(20);
let l_337 = l_mut_275 / u32(20);
l_mut_274 = l_337;
let l_338 = a_273[u32(1)];
let l_339 = u64(l_338);
let l_340 = u64(1) << u32(bitcast<u64>(l_339));
let l_341 = u64(l_336);
let l_342 = u64(1) << u32(bitcast<u64>(l_341));
let l_343 = l_340 | l_342;
let l_344 = l_338 == l_336;
let l_345 = l_mut_86 & l_343;
let l_346 = l_345 != u64(0);
let l_347 = l_344 || l_346;
if l_347 {
l_mut_314 = bool(false);
}
l_mut_86 = l_mut_86 | l_343;
l_mut_275 = l_mut_274;
let l_348 = a_273[u32(0)];
let l_349 = a_266[u32(2)];
let l_350 = l_348 * l_349;
l_mut_275 = l_mut_275 + l_350;
let l_351 = a_273[u32(1)];
let l_352 = a_266[u32(1)];
let l_353 = l_351 * l_352;
l_mut_275 = l_mut_275 + l_353;
let l_354 = a_273[u32(2)];
let l_355 = a_266[u32(0)];
let l_356 = l_354 * l_355;
l_mut_275 = l_mut_275 + l_356;
let l_357 = l_mut_275 % u32(20);
let l_358 = l_mut_275 / u32(20);
l_mut_274 = l_358;
let l_359 = a_273[u32(2)];
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
l_mut_314 = bool(false);
}
l_mut_86 = l_mut_86 | l_364;
l_mut_275 = l_mut_274;
let l_369 = a_273[u32(0)];
let l_370 = a_266[u32(3)];
let l_371 = l_369 * l_370;
l_mut_275 = l_mut_275 + l_371;
let l_372 = a_273[u32(1)];
let l_373 = a_266[u32(2)];
let l_374 = l_372 * l_373;
l_mut_275 = l_mut_275 + l_374;
let l_375 = a_273[u32(2)];
let l_376 = a_266[u32(1)];
let l_377 = l_375 * l_376;
l_mut_275 = l_mut_275 + l_377;
let l_378 = a_273[u32(3)];
let l_379 = a_266[u32(0)];
let l_380 = l_378 * l_379;
l_mut_275 = l_mut_275 + l_380;
let l_381 = l_mut_275 % u32(20);
let l_382 = l_mut_275 / u32(20);
l_mut_274 = l_382;
let l_383 = a_273[u32(3)];
let l_384 = u64(l_383);
let l_385 = u64(1) << u32(bitcast<u64>(l_384));
let l_386 = u64(l_381);
let l_387 = u64(1) << u32(bitcast<u64>(l_386));
let l_388 = l_385 | l_387;
let l_389 = l_383 == l_381;
let l_390 = l_mut_86 & l_388;
let l_391 = l_390 != u64(0);
let l_392 = l_389 || l_391;
if l_392 {
l_mut_314 = bool(false);
}
l_mut_86 = l_mut_86 | l_388;
if l_mut_314 {
l_mut_245 = u32(1);
}
}
let l_393 = subgroupExclusiveAdd(l_mut_245);
let l_394 = subgroupAdd(l_mut_245);
let l_395 = subgroup_invocation_id == u32(0);
if l_395 {
shared_memory_0[l_239] = l_394;
}
workgroupBarrier();
l_mut_275 = u32(0);
l_mut_274 = u32(0);
l_mut_269 = u32(0);
loop {
let l_396 = l_mut_269 < l_240;
let l_397 = !l_396;
if l_397 {
break;
}
let l_398 = shared_memory_0[l_mut_269];
let l_399 = l_mut_269 < l_239;
if l_399 {
l_mut_275 = l_mut_275 + l_398;
}
l_mut_274 = l_mut_274 + l_398;
l_mut_269 = l_mut_269 + u32(1);
}
let l_400 = local_invocation_id.x == u32(0);
let l_401 = l_mut_274 > u32(0);
let l_402 = l_400 && l_401;
if l_402 {
let l_403 = &buffer_11_global[u32(0)];
let l_404 = atomicAdd(l_403, l_mut_274);shared_memory_9[u32(0)] = l_404;
}
workgroupBarrier();
let l_405 = l_mut_245 != u32(0);
if l_405 {
let l_406 = shared_memory_9[u32(0)];
let l_407 = l_406 + l_mut_275;
let l_408 = l_407 + l_393;
let l_409 = l_408 < info.scalars_u32[2];
if l_409 {
let l_410 = u32(2) * l_408;
buffer_10_global[l_410] = l_mut_246;
let l_411 = u32(2) * l_408;
let l_412 = l_411 + u32(1);
buffer_10_global[l_412] = l_mut_247;
}
}
l_mut_241 = l_mut_241 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_413 = local_invocation_id.x == u32(0);
if l_413 {
let l_414 = &shared_memory_8[u32(0)];
atomicStore(l_414,u32(0));
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
let l_415 = &shared_memory_8[u32(0)];
let l_416 = atomicLoad(l_415);
let l_417 = l_416 > u32(0);
if l_417 {
l_mut_275 = l_416;
let l_418 = l_mut_275 > u32(1024);
if l_418 {
l_mut_275 = u32(1024);
}
let l_419 = local_invocation_id.x == u32(0);
if l_419 {
let l_420 = &buffer_13_global[u32(0)];
let l_421 = atomicAdd(l_420, l_mut_275);}
let l_422 = local_invocation_id.x / subgroup_size;
let l_423 = WORKGROUP_SIZE_X / subgroup_size;
l_mut_274 = u32(0);
loop {
let l_424 = l_mut_274 < l_mut_275;
let l_425 = !l_424;
if l_425 {
break;
}
let l_426 = l_mut_274 + local_invocation_id.x;
l_mut_269 = u32(0);
l_mut_267 = u32(0);
l_mut_247 = u32(0);
let l_427 = l_426 < l_mut_275;
if l_427 {
let l_428 = shared_memory_6[l_426];
l_mut_267 = l_428;
let l_429 = shared_memory_7[l_426];
l_mut_247 = l_429;
let l_430 = u32(2) * l_mut_267;
let l_431 = buffer_12_global[l_430];
l_mut_86 = u64(0);
let l_432 = u32(2) * l_mut_267;
let l_433 = l_432 + u32(1);
let l_434 = buffer_12_global[l_433];
let l_435 = l_434 != u32(0);
if l_435 {
let l_436 = u32(2) * l_mut_267;
let l_437 = l_436 + u32(1);
let l_438 = buffer_8_global[l_437];
let l_439 = u64(l_438);
let l_440 = l_439 << u32(bitcast<u64>(u64(32)));
let l_441 = u32(2) * l_mut_267;
let l_442 = buffer_8_global[l_441];
let l_443 = u64(l_442);
let l_444 = l_440 | l_443;
l_mut_86 = l_444;
}
l_mut_246 = l_mut_247;
let l_446 = l_mut_246 % u32(20);
a_445[u32(0)] = l_446;
l_mut_246 = l_mut_246 / u32(20);
l_mut_245 = l_431;
let l_447 = l_mut_245 % u32(20);
a_445[u32(1)] = l_447;
l_mut_245 = l_mut_245 / u32(20);
let l_448 = l_mut_245 % u32(20);
a_445[u32(2)] = l_448;
l_mut_245 = l_mut_245 / u32(20);
let l_449 = l_mut_245 % u32(20);
a_445[u32(3)] = l_449;
l_mut_245 = l_mut_245 / u32(20);
l_mut_241 = u32(0);
l_mut_180 = l_mut_241;
let l_451 = a_445[u32(0)];
let l_452 = a_445[u32(0)];
let l_453 = l_451 * l_452;
l_mut_180 = l_mut_180 + l_453;
let l_454 = l_mut_180 % u32(20);
a_450[u32(0)] = l_454;
let l_455 = l_mut_180 / u32(20);
l_mut_241 = l_455;
l_mut_180 = l_mut_241;
let l_456 = a_445[u32(0)];
let l_457 = a_445[u32(1)];
let l_458 = l_456 * l_457;
l_mut_180 = l_mut_180 + l_458;
let l_459 = a_445[u32(1)];
let l_460 = a_445[u32(0)];
let l_461 = l_459 * l_460;
l_mut_180 = l_mut_180 + l_461;
let l_462 = l_mut_180 % u32(20);
a_450[u32(1)] = l_462;
let l_463 = l_mut_180 / u32(20);
l_mut_241 = l_463;
l_mut_180 = l_mut_241;
let l_464 = a_445[u32(0)];
let l_465 = a_445[u32(2)];
let l_466 = l_464 * l_465;
l_mut_180 = l_mut_180 + l_466;
let l_467 = a_445[u32(1)];
let l_468 = a_445[u32(1)];
let l_469 = l_467 * l_468;
l_mut_180 = l_mut_180 + l_469;
let l_470 = a_445[u32(2)];
let l_471 = a_445[u32(0)];
let l_472 = l_470 * l_471;
l_mut_180 = l_mut_180 + l_472;
let l_473 = l_mut_180 % u32(20);
a_450[u32(2)] = l_473;
let l_474 = l_mut_180 / u32(20);
l_mut_241 = l_474;
l_mut_180 = l_mut_241;
let l_475 = a_445[u32(0)];
let l_476 = a_445[u32(3)];
let l_477 = l_475 * l_476;
l_mut_180 = l_mut_180 + l_477;
let l_478 = a_445[u32(1)];
let l_479 = a_445[u32(2)];
let l_480 = l_478 * l_479;
l_mut_180 = l_mut_180 + l_480;
let l_481 = a_445[u32(2)];
let l_482 = a_445[u32(1)];
let l_483 = l_481 * l_482;
l_mut_180 = l_mut_180 + l_483;
let l_484 = a_445[u32(3)];
let l_485 = a_445[u32(0)];
let l_486 = l_484 * l_485;
l_mut_180 = l_mut_180 + l_486;
let l_487 = l_mut_180 % u32(20);
a_450[u32(3)] = l_487;
let l_488 = l_mut_180 / u32(20);
l_mut_241 = l_488;
l_mut_314 = bool(true);
l_mut_241 = u32(0);
l_mut_180 = l_mut_241;
let l_489 = a_450[u32(0)];
let l_490 = a_445[u32(0)];
let l_491 = l_489 * l_490;
l_mut_180 = l_mut_180 + l_491;
let l_492 = l_mut_180 % u32(20);
let l_493 = l_mut_180 / u32(20);
l_mut_241 = l_493;
let l_494 = a_450[u32(0)];
let l_495 = u64(l_494);
let l_496 = u64(1) << u32(bitcast<u64>(l_495));
let l_497 = u64(l_492);
let l_498 = u64(1) << u32(bitcast<u64>(l_497));
let l_499 = l_496 | l_498;
let l_500 = l_494 == l_492;
let l_501 = l_mut_86 & l_499;
let l_502 = l_501 != u64(0);
let l_503 = l_500 || l_502;
if l_503 {
l_mut_314 = bool(false);
}
l_mut_86 = l_mut_86 | l_499;
l_mut_180 = l_mut_241;
let l_504 = a_450[u32(0)];
let l_505 = a_445[u32(1)];
let l_506 = l_504 * l_505;
l_mut_180 = l_mut_180 + l_506;
let l_507 = a_450[u32(1)];
let l_508 = a_445[u32(0)];
let l_509 = l_507 * l_508;
l_mut_180 = l_mut_180 + l_509;
let l_510 = l_mut_180 % u32(20);
let l_511 = l_mut_180 / u32(20);
l_mut_241 = l_511;
let l_512 = a_450[u32(1)];
let l_513 = u64(l_512);
let l_514 = u64(1) << u32(bitcast<u64>(l_513));
let l_515 = u64(l_510);
let l_516 = u64(1) << u32(bitcast<u64>(l_515));
let l_517 = l_514 | l_516;
let l_518 = l_512 == l_510;
let l_519 = l_mut_86 & l_517;
let l_520 = l_519 != u64(0);
let l_521 = l_518 || l_520;
if l_521 {
l_mut_314 = bool(false);
}
l_mut_86 = l_mut_86 | l_517;
l_mut_180 = l_mut_241;
let l_522 = a_450[u32(0)];
let l_523 = a_445[u32(2)];
let l_524 = l_522 * l_523;
l_mut_180 = l_mut_180 + l_524;
let l_525 = a_450[u32(1)];
let l_526 = a_445[u32(1)];
let l_527 = l_525 * l_526;
l_mut_180 = l_mut_180 + l_527;
let l_528 = a_450[u32(2)];
let l_529 = a_445[u32(0)];
let l_530 = l_528 * l_529;
l_mut_180 = l_mut_180 + l_530;
let l_531 = l_mut_180 % u32(20);
let l_532 = l_mut_180 / u32(20);
l_mut_241 = l_532;
let l_533 = a_450[u32(2)];
let l_534 = u64(l_533);
let l_535 = u64(1) << u32(bitcast<u64>(l_534));
let l_536 = u64(l_531);
let l_537 = u64(1) << u32(bitcast<u64>(l_536));
let l_538 = l_535 | l_537;
let l_539 = l_533 == l_531;
let l_540 = l_mut_86 & l_538;
let l_541 = l_540 != u64(0);
let l_542 = l_539 || l_541;
if l_542 {
l_mut_314 = bool(false);
}
l_mut_86 = l_mut_86 | l_538;
l_mut_180 = l_mut_241;
let l_543 = a_450[u32(0)];
let l_544 = a_445[u32(3)];
let l_545 = l_543 * l_544;
l_mut_180 = l_mut_180 + l_545;
let l_546 = a_450[u32(1)];
let l_547 = a_445[u32(2)];
let l_548 = l_546 * l_547;
l_mut_180 = l_mut_180 + l_548;
let l_549 = a_450[u32(2)];
let l_550 = a_445[u32(1)];
let l_551 = l_549 * l_550;
l_mut_180 = l_mut_180 + l_551;
let l_552 = a_450[u32(3)];
let l_553 = a_445[u32(0)];
let l_554 = l_552 * l_553;
l_mut_180 = l_mut_180 + l_554;
let l_555 = l_mut_180 % u32(20);
let l_556 = l_mut_180 / u32(20);
l_mut_241 = l_556;
let l_557 = a_450[u32(3)];
let l_558 = u64(l_557);
let l_559 = u64(1) << u32(bitcast<u64>(l_558));
let l_560 = u64(l_555);
let l_561 = u64(1) << u32(bitcast<u64>(l_560));
let l_562 = l_559 | l_561;
let l_563 = l_557 == l_555;
let l_564 = l_mut_86 & l_562;
let l_565 = l_564 != u64(0);
let l_566 = l_563 || l_565;
if l_566 {
l_mut_314 = bool(false);
}
l_mut_86 = l_mut_86 | l_562;
if l_mut_314 {
l_mut_269 = u32(1);
}
}
let l_567 = subgroupExclusiveAdd(l_mut_269);
let l_568 = subgroupAdd(l_mut_269);
let l_569 = subgroup_invocation_id == u32(0);
if l_569 {
shared_memory_0[l_422] = l_568;
}
workgroupBarrier();
l_mut_246 = u32(0);
l_mut_245 = u32(0);
l_mut_241 = u32(0);
loop {
let l_570 = l_mut_241 < l_423;
let l_571 = !l_570;
if l_571 {
break;
}
let l_572 = shared_memory_0[l_mut_241];
let l_573 = l_mut_241 < l_422;
if l_573 {
l_mut_246 = l_mut_246 + l_572;
}
l_mut_245 = l_mut_245 + l_572;
l_mut_241 = l_mut_241 + u32(1);
}
let l_574 = local_invocation_id.x == u32(0);
let l_575 = l_mut_245 > u32(0);
let l_576 = l_574 && l_575;
if l_576 {
let l_577 = &buffer_11_global[u32(0)];
let l_578 = atomicAdd(l_577, l_mut_245);shared_memory_9[u32(0)] = l_578;
}
workgroupBarrier();
let l_579 = l_mut_269 != u32(0);
if l_579 {
let l_580 = shared_memory_9[u32(0)];
let l_581 = l_580 + l_mut_246;
let l_582 = l_581 + l_567;
let l_583 = l_582 < info.scalars_u32[2];
if l_583 {
let l_584 = u32(2) * l_582;
buffer_10_global[l_584] = l_mut_267;
let l_585 = u32(2) * l_582;
let l_586 = l_585 + u32(1);
buffer_10_global[l_586] = l_mut_247;
}
}
l_mut_274 = l_mut_274 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_587 = local_invocation_id.x == u32(0);
if l_587 {
let l_588 = &shared_memory_8[u32(0)];
atomicStore(l_588,u32(0));
}
}
workgroupBarrier();
let l_589 = local_invocation_id.x == u32(0);
if l_589 {
let l_590 = &buffer_14_global[u32(4)];
let l_591 = atomicAdd(l_590, u32(1));}
}
```
