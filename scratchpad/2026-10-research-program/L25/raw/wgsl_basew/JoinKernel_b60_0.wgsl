
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

var a_230: array<u32, 6>;

var a_239: array<u32, 6>;

var a_505: array<u32, 6>;

var a_512: array<u32, 6>;

var l_mut_86: u64;
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
var l_mut_240: u32;
var l_mut_241: u32;
var l_mut_317: bool;
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
let l_26 = l_19 / u32(59);
let l_27 = l_26 * u32(59);
let l_28 = l_19 - l_27;
let l_29 = buffer_3_global[l_28];
let l_30 = l_28 + u32(1);
let l_31 = buffer_3_global[l_30];
let l_32 = l_31 - l_29;
let l_33 = l_16 * u32(1);
let l_34 = l_33 + l_26;
let l_35 = l_34 * u32(59);
let l_36 = l_35 + l_28;
let l_37 = buffer_5_global[l_36];
let l_38 = l_16 * u32(60);
let l_39 = l_38 * info.scalars_u32[1];
let l_40 = u32(60) * l_29;
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
let l_232 = l_mut_231 % u32(60);
a_230[u32(0)] = l_232;
l_mut_231 = l_mut_231 / u32(60);
let l_233 = l_mut_231 % u32(60);
a_230[u32(1)] = l_233;
l_mut_231 = l_mut_231 / u32(60);
l_mut_234 = l_216;
let l_235 = l_mut_234 % u32(60);
a_230[u32(2)] = l_235;
l_mut_234 = l_mut_234 / u32(60);
let l_236 = l_mut_234 % u32(60);
a_230[u32(3)] = l_236;
l_mut_234 = l_mut_234 / u32(60);
let l_237 = l_mut_234 % u32(60);
a_230[u32(4)] = l_237;
l_mut_234 = l_mut_234 / u32(60);
let l_238 = l_mut_234 % u32(60);
a_230[u32(5)] = l_238;
l_mut_234 = l_mut_234 / u32(60);
l_mut_240 = u32(0);
l_mut_241 = l_mut_240;
let l_242 = a_230[u32(0)];
let l_243 = a_230[u32(0)];
let l_244 = l_242 * l_243;
l_mut_241 = l_mut_241 + l_244;
let l_245 = l_mut_241 % u32(60);
a_239[u32(0)] = l_245;
let l_246 = l_mut_241 / u32(60);
l_mut_240 = l_246;
l_mut_241 = l_mut_240;
let l_247 = a_230[u32(0)];
let l_248 = a_230[u32(1)];
let l_249 = l_247 * l_248;
l_mut_241 = l_mut_241 + l_249;
let l_250 = a_230[u32(1)];
let l_251 = a_230[u32(0)];
let l_252 = l_250 * l_251;
l_mut_241 = l_mut_241 + l_252;
let l_253 = l_mut_241 % u32(60);
a_239[u32(1)] = l_253;
let l_254 = l_mut_241 / u32(60);
l_mut_240 = l_254;
l_mut_241 = l_mut_240;
let l_255 = a_230[u32(0)];
let l_256 = a_230[u32(2)];
let l_257 = l_255 * l_256;
l_mut_241 = l_mut_241 + l_257;
let l_258 = a_230[u32(1)];
let l_259 = a_230[u32(1)];
let l_260 = l_258 * l_259;
l_mut_241 = l_mut_241 + l_260;
let l_261 = a_230[u32(2)];
let l_262 = a_230[u32(0)];
let l_263 = l_261 * l_262;
l_mut_241 = l_mut_241 + l_263;
let l_264 = l_mut_241 % u32(60);
a_239[u32(2)] = l_264;
let l_265 = l_mut_241 / u32(60);
l_mut_240 = l_265;
l_mut_241 = l_mut_240;
let l_266 = a_230[u32(0)];
let l_267 = a_230[u32(3)];
let l_268 = l_266 * l_267;
l_mut_241 = l_mut_241 + l_268;
let l_269 = a_230[u32(1)];
let l_270 = a_230[u32(2)];
let l_271 = l_269 * l_270;
l_mut_241 = l_mut_241 + l_271;
let l_272 = a_230[u32(2)];
let l_273 = a_230[u32(1)];
let l_274 = l_272 * l_273;
l_mut_241 = l_mut_241 + l_274;
let l_275 = a_230[u32(3)];
let l_276 = a_230[u32(0)];
let l_277 = l_275 * l_276;
l_mut_241 = l_mut_241 + l_277;
let l_278 = l_mut_241 % u32(60);
a_239[u32(3)] = l_278;
let l_279 = l_mut_241 / u32(60);
l_mut_240 = l_279;
l_mut_241 = l_mut_240;
let l_280 = a_230[u32(0)];
let l_281 = a_230[u32(4)];
let l_282 = l_280 * l_281;
l_mut_241 = l_mut_241 + l_282;
let l_283 = a_230[u32(1)];
let l_284 = a_230[u32(3)];
let l_285 = l_283 * l_284;
l_mut_241 = l_mut_241 + l_285;
let l_286 = a_230[u32(2)];
let l_287 = a_230[u32(2)];
let l_288 = l_286 * l_287;
l_mut_241 = l_mut_241 + l_288;
let l_289 = a_230[u32(3)];
let l_290 = a_230[u32(1)];
let l_291 = l_289 * l_290;
l_mut_241 = l_mut_241 + l_291;
let l_292 = a_230[u32(4)];
let l_293 = a_230[u32(0)];
let l_294 = l_292 * l_293;
l_mut_241 = l_mut_241 + l_294;
let l_295 = l_mut_241 % u32(60);
a_239[u32(4)] = l_295;
let l_296 = l_mut_241 / u32(60);
l_mut_240 = l_296;
l_mut_241 = l_mut_240;
let l_297 = a_230[u32(0)];
let l_298 = a_230[u32(5)];
let l_299 = l_297 * l_298;
l_mut_241 = l_mut_241 + l_299;
let l_300 = a_230[u32(1)];
let l_301 = a_230[u32(4)];
let l_302 = l_300 * l_301;
l_mut_241 = l_mut_241 + l_302;
let l_303 = a_230[u32(2)];
let l_304 = a_230[u32(3)];
let l_305 = l_303 * l_304;
l_mut_241 = l_mut_241 + l_305;
let l_306 = a_230[u32(3)];
let l_307 = a_230[u32(2)];
let l_308 = l_306 * l_307;
l_mut_241 = l_mut_241 + l_308;
let l_309 = a_230[u32(4)];
let l_310 = a_230[u32(1)];
let l_311 = l_309 * l_310;
l_mut_241 = l_mut_241 + l_311;
let l_312 = a_230[u32(5)];
let l_313 = a_230[u32(0)];
let l_314 = l_312 * l_313;
l_mut_241 = l_mut_241 + l_314;
let l_315 = l_mut_241 % u32(60);
a_239[u32(5)] = l_315;
let l_316 = l_mut_241 / u32(60);
l_mut_240 = l_316;
l_mut_317 = bool(true);
l_mut_240 = u32(0);
l_mut_241 = l_mut_240;
let l_318 = a_239[u32(0)];
let l_319 = a_230[u32(0)];
let l_320 = l_318 * l_319;
l_mut_241 = l_mut_241 + l_320;
let l_321 = l_mut_241 % u32(60);
let l_322 = l_mut_241 / u32(60);
l_mut_240 = l_322;
let l_323 = a_239[u32(0)];
let l_324 = u64(l_323);
let l_325 = u64(1) << u32(bitcast<u64>(l_324));
let l_326 = u64(l_321);
let l_327 = u64(1) << u32(bitcast<u64>(l_326));
let l_328 = l_325 | l_327;
let l_329 = l_323 == l_321;
let l_330 = l_mut_86 & l_328;
let l_331 = l_330 != u64(0);
let l_332 = l_329 || l_331;
if l_332 {
l_mut_317 = bool(false);
}
l_mut_86 = l_mut_86 | l_328;
l_mut_241 = l_mut_240;
let l_333 = a_239[u32(0)];
let l_334 = a_230[u32(1)];
let l_335 = l_333 * l_334;
l_mut_241 = l_mut_241 + l_335;
let l_336 = a_239[u32(1)];
let l_337 = a_230[u32(0)];
let l_338 = l_336 * l_337;
l_mut_241 = l_mut_241 + l_338;
let l_339 = l_mut_241 % u32(60);
let l_340 = l_mut_241 / u32(60);
l_mut_240 = l_340;
let l_341 = a_239[u32(1)];
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
l_mut_317 = bool(false);
}
l_mut_86 = l_mut_86 | l_346;
l_mut_241 = l_mut_240;
let l_351 = a_239[u32(0)];
let l_352 = a_230[u32(2)];
let l_353 = l_351 * l_352;
l_mut_241 = l_mut_241 + l_353;
let l_354 = a_239[u32(1)];
let l_355 = a_230[u32(1)];
let l_356 = l_354 * l_355;
l_mut_241 = l_mut_241 + l_356;
let l_357 = a_239[u32(2)];
let l_358 = a_230[u32(0)];
let l_359 = l_357 * l_358;
l_mut_241 = l_mut_241 + l_359;
let l_360 = l_mut_241 % u32(60);
let l_361 = l_mut_241 / u32(60);
l_mut_240 = l_361;
let l_362 = a_239[u32(2)];
let l_363 = u64(l_362);
let l_364 = u64(1) << u32(bitcast<u64>(l_363));
let l_365 = u64(l_360);
let l_366 = u64(1) << u32(bitcast<u64>(l_365));
let l_367 = l_364 | l_366;
let l_368 = l_362 == l_360;
let l_369 = l_mut_86 & l_367;
let l_370 = l_369 != u64(0);
let l_371 = l_368 || l_370;
if l_371 {
l_mut_317 = bool(false);
}
l_mut_86 = l_mut_86 | l_367;
l_mut_241 = l_mut_240;
let l_372 = a_239[u32(0)];
let l_373 = a_230[u32(3)];
let l_374 = l_372 * l_373;
l_mut_241 = l_mut_241 + l_374;
let l_375 = a_239[u32(1)];
let l_376 = a_230[u32(2)];
let l_377 = l_375 * l_376;
l_mut_241 = l_mut_241 + l_377;
let l_378 = a_239[u32(2)];
let l_379 = a_230[u32(1)];
let l_380 = l_378 * l_379;
l_mut_241 = l_mut_241 + l_380;
let l_381 = a_239[u32(3)];
let l_382 = a_230[u32(0)];
let l_383 = l_381 * l_382;
l_mut_241 = l_mut_241 + l_383;
let l_384 = l_mut_241 % u32(60);
let l_385 = l_mut_241 / u32(60);
l_mut_240 = l_385;
let l_386 = a_239[u32(3)];
let l_387 = u64(l_386);
let l_388 = u64(1) << u32(bitcast<u64>(l_387));
let l_389 = u64(l_384);
let l_390 = u64(1) << u32(bitcast<u64>(l_389));
let l_391 = l_388 | l_390;
let l_392 = l_386 == l_384;
let l_393 = l_mut_86 & l_391;
let l_394 = l_393 != u64(0);
let l_395 = l_392 || l_394;
if l_395 {
l_mut_317 = bool(false);
}
l_mut_86 = l_mut_86 | l_391;
l_mut_241 = l_mut_240;
let l_396 = a_239[u32(0)];
let l_397 = a_230[u32(4)];
let l_398 = l_396 * l_397;
l_mut_241 = l_mut_241 + l_398;
let l_399 = a_239[u32(1)];
let l_400 = a_230[u32(3)];
let l_401 = l_399 * l_400;
l_mut_241 = l_mut_241 + l_401;
let l_402 = a_239[u32(2)];
let l_403 = a_230[u32(2)];
let l_404 = l_402 * l_403;
l_mut_241 = l_mut_241 + l_404;
let l_405 = a_239[u32(3)];
let l_406 = a_230[u32(1)];
let l_407 = l_405 * l_406;
l_mut_241 = l_mut_241 + l_407;
let l_408 = a_239[u32(4)];
let l_409 = a_230[u32(0)];
let l_410 = l_408 * l_409;
l_mut_241 = l_mut_241 + l_410;
let l_411 = l_mut_241 % u32(60);
let l_412 = l_mut_241 / u32(60);
l_mut_240 = l_412;
let l_413 = a_239[u32(4)];
let l_414 = u64(l_413);
let l_415 = u64(1) << u32(bitcast<u64>(l_414));
let l_416 = u64(l_411);
let l_417 = u64(1) << u32(bitcast<u64>(l_416));
let l_418 = l_415 | l_417;
let l_419 = l_413 == l_411;
let l_420 = l_mut_86 & l_418;
let l_421 = l_420 != u64(0);
let l_422 = l_419 || l_421;
if l_422 {
l_mut_317 = bool(false);
}
l_mut_86 = l_mut_86 | l_418;
l_mut_241 = l_mut_240;
let l_423 = a_239[u32(0)];
let l_424 = a_230[u32(5)];
let l_425 = l_423 * l_424;
l_mut_241 = l_mut_241 + l_425;
let l_426 = a_239[u32(1)];
let l_427 = a_230[u32(4)];
let l_428 = l_426 * l_427;
l_mut_241 = l_mut_241 + l_428;
let l_429 = a_239[u32(2)];
let l_430 = a_230[u32(3)];
let l_431 = l_429 * l_430;
l_mut_241 = l_mut_241 + l_431;
let l_432 = a_239[u32(3)];
let l_433 = a_230[u32(2)];
let l_434 = l_432 * l_433;
l_mut_241 = l_mut_241 + l_434;
let l_435 = a_239[u32(4)];
let l_436 = a_230[u32(1)];
let l_437 = l_435 * l_436;
l_mut_241 = l_mut_241 + l_437;
let l_438 = a_239[u32(5)];
let l_439 = a_230[u32(0)];
let l_440 = l_438 * l_439;
l_mut_241 = l_mut_241 + l_440;
let l_441 = l_mut_241 % u32(60);
let l_442 = l_mut_241 / u32(60);
l_mut_240 = l_442;
let l_443 = a_239[u32(5)];
let l_444 = u64(l_443);
let l_445 = u64(1) << u32(bitcast<u64>(l_444));
let l_446 = u64(l_441);
let l_447 = u64(1) << u32(bitcast<u64>(l_446));
let l_448 = l_445 | l_447;
let l_449 = l_443 == l_441;
let l_450 = l_mut_86 & l_448;
let l_451 = l_450 != u64(0);
let l_452 = l_449 || l_451;
if l_452 {
l_mut_317 = bool(false);
}
l_mut_86 = l_mut_86 | l_448;
if l_mut_317 {
l_mut_209 = u32(1);
}
}
let l_453 = subgroupExclusiveAdd(l_mut_209);
let l_454 = subgroupAdd(l_mut_209);
let l_455 = subgroup_invocation_id == u32(0);
if l_455 {
shared_memory_0[l_203] = l_454;
}
workgroupBarrier();
l_mut_241 = u32(0);
l_mut_240 = u32(0);
l_mut_234 = u32(0);
loop {
let l_456 = l_mut_234 < l_204;
let l_457 = !l_456;
if l_457 {
break;
}
let l_458 = shared_memory_0[l_mut_234];
let l_459 = l_mut_234 < l_203;
if l_459 {
l_mut_241 = l_mut_241 + l_458;
}
l_mut_240 = l_mut_240 + l_458;
l_mut_234 = l_mut_234 + u32(1);
}
let l_460 = local_invocation_id.x == u32(0);
let l_461 = l_mut_240 > u32(0);
let l_462 = l_460 && l_461;
if l_462 {
let l_463 = &buffer_11_global[u32(0)];
let l_464 = atomicAdd(l_463, l_mut_240);shared_memory_9[u32(0)] = l_464;
}
workgroupBarrier();
let l_465 = l_mut_209 != u32(0);
if l_465 {
let l_466 = shared_memory_9[u32(0)];
let l_467 = l_466 + l_mut_241;
let l_468 = l_467 + l_453;
let l_469 = l_468 < info.scalars_u32[2];
if l_469 {
let l_470 = u32(2) * l_468;
buffer_10_global[l_470] = l_mut_210;
let l_471 = u32(2) * l_468;
let l_472 = l_471 + u32(1);
buffer_10_global[l_472] = l_mut_211;
}
}
l_mut_205 = l_mut_205 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_473 = local_invocation_id.x == u32(0);
if l_473 {
let l_474 = &shared_memory_8[u32(0)];
atomicStore(l_474,u32(0));
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
let l_475 = &shared_memory_8[u32(0)];
let l_476 = atomicLoad(l_475);
let l_477 = l_476 > u32(0);
if l_477 {
l_mut_241 = l_476;
let l_478 = l_mut_241 > u32(1024);
if l_478 {
l_mut_241 = u32(1024);
}
let l_479 = local_invocation_id.x == u32(0);
if l_479 {
let l_480 = &buffer_13_global[u32(0)];
let l_481 = atomicAdd(l_480, l_mut_241);}
let l_482 = local_invocation_id.x / subgroup_size;
let l_483 = WORKGROUP_SIZE_X / subgroup_size;
l_mut_240 = u32(0);
loop {
let l_484 = l_mut_240 < l_mut_241;
let l_485 = !l_484;
if l_485 {
break;
}
let l_486 = l_mut_240 + local_invocation_id.x;
l_mut_234 = u32(0);
l_mut_231 = u32(0);
l_mut_211 = u32(0);
let l_487 = l_486 < l_mut_241;
if l_487 {
let l_488 = shared_memory_6[l_486];
l_mut_231 = l_488;
let l_489 = shared_memory_7[l_486];
l_mut_211 = l_489;
let l_490 = u32(2) * l_mut_231;
let l_491 = buffer_12_global[l_490];
l_mut_86 = u64(0);
let l_492 = u32(2) * l_mut_231;
let l_493 = l_492 + u32(1);
let l_494 = buffer_12_global[l_493];
let l_495 = l_494 != u32(0);
if l_495 {
let l_496 = u32(2) * l_mut_231;
let l_497 = l_496 + u32(1);
let l_498 = buffer_8_global[l_497];
let l_499 = u64(l_498);
let l_500 = l_499 << u32(bitcast<u64>(u64(32)));
let l_501 = u32(2) * l_mut_231;
let l_502 = buffer_8_global[l_501];
let l_503 = u64(l_502);
let l_504 = l_500 | l_503;
l_mut_86 = l_504;
}
l_mut_210 = l_mut_211;
let l_506 = l_mut_210 % u32(60);
a_505[u32(0)] = l_506;
l_mut_210 = l_mut_210 / u32(60);
let l_507 = l_mut_210 % u32(60);
a_505[u32(1)] = l_507;
l_mut_210 = l_mut_210 / u32(60);
l_mut_209 = l_491;
let l_508 = l_mut_209 % u32(60);
a_505[u32(2)] = l_508;
l_mut_209 = l_mut_209 / u32(60);
let l_509 = l_mut_209 % u32(60);
a_505[u32(3)] = l_509;
l_mut_209 = l_mut_209 / u32(60);
let l_510 = l_mut_209 % u32(60);
a_505[u32(4)] = l_510;
l_mut_209 = l_mut_209 / u32(60);
let l_511 = l_mut_209 % u32(60);
a_505[u32(5)] = l_511;
l_mut_209 = l_mut_209 / u32(60);
l_mut_205 = u32(0);
l_mut_144 = l_mut_205;
let l_513 = a_505[u32(0)];
let l_514 = a_505[u32(0)];
let l_515 = l_513 * l_514;
l_mut_144 = l_mut_144 + l_515;
let l_516 = l_mut_144 % u32(60);
a_512[u32(0)] = l_516;
let l_517 = l_mut_144 / u32(60);
l_mut_205 = l_517;
l_mut_144 = l_mut_205;
let l_518 = a_505[u32(0)];
let l_519 = a_505[u32(1)];
let l_520 = l_518 * l_519;
l_mut_144 = l_mut_144 + l_520;
let l_521 = a_505[u32(1)];
let l_522 = a_505[u32(0)];
let l_523 = l_521 * l_522;
l_mut_144 = l_mut_144 + l_523;
let l_524 = l_mut_144 % u32(60);
a_512[u32(1)] = l_524;
let l_525 = l_mut_144 / u32(60);
l_mut_205 = l_525;
l_mut_144 = l_mut_205;
let l_526 = a_505[u32(0)];
let l_527 = a_505[u32(2)];
let l_528 = l_526 * l_527;
l_mut_144 = l_mut_144 + l_528;
let l_529 = a_505[u32(1)];
let l_530 = a_505[u32(1)];
let l_531 = l_529 * l_530;
l_mut_144 = l_mut_144 + l_531;
let l_532 = a_505[u32(2)];
let l_533 = a_505[u32(0)];
let l_534 = l_532 * l_533;
l_mut_144 = l_mut_144 + l_534;
let l_535 = l_mut_144 % u32(60);
a_512[u32(2)] = l_535;
let l_536 = l_mut_144 / u32(60);
l_mut_205 = l_536;
l_mut_144 = l_mut_205;
let l_537 = a_505[u32(0)];
let l_538 = a_505[u32(3)];
let l_539 = l_537 * l_538;
l_mut_144 = l_mut_144 + l_539;
let l_540 = a_505[u32(1)];
let l_541 = a_505[u32(2)];
let l_542 = l_540 * l_541;
l_mut_144 = l_mut_144 + l_542;
let l_543 = a_505[u32(2)];
let l_544 = a_505[u32(1)];
let l_545 = l_543 * l_544;
l_mut_144 = l_mut_144 + l_545;
let l_546 = a_505[u32(3)];
let l_547 = a_505[u32(0)];
let l_548 = l_546 * l_547;
l_mut_144 = l_mut_144 + l_548;
let l_549 = l_mut_144 % u32(60);
a_512[u32(3)] = l_549;
let l_550 = l_mut_144 / u32(60);
l_mut_205 = l_550;
l_mut_144 = l_mut_205;
let l_551 = a_505[u32(0)];
let l_552 = a_505[u32(4)];
let l_553 = l_551 * l_552;
l_mut_144 = l_mut_144 + l_553;
let l_554 = a_505[u32(1)];
let l_555 = a_505[u32(3)];
let l_556 = l_554 * l_555;
l_mut_144 = l_mut_144 + l_556;
let l_557 = a_505[u32(2)];
let l_558 = a_505[u32(2)];
let l_559 = l_557 * l_558;
l_mut_144 = l_mut_144 + l_559;
let l_560 = a_505[u32(3)];
let l_561 = a_505[u32(1)];
let l_562 = l_560 * l_561;
l_mut_144 = l_mut_144 + l_562;
let l_563 = a_505[u32(4)];
let l_564 = a_505[u32(0)];
let l_565 = l_563 * l_564;
l_mut_144 = l_mut_144 + l_565;
let l_566 = l_mut_144 % u32(60);
a_512[u32(4)] = l_566;
let l_567 = l_mut_144 / u32(60);
l_mut_205 = l_567;
l_mut_144 = l_mut_205;
let l_568 = a_505[u32(0)];
let l_569 = a_505[u32(5)];
let l_570 = l_568 * l_569;
l_mut_144 = l_mut_144 + l_570;
let l_571 = a_505[u32(1)];
let l_572 = a_505[u32(4)];
let l_573 = l_571 * l_572;
l_mut_144 = l_mut_144 + l_573;
let l_574 = a_505[u32(2)];
let l_575 = a_505[u32(3)];
let l_576 = l_574 * l_575;
l_mut_144 = l_mut_144 + l_576;
let l_577 = a_505[u32(3)];
let l_578 = a_505[u32(2)];
let l_579 = l_577 * l_578;
l_mut_144 = l_mut_144 + l_579;
let l_580 = a_505[u32(4)];
let l_581 = a_505[u32(1)];
let l_582 = l_580 * l_581;
l_mut_144 = l_mut_144 + l_582;
let l_583 = a_505[u32(5)];
let l_584 = a_505[u32(0)];
let l_585 = l_583 * l_584;
l_mut_144 = l_mut_144 + l_585;
let l_586 = l_mut_144 % u32(60);
a_512[u32(5)] = l_586;
let l_587 = l_mut_144 / u32(60);
l_mut_205 = l_587;
l_mut_317 = bool(true);
l_mut_205 = u32(0);
l_mut_144 = l_mut_205;
let l_588 = a_512[u32(0)];
let l_589 = a_505[u32(0)];
let l_590 = l_588 * l_589;
l_mut_144 = l_mut_144 + l_590;
let l_591 = l_mut_144 % u32(60);
let l_592 = l_mut_144 / u32(60);
l_mut_205 = l_592;
let l_593 = a_512[u32(0)];
let l_594 = u64(l_593);
let l_595 = u64(1) << u32(bitcast<u64>(l_594));
let l_596 = u64(l_591);
let l_597 = u64(1) << u32(bitcast<u64>(l_596));
let l_598 = l_595 | l_597;
let l_599 = l_593 == l_591;
let l_600 = l_mut_86 & l_598;
let l_601 = l_600 != u64(0);
let l_602 = l_599 || l_601;
if l_602 {
l_mut_317 = bool(false);
}
l_mut_86 = l_mut_86 | l_598;
l_mut_144 = l_mut_205;
let l_603 = a_512[u32(0)];
let l_604 = a_505[u32(1)];
let l_605 = l_603 * l_604;
l_mut_144 = l_mut_144 + l_605;
let l_606 = a_512[u32(1)];
let l_607 = a_505[u32(0)];
let l_608 = l_606 * l_607;
l_mut_144 = l_mut_144 + l_608;
let l_609 = l_mut_144 % u32(60);
let l_610 = l_mut_144 / u32(60);
l_mut_205 = l_610;
let l_611 = a_512[u32(1)];
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
l_mut_317 = bool(false);
}
l_mut_86 = l_mut_86 | l_616;
l_mut_144 = l_mut_205;
let l_621 = a_512[u32(0)];
let l_622 = a_505[u32(2)];
let l_623 = l_621 * l_622;
l_mut_144 = l_mut_144 + l_623;
let l_624 = a_512[u32(1)];
let l_625 = a_505[u32(1)];
let l_626 = l_624 * l_625;
l_mut_144 = l_mut_144 + l_626;
let l_627 = a_512[u32(2)];
let l_628 = a_505[u32(0)];
let l_629 = l_627 * l_628;
l_mut_144 = l_mut_144 + l_629;
let l_630 = l_mut_144 % u32(60);
let l_631 = l_mut_144 / u32(60);
l_mut_205 = l_631;
let l_632 = a_512[u32(2)];
let l_633 = u64(l_632);
let l_634 = u64(1) << u32(bitcast<u64>(l_633));
let l_635 = u64(l_630);
let l_636 = u64(1) << u32(bitcast<u64>(l_635));
let l_637 = l_634 | l_636;
let l_638 = l_632 == l_630;
let l_639 = l_mut_86 & l_637;
let l_640 = l_639 != u64(0);
let l_641 = l_638 || l_640;
if l_641 {
l_mut_317 = bool(false);
}
l_mut_86 = l_mut_86 | l_637;
l_mut_144 = l_mut_205;
let l_642 = a_512[u32(0)];
let l_643 = a_505[u32(3)];
let l_644 = l_642 * l_643;
l_mut_144 = l_mut_144 + l_644;
let l_645 = a_512[u32(1)];
let l_646 = a_505[u32(2)];
let l_647 = l_645 * l_646;
l_mut_144 = l_mut_144 + l_647;
let l_648 = a_512[u32(2)];
let l_649 = a_505[u32(1)];
let l_650 = l_648 * l_649;
l_mut_144 = l_mut_144 + l_650;
let l_651 = a_512[u32(3)];
let l_652 = a_505[u32(0)];
let l_653 = l_651 * l_652;
l_mut_144 = l_mut_144 + l_653;
let l_654 = l_mut_144 % u32(60);
let l_655 = l_mut_144 / u32(60);
l_mut_205 = l_655;
let l_656 = a_512[u32(3)];
let l_657 = u64(l_656);
let l_658 = u64(1) << u32(bitcast<u64>(l_657));
let l_659 = u64(l_654);
let l_660 = u64(1) << u32(bitcast<u64>(l_659));
let l_661 = l_658 | l_660;
let l_662 = l_656 == l_654;
let l_663 = l_mut_86 & l_661;
let l_664 = l_663 != u64(0);
let l_665 = l_662 || l_664;
if l_665 {
l_mut_317 = bool(false);
}
l_mut_86 = l_mut_86 | l_661;
l_mut_144 = l_mut_205;
let l_666 = a_512[u32(0)];
let l_667 = a_505[u32(4)];
let l_668 = l_666 * l_667;
l_mut_144 = l_mut_144 + l_668;
let l_669 = a_512[u32(1)];
let l_670 = a_505[u32(3)];
let l_671 = l_669 * l_670;
l_mut_144 = l_mut_144 + l_671;
let l_672 = a_512[u32(2)];
let l_673 = a_505[u32(2)];
let l_674 = l_672 * l_673;
l_mut_144 = l_mut_144 + l_674;
let l_675 = a_512[u32(3)];
let l_676 = a_505[u32(1)];
let l_677 = l_675 * l_676;
l_mut_144 = l_mut_144 + l_677;
let l_678 = a_512[u32(4)];
let l_679 = a_505[u32(0)];
let l_680 = l_678 * l_679;
l_mut_144 = l_mut_144 + l_680;
let l_681 = l_mut_144 % u32(60);
let l_682 = l_mut_144 / u32(60);
l_mut_205 = l_682;
let l_683 = a_512[u32(4)];
let l_684 = u64(l_683);
let l_685 = u64(1) << u32(bitcast<u64>(l_684));
let l_686 = u64(l_681);
let l_687 = u64(1) << u32(bitcast<u64>(l_686));
let l_688 = l_685 | l_687;
let l_689 = l_683 == l_681;
let l_690 = l_mut_86 & l_688;
let l_691 = l_690 != u64(0);
let l_692 = l_689 || l_691;
if l_692 {
l_mut_317 = bool(false);
}
l_mut_86 = l_mut_86 | l_688;
l_mut_144 = l_mut_205;
let l_693 = a_512[u32(0)];
let l_694 = a_505[u32(5)];
let l_695 = l_693 * l_694;
l_mut_144 = l_mut_144 + l_695;
let l_696 = a_512[u32(1)];
let l_697 = a_505[u32(4)];
let l_698 = l_696 * l_697;
l_mut_144 = l_mut_144 + l_698;
let l_699 = a_512[u32(2)];
let l_700 = a_505[u32(3)];
let l_701 = l_699 * l_700;
l_mut_144 = l_mut_144 + l_701;
let l_702 = a_512[u32(3)];
let l_703 = a_505[u32(2)];
let l_704 = l_702 * l_703;
l_mut_144 = l_mut_144 + l_704;
let l_705 = a_512[u32(4)];
let l_706 = a_505[u32(1)];
let l_707 = l_705 * l_706;
l_mut_144 = l_mut_144 + l_707;
let l_708 = a_512[u32(5)];
let l_709 = a_505[u32(0)];
let l_710 = l_708 * l_709;
l_mut_144 = l_mut_144 + l_710;
let l_711 = l_mut_144 % u32(60);
let l_712 = l_mut_144 / u32(60);
l_mut_205 = l_712;
let l_713 = a_512[u32(5)];
let l_714 = u64(l_713);
let l_715 = u64(1) << u32(bitcast<u64>(l_714));
let l_716 = u64(l_711);
let l_717 = u64(1) << u32(bitcast<u64>(l_716));
let l_718 = l_715 | l_717;
let l_719 = l_713 == l_711;
let l_720 = l_mut_86 & l_718;
let l_721 = l_720 != u64(0);
let l_722 = l_719 || l_721;
if l_722 {
l_mut_317 = bool(false);
}
l_mut_86 = l_mut_86 | l_718;
if l_mut_317 {
l_mut_234 = u32(1);
}
}
let l_723 = subgroupExclusiveAdd(l_mut_234);
let l_724 = subgroupAdd(l_mut_234);
let l_725 = subgroup_invocation_id == u32(0);
if l_725 {
shared_memory_0[l_482] = l_724;
}
workgroupBarrier();
l_mut_210 = u32(0);
l_mut_209 = u32(0);
l_mut_205 = u32(0);
loop {
let l_726 = l_mut_205 < l_483;
let l_727 = !l_726;
if l_727 {
break;
}
let l_728 = shared_memory_0[l_mut_205];
let l_729 = l_mut_205 < l_482;
if l_729 {
l_mut_210 = l_mut_210 + l_728;
}
l_mut_209 = l_mut_209 + l_728;
l_mut_205 = l_mut_205 + u32(1);
}
let l_730 = local_invocation_id.x == u32(0);
let l_731 = l_mut_209 > u32(0);
let l_732 = l_730 && l_731;
if l_732 {
let l_733 = &buffer_11_global[u32(0)];
let l_734 = atomicAdd(l_733, l_mut_209);shared_memory_9[u32(0)] = l_734;
}
workgroupBarrier();
let l_735 = l_mut_234 != u32(0);
if l_735 {
let l_736 = shared_memory_9[u32(0)];
let l_737 = l_736 + l_mut_210;
let l_738 = l_737 + l_723;
let l_739 = l_738 < info.scalars_u32[2];
if l_739 {
let l_740 = u32(2) * l_738;
buffer_10_global[l_740] = l_mut_231;
let l_741 = u32(2) * l_738;
let l_742 = l_741 + u32(1);
buffer_10_global[l_742] = l_mut_211;
}
}
l_mut_240 = l_mut_240 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_743 = local_invocation_id.x == u32(0);
if l_743 {
let l_744 = &shared_memory_8[u32(0)];
atomicStore(l_744,u32(0));
}
}
workgroupBarrier();
let l_745 = local_invocation_id.x == u32(0);
if l_745 {
let l_746 = &buffer_14_global[u32(4)];
let l_747 = atomicAdd(l_746, u32(1));}
}
```
