// floor: exact fractional-cover lower bound for the view-certificate (PSJ) model, ignoring the
// cost of creating views.  For every admissible n (residue class mod b-1 passes), mu(n) = size of
// the largest view (prefix t digits) x (suffix k digits), t + k <= L, that contains n and whose
// revealed certificate C(prefix t) ∪ low k digits of n², n³ repeats a digit.  Any set of tested
// views that discards every non-nice admissible n costs >= sum_n 1/mu(n)  (mu = 1 if no view is bad).
// usage: floor <base> [start:len ...]
fn ceil_root(x: u128, k: u32) -> u128 {
    let mut lo: u128 = 0;
    let mut hi: u128 = 1;
    while hi.checked_pow(k).map_or(false, |v| v <= x) { hi *= 2; }
    while lo < hi {
        let m = (lo + hi) / 2;
        if m.checked_pow(k).map_or(false, |v| v < x) { lo = m + 1; } else { hi = m; }
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
fn digits(mut x: u128, b: u128) -> Vec<u32> {
    let mut v = Vec::new();
    while x > 0 { v.push((x % b) as u32); x /= b; }
    v
}
// certificate of an interval [lo, hi]: common top digits of lo^j and hi^j -> (mask, count, bad)
fn cert(lo: u128, hi: u128, b: u128) -> (u64, u32, bool) {
    let mut m: u64 = 0;
    let mut cnt = 0u32;
    let mut bad = false;
    for p in [2u32, 3] {
        let a = digits(lo.pow(p), b);
        let c = digits(hi.pow(p), b);
        if a.len() != c.len() { continue; }
        for i in (0..a.len()).rev() {
            if a[i] != c[i] { break; }
            if m >> a[i] & 1 == 1 { bad = true; }
            m |= 1u64 << a[i];
            cnt += 1;
        }
    }
    (m, cnt, bad)
}

fn run<const B: u32>(windows: &[(u128, u128)]) {
    let b = B as u128;
    let (rs, re) = base_range(B).unwrap();
    let ln = digits(rs, b).len();
    let l2 = digits(rs * rs, b).len();
    let l3 = digits(rs * rs * rs, b).len();
    let target = (B * (B - 1) / 2) % (B - 1);
    let roots: Vec<u32> = (0..B - 1).filter(|&x| ((x as u64).pow(2) + (x as u64).pow(3)) % (B as u64 - 1) == target as u64).collect();
    let mut sum_inv = 0f64; // sum over admissible n of 1/mu
    let mut n_adm = 0u64;
    let mut n_mu1 = 0u64; // admissible n with no bad view of size > 1 (must be identified)
    let mut hist_g = vec![0u64; 64]; // log_b(mu) rounded down
    let mut total = 0u64;
    let mut pairs = vec![vec![0u64; ln + 1]; ln + 1];
    let mut surv = vec![vec![0u64; ln + 1]; ln + 1];
    let mut cr_t = vec![0u64; ln + 1];
    for &(ws, wl) in windows {
        let ws = ws.max(rs);
        let we = (ws + wl).min(re);
        if ws >= we { continue; }
        // per-t prefix data
        let mut pm = vec![0u64; ln + 1];
        let mut pc = vec![0u32; ln + 1];
        let mut pb = vec![false; ln + 1];
        let mut pw = vec![0f64; ln + 1];
        let mut d2 = [0u32; 32];
        let mut d3 = [0u32; 32];
        let mut d1 = [0u32; 32];
        for (i, v) in digits(ws, b).iter().enumerate() { d1[i] = *v; }
        for (i, v) in digits(ws * ws, b).iter().enumerate() { d2[i] = *v; }
        for (i, v) in digits(ws * ws * ws, b).iter().enumerate() { d3[i] = *v; }
        let mut n = ws;
        let mut first = true;
        let blks: Vec<u128> = (0..ln).map(|t| b.pow((ln - t) as u32)).collect();
        let mut ctr: Vec<u128> = blks.iter().map(|bl| n % bl).collect();
        while n < we {
            // refresh prefix certs whose block starts here
            for t in 0..ln {
                let blk = blks[t];
                if first || ctr[t] == 0 {
                    let lo = (n / blk * blk).max(rs);
                    let hi = (n / blk * blk + blk - 1).min(re - 1);
                    let (m, c, bad) = if t == 0 { (0, 0, false) } else { cert(lo, hi, b) };
                    pm[t] = m; pc[t] = c; pb[t] = bad;
                    pw[t] = (hi - lo + 1) as f64;
                    if t >= 1 && (t == 1 || !pb[t - 1]) { cr_t[t] += 1; }
                }
            }
            first = false;
            total += 1;
            let r = (n % (b - 1)) as u32;
            if roots.contains(&r) {
                n_adm += 1;
                // suffix masks
                let mut best = 1f64;
                for t in 0..ln {
                    if pb[t] { best = best.max(pw[t] * roots.len() as f64 / (B - 1) as f64); continue; }
                    let mut sm = pm[t];
                    let mut cnt = pc[t];
                    let mut kbad = None;
                    for k in 1..=(ln - t) {
                        let a = d2[k - 1];
                        let c = d3[k - 1];
                        // digits must not overlap the certificate positions: low k < l2 - cert, fine for k <= L
                        let _ = (l2, l3);
                        for d in [a, c] {
                            cnt += 1;
                            if sm >> d & 1 == 1 { kbad = Some(k); }
                            sm |= 1u64 << d;
                        }
                        if kbad.is_some() { break; }
                    }
                    if let Some(k) = kbad {
                        // view size: prefix interval / b^k, restricted to admissible classes
                        let size = (pw[t] / (b as f64).powi(k as i32) * roots.len() as f64 / (B - 1) as f64).max(1.0);
                        best = best.max(size);
                    }
                }
                if best <= 1.0 { n_mu1 += 1; }
                // PSJ pair counts: prefix_t certified (t >= 1), residue_k certified, t + k >= L
                let mut kmax = 0usize; // largest k with low k digits of n², n³ distinct
                {
                    let mut m: u64 = 0;
                    for k in 1..ln {
                        let a = d2[k - 1]; let c = d3[k - 1];
                        if m >> a & 1 == 1 { break; }
                        m |= 1u64 << a;
                        if m >> c & 1 == 1 { break; }
                        m |= 1u64 << c;
                        kmax = k;
                    }
                }
                for t in 1..ln {
                    if pb[t] { break; }
                    let mut sm = pm[t]; let mut cnt = pc[t]; let mut dis = true;
                    for k in 1..=kmax {
                        for d in [d2[k - 1], d3[k - 1]] { cnt += 1; if sm >> d & 1 == 1 { dis = false; } sm |= 1u64 << d; }
                        let _ = cnt;
                        if k + t >= ln { pairs[t][k] += 1; if dis { surv[t][k] += 1; } }
                    }
                }
                sum_inv += 1.0 / best;
                let g = (best.ln() / (b as f64).ln()).floor() as usize;
                hist_g[g.min(63)] += 1;
            }
            // step
            let mut carry = 1u32;
            for i in 0..l3 { let v = d3[i] + 3 * d2[i] + 3 * d1[i] + carry; d3[i] = v % B; carry = v / B; }
            let mut carry = 1u32;
            for i in 0..l2 { let v = d2[i] + 2 * d1[i] + carry; d2[i] = v % B; carry = v / B; }
            let mut carry = 1u32;
            let mut i = 0;
            while carry > 0 { let v = d1[i] + carry; d1[i] = v % B; carry = v / B; i += 1; }
            n += 1;
            for t in 0..ln { ctr[t] += 1; if ctr[t] == blks[t] { ctr[t] = 0; } }
        }
    }
    // bottoms: good residues mod b^j (low j digits of R², R³ distinct), j = 0..L-2
    fn good_count(b: u128, j: usize, depth: usize, r: u128, bj: u128, out: &mut Vec<u64>) {
        out[j] += 1;
        if j == depth { return; }
        for d in 0..b {
            let r2 = r + d * bj;
            let m = bj * b;
            let x2 = r2 * r2 % m; let x3 = x2 * r2 % m;
            let mut mask: u64 = 0; let mut ok = true;
            let (mut a, mut c) = (x2, x3);
            for _ in 0..=j { for v in [a % b, c % b] { if mask >> v & 1 == 1 { ok = false; } mask |= 1u64 << v; } a /= b; c /= b; }
            if ok { good_count(b, j + 1, depth, r2, m, out); }
        }
    }
    let mut good = vec![0u64; ln];
    good_count(b, 0, ln - 2, 0, 1, &mut good);
    let cr_b: Vec<u64> = (0..ln).map(|k| if k == 0 { 0 } else { good[k - 1] * B as u64 }).collect();
    let mut best = (u64::MAX, 0, 0, 0u64);
    for t in 1..ln { for k in 1..ln { if t + k >= ln {
        let c = 50 * (cr_t[1..=t].iter().sum::<u64>() + cr_b[1..=k].iter().sum::<u64>()) + pairs[t][k] + 45 * surv[t][k];
        if c < best.0 { best = (c, t, k, pairs[t][k]); }
    }}}
    let mut ideal = (u64::MAX, 0, 0, 0u64);
    for t in 1..ln { for k in 1..ln { if t + k >= ln {
        let c = 50 * (cr_t[1..=t].iter().sum::<u64>() + cr_b[1..=k].iter().sum::<u64>()) + 45 * surv[t][k];
        if c < ideal.0 { ideal = (c, t, k, surv[t][k]); }
    }}}
    println!("{{\"base\":{B},\"ideal_ov\":[{},{},{},{}]}}", ideal.0, ideal.1, ideal.2, ideal.3);
    println!("{{\"base\":{B},\"psj_best\":[{},{},{},{}],\"crT\":{:?},\"crB\":{:?}}}", best.0, best.1, best.2, best.3, cr_t, cr_b);
    let hg: Vec<String> = hist_g.iter().take(ln + 2).map(|x| x.to_string()).collect();
    println!("{{\"base\":{B},\"L\":{ln},\"total\":{total},\"admissible\":{n_adm},\"floor\":{sum_inv},\"mu1\":{n_mu1},\"hist_logmu\":[{}]}}", hg.join(","));
}

macro_rules! dispatch {
    ($b:expr, $w:expr; $($n:literal),*) => { match $b { $($n => run::<$n>($w),)* _ => panic!("base") } };
}
fn main() {
    let a: Vec<String> = std::env::args().collect();
    let base: u32 = a[1].parse().unwrap();
    let (rs, re) = base_range(base).unwrap();
    let mut w: Vec<(u128, u128)> = vec![];
    for x in &a[2..] {
        let mut p = x.split(':');
        w.push((p.next().unwrap().parse().unwrap(), p.next().unwrap().parse().unwrap()));
    }
    if w.is_empty() { w.push((rs, re - rs)); }
    dispatch!(base, &w; 10,12,13,14,15,17,18,19,20,22,23,24,25,27,28,29,30,32,33,34,35,37,38,39,40);
}
