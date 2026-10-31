
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
var a_31: array<u32, 1>;

var a_34: array<u32, 1>;

var a_42: array<u32, 1>;

var l_mut_48: bool;
var l_mut_30: u64;
var l_mut_17: u32;
var l_mut_32: u32;
var l_mut_33: u32;
var l_mut_35: u32;
var l_mut_36: u32;
var l_mut_74: u32;
var l_mut_75: u32;
var l_mut_78: u32;
var l_mut_79: u32;
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
let l_11 = workgroup_id.y * u32(10);
let l_12 = l_11 * info.scalars_u32[0];
let l_13 = u32(10) * l_7;
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
l_mut_33 = l_15;
a_31[u32(0)] = u32(0);
l_mut_35 = u32(0);
l_mut_36 = l_mut_35;
let l_37 = a_31[u32(0)];
let l_38 = a_31[u32(0)];
let l_39 = l_37 * l_38;
l_mut_36 = l_mut_36 + l_39;
let l_40 = l_mut_36 % u32(10);
a_34[u32(0)] = l_40;
let l_41 = l_mut_36 / u32(10);
l_mut_35 = l_41;
l_mut_35 = u32(0);
l_mut_36 = l_mut_35;
let l_43 = a_34[u32(0)];
let l_44 = a_31[u32(0)];
let l_45 = l_43 * l_44;
l_mut_36 = l_mut_36 + l_45;
let l_46 = l_mut_36 % u32(10);
a_42[u32(0)] = l_46;
let l_47 = l_mut_36 / u32(10);
l_mut_35 = l_47;
l_mut_48 = bool(true);
let l_49 = !l_mut_48;
if l_49 {
l_mut_30 = bitcast<u64>(i64(-1));
}
let l_50 = l_mut_30 | l_3;
let l_51 = workgroup_id.y * info.scalars_u32[0];
let l_52 = l_51 + l_mut_17;
let l_53 = u32(2) * l_52;
let l_54 = u32(bitcast<u64>(l_mut_30));
buffer_4_global[l_53] = l_54;
let l_55 = u32(2) * l_52;
let l_56 = l_55 + u32(1);
let l_57 = l_mut_30 >> u32(bitcast<u64>(u64(32)));
let l_58 = u32(bitcast<u64>(l_57));
buffer_4_global[l_56] = l_58;
let l_59 = a_34[u32(0)];
let l_60 = a_42[u32(0)];
let l_61 = a_31[u32(0)];
let l_62 = u32(2) * l_61;
let l_63 = l_62 % u32(10);
let l_64 = l_61 * l_61;
let l_65 = l_64 % u32(10);
let l_66 = u32(3) * l_65;
let l_67 = l_66 % u32(10);
let l_68 = l_60 << u32(8);
let l_69 = l_59 | l_68;
let l_70 = l_63 << u32(16);
let l_71 = l_69 | l_70;
let l_72 = l_67 << u32(24);
let l_73 = l_71 | l_72;
buffer_5_global[l_52] = l_73;
if l_mut_48 {
l_mut_36 = l_59;
l_mut_74 = l_60;
l_mut_75 = u32(0);
loop {
let l_76 = l_mut_75 < u32(10);
let l_77 = !l_76;
if l_77 {
break;
}
l_mut_78 = l_mut_36;
l_mut_79 = l_mut_74;
let l_80 = l_mut_75 * l_mut_75;
let l_81 = l_80 % u32(10);
l_mut_78 = l_81;
let l_82 = l_mut_78 * l_mut_75;
let l_83 = l_82 % u32(10);
l_mut_79 = l_83;
let l_84 = u64(l_mut_78);
let l_85 = u64(1) << u32(bitcast<u64>(l_84));
let l_86 = u64(l_mut_79);
let l_87 = u64(1) << u32(bitcast<u64>(l_86));
let l_88 = l_85 | l_87;
let l_89 = l_mut_78 != l_mut_79;
let l_90 = l_50 & l_88;
let l_91 = l_90 == u64(0);
let l_92 = l_89 && l_91;
if l_92 {
let l_93 = &shared_memory_4[l_mut_75];
let l_94 = atomicAdd(l_93, u32(1));let l_95 = l_mut_75 * l_10;
let l_96 = l_14 + l_95;
let l_97 = l_96 + l_94;
buffer_6_global[l_97] = l_mut_17;
}
l_mut_36 = l_mut_36 + l_63;
let l_98 = l_mut_36 >= u32(10);
if l_98 {
l_mut_36 = l_mut_36 - u32(10);
}
l_mut_74 = l_mut_74 + l_67;
let l_99 = l_mut_74 >= u32(10);
if l_99 {
l_mut_74 = l_mut_74 - u32(10);
}
l_mut_75 = l_mut_75 + u32(1);
}
}
l_mut_17 = l_mut_17 + WORKGROUP_SIZE_X;
}
workgroupBarrier();
let l_100 = local_invocation_id.x < u32(10);
if l_100 {
let l_101 = workgroup_id.y * u32(10);
let l_102 = l_101 + local_invocation_id.x;
let l_103 = l_102 * u32(9);
let l_104 = l_103 + workgroup_id.x;
let l_105 = &shared_memory_4[local_invocation_id.x];
let l_106 = atomicLoad(l_105);
buffer_7_global[l_104] = l_106;
}
workgroupBarrier();
let l_107 = local_invocation_id.x == u32(0);
if l_107 {
let l_108 = &buffer_8_global[u32(3)];
let l_109 = atomicAdd(l_108, u32(1));}
}
```
