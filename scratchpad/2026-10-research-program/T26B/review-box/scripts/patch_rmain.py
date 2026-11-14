p="/root/rv/rmain/common/src/cubecl_backend.rs"; s=open(p).read()
old="""        let planes: &[bool] = if plane_queue_runs(client, &ctx.device_name()) {
            &[false, true]
        } else {
            &[false]
        };"""
assert s.count(old)==1
s=s.replace(old,"        let planes: &[bool] = &[false];")
open(p,"w").write(s); print("patched")
