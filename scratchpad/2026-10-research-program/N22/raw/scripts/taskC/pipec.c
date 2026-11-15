// pipec: create one compute pipeline from a SPIR-V file on the first Vulkan device (RADV's null winsys under
// RADV_FORCE_FAMILY), so that RADV_DEBUG=shaders dumps what ACO generates. Usage: pipec SHADER.spv LAYOUT.txt
// LAYOUT.txt: lines "binding <set> <binding> <storage|uniform>" and "push <bytes>". Nothing is executed.
#include <vulkan/vulkan.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define CK(x) do { VkResult r_ = (x); if (r_ != VK_SUCCESS) { fprintf(stderr, "%s failed: %d\n", #x, r_); return 1; } } while (0)
int main(int argc, char **argv) {
  if (argc < 3) return 2;
  VkApplicationInfo ai = {VK_STRUCTURE_TYPE_APPLICATION_INFO, 0, "pipec", 1, "pipec", 1, VK_API_VERSION_1_3};
  VkInstanceCreateInfo ici = {VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, 0, 0, &ai};
  VkInstance inst; CK(vkCreateInstance(&ici, 0, &inst));
  uint32_t n = 1; VkPhysicalDevice pd; vkEnumeratePhysicalDevices(inst, &n, &pd);
  if (!n) { fprintf(stderr, "no device\n"); return 1; }
  VkPhysicalDeviceProperties pp; vkGetPhysicalDeviceProperties(pd, &pp);
  VkPhysicalDeviceVulkan11Properties p11 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_PROPERTIES};
  VkPhysicalDeviceVulkan13Properties p13 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_PROPERTIES, &p11};
  VkPhysicalDeviceProperties2 pp2 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2, &p13};
  vkGetPhysicalDeviceProperties2(pd, &pp2);
  fprintf(stderr, "PIPEC device=%s subgroupSize=%u minSubgroup=%u maxSubgroup=%u\n", pp.deviceName, p11.subgroupSize,
          p13.minSubgroupSize, p13.maxSubgroupSize);
  VkPhysicalDeviceVulkan13Features f13 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES};
  VkPhysicalDeviceVulkan12Features f12 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES, &f13};
  VkPhysicalDeviceVulkan11Features f11 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES, &f12};
  VkPhysicalDeviceFeatures2 f2 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &f11};
  vkGetPhysicalDeviceFeatures2(pd, &f2);
  float pr = 1; VkDeviceQueueCreateInfo qi = {VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO, 0, 0, 0, 1, &pr};
  VkDeviceCreateInfo dci = {VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO, &f2, 0, 1, &qi};
  VkDevice dev; CK(vkCreateDevice(pd, &dci, 0, &dev));
  FILE *f = fopen(argv[1], "rb"); fseek(f, 0, SEEK_END); long sz = ftell(f); fseek(f, 0, SEEK_SET);
  uint32_t *code = malloc(sz); fread(code, 1, sz, f); fclose(f);
  VkShaderModuleCreateInfo smi = {VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO, 0, 0, (size_t)sz, code};
  VkShaderModule sm; CK(vkCreateShaderModule(dev, &smi, 0, &sm));
  VkDescriptorSetLayoutBinding b[64]; int nb = 0; uint32_t push = 0; char kind[32]; int s, bi;
  f = fopen(argv[2], "r"); char line[256];
  while (fgets(line, sizeof line, f)) {
    if (sscanf(line, "binding %d %d %31s", &s, &bi, kind) == 3) {
      b[nb] = (VkDescriptorSetLayoutBinding){(uint32_t)bi, strcmp(kind, "uniform") ? VK_DESCRIPTOR_TYPE_STORAGE_BUFFER : VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, 0};
      nb++;
    } else sscanf(line, "push %u", &push);
  }
  fclose(f);
  VkDescriptorSetLayoutCreateInfo dli = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO, 0, 0, (uint32_t)nb, b};
  VkDescriptorSetLayout dl; CK(vkCreateDescriptorSetLayout(dev, &dli, 0, &dl));
  VkPushConstantRange pcr = {VK_SHADER_STAGE_COMPUTE_BIT, 0, push};
  VkPipelineLayoutCreateInfo pli = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO, 0, 0, 1, &dl, push ? 1u : 0u, &pcr};
  VkPipelineLayout pl; CK(vkCreatePipelineLayout(dev, &pli, 0, &pl));
  VkPipelineShaderStageCreateInfo st = {VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO, 0, 0, VK_SHADER_STAGE_COMPUTE_BIT, sm, "main"};
  const char *ep = getenv("ENTRY"); if (ep) st.pName = ep;
  VkPipelineShaderStageRequiredSubgroupSizeCreateInfo rs = {VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_REQUIRED_SUBGROUP_SIZE_CREATE_INFO, 0, 0};
  if (getenv("SUBGROUP")) { rs.requiredSubgroupSize = atoi(getenv("SUBGROUP")); st.pNext = &rs; }
  VkComputePipelineCreateInfo cpi = {VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO, 0, 0, st, pl};
  VkPipeline pipe; CK(vkCreateComputePipelines(dev, VK_NULL_HANDLE, 1, &cpi, 0, &pipe));
  fprintf(stderr, "PIPEC ok %s\n", argv[1]);
  return 0;
}
