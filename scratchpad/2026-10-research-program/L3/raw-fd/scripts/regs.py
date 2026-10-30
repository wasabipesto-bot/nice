import re,subprocess,sys,os
os.makedirs('/root/runs/fd/src',exist_ok=True)
out=[]
for log,tag in (('/root/runs/fd/cubecl_src.log','fd'),('/root/runs/fd/cubecl_src_old.log','old')):
    s=open(log).read()
    blocks=re.findall(r'```cpp\n(.*?)```',s,re.S)
    k=0
    for b in blocks:
        m=re.search(r'__global__ void __launch_bounds__\(\d+\)(\w+)',b)
        name=m.group(1)
        if 'detailed' not in name: continue
        base=(40,50)[k] if k<2 else k
        k+=1
        f=f'/root/runs/fd/src/{tag}_{name}_b{base}.cu'
        open(f,'w').write(b)
        r=subprocess.run(['/usr/local/cuda/bin/nvcc','-arch=sm_86','-cubin','-lineinfo','-Xptxas','-v','-o',f[:-3]+'.cubin',f],capture_output=True,text=True)
        out.append(f'{f}:\n{r.stderr.strip()}')
        sass=subprocess.run(['/usr/local/cuda/bin/cuobjdump','-sass',f[:-3]+'.cubin'],capture_output=True,text=True).stdout
        open(f[:-3]+'.sass','w').write(sass)
        n=len(re.findall(r'^\s+/\*[0-9a-f]{4}\*/',sass,re.M))
        out.append(f'  SASS instructions: {n}')
print('\n'.join(out))
