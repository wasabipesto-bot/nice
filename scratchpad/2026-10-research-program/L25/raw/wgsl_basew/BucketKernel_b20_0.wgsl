
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
var a_31: array<u32, 2>;

var a_35: array<u32, 2>;

var a_51: array<u32, 2>;

var l_mut_30: u64;
var l_mut_65: bool;
var l_mut_17: u32;
var l_mut_32: u32;
var l_mut_34: u32;
var l_mut_36: u32;
var l_mut_37: u32;
var l_mut_91: u32;
var l_mut_92: u32;
var l_mut_95: u32;
var l_mut_96: u32;
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
l_mut_34 = l_15;
a_31[u32(1)] = u32(0);
l_mut_36 = u32(0);
l_mut_37 = l_mut_36;
let l_38 = a_31[u32(0)];
let l_39 = a_31[u32(0)];
let l_40 = l_38 * l_39;
l_mut_37 = l_mut_37 + l_40;
let l_41 = l_mut_37 % u32(20);
a_35[u32(0)] = l_41;
let l_42 = l_mut_37 / u32(20);
l_mut_36 = l_42;
l_mut_37 = l_mut_36;
let l_43 = a_31[u32(0)];
let l_44 = a_31[u32(1)];
let l_45 = l_43 * l_44;
l_mut_37 = l_mut_37 + l_45;
let l_46 = a_31[u32(1)];
let l_47 = a_31[u32(0)];
let l_48 = l_46 * l_47;
l_mut_37 = l_mut_37 + l_48;
let l_49 = l_mut_37 % u32(20);
a_35[u32(1)] = l_49;
let l_50 = l_mut_37 / u32(20);
l_mut_36 = l_50;
l_mut_36 = u32(0);
l_mut_37 = l_mut_36;
let l_52 = a_35[u32(0)];
let l_53 = a_31[u32(0)];
let l_54 = l_52 * l_53;
l_mut_37 = l_mut_37 + l_54;
let l_55 = l_mut_37 % u32(20);
a_51[u32(0)] = l_55;
let l_56 = l_mut_37 / u32(20);
l_mut_36 = l_56;
l_mut_37 = l_mut_36;
let l_57 = a_35[u32(0)];
let l_58 = a_31[u32(1)];
let l_59 = l_57 * l_58;
l_mut_37 = l_mut_37 + l_59;
let l_60 = a_35[u32(1)];
let l_61 = a_31[u32(0)];
let l_62 = l_60 * l_61;
l_mut_37 = l_mut_37 + l_62;
let l_63 = l_mut_37 % u32(20);
a_51[u32(1)] = l_63;
let l_64 = l_mut_37 / u32(20);
l_mut_36 = l_64;
l_mut_65 = bool(true);
let l_66 = !l_mut_65;
if l_66 {
l_mut_30 = bitcast<u64>(i64(-1));
}
let l_67 = l_mut_30 | l_3;
let l_68 = workgroup_id.y * info.scalars_u32[0];
let l_69 = l_68 + l_mut_17;
let l_70 = u32(2) * l_69;
let l_71 = u32(bitcast<u64>(l_mut_30));
buffer_4_global[l_70] = l_71;
let l_72 = u32(2) * l_69;
let l_73 = l_72 + u32(1);
let l_74 = l_mut_30 >> u32(bitcast<u64>(u64(32)));
let l_75 = u32(bitcast<u64>(l_74));
buffer_4_global[l_73] = l_75;
let l_76 = a_35[u32(1)];
let l_77 = a_51[u32(1)];
let l_78 = a_31[u32(0)];
let l_79 = u32(2) * l_78;
let l_80 = l_79 % u32(20);
let l_81 = l_78 * l_78;
let l_82 = l_81 % u32(20);
let l_83 = u32(3) * l_82;
let l_84 = l_83 % u32(20);
let l_85 = l_77 << u32(8);
let l_86 = l_76 | l_85;
let l_87 = l_80 << u32(16);
let l_88 = l_86 | l_87;
let l_89 = l_84 << u32(24);
let l_90 = l_88 | l_89;
buffer_5_global[l_69] = l_90;
if l_mut_65 {
l_mut_37 = l_76;
l_mut_91 = l_77;
l_mut_92 = u32(0);
loop {
let l_93 = l_mut_92 < u32(20);
let l_94 = !l_93;
if l_94 {
break;
}
l_mut_95 = l_mut_37;
l_mut_96 = l_mut_91;
let l_97 = u64(l_mut_95);
let l_98 = u64(1) << u32(bitcast<u64>(l_97));
let l_99 = u64(l_mut_96);
let l_100 = u64(1) << u32(bitcast<u64>(l_99));
let l_101 = l_98 | l_100;
let l_102 = l_mut_95 != l_mut_96;
let l_103 = l_67 & l_101;
let l_104 = l_103 == u64(0);
let l_105 = l_102 && l_104;
if l_105 {
let l_106 = &shared_memory_4[l_mut_92];
let l_107 = atomicAdd(l_106, u32(1));let l_108 = l_mut_92 * l_10;
let l_109 = l_14 + l_108;
let l_110 = l_109 + l_107;
buffer_6_global[l_110] = l_mut_17;
}
l_mut_37 = l_mut_37 + l_80;
let l_111 = l_mut_37 >= u32(20);
if l_111 {
l_mut_37 = l_mut_37 - u32(20);
}
l_mut_91 = l_mut_91 + l_84;
let l_112 = l_mut_91 >= u32(20);
if l_112 {
l_mut_91 = l_mut_91 - u32(20);
}
l_mut_92 = l_mut_92 + u32(1);
}
}
l_mut_17 = l_mut_17 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_113 = local_invocation_id.x < u32(20);
if l_113 {
let l_114 = workgroup_id.y * u32(20);
let l_115 = l_114 + local_invocation_id.x;
let l_116 = l_115 * u32(19);
let l_117 = l_116 + workgroup_id.x;
let l_118 = &shared_memory_4[local_invocation_id.x];
let l_119 = atomicLoad(l_118);
buffer_7_global[l_117] = l_119;
}
workgroupBarrier();
let l_120 = local_invocation_id.x == u32(0);
if l_120 {
let l_121 = &buffer_8_global[u32(3)];
let l_122 = atomicAdd(l_121, u32(1));}
}
```
