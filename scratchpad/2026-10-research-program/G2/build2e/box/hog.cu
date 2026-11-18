// hog: hold all but LEAVE_MIB of the card's free memory until killed.
// usage: hog LEAVE_MIB [TRIGGER_FILE]  (with a trigger file: wait until it exists, then allocate)
#include <cstdio>
#include <cstdlib>
#include <unistd.h>
#include <cuda_runtime.h>
int main(int argc, char** argv) {
  long leave = atol(argv[1]);
  if (argc > 2) { while (access(argv[2], F_OK) != 0) usleep(20000); }
  cudaFree(0);
  size_t fr, tot; cudaMemGetInfo(&fr, &tot);
  long want = (long)(fr >> 20) - leave; long got = 0;
  while (got < want) {
    long c = want - got > 256 ? 256 : want - got; void* p;
    if (cudaMalloc(&p, (size_t)c << 20) != cudaSuccess) break;
    got += c;
  }
  cudaMemGetInfo(&fr, &tot);
  printf("hog: held %ld MiB, free now %zu MiB of %zu\n", got, fr >> 20, tot >> 20); fflush(stdout);
  pause();
}
