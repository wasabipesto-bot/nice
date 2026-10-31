
```wgsl
@group(0)
@binding(0)
var<storage, read_write> buffer_0_global: array<u32>;

@group(0)
@binding(1)
var<storage, read_write> buffer_1_global: array<u32>;

struct info_st {
   scalars_u32: array<u32, 2>,
   static_meta: array<u32, 4>,
}

@group(0)
@binding(2)
var<storage, read> info: info_st;

const WORKGROUP_SIZE_X = 64u;
const WORKGROUP_SIZE_Y = 1u;
const WORKGROUP_SIZE_Z = 1u;

@compute
@workgroup_size(64, 1, 1)
fn hi_div_repro_kernel(
    @builtin(global_invocation_id) global_id: vec3<u32>,
) {
let l_0 = global_id.x < info.scalars_u32[0];
if l_0 {
let l_1 = u32(2) * global_id.x;
let l_2 = buffer_0_global[l_1];
let l_3 = u32(2) * global_id.x;
let l_4 = l_3 + u32(1);
let l_5 = buffer_0_global[l_4];
let l_6 = u64(l_2);
let l_7 = u64(l_5);
let l_8 = l_6 * l_7;
let l_9 = l_8 >> u32(bitcast<u64>(u64(32)));
let l_10 = u32(bitcast<u64>(l_9));
let l_11 = l_10 >> u32(16);
let l_12 = l_11 / u32(2500);
buffer_1_global[global_id.x] = l_12;
}
}
```
