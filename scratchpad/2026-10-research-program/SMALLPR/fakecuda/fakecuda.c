/* A stand-in libcuda whose driver loads and then refuses: every entry point
   cudarc reaches first returns CUDA_ERROR_OUT_OF_MEMORY (2), as a GPU whose
   memory is taken does at context creation. Test-only, for exercising the
   client's CUDA-failure path on a machine with no NVIDIA GPU. */
#include <stddef.h>
static const char *name = "CUDA_ERROR_OUT_OF_MEMORY";
static const char *desc = "out of memory";
int cuInit(unsigned int flags) { (void)flags; return 2; }
int cuDriverGetVersion(int *v) { if (v) *v = 12080; return 0; }
int cuDeviceGetCount(int *c) { if (c) *c = 1; return 0; }
int cuDeviceGet(int *d, int o) { if (d) *d = o; return 2; }
int cuDevicePrimaryCtxRetain(void **c, int d) { (void)c; (void)d; return 2; }
int cuCtxCreate_v2(void **c, unsigned f, int d) { (void)c; (void)f; (void)d; return 2; }
int cuGetErrorName(int e, const char **s) { (void)e; if (s) *s = name; return 0; }
int cuGetErrorString(int e, const char **s) { (void)e; if (s) *s = desc; return 0; }
