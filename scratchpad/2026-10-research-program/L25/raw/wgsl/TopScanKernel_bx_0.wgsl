
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

@group(0)
@binding(3)
var<storage, read_write> buffer_3_global: array<atomic<u32>>;

struct info_st {
   scalars_u32: array<u32, 2>,
   static_meta: array<u32, 8>,
}

@group(0)
@binding(4)
var<storage, read> info: info_st;

var<workgroup> shared_memory_0: array<u32, 256>;

const WORKGROUP_SIZE_X = 256u;
const WORKGROUP_SIZE_Y = 1u;
const WORKGROUP_SIZE_Z = 1u;

@compute
@workgroup_size(256, 1, 1)
fn top_scan_kernel(
    @builtin(local_invocation_id) local_invocation_id: vec3<u32>,
    @builtin(workgroup_id) workgroup_id: vec3<u32>,
) {
var l_mut_2: u32;
var l_mut_46: u32;
let l_1 = local_invocation_id.x * u32(7);
l_mut_2 = u32(0);
let l_3 = l_1 + u32(0);
let l_4 = l_3 < u32(1560);
if l_4 {
let l_5 = workgroup_id.x * u32(1560);
let l_6 = l_5 + l_3;
let l_7 = &buffer_0_global[l_6];
let l_8 = atomicLoad(l_7);
l_mut_2 = l_mut_2 + l_8;
}
let l_9 = l_1 + u32(1);
let l_10 = l_9 < u32(1560);
if l_10 {
let l_11 = workgroup_id.x * u32(1560);
let l_12 = l_11 + l_9;
let l_13 = &buffer_0_global[l_12];
let l_14 = atomicLoad(l_13);
l_mut_2 = l_mut_2 + l_14;
}
let l_15 = l_1 + u32(2);
let l_16 = l_15 < u32(1560);
if l_16 {
let l_17 = workgroup_id.x * u32(1560);
let l_18 = l_17 + l_15;
let l_19 = &buffer_0_global[l_18];
let l_20 = atomicLoad(l_19);
l_mut_2 = l_mut_2 + l_20;
}
let l_21 = l_1 + u32(3);
let l_22 = l_21 < u32(1560);
if l_22 {
let l_23 = workgroup_id.x * u32(1560);
let l_24 = l_23 + l_21;
let l_25 = &buffer_0_global[l_24];
let l_26 = atomicLoad(l_25);
l_mut_2 = l_mut_2 + l_26;
}
let l_27 = l_1 + u32(4);
let l_28 = l_27 < u32(1560);
if l_28 {
let l_29 = workgroup_id.x * u32(1560);
let l_30 = l_29 + l_27;
let l_31 = &buffer_0_global[l_30];
let l_32 = atomicLoad(l_31);
l_mut_2 = l_mut_2 + l_32;
}
let l_33 = l_1 + u32(5);
let l_34 = l_33 < u32(1560);
if l_34 {
let l_35 = workgroup_id.x * u32(1560);
let l_36 = l_35 + l_33;
let l_37 = &buffer_0_global[l_36];
let l_38 = atomicLoad(l_37);
l_mut_2 = l_mut_2 + l_38;
}
let l_39 = l_1 + u32(6);
let l_40 = l_39 < u32(1560);
if l_40 {
let l_41 = workgroup_id.x * u32(1560);
let l_42 = l_41 + l_39;
let l_43 = &buffer_0_global[l_42];
let l_44 = atomicLoad(l_43);
l_mut_2 = l_mut_2 + l_44;
}
shared_memory_0[local_invocation_id.x] = l_mut_2;
workgroupBarrier();
let l_45 = local_invocation_id.x == u32(0);
if l_45 {
l_mut_2 = u32(0);
l_mut_46 = u32(0);
loop {
let l_47 = l_mut_46 < WORKGROUP_SIZE_X;
let l_48 = !l_47;
if l_48 {
break;
}
let l_49 = shared_memory_0[l_mut_46];
shared_memory_0[l_mut_46] = l_mut_2;
l_mut_2 = l_mut_2 + l_49;
l_mut_46 = l_mut_46 + u32(1);
}
}
workgroupBarrier();
let l_50 = shared_memory_0[local_invocation_id.x];
let l_51 = workgroup_id.x * info.scalars_u32[0];
let l_52 = l_50 + l_51;
l_mut_46 = l_52;
let l_53 = l_1 + u32(0);
let l_54 = l_53 < u32(1560);
if l_54 {
let l_55 = workgroup_id.x * u32(1560);
let l_56 = l_55 + l_53;
let l_57 = &buffer_0_global[l_56];
let l_58 = atomicLoad(l_57);
let l_59 = workgroup_id.x * u32(1560);
let l_60 = l_59 + l_53;
let l_61 = &buffer_1_global[l_60];
atomicStore(l_61,l_mut_46);
let l_62 = workgroup_id.x * u32(1560);
let l_63 = l_62 + l_53;
let l_64 = u32(4) * l_63;
buffer_2_global[l_64] = workgroup_id.x;
let l_65 = u32(4) * l_63;
let l_66 = l_65 + u32(1);
buffer_2_global[l_66] = l_53;
let l_67 = u32(4) * l_63;
let l_68 = l_67 + u32(2);
buffer_2_global[l_68] = l_mut_46;
let l_69 = u32(4) * l_63;
let l_70 = l_69 + u32(3);
let l_71 = l_mut_46 + l_58;
buffer_2_global[l_70] = l_71;
l_mut_46 = l_mut_46 + l_58;
}
let l_72 = l_1 + u32(1);
let l_73 = l_72 < u32(1560);
if l_73 {
let l_74 = workgroup_id.x * u32(1560);
let l_75 = l_74 + l_72;
let l_76 = &buffer_0_global[l_75];
let l_77 = atomicLoad(l_76);
let l_78 = workgroup_id.x * u32(1560);
let l_79 = l_78 + l_72;
let l_80 = &buffer_1_global[l_79];
atomicStore(l_80,l_mut_46);
let l_81 = workgroup_id.x * u32(1560);
let l_82 = l_81 + l_72;
let l_83 = u32(4) * l_82;
buffer_2_global[l_83] = workgroup_id.x;
let l_84 = u32(4) * l_82;
let l_85 = l_84 + u32(1);
buffer_2_global[l_85] = l_72;
let l_86 = u32(4) * l_82;
let l_87 = l_86 + u32(2);
buffer_2_global[l_87] = l_mut_46;
let l_88 = u32(4) * l_82;
let l_89 = l_88 + u32(3);
let l_90 = l_mut_46 + l_77;
buffer_2_global[l_89] = l_90;
l_mut_46 = l_mut_46 + l_77;
}
let l_91 = l_1 + u32(2);
let l_92 = l_91 < u32(1560);
if l_92 {
let l_93 = workgroup_id.x * u32(1560);
let l_94 = l_93 + l_91;
let l_95 = &buffer_0_global[l_94];
let l_96 = atomicLoad(l_95);
let l_97 = workgroup_id.x * u32(1560);
let l_98 = l_97 + l_91;
let l_99 = &buffer_1_global[l_98];
atomicStore(l_99,l_mut_46);
let l_100 = workgroup_id.x * u32(1560);
let l_101 = l_100 + l_91;
let l_102 = u32(4) * l_101;
buffer_2_global[l_102] = workgroup_id.x;
let l_103 = u32(4) * l_101;
let l_104 = l_103 + u32(1);
buffer_2_global[l_104] = l_91;
let l_105 = u32(4) * l_101;
let l_106 = l_105 + u32(2);
buffer_2_global[l_106] = l_mut_46;
let l_107 = u32(4) * l_101;
let l_108 = l_107 + u32(3);
let l_109 = l_mut_46 + l_96;
buffer_2_global[l_108] = l_109;
l_mut_46 = l_mut_46 + l_96;
}
let l_110 = l_1 + u32(3);
let l_111 = l_110 < u32(1560);
if l_111 {
let l_112 = workgroup_id.x * u32(1560);
let l_113 = l_112 + l_110;
let l_114 = &buffer_0_global[l_113];
let l_115 = atomicLoad(l_114);
let l_116 = workgroup_id.x * u32(1560);
let l_117 = l_116 + l_110;
let l_118 = &buffer_1_global[l_117];
atomicStore(l_118,l_mut_46);
let l_119 = workgroup_id.x * u32(1560);
let l_120 = l_119 + l_110;
let l_121 = u32(4) * l_120;
buffer_2_global[l_121] = workgroup_id.x;
let l_122 = u32(4) * l_120;
let l_123 = l_122 + u32(1);
buffer_2_global[l_123] = l_110;
let l_124 = u32(4) * l_120;
let l_125 = l_124 + u32(2);
buffer_2_global[l_125] = l_mut_46;
let l_126 = u32(4) * l_120;
let l_127 = l_126 + u32(3);
let l_128 = l_mut_46 + l_115;
buffer_2_global[l_127] = l_128;
l_mut_46 = l_mut_46 + l_115;
}
let l_129 = l_1 + u32(4);
let l_130 = l_129 < u32(1560);
if l_130 {
let l_131 = workgroup_id.x * u32(1560);
let l_132 = l_131 + l_129;
let l_133 = &buffer_0_global[l_132];
let l_134 = atomicLoad(l_133);
let l_135 = workgroup_id.x * u32(1560);
let l_136 = l_135 + l_129;
let l_137 = &buffer_1_global[l_136];
atomicStore(l_137,l_mut_46);
let l_138 = workgroup_id.x * u32(1560);
let l_139 = l_138 + l_129;
let l_140 = u32(4) * l_139;
buffer_2_global[l_140] = workgroup_id.x;
let l_141 = u32(4) * l_139;
let l_142 = l_141 + u32(1);
buffer_2_global[l_142] = l_129;
let l_143 = u32(4) * l_139;
let l_144 = l_143 + u32(2);
buffer_2_global[l_144] = l_mut_46;
let l_145 = u32(4) * l_139;
let l_146 = l_145 + u32(3);
let l_147 = l_mut_46 + l_134;
buffer_2_global[l_146] = l_147;
l_mut_46 = l_mut_46 + l_134;
}
let l_148 = l_1 + u32(5);
let l_149 = l_148 < u32(1560);
if l_149 {
let l_150 = workgroup_id.x * u32(1560);
let l_151 = l_150 + l_148;
let l_152 = &buffer_0_global[l_151];
let l_153 = atomicLoad(l_152);
let l_154 = workgroup_id.x * u32(1560);
let l_155 = l_154 + l_148;
let l_156 = &buffer_1_global[l_155];
atomicStore(l_156,l_mut_46);
let l_157 = workgroup_id.x * u32(1560);
let l_158 = l_157 + l_148;
let l_159 = u32(4) * l_158;
buffer_2_global[l_159] = workgroup_id.x;
let l_160 = u32(4) * l_158;
let l_161 = l_160 + u32(1);
buffer_2_global[l_161] = l_148;
let l_162 = u32(4) * l_158;
let l_163 = l_162 + u32(2);
buffer_2_global[l_163] = l_mut_46;
let l_164 = u32(4) * l_158;
let l_165 = l_164 + u32(3);
let l_166 = l_mut_46 + l_153;
buffer_2_global[l_165] = l_166;
l_mut_46 = l_mut_46 + l_153;
}
let l_167 = l_1 + u32(6);
let l_168 = l_167 < u32(1560);
if l_168 {
let l_169 = workgroup_id.x * u32(1560);
let l_170 = l_169 + l_167;
let l_171 = &buffer_0_global[l_170];
let l_172 = atomicLoad(l_171);
let l_173 = workgroup_id.x * u32(1560);
let l_174 = l_173 + l_167;
let l_175 = &buffer_1_global[l_174];
atomicStore(l_175,l_mut_46);
let l_176 = workgroup_id.x * u32(1560);
let l_177 = l_176 + l_167;
let l_178 = u32(4) * l_177;
buffer_2_global[l_178] = workgroup_id.x;
let l_179 = u32(4) * l_177;
let l_180 = l_179 + u32(1);
buffer_2_global[l_180] = l_167;
let l_181 = u32(4) * l_177;
let l_182 = l_181 + u32(2);
buffer_2_global[l_182] = l_mut_46;
let l_183 = u32(4) * l_177;
let l_184 = l_183 + u32(3);
let l_185 = l_mut_46 + l_172;
buffer_2_global[l_184] = l_185;
l_mut_46 = l_mut_46 + l_172;
}
workgroupBarrier();
let l_186 = local_invocation_id.x == u32(0);
if l_186 {
let l_187 = &buffer_3_global[u32(1)];
let l_188 = atomicAdd(l_187, u32(1));}
}
```
