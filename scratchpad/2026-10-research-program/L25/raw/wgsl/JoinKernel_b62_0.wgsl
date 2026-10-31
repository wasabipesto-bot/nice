
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

var a_266: array<u32, 8>;

var a_277: array<u32, 8>;

var a_661: array<u32, 8>;

var a_670: array<u32, 8>;

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
var l_mut_271: u32;
var l_mut_278: u32;
var l_mut_279: u32;
var l_mut_404: bool;
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
let l_26 = l_19 / u32(61);
let l_27 = l_26 * u32(61);
let l_28 = l_19 - l_27;
let l_29 = buffer_3_global[l_28];
let l_30 = l_28 + u32(1);
let l_31 = buffer_3_global[l_30];
let l_32 = l_31 - l_29;
let l_33 = l_16 * u32(62);
let l_34 = l_33 + l_26;
let l_35 = l_34 * u32(61);
let l_36 = l_35 + l_28;
let l_37 = buffer_5_global[l_36];
let l_38 = l_16 * u32(62);
let l_39 = l_38 * info.scalars_u32[1];
let l_40 = u32(62) * l_29;
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
let l_93 = l_92 % u32(62);
l_mut_94 = l_93;
let l_95 = l_87 >> u32(8);
let l_96 = l_95 & u32(255);
let l_97 = l_87 >> u32(24);
let l_98 = l_26 * l_97;
let l_99 = l_96 + l_98;
let l_100 = l_99 % u32(62);
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
let l_132 = l_131 % u32(62);
l_mut_101 = l_132;
let l_133 = l_126 >> u32(8);
let l_134 = l_133 & u32(255);
let l_135 = l_126 >> u32(24);
let l_136 = l_26 * l_135;
let l_137 = l_134 + l_136;
let l_138 = l_137 % u32(62);
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
let l_268 = l_mut_267 % u32(62);
a_266[u32(0)] = l_268;
l_mut_267 = l_mut_267 / u32(62);
let l_269 = l_mut_267 % u32(62);
a_266[u32(1)] = l_269;
l_mut_267 = l_mut_267 / u32(62);
let l_270 = l_mut_267 % u32(62);
a_266[u32(2)] = l_270;
l_mut_267 = l_mut_267 / u32(62);
l_mut_271 = l_252;
let l_272 = l_mut_271 % u32(62);
a_266[u32(3)] = l_272;
l_mut_271 = l_mut_271 / u32(62);
let l_273 = l_mut_271 % u32(62);
a_266[u32(4)] = l_273;
l_mut_271 = l_mut_271 / u32(62);
let l_274 = l_mut_271 % u32(62);
a_266[u32(5)] = l_274;
l_mut_271 = l_mut_271 / u32(62);
let l_275 = l_mut_271 % u32(62);
a_266[u32(6)] = l_275;
l_mut_271 = l_mut_271 / u32(62);
let l_276 = l_mut_271 % u32(62);
a_266[u32(7)] = l_276;
l_mut_271 = l_mut_271 / u32(62);
l_mut_278 = u32(0);
l_mut_279 = l_mut_278;
let l_280 = a_266[u32(0)];
let l_281 = a_266[u32(0)];
let l_282 = l_280 * l_281;
l_mut_279 = l_mut_279 + l_282;
let l_283 = l_mut_279 % u32(62);
a_277[u32(0)] = l_283;
let l_284 = l_mut_279 / u32(62);
l_mut_278 = l_284;
l_mut_279 = l_mut_278;
let l_285 = a_266[u32(0)];
let l_286 = a_266[u32(1)];
let l_287 = l_285 * l_286;
l_mut_279 = l_mut_279 + l_287;
let l_288 = a_266[u32(1)];
let l_289 = a_266[u32(0)];
let l_290 = l_288 * l_289;
l_mut_279 = l_mut_279 + l_290;
let l_291 = l_mut_279 % u32(62);
a_277[u32(1)] = l_291;
let l_292 = l_mut_279 / u32(62);
l_mut_278 = l_292;
l_mut_279 = l_mut_278;
let l_293 = a_266[u32(0)];
let l_294 = a_266[u32(2)];
let l_295 = l_293 * l_294;
l_mut_279 = l_mut_279 + l_295;
let l_296 = a_266[u32(1)];
let l_297 = a_266[u32(1)];
let l_298 = l_296 * l_297;
l_mut_279 = l_mut_279 + l_298;
let l_299 = a_266[u32(2)];
let l_300 = a_266[u32(0)];
let l_301 = l_299 * l_300;
l_mut_279 = l_mut_279 + l_301;
let l_302 = l_mut_279 % u32(62);
a_277[u32(2)] = l_302;
let l_303 = l_mut_279 / u32(62);
l_mut_278 = l_303;
l_mut_279 = l_mut_278;
let l_304 = a_266[u32(0)];
let l_305 = a_266[u32(3)];
let l_306 = l_304 * l_305;
l_mut_279 = l_mut_279 + l_306;
let l_307 = a_266[u32(1)];
let l_308 = a_266[u32(2)];
let l_309 = l_307 * l_308;
l_mut_279 = l_mut_279 + l_309;
let l_310 = a_266[u32(2)];
let l_311 = a_266[u32(1)];
let l_312 = l_310 * l_311;
l_mut_279 = l_mut_279 + l_312;
let l_313 = a_266[u32(3)];
let l_314 = a_266[u32(0)];
let l_315 = l_313 * l_314;
l_mut_279 = l_mut_279 + l_315;
let l_316 = l_mut_279 % u32(62);
a_277[u32(3)] = l_316;
let l_317 = l_mut_279 / u32(62);
l_mut_278 = l_317;
l_mut_279 = l_mut_278;
let l_318 = a_266[u32(0)];
let l_319 = a_266[u32(4)];
let l_320 = l_318 * l_319;
l_mut_279 = l_mut_279 + l_320;
let l_321 = a_266[u32(1)];
let l_322 = a_266[u32(3)];
let l_323 = l_321 * l_322;
l_mut_279 = l_mut_279 + l_323;
let l_324 = a_266[u32(2)];
let l_325 = a_266[u32(2)];
let l_326 = l_324 * l_325;
l_mut_279 = l_mut_279 + l_326;
let l_327 = a_266[u32(3)];
let l_328 = a_266[u32(1)];
let l_329 = l_327 * l_328;
l_mut_279 = l_mut_279 + l_329;
let l_330 = a_266[u32(4)];
let l_331 = a_266[u32(0)];
let l_332 = l_330 * l_331;
l_mut_279 = l_mut_279 + l_332;
let l_333 = l_mut_279 % u32(62);
a_277[u32(4)] = l_333;
let l_334 = l_mut_279 / u32(62);
l_mut_278 = l_334;
l_mut_279 = l_mut_278;
let l_335 = a_266[u32(0)];
let l_336 = a_266[u32(5)];
let l_337 = l_335 * l_336;
l_mut_279 = l_mut_279 + l_337;
let l_338 = a_266[u32(1)];
let l_339 = a_266[u32(4)];
let l_340 = l_338 * l_339;
l_mut_279 = l_mut_279 + l_340;
let l_341 = a_266[u32(2)];
let l_342 = a_266[u32(3)];
let l_343 = l_341 * l_342;
l_mut_279 = l_mut_279 + l_343;
let l_344 = a_266[u32(3)];
let l_345 = a_266[u32(2)];
let l_346 = l_344 * l_345;
l_mut_279 = l_mut_279 + l_346;
let l_347 = a_266[u32(4)];
let l_348 = a_266[u32(1)];
let l_349 = l_347 * l_348;
l_mut_279 = l_mut_279 + l_349;
let l_350 = a_266[u32(5)];
let l_351 = a_266[u32(0)];
let l_352 = l_350 * l_351;
l_mut_279 = l_mut_279 + l_352;
let l_353 = l_mut_279 % u32(62);
a_277[u32(5)] = l_353;
let l_354 = l_mut_279 / u32(62);
l_mut_278 = l_354;
l_mut_279 = l_mut_278;
let l_355 = a_266[u32(0)];
let l_356 = a_266[u32(6)];
let l_357 = l_355 * l_356;
l_mut_279 = l_mut_279 + l_357;
let l_358 = a_266[u32(1)];
let l_359 = a_266[u32(5)];
let l_360 = l_358 * l_359;
l_mut_279 = l_mut_279 + l_360;
let l_361 = a_266[u32(2)];
let l_362 = a_266[u32(4)];
let l_363 = l_361 * l_362;
l_mut_279 = l_mut_279 + l_363;
let l_364 = a_266[u32(3)];
let l_365 = a_266[u32(3)];
let l_366 = l_364 * l_365;
l_mut_279 = l_mut_279 + l_366;
let l_367 = a_266[u32(4)];
let l_368 = a_266[u32(2)];
let l_369 = l_367 * l_368;
l_mut_279 = l_mut_279 + l_369;
let l_370 = a_266[u32(5)];
let l_371 = a_266[u32(1)];
let l_372 = l_370 * l_371;
l_mut_279 = l_mut_279 + l_372;
let l_373 = a_266[u32(6)];
let l_374 = a_266[u32(0)];
let l_375 = l_373 * l_374;
l_mut_279 = l_mut_279 + l_375;
let l_376 = l_mut_279 % u32(62);
a_277[u32(6)] = l_376;
let l_377 = l_mut_279 / u32(62);
l_mut_278 = l_377;
l_mut_279 = l_mut_278;
let l_378 = a_266[u32(0)];
let l_379 = a_266[u32(7)];
let l_380 = l_378 * l_379;
l_mut_279 = l_mut_279 + l_380;
let l_381 = a_266[u32(1)];
let l_382 = a_266[u32(6)];
let l_383 = l_381 * l_382;
l_mut_279 = l_mut_279 + l_383;
let l_384 = a_266[u32(2)];
let l_385 = a_266[u32(5)];
let l_386 = l_384 * l_385;
l_mut_279 = l_mut_279 + l_386;
let l_387 = a_266[u32(3)];
let l_388 = a_266[u32(4)];
let l_389 = l_387 * l_388;
l_mut_279 = l_mut_279 + l_389;
let l_390 = a_266[u32(4)];
let l_391 = a_266[u32(3)];
let l_392 = l_390 * l_391;
l_mut_279 = l_mut_279 + l_392;
let l_393 = a_266[u32(5)];
let l_394 = a_266[u32(2)];
let l_395 = l_393 * l_394;
l_mut_279 = l_mut_279 + l_395;
let l_396 = a_266[u32(6)];
let l_397 = a_266[u32(1)];
let l_398 = l_396 * l_397;
l_mut_279 = l_mut_279 + l_398;
let l_399 = a_266[u32(7)];
let l_400 = a_266[u32(0)];
let l_401 = l_399 * l_400;
l_mut_279 = l_mut_279 + l_401;
let l_402 = l_mut_279 % u32(62);
a_277[u32(7)] = l_402;
let l_403 = l_mut_279 / u32(62);
l_mut_278 = l_403;
l_mut_404 = bool(true);
l_mut_278 = u32(0);
l_mut_279 = l_mut_278;
let l_405 = a_277[u32(0)];
let l_406 = a_266[u32(0)];
let l_407 = l_405 * l_406;
l_mut_279 = l_mut_279 + l_407;
let l_408 = l_mut_279 % u32(62);
let l_409 = l_mut_279 / u32(62);
l_mut_278 = l_409;
let l_410 = a_277[u32(0)];
let l_411 = u64(l_410);
let l_412 = u64(1) << u32(bitcast<u64>(l_411));
let l_413 = u64(l_408);
let l_414 = u64(1) << u32(bitcast<u64>(l_413));
let l_415 = l_412 | l_414;
let l_416 = l_410 == l_408;
let l_417 = l_mut_86 & l_415;
let l_418 = l_417 != u64(0);
let l_419 = l_416 || l_418;
if l_419 {
l_mut_404 = bool(false);
}
l_mut_86 = l_mut_86 | l_415;
l_mut_279 = l_mut_278;
let l_420 = a_277[u32(0)];
let l_421 = a_266[u32(1)];
let l_422 = l_420 * l_421;
l_mut_279 = l_mut_279 + l_422;
let l_423 = a_277[u32(1)];
let l_424 = a_266[u32(0)];
let l_425 = l_423 * l_424;
l_mut_279 = l_mut_279 + l_425;
let l_426 = l_mut_279 % u32(62);
let l_427 = l_mut_279 / u32(62);
l_mut_278 = l_427;
let l_428 = a_277[u32(1)];
let l_429 = u64(l_428);
let l_430 = u64(1) << u32(bitcast<u64>(l_429));
let l_431 = u64(l_426);
let l_432 = u64(1) << u32(bitcast<u64>(l_431));
let l_433 = l_430 | l_432;
let l_434 = l_428 == l_426;
let l_435 = l_mut_86 & l_433;
let l_436 = l_435 != u64(0);
let l_437 = l_434 || l_436;
if l_437 {
l_mut_404 = bool(false);
}
l_mut_86 = l_mut_86 | l_433;
l_mut_279 = l_mut_278;
let l_438 = a_277[u32(0)];
let l_439 = a_266[u32(2)];
let l_440 = l_438 * l_439;
l_mut_279 = l_mut_279 + l_440;
let l_441 = a_277[u32(1)];
let l_442 = a_266[u32(1)];
let l_443 = l_441 * l_442;
l_mut_279 = l_mut_279 + l_443;
let l_444 = a_277[u32(2)];
let l_445 = a_266[u32(0)];
let l_446 = l_444 * l_445;
l_mut_279 = l_mut_279 + l_446;
let l_447 = l_mut_279 % u32(62);
let l_448 = l_mut_279 / u32(62);
l_mut_278 = l_448;
let l_449 = a_277[u32(2)];
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
l_mut_404 = bool(false);
}
l_mut_86 = l_mut_86 | l_454;
l_mut_279 = l_mut_278;
let l_459 = a_277[u32(0)];
let l_460 = a_266[u32(3)];
let l_461 = l_459 * l_460;
l_mut_279 = l_mut_279 + l_461;
let l_462 = a_277[u32(1)];
let l_463 = a_266[u32(2)];
let l_464 = l_462 * l_463;
l_mut_279 = l_mut_279 + l_464;
let l_465 = a_277[u32(2)];
let l_466 = a_266[u32(1)];
let l_467 = l_465 * l_466;
l_mut_279 = l_mut_279 + l_467;
let l_468 = a_277[u32(3)];
let l_469 = a_266[u32(0)];
let l_470 = l_468 * l_469;
l_mut_279 = l_mut_279 + l_470;
let l_471 = l_mut_279 % u32(62);
let l_472 = l_mut_279 / u32(62);
l_mut_278 = l_472;
let l_473 = a_277[u32(3)];
let l_474 = u64(l_473);
let l_475 = u64(1) << u32(bitcast<u64>(l_474));
let l_476 = u64(l_471);
let l_477 = u64(1) << u32(bitcast<u64>(l_476));
let l_478 = l_475 | l_477;
let l_479 = l_473 == l_471;
let l_480 = l_mut_86 & l_478;
let l_481 = l_480 != u64(0);
let l_482 = l_479 || l_481;
if l_482 {
l_mut_404 = bool(false);
}
l_mut_86 = l_mut_86 | l_478;
l_mut_279 = l_mut_278;
let l_483 = a_277[u32(0)];
let l_484 = a_266[u32(4)];
let l_485 = l_483 * l_484;
l_mut_279 = l_mut_279 + l_485;
let l_486 = a_277[u32(1)];
let l_487 = a_266[u32(3)];
let l_488 = l_486 * l_487;
l_mut_279 = l_mut_279 + l_488;
let l_489 = a_277[u32(2)];
let l_490 = a_266[u32(2)];
let l_491 = l_489 * l_490;
l_mut_279 = l_mut_279 + l_491;
let l_492 = a_277[u32(3)];
let l_493 = a_266[u32(1)];
let l_494 = l_492 * l_493;
l_mut_279 = l_mut_279 + l_494;
let l_495 = a_277[u32(4)];
let l_496 = a_266[u32(0)];
let l_497 = l_495 * l_496;
l_mut_279 = l_mut_279 + l_497;
let l_498 = l_mut_279 % u32(62);
let l_499 = l_mut_279 / u32(62);
l_mut_278 = l_499;
let l_500 = a_277[u32(4)];
let l_501 = u64(l_500);
let l_502 = u64(1) << u32(bitcast<u64>(l_501));
let l_503 = u64(l_498);
let l_504 = u64(1) << u32(bitcast<u64>(l_503));
let l_505 = l_502 | l_504;
let l_506 = l_500 == l_498;
let l_507 = l_mut_86 & l_505;
let l_508 = l_507 != u64(0);
let l_509 = l_506 || l_508;
if l_509 {
l_mut_404 = bool(false);
}
l_mut_86 = l_mut_86 | l_505;
l_mut_279 = l_mut_278;
let l_510 = a_277[u32(0)];
let l_511 = a_266[u32(5)];
let l_512 = l_510 * l_511;
l_mut_279 = l_mut_279 + l_512;
let l_513 = a_277[u32(1)];
let l_514 = a_266[u32(4)];
let l_515 = l_513 * l_514;
l_mut_279 = l_mut_279 + l_515;
let l_516 = a_277[u32(2)];
let l_517 = a_266[u32(3)];
let l_518 = l_516 * l_517;
l_mut_279 = l_mut_279 + l_518;
let l_519 = a_277[u32(3)];
let l_520 = a_266[u32(2)];
let l_521 = l_519 * l_520;
l_mut_279 = l_mut_279 + l_521;
let l_522 = a_277[u32(4)];
let l_523 = a_266[u32(1)];
let l_524 = l_522 * l_523;
l_mut_279 = l_mut_279 + l_524;
let l_525 = a_277[u32(5)];
let l_526 = a_266[u32(0)];
let l_527 = l_525 * l_526;
l_mut_279 = l_mut_279 + l_527;
let l_528 = l_mut_279 % u32(62);
let l_529 = l_mut_279 / u32(62);
l_mut_278 = l_529;
let l_530 = a_277[u32(5)];
let l_531 = u64(l_530);
let l_532 = u64(1) << u32(bitcast<u64>(l_531));
let l_533 = u64(l_528);
let l_534 = u64(1) << u32(bitcast<u64>(l_533));
let l_535 = l_532 | l_534;
let l_536 = l_530 == l_528;
let l_537 = l_mut_86 & l_535;
let l_538 = l_537 != u64(0);
let l_539 = l_536 || l_538;
if l_539 {
l_mut_404 = bool(false);
}
l_mut_86 = l_mut_86 | l_535;
l_mut_279 = l_mut_278;
let l_540 = a_277[u32(0)];
let l_541 = a_266[u32(6)];
let l_542 = l_540 * l_541;
l_mut_279 = l_mut_279 + l_542;
let l_543 = a_277[u32(1)];
let l_544 = a_266[u32(5)];
let l_545 = l_543 * l_544;
l_mut_279 = l_mut_279 + l_545;
let l_546 = a_277[u32(2)];
let l_547 = a_266[u32(4)];
let l_548 = l_546 * l_547;
l_mut_279 = l_mut_279 + l_548;
let l_549 = a_277[u32(3)];
let l_550 = a_266[u32(3)];
let l_551 = l_549 * l_550;
l_mut_279 = l_mut_279 + l_551;
let l_552 = a_277[u32(4)];
let l_553 = a_266[u32(2)];
let l_554 = l_552 * l_553;
l_mut_279 = l_mut_279 + l_554;
let l_555 = a_277[u32(5)];
let l_556 = a_266[u32(1)];
let l_557 = l_555 * l_556;
l_mut_279 = l_mut_279 + l_557;
let l_558 = a_277[u32(6)];
let l_559 = a_266[u32(0)];
let l_560 = l_558 * l_559;
l_mut_279 = l_mut_279 + l_560;
let l_561 = l_mut_279 % u32(62);
let l_562 = l_mut_279 / u32(62);
l_mut_278 = l_562;
let l_563 = a_277[u32(6)];
let l_564 = u64(l_563);
let l_565 = u64(1) << u32(bitcast<u64>(l_564));
let l_566 = u64(l_561);
let l_567 = u64(1) << u32(bitcast<u64>(l_566));
let l_568 = l_565 | l_567;
let l_569 = l_563 == l_561;
let l_570 = l_mut_86 & l_568;
let l_571 = l_570 != u64(0);
let l_572 = l_569 || l_571;
if l_572 {
l_mut_404 = bool(false);
}
l_mut_86 = l_mut_86 | l_568;
l_mut_279 = l_mut_278;
let l_573 = a_277[u32(0)];
let l_574 = a_266[u32(7)];
let l_575 = l_573 * l_574;
l_mut_279 = l_mut_279 + l_575;
let l_576 = a_277[u32(1)];
let l_577 = a_266[u32(6)];
let l_578 = l_576 * l_577;
l_mut_279 = l_mut_279 + l_578;
let l_579 = a_277[u32(2)];
let l_580 = a_266[u32(5)];
let l_581 = l_579 * l_580;
l_mut_279 = l_mut_279 + l_581;
let l_582 = a_277[u32(3)];
let l_583 = a_266[u32(4)];
let l_584 = l_582 * l_583;
l_mut_279 = l_mut_279 + l_584;
let l_585 = a_277[u32(4)];
let l_586 = a_266[u32(3)];
let l_587 = l_585 * l_586;
l_mut_279 = l_mut_279 + l_587;
let l_588 = a_277[u32(5)];
let l_589 = a_266[u32(2)];
let l_590 = l_588 * l_589;
l_mut_279 = l_mut_279 + l_590;
let l_591 = a_277[u32(6)];
let l_592 = a_266[u32(1)];
let l_593 = l_591 * l_592;
l_mut_279 = l_mut_279 + l_593;
let l_594 = a_277[u32(7)];
let l_595 = a_266[u32(0)];
let l_596 = l_594 * l_595;
l_mut_279 = l_mut_279 + l_596;
let l_597 = l_mut_279 % u32(62);
let l_598 = l_mut_279 / u32(62);
l_mut_278 = l_598;
let l_599 = a_277[u32(7)];
let l_600 = u64(l_599);
let l_601 = u64(1) << u32(bitcast<u64>(l_600));
let l_602 = u64(l_597);
let l_603 = u64(1) << u32(bitcast<u64>(l_602));
let l_604 = l_601 | l_603;
let l_605 = l_599 == l_597;
let l_606 = l_mut_86 & l_604;
let l_607 = l_606 != u64(0);
let l_608 = l_605 || l_607;
if l_608 {
l_mut_404 = bool(false);
}
l_mut_86 = l_mut_86 | l_604;
if l_mut_404 {
l_mut_245 = u32(1);
}
}
let l_609 = subgroupExclusiveAdd(l_mut_245);
let l_610 = subgroupAdd(l_mut_245);
let l_611 = subgroup_invocation_id == u32(0);
if l_611 {
shared_memory_0[l_239] = l_610;
}
workgroupBarrier();
l_mut_279 = u32(0);
l_mut_278 = u32(0);
l_mut_271 = u32(0);
loop {
let l_612 = l_mut_271 < l_240;
let l_613 = !l_612;
if l_613 {
break;
}
let l_614 = shared_memory_0[l_mut_271];
let l_615 = l_mut_271 < l_239;
if l_615 {
l_mut_279 = l_mut_279 + l_614;
}
l_mut_278 = l_mut_278 + l_614;
l_mut_271 = l_mut_271 + u32(1);
}
let l_616 = local_invocation_id.x == u32(0);
let l_617 = l_mut_278 > u32(0);
let l_618 = l_616 && l_617;
if l_618 {
let l_619 = &buffer_11_global[u32(0)];
let l_620 = atomicAdd(l_619, l_mut_278);shared_memory_9[u32(0)] = l_620;
}
workgroupBarrier();
let l_621 = l_mut_245 != u32(0);
if l_621 {
let l_622 = shared_memory_9[u32(0)];
let l_623 = l_622 + l_mut_279;
let l_624 = l_623 + l_609;
let l_625 = l_624 < info.scalars_u32[2];
if l_625 {
let l_626 = u32(2) * l_624;
buffer_10_global[l_626] = l_mut_246;
let l_627 = u32(2) * l_624;
let l_628 = l_627 + u32(1);
buffer_10_global[l_628] = l_mut_247;
}
}
l_mut_241 = l_mut_241 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_629 = local_invocation_id.x == u32(0);
if l_629 {
let l_630 = &shared_memory_8[u32(0)];
atomicStore(l_630,u32(0));
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
let l_631 = &shared_memory_8[u32(0)];
let l_632 = atomicLoad(l_631);
let l_633 = l_632 > u32(0);
if l_633 {
l_mut_279 = l_632;
let l_634 = l_mut_279 > u32(1024);
if l_634 {
l_mut_279 = u32(1024);
}
let l_635 = local_invocation_id.x == u32(0);
if l_635 {
let l_636 = &buffer_13_global[u32(0)];
let l_637 = atomicAdd(l_636, l_mut_279);}
let l_638 = local_invocation_id.x / subgroup_size;
let l_639 = WORKGROUP_SIZE_X / subgroup_size;
l_mut_278 = u32(0);
loop {
let l_640 = l_mut_278 < l_mut_279;
let l_641 = !l_640;
if l_641 {
break;
}
let l_642 = l_mut_278 + local_invocation_id.x;
l_mut_271 = u32(0);
l_mut_267 = u32(0);
l_mut_247 = u32(0);
let l_643 = l_642 < l_mut_279;
if l_643 {
let l_644 = shared_memory_6[l_642];
l_mut_267 = l_644;
let l_645 = shared_memory_7[l_642];
l_mut_247 = l_645;
let l_646 = u32(2) * l_mut_267;
let l_647 = buffer_12_global[l_646];
l_mut_86 = u64(0);
let l_648 = u32(2) * l_mut_267;
let l_649 = l_648 + u32(1);
let l_650 = buffer_12_global[l_649];
let l_651 = l_650 != u32(0);
if l_651 {
let l_652 = u32(2) * l_mut_267;
let l_653 = l_652 + u32(1);
let l_654 = buffer_8_global[l_653];
let l_655 = u64(l_654);
let l_656 = l_655 << u32(bitcast<u64>(u64(32)));
let l_657 = u32(2) * l_mut_267;
let l_658 = buffer_8_global[l_657];
let l_659 = u64(l_658);
let l_660 = l_656 | l_659;
l_mut_86 = l_660;
}
l_mut_246 = l_mut_247;
let l_662 = l_mut_246 % u32(62);
a_661[u32(0)] = l_662;
l_mut_246 = l_mut_246 / u32(62);
let l_663 = l_mut_246 % u32(62);
a_661[u32(1)] = l_663;
l_mut_246 = l_mut_246 / u32(62);
let l_664 = l_mut_246 % u32(62);
a_661[u32(2)] = l_664;
l_mut_246 = l_mut_246 / u32(62);
l_mut_245 = l_647;
let l_665 = l_mut_245 % u32(62);
a_661[u32(3)] = l_665;
l_mut_245 = l_mut_245 / u32(62);
let l_666 = l_mut_245 % u32(62);
a_661[u32(4)] = l_666;
l_mut_245 = l_mut_245 / u32(62);
let l_667 = l_mut_245 % u32(62);
a_661[u32(5)] = l_667;
l_mut_245 = l_mut_245 / u32(62);
let l_668 = l_mut_245 % u32(62);
a_661[u32(6)] = l_668;
l_mut_245 = l_mut_245 / u32(62);
let l_669 = l_mut_245 % u32(62);
a_661[u32(7)] = l_669;
l_mut_245 = l_mut_245 / u32(62);
l_mut_241 = u32(0);
l_mut_180 = l_mut_241;
let l_671 = a_661[u32(0)];
let l_672 = a_661[u32(0)];
let l_673 = l_671 * l_672;
l_mut_180 = l_mut_180 + l_673;
let l_674 = l_mut_180 % u32(62);
a_670[u32(0)] = l_674;
let l_675 = l_mut_180 / u32(62);
l_mut_241 = l_675;
l_mut_180 = l_mut_241;
let l_676 = a_661[u32(0)];
let l_677 = a_661[u32(1)];
let l_678 = l_676 * l_677;
l_mut_180 = l_mut_180 + l_678;
let l_679 = a_661[u32(1)];
let l_680 = a_661[u32(0)];
let l_681 = l_679 * l_680;
l_mut_180 = l_mut_180 + l_681;
let l_682 = l_mut_180 % u32(62);
a_670[u32(1)] = l_682;
let l_683 = l_mut_180 / u32(62);
l_mut_241 = l_683;
l_mut_180 = l_mut_241;
let l_684 = a_661[u32(0)];
let l_685 = a_661[u32(2)];
let l_686 = l_684 * l_685;
l_mut_180 = l_mut_180 + l_686;
let l_687 = a_661[u32(1)];
let l_688 = a_661[u32(1)];
let l_689 = l_687 * l_688;
l_mut_180 = l_mut_180 + l_689;
let l_690 = a_661[u32(2)];
let l_691 = a_661[u32(0)];
let l_692 = l_690 * l_691;
l_mut_180 = l_mut_180 + l_692;
let l_693 = l_mut_180 % u32(62);
a_670[u32(2)] = l_693;
let l_694 = l_mut_180 / u32(62);
l_mut_241 = l_694;
l_mut_180 = l_mut_241;
let l_695 = a_661[u32(0)];
let l_696 = a_661[u32(3)];
let l_697 = l_695 * l_696;
l_mut_180 = l_mut_180 + l_697;
let l_698 = a_661[u32(1)];
let l_699 = a_661[u32(2)];
let l_700 = l_698 * l_699;
l_mut_180 = l_mut_180 + l_700;
let l_701 = a_661[u32(2)];
let l_702 = a_661[u32(1)];
let l_703 = l_701 * l_702;
l_mut_180 = l_mut_180 + l_703;
let l_704 = a_661[u32(3)];
let l_705 = a_661[u32(0)];
let l_706 = l_704 * l_705;
l_mut_180 = l_mut_180 + l_706;
let l_707 = l_mut_180 % u32(62);
a_670[u32(3)] = l_707;
let l_708 = l_mut_180 / u32(62);
l_mut_241 = l_708;
l_mut_180 = l_mut_241;
let l_709 = a_661[u32(0)];
let l_710 = a_661[u32(4)];
let l_711 = l_709 * l_710;
l_mut_180 = l_mut_180 + l_711;
let l_712 = a_661[u32(1)];
let l_713 = a_661[u32(3)];
let l_714 = l_712 * l_713;
l_mut_180 = l_mut_180 + l_714;
let l_715 = a_661[u32(2)];
let l_716 = a_661[u32(2)];
let l_717 = l_715 * l_716;
l_mut_180 = l_mut_180 + l_717;
let l_718 = a_661[u32(3)];
let l_719 = a_661[u32(1)];
let l_720 = l_718 * l_719;
l_mut_180 = l_mut_180 + l_720;
let l_721 = a_661[u32(4)];
let l_722 = a_661[u32(0)];
let l_723 = l_721 * l_722;
l_mut_180 = l_mut_180 + l_723;
let l_724 = l_mut_180 % u32(62);
a_670[u32(4)] = l_724;
let l_725 = l_mut_180 / u32(62);
l_mut_241 = l_725;
l_mut_180 = l_mut_241;
let l_726 = a_661[u32(0)];
let l_727 = a_661[u32(5)];
let l_728 = l_726 * l_727;
l_mut_180 = l_mut_180 + l_728;
let l_729 = a_661[u32(1)];
let l_730 = a_661[u32(4)];
let l_731 = l_729 * l_730;
l_mut_180 = l_mut_180 + l_731;
let l_732 = a_661[u32(2)];
let l_733 = a_661[u32(3)];
let l_734 = l_732 * l_733;
l_mut_180 = l_mut_180 + l_734;
let l_735 = a_661[u32(3)];
let l_736 = a_661[u32(2)];
let l_737 = l_735 * l_736;
l_mut_180 = l_mut_180 + l_737;
let l_738 = a_661[u32(4)];
let l_739 = a_661[u32(1)];
let l_740 = l_738 * l_739;
l_mut_180 = l_mut_180 + l_740;
let l_741 = a_661[u32(5)];
let l_742 = a_661[u32(0)];
let l_743 = l_741 * l_742;
l_mut_180 = l_mut_180 + l_743;
let l_744 = l_mut_180 % u32(62);
a_670[u32(5)] = l_744;
let l_745 = l_mut_180 / u32(62);
l_mut_241 = l_745;
l_mut_180 = l_mut_241;
let l_746 = a_661[u32(0)];
let l_747 = a_661[u32(6)];
let l_748 = l_746 * l_747;
l_mut_180 = l_mut_180 + l_748;
let l_749 = a_661[u32(1)];
let l_750 = a_661[u32(5)];
let l_751 = l_749 * l_750;
l_mut_180 = l_mut_180 + l_751;
let l_752 = a_661[u32(2)];
let l_753 = a_661[u32(4)];
let l_754 = l_752 * l_753;
l_mut_180 = l_mut_180 + l_754;
let l_755 = a_661[u32(3)];
let l_756 = a_661[u32(3)];
let l_757 = l_755 * l_756;
l_mut_180 = l_mut_180 + l_757;
let l_758 = a_661[u32(4)];
let l_759 = a_661[u32(2)];
let l_760 = l_758 * l_759;
l_mut_180 = l_mut_180 + l_760;
let l_761 = a_661[u32(5)];
let l_762 = a_661[u32(1)];
let l_763 = l_761 * l_762;
l_mut_180 = l_mut_180 + l_763;
let l_764 = a_661[u32(6)];
let l_765 = a_661[u32(0)];
let l_766 = l_764 * l_765;
l_mut_180 = l_mut_180 + l_766;
let l_767 = l_mut_180 % u32(62);
a_670[u32(6)] = l_767;
let l_768 = l_mut_180 / u32(62);
l_mut_241 = l_768;
l_mut_180 = l_mut_241;
let l_769 = a_661[u32(0)];
let l_770 = a_661[u32(7)];
let l_771 = l_769 * l_770;
l_mut_180 = l_mut_180 + l_771;
let l_772 = a_661[u32(1)];
let l_773 = a_661[u32(6)];
let l_774 = l_772 * l_773;
l_mut_180 = l_mut_180 + l_774;
let l_775 = a_661[u32(2)];
let l_776 = a_661[u32(5)];
let l_777 = l_775 * l_776;
l_mut_180 = l_mut_180 + l_777;
let l_778 = a_661[u32(3)];
let l_779 = a_661[u32(4)];
let l_780 = l_778 * l_779;
l_mut_180 = l_mut_180 + l_780;
let l_781 = a_661[u32(4)];
let l_782 = a_661[u32(3)];
let l_783 = l_781 * l_782;
l_mut_180 = l_mut_180 + l_783;
let l_784 = a_661[u32(5)];
let l_785 = a_661[u32(2)];
let l_786 = l_784 * l_785;
l_mut_180 = l_mut_180 + l_786;
let l_787 = a_661[u32(6)];
let l_788 = a_661[u32(1)];
let l_789 = l_787 * l_788;
l_mut_180 = l_mut_180 + l_789;
let l_790 = a_661[u32(7)];
let l_791 = a_661[u32(0)];
let l_792 = l_790 * l_791;
l_mut_180 = l_mut_180 + l_792;
let l_793 = l_mut_180 % u32(62);
a_670[u32(7)] = l_793;
let l_794 = l_mut_180 / u32(62);
l_mut_241 = l_794;
l_mut_404 = bool(true);
l_mut_241 = u32(0);
l_mut_180 = l_mut_241;
let l_795 = a_670[u32(0)];
let l_796 = a_661[u32(0)];
let l_797 = l_795 * l_796;
l_mut_180 = l_mut_180 + l_797;
let l_798 = l_mut_180 % u32(62);
let l_799 = l_mut_180 / u32(62);
l_mut_241 = l_799;
let l_800 = a_670[u32(0)];
let l_801 = u64(l_800);
let l_802 = u64(1) << u32(bitcast<u64>(l_801));
let l_803 = u64(l_798);
let l_804 = u64(1) << u32(bitcast<u64>(l_803));
let l_805 = l_802 | l_804;
let l_806 = l_800 == l_798;
let l_807 = l_mut_86 & l_805;
let l_808 = l_807 != u64(0);
let l_809 = l_806 || l_808;
if l_809 {
l_mut_404 = bool(false);
}
l_mut_86 = l_mut_86 | l_805;
l_mut_180 = l_mut_241;
let l_810 = a_670[u32(0)];
let l_811 = a_661[u32(1)];
let l_812 = l_810 * l_811;
l_mut_180 = l_mut_180 + l_812;
let l_813 = a_670[u32(1)];
let l_814 = a_661[u32(0)];
let l_815 = l_813 * l_814;
l_mut_180 = l_mut_180 + l_815;
let l_816 = l_mut_180 % u32(62);
let l_817 = l_mut_180 / u32(62);
l_mut_241 = l_817;
let l_818 = a_670[u32(1)];
let l_819 = u64(l_818);
let l_820 = u64(1) << u32(bitcast<u64>(l_819));
let l_821 = u64(l_816);
let l_822 = u64(1) << u32(bitcast<u64>(l_821));
let l_823 = l_820 | l_822;
let l_824 = l_818 == l_816;
let l_825 = l_mut_86 & l_823;
let l_826 = l_825 != u64(0);
let l_827 = l_824 || l_826;
if l_827 {
l_mut_404 = bool(false);
}
l_mut_86 = l_mut_86 | l_823;
l_mut_180 = l_mut_241;
let l_828 = a_670[u32(0)];
let l_829 = a_661[u32(2)];
let l_830 = l_828 * l_829;
l_mut_180 = l_mut_180 + l_830;
let l_831 = a_670[u32(1)];
let l_832 = a_661[u32(1)];
let l_833 = l_831 * l_832;
l_mut_180 = l_mut_180 + l_833;
let l_834 = a_670[u32(2)];
let l_835 = a_661[u32(0)];
let l_836 = l_834 * l_835;
l_mut_180 = l_mut_180 + l_836;
let l_837 = l_mut_180 % u32(62);
let l_838 = l_mut_180 / u32(62);
l_mut_241 = l_838;
let l_839 = a_670[u32(2)];
let l_840 = u64(l_839);
let l_841 = u64(1) << u32(bitcast<u64>(l_840));
let l_842 = u64(l_837);
let l_843 = u64(1) << u32(bitcast<u64>(l_842));
let l_844 = l_841 | l_843;
let l_845 = l_839 == l_837;
let l_846 = l_mut_86 & l_844;
let l_847 = l_846 != u64(0);
let l_848 = l_845 || l_847;
if l_848 {
l_mut_404 = bool(false);
}
l_mut_86 = l_mut_86 | l_844;
l_mut_180 = l_mut_241;
let l_849 = a_670[u32(0)];
let l_850 = a_661[u32(3)];
let l_851 = l_849 * l_850;
l_mut_180 = l_mut_180 + l_851;
let l_852 = a_670[u32(1)];
let l_853 = a_661[u32(2)];
let l_854 = l_852 * l_853;
l_mut_180 = l_mut_180 + l_854;
let l_855 = a_670[u32(2)];
let l_856 = a_661[u32(1)];
let l_857 = l_855 * l_856;
l_mut_180 = l_mut_180 + l_857;
let l_858 = a_670[u32(3)];
let l_859 = a_661[u32(0)];
let l_860 = l_858 * l_859;
l_mut_180 = l_mut_180 + l_860;
let l_861 = l_mut_180 % u32(62);
let l_862 = l_mut_180 / u32(62);
l_mut_241 = l_862;
let l_863 = a_670[u32(3)];
let l_864 = u64(l_863);
let l_865 = u64(1) << u32(bitcast<u64>(l_864));
let l_866 = u64(l_861);
let l_867 = u64(1) << u32(bitcast<u64>(l_866));
let l_868 = l_865 | l_867;
let l_869 = l_863 == l_861;
let l_870 = l_mut_86 & l_868;
let l_871 = l_870 != u64(0);
let l_872 = l_869 || l_871;
if l_872 {
l_mut_404 = bool(false);
}
l_mut_86 = l_mut_86 | l_868;
l_mut_180 = l_mut_241;
let l_873 = a_670[u32(0)];
let l_874 = a_661[u32(4)];
let l_875 = l_873 * l_874;
l_mut_180 = l_mut_180 + l_875;
let l_876 = a_670[u32(1)];
let l_877 = a_661[u32(3)];
let l_878 = l_876 * l_877;
l_mut_180 = l_mut_180 + l_878;
let l_879 = a_670[u32(2)];
let l_880 = a_661[u32(2)];
let l_881 = l_879 * l_880;
l_mut_180 = l_mut_180 + l_881;
let l_882 = a_670[u32(3)];
let l_883 = a_661[u32(1)];
let l_884 = l_882 * l_883;
l_mut_180 = l_mut_180 + l_884;
let l_885 = a_670[u32(4)];
let l_886 = a_661[u32(0)];
let l_887 = l_885 * l_886;
l_mut_180 = l_mut_180 + l_887;
let l_888 = l_mut_180 % u32(62);
let l_889 = l_mut_180 / u32(62);
l_mut_241 = l_889;
let l_890 = a_670[u32(4)];
let l_891 = u64(l_890);
let l_892 = u64(1) << u32(bitcast<u64>(l_891));
let l_893 = u64(l_888);
let l_894 = u64(1) << u32(bitcast<u64>(l_893));
let l_895 = l_892 | l_894;
let l_896 = l_890 == l_888;
let l_897 = l_mut_86 & l_895;
let l_898 = l_897 != u64(0);
let l_899 = l_896 || l_898;
if l_899 {
l_mut_404 = bool(false);
}
l_mut_86 = l_mut_86 | l_895;
l_mut_180 = l_mut_241;
let l_900 = a_670[u32(0)];
let l_901 = a_661[u32(5)];
let l_902 = l_900 * l_901;
l_mut_180 = l_mut_180 + l_902;
let l_903 = a_670[u32(1)];
let l_904 = a_661[u32(4)];
let l_905 = l_903 * l_904;
l_mut_180 = l_mut_180 + l_905;
let l_906 = a_670[u32(2)];
let l_907 = a_661[u32(3)];
let l_908 = l_906 * l_907;
l_mut_180 = l_mut_180 + l_908;
let l_909 = a_670[u32(3)];
let l_910 = a_661[u32(2)];
let l_911 = l_909 * l_910;
l_mut_180 = l_mut_180 + l_911;
let l_912 = a_670[u32(4)];
let l_913 = a_661[u32(1)];
let l_914 = l_912 * l_913;
l_mut_180 = l_mut_180 + l_914;
let l_915 = a_670[u32(5)];
let l_916 = a_661[u32(0)];
let l_917 = l_915 * l_916;
l_mut_180 = l_mut_180 + l_917;
let l_918 = l_mut_180 % u32(62);
let l_919 = l_mut_180 / u32(62);
l_mut_241 = l_919;
let l_920 = a_670[u32(5)];
let l_921 = u64(l_920);
let l_922 = u64(1) << u32(bitcast<u64>(l_921));
let l_923 = u64(l_918);
let l_924 = u64(1) << u32(bitcast<u64>(l_923));
let l_925 = l_922 | l_924;
let l_926 = l_920 == l_918;
let l_927 = l_mut_86 & l_925;
let l_928 = l_927 != u64(0);
let l_929 = l_926 || l_928;
if l_929 {
l_mut_404 = bool(false);
}
l_mut_86 = l_mut_86 | l_925;
l_mut_180 = l_mut_241;
let l_930 = a_670[u32(0)];
let l_931 = a_661[u32(6)];
let l_932 = l_930 * l_931;
l_mut_180 = l_mut_180 + l_932;
let l_933 = a_670[u32(1)];
let l_934 = a_661[u32(5)];
let l_935 = l_933 * l_934;
l_mut_180 = l_mut_180 + l_935;
let l_936 = a_670[u32(2)];
let l_937 = a_661[u32(4)];
let l_938 = l_936 * l_937;
l_mut_180 = l_mut_180 + l_938;
let l_939 = a_670[u32(3)];
let l_940 = a_661[u32(3)];
let l_941 = l_939 * l_940;
l_mut_180 = l_mut_180 + l_941;
let l_942 = a_670[u32(4)];
let l_943 = a_661[u32(2)];
let l_944 = l_942 * l_943;
l_mut_180 = l_mut_180 + l_944;
let l_945 = a_670[u32(5)];
let l_946 = a_661[u32(1)];
let l_947 = l_945 * l_946;
l_mut_180 = l_mut_180 + l_947;
let l_948 = a_670[u32(6)];
let l_949 = a_661[u32(0)];
let l_950 = l_948 * l_949;
l_mut_180 = l_mut_180 + l_950;
let l_951 = l_mut_180 % u32(62);
let l_952 = l_mut_180 / u32(62);
l_mut_241 = l_952;
let l_953 = a_670[u32(6)];
let l_954 = u64(l_953);
let l_955 = u64(1) << u32(bitcast<u64>(l_954));
let l_956 = u64(l_951);
let l_957 = u64(1) << u32(bitcast<u64>(l_956));
let l_958 = l_955 | l_957;
let l_959 = l_953 == l_951;
let l_960 = l_mut_86 & l_958;
let l_961 = l_960 != u64(0);
let l_962 = l_959 || l_961;
if l_962 {
l_mut_404 = bool(false);
}
l_mut_86 = l_mut_86 | l_958;
l_mut_180 = l_mut_241;
let l_963 = a_670[u32(0)];
let l_964 = a_661[u32(7)];
let l_965 = l_963 * l_964;
l_mut_180 = l_mut_180 + l_965;
let l_966 = a_670[u32(1)];
let l_967 = a_661[u32(6)];
let l_968 = l_966 * l_967;
l_mut_180 = l_mut_180 + l_968;
let l_969 = a_670[u32(2)];
let l_970 = a_661[u32(5)];
let l_971 = l_969 * l_970;
l_mut_180 = l_mut_180 + l_971;
let l_972 = a_670[u32(3)];
let l_973 = a_661[u32(4)];
let l_974 = l_972 * l_973;
l_mut_180 = l_mut_180 + l_974;
let l_975 = a_670[u32(4)];
let l_976 = a_661[u32(3)];
let l_977 = l_975 * l_976;
l_mut_180 = l_mut_180 + l_977;
let l_978 = a_670[u32(5)];
let l_979 = a_661[u32(2)];
let l_980 = l_978 * l_979;
l_mut_180 = l_mut_180 + l_980;
let l_981 = a_670[u32(6)];
let l_982 = a_661[u32(1)];
let l_983 = l_981 * l_982;
l_mut_180 = l_mut_180 + l_983;
let l_984 = a_670[u32(7)];
let l_985 = a_661[u32(0)];
let l_986 = l_984 * l_985;
l_mut_180 = l_mut_180 + l_986;
let l_987 = l_mut_180 % u32(62);
let l_988 = l_mut_180 / u32(62);
l_mut_241 = l_988;
let l_989 = a_670[u32(7)];
let l_990 = u64(l_989);
let l_991 = u64(1) << u32(bitcast<u64>(l_990));
let l_992 = u64(l_987);
let l_993 = u64(1) << u32(bitcast<u64>(l_992));
let l_994 = l_991 | l_993;
let l_995 = l_989 == l_987;
let l_996 = l_mut_86 & l_994;
let l_997 = l_996 != u64(0);
let l_998 = l_995 || l_997;
if l_998 {
l_mut_404 = bool(false);
}
l_mut_86 = l_mut_86 | l_994;
if l_mut_404 {
l_mut_271 = u32(1);
}
}
let l_999 = subgroupExclusiveAdd(l_mut_271);
let l_1000 = subgroupAdd(l_mut_271);
let l_1001 = subgroup_invocation_id == u32(0);
if l_1001 {
shared_memory_0[l_638] = l_1000;
}
workgroupBarrier();
l_mut_246 = u32(0);
l_mut_245 = u32(0);
l_mut_241 = u32(0);
loop {
let l_1002 = l_mut_241 < l_639;
let l_1003 = !l_1002;
if l_1003 {
break;
}
let l_1004 = shared_memory_0[l_mut_241];
let l_1005 = l_mut_241 < l_638;
if l_1005 {
l_mut_246 = l_mut_246 + l_1004;
}
l_mut_245 = l_mut_245 + l_1004;
l_mut_241 = l_mut_241 + u32(1);
}
let l_1006 = local_invocation_id.x == u32(0);
let l_1007 = l_mut_245 > u32(0);
let l_1008 = l_1006 && l_1007;
if l_1008 {
let l_1009 = &buffer_11_global[u32(0)];
let l_1010 = atomicAdd(l_1009, l_mut_245);shared_memory_9[u32(0)] = l_1010;
}
workgroupBarrier();
let l_1011 = l_mut_271 != u32(0);
if l_1011 {
let l_1012 = shared_memory_9[u32(0)];
let l_1013 = l_1012 + l_mut_246;
let l_1014 = l_1013 + l_999;
let l_1015 = l_1014 < info.scalars_u32[2];
if l_1015 {
let l_1016 = u32(2) * l_1014;
buffer_10_global[l_1016] = l_mut_267;
let l_1017 = u32(2) * l_1014;
let l_1018 = l_1017 + u32(1);
buffer_10_global[l_1018] = l_mut_247;
}
}
l_mut_278 = l_mut_278 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_1019 = local_invocation_id.x == u32(0);
if l_1019 {
let l_1020 = &shared_memory_8[u32(0)];
atomicStore(l_1020,u32(0));
}
}
workgroupBarrier();
let l_1021 = local_invocation_id.x == u32(0);
if l_1021 {
let l_1022 = &buffer_14_global[u32(4)];
let l_1023 = atomicAdd(l_1022, u32(1));}
}
```
