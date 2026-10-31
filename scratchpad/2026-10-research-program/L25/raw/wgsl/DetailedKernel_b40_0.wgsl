
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

struct info_st {
   scalars_u32: array<u32, 8>,
   static_meta: array<u32, 6>,
}

@group(0)
@binding(3)
var<storage, read> info: info_st;

var<workgroup> shared_memory_0: array<atomic<u32>, 164>;

var<workgroup> shared_memory_22: array<u32, 1792>;

const WORKGROUP_SIZE_X = 256u;
const WORKGROUP_SIZE_Y = 1u;
const WORKGROUP_SIZE_Z = 1u;

@compute
@workgroup_size(256, 1, 1)
fn detailed_kernel(
    @builtin(global_invocation_id) global_id: vec3<u32>,
    @builtin(local_invocation_id) local_invocation_id: vec3<u32>,
    @builtin(num_workgroups) num_workgroups: vec3<u32>,
) {
var a_31: array<u32, 2>;

var a_36: array<u32, 4>;

var a_84: array<u32, 6>;

var l_mut_1: u32;
var l_mut_178: u32;
var l_mut_213: u32;
var l_mut_242: u32;
var l_mut_25: u64;
var l_mut_29: u64;
var l_mut_37: u64;
var l_mut_177: u64;
var l_mut_204: i32;
var l_mut_214: i32;
l_mut_1 = local_invocation_id.x;
loop {
let l_2 = l_mut_1 < u32(164);
let l_3 = !l_2;
if l_3 {
break;
}
let l_4 = &shared_memory_0[l_mut_1];
atomicStore(l_4,u32(0));
l_mut_1 = l_mut_1 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_5 = u64(info.scalars_u32[1]);
let l_6 = l_5 << u32(bitcast<u64>(u64(32)));
let l_7 = u64(info.scalars_u32[0]);
let l_8 = l_6 | l_7;
let l_9 = u64(info.scalars_u32[3]);
let l_10 = l_9 << u32(bitcast<u64>(u64(32)));
let l_11 = u64(info.scalars_u32[2]);
let l_12 = l_10 | l_11;
let l_13 = u64(info.scalars_u32[5]);
let l_14 = l_13 << u32(bitcast<u64>(u64(32)));
let l_15 = u64(info.scalars_u32[4]);
let l_16 = l_14 | l_15;
let l_17 = local_invocation_id.x >> u32(5);
let l_18 = l_17 % u32(4);
let l_19 = u64(num_workgroups.x);
let l_20 = u64(WORKGROUP_SIZE_X);
let l_21 = l_19 * l_20;
let l_23 = local_invocation_id.x * u32(7);
let l_24 = u64(global_id.x);
l_mut_25 = l_24;
loop {
let l_26 = l_mut_25 < l_16;
let l_27 = !l_26;
if l_27 {
break;
}
let l_28 = l_8 + l_mut_25;
l_mut_29 = l_12;
let l_30 = l_28 < l_8;
if l_30 {
l_mut_29 = l_mut_29 + u64(1);
}
let l_32 = l_28 >> u32(bitcast<u64>(u64(0)));
let l_33 = u32(bitcast<u64>(l_32));
a_31[u32(0)] = l_33;
let l_34 = l_28 >> u32(bitcast<u64>(u64(32)));
let l_35 = u32(bitcast<u64>(l_34));
a_31[u32(1)] = l_35;
a_36[u32(0)] = u32(0);
a_36[u32(1)] = u32(0);
a_36[u32(2)] = u32(0);
a_36[u32(3)] = u32(0);
l_mut_37 = u64(0);
let l_38 = a_31[u32(0)];
let l_39 = u64(l_38);
let l_40 = a_31[u32(0)];
let l_41 = u64(l_40);
let l_42 = l_39 * l_41;
let l_43 = a_36[u32(0)];
let l_44 = u64(l_43);
let l_45 = l_42 + l_44;
let l_46 = l_45 + l_mut_37;
let l_47 = u32(bitcast<u64>(l_46));
a_36[u32(0)] = l_47;
let l_48 = l_46 >> u32(bitcast<u64>(u64(32)));
l_mut_37 = l_48;
let l_49 = a_31[u32(0)];
let l_50 = u64(l_49);
let l_51 = a_31[u32(1)];
let l_52 = u64(l_51);
let l_53 = l_50 * l_52;
let l_54 = a_36[u32(1)];
let l_55 = u64(l_54);
let l_56 = l_53 + l_55;
let l_57 = l_56 + l_mut_37;
let l_58 = u32(bitcast<u64>(l_57));
a_36[u32(1)] = l_58;
let l_59 = l_57 >> u32(bitcast<u64>(u64(32)));
l_mut_37 = l_59;
let l_60 = u32(bitcast<u64>(l_mut_37));
a_36[u32(2)] = l_60;
l_mut_37 = u64(0);
let l_61 = a_31[u32(1)];
let l_62 = u64(l_61);
let l_63 = a_31[u32(0)];
let l_64 = u64(l_63);
let l_65 = l_62 * l_64;
let l_66 = a_36[u32(1)];
let l_67 = u64(l_66);
let l_68 = l_65 + l_67;
let l_69 = l_68 + l_mut_37;
let l_70 = u32(bitcast<u64>(l_69));
a_36[u32(1)] = l_70;
let l_71 = l_69 >> u32(bitcast<u64>(u64(32)));
l_mut_37 = l_71;
let l_72 = a_31[u32(1)];
let l_73 = u64(l_72);
let l_74 = a_31[u32(1)];
let l_75 = u64(l_74);
let l_76 = l_73 * l_75;
let l_77 = a_36[u32(2)];
let l_78 = u64(l_77);
let l_79 = l_76 + l_78;
let l_80 = l_79 + l_mut_37;
let l_81 = u32(bitcast<u64>(l_80));
a_36[u32(2)] = l_81;
let l_82 = l_80 >> u32(bitcast<u64>(u64(32)));
l_mut_37 = l_82;
let l_83 = u32(bitcast<u64>(l_mut_37));
a_36[u32(3)] = l_83;
a_84[u32(0)] = u32(0);
a_84[u32(1)] = u32(0);
a_84[u32(2)] = u32(0);
a_84[u32(3)] = u32(0);
a_84[u32(4)] = u32(0);
a_84[u32(5)] = u32(0);
l_mut_37 = u64(0);
let l_85 = a_36[u32(0)];
let l_86 = u64(l_85);
let l_87 = a_31[u32(0)];
let l_88 = u64(l_87);
let l_89 = l_86 * l_88;
let l_90 = a_84[u32(0)];
let l_91 = u64(l_90);
let l_92 = l_89 + l_91;
let l_93 = l_92 + l_mut_37;
let l_94 = u32(bitcast<u64>(l_93));
a_84[u32(0)] = l_94;
let l_95 = l_93 >> u32(bitcast<u64>(u64(32)));
l_mut_37 = l_95;
let l_96 = a_36[u32(0)];
let l_97 = u64(l_96);
let l_98 = a_31[u32(1)];
let l_99 = u64(l_98);
let l_100 = l_97 * l_99;
let l_101 = a_84[u32(1)];
let l_102 = u64(l_101);
let l_103 = l_100 + l_102;
let l_104 = l_103 + l_mut_37;
let l_105 = u32(bitcast<u64>(l_104));
a_84[u32(1)] = l_105;
let l_106 = l_104 >> u32(bitcast<u64>(u64(32)));
l_mut_37 = l_106;
let l_107 = u32(bitcast<u64>(l_mut_37));
a_84[u32(2)] = l_107;
l_mut_37 = u64(0);
let l_108 = a_36[u32(1)];
let l_109 = u64(l_108);
let l_110 = a_31[u32(0)];
let l_111 = u64(l_110);
let l_112 = l_109 * l_111;
let l_113 = a_84[u32(1)];
let l_114 = u64(l_113);
let l_115 = l_112 + l_114;
let l_116 = l_115 + l_mut_37;
let l_117 = u32(bitcast<u64>(l_116));
a_84[u32(1)] = l_117;
let l_118 = l_116 >> u32(bitcast<u64>(u64(32)));
l_mut_37 = l_118;
let l_119 = a_36[u32(1)];
let l_120 = u64(l_119);
let l_121 = a_31[u32(1)];
let l_122 = u64(l_121);
let l_123 = l_120 * l_122;
let l_124 = a_84[u32(2)];
let l_125 = u64(l_124);
let l_126 = l_123 + l_125;
let l_127 = l_126 + l_mut_37;
let l_128 = u32(bitcast<u64>(l_127));
a_84[u32(2)] = l_128;
let l_129 = l_127 >> u32(bitcast<u64>(u64(32)));
l_mut_37 = l_129;
let l_130 = u32(bitcast<u64>(l_mut_37));
a_84[u32(3)] = l_130;
l_mut_37 = u64(0);
let l_131 = a_36[u32(2)];
let l_132 = u64(l_131);
let l_133 = a_31[u32(0)];
let l_134 = u64(l_133);
let l_135 = l_132 * l_134;
let l_136 = a_84[u32(2)];
let l_137 = u64(l_136);
let l_138 = l_135 + l_137;
let l_139 = l_138 + l_mut_37;
let l_140 = u32(bitcast<u64>(l_139));
a_84[u32(2)] = l_140;
let l_141 = l_139 >> u32(bitcast<u64>(u64(32)));
l_mut_37 = l_141;
let l_142 = a_36[u32(2)];
let l_143 = u64(l_142);
let l_144 = a_31[u32(1)];
let l_145 = u64(l_144);
let l_146 = l_143 * l_145;
let l_147 = a_84[u32(3)];
let l_148 = u64(l_147);
let l_149 = l_146 + l_148;
let l_150 = l_149 + l_mut_37;
let l_151 = u32(bitcast<u64>(l_150));
a_84[u32(3)] = l_151;
let l_152 = l_150 >> u32(bitcast<u64>(u64(32)));
l_mut_37 = l_152;
let l_153 = u32(bitcast<u64>(l_mut_37));
a_84[u32(4)] = l_153;
l_mut_37 = u64(0);
let l_154 = a_36[u32(3)];
let l_155 = u64(l_154);
let l_156 = a_31[u32(0)];
let l_157 = u64(l_156);
let l_158 = l_155 * l_157;
let l_159 = a_84[u32(3)];
let l_160 = u64(l_159);
let l_161 = l_158 + l_160;
let l_162 = l_161 + l_mut_37;
let l_163 = u32(bitcast<u64>(l_162));
a_84[u32(3)] = l_163;
let l_164 = l_162 >> u32(bitcast<u64>(u64(32)));
l_mut_37 = l_164;
let l_165 = a_36[u32(3)];
let l_166 = u64(l_165);
let l_167 = a_31[u32(1)];
let l_168 = u64(l_167);
let l_169 = l_166 * l_168;
let l_170 = a_84[u32(4)];
let l_171 = u64(l_170);
let l_172 = l_169 + l_171;
let l_173 = l_172 + l_mut_37;
let l_174 = u32(bitcast<u64>(l_173));
a_84[u32(4)] = l_174;
let l_175 = l_173 >> u32(bitcast<u64>(u64(32)));
l_mut_37 = l_175;
let l_176 = u32(bitcast<u64>(l_mut_37));
a_84[u32(5)] = l_176;
l_mut_37 = u64(0);
l_mut_177 = u64(0);
l_mut_178 = u32(0);
loop {
let l_179 = l_mut_178 < u32(2);
let l_180 = !l_179;
if l_180 {
break;
}
let l_181 = l_mut_178 == u32(0);
if l_181 {
let l_182 = l_23 + u32(0);
let l_183 = a_36[u32(0)];
shared_memory_22[l_182] = l_183;
let l_184 = l_23 + u32(1);
let l_185 = a_36[u32(1)];
shared_memory_22[l_184] = l_185;
let l_186 = l_23 + u32(2);
let l_187 = a_36[u32(2)];
shared_memory_22[l_186] = l_187;
let l_188 = l_23 + u32(3);
let l_189 = a_36[u32(3)];
shared_memory_22[l_188] = l_189;
let l_190 = l_23 + u32(4);
shared_memory_22[l_190] = u32(0);
let l_191 = l_23 + u32(5);
shared_memory_22[l_191] = u32(0);
} else {
let l_192 = l_23 + u32(0);
let l_193 = a_84[u32(0)];
shared_memory_22[l_192] = l_193;
let l_194 = l_23 + u32(1);
let l_195 = a_84[u32(1)];
shared_memory_22[l_194] = l_195;
let l_196 = l_23 + u32(2);
let l_197 = a_84[u32(2)];
shared_memory_22[l_196] = l_197;
let l_198 = l_23 + u32(3);
let l_199 = a_84[u32(3)];
shared_memory_22[l_198] = l_199;
let l_200 = l_23 + u32(4);
let l_201 = a_84[u32(4)];
shared_memory_22[l_200] = l_201;
let l_202 = l_23 + u32(5);
let l_203 = a_84[u32(5)];
shared_memory_22[l_202] = l_203;
}
l_mut_204 = i32(5);
loop {
let l_205 = l_mut_204 >= i32(0);
let l_206 = !l_205;
if l_206 {
break;
}
let l_207 = u32(l_mut_204);
let l_208 = l_23 + l_207;
let l_209 = shared_memory_22[l_208];
let l_210 = l_209 != u32(0);
if l_210 {
break;
}
l_mut_204 = l_mut_204 - i32(1);
}
loop {
let l_211 = l_mut_204 >= i32(0);
let l_212 = !l_211;
if l_212 {
break;
}
l_mut_213 = u32(0);
l_mut_214 = l_mut_204;
loop {
let l_215 = l_mut_214 >= i32(0);
let l_216 = !l_215;
if l_216 {
break;
}
let l_217 = u32(l_mut_214);
let l_218 = l_23 + l_217;
let l_219 = shared_memory_22[l_218];
let l_220 = l_mut_213 << u32(16);
let l_221 = l_219 >> u32(16);
let l_222 = l_220 | l_221;
let l_223 = l_222 / u32(64000);
let l_224 = l_223 * u32(64000);
let l_225 = l_222 - l_224;
let l_226 = l_225 << u32(16);
let l_227 = l_219 & u32(65535);
let l_228 = l_226 | l_227;
let l_229 = l_228 / u32(64000);
let l_230 = l_229 * u32(64000);
let l_231 = l_228 - l_230;
l_mut_213 = l_231;
let l_232 = u32(l_mut_214);
let l_233 = l_23 + l_232;
let l_234 = l_223 << u32(16);
let l_235 = l_234 | l_229;
shared_memory_22[l_233] = l_235;
l_mut_214 = l_mut_214 - i32(1);
}
loop {
let l_236 = l_mut_204 >= i32(0);
let l_237 = !l_236;
if l_237 {
break;
}
let l_238 = u32(l_mut_204);
let l_239 = l_23 + l_238;
let l_240 = shared_memory_22[l_239];
let l_241 = l_240 != u32(0);
if l_241 {
break;
}
l_mut_204 = l_mut_204 - i32(1);
}
l_mut_242 = l_mut_213;
let l_243 = l_mut_204 >= i32(0);
if l_243 {
let l_244 = l_mut_242 / u32(40);
let l_245 = l_244 * u32(40);
let l_246 = l_mut_242 - l_245;
l_mut_242 = l_244;
let l_247 = u64(l_246);
let l_248 = u64(1) << u32(bitcast<u64>(l_247));
l_mut_37 = l_mut_37 | l_248;
let l_249 = l_mut_242 / u32(40);
let l_250 = l_249 * u32(40);
let l_251 = l_mut_242 - l_250;
l_mut_242 = l_249;
let l_252 = u64(l_251);
let l_253 = u64(1) << u32(bitcast<u64>(l_252));
l_mut_37 = l_mut_37 | l_253;
let l_254 = l_mut_242 / u32(40);
let l_255 = l_254 * u32(40);
let l_256 = l_mut_242 - l_255;
l_mut_242 = l_254;
let l_257 = u64(l_256);
let l_258 = u64(1) << u32(bitcast<u64>(l_257));
l_mut_37 = l_mut_37 | l_258;
} else {
loop {
let l_259 = l_mut_242 != u32(0);
let l_260 = !l_259;
if l_260 {
break;
}
let l_261 = l_mut_242 / u32(40);
let l_262 = l_261 * u32(40);
let l_263 = l_mut_242 - l_262;
l_mut_242 = l_261;
let l_264 = u64(l_263);
let l_265 = u64(1) << u32(bitcast<u64>(l_264));
l_mut_37 = l_mut_37 | l_265;
}
}
}
l_mut_178 = l_mut_178 + u32(1);
}
let l_266 = u32(bitcast<u64>(l_mut_37));
let l_267 = countOneBits(l_266);
let l_268 = l_mut_37 >> u32(bitcast<u64>(u64(32)));
let l_269 = u32(bitcast<u64>(l_268));
let l_270 = countOneBits(l_269);
let l_271 = l_267 + l_270;
l_mut_242 = l_271;
let l_272 = l_18 * u32(41);
let l_273 = l_272 + l_mut_242;
let l_274 = &shared_memory_0[l_273];
let l_275 = atomicAdd(l_274, u32(1));let l_276 = l_mut_242 > u32(36);
if l_276 {
let l_277 = &buffer_1_global[u32(0)];
let l_278 = atomicAdd(l_277, u32(1));let l_279 = l_278 < info.scalars_u32[6];
if l_279 {
let l_280 = u32(5) * l_278;
let l_281 = u32(bitcast<u64>(l_28));
buffer_2_global[l_280] = l_281;
let l_282 = l_280 + u32(1);
let l_283 = l_28 >> u32(bitcast<u64>(u64(32)));
let l_284 = u32(bitcast<u64>(l_283));
buffer_2_global[l_282] = l_284;
let l_285 = l_280 + u32(2);
let l_286 = u32(bitcast<u64>(l_mut_29));
buffer_2_global[l_285] = l_286;
let l_287 = l_280 + u32(3);
let l_288 = l_mut_29 >> u32(bitcast<u64>(u64(32)));
let l_289 = u32(bitcast<u64>(l_288));
buffer_2_global[l_287] = l_289;
let l_290 = l_280 + u32(4);
buffer_2_global[l_290] = l_mut_242;
}
}
l_mut_25 = l_mut_25 + l_21;
}
workgroupBarrier();
l_mut_242 = local_invocation_id.x;
loop {
let l_291 = l_mut_242 < u32(41);
let l_292 = !l_291;
if l_292 {
break;
}
l_mut_213 = u32(0);
let l_293 = u32(0) + l_mut_242;
let l_294 = &shared_memory_0[l_293];
let l_295 = atomicLoad(l_294);
l_mut_213 = l_mut_213 + l_295;
let l_296 = u32(41) + l_mut_242;
let l_297 = &shared_memory_0[l_296];
let l_298 = atomicLoad(l_297);
l_mut_213 = l_mut_213 + l_298;
let l_299 = u32(82) + l_mut_242;
let l_300 = &shared_memory_0[l_299];
let l_301 = atomicLoad(l_300);
l_mut_213 = l_mut_213 + l_301;
let l_302 = u32(123) + l_mut_242;
let l_303 = &shared_memory_0[l_302];
let l_304 = atomicLoad(l_303);
l_mut_213 = l_mut_213 + l_304;
let l_305 = l_mut_213 != u32(0);
if l_305 {
let l_306 = &buffer_0_global[l_mut_242];
let l_307 = atomicAdd(l_306, l_mut_213);}
l_mut_242 = l_mut_242 + WORKGROUP_SIZE_X;
}
}
```
