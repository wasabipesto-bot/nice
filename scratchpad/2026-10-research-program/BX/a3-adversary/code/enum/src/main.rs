// a3enum: exhaustive / windowed enumeration of a base's range with per-n niceness,
// end-digit ("E") vs middle analysis, a stride sample and a near-nice list.
//
// usage: a3enum <base> <out_dir> <pos_slack> [start:len ...]
//   pos_slack: write every n with niceness >= base - pos_slack to <out>/b<base>_pos.bin
//   windows default to the whole range.
// Record (32 bytes): n u64, nice u8, e u8, eclean u8, ndA u8, ndC u8, lenA u8, lenC u8, ecoll u8,
//                    maskA u64, maskC u64
use std::fs::File;
use std::io::{BufWriter, Write};

fn ceil_root(x: u128, k: u32) -> u128 {
    let mut lo: u128 = 0;
    let mut hi: u128 = 1;
    while hi.checked_pow(k).map_or(false, |v| v <= x) {
        hi *= 2;
    }
    while lo < hi {
        let m = (lo + hi) / 2;
        if m.checked_pow(k).map_or(false, |v| v < x) {
            lo = m + 1;
        } else {
            hi = m;
        }
    }
    lo
}

fn base_range(b: u32) -> Option<(u128, u128)> {
    let bb = b as u128;
    let k = b / 5;
    match b % 5 {
        0 => Some((ceil_root(bb.pow(3 * k - 1), 3), bb.pow(k))),
        2 => Some((bb.pow(k), ceil_root(bb.pow(3 * k + 1), 3))),
        3 => Some((ceil_root(bb.pow(3 * k + 1), 3), ceil_root(bb.pow(2 * k + 1), 2))),
        4 => Some((ceil_root(bb.pow(2 * k + 1), 2), ceil_root(bb.pow(3 * k + 2), 3))),
        _ => None,
    }
}

fn range_of(b: u32) -> (u128, u128) {
    if let Ok(v) = std::env::var("A3_RANGE") { let mut p = v.split(':'); return (p.next().unwrap().parse().unwrap(), p.next().unwrap().parse().unwrap()); }
    base_range(b).unwrap()
}
fn digits(mut x: u128, b: u128) -> Vec<u32> {
    let mut v = Vec::new();
    while x > 0 {
        v.push((x % b) as u32);
        x /= b;
    }
    v
}

fn common_top(a: &[u32], c: &[u32]) -> usize {
    if a.len() != c.len() {
        return 0;
    }
    let mut k = 0;
    for i in (0..a.len()).rev() {
        if a[i] == c[i] {
            k += 1
        } else {
            break;
        }
    }
    k
}


// digits of x^p in base b without overflow (schoolbook on base-b digit vectors)
fn pdig(x: u128, p: u32, b: u128) -> Vec<u32> {
    let xd = digits(x, b);
    let mut acc: Vec<u32> = vec![1];
    for _ in 0..p {
        let mut out = vec![0u64; acc.len() + xd.len() + 1];
        for (i, &a) in acc.iter().enumerate() {
            for (j, &c) in xd.iter().enumerate() {
                out[i + j] += a as u64 * c as u64;
            }
            // normalise occasionally to avoid overflow
            let mut carry = 0u64;
            for v in out.iter_mut() { let t = *v + carry; *v = t % b as u64; carry = t / b as u64; }
        }
        while out.len() > 1 && *out.last().unwrap() == 0 { out.pop(); }
        acc = out.iter().map(|&v| v as u32).collect();
    }
    while acc.len() > 1 && *acc.last().unwrap() == 0 { acc.pop(); }
    acc
}

const MAXD: usize = 48;

fn splitmix(x: u64) -> u64 {
    let mut z = x.wrapping_add(0x9E3779B97F4A7C15);
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

struct Stats {
    hist_nice: Vec<u64>,          // [nice]
    hist_e_mid: Vec<Vec<u64>>,    // eclean n: [e][nice]
    hist_ecoll_nice: Vec<Vec<u64>>, // all n: [ecoll][nice]
    // core analysis: E2 = E + 2 buffer positions at each view edge; core = rest
    hist_e2: Vec<Vec<u64>>,       // E2-clean n: [e2][nice]
    pair: Vec<Vec<u64>>,          // E2-clean: [jp_i][jp_j] equal-digit counts over core pairs
    pair_n: Vec<Vec<u64>>,        // E2-clean: number of n where both i, j are core
    core_inE: Vec<u64>, core_n: Vec<u64>,
    hist_e_all: Vec<Vec<u64>>,    // all n: [e][ecoll]
    hist_e3: Vec<u64>,            // fixed-core test: n with all non-core digits distinct: [nice]
    pos_mid: [[u64; 64]; 2],      // eclean: position is middle
    pos_inE: [[u64; 64]; 2],      // eclean: middle digit lies in E set
    pos_coll: [[u64; 64]; 2],     // eclean: middle digit repeated anywhere in output
    pos_digit: Vec<Vec<Vec<u64>>>, // eclean: [which][pos][digit]
    // square/cube dependence over all n: [ndA][ndC][overlap]
    sc: Vec<Vec<Vec<u64>>>,
    // same, restricted to n with A and C internally distinct
    total: u64,
    resid_pass: u64,
    nice_list: Vec<u128>,
}

fn run<const B: u32>(windows: &[(u128, u128)], out: &str, slack: u32) {
    let b = B as u128;
    let (rs, re) = range_of(B);
    let ln = digits(rs, b).len();
    let l2 = pdig(rs, 2, b).len();
    let l3 = pdig(rs, 3, b).len();
    let le = re - 1;
    assert_eq!(pdig(le, 2, b).len(), l2);
    assert_eq!(pdig(le, 3, b).len(), l3);
    assert_eq!(l2 + l3, B as usize);
    let t = (ln + 1) / 2;
    let k = ln - t;
    let bk = b.pow(k as u32);
    let mut fixed_core = vec![false; l2 + l3];
    for i in (k + 2)..(l2 - t - 2) { fixed_core[i] = true; }
    for j in (k + 2)..(l3 - t - 2) { fixed_core[l2 + j] = true; }
    let e3pos: Vec<usize> = (0..(l2 + l3)).filter(|&i| !fixed_core[i]).collect();
    let n_core = l2 + l3 - e3pos.len();
    let target = (B * (B - 1) / 2) % (B - 1);
    let mut st = Stats {
        hist_nice: vec![0; 65],
        hist_e_mid: vec![vec![0; 65]; 65],
        hist_ecoll_nice: vec![vec![0; 65]; 65],
        hist_e2: vec![vec![0; 65]; 65],
        pair: vec![vec![0; 64]; 64],
        pair_n: vec![vec![0; 64]; 64],
        core_inE: vec![0; 64], core_n: vec![0; 64],
        hist_e_all: vec![vec![0; 65]; 65],
        hist_e3: vec![0; 65],
        pos_mid: [[0; 64]; 2],
        pos_inE: [[0; 64]; 2],
        pos_coll: [[0; 64]; 2],
        pos_digit: vec![vec![vec![0; 64]; 64]; 2],
        sc: vec![vec![vec![0; 65]; 65]; 65],
        total: 0,
        resid_pass: 0,
        nice_list: vec![],
    };
    let ntot: u128 = windows.iter().map(|w| w.1).sum();
    // hash-based pseudo-random sample of about 2e6 n (no residue aliasing)
    let stride: u64 = (ntot / 2_000_000).max(1) as u64;
    let thr: u64 = if stride <= 1 { u64::MAX } else { u64::MAX / stride };
    let mut fs = BufWriter::new(File::create(format!("{out}/b{B}_sample.bin")).unwrap());
    let mut fp = BufWriter::new(File::create(format!("{out}/b{B}_pos.bin")).unwrap());
    let thresh = B - slack;

    for &(ws, wl) in windows {
        let ws = ws.max(rs);
        let we = (ws + wl).min(re);
        if ws >= we {
            continue;
        }
        let mut d1 = [0u32; MAXD];
        let mut d2 = [0u32; MAXD];
        let mut d3 = [0u32; MAXD];
        for (i, v) in digits(ws, b).iter().enumerate() {
            d1[i] = *v;
        }
        for (i, v) in pdig(ws, 2, b).iter().enumerate() {
            d2[i] = *v;
        }
        for (i, v) in pdig(ws, 3, b).iter().enumerate() {
            d3[i] = *v;
        }
        let mut c2 = 0usize;
        let mut c3 = 0usize;
        let mut core: Vec<usize> = vec![]; // joint positions (n² 0..l2, n³ l2..)
        let mut e2pos: Vec<usize> = vec![];
        let mut n = ws;
        let mut since_block: u128 = n % bk; // position within block
        let mut first = true;
        let mut nm1 = (n % (b - 1)) as u32;
        while n < we {
            if first || since_block == 0 {
                first = false;
                let p = n / bk;
                let lo = (p * bk).max(rs);
                let hi = (p * bk + bk - 1).min(re - 1);
                c2 = common_top(&pdig(lo, 2, b), &pdig(hi, 2, b));
                c3 = common_top(&pdig(lo, 3, b), &pdig(hi, 3, b));
                // cap so certificates never meet the low-k windows
                c2 = c2.min(l2 - k);
                c3 = c3.min(l3 - k);
                let mut isE2 = [false; 64];
                for i in 0..k { isE2[i] = true; isE2[l2 + i] = true; }
                for i in (l2 - c2)..l2 { isE2[i] = true; }
                for i in (l3 - c3)..l3 { isE2[l2 + i] = true; }
                for (off, ln_, c) in [(0usize, l2, c2), (l2, l3, c3)] {
                    for dd in 0..2 {
                        if k + dd < ln_ { isE2[off + k + dd] = true; }
                        if ln_ >= c + 1 + dd { isE2[off + ln_ - c - 1 - dd] = true; }
                    }
                }
                core = (0..(l2 + l3)).filter(|&i| !isE2[i]).collect();
                e2pos = (0..(l2 + l3)).filter(|&i| isE2[i]).collect();
            }
            // masks
            let mut ma: u64 = 0;
            for i in 0..l2 {
                ma |= 1u64 << d2[i];
            }
            let mut mc: u64 = 0;
            for i in 0..l3 {
                mc |= 1u64 << d3[i];
            }
            let nice = (ma | mc).count_ones();
            st.hist_nice[nice as usize] += 1;
            st.total += 1;
            let nda = ma.count_ones() as usize;
            let ndc = mc.count_ones() as usize;
            st.sc[nda][ndc][(ma & mc).count_ones() as usize] += 1;
            if (nm1 * nm1 % (B - 1) * nm1 % (B - 1) + nm1 * nm1 % (B - 1)) % (B - 1) == target {
                st.resid_pass += 1;
            }
            // E set: low k of both, top c2 of n^2, top c3 of n^3
            let mut em: u64 = 0;
            let mut e = 0u32;
            for i in 0..k {
                em |= 1u64 << d2[i];
                em |= 1u64 << d3[i];
            }
            e += 2 * k as u32;
            for i in (l2 - c2)..l2 {
                em |= 1u64 << d2[i];
            }
            for i in (l3 - c3)..l3 {
                em |= 1u64 << d3[i];
            }
            e += (c2 + c3) as u32;
            let ecoll = e - em.count_ones();
            st.hist_ecoll_nice[ecoll as usize][nice as usize] += 1;
            st.hist_e_all[e as usize][ecoll as usize] += 1;
            {
                let mut m3: u64 = 0;
                for &p in &e3pos {
                    let d = if p < l2 { d2[p] } else { d3[p - l2] };
                    m3 |= 1u64 << d;
                }
                if m3.count_ones() as usize == e3pos.len() {
                    st.hist_e3[nice as usize] += 1;
                }
            }
            let eclean = ecoll == 0;
            if eclean {
                let mut jd = [0u32; 64];
                jd[..l2].copy_from_slice(&d2[..l2]);
                jd[l2..l2 + l3].copy_from_slice(&d3[..l3]);
                let mut m2: u64 = 0;
                for &p in &e2pos { m2 |= 1u64 << jd[p]; }
                if m2.count_ones() as usize == e2pos.len() {
                    st.hist_e2[e2pos.len()][nice as usize] += 1;
                    for (ii, &pi) in core.iter().enumerate() {
                        st.core_n[pi] += 1;
                        if m2 >> jd[pi] & 1 == 1 { st.core_inE[pi] += 1; }
                        for &pj in &core[ii + 1..] {
                            st.pair_n[pi][pj] += 1;
                            if jd[pi] == jd[pj] { st.pair[pi][pj] += 1; }
                        }
                    }
                }
            }
            if eclean {
                st.hist_e_mid[e as usize][nice as usize] += 1;
                let mut cnt = [0u8; 64];
                for i in 0..l2 {
                    cnt[d2[i] as usize] += 1;
                }
                for i in 0..l3 {
                    cnt[d3[i] as usize] += 1;
                }
                for i in k..(l2 - c2) {
                    let d = d2[i] as usize;
                    st.pos_mid[0][i] += 1;
                    if em >> d & 1 == 1 {
                        st.pos_inE[0][i] += 1;
                    }
                    if cnt[d] > 1 {
                        st.pos_coll[0][i] += 1;
                    }
                    st.pos_digit[0][i][d] += 1;
                }
                for i in k..(l3 - c3) {
                    let d = d3[i] as usize;
                    st.pos_mid[1][i] += 1;
                    if em >> d & 1 == 1 {
                        st.pos_inE[1][i] += 1;
                    }
                    if cnt[d] > 1 {
                        st.pos_coll[1][i] += 1;
                    }
                    st.pos_digit[1][i][d] += 1;
                }
            }
            let rec = |w: &mut BufWriter<File>| {
                w.write_all(&(n as u64).to_le_bytes()).unwrap();
                w.write_all(&[
                    nice as u8,
                    e as u8,
                    eclean as u8,
                    nda as u8,
                    ndc as u8,
                    l2 as u8,
                    l3 as u8,
                    ecoll as u8,
                ])
                .unwrap();
                w.write_all(&ma.to_le_bytes()).unwrap();
                w.write_all(&mc.to_le_bytes()).unwrap();
            };
            if stride <= 1 || splitmix(n as u64) < thr {
                rec(&mut fs);
            }
            if nice >= thresh {
                rec(&mut fp);
                if nice == B {
                    st.nice_list.push(n);
                }
            }
            // step: n3 += 3n2 + 3n + 1 ; n2 += 2n + 1 ; n += 1  (old values on rhs)
            let mut carry = 1u32;
            for i in 0..l3 {
                let v = d3[i] + 3 * d2[i] + 3 * d1[i] + carry;
                d3[i] = v % B;
                carry = v / B;
            }
            let mut carry = 1u32;
            for i in 0..l2 {
                let v = d2[i] + 2 * d1[i] + carry;
                d2[i] = v % B;
                carry = v / B;
            }
            let mut carry = 1u32;
            let mut i = 0;
            while carry > 0 {
                let v = d1[i] + carry;
                d1[i] = v % B;
                carry = v / B;
                i += 1;
            }
            n += 1;
            since_block += 1;
            if since_block == bk {
                since_block = 0;
            }
            nm1 += 1;
            if nm1 == B - 1 {
                nm1 = 0;
            }
        }
    }
    fs.flush().unwrap();
    fp.flush().unwrap();
    // stats as a simple JSON
    let mut s = String::new();
    s += &format!(
        "{{\"base\":{B},\"L\":{ln},\"l2\":{l2},\"l3\":{l3},\"t\":{t},\"k\":{k},\"range\":[{rs},{re}],\"total\":{},\"resid_pass\":{},\"stride\":{stride},\"slack\":{slack},\n",
        st.total, st.resid_pass
    );
    let v1 = |v: &Vec<u64>| format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(","));
    let v2 = |v: &Vec<Vec<u64>>| format!("[{}]", v.iter().map(|x| v1(x)).collect::<Vec<_>>().join(","));
    s += &format!("\"hist_nice\":{},\n", v1(&st.hist_nice));
    s += &format!("\"hist_e_mid\":{},\n", v2(&st.hist_e_mid));
    s += &format!("\"hist_ecoll_nice\":{},\n", v2(&st.hist_ecoll_nice));
    s += &format!("\"hist_e2\":{},\n\"pair\":{},\n\"pair_n\":{},\n\"core_inE\":{},\n\"core_n\":{},\n",
        v2(&st.hist_e2), v2(&st.pair), v2(&st.pair_n), v1(&st.core_inE), v1(&st.core_n));
    s += &format!("\"hist_e_all\":{},\n", v2(&st.hist_e_all));
    s += &format!("\"hist_e3\":{},\n\"n_core\":{},\n", v1(&st.hist_e3), n_core);
    for (name, arr) in [("pos_mid", &st.pos_mid), ("pos_inE", &st.pos_inE), ("pos_coll", &st.pos_coll)] {
        let a: Vec<Vec<u64>> = arr.iter().map(|r| r.to_vec()).collect();
        s += &format!("\"{name}\":{},\n", v2(&a));
    }
    s += &format!(
        "\"pos_digit\":[{}],\n",
        st.pos_digit.iter().map(|x| v2(x)).collect::<Vec<_>>().join(",")
    );
    s += &format!(
        "\"sc\":[{}],\n",
        st.sc.iter().map(|x| v2(x)).collect::<Vec<_>>().join(",")
    );
    s += &format!(
        "\"nice_list\":[{}]}}\n",
        st.nice_list.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(",")
    );
    std::fs::write(format!("{out}/b{B}_stats.json"), s).unwrap();
}

macro_rules! dispatch {
    ($b:expr, $w:expr, $o:expr, $s:expr; $($n:literal),*) => {
        match $b { $($n => run::<$n>($w, $o, $s),)* _ => panic!("base not compiled") }
    };
}

fn main() {
    let a: Vec<String> = std::env::args().collect();
    let base: u32 = a[1].parse().unwrap();
    let out = &a[2];
    let slack: u32 = a[3].parse().unwrap();
    let (rs, re) = range_of(base);
    let mut w: Vec<(u128, u128)> = vec![];
    for x in &a[4..] {
        let mut p = x.split(':');
        let s: u128 = p.next().unwrap().parse().unwrap();
        let l: u128 = p.next().unwrap().parse().unwrap();
        w.push((s, l));
    }
    if w.is_empty() {
        w.push((rs, re - rs));
    }
    dispatch!(base, &w, out, slack; 10,12,13,14,15,17,18,19,20,22,23,24,25,27,28,29,30,32,33,34,35,37,38,39,40,42,44,45,47,50,52,55,57,60,62);
}
