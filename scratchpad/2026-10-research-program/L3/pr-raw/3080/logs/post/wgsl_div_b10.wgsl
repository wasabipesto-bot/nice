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

var<workgroup> shared_memory_0: array<atomic<u32>, 44>;

var<workgroup> shared_memory_22: array<u32, 768>;

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
var a_31: array<u32, 1>;

var a_34: array<u32, 2>;

var a_48: array<u32, 3>;

var l_mut_1: u32;
var l_mut_74: u32;
var l_mut_98: u32;
var l_mut_127: u32;
var l_mut_89: i32;
var l_mut_99: i32;
var l_mut_25: u64;
var l_mut_29: u64;
var l_mut_35: u64;
var l_mut_73: u64;
l_mut_1 = local_invocation_id.x;
loop {
let l_2 = l_mut_1 < u32(44);
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
let l_23 = local_invocation_id.x * u32(3);
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
a_34[u32(0)] = u32(0);
a_34[u32(1)] = u32(0);
l_mut_35 = u64(0);
let l_36 = a_31[u32(0)];
let l_37 = u64(l_36);
let l_38 = a_31[u32(0)];
let l_39 = u64(l_38);
let l_40 = l_37 * l_39;
let l_41 = a_34[u32(0)];
let l_42 = u64(l_41);
let l_43 = l_40 + l_42;
let l_44 = l_43 + l_mut_35;
let l_45 = u32(bitcast<u64>(l_44));
a_34[u32(0)] = l_45;
let l_46 = l_44 >> u32(bitcast<u64>(u64(32)));
l_mut_35 = l_46;
let l_47 = u32(bitcast<u64>(l_mut_35));
a_34[u32(1)] = l_47;
a_48[u32(0)] = u32(0);
a_48[u32(1)] = u32(0);
a_48[u32(2)] = u32(0);
l_mut_35 = u64(0);
let l_49 = a_34[u32(0)];
let l_50 = u64(l_49);
let l_51 = a_31[u32(0)];
let l_52 = u64(l_51);
let l_53 = l_50 * l_52;
let l_54 = a_48[u32(0)];
let l_55 = u64(l_54);
let l_56 = l_53 + l_55;
let l_57 = l_56 + l_mut_35;
let l_58 = u32(bitcast<u64>(l_57));
a_48[u32(0)] = l_58;
let l_59 = l_57 >> u32(bitcast<u64>(u64(32)));
l_mut_35 = l_59;
let l_60 = u32(bitcast<u64>(l_mut_35));
a_48[u32(1)] = l_60;
l_mut_35 = u64(0);
let l_61 = a_34[u32(1)];
let l_62 = u64(l_61);
let l_63 = a_31[u32(0)];
let l_64 = u64(l_63);
let l_65 = l_62 * l_64;
let l_66 = a_48[u32(1)];
let l_67 = u64(l_66);
let l_68 = l_65 + l_67;
let l_69 = l_68 + l_mut_35;
let l_70 = u32(bitcast<u64>(l_69));
a_48[u32(1)] = l_70;
let l_71 = l_69 >> u32(bitcast<u64>(u64(32)));
l_mut_35 = l_71;
let l_72 = u32(bitcast<u64>(l_mut_35));
a_48[u32(2)] = l_72;
l_mut_35 = u64(0);
l_mut_73 = u64(0);
l_mut_74 = u32(0);
loop {
let l_75 = l_mut_74 < u32(2);
let l_76 = !l_75;
if l_76 {
break;
}
let l_77 = l_mut_74 == u32(0);
if l_77 {
let l_78 = l_23 + u32(0);
let l_79 = a_34[u32(0)];
shared_memory_22[l_78] = l_79;
let l_80 = l_23 + u32(1);
let l_81 = a_34[u32(1)];
shared_memory_22[l_80] = l_81;
let l_82 = l_23 + u32(2);
shared_memory_22[l_82] = u32(0);
} else {
let l_83 = l_23 + u32(0);
let l_84 = a_48[u32(0)];
shared_memory_22[l_83] = l_84;
let l_85 = l_23 + u32(1);
let l_86 = a_48[u32(1)];
shared_memory_22[l_85] = l_86;
let l_87 = l_23 + u32(2);
let l_88 = a_48[u32(2)];
shared_memory_22[l_87] = l_88;
}
l_mut_89 = i32(2);
loop {
let l_90 = l_mut_89 >= i32(0);
let l_91 = !l_90;
if l_91 {
break;
}
let l_92 = u32(l_mut_89);
let l_93 = l_23 + l_92;
let l_94 = shared_memory_22[l_93];
let l_95 = l_94 != u32(0);
if l_95 {
break;
}
l_mut_89 = l_mut_89 - i32(1);
}
loop {
let l_96 = l_mut_89 >= i32(0);
let l_97 = !l_96;
if l_97 {
break;
}
l_mut_98 = u32(0);
l_mut_99 = l_mut_89;
loop {
let l_100 = l_mut_99 >= i32(0);
let l_101 = !l_100;
if l_101 {
break;
}
let l_102 = u32(l_mut_99);
let l_103 = l_23 + l_102;
let l_104 = shared_memory_22[l_103];
let l_105 = l_mut_98 << u32(16);
let l_106 = l_104 >> u32(16);
let l_107 = l_105 | l_106;
let l_108 = l_107 / u32(10000);
let l_109 = l_108 * u32(10000);
let l_110 = l_107 - l_109;
let l_111 = l_110 << u32(16);
let l_112 = l_104 & u32(65535);
let l_113 = l_111 | l_112;
let l_114 = l_113 / u32(10000);
let l_115 = l_114 * u32(10000);
let l_116 = l_113 - l_115;
l_mut_98 = l_116;
let l_117 = u32(l_mut_99);
let l_118 = l_23 + l_117;
let l_119 = l_108 << u32(16);
let l_120 = l_119 | l_114;
shared_memory_22[l_118] = l_120;
l_mut_99 = l_mut_99 - i32(1);
}
loop {
let l_121 = l_mut_89 >= i32(0);
let l_122 = !l_121;
if l_122 {
break;
}
let l_123 = u32(l_mut_89);
let l_124 = l_23 + l_123;
let l_125 = shared_memory_22[l_124];
let l_126 = l_125 != u32(0);
if l_126 {
break;
}
l_mut_89 = l_mut_89 - i32(1);
}
l_mut_127 = l_mut_98;
let l_128 = l_mut_89 >= i32(0);
if l_128 {
let l_129 = l_mut_127 / u32(10);
let l_130 = l_129 * u32(10);
let l_131 = l_mut_127 - l_130;
l_mut_127 = l_129;
let l_132 = u64(l_131);
let l_133 = u64(1) << u32(bitcast<u64>(l_132));
l_mut_35 = l_mut_35 | l_133;
let l_134 = l_mut_127 / u32(10);
let l_135 = l_134 * u32(10);
let l_136 = l_mut_127 - l_135;
l_mut_127 = l_134;
let l_137 = u64(l_136);
let l_138 = u64(1) << u32(bitcast<u64>(l_137));
l_mut_35 = l_mut_35 | l_138;
let l_139 = l_mut_127 / u32(10);
let l_140 = l_139 * u32(10);
let l_141 = l_mut_127 - l_140;
l_mut_127 = l_139;
let l_142 = u64(l_141);
let l_143 = u64(1) << u32(bitcast<u64>(l_142));
l_mut_35 = l_mut_35 | l_143;
let l_144 = l_mut_127 / u32(10);
let l_145 = l_144 * u32(10);
let l_146 = l_mut_127 - l_145;
l_mut_127 = l_144;
let l_147 = u64(l_146);
let l_148 = u64(1) << u32(bitcast<u64>(l_147));
l_mut_35 = l_mut_35 | l_148;
} else {
loop {
let l_149 = l_mut_127 != u32(0);
let l_150 = !l_149;
if l_150 {
break;
}
let l_151 = l_mut_127 / u32(10);
let l_152 = l_151 * u32(10);
let l_153 = l_mut_127 - l_152;
l_mut_127 = l_151;
let l_154 = u64(l_153);
let l_155 = u64(1) << u32(bitcast<u64>(l_154));
l_mut_35 = l_mut_35 | l_155;
}
}
}
l_mut_74 = l_mut_74 + u32(1);
}
let l_156 = u32(bitcast<u64>(l_mut_35));
let l_157 = countOneBits(l_156);
let l_158 = l_mut_35 >> u32(bitcast<u64>(u64(32)));
let l_159 = u32(bitcast<u64>(l_158));
let l_160 = countOneBits(l_159);
let l_161 = l_157 + l_160;
l_mut_127 = l_161;
let l_162 = l_18 * u32(11);
let l_163 = l_162 + l_mut_127;
let l_164 = &shared_memory_0[l_163];
let l_165 = atomicAdd(l_164, u32(1));let l_166 = l_mut_127 > u32(9);
if l_166 {
let l_167 = &buffer_1_global[u32(0)];
let l_168 = atomicAdd(l_167, u32(1));let l_169 = l_168 < info.scalars_u32[6];
if l_169 {
let l_170 = u32(5) * l_168;
let l_171 = u32(bitcast<u64>(l_28));
buffer_2_global[l_170] = l_171;
let l_172 = l_170 + u32(1);
let l_173 = l_28 >> u32(bitcast<u64>(u64(32)));
let l_174 = u32(bitcast<u64>(l_173));
buffer_2_global[l_172] = l_174;
let l_175 = l_170 + u32(2);
let l_176 = u32(bitcast<u64>(l_mut_29));
buffer_2_global[l_175] = l_176;
let l_177 = l_170 + u32(3);
let l_178 = l_mut_29 >> u32(bitcast<u64>(u64(32)));
let l_179 = u32(bitcast<u64>(l_178));
buffer_2_global[l_177] = l_179;
let l_180 = l_170 + u32(4);
buffer_2_global[l_180] = l_mut_127;
}
}
l_mut_25 = l_mut_25 + l_21;
}
workgroupBarrier();
l_mut_127 = local_invocation_id.x;
loop {
let l_181 = l_mut_127 < u32(11);
let l_182 = !l_181;
if l_182 {
break;
}
l_mut_98 = u32(0);
let l_183 = u32(0) + l_mut_127;
let l_184 = &shared_memory_0[l_183];
let l_185 = atomicLoad(l_184);
l_mut_98 = l_mut_98 + l_185;
let l_186 = u32(11) + l_mut_127;
let l_187 = &shared_memory_0[l_186];
let l_188 = atomicLoad(l_187);
l_mut_98 = l_mut_98 + l_188;
let l_189 = u32(22) + l_mut_127;
let l_190 = &shared_memory_0[l_189];
let l_191 = atomicLoad(l_190);
l_mut_98 = l_mut_98 + l_191;
let l_192 = u32(33) + l_mut_127;
let l_193 = &shared_memory_0[l_192];
let l_194 = atomicLoad(l_193);
l_mut_98 = l_mut_98 + l_194;
let l_195 = l_mut_98 != u32(0);
if l_195 {
let l_196 = &buffer_0_global[l_mut_127];
let l_197 = atomicAdd(l_196, l_mut_98);}
l_mut_127 = l_mut_127 + WORKGROUP_SIZE_X;
}
}
