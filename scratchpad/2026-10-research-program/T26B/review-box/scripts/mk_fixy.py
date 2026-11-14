p="/root/rv/fixy/common/src/cubecl_backend.rs"; s=open(p).read()
old="                            let nr = dim >> shift;\n"
assert s.count(old)==1
s=s.replace(old,"                            let k: u32 = std::env::var(\"NICE_REVIEW_CUBES\").ok().and_then(|v| v.parse().ok()).unwrap_or(1);\n                            let nr = (dim * k) >> shift;\n")
old2="&[256, 100, 48, 36]"
assert s.count(old2)==2
s=s.replace(old2,"&[256, 255, 200, 129, 100, 65, 63, 48, 36, 33, 31, 17, 9, 2, 1]")
open(p,"w").write(s); print("ok")
