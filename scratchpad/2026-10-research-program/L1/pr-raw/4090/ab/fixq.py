p = "/root/prept/common/src/cpu_join.rs"
s = open(p).read()
s = s.replace("x.contains(e)", "x.contains('e')").replace("v.split(,)", "v.split(',')").replace("f.split(:)", "f.split(':')")
open(p, "w").write(s)
