#!/usr/bin/env python3
"""patch51b.py: L51's split of the profile's `upload` (JoinDevice::new per slice) into host preparation (sorted_layer
apart), the buffer creation + allocation (synchronised), and warm_top (synchronised). Profile-only; no kernel change."""
import sys
p = sys.argv[1]
s = open(p).read()
def rep(old, new, count=1):
    global s
    assert s.count(old) == count, (s.count(old), old[:100])
    s = s.replace(old, new)
rep('''    fn new_inner(client: &ComputeClient<R>, fs: &FieldSetup, plan: &JoinPlan) -> Result<Self> {
        let limbs''', '''    fn new_inner(client: &ComputeClient<R>, fs: &FieldSetup, plan: &JoinPlan) -> Result<Self> {
        let t_in = Instant::now();
        let limbs''')
rep('''        let (tl, goff) = sorted_layer(fs, nkeys)?;
''', '''        let t_sort = Instant::now();
        let (tl, goff) = sorted_layer(fs, nkeys)?;
        let sort_secs = t_sort.elapsed().as_secs_f64();
''')
rep('''        let pdiv = fs.nparts;
        let dev = Self {''', '''        let pdiv = fs.nparts;
        let host_secs = t_in.elapsed().as_secs_f64();
        let t_dev = Instant::now();
        let dev = Self {''')
rep('''            prof: std::cell::Cell::new(JoinProfile::default()),
        };
        // The FD top stage takes''', '''            prof: std::cell::Cell::new(JoinProfile::default()),
        };
        if dev.profile {
            profile_sync(client)?;
            let dev_secs = t_dev.elapsed().as_secs_f64();
            dev.prof_add(|p| {
                p.up_host_secs += host_secs;
                p.up_sort_secs += sort_secs;
                p.up_dev_secs += dev_secs;
            });
        }
        let t_warm = Instant::now();
        // The FD top stage takes''')
rep('''            dev.warm_top(v);
        }
        Ok(dev)
    }''', '''            dev.warm_top(v);
        }
        if dev.profile {
            profile_sync(client)?;
            let w = t_warm.elapsed().as_secs_f64();
            dev.prof_add(|p| p.up_warm_secs += w);
        }
        Ok(dev)
    }''')
rep('''    /// One empty mark per batch (the floor of a mark).
    pub null_secs: f64,''', '''    /// One empty mark per batch (the floor of a mark).
    pub null_secs: f64,
    /// L51: `upload_secs` split: host preparation (of which `sorted_layer`),
    /// the buffers' creation and allocation, `warm_top`.
    pub up_host_secs: f64,
    pub up_sort_secs: f64,
    pub up_dev_secs: f64,
    pub up_warm_secs: f64,''')
rep('''        self.null_secs += o.null_secs;''', '''        self.null_secs += o.null_secs;
        self.up_host_secs += o.up_host_secs;
        self.up_sort_secs += o.up_sort_secs;
        self.up_dev_secs += o.up_dev_secs;
        self.up_warm_secs += o.up_warm_secs;''')
rep('''top_fd={:.4} top_clip={:.4} clip_launches={} null={:.4} \\
         | ntlay''', '''top_fd={:.4} top_clip={:.4} clip_launches={} null={:.4} \\
         up_host={:.4} up_sort={:.4} up_dev={:.4} up_warm={:.4} | ntlay''')
rep('''        p.null_secs,
        p.ntlay,''', '''        p.null_secs,
        p.up_host_secs,
        p.up_sort_secs,
        p.up_dev_secs,
        p.up_warm_secs,
        p.ntlay,''')
open(p, 'w').write(s)
print('patched')
