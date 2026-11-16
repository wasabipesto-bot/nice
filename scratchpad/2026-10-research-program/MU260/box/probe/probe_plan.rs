
// MU260 probe (box only, never committed): the b60 dense compare's CPU side for a given CUDA device total memory.
#[cfg(test)]
mod mu260_probe {
    use super::*;
    #[test]
    #[ignore = "MU260 probe"]
    fn mu260_b60_dense_by_device_memory() {
        let (b, dense, size): (u32, u128, u128) = {
            let v = std::env::var("MU_FIELD").unwrap_or("60:1447429612114824200908:10000000000000000".into());
            let x: Vec<&str> = v.split(':').collect();
            (x[0].parse().unwrap(), x[1].parse().unwrap(), x[2].parse().unwrap())
        };
        let range = FieldSize::new(dense, dense + size);
        for t in std::env::var("MU_TOTALS").unwrap().split(',') {
            let t: u64 = t.parse().unwrap();
            let lim = JoinLimits::for_buffer(t / 4).with_vram_budget();
            let field = plan_join(b, &range, lim).expect("a join field");
            let total = u32::try_from(field.fs.nparts).unwrap();
            let parts: Vec<u32> = (0..8).map(|i| i * total / 8).collect();
            let cpu = crate::cpu_join::CpuJoin::new(b, &field.slices[0], field.fs.jp).unwrap();
            let mut sc = crate::cpu_join::Scratch::default();
            let mut want = crate::cpu_join::PartitionResult::default();
            for &v in &parts {
                want.add(cpu.run_partition(v, &mut sc));
            }
            println!(
                "MU total {t} page {} budget {} slices {:?} nparts {total} parts {parts:?} survivors {} checked {}",
                t / 4, field.lim.budget, field.slices, want.survivors, want.checked
            );
        }
    }
}
