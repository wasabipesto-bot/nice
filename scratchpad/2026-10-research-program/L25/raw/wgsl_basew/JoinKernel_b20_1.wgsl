
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

var a_116: array<u32, 2>;

var a_230: array<u32, 5>;

var a_238: array<u32, 5>;

var a_454: array<u32, 5>;

var a_460: array<u32, 5>;

var l_mut_296: bool;
var l_mut_12: u32;
var l_mut_45: u32;
var l_mut_49: u32;
var l_mut_64: u32;
var l_mut_110: u32;
var l_mut_114: u32;
var l_mut_117: u32;
var l_mut_118: u32;
var l_mut_144: u32;
var l_mut_205: u32;
var l_mut_209: u32;
var l_mut_210: u32;
var l_mut_211: u32;
var l_mut_231: u32;
var l_mut_234: u32;
var l_mut_239: u32;
var l_mut_240: u32;
var l_mut_86: u64;
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
let l_33 = l_16 * u32(1);
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
let l_87 = u32(bitcast<u64>(l_mut_86));
a_67[u32(0)] = l_87;
let l_88 = l_mut_86 >> u32(bitcast<u64>(u64(32)));
let l_89 = u32(bitcast<u64>(l_88));
a_68[u32(0)] = l_89;
let l_90 = buffer_2_global[l_75];
a_69[u32(0)] = l_90;
}
let l_91 = l_mut_64 + local_invocation_id.x;
let l_92 = l_91 + u32(256);
a_67[u32(1)] = u32(4294967295);
a_68[u32(1)] = u32(4294967295);
a_69[u32(1)] = u32(0);
a_70[u32(1)] = u32(0);
let l_93 = l_92 < l_37;
if l_93 {
a_70[u32(1)] = u32(4294967295);
let l_94 = l_43 + l_92;
let l_95 = buffer_4_global[l_94];
let l_96 = l_44 + l_95;
let l_97 = u32(2) * l_96;
let l_98 = l_97 + u32(1);
let l_99 = buffer_0_global[l_98];
let l_100 = u64(l_99);
let l_101 = l_100 << u32(bitcast<u64>(u64(32)));
let l_102 = u32(2) * l_96;
let l_103 = buffer_0_global[l_102];
let l_104 = u64(l_103);
let l_105 = l_101 | l_104;
l_mut_86 = l_105;
let l_106 = u32(bitcast<u64>(l_mut_86));
a_67[u32(1)] = l_106;
let l_107 = l_mut_86 >> u32(bitcast<u64>(u64(32)));
let l_108 = u32(bitcast<u64>(l_107));
a_68[u32(1)] = l_108;
let l_109 = buffer_2_global[l_95];
a_69[u32(1)] = l_109;
}
l_mut_110 = u32(0);
loop {
let l_111 = l_mut_110 < l_mut_49;
let l_112 = !l_111;
if l_112 {
break;
}
let l_113 = l_mut_110 + u32(32);
l_mut_114 = l_113;
let l_115 = l_mut_114 > l_mut_49;
if l_115 {
l_mut_114 = l_mut_49;
}
a_116[u32(0)] = u32(0);
a_116[u32(1)] = u32(0);
l_mut_117 = l_mut_110;
l_mut_118 = u32(1);
loop {
let l_119 = l_mut_117 < l_mut_114;
let l_120 = !l_119;
if l_120 {
break;
}
let l_121 = shared_memory_1[l_mut_117];
let l_122 = shared_memory_2[l_mut_117];
let l_123 = a_67[u32(0)];
let l_124 = l_123 & l_121;
let l_125 = a_68[u32(0)];
let l_126 = l_125 & l_122;
let l_127 = l_124 | l_126;
let l_128 = l_127 == u32(0);
let l_129 = select(u32(0), l_mut_118, l_128);
let l_130 = a_116[u32(0)];
let l_131 = l_130 | l_129;
a_116[u32(0)] = l_131;
let l_132 = a_67[u32(1)];
let l_133 = l_132 & l_121;
let l_134 = a_68[u32(1)];
let l_135 = l_134 & l_122;
let l_136 = l_133 | l_135;
let l_137 = l_136 == u32(0);
let l_138 = select(u32(0), l_mut_118, l_137);
let l_139 = a_116[u32(1)];
let l_140 = l_139 | l_138;
a_116[u32(1)] = l_140;
l_mut_118 = l_mut_118 << u32(1);
l_mut_117 = l_mut_117 + u32(1);
}
let l_141 = a_116[u32(0)];
let l_142 = a_70[u32(0)];
let l_143 = l_141 & l_142;
l_mut_144 = l_143;
let l_145 = a_69[u32(0)];
loop {
let l_146 = l_mut_144 != u32(0);
let l_147 = subgroupAny(l_146);
let l_148 = !l_147;
if l_148 {
break;
}
let l_149 = l_mut_144 != u32(0);
if l_149 {
let l_150 = countTrailingZeros(l_mut_144);
let l_151 = l_mut_110 + l_150;
let l_152 = l_mut_144 - u32(1);
l_mut_144 = l_mut_144 & l_152;
let l_153 = shared_memory_3[l_151];
let l_154 = l_145 >= l_153;
let l_155 = shared_memory_4[l_151];
let l_156 = l_145 < l_155;
let l_157 = l_154 && l_156;
if l_157 {
let l_158 = &shared_memory_8[u32(0)];
let l_159 = atomicAdd(l_158, u32(1));let l_160 = l_159 < u32(1024);
if l_160 {
let l_161 = shared_memory_5[l_151];
shared_memory_6[l_159] = l_161;
shared_memory_7[l_159] = l_145;
} else {
let l_162 = &buffer_11_global[u32(0)];
let l_163 = atomicAdd(l_162, u32(1));let l_164 = l_163 < info.scalars_u32[2];
if l_164 {
let l_165 = u32(2) * l_163;
let l_166 = shared_memory_5[l_151];
buffer_10_global[l_165] = l_166;
let l_167 = u32(2) * l_163;
let l_168 = l_167 + u32(1);
buffer_10_global[l_168] = l_145;
}
}
}
}
}
let l_169 = a_116[u32(1)];
let l_170 = a_70[u32(1)];
let l_171 = l_169 & l_170;
l_mut_144 = l_171;
let l_172 = a_69[u32(1)];
loop {
let l_173 = l_mut_144 != u32(0);
let l_174 = subgroupAny(l_173);
let l_175 = !l_174;
if l_175 {
break;
}
let l_176 = l_mut_144 != u32(0);
if l_176 {
let l_177 = countTrailingZeros(l_mut_144);
let l_178 = l_mut_110 + l_177;
let l_179 = l_mut_144 - u32(1);
l_mut_144 = l_mut_144 & l_179;
let l_180 = shared_memory_3[l_178];
let l_181 = l_172 >= l_180;
let l_182 = shared_memory_4[l_178];
let l_183 = l_172 < l_182;
let l_184 = l_181 && l_183;
if l_184 {
let l_185 = &shared_memory_8[u32(0)];
let l_186 = atomicAdd(l_185, u32(1));let l_187 = l_186 < u32(1024);
if l_187 {
let l_188 = shared_memory_5[l_178];
shared_memory_6[l_186] = l_188;
shared_memory_7[l_186] = l_172;
} else {
let l_189 = &buffer_11_global[u32(0)];
let l_190 = atomicAdd(l_189, u32(1));let l_191 = l_190 < info.scalars_u32[2];
if l_191 {
let l_192 = u32(2) * l_190;
let l_193 = shared_memory_5[l_178];
buffer_10_global[l_192] = l_193;
let l_194 = u32(2) * l_190;
let l_195 = l_194 + u32(1);
buffer_10_global[l_195] = l_172;
}
}
}
}
}
workgroupBarrier();
let l_196 = &shared_memory_8[u32(0)];
let l_197 = atomicLoad(l_196);
workgroupBarrier();
let l_198 = l_197 >= u32(512);
if l_198 {
l_mut_144 = l_197;
let l_199 = l_mut_144 > u32(1024);
if l_199 {
l_mut_144 = u32(1024);
}
let l_200 = local_invocation_id.x == u32(0);
if l_200 {
let l_201 = &buffer_13_global[u32(0)];
let l_202 = atomicAdd(l_201, l_mut_144);}
let l_203 = local_invocation_id.x / subgroup_size;
let l_204 = WORKGROUP_SIZE_X / subgroup_size;
l_mut_205 = u32(0);
loop {
let l_206 = l_mut_205 < l_mut_144;
let l_207 = !l_206;
if l_207 {
break;
}
let l_208 = l_mut_205 + local_invocation_id.x;
l_mut_209 = u32(0);
l_mut_210 = u32(0);
l_mut_211 = u32(0);
let l_212 = l_208 < l_mut_144;
if l_212 {
let l_213 = shared_memory_6[l_208];
l_mut_210 = l_213;
let l_214 = shared_memory_7[l_208];
l_mut_211 = l_214;
let l_215 = u32(2) * l_mut_210;
let l_216 = buffer_12_global[l_215];
l_mut_86 = u64(0);
let l_217 = u32(2) * l_mut_210;
let l_218 = l_217 + u32(1);
let l_219 = buffer_12_global[l_218];
let l_220 = l_219 != u32(0);
if l_220 {
let l_221 = u32(2) * l_mut_210;
let l_222 = l_221 + u32(1);
let l_223 = buffer_8_global[l_222];
let l_224 = u64(l_223);
let l_225 = l_224 << u32(bitcast<u64>(u64(32)));
let l_226 = u32(2) * l_mut_210;
let l_227 = buffer_8_global[l_226];
let l_228 = u64(l_227);
let l_229 = l_225 | l_228;
l_mut_86 = l_229;
}
l_mut_231 = l_mut_211;
let l_232 = l_mut_231 % u32(20);
a_230[u32(0)] = l_232;
l_mut_231 = l_mut_231 / u32(20);
let l_233 = l_mut_231 % u32(20);
a_230[u32(1)] = l_233;
l_mut_231 = l_mut_231 / u32(20);
l_mut_234 = l_216;
let l_235 = l_mut_234 % u32(20);
a_230[u32(2)] = l_235;
l_mut_234 = l_mut_234 / u32(20);
let l_236 = l_mut_234 % u32(20);
a_230[u32(3)] = l_236;
l_mut_234 = l_mut_234 / u32(20);
let l_237 = l_mut_234 % u32(20);
a_230[u32(4)] = l_237;
l_mut_234 = l_mut_234 / u32(20);
l_mut_239 = u32(0);
l_mut_240 = l_mut_239;
let l_241 = a_230[u32(0)];
let l_242 = a_230[u32(0)];
let l_243 = l_241 * l_242;
l_mut_240 = l_mut_240 + l_243;
let l_244 = l_mut_240 % u32(20);
a_238[u32(0)] = l_244;
let l_245 = l_mut_240 / u32(20);
l_mut_239 = l_245;
l_mut_240 = l_mut_239;
let l_246 = a_230[u32(0)];
let l_247 = a_230[u32(1)];
let l_248 = l_246 * l_247;
l_mut_240 = l_mut_240 + l_248;
let l_249 = a_230[u32(1)];
let l_250 = a_230[u32(0)];
let l_251 = l_249 * l_250;
l_mut_240 = l_mut_240 + l_251;
let l_252 = l_mut_240 % u32(20);
a_238[u32(1)] = l_252;
let l_253 = l_mut_240 / u32(20);
l_mut_239 = l_253;
l_mut_240 = l_mut_239;
let l_254 = a_230[u32(0)];
let l_255 = a_230[u32(2)];
let l_256 = l_254 * l_255;
l_mut_240 = l_mut_240 + l_256;
let l_257 = a_230[u32(1)];
let l_258 = a_230[u32(1)];
let l_259 = l_257 * l_258;
l_mut_240 = l_mut_240 + l_259;
let l_260 = a_230[u32(2)];
let l_261 = a_230[u32(0)];
let l_262 = l_260 * l_261;
l_mut_240 = l_mut_240 + l_262;
let l_263 = l_mut_240 % u32(20);
a_238[u32(2)] = l_263;
let l_264 = l_mut_240 / u32(20);
l_mut_239 = l_264;
l_mut_240 = l_mut_239;
let l_265 = a_230[u32(0)];
let l_266 = a_230[u32(3)];
let l_267 = l_265 * l_266;
l_mut_240 = l_mut_240 + l_267;
let l_268 = a_230[u32(1)];
let l_269 = a_230[u32(2)];
let l_270 = l_268 * l_269;
l_mut_240 = l_mut_240 + l_270;
let l_271 = a_230[u32(2)];
let l_272 = a_230[u32(1)];
let l_273 = l_271 * l_272;
l_mut_240 = l_mut_240 + l_273;
let l_274 = a_230[u32(3)];
let l_275 = a_230[u32(0)];
let l_276 = l_274 * l_275;
l_mut_240 = l_mut_240 + l_276;
let l_277 = l_mut_240 % u32(20);
a_238[u32(3)] = l_277;
let l_278 = l_mut_240 / u32(20);
l_mut_239 = l_278;
l_mut_240 = l_mut_239;
let l_279 = a_230[u32(0)];
let l_280 = a_230[u32(4)];
let l_281 = l_279 * l_280;
l_mut_240 = l_mut_240 + l_281;
let l_282 = a_230[u32(1)];
let l_283 = a_230[u32(3)];
let l_284 = l_282 * l_283;
l_mut_240 = l_mut_240 + l_284;
let l_285 = a_230[u32(2)];
let l_286 = a_230[u32(2)];
let l_287 = l_285 * l_286;
l_mut_240 = l_mut_240 + l_287;
let l_288 = a_230[u32(3)];
let l_289 = a_230[u32(1)];
let l_290 = l_288 * l_289;
l_mut_240 = l_mut_240 + l_290;
let l_291 = a_230[u32(4)];
let l_292 = a_230[u32(0)];
let l_293 = l_291 * l_292;
l_mut_240 = l_mut_240 + l_293;
let l_294 = l_mut_240 % u32(20);
a_238[u32(4)] = l_294;
let l_295 = l_mut_240 / u32(20);
l_mut_239 = l_295;
l_mut_296 = bool(true);
l_mut_239 = u32(0);
l_mut_240 = l_mut_239;
let l_297 = a_238[u32(0)];
let l_298 = a_230[u32(0)];
let l_299 = l_297 * l_298;
l_mut_240 = l_mut_240 + l_299;
let l_300 = l_mut_240 % u32(20);
let l_301 = l_mut_240 / u32(20);
l_mut_239 = l_301;
let l_302 = a_238[u32(0)];
let l_303 = u64(l_302);
let l_304 = u64(1) << u32(bitcast<u64>(l_303));
let l_305 = u64(l_300);
let l_306 = u64(1) << u32(bitcast<u64>(l_305));
let l_307 = l_304 | l_306;
let l_308 = l_302 == l_300;
let l_309 = l_mut_86 & l_307;
let l_310 = l_309 != u64(0);
let l_311 = l_308 || l_310;
if l_311 {
l_mut_296 = bool(false);
}
l_mut_86 = l_mut_86 | l_307;
l_mut_240 = l_mut_239;
let l_312 = a_238[u32(0)];
let l_313 = a_230[u32(1)];
let l_314 = l_312 * l_313;
l_mut_240 = l_mut_240 + l_314;
let l_315 = a_238[u32(1)];
let l_316 = a_230[u32(0)];
let l_317 = l_315 * l_316;
l_mut_240 = l_mut_240 + l_317;
let l_318 = l_mut_240 % u32(20);
let l_319 = l_mut_240 / u32(20);
l_mut_239 = l_319;
let l_320 = a_238[u32(1)];
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
l_mut_296 = bool(false);
}
l_mut_86 = l_mut_86 | l_325;
l_mut_240 = l_mut_239;
let l_330 = a_238[u32(0)];
let l_331 = a_230[u32(2)];
let l_332 = l_330 * l_331;
l_mut_240 = l_mut_240 + l_332;
let l_333 = a_238[u32(1)];
let l_334 = a_230[u32(1)];
let l_335 = l_333 * l_334;
l_mut_240 = l_mut_240 + l_335;
let l_336 = a_238[u32(2)];
let l_337 = a_230[u32(0)];
let l_338 = l_336 * l_337;
l_mut_240 = l_mut_240 + l_338;
let l_339 = l_mut_240 % u32(20);
let l_340 = l_mut_240 / u32(20);
l_mut_239 = l_340;
let l_341 = a_238[u32(2)];
let l_342 = u64(l_341);
let l_343 = u64(1) << u32(bitcast<u64>(l_342));
let l_344 = u64(l_339);
let l_345 = u64(1) << u32(bitcast<u64>(l_344));
let l_346 = l_343 | l_345;
let l_347 = l_341 == l_339;
let l_348 = l_mut_86 & l_346;
let l_349 = l_348 != u64(0);
let l_350 = l_347 || l_349;
if l_350 {
l_mut_296 = bool(false);
}
l_mut_86 = l_mut_86 | l_346;
l_mut_240 = l_mut_239;
let l_351 = a_238[u32(0)];
let l_352 = a_230[u32(3)];
let l_353 = l_351 * l_352;
l_mut_240 = l_mut_240 + l_353;
let l_354 = a_238[u32(1)];
let l_355 = a_230[u32(2)];
let l_356 = l_354 * l_355;
l_mut_240 = l_mut_240 + l_356;
let l_357 = a_238[u32(2)];
let l_358 = a_230[u32(1)];
let l_359 = l_357 * l_358;
l_mut_240 = l_mut_240 + l_359;
let l_360 = a_238[u32(3)];
let l_361 = a_230[u32(0)];
let l_362 = l_360 * l_361;
l_mut_240 = l_mut_240 + l_362;
let l_363 = l_mut_240 % u32(20);
let l_364 = l_mut_240 / u32(20);
l_mut_239 = l_364;
let l_365 = a_238[u32(3)];
let l_366 = u64(l_365);
let l_367 = u64(1) << u32(bitcast<u64>(l_366));
let l_368 = u64(l_363);
let l_369 = u64(1) << u32(bitcast<u64>(l_368));
let l_370 = l_367 | l_369;
let l_371 = l_365 == l_363;
let l_372 = l_mut_86 & l_370;
let l_373 = l_372 != u64(0);
let l_374 = l_371 || l_373;
if l_374 {
l_mut_296 = bool(false);
}
l_mut_86 = l_mut_86 | l_370;
l_mut_240 = l_mut_239;
let l_375 = a_238[u32(0)];
let l_376 = a_230[u32(4)];
let l_377 = l_375 * l_376;
l_mut_240 = l_mut_240 + l_377;
let l_378 = a_238[u32(1)];
let l_379 = a_230[u32(3)];
let l_380 = l_378 * l_379;
l_mut_240 = l_mut_240 + l_380;
let l_381 = a_238[u32(2)];
let l_382 = a_230[u32(2)];
let l_383 = l_381 * l_382;
l_mut_240 = l_mut_240 + l_383;
let l_384 = a_238[u32(3)];
let l_385 = a_230[u32(1)];
let l_386 = l_384 * l_385;
l_mut_240 = l_mut_240 + l_386;
let l_387 = a_238[u32(4)];
let l_388 = a_230[u32(0)];
let l_389 = l_387 * l_388;
l_mut_240 = l_mut_240 + l_389;
let l_390 = l_mut_240 % u32(20);
let l_391 = l_mut_240 / u32(20);
l_mut_239 = l_391;
let l_392 = a_238[u32(4)];
let l_393 = u64(l_392);
let l_394 = u64(1) << u32(bitcast<u64>(l_393));
let l_395 = u64(l_390);
let l_396 = u64(1) << u32(bitcast<u64>(l_395));
let l_397 = l_394 | l_396;
let l_398 = l_392 == l_390;
let l_399 = l_mut_86 & l_397;
let l_400 = l_399 != u64(0);
let l_401 = l_398 || l_400;
if l_401 {
l_mut_296 = bool(false);
}
l_mut_86 = l_mut_86 | l_397;
if l_mut_296 {
l_mut_209 = u32(1);
}
}
let l_402 = subgroupExclusiveAdd(l_mut_209);
let l_403 = subgroupAdd(l_mut_209);
let l_404 = subgroup_invocation_id == u32(0);
if l_404 {
shared_memory_0[l_203] = l_403;
}
workgroupBarrier();
l_mut_240 = u32(0);
l_mut_239 = u32(0);
l_mut_234 = u32(0);
loop {
let l_405 = l_mut_234 < l_204;
let l_406 = !l_405;
if l_406 {
break;
}
let l_407 = shared_memory_0[l_mut_234];
let l_408 = l_mut_234 < l_203;
if l_408 {
l_mut_240 = l_mut_240 + l_407;
}
l_mut_239 = l_mut_239 + l_407;
l_mut_234 = l_mut_234 + u32(1);
}
let l_409 = local_invocation_id.x == u32(0);
let l_410 = l_mut_239 > u32(0);
let l_411 = l_409 && l_410;
if l_411 {
let l_412 = &buffer_11_global[u32(0)];
let l_413 = atomicAdd(l_412, l_mut_239);shared_memory_9[u32(0)] = l_413;
}
workgroupBarrier();
let l_414 = l_mut_209 != u32(0);
if l_414 {
let l_415 = shared_memory_9[u32(0)];
let l_416 = l_415 + l_mut_240;
let l_417 = l_416 + l_402;
let l_418 = l_417 < info.scalars_u32[2];
if l_418 {
let l_419 = u32(2) * l_417;
buffer_10_global[l_419] = l_mut_210;
let l_420 = u32(2) * l_417;
let l_421 = l_420 + u32(1);
buffer_10_global[l_421] = l_mut_211;
}
}
l_mut_205 = l_mut_205 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_422 = local_invocation_id.x == u32(0);
if l_422 {
let l_423 = &shared_memory_8[u32(0)];
atomicStore(l_423,u32(0));
}
workgroupBarrier();
}
l_mut_110 = l_mut_110 + u32(32);
}
l_mut_64 = l_mut_64 + u32(512);
}
l_mut_45 = l_mut_45 + u32(256);
workgroupBarrier();
}
l_mut_12 = l_mut_12 + num_workgroups.x;
}
workgroupBarrier();
let l_424 = &shared_memory_8[u32(0)];
let l_425 = atomicLoad(l_424);
let l_426 = l_425 > u32(0);
if l_426 {
l_mut_240 = l_425;
let l_427 = l_mut_240 > u32(1024);
if l_427 {
l_mut_240 = u32(1024);
}
let l_428 = local_invocation_id.x == u32(0);
if l_428 {
let l_429 = &buffer_13_global[u32(0)];
let l_430 = atomicAdd(l_429, l_mut_240);}
let l_431 = local_invocation_id.x / subgroup_size;
let l_432 = WORKGROUP_SIZE_X / subgroup_size;
l_mut_239 = u32(0);
loop {
let l_433 = l_mut_239 < l_mut_240;
let l_434 = !l_433;
if l_434 {
break;
}
let l_435 = l_mut_239 + local_invocation_id.x;
l_mut_234 = u32(0);
l_mut_231 = u32(0);
l_mut_211 = u32(0);
let l_436 = l_435 < l_mut_240;
if l_436 {
let l_437 = shared_memory_6[l_435];
l_mut_231 = l_437;
let l_438 = shared_memory_7[l_435];
l_mut_211 = l_438;
let l_439 = u32(2) * l_mut_231;
let l_440 = buffer_12_global[l_439];
l_mut_86 = u64(0);
let l_441 = u32(2) * l_mut_231;
let l_442 = l_441 + u32(1);
let l_443 = buffer_12_global[l_442];
let l_444 = l_443 != u32(0);
if l_444 {
let l_445 = u32(2) * l_mut_231;
let l_446 = l_445 + u32(1);
let l_447 = buffer_8_global[l_446];
let l_448 = u64(l_447);
let l_449 = l_448 << u32(bitcast<u64>(u64(32)));
let l_450 = u32(2) * l_mut_231;
let l_451 = buffer_8_global[l_450];
let l_452 = u64(l_451);
let l_453 = l_449 | l_452;
l_mut_86 = l_453;
}
l_mut_210 = l_mut_211;
let l_455 = l_mut_210 % u32(20);
a_454[u32(0)] = l_455;
l_mut_210 = l_mut_210 / u32(20);
let l_456 = l_mut_210 % u32(20);
a_454[u32(1)] = l_456;
l_mut_210 = l_mut_210 / u32(20);
l_mut_209 = l_440;
let l_457 = l_mut_209 % u32(20);
a_454[u32(2)] = l_457;
l_mut_209 = l_mut_209 / u32(20);
let l_458 = l_mut_209 % u32(20);
a_454[u32(3)] = l_458;
l_mut_209 = l_mut_209 / u32(20);
let l_459 = l_mut_209 % u32(20);
a_454[u32(4)] = l_459;
l_mut_209 = l_mut_209 / u32(20);
l_mut_205 = u32(0);
l_mut_144 = l_mut_205;
let l_461 = a_454[u32(0)];
let l_462 = a_454[u32(0)];
let l_463 = l_461 * l_462;
l_mut_144 = l_mut_144 + l_463;
let l_464 = l_mut_144 % u32(20);
a_460[u32(0)] = l_464;
let l_465 = l_mut_144 / u32(20);
l_mut_205 = l_465;
l_mut_144 = l_mut_205;
let l_466 = a_454[u32(0)];
let l_467 = a_454[u32(1)];
let l_468 = l_466 * l_467;
l_mut_144 = l_mut_144 + l_468;
let l_469 = a_454[u32(1)];
let l_470 = a_454[u32(0)];
let l_471 = l_469 * l_470;
l_mut_144 = l_mut_144 + l_471;
let l_472 = l_mut_144 % u32(20);
a_460[u32(1)] = l_472;
let l_473 = l_mut_144 / u32(20);
l_mut_205 = l_473;
l_mut_144 = l_mut_205;
let l_474 = a_454[u32(0)];
let l_475 = a_454[u32(2)];
let l_476 = l_474 * l_475;
l_mut_144 = l_mut_144 + l_476;
let l_477 = a_454[u32(1)];
let l_478 = a_454[u32(1)];
let l_479 = l_477 * l_478;
l_mut_144 = l_mut_144 + l_479;
let l_480 = a_454[u32(2)];
let l_481 = a_454[u32(0)];
let l_482 = l_480 * l_481;
l_mut_144 = l_mut_144 + l_482;
let l_483 = l_mut_144 % u32(20);
a_460[u32(2)] = l_483;
let l_484 = l_mut_144 / u32(20);
l_mut_205 = l_484;
l_mut_144 = l_mut_205;
let l_485 = a_454[u32(0)];
let l_486 = a_454[u32(3)];
let l_487 = l_485 * l_486;
l_mut_144 = l_mut_144 + l_487;
let l_488 = a_454[u32(1)];
let l_489 = a_454[u32(2)];
let l_490 = l_488 * l_489;
l_mut_144 = l_mut_144 + l_490;
let l_491 = a_454[u32(2)];
let l_492 = a_454[u32(1)];
let l_493 = l_491 * l_492;
l_mut_144 = l_mut_144 + l_493;
let l_494 = a_454[u32(3)];
let l_495 = a_454[u32(0)];
let l_496 = l_494 * l_495;
l_mut_144 = l_mut_144 + l_496;
let l_497 = l_mut_144 % u32(20);
a_460[u32(3)] = l_497;
let l_498 = l_mut_144 / u32(20);
l_mut_205 = l_498;
l_mut_144 = l_mut_205;
let l_499 = a_454[u32(0)];
let l_500 = a_454[u32(4)];
let l_501 = l_499 * l_500;
l_mut_144 = l_mut_144 + l_501;
let l_502 = a_454[u32(1)];
let l_503 = a_454[u32(3)];
let l_504 = l_502 * l_503;
l_mut_144 = l_mut_144 + l_504;
let l_505 = a_454[u32(2)];
let l_506 = a_454[u32(2)];
let l_507 = l_505 * l_506;
l_mut_144 = l_mut_144 + l_507;
let l_508 = a_454[u32(3)];
let l_509 = a_454[u32(1)];
let l_510 = l_508 * l_509;
l_mut_144 = l_mut_144 + l_510;
let l_511 = a_454[u32(4)];
let l_512 = a_454[u32(0)];
let l_513 = l_511 * l_512;
l_mut_144 = l_mut_144 + l_513;
let l_514 = l_mut_144 % u32(20);
a_460[u32(4)] = l_514;
let l_515 = l_mut_144 / u32(20);
l_mut_205 = l_515;
l_mut_296 = bool(true);
l_mut_205 = u32(0);
l_mut_144 = l_mut_205;
let l_516 = a_460[u32(0)];
let l_517 = a_454[u32(0)];
let l_518 = l_516 * l_517;
l_mut_144 = l_mut_144 + l_518;
let l_519 = l_mut_144 % u32(20);
let l_520 = l_mut_144 / u32(20);
l_mut_205 = l_520;
let l_521 = a_460[u32(0)];
let l_522 = u64(l_521);
let l_523 = u64(1) << u32(bitcast<u64>(l_522));
let l_524 = u64(l_519);
let l_525 = u64(1) << u32(bitcast<u64>(l_524));
let l_526 = l_523 | l_525;
let l_527 = l_521 == l_519;
let l_528 = l_mut_86 & l_526;
let l_529 = l_528 != u64(0);
let l_530 = l_527 || l_529;
if l_530 {
l_mut_296 = bool(false);
}
l_mut_86 = l_mut_86 | l_526;
l_mut_144 = l_mut_205;
let l_531 = a_460[u32(0)];
let l_532 = a_454[u32(1)];
let l_533 = l_531 * l_532;
l_mut_144 = l_mut_144 + l_533;
let l_534 = a_460[u32(1)];
let l_535 = a_454[u32(0)];
let l_536 = l_534 * l_535;
l_mut_144 = l_mut_144 + l_536;
let l_537 = l_mut_144 % u32(20);
let l_538 = l_mut_144 / u32(20);
l_mut_205 = l_538;
let l_539 = a_460[u32(1)];
let l_540 = u64(l_539);
let l_541 = u64(1) << u32(bitcast<u64>(l_540));
let l_542 = u64(l_537);
let l_543 = u64(1) << u32(bitcast<u64>(l_542));
let l_544 = l_541 | l_543;
let l_545 = l_539 == l_537;
let l_546 = l_mut_86 & l_544;
let l_547 = l_546 != u64(0);
let l_548 = l_545 || l_547;
if l_548 {
l_mut_296 = bool(false);
}
l_mut_86 = l_mut_86 | l_544;
l_mut_144 = l_mut_205;
let l_549 = a_460[u32(0)];
let l_550 = a_454[u32(2)];
let l_551 = l_549 * l_550;
l_mut_144 = l_mut_144 + l_551;
let l_552 = a_460[u32(1)];
let l_553 = a_454[u32(1)];
let l_554 = l_552 * l_553;
l_mut_144 = l_mut_144 + l_554;
let l_555 = a_460[u32(2)];
let l_556 = a_454[u32(0)];
let l_557 = l_555 * l_556;
l_mut_144 = l_mut_144 + l_557;
let l_558 = l_mut_144 % u32(20);
let l_559 = l_mut_144 / u32(20);
l_mut_205 = l_559;
let l_560 = a_460[u32(2)];
let l_561 = u64(l_560);
let l_562 = u64(1) << u32(bitcast<u64>(l_561));
let l_563 = u64(l_558);
let l_564 = u64(1) << u32(bitcast<u64>(l_563));
let l_565 = l_562 | l_564;
let l_566 = l_560 == l_558;
let l_567 = l_mut_86 & l_565;
let l_568 = l_567 != u64(0);
let l_569 = l_566 || l_568;
if l_569 {
l_mut_296 = bool(false);
}
l_mut_86 = l_mut_86 | l_565;
l_mut_144 = l_mut_205;
let l_570 = a_460[u32(0)];
let l_571 = a_454[u32(3)];
let l_572 = l_570 * l_571;
l_mut_144 = l_mut_144 + l_572;
let l_573 = a_460[u32(1)];
let l_574 = a_454[u32(2)];
let l_575 = l_573 * l_574;
l_mut_144 = l_mut_144 + l_575;
let l_576 = a_460[u32(2)];
let l_577 = a_454[u32(1)];
let l_578 = l_576 * l_577;
l_mut_144 = l_mut_144 + l_578;
let l_579 = a_460[u32(3)];
let l_580 = a_454[u32(0)];
let l_581 = l_579 * l_580;
l_mut_144 = l_mut_144 + l_581;
let l_582 = l_mut_144 % u32(20);
let l_583 = l_mut_144 / u32(20);
l_mut_205 = l_583;
let l_584 = a_460[u32(3)];
let l_585 = u64(l_584);
let l_586 = u64(1) << u32(bitcast<u64>(l_585));
let l_587 = u64(l_582);
let l_588 = u64(1) << u32(bitcast<u64>(l_587));
let l_589 = l_586 | l_588;
let l_590 = l_584 == l_582;
let l_591 = l_mut_86 & l_589;
let l_592 = l_591 != u64(0);
let l_593 = l_590 || l_592;
if l_593 {
l_mut_296 = bool(false);
}
l_mut_86 = l_mut_86 | l_589;
l_mut_144 = l_mut_205;
let l_594 = a_460[u32(0)];
let l_595 = a_454[u32(4)];
let l_596 = l_594 * l_595;
l_mut_144 = l_mut_144 + l_596;
let l_597 = a_460[u32(1)];
let l_598 = a_454[u32(3)];
let l_599 = l_597 * l_598;
l_mut_144 = l_mut_144 + l_599;
let l_600 = a_460[u32(2)];
let l_601 = a_454[u32(2)];
let l_602 = l_600 * l_601;
l_mut_144 = l_mut_144 + l_602;
let l_603 = a_460[u32(3)];
let l_604 = a_454[u32(1)];
let l_605 = l_603 * l_604;
l_mut_144 = l_mut_144 + l_605;
let l_606 = a_460[u32(4)];
let l_607 = a_454[u32(0)];
let l_608 = l_606 * l_607;
l_mut_144 = l_mut_144 + l_608;
let l_609 = l_mut_144 % u32(20);
let l_610 = l_mut_144 / u32(20);
l_mut_205 = l_610;
let l_611 = a_460[u32(4)];
let l_612 = u64(l_611);
let l_613 = u64(1) << u32(bitcast<u64>(l_612));
let l_614 = u64(l_609);
let l_615 = u64(1) << u32(bitcast<u64>(l_614));
let l_616 = l_613 | l_615;
let l_617 = l_611 == l_609;
let l_618 = l_mut_86 & l_616;
let l_619 = l_618 != u64(0);
let l_620 = l_617 || l_619;
if l_620 {
l_mut_296 = bool(false);
}
l_mut_86 = l_mut_86 | l_616;
if l_mut_296 {
l_mut_234 = u32(1);
}
}
let l_621 = subgroupExclusiveAdd(l_mut_234);
let l_622 = subgroupAdd(l_mut_234);
let l_623 = subgroup_invocation_id == u32(0);
if l_623 {
shared_memory_0[l_431] = l_622;
}
workgroupBarrier();
l_mut_210 = u32(0);
l_mut_209 = u32(0);
l_mut_205 = u32(0);
loop {
let l_624 = l_mut_205 < l_432;
let l_625 = !l_624;
if l_625 {
break;
}
let l_626 = shared_memory_0[l_mut_205];
let l_627 = l_mut_205 < l_431;
if l_627 {
l_mut_210 = l_mut_210 + l_626;
}
l_mut_209 = l_mut_209 + l_626;
l_mut_205 = l_mut_205 + u32(1);
}
let l_628 = local_invocation_id.x == u32(0);
let l_629 = l_mut_209 > u32(0);
let l_630 = l_628 && l_629;
if l_630 {
let l_631 = &buffer_11_global[u32(0)];
let l_632 = atomicAdd(l_631, l_mut_209);shared_memory_9[u32(0)] = l_632;
}
workgroupBarrier();
let l_633 = l_mut_234 != u32(0);
if l_633 {
let l_634 = shared_memory_9[u32(0)];
let l_635 = l_634 + l_mut_210;
let l_636 = l_635 + l_621;
let l_637 = l_636 < info.scalars_u32[2];
if l_637 {
let l_638 = u32(2) * l_636;
buffer_10_global[l_638] = l_mut_231;
let l_639 = u32(2) * l_636;
let l_640 = l_639 + u32(1);
buffer_10_global[l_640] = l_mut_211;
}
}
l_mut_239 = l_mut_239 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_641 = local_invocation_id.x == u32(0);
if l_641 {
let l_642 = &shared_memory_8[u32(0)];
atomicStore(l_642,u32(0));
}
}
workgroupBarrier();
let l_643 = local_invocation_id.x == u32(0);
if l_643 {
let l_644 = &buffer_14_global[u32(4)];
let l_645 = atomicAdd(l_644, u32(1));}
}
```
