
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
var<storage, read_write> buffer_8_global: array<atomic<u32>>;

struct info_st {
   scalars_u32: array<u32, 4>,
   static_meta: array<u32, 18>,
}

@group(0)
@binding(9)
var<storage, read> info: info_st;

var<workgroup> shared_memory_4: array<atomic<u32>, 64>;

const WORKGROUP_SIZE_X = 256u;
const WORKGROUP_SIZE_Y = 1u;
const WORKGROUP_SIZE_Z = 1u;

@compute
@workgroup_size(256, 1, 1)
fn bucket_kernel(
    @builtin(local_invocation_id) local_invocation_id: vec3<u32>,
    @builtin(workgroup_id) workgroup_id: vec3<u32>,
) {
var a_31: array<u32, 3>;

var a_37: array<u32, 3>;

var a_64: array<u32, 3>;

var l_mut_17: u32;
var l_mut_32: u32;
var l_mut_35: u32;
var l_mut_38: u32;
var l_mut_39: u32;
var l_mut_30: u64;
var l_mut_89: bool;
let l_0 = u64(info.scalars_u32[2]);
let l_1 = l_0 << u32(bitcast<u64>(u64(32)));
let l_2 = u64(info.scalars_u32[1]);
let l_3 = l_1 | l_2;
let l_5 = local_invocation_id.x < u32(64);
if l_5 {
let l_6 = &shared_memory_4[local_invocation_id.x];
atomicStore(l_6,u32(0));
}
workgroupBarrier();
let l_7 = buffer_2_global[workgroup_id.x];
let l_8 = workgroup_id.x + u32(1);
let l_9 = buffer_2_global[l_8];
let l_10 = l_9 - l_7;
let l_11 = workgroup_id.y * u32(20);
let l_12 = l_11 * info.scalars_u32[0];
let l_13 = u32(20) * l_7;
let l_14 = l_12 + l_13;
let l_15 = buffer_3_global[workgroup_id.y];
let l_16 = l_7 + local_invocation_id.x;
l_mut_17 = l_16;
loop {
let l_18 = l_mut_17 < l_9;
let l_19 = !l_18;
if l_19 {
break;
}
let l_20 = buffer_0_global[l_mut_17];
let l_21 = u32(2) * l_mut_17;
let l_22 = l_21 + u32(1);
let l_23 = buffer_1_global[l_22];
let l_24 = u64(l_23);
let l_25 = l_24 << u32(bitcast<u64>(u64(32)));
let l_26 = u32(2) * l_mut_17;
let l_27 = buffer_1_global[l_26];
let l_28 = u64(l_27);
let l_29 = l_25 | l_28;
l_mut_30 = l_29;
l_mut_32 = l_20;
let l_33 = l_mut_32 % u32(20);
a_31[u32(0)] = l_33;
l_mut_32 = l_mut_32 / u32(20);
let l_34 = l_mut_32 % u32(20);
a_31[u32(1)] = l_34;
l_mut_32 = l_mut_32 / u32(20);
l_mut_35 = l_15;
let l_36 = l_mut_35 % u32(20);
a_31[u32(2)] = l_36;
l_mut_35 = l_mut_35 / u32(20);
l_mut_38 = u32(0);
l_mut_39 = l_mut_38;
let l_40 = a_31[u32(0)];
let l_41 = a_31[u32(0)];
let l_42 = l_40 * l_41;
l_mut_39 = l_mut_39 + l_42;
let l_43 = l_mut_39 % u32(20);
a_37[u32(0)] = l_43;
let l_44 = l_mut_39 / u32(20);
l_mut_38 = l_44;
l_mut_39 = l_mut_38;
let l_45 = a_31[u32(0)];
let l_46 = a_31[u32(1)];
let l_47 = l_45 * l_46;
l_mut_39 = l_mut_39 + l_47;
let l_48 = a_31[u32(1)];
let l_49 = a_31[u32(0)];
let l_50 = l_48 * l_49;
l_mut_39 = l_mut_39 + l_50;
let l_51 = l_mut_39 % u32(20);
a_37[u32(1)] = l_51;
let l_52 = l_mut_39 / u32(20);
l_mut_38 = l_52;
l_mut_39 = l_mut_38;
let l_53 = a_31[u32(0)];
let l_54 = a_31[u32(2)];
let l_55 = l_53 * l_54;
l_mut_39 = l_mut_39 + l_55;
let l_56 = a_31[u32(1)];
let l_57 = a_31[u32(1)];
let l_58 = l_56 * l_57;
l_mut_39 = l_mut_39 + l_58;
let l_59 = a_31[u32(2)];
let l_60 = a_31[u32(0)];
let l_61 = l_59 * l_60;
l_mut_39 = l_mut_39 + l_61;
let l_62 = l_mut_39 % u32(20);
a_37[u32(2)] = l_62;
let l_63 = l_mut_39 / u32(20);
l_mut_38 = l_63;
l_mut_38 = u32(0);
l_mut_39 = l_mut_38;
let l_65 = a_37[u32(0)];
let l_66 = a_31[u32(0)];
let l_67 = l_65 * l_66;
l_mut_39 = l_mut_39 + l_67;
let l_68 = l_mut_39 % u32(20);
a_64[u32(0)] = l_68;
let l_69 = l_mut_39 / u32(20);
l_mut_38 = l_69;
l_mut_39 = l_mut_38;
let l_70 = a_37[u32(0)];
let l_71 = a_31[u32(1)];
let l_72 = l_70 * l_71;
l_mut_39 = l_mut_39 + l_72;
let l_73 = a_37[u32(1)];
let l_74 = a_31[u32(0)];
let l_75 = l_73 * l_74;
l_mut_39 = l_mut_39 + l_75;
let l_76 = l_mut_39 % u32(20);
a_64[u32(1)] = l_76;
let l_77 = l_mut_39 / u32(20);
l_mut_38 = l_77;
l_mut_39 = l_mut_38;
let l_78 = a_37[u32(0)];
let l_79 = a_31[u32(2)];
let l_80 = l_78 * l_79;
l_mut_39 = l_mut_39 + l_80;
let l_81 = a_37[u32(1)];
let l_82 = a_31[u32(1)];
let l_83 = l_81 * l_82;
l_mut_39 = l_mut_39 + l_83;
let l_84 = a_37[u32(2)];
let l_85 = a_31[u32(0)];
let l_86 = l_84 * l_85;
l_mut_39 = l_mut_39 + l_86;
let l_87 = l_mut_39 % u32(20);
a_64[u32(2)] = l_87;
let l_88 = l_mut_39 / u32(20);
l_mut_38 = l_88;
l_mut_89 = bool(true);
let l_90 = a_37[u32(2)];
let l_91 = a_64[u32(2)];
let l_92 = u64(l_90);
let l_93 = u64(1) << u32(bitcast<u64>(l_92));
let l_94 = u64(l_91);
let l_95 = u64(1) << u32(bitcast<u64>(l_94));
let l_96 = l_93 | l_95;
let l_97 = l_90 == l_91;
let l_98 = l_mut_30 | l_3;
let l_99 = l_98 & l_96;
let l_100 = l_99 != u64(0);
let l_101 = l_97 || l_100;
if l_101 {
l_mut_89 = bool(false);
}
l_mut_30 = l_mut_30 | l_96;
let l_102 = !l_mut_89;
if l_102 {
l_mut_30 = bitcast<u64>(i64(-1));
}
let l_103 = l_mut_30 | l_3;
let l_104 = workgroup_id.y * info.scalars_u32[0];
let l_105 = l_104 + l_mut_17;
let l_106 = u32(2) * l_105;
let l_107 = u32(bitcast<u64>(l_mut_30));
buffer_4_global[l_106] = l_107;
let l_108 = u32(2) * l_105;
let l_109 = l_108 + u32(1);
let l_110 = l_mut_30 >> u32(bitcast<u64>(u64(32)));
let l_111 = u32(bitcast<u64>(l_110));
buffer_4_global[l_109] = l_111;
if l_mut_89 {
let l_112 = &shared_memory_4[u32(0)];
let l_113 = atomicAdd(l_112, u32(1));let l_114 = l_14 + l_113;
buffer_6_global[l_114] = l_mut_17;
}
l_mut_17 = l_mut_17 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_115 = local_invocation_id.x < u32(1);
if l_115 {
let l_116 = workgroup_id.y * u32(1);
let l_117 = l_116 + local_invocation_id.x;
let l_118 = l_117 * u32(19);
let l_119 = l_118 + workgroup_id.x;
let l_120 = &shared_memory_4[local_invocation_id.x];
let l_121 = atomicLoad(l_120);
buffer_7_global[l_119] = l_121;
}
workgroupBarrier();
let l_122 = local_invocation_id.x == u32(0);
if l_122 {
let l_123 = &buffer_8_global[u32(3)];
let l_124 = atomicAdd(l_123, u32(1));}
}
```
