
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

var a_230: array<u32, 7>;

var a_240: array<u32, 7>;

var a_562: array<u32, 7>;

var a_570: array<u32, 7>;

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
var l_mut_235: u32;
var l_mut_241: u32;
var l_mut_242: u32;
var l_mut_86: u64;
var l_mut_341: bool;
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
let l_26 = l_19 / u32(56);
let l_27 = l_26 * u32(56);
let l_28 = l_19 - l_27;
let l_29 = buffer_3_global[l_28];
let l_30 = l_28 + u32(1);
let l_31 = buffer_3_global[l_30];
let l_32 = l_31 - l_29;
let l_33 = l_16 * u32(1);
let l_34 = l_33 + l_26;
let l_35 = l_34 * u32(56);
let l_36 = l_35 + l_28;
let l_37 = buffer_5_global[l_36];
let l_38 = l_16 * u32(57);
let l_39 = l_38 * info.scalars_u32[1];
let l_40 = u32(57) * l_29;
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
let l_232 = l_mut_231 % u32(57);
a_230[u32(0)] = l_232;
l_mut_231 = l_mut_231 / u32(57);
let l_233 = l_mut_231 % u32(57);
a_230[u32(1)] = l_233;
l_mut_231 = l_mut_231 / u32(57);
let l_234 = l_mut_231 % u32(57);
a_230[u32(2)] = l_234;
l_mut_231 = l_mut_231 / u32(57);
l_mut_235 = l_216;
let l_236 = l_mut_235 % u32(57);
a_230[u32(3)] = l_236;
l_mut_235 = l_mut_235 / u32(57);
let l_237 = l_mut_235 % u32(57);
a_230[u32(4)] = l_237;
l_mut_235 = l_mut_235 / u32(57);
let l_238 = l_mut_235 % u32(57);
a_230[u32(5)] = l_238;
l_mut_235 = l_mut_235 / u32(57);
let l_239 = l_mut_235 % u32(57);
a_230[u32(6)] = l_239;
l_mut_235 = l_mut_235 / u32(57);
l_mut_241 = u32(0);
l_mut_242 = l_mut_241;
let l_243 = a_230[u32(0)];
let l_244 = a_230[u32(0)];
let l_245 = l_243 * l_244;
l_mut_242 = l_mut_242 + l_245;
let l_246 = l_mut_242 % u32(57);
a_240[u32(0)] = l_246;
let l_247 = l_mut_242 / u32(57);
l_mut_241 = l_247;
l_mut_242 = l_mut_241;
let l_248 = a_230[u32(0)];
let l_249 = a_230[u32(1)];
let l_250 = l_248 * l_249;
l_mut_242 = l_mut_242 + l_250;
let l_251 = a_230[u32(1)];
let l_252 = a_230[u32(0)];
let l_253 = l_251 * l_252;
l_mut_242 = l_mut_242 + l_253;
let l_254 = l_mut_242 % u32(57);
a_240[u32(1)] = l_254;
let l_255 = l_mut_242 / u32(57);
l_mut_241 = l_255;
l_mut_242 = l_mut_241;
let l_256 = a_230[u32(0)];
let l_257 = a_230[u32(2)];
let l_258 = l_256 * l_257;
l_mut_242 = l_mut_242 + l_258;
let l_259 = a_230[u32(1)];
let l_260 = a_230[u32(1)];
let l_261 = l_259 * l_260;
l_mut_242 = l_mut_242 + l_261;
let l_262 = a_230[u32(2)];
let l_263 = a_230[u32(0)];
let l_264 = l_262 * l_263;
l_mut_242 = l_mut_242 + l_264;
let l_265 = l_mut_242 % u32(57);
a_240[u32(2)] = l_265;
let l_266 = l_mut_242 / u32(57);
l_mut_241 = l_266;
l_mut_242 = l_mut_241;
let l_267 = a_230[u32(0)];
let l_268 = a_230[u32(3)];
let l_269 = l_267 * l_268;
l_mut_242 = l_mut_242 + l_269;
let l_270 = a_230[u32(1)];
let l_271 = a_230[u32(2)];
let l_272 = l_270 * l_271;
l_mut_242 = l_mut_242 + l_272;
let l_273 = a_230[u32(2)];
let l_274 = a_230[u32(1)];
let l_275 = l_273 * l_274;
l_mut_242 = l_mut_242 + l_275;
let l_276 = a_230[u32(3)];
let l_277 = a_230[u32(0)];
let l_278 = l_276 * l_277;
l_mut_242 = l_mut_242 + l_278;
let l_279 = l_mut_242 % u32(57);
a_240[u32(3)] = l_279;
let l_280 = l_mut_242 / u32(57);
l_mut_241 = l_280;
l_mut_242 = l_mut_241;
let l_281 = a_230[u32(0)];
let l_282 = a_230[u32(4)];
let l_283 = l_281 * l_282;
l_mut_242 = l_mut_242 + l_283;
let l_284 = a_230[u32(1)];
let l_285 = a_230[u32(3)];
let l_286 = l_284 * l_285;
l_mut_242 = l_mut_242 + l_286;
let l_287 = a_230[u32(2)];
let l_288 = a_230[u32(2)];
let l_289 = l_287 * l_288;
l_mut_242 = l_mut_242 + l_289;
let l_290 = a_230[u32(3)];
let l_291 = a_230[u32(1)];
let l_292 = l_290 * l_291;
l_mut_242 = l_mut_242 + l_292;
let l_293 = a_230[u32(4)];
let l_294 = a_230[u32(0)];
let l_295 = l_293 * l_294;
l_mut_242 = l_mut_242 + l_295;
let l_296 = l_mut_242 % u32(57);
a_240[u32(4)] = l_296;
let l_297 = l_mut_242 / u32(57);
l_mut_241 = l_297;
l_mut_242 = l_mut_241;
let l_298 = a_230[u32(0)];
let l_299 = a_230[u32(5)];
let l_300 = l_298 * l_299;
l_mut_242 = l_mut_242 + l_300;
let l_301 = a_230[u32(1)];
let l_302 = a_230[u32(4)];
let l_303 = l_301 * l_302;
l_mut_242 = l_mut_242 + l_303;
let l_304 = a_230[u32(2)];
let l_305 = a_230[u32(3)];
let l_306 = l_304 * l_305;
l_mut_242 = l_mut_242 + l_306;
let l_307 = a_230[u32(3)];
let l_308 = a_230[u32(2)];
let l_309 = l_307 * l_308;
l_mut_242 = l_mut_242 + l_309;
let l_310 = a_230[u32(4)];
let l_311 = a_230[u32(1)];
let l_312 = l_310 * l_311;
l_mut_242 = l_mut_242 + l_312;
let l_313 = a_230[u32(5)];
let l_314 = a_230[u32(0)];
let l_315 = l_313 * l_314;
l_mut_242 = l_mut_242 + l_315;
let l_316 = l_mut_242 % u32(57);
a_240[u32(5)] = l_316;
let l_317 = l_mut_242 / u32(57);
l_mut_241 = l_317;
l_mut_242 = l_mut_241;
let l_318 = a_230[u32(0)];
let l_319 = a_230[u32(6)];
let l_320 = l_318 * l_319;
l_mut_242 = l_mut_242 + l_320;
let l_321 = a_230[u32(1)];
let l_322 = a_230[u32(5)];
let l_323 = l_321 * l_322;
l_mut_242 = l_mut_242 + l_323;
let l_324 = a_230[u32(2)];
let l_325 = a_230[u32(4)];
let l_326 = l_324 * l_325;
l_mut_242 = l_mut_242 + l_326;
let l_327 = a_230[u32(3)];
let l_328 = a_230[u32(3)];
let l_329 = l_327 * l_328;
l_mut_242 = l_mut_242 + l_329;
let l_330 = a_230[u32(4)];
let l_331 = a_230[u32(2)];
let l_332 = l_330 * l_331;
l_mut_242 = l_mut_242 + l_332;
let l_333 = a_230[u32(5)];
let l_334 = a_230[u32(1)];
let l_335 = l_333 * l_334;
l_mut_242 = l_mut_242 + l_335;
let l_336 = a_230[u32(6)];
let l_337 = a_230[u32(0)];
let l_338 = l_336 * l_337;
l_mut_242 = l_mut_242 + l_338;
let l_339 = l_mut_242 % u32(57);
a_240[u32(6)] = l_339;
let l_340 = l_mut_242 / u32(57);
l_mut_241 = l_340;
l_mut_341 = bool(true);
l_mut_241 = u32(0);
l_mut_242 = l_mut_241;
let l_342 = a_240[u32(0)];
let l_343 = a_230[u32(0)];
let l_344 = l_342 * l_343;
l_mut_242 = l_mut_242 + l_344;
let l_345 = l_mut_242 % u32(57);
let l_346 = l_mut_242 / u32(57);
l_mut_241 = l_346;
let l_347 = a_240[u32(0)];
let l_348 = u64(l_347);
let l_349 = u64(1) << u32(bitcast<u64>(l_348));
let l_350 = u64(l_345);
let l_351 = u64(1) << u32(bitcast<u64>(l_350));
let l_352 = l_349 | l_351;
let l_353 = l_347 == l_345;
let l_354 = l_mut_86 & l_352;
let l_355 = l_354 != u64(0);
let l_356 = l_353 || l_355;
if l_356 {
l_mut_341 = bool(false);
}
l_mut_86 = l_mut_86 | l_352;
l_mut_242 = l_mut_241;
let l_357 = a_240[u32(0)];
let l_358 = a_230[u32(1)];
let l_359 = l_357 * l_358;
l_mut_242 = l_mut_242 + l_359;
let l_360 = a_240[u32(1)];
let l_361 = a_230[u32(0)];
let l_362 = l_360 * l_361;
l_mut_242 = l_mut_242 + l_362;
let l_363 = l_mut_242 % u32(57);
let l_364 = l_mut_242 / u32(57);
l_mut_241 = l_364;
let l_365 = a_240[u32(1)];
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
l_mut_341 = bool(false);
}
l_mut_86 = l_mut_86 | l_370;
l_mut_242 = l_mut_241;
let l_375 = a_240[u32(0)];
let l_376 = a_230[u32(2)];
let l_377 = l_375 * l_376;
l_mut_242 = l_mut_242 + l_377;
let l_378 = a_240[u32(1)];
let l_379 = a_230[u32(1)];
let l_380 = l_378 * l_379;
l_mut_242 = l_mut_242 + l_380;
let l_381 = a_240[u32(2)];
let l_382 = a_230[u32(0)];
let l_383 = l_381 * l_382;
l_mut_242 = l_mut_242 + l_383;
let l_384 = l_mut_242 % u32(57);
let l_385 = l_mut_242 / u32(57);
l_mut_241 = l_385;
let l_386 = a_240[u32(2)];
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
l_mut_341 = bool(false);
}
l_mut_86 = l_mut_86 | l_391;
l_mut_242 = l_mut_241;
let l_396 = a_240[u32(0)];
let l_397 = a_230[u32(3)];
let l_398 = l_396 * l_397;
l_mut_242 = l_mut_242 + l_398;
let l_399 = a_240[u32(1)];
let l_400 = a_230[u32(2)];
let l_401 = l_399 * l_400;
l_mut_242 = l_mut_242 + l_401;
let l_402 = a_240[u32(2)];
let l_403 = a_230[u32(1)];
let l_404 = l_402 * l_403;
l_mut_242 = l_mut_242 + l_404;
let l_405 = a_240[u32(3)];
let l_406 = a_230[u32(0)];
let l_407 = l_405 * l_406;
l_mut_242 = l_mut_242 + l_407;
let l_408 = l_mut_242 % u32(57);
let l_409 = l_mut_242 / u32(57);
l_mut_241 = l_409;
let l_410 = a_240[u32(3)];
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
l_mut_341 = bool(false);
}
l_mut_86 = l_mut_86 | l_415;
l_mut_242 = l_mut_241;
let l_420 = a_240[u32(0)];
let l_421 = a_230[u32(4)];
let l_422 = l_420 * l_421;
l_mut_242 = l_mut_242 + l_422;
let l_423 = a_240[u32(1)];
let l_424 = a_230[u32(3)];
let l_425 = l_423 * l_424;
l_mut_242 = l_mut_242 + l_425;
let l_426 = a_240[u32(2)];
let l_427 = a_230[u32(2)];
let l_428 = l_426 * l_427;
l_mut_242 = l_mut_242 + l_428;
let l_429 = a_240[u32(3)];
let l_430 = a_230[u32(1)];
let l_431 = l_429 * l_430;
l_mut_242 = l_mut_242 + l_431;
let l_432 = a_240[u32(4)];
let l_433 = a_230[u32(0)];
let l_434 = l_432 * l_433;
l_mut_242 = l_mut_242 + l_434;
let l_435 = l_mut_242 % u32(57);
let l_436 = l_mut_242 / u32(57);
l_mut_241 = l_436;
let l_437 = a_240[u32(4)];
let l_438 = u64(l_437);
let l_439 = u64(1) << u32(bitcast<u64>(l_438));
let l_440 = u64(l_435);
let l_441 = u64(1) << u32(bitcast<u64>(l_440));
let l_442 = l_439 | l_441;
let l_443 = l_437 == l_435;
let l_444 = l_mut_86 & l_442;
let l_445 = l_444 != u64(0);
let l_446 = l_443 || l_445;
if l_446 {
l_mut_341 = bool(false);
}
l_mut_86 = l_mut_86 | l_442;
l_mut_242 = l_mut_241;
let l_447 = a_240[u32(0)];
let l_448 = a_230[u32(5)];
let l_449 = l_447 * l_448;
l_mut_242 = l_mut_242 + l_449;
let l_450 = a_240[u32(1)];
let l_451 = a_230[u32(4)];
let l_452 = l_450 * l_451;
l_mut_242 = l_mut_242 + l_452;
let l_453 = a_240[u32(2)];
let l_454 = a_230[u32(3)];
let l_455 = l_453 * l_454;
l_mut_242 = l_mut_242 + l_455;
let l_456 = a_240[u32(3)];
let l_457 = a_230[u32(2)];
let l_458 = l_456 * l_457;
l_mut_242 = l_mut_242 + l_458;
let l_459 = a_240[u32(4)];
let l_460 = a_230[u32(1)];
let l_461 = l_459 * l_460;
l_mut_242 = l_mut_242 + l_461;
let l_462 = a_240[u32(5)];
let l_463 = a_230[u32(0)];
let l_464 = l_462 * l_463;
l_mut_242 = l_mut_242 + l_464;
let l_465 = l_mut_242 % u32(57);
let l_466 = l_mut_242 / u32(57);
l_mut_241 = l_466;
let l_467 = a_240[u32(5)];
let l_468 = u64(l_467);
let l_469 = u64(1) << u32(bitcast<u64>(l_468));
let l_470 = u64(l_465);
let l_471 = u64(1) << u32(bitcast<u64>(l_470));
let l_472 = l_469 | l_471;
let l_473 = l_467 == l_465;
let l_474 = l_mut_86 & l_472;
let l_475 = l_474 != u64(0);
let l_476 = l_473 || l_475;
if l_476 {
l_mut_341 = bool(false);
}
l_mut_86 = l_mut_86 | l_472;
l_mut_242 = l_mut_241;
let l_477 = a_240[u32(0)];
let l_478 = a_230[u32(6)];
let l_479 = l_477 * l_478;
l_mut_242 = l_mut_242 + l_479;
let l_480 = a_240[u32(1)];
let l_481 = a_230[u32(5)];
let l_482 = l_480 * l_481;
l_mut_242 = l_mut_242 + l_482;
let l_483 = a_240[u32(2)];
let l_484 = a_230[u32(4)];
let l_485 = l_483 * l_484;
l_mut_242 = l_mut_242 + l_485;
let l_486 = a_240[u32(3)];
let l_487 = a_230[u32(3)];
let l_488 = l_486 * l_487;
l_mut_242 = l_mut_242 + l_488;
let l_489 = a_240[u32(4)];
let l_490 = a_230[u32(2)];
let l_491 = l_489 * l_490;
l_mut_242 = l_mut_242 + l_491;
let l_492 = a_240[u32(5)];
let l_493 = a_230[u32(1)];
let l_494 = l_492 * l_493;
l_mut_242 = l_mut_242 + l_494;
let l_495 = a_240[u32(6)];
let l_496 = a_230[u32(0)];
let l_497 = l_495 * l_496;
l_mut_242 = l_mut_242 + l_497;
let l_498 = l_mut_242 % u32(57);
let l_499 = l_mut_242 / u32(57);
l_mut_241 = l_499;
let l_500 = a_240[u32(6)];
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
l_mut_341 = bool(false);
}
l_mut_86 = l_mut_86 | l_505;
if l_mut_341 {
l_mut_209 = u32(1);
}
}
let l_510 = subgroupExclusiveAdd(l_mut_209);
let l_511 = subgroupAdd(l_mut_209);
let l_512 = subgroup_invocation_id == u32(0);
if l_512 {
shared_memory_0[l_203] = l_511;
}
workgroupBarrier();
l_mut_242 = u32(0);
l_mut_241 = u32(0);
l_mut_235 = u32(0);
loop {
let l_513 = l_mut_235 < l_204;
let l_514 = !l_513;
if l_514 {
break;
}
let l_515 = shared_memory_0[l_mut_235];
let l_516 = l_mut_235 < l_203;
if l_516 {
l_mut_242 = l_mut_242 + l_515;
}
l_mut_241 = l_mut_241 + l_515;
l_mut_235 = l_mut_235 + u32(1);
}
let l_517 = local_invocation_id.x == u32(0);
let l_518 = l_mut_241 > u32(0);
let l_519 = l_517 && l_518;
if l_519 {
let l_520 = &buffer_11_global[u32(0)];
let l_521 = atomicAdd(l_520, l_mut_241);shared_memory_9[u32(0)] = l_521;
}
workgroupBarrier();
let l_522 = l_mut_209 != u32(0);
if l_522 {
let l_523 = shared_memory_9[u32(0)];
let l_524 = l_523 + l_mut_242;
let l_525 = l_524 + l_510;
let l_526 = l_525 < info.scalars_u32[2];
if l_526 {
let l_527 = u32(2) * l_525;
buffer_10_global[l_527] = l_mut_210;
let l_528 = u32(2) * l_525;
let l_529 = l_528 + u32(1);
buffer_10_global[l_529] = l_mut_211;
}
}
l_mut_205 = l_mut_205 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_530 = local_invocation_id.x == u32(0);
if l_530 {
let l_531 = &shared_memory_8[u32(0)];
atomicStore(l_531,u32(0));
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
let l_532 = &shared_memory_8[u32(0)];
let l_533 = atomicLoad(l_532);
let l_534 = l_533 > u32(0);
if l_534 {
l_mut_242 = l_533;
let l_535 = l_mut_242 > u32(1024);
if l_535 {
l_mut_242 = u32(1024);
}
let l_536 = local_invocation_id.x == u32(0);
if l_536 {
let l_537 = &buffer_13_global[u32(0)];
let l_538 = atomicAdd(l_537, l_mut_242);}
let l_539 = local_invocation_id.x / subgroup_size;
let l_540 = WORKGROUP_SIZE_X / subgroup_size;
l_mut_241 = u32(0);
loop {
let l_541 = l_mut_241 < l_mut_242;
let l_542 = !l_541;
if l_542 {
break;
}
let l_543 = l_mut_241 + local_invocation_id.x;
l_mut_235 = u32(0);
l_mut_231 = u32(0);
l_mut_211 = u32(0);
let l_544 = l_543 < l_mut_242;
if l_544 {
let l_545 = shared_memory_6[l_543];
l_mut_231 = l_545;
let l_546 = shared_memory_7[l_543];
l_mut_211 = l_546;
let l_547 = u32(2) * l_mut_231;
let l_548 = buffer_12_global[l_547];
l_mut_86 = u64(0);
let l_549 = u32(2) * l_mut_231;
let l_550 = l_549 + u32(1);
let l_551 = buffer_12_global[l_550];
let l_552 = l_551 != u32(0);
if l_552 {
let l_553 = u32(2) * l_mut_231;
let l_554 = l_553 + u32(1);
let l_555 = buffer_8_global[l_554];
let l_556 = u64(l_555);
let l_557 = l_556 << u32(bitcast<u64>(u64(32)));
let l_558 = u32(2) * l_mut_231;
let l_559 = buffer_8_global[l_558];
let l_560 = u64(l_559);
let l_561 = l_557 | l_560;
l_mut_86 = l_561;
}
l_mut_210 = l_mut_211;
let l_563 = l_mut_210 % u32(57);
a_562[u32(0)] = l_563;
l_mut_210 = l_mut_210 / u32(57);
let l_564 = l_mut_210 % u32(57);
a_562[u32(1)] = l_564;
l_mut_210 = l_mut_210 / u32(57);
let l_565 = l_mut_210 % u32(57);
a_562[u32(2)] = l_565;
l_mut_210 = l_mut_210 / u32(57);
l_mut_209 = l_548;
let l_566 = l_mut_209 % u32(57);
a_562[u32(3)] = l_566;
l_mut_209 = l_mut_209 / u32(57);
let l_567 = l_mut_209 % u32(57);
a_562[u32(4)] = l_567;
l_mut_209 = l_mut_209 / u32(57);
let l_568 = l_mut_209 % u32(57);
a_562[u32(5)] = l_568;
l_mut_209 = l_mut_209 / u32(57);
let l_569 = l_mut_209 % u32(57);
a_562[u32(6)] = l_569;
l_mut_209 = l_mut_209 / u32(57);
l_mut_205 = u32(0);
l_mut_144 = l_mut_205;
let l_571 = a_562[u32(0)];
let l_572 = a_562[u32(0)];
let l_573 = l_571 * l_572;
l_mut_144 = l_mut_144 + l_573;
let l_574 = l_mut_144 % u32(57);
a_570[u32(0)] = l_574;
let l_575 = l_mut_144 / u32(57);
l_mut_205 = l_575;
l_mut_144 = l_mut_205;
let l_576 = a_562[u32(0)];
let l_577 = a_562[u32(1)];
let l_578 = l_576 * l_577;
l_mut_144 = l_mut_144 + l_578;
let l_579 = a_562[u32(1)];
let l_580 = a_562[u32(0)];
let l_581 = l_579 * l_580;
l_mut_144 = l_mut_144 + l_581;
let l_582 = l_mut_144 % u32(57);
a_570[u32(1)] = l_582;
let l_583 = l_mut_144 / u32(57);
l_mut_205 = l_583;
l_mut_144 = l_mut_205;
let l_584 = a_562[u32(0)];
let l_585 = a_562[u32(2)];
let l_586 = l_584 * l_585;
l_mut_144 = l_mut_144 + l_586;
let l_587 = a_562[u32(1)];
let l_588 = a_562[u32(1)];
let l_589 = l_587 * l_588;
l_mut_144 = l_mut_144 + l_589;
let l_590 = a_562[u32(2)];
let l_591 = a_562[u32(0)];
let l_592 = l_590 * l_591;
l_mut_144 = l_mut_144 + l_592;
let l_593 = l_mut_144 % u32(57);
a_570[u32(2)] = l_593;
let l_594 = l_mut_144 / u32(57);
l_mut_205 = l_594;
l_mut_144 = l_mut_205;
let l_595 = a_562[u32(0)];
let l_596 = a_562[u32(3)];
let l_597 = l_595 * l_596;
l_mut_144 = l_mut_144 + l_597;
let l_598 = a_562[u32(1)];
let l_599 = a_562[u32(2)];
let l_600 = l_598 * l_599;
l_mut_144 = l_mut_144 + l_600;
let l_601 = a_562[u32(2)];
let l_602 = a_562[u32(1)];
let l_603 = l_601 * l_602;
l_mut_144 = l_mut_144 + l_603;
let l_604 = a_562[u32(3)];
let l_605 = a_562[u32(0)];
let l_606 = l_604 * l_605;
l_mut_144 = l_mut_144 + l_606;
let l_607 = l_mut_144 % u32(57);
a_570[u32(3)] = l_607;
let l_608 = l_mut_144 / u32(57);
l_mut_205 = l_608;
l_mut_144 = l_mut_205;
let l_609 = a_562[u32(0)];
let l_610 = a_562[u32(4)];
let l_611 = l_609 * l_610;
l_mut_144 = l_mut_144 + l_611;
let l_612 = a_562[u32(1)];
let l_613 = a_562[u32(3)];
let l_614 = l_612 * l_613;
l_mut_144 = l_mut_144 + l_614;
let l_615 = a_562[u32(2)];
let l_616 = a_562[u32(2)];
let l_617 = l_615 * l_616;
l_mut_144 = l_mut_144 + l_617;
let l_618 = a_562[u32(3)];
let l_619 = a_562[u32(1)];
let l_620 = l_618 * l_619;
l_mut_144 = l_mut_144 + l_620;
let l_621 = a_562[u32(4)];
let l_622 = a_562[u32(0)];
let l_623 = l_621 * l_622;
l_mut_144 = l_mut_144 + l_623;
let l_624 = l_mut_144 % u32(57);
a_570[u32(4)] = l_624;
let l_625 = l_mut_144 / u32(57);
l_mut_205 = l_625;
l_mut_144 = l_mut_205;
let l_626 = a_562[u32(0)];
let l_627 = a_562[u32(5)];
let l_628 = l_626 * l_627;
l_mut_144 = l_mut_144 + l_628;
let l_629 = a_562[u32(1)];
let l_630 = a_562[u32(4)];
let l_631 = l_629 * l_630;
l_mut_144 = l_mut_144 + l_631;
let l_632 = a_562[u32(2)];
let l_633 = a_562[u32(3)];
let l_634 = l_632 * l_633;
l_mut_144 = l_mut_144 + l_634;
let l_635 = a_562[u32(3)];
let l_636 = a_562[u32(2)];
let l_637 = l_635 * l_636;
l_mut_144 = l_mut_144 + l_637;
let l_638 = a_562[u32(4)];
let l_639 = a_562[u32(1)];
let l_640 = l_638 * l_639;
l_mut_144 = l_mut_144 + l_640;
let l_641 = a_562[u32(5)];
let l_642 = a_562[u32(0)];
let l_643 = l_641 * l_642;
l_mut_144 = l_mut_144 + l_643;
let l_644 = l_mut_144 % u32(57);
a_570[u32(5)] = l_644;
let l_645 = l_mut_144 / u32(57);
l_mut_205 = l_645;
l_mut_144 = l_mut_205;
let l_646 = a_562[u32(0)];
let l_647 = a_562[u32(6)];
let l_648 = l_646 * l_647;
l_mut_144 = l_mut_144 + l_648;
let l_649 = a_562[u32(1)];
let l_650 = a_562[u32(5)];
let l_651 = l_649 * l_650;
l_mut_144 = l_mut_144 + l_651;
let l_652 = a_562[u32(2)];
let l_653 = a_562[u32(4)];
let l_654 = l_652 * l_653;
l_mut_144 = l_mut_144 + l_654;
let l_655 = a_562[u32(3)];
let l_656 = a_562[u32(3)];
let l_657 = l_655 * l_656;
l_mut_144 = l_mut_144 + l_657;
let l_658 = a_562[u32(4)];
let l_659 = a_562[u32(2)];
let l_660 = l_658 * l_659;
l_mut_144 = l_mut_144 + l_660;
let l_661 = a_562[u32(5)];
let l_662 = a_562[u32(1)];
let l_663 = l_661 * l_662;
l_mut_144 = l_mut_144 + l_663;
let l_664 = a_562[u32(6)];
let l_665 = a_562[u32(0)];
let l_666 = l_664 * l_665;
l_mut_144 = l_mut_144 + l_666;
let l_667 = l_mut_144 % u32(57);
a_570[u32(6)] = l_667;
let l_668 = l_mut_144 / u32(57);
l_mut_205 = l_668;
l_mut_341 = bool(true);
l_mut_205 = u32(0);
l_mut_144 = l_mut_205;
let l_669 = a_570[u32(0)];
let l_670 = a_562[u32(0)];
let l_671 = l_669 * l_670;
l_mut_144 = l_mut_144 + l_671;
let l_672 = l_mut_144 % u32(57);
let l_673 = l_mut_144 / u32(57);
l_mut_205 = l_673;
let l_674 = a_570[u32(0)];
let l_675 = u64(l_674);
let l_676 = u64(1) << u32(bitcast<u64>(l_675));
let l_677 = u64(l_672);
let l_678 = u64(1) << u32(bitcast<u64>(l_677));
let l_679 = l_676 | l_678;
let l_680 = l_674 == l_672;
let l_681 = l_mut_86 & l_679;
let l_682 = l_681 != u64(0);
let l_683 = l_680 || l_682;
if l_683 {
l_mut_341 = bool(false);
}
l_mut_86 = l_mut_86 | l_679;
l_mut_144 = l_mut_205;
let l_684 = a_570[u32(0)];
let l_685 = a_562[u32(1)];
let l_686 = l_684 * l_685;
l_mut_144 = l_mut_144 + l_686;
let l_687 = a_570[u32(1)];
let l_688 = a_562[u32(0)];
let l_689 = l_687 * l_688;
l_mut_144 = l_mut_144 + l_689;
let l_690 = l_mut_144 % u32(57);
let l_691 = l_mut_144 / u32(57);
l_mut_205 = l_691;
let l_692 = a_570[u32(1)];
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
l_mut_341 = bool(false);
}
l_mut_86 = l_mut_86 | l_697;
l_mut_144 = l_mut_205;
let l_702 = a_570[u32(0)];
let l_703 = a_562[u32(2)];
let l_704 = l_702 * l_703;
l_mut_144 = l_mut_144 + l_704;
let l_705 = a_570[u32(1)];
let l_706 = a_562[u32(1)];
let l_707 = l_705 * l_706;
l_mut_144 = l_mut_144 + l_707;
let l_708 = a_570[u32(2)];
let l_709 = a_562[u32(0)];
let l_710 = l_708 * l_709;
l_mut_144 = l_mut_144 + l_710;
let l_711 = l_mut_144 % u32(57);
let l_712 = l_mut_144 / u32(57);
l_mut_205 = l_712;
let l_713 = a_570[u32(2)];
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
l_mut_341 = bool(false);
}
l_mut_86 = l_mut_86 | l_718;
l_mut_144 = l_mut_205;
let l_723 = a_570[u32(0)];
let l_724 = a_562[u32(3)];
let l_725 = l_723 * l_724;
l_mut_144 = l_mut_144 + l_725;
let l_726 = a_570[u32(1)];
let l_727 = a_562[u32(2)];
let l_728 = l_726 * l_727;
l_mut_144 = l_mut_144 + l_728;
let l_729 = a_570[u32(2)];
let l_730 = a_562[u32(1)];
let l_731 = l_729 * l_730;
l_mut_144 = l_mut_144 + l_731;
let l_732 = a_570[u32(3)];
let l_733 = a_562[u32(0)];
let l_734 = l_732 * l_733;
l_mut_144 = l_mut_144 + l_734;
let l_735 = l_mut_144 % u32(57);
let l_736 = l_mut_144 / u32(57);
l_mut_205 = l_736;
let l_737 = a_570[u32(3)];
let l_738 = u64(l_737);
let l_739 = u64(1) << u32(bitcast<u64>(l_738));
let l_740 = u64(l_735);
let l_741 = u64(1) << u32(bitcast<u64>(l_740));
let l_742 = l_739 | l_741;
let l_743 = l_737 == l_735;
let l_744 = l_mut_86 & l_742;
let l_745 = l_744 != u64(0);
let l_746 = l_743 || l_745;
if l_746 {
l_mut_341 = bool(false);
}
l_mut_86 = l_mut_86 | l_742;
l_mut_144 = l_mut_205;
let l_747 = a_570[u32(0)];
let l_748 = a_562[u32(4)];
let l_749 = l_747 * l_748;
l_mut_144 = l_mut_144 + l_749;
let l_750 = a_570[u32(1)];
let l_751 = a_562[u32(3)];
let l_752 = l_750 * l_751;
l_mut_144 = l_mut_144 + l_752;
let l_753 = a_570[u32(2)];
let l_754 = a_562[u32(2)];
let l_755 = l_753 * l_754;
l_mut_144 = l_mut_144 + l_755;
let l_756 = a_570[u32(3)];
let l_757 = a_562[u32(1)];
let l_758 = l_756 * l_757;
l_mut_144 = l_mut_144 + l_758;
let l_759 = a_570[u32(4)];
let l_760 = a_562[u32(0)];
let l_761 = l_759 * l_760;
l_mut_144 = l_mut_144 + l_761;
let l_762 = l_mut_144 % u32(57);
let l_763 = l_mut_144 / u32(57);
l_mut_205 = l_763;
let l_764 = a_570[u32(4)];
let l_765 = u64(l_764);
let l_766 = u64(1) << u32(bitcast<u64>(l_765));
let l_767 = u64(l_762);
let l_768 = u64(1) << u32(bitcast<u64>(l_767));
let l_769 = l_766 | l_768;
let l_770 = l_764 == l_762;
let l_771 = l_mut_86 & l_769;
let l_772 = l_771 != u64(0);
let l_773 = l_770 || l_772;
if l_773 {
l_mut_341 = bool(false);
}
l_mut_86 = l_mut_86 | l_769;
l_mut_144 = l_mut_205;
let l_774 = a_570[u32(0)];
let l_775 = a_562[u32(5)];
let l_776 = l_774 * l_775;
l_mut_144 = l_mut_144 + l_776;
let l_777 = a_570[u32(1)];
let l_778 = a_562[u32(4)];
let l_779 = l_777 * l_778;
l_mut_144 = l_mut_144 + l_779;
let l_780 = a_570[u32(2)];
let l_781 = a_562[u32(3)];
let l_782 = l_780 * l_781;
l_mut_144 = l_mut_144 + l_782;
let l_783 = a_570[u32(3)];
let l_784 = a_562[u32(2)];
let l_785 = l_783 * l_784;
l_mut_144 = l_mut_144 + l_785;
let l_786 = a_570[u32(4)];
let l_787 = a_562[u32(1)];
let l_788 = l_786 * l_787;
l_mut_144 = l_mut_144 + l_788;
let l_789 = a_570[u32(5)];
let l_790 = a_562[u32(0)];
let l_791 = l_789 * l_790;
l_mut_144 = l_mut_144 + l_791;
let l_792 = l_mut_144 % u32(57);
let l_793 = l_mut_144 / u32(57);
l_mut_205 = l_793;
let l_794 = a_570[u32(5)];
let l_795 = u64(l_794);
let l_796 = u64(1) << u32(bitcast<u64>(l_795));
let l_797 = u64(l_792);
let l_798 = u64(1) << u32(bitcast<u64>(l_797));
let l_799 = l_796 | l_798;
let l_800 = l_794 == l_792;
let l_801 = l_mut_86 & l_799;
let l_802 = l_801 != u64(0);
let l_803 = l_800 || l_802;
if l_803 {
l_mut_341 = bool(false);
}
l_mut_86 = l_mut_86 | l_799;
l_mut_144 = l_mut_205;
let l_804 = a_570[u32(0)];
let l_805 = a_562[u32(6)];
let l_806 = l_804 * l_805;
l_mut_144 = l_mut_144 + l_806;
let l_807 = a_570[u32(1)];
let l_808 = a_562[u32(5)];
let l_809 = l_807 * l_808;
l_mut_144 = l_mut_144 + l_809;
let l_810 = a_570[u32(2)];
let l_811 = a_562[u32(4)];
let l_812 = l_810 * l_811;
l_mut_144 = l_mut_144 + l_812;
let l_813 = a_570[u32(3)];
let l_814 = a_562[u32(3)];
let l_815 = l_813 * l_814;
l_mut_144 = l_mut_144 + l_815;
let l_816 = a_570[u32(4)];
let l_817 = a_562[u32(2)];
let l_818 = l_816 * l_817;
l_mut_144 = l_mut_144 + l_818;
let l_819 = a_570[u32(5)];
let l_820 = a_562[u32(1)];
let l_821 = l_819 * l_820;
l_mut_144 = l_mut_144 + l_821;
let l_822 = a_570[u32(6)];
let l_823 = a_562[u32(0)];
let l_824 = l_822 * l_823;
l_mut_144 = l_mut_144 + l_824;
let l_825 = l_mut_144 % u32(57);
let l_826 = l_mut_144 / u32(57);
l_mut_205 = l_826;
let l_827 = a_570[u32(6)];
let l_828 = u64(l_827);
let l_829 = u64(1) << u32(bitcast<u64>(l_828));
let l_830 = u64(l_825);
let l_831 = u64(1) << u32(bitcast<u64>(l_830));
let l_832 = l_829 | l_831;
let l_833 = l_827 == l_825;
let l_834 = l_mut_86 & l_832;
let l_835 = l_834 != u64(0);
let l_836 = l_833 || l_835;
if l_836 {
l_mut_341 = bool(false);
}
l_mut_86 = l_mut_86 | l_832;
if l_mut_341 {
l_mut_235 = u32(1);
}
}
let l_837 = subgroupExclusiveAdd(l_mut_235);
let l_838 = subgroupAdd(l_mut_235);
let l_839 = subgroup_invocation_id == u32(0);
if l_839 {
shared_memory_0[l_539] = l_838;
}
workgroupBarrier();
l_mut_210 = u32(0);
l_mut_209 = u32(0);
l_mut_205 = u32(0);
loop {
let l_840 = l_mut_205 < l_540;
let l_841 = !l_840;
if l_841 {
break;
}
let l_842 = shared_memory_0[l_mut_205];
let l_843 = l_mut_205 < l_539;
if l_843 {
l_mut_210 = l_mut_210 + l_842;
}
l_mut_209 = l_mut_209 + l_842;
l_mut_205 = l_mut_205 + u32(1);
}
let l_844 = local_invocation_id.x == u32(0);
let l_845 = l_mut_209 > u32(0);
let l_846 = l_844 && l_845;
if l_846 {
let l_847 = &buffer_11_global[u32(0)];
let l_848 = atomicAdd(l_847, l_mut_209);shared_memory_9[u32(0)] = l_848;
}
workgroupBarrier();
let l_849 = l_mut_235 != u32(0);
if l_849 {
let l_850 = shared_memory_9[u32(0)];
let l_851 = l_850 + l_mut_210;
let l_852 = l_851 + l_837;
let l_853 = l_852 < info.scalars_u32[2];
if l_853 {
let l_854 = u32(2) * l_852;
buffer_10_global[l_854] = l_mut_231;
let l_855 = u32(2) * l_852;
let l_856 = l_855 + u32(1);
buffer_10_global[l_856] = l_mut_211;
}
}
l_mut_241 = l_mut_241 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_857 = local_invocation_id.x == u32(0);
if l_857 {
let l_858 = &shared_memory_8[u32(0)];
atomicStore(l_858,u32(0));
}
}
workgroupBarrier();
let l_859 = local_invocation_id.x == u32(0);
if l_859 {
let l_860 = &buffer_14_global[u32(4)];
let l_861 = atomicAdd(l_860, u32(1));}
}
```
