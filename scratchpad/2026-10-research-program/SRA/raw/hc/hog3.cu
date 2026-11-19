// hog3: greedy hog. Takes all but LEAVE_MIB of free memory, then keeps polling and grabs (in 1 MiB pieces)
// any memory the client frees, so the client's later allocations fail. usage: hog2 LEAVE_MIB [TRIGGER_FILE]
#include <cstdio>
#include <cstdlib>
#include <unistd.h>
#include <cuda_runtime.h>
int main(int argc, char** argv) {
  long leave = atol(argv[1]);
  if (argc > 2) { while (access(argv[2], F_OK) != 0) usleep(20000); }
  cudaFree(0);
  size_t fr, tot; long got = 0, grabs = 0; int printed = 0;
  for (long it = 0;; it++) {
    cudaMemGetInfo(&fr, &tot);
    long excess = (long)(fr >> 20) - leave;
    while (excess > 0) {
      long c = excess > 256 ? 256 : excess; void* p;
      if (cudaMalloc(&p, (size_t)c << 20) != cudaSuccess) { if (c == 1) break; excess = c / 2; continue; }
      got += c; excess -= c; grabs++;
    }
    if (!printed && it > 0) { printf("hog3: initial hold %ld MiB, free now %zu MiB of %zu\n", got, fr >> 20, tot >> 20); fflush(stdout); printed = 1; }
    if (it % 200000 == 0 && it) { cudaMemGetInfo(&fr, &tot); printf("hog3: t+%lds holding %ld MiB in %ld grabs, free %zu MiB\n", it, got, grabs, fr >> 20); fflush(stdout); }
    ;
  }
}
