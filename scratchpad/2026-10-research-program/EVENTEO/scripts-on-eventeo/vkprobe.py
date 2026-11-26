import ctypes, sys
vk = ctypes.CDLL('libvulkan.so.1')
class CI(ctypes.Structure):
    _fields_ = [('sType', ctypes.c_int), ('pNext', ctypes.c_void_p), ('flags', ctypes.c_uint),
                ('pApplicationInfo', ctypes.c_void_p), ('enabledLayerCount', ctypes.c_uint),
                ('ppEnabledLayerNames', ctypes.c_void_p), ('enabledExtensionCount', ctypes.c_uint),
                ('ppEnabledExtensionNames', ctypes.c_void_p)]
ci = CI(1, None, 0, None, 0, None, 0, None)
inst = ctypes.c_void_p()
r = vk.vkCreateInstance(ctypes.byref(ci), None, ctypes.byref(inst))
print('vkCreateInstance ->', r)
if r != 0: sys.exit(1)
n = ctypes.c_uint(0)
vk.vkEnumeratePhysicalDevices(inst, ctypes.byref(n), None)
print('physical devices:', n.value)
devs = (ctypes.c_void_p * n.value)()
vk.vkEnumeratePhysicalDevices(inst, ctypes.byref(n), devs)
class Props(ctypes.Structure):
    _fields_ = [('apiVersion', ctypes.c_uint), ('driverVersion', ctypes.c_uint), ('vendorID', ctypes.c_uint),
                ('deviceID', ctypes.c_uint), ('deviceType', ctypes.c_uint), ('deviceName', ctypes.c_char * 256),
                ('rest', ctypes.c_char * 1024)]
for d in devs:
    p = Props(); vk.vkGetPhysicalDeviceProperties(ctypes.c_void_p(d), ctypes.byref(p))
    print(hex(p.vendorID), p.deviceType, p.deviceName.decode())
