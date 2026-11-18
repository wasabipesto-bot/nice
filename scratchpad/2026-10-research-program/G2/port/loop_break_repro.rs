//! Repro: cubecl-spirv and `loop { … break … }`. usage: loop_break_repro VARIANT (1..6)
use cubecl::prelude::*;
use nice_common::cubecl_backend::CubeclContext;

/// 1: break at the top of the loop body
#[cube(launch_unchecked)]
fn k1(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    loop {
        if i >= n {
            break;
        }
        out[i as usize] = i;
        i += 1u32;
    }
}

/// 2: break at the end of the loop body (after other work)
#[cube(launch_unchecked)]
fn k2(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    loop {
        out[i as usize] = i;
        i += 1u32;
        if i >= n {
            break;
        }
    }
}

/// 3: two breaks, one in the middle and one at the end
#[cube(launch_unchecked)]
fn k3(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    loop {
        if i >= n {
            break;
        }
        out[i as usize] = i;
        i += 1u32;
        if i == 5u32 {
            break;
        }
    }
}

/// 4: a break inside an if/else
#[cube(launch_unchecked)]
fn k4(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    loop {
        if i >= n {
            break;
        } else {
            out[i as usize] = i;
        }
        i += 1u32;
    }
}

/// 5: a while loop nested in the loop, then a break
#[cube(launch_unchecked)]
fn k5(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    loop {
        let mut j = 0u32;
        while j < 2u32 {
            j += 1u32;
        }
        out[i as usize] = i + j;
        i += 1u32;
        if i >= n {
            break;
        }
    }
}

/// 6: the same as 2, rewritten without `loop`/`break` (the workaround)
#[cube(launch_unchecked)]
fn k6(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    let mut going = true;
    while going {
        out[i as usize] = i;
        i += 1u32;
        if i >= n {
            going = false;
        }
    }
}


/// 7: the port's shape: an inner while with `&&`, a break in the middle, a nested for, a break at the end
#[cube(launch_unchecked)]
fn k7(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    let mut cur = 0u32;
    loop {
        while i < 4u32 && cur < n {
            cur += 1u32;
            i += 1u32;
        }
        let m = min(4u32, n - min(n, cur - i));
        if m == 0u32 {
            break;
        }
        for k in 0..m {
            out[(cur - i + k) as usize] = cur - i + k;
        }
        let done = cur >= n;
        i = 0u32;
        if done {
            break;
        }
    }
}

/// 8: as 7, with barriers
#[cube(launch_unchecked)]
fn k8(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    let mut cur = 0u32;
    loop {
        while i < 4u32 && cur < n {
            cur += 1u32;
            i += 1u32;
            sync_cube();
        }
        sync_cube();
        let m = min(4u32, n - min(n, cur - i));
        if m == 0u32 {
            break;
        }
        for k in 0..m {
            out[(cur - i + k) as usize] = cur - i + k;
        }
        sync_cube();
        let done = cur >= n;
        i = 0u32;
        if done {
            break;
        }
    }
}

/// 9: two breaks, the second with `&&`
#[cube(launch_unchecked)]
fn k9(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    loop {
        if i >= n {
            break;
        }
        out[i as usize] = i;
        i += 1u32;
        if i > 2u32 && i == n {
            break;
        }
    }
}

/// 10: one break at the end, guarded by `&&`
#[cube(launch_unchecked)]
fn k10(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    loop {
        out[i as usize] = i;
        i += 1u32;
        if i > 2u32 && i >= n {
            break;
        }
    }
}

/// 11: as 7, plus a loop-carried counter used after the loop
#[cube(launch_unchecked)]
fn k11(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    let mut cur = 0u32;
    let mut rounds = 0u32;
    loop {
        while i < 4u32 && cur < n {
            cur += 1u32;
            i += 1u32;
        }
        let m = min(4u32, n - min(n, cur - i));
        if m == 0u32 {
            break;
        }
        rounds += 1u32;
        for k in 0..m {
            out[(cur - i + k) as usize] = cur - i + k;
        }
        let done = cur >= n;
        i = 0u32;
        if done {
            break;
        }
    }
    out[7usize] = rounds;
}

/// 12: a break right after an inner loop, and a value carried out of the outer loop
#[cube(launch_unchecked)]
fn k12(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    let mut rounds = 0u32;
    loop {
        while i < n {
            i += 1u32;
        }
        if rounds == 2u32 {
            break;
        }
        rounds += 1u32;
    }
    out[0usize] = rounds;
}

/// 13: as 12 without the inner loop
#[cube(launch_unchecked)]
fn k13(out: &mut Array<u32>, n: u32) {
    let mut rounds = 0u32;
    loop {
        if rounds == n {
            break;
        }
        rounds += 1u32;
    }
    out[0usize] = rounds;
}

/// 14-17: variant 11 with one piece removed (14: the for loop; 15: the `&&`; 16: the use after the loop; 17: the min)
#[cube(launch_unchecked)]
fn k14(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    let mut cur = 0u32;
    let mut rounds = 0u32;
    loop {
        while i < 4u32 && cur < n {
            cur += 1u32;
            i += 1u32;
        }
        let m = min(4u32, n - min(n, cur - i));
        if m == 0u32 {
            break;
        }
        rounds += 1u32;
        out[(cur - 1u32) as usize] = cur;
        let done = cur >= n;
        i = 0u32;
        if done {
            break;
        }
    }
    out[7usize] = rounds;
}

#[cube(launch_unchecked)]
fn k15(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    let mut cur = 0u32;
    let mut rounds = 0u32;
    loop {
        while i < 4u32 {
            cur += 1u32;
            i += 1u32;
        }
        let m = min(4u32, n - min(n, cur - i));
        if m == 0u32 {
            break;
        }
        rounds += 1u32;
        for k in 0..m {
            out[(cur - i + k) as usize] = cur - i + k;
        }
        let done = cur >= n;
        i = 0u32;
        if done {
            break;
        }
    }
    out[7usize] = rounds;
}

#[cube(launch_unchecked)]
fn k16(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    let mut cur = 0u32;
    loop {
        while i < 4u32 && cur < n {
            cur += 1u32;
            i += 1u32;
        }
        let m = min(4u32, n - min(n, cur - i));
        if m == 0u32 {
            break;
        }
        for k in 0..m {
            out[(cur - i + k) as usize] = cur - i + k;
        }
        let done = cur >= n;
        i = 0u32;
        if done {
            break;
        }
    }
}

#[cube(launch_unchecked)]
fn k17(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    let mut cur = 0u32;
    let mut rounds = 0u32;
    loop {
        while i < 4u32 && cur < n {
            cur += 1u32;
            i += 1u32;
        }
        if cur - i >= n {
            break;
        }
        rounds += 1u32;
        for k in 0..i {
            out[(cur - i + k) as usize] = cur - i + k;
        }
        let done = cur >= n;
        i = 0u32;
        if done {
            break;
        }
    }
    out[7usize] = rounds;
}


/// 18: two breaks and a value carried out of the loop, with an inner loop before the first break
#[cube(launch_unchecked)]
fn k18(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    let mut rounds = 0u32;
    loop {
        while i < n {
            i += 1u32;
        }
        if i > n {
            break;
        }
        rounds += 1u32;
        if rounds == 3u32 {
            break;
        }
    }
    out[0usize] = rounds;
}

/// 19: as 18 without the inner loop
#[cube(launch_unchecked)]
fn k19(out: &mut Array<u32>, n: u32) {
    let mut rounds = 0u32;
    loop {
        if rounds > n {
            break;
        }
        rounds += 1u32;
        if rounds == 3u32 {
            break;
        }
    }
    out[0usize] = rounds;
}

/// 20: as 18 with the second break only
#[cube(launch_unchecked)]
fn k20(out: &mut Array<u32>, n: u32) {
    let mut i = 0u32;
    let mut rounds = 0u32;
    loop {
        while i < n {
            i += 1u32;
        }
        rounds += 1u32;
        if rounds == 3u32 {
            break;
        }
    }
    out[0usize] = rounds;
}

/// 23: 19 rewritten without `loop`/`break` (a flag)
#[cube(launch_unchecked)]
fn k23(out: &mut Array<u32>, n: u32) {
    let mut rounds = 0u32;
    let mut going = true;
    while going {
        if rounds > n {
            going = false;
        } else {
            rounds += 1u32;
            if rounds == 3u32 {
                going = false;
            }
        }
    }
    out[0usize] = rounds;
}

/// 24: 19 with the two exits merged into one `break`
#[cube(launch_unchecked)]
fn k24(out: &mut Array<u32>, n: u32) {
    let mut rounds = 0u32;
    loop {
        if rounds > n || rounds == 3u32 {
            break;
        }
        rounds += 1u32;
    }
    out[0usize] = rounds;
}

/// 25: 19 with the carried value stored inside the loop instead of after it
#[cube(launch_unchecked)]
fn k25(out: &mut Array<u32>, n: u32) {
    let mut rounds = 0u32;
    loop {
        if rounds > n {
            break;
        }
        rounds += 1u32;
        out[0usize] = rounds;
        if rounds == 3u32 {
            break;
        }
    }
}

fn main() {
    env_logger::init();
    let v: u32 = std::env::args().nth(1).map_or(1, |s| s.parse().unwrap());
    let ctx = CubeclContext::new_default().expect("wgpu");
    #[allow(irrefutable_let_patterns)]
    let CubeclContext::Wgpu { client, .. } = ctx else { unreachable!() };
    let n = 8u32;
    let out = client.create(cubecl::bytes::Bytes::from_elems(vec![99u32; 8]));
    macro_rules! go {
        ($k:ident) => {
            unsafe {
                $k::launch_unchecked::<cubecl::wgpu::WgpuRuntime>(&client, CubeCount::Static(1, 1, 1), CubeDim::new_1d(1), ArrayArg::from_raw_parts(out.clone(), 8), n)
            }
        };
    }
    match v {
        1 => go!(k1),
        2 => go!(k2),
        3 => go!(k3),
        4 => go!(k4),
        5 => go!(k5),
        7 => go!(k7),
        8 => go!(k8),
        9 => go!(k9),
        10 => go!(k10),
        11 => go!(k11),
        12 => go!(k12),
        13 => go!(k13),
        14 => go!(k14),
        15 => go!(k15),
        16 => go!(k16),
        17 => go!(k17),
        18 => go!(k18),
        19 => go!(k19),
        20 => go!(k20),
        23 => go!(k23),
        24 => go!(k24),
        25 => go!(k25),
        _ => go!(k6),
    }
    let r = cubecl::future::block_on(client.sync());
    println!("variant {v}: sync {:?}", r.is_ok());
    let b = client.read_one(out).map(|b| u32::from_bytes(&b).to_vec());
    println!("variant {v}: out {:?}", b);
}
