
```wgsl
@group(0)
@binding(0)
var<storage, read_write> buffer_0_global: array<u32>;

@group(0)
@binding(1)
var<storage, read_write> buffer_1_global: array<atomic<u32>>;

@group(0)
@binding(2)
var<storage, read_write> buffer_2_global: array<u32>;

@group(0)
@binding(3)
var<storage, read_write> buffer_3_global: array<u32>;

@group(0)
@binding(4)
var<storage, read_write> buffer_4_global: array<atomic<u32>>;

@group(0)
@binding(5)
var<storage, read_write> buffer_5_global: array<atomic<u32>>;

struct info_st {
   scalars_u32: array<u32, 4>,
   static_meta: array<u32, 12>,
}

@group(0)
@binding(6)
var<storage, read> info: info_st;

var<workgroup> shared_memory_0: array<u32, 768>;

const WORKGROUP_SIZE_X = 256u;
const WORKGROUP_SIZE_Y = 1u;
const WORKGROUP_SIZE_Z = 1u;

@compute
@workgroup_size(256, 1, 1)
fn check_kernel(
    @builtin(global_invocation_id) global_id: vec3<u32>,
    @builtin(local_invocation_id) local_invocation_id: vec3<u32>,
    @builtin(num_workgroups) num_workgroups: vec3<u32>,
) {
var a_37: array<u32, 1>;

var a_40: array<u32, 2>;

var l_mut_33: bool;
var l_mut_4: u32;
var l_mut_7: u32;
var l_mut_68: u32;
var l_mut_97: u32;
var l_mut_58: i32;
var l_mut_69: i32;
var l_mut_174: i32;
var l_mut_28: u64;
var l_mut_34: u64;
var l_mut_35: u64;
var l_mut_41: u64;
let l_1 = local_invocation_id.x * u32(3);
let l_2 = &buffer_1_global[u32(0)];
let l_3 = atomicLoad(l_2);
l_mut_4 = l_3;
let l_5 = l_mut_4 > info.scalars_u32[0];
if l_5 {
l_mut_4 = info.scalars_u32[0];
}
let l_6 = num_workgroups.x * WORKGROUP_SIZE_X;
l_mut_7 = global_id.x;
loop {
let l_8 = l_mut_7 < l_mut_4;
let l_9 = !l_8;
if l_9 {
break;
}
let l_10 = u32(2) * l_mut_7;
let l_11 = buffer_0_global[l_10];
let l_12 = u32(2) * l_mut_7;
let l_13 = l_12 + u32(1);
let l_14 = buffer_0_global[l_13];
let l_15 = u32(2) * l_11;
let l_16 = buffer_2_global[l_15];
let l_17 = u64(l_16);
let l_18 = u32(2) * l_11;
let l_19 = l_18 + u32(1);
let l_20 = buffer_2_global[l_19];
let l_21 = u64(l_20);
let l_22 = u64(info.scalars_u32[2]);
let l_23 = l_17 * l_22;
let l_24 = l_21 * l_22;
let l_25 = l_24 << u32(bitcast<u64>(u64(32)));
let l_26 = l_23 + l_25;
let l_27 = l_24 >> u32(bitcast<u64>(u64(32)));
l_mut_28 = l_27;
let l_29 = l_26 < l_23;
if l_29 {
l_mut_28 = l_mut_28 + u64(1);
}
let l_30 = u64(l_14);
let l_31 = l_26 + l_30;
let l_32 = l_31 < l_26;
if l_32 {
l_mut_28 = l_mut_28 + u64(1);
}
l_mut_33 = bool(true);
l_mut_34 = u64(0);
l_mut_35 = u64(0);
let l_36 = l_mut_33 && bool(true);
if l_36 {
let l_38 = l_31 >> u32(bitcast<u64>(u64(0)));
let l_39 = u32(bitcast<u64>(l_38));
a_37[u32(0)] = l_39;
a_40[u32(0)] = u32(0);
a_40[u32(1)] = u32(0);
l_mut_41 = u64(0);
let l_42 = a_37[u32(0)];
let l_43 = u64(l_42);
let l_44 = a_37[u32(0)];
let l_45 = u64(l_44);
let l_46 = l_43 * l_45;
let l_47 = a_40[u32(0)];
let l_48 = u64(l_47);
let l_49 = l_46 + l_48;
let l_50 = l_49 + l_mut_41;
let l_51 = u32(bitcast<u64>(l_50));
a_40[u32(0)] = l_51;
let l_52 = l_50 >> u32(bitcast<u64>(u64(32)));
l_mut_41 = l_52;
let l_53 = u32(bitcast<u64>(l_mut_41));
a_40[u32(1)] = l_53;
let l_54 = l_1 + u32(0);
let l_55 = a_40[u32(0)];
shared_memory_0[l_54] = l_55;
let l_56 = l_1 + u32(1);
let l_57 = a_40[u32(1)];
shared_memory_0[l_56] = l_57;
l_mut_58 = i32(1);
loop {
let l_59 = l_mut_58 >= i32(0);
let l_60 = !l_59;
if l_60 {
break;
}
let l_61 = u32(l_mut_58);
let l_62 = l_1 + l_61;
let l_63 = shared_memory_0[l_62];
let l_64 = l_63 != u32(0);
if l_64 {
break;
}
l_mut_58 = l_mut_58 - i32(1);
}
loop {
let l_65 = l_mut_58 >= i32(0);
let l_66 = l_65 && l_mut_33;
let l_67 = !l_66;
if l_67 {
break;
}
l_mut_68 = u32(0);
l_mut_69 = l_mut_58;
loop {
let l_70 = l_mut_69 >= i32(0);
let l_71 = !l_70;
if l_71 {
break;
}
let l_72 = u32(l_mut_69);
let l_73 = l_1 + l_72;
let l_74 = shared_memory_0[l_73];
let l_75 = l_mut_68 << u32(16);
let l_76 = l_74 >> u32(16);
let l_77 = l_75 | l_76;
let l_78 = l_77 / u32(10000);
let l_79 = l_78 * u32(10000);
let l_80 = l_77 - l_79;
let l_81 = l_80 << u32(16);
let l_82 = l_74 & u32(65535);
let l_83 = l_81 | l_82;
let l_84 = l_83 / u32(10000);
let l_85 = l_84 * u32(10000);
let l_86 = l_83 - l_85;
l_mut_68 = l_86;
let l_87 = u32(l_mut_69);
let l_88 = l_1 + l_87;
let l_89 = l_78 << u32(16);
let l_90 = l_89 | l_84;
shared_memory_0[l_88] = l_90;
l_mut_69 = l_mut_69 - i32(1);
}
loop {
let l_91 = l_mut_58 >= i32(0);
let l_92 = !l_91;
if l_92 {
break;
}
let l_93 = u32(l_mut_58);
let l_94 = l_1 + l_93;
let l_95 = shared_memory_0[l_94];
let l_96 = l_95 != u32(0);
if l_96 {
break;
}
l_mut_58 = l_mut_58 - i32(1);
}
l_mut_97 = l_mut_68;
l_mut_41 = u64(0);
let l_98 = l_mut_58 >= i32(0);
if l_98 {
let l_99 = l_mut_97 / u32(10);
let l_100 = l_99 * u32(10);
let l_101 = l_mut_97 - l_100;
l_mut_97 = l_99;
let l_102 = u64(l_101);
let l_103 = u64(1) << u32(bitcast<u64>(l_102));
let l_104 = l_mut_34 & l_103;
l_mut_41 = l_mut_41 | l_104;
l_mut_34 = l_mut_34 | l_103;
let l_105 = l_mut_97 / u32(10);
let l_106 = l_105 * u32(10);
let l_107 = l_mut_97 - l_106;
l_mut_97 = l_105;
let l_108 = u64(l_107);
let l_109 = u64(1) << u32(bitcast<u64>(l_108));
let l_110 = l_mut_34 & l_109;
l_mut_41 = l_mut_41 | l_110;
l_mut_34 = l_mut_34 | l_109;
let l_111 = l_mut_97 / u32(10);
let l_112 = l_111 * u32(10);
let l_113 = l_mut_97 - l_112;
l_mut_97 = l_111;
let l_114 = u64(l_113);
let l_115 = u64(1) << u32(bitcast<u64>(l_114));
let l_116 = l_mut_34 & l_115;
l_mut_41 = l_mut_41 | l_116;
l_mut_34 = l_mut_34 | l_115;
let l_117 = l_mut_97 / u32(10);
let l_118 = l_117 * u32(10);
let l_119 = l_mut_97 - l_118;
l_mut_97 = l_117;
let l_120 = u64(l_119);
let l_121 = u64(1) << u32(bitcast<u64>(l_120));
let l_122 = l_mut_34 & l_121;
l_mut_41 = l_mut_41 | l_122;
l_mut_34 = l_mut_34 | l_121;
} else {
loop {
let l_123 = l_mut_97 != u32(0);
let l_124 = !l_123;
if l_124 {
break;
}
let l_125 = l_mut_97 / u32(10);
let l_126 = l_125 * u32(10);
let l_127 = l_mut_97 - l_126;
l_mut_97 = l_125;
let l_128 = u64(l_127);
let l_129 = u64(1) << u32(bitcast<u64>(l_128));
let l_130 = l_mut_34 & l_129;
l_mut_41 = l_mut_41 | l_130;
l_mut_34 = l_mut_34 | l_129;
}
}
let l_131 = l_mut_41 != u64(0);
if l_131 {
l_mut_33 = bool(false);
}
}
if l_mut_33 {
let l_132 = l_1 + u32(0);
shared_memory_0[l_132] = u32(0);
let l_133 = l_1 + u32(1);
shared_memory_0[l_133] = u32(0);
let l_134 = l_1 + u32(2);
shared_memory_0[l_134] = u32(0);
l_mut_41 = u64(0);
let l_135 = a_40[u32(0)];
let l_136 = u64(l_135);
let l_137 = a_37[u32(0)];
let l_138 = u64(l_137);
let l_139 = l_136 * l_138;
let l_140 = l_1 + u32(0);
let l_141 = shared_memory_0[l_140];
let l_142 = u64(l_141);
let l_143 = l_139 + l_142;
let l_144 = l_143 + l_mut_41;
let l_145 = l_1 + u32(0);
let l_146 = u32(bitcast<u64>(l_144));
shared_memory_0[l_145] = l_146;
let l_147 = l_144 >> u32(bitcast<u64>(u64(32)));
l_mut_41 = l_147;
let l_148 = l_1 + u32(1);
let l_149 = u32(bitcast<u64>(l_mut_41));
shared_memory_0[l_148] = l_149;
l_mut_41 = u64(0);
let l_150 = a_40[u32(1)];
let l_151 = u64(l_150);
let l_152 = a_37[u32(0)];
let l_153 = u64(l_152);
let l_154 = l_151 * l_153;
let l_155 = l_1 + u32(1);
let l_156 = shared_memory_0[l_155];
let l_157 = u64(l_156);
let l_158 = l_154 + l_157;
let l_159 = l_158 + l_mut_41;
let l_160 = l_1 + u32(1);
let l_161 = u32(bitcast<u64>(l_159));
shared_memory_0[l_160] = l_161;
let l_162 = l_159 >> u32(bitcast<u64>(u64(32)));
l_mut_41 = l_162;
let l_163 = l_1 + u32(2);
let l_164 = u32(bitcast<u64>(l_mut_41));
shared_memory_0[l_163] = l_164;
l_mut_69 = i32(2);
loop {
let l_165 = l_mut_69 >= i32(0);
let l_166 = !l_165;
if l_166 {
break;
}
let l_167 = u32(l_mut_69);
let l_168 = l_1 + l_167;
let l_169 = shared_memory_0[l_168];
let l_170 = l_169 != u32(0);
if l_170 {
break;
}
l_mut_69 = l_mut_69 - i32(1);
}
loop {
let l_171 = l_mut_69 >= i32(0);
let l_172 = l_171 && l_mut_33;
let l_173 = !l_172;
if l_173 {
break;
}
l_mut_97 = u32(0);
l_mut_174 = l_mut_69;
loop {
let l_175 = l_mut_174 >= i32(0);
let l_176 = !l_175;
if l_176 {
break;
}
let l_177 = u32(l_mut_174);
let l_178 = l_1 + l_177;
let l_179 = shared_memory_0[l_178];
let l_180 = l_mut_97 << u32(16);
let l_181 = l_179 >> u32(16);
let l_182 = l_180 | l_181;
let l_183 = l_182 / u32(10000);
let l_184 = l_183 * u32(10000);
let l_185 = l_182 - l_184;
let l_186 = l_185 << u32(16);
let l_187 = l_179 & u32(65535);
let l_188 = l_186 | l_187;
let l_189 = l_188 / u32(10000);
let l_190 = l_189 * u32(10000);
let l_191 = l_188 - l_190;
l_mut_97 = l_191;
let l_192 = u32(l_mut_174);
let l_193 = l_1 + l_192;
let l_194 = l_183 << u32(16);
let l_195 = l_194 | l_189;
shared_memory_0[l_193] = l_195;
l_mut_174 = l_mut_174 - i32(1);
}
loop {
let l_196 = l_mut_69 >= i32(0);
let l_197 = !l_196;
if l_197 {
break;
}
let l_198 = u32(l_mut_69);
let l_199 = l_1 + l_198;
let l_200 = shared_memory_0[l_199];
let l_201 = l_200 != u32(0);
if l_201 {
break;
}
l_mut_69 = l_mut_69 - i32(1);
}
l_mut_68 = l_mut_97;
l_mut_41 = u64(0);
let l_202 = l_mut_69 >= i32(0);
if l_202 {
let l_203 = l_mut_68 / u32(10);
let l_204 = l_203 * u32(10);
let l_205 = l_mut_68 - l_204;
l_mut_68 = l_203;
let l_206 = u64(l_205);
let l_207 = u64(1) << u32(bitcast<u64>(l_206));
let l_208 = l_mut_34 & l_207;
l_mut_41 = l_mut_41 | l_208;
l_mut_34 = l_mut_34 | l_207;
let l_209 = l_mut_68 / u32(10);
let l_210 = l_209 * u32(10);
let l_211 = l_mut_68 - l_210;
l_mut_68 = l_209;
let l_212 = u64(l_211);
let l_213 = u64(1) << u32(bitcast<u64>(l_212));
let l_214 = l_mut_34 & l_213;
l_mut_41 = l_mut_41 | l_214;
l_mut_34 = l_mut_34 | l_213;
let l_215 = l_mut_68 / u32(10);
let l_216 = l_215 * u32(10);
let l_217 = l_mut_68 - l_216;
l_mut_68 = l_215;
let l_218 = u64(l_217);
let l_219 = u64(1) << u32(bitcast<u64>(l_218));
let l_220 = l_mut_34 & l_219;
l_mut_41 = l_mut_41 | l_220;
l_mut_34 = l_mut_34 | l_219;
let l_221 = l_mut_68 / u32(10);
let l_222 = l_221 * u32(10);
let l_223 = l_mut_68 - l_222;
l_mut_68 = l_221;
let l_224 = u64(l_223);
let l_225 = u64(1) << u32(bitcast<u64>(l_224));
let l_226 = l_mut_34 & l_225;
l_mut_41 = l_mut_41 | l_226;
l_mut_34 = l_mut_34 | l_225;
} else {
loop {
let l_227 = l_mut_68 != u32(0);
let l_228 = !l_227;
if l_228 {
break;
}
let l_229 = l_mut_68 / u32(10);
let l_230 = l_229 * u32(10);
let l_231 = l_mut_68 - l_230;
l_mut_68 = l_229;
let l_232 = u64(l_231);
let l_233 = u64(1) << u32(bitcast<u64>(l_232));
let l_234 = l_mut_34 & l_233;
l_mut_41 = l_mut_41 | l_234;
l_mut_34 = l_mut_34 | l_233;
}
}
let l_235 = l_mut_41 != u64(0);
if l_235 {
l_mut_33 = bool(false);
}
}
}
}
if l_mut_33 {
let l_236 = u32(bitcast<u64>(l_mut_34));
let l_237 = countOneBits(l_236);
let l_238 = l_mut_34 >> u32(bitcast<u64>(u64(32)));
let l_239 = u32(bitcast<u64>(l_238));
let l_240 = countOneBits(l_239);
let l_241 = l_237 + l_240;
l_mut_97 = l_241;
let l_242 = l_mut_97 == u32(10);
let l_243 = bool(false) || l_242;
if l_243 {
let l_244 = &buffer_4_global[u32(0)];
let l_245 = atomicAdd(l_244, u32(1));let l_246 = l_245 < info.scalars_u32[1];
if l_246 {
let l_247 = u32(4) * l_245;
let l_248 = u32(bitcast<u64>(l_31));
buffer_3_global[l_247] = l_248;
let l_249 = l_247 + u32(1);
let l_250 = l_31 >> u32(bitcast<u64>(u64(32)));
let l_251 = u32(bitcast<u64>(l_250));
buffer_3_global[l_249] = l_251;
let l_252 = l_247 + u32(2);
let l_253 = u32(bitcast<u64>(l_mut_28));
buffer_3_global[l_252] = l_253;
let l_254 = l_247 + u32(3);
let l_255 = l_mut_28 >> u32(bitcast<u64>(u64(32)));
let l_256 = u32(bitcast<u64>(l_255));
buffer_3_global[l_254] = l_256;
}
}
}
l_mut_7 = l_mut_7 + l_6;
}
workgroupBarrier();
let l_257 = local_invocation_id.x == u32(0);
if l_257 {
let l_258 = &buffer_5_global[u32(5)];
let l_259 = atomicAdd(l_258, u32(1));}
}
```
