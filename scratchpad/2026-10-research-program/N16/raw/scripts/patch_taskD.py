#!/usr/bin/env python3
"""N16 Task D (branch exp/n14-wgpu-dense-plan from upstream main 5b1d627): give a discrete wgpu adapter CUDA's denser
batch plan (`JoinLimits::with_vram_budget`). python3 patch_taskD.py TREE"""
import sys
T = sys.argv[1]


def patch(path, pairs):
    p = f'{T}/common/src/{path}'
    s = open(p).read()
    for a, b, n in pairs:
        assert s.count(a) == n, (path, s.count(a), a[:80])
        s = s.replace(a, b)
    open(p, 'w').write(s)


patch('cubecl_backend.rs', [(
    """            let info = setup.adapter.get_info();
            let client = cubecl::wgpu::WgpuRuntime::client(&device);""",
    """            let info = setup.adapter.get_info();
            crate::cubecl_join::note_wgpu_adapter(&info.name, &format!("{:?}", info.device_type));
            let client = cubecl::wgpu::WgpuRuntime::client(&device);""", 2)])

patch('cubecl_join.rs', [(
    """/// What `client`'s device allows the join: `CubeCL` reports its largest
/// buffer as `max_page_size`, on CUDA a quarter of the device's memory
/// ([`JoinLimits::vram_budget`]).
pub(crate) fn limits_of<R: Runtime>(client: &ComputeClient<R>) -> JoinLimits {
    let lim = JoinLimits::for_buffer(client.properties().memory.max_page_size);
    if R::name(client).contains("cuda") {
        lim.with_vram_budget()
    } else {
        lim
    }
}""",
    """/// The process's wgpu adapter: its name and its `wgpu::DeviceType` (as
/// `Debug` text), noted once when the wgpu client is created.
static WGPU_ADAPTER: std::sync::OnceLock<(String, String)> = std::sync::OnceLock::new();

/// Note the wgpu adapter the process runs on (see [`wgpu_dense_plan`]).
pub(crate) fn note_wgpu_adapter(name: &str, device_type: &str) {
    let _ = WGPU_ADAPTER.set((name.to_owned(), device_type.to_owned()));
}

/// The largest budget a wgpu adapter may have and still take the denser
/// plan: 2 GiB, what desktop drivers' 2 GiB binding limit gives (RADV,
/// the RX 9070 XT). A Vulkan driver that reports 4 GiB bindings gets a
/// 4 GiB budget, which wgpu cannot relate to the card's memory.
const WGPU_DENSE_BUDGET: usize = 2 << 30;

/// Whether a wgpu adapter takes the denser batch plan that CUDA takes
/// ([`JoinLimits::vram_budget`]): a discrete GPU (wgpu's `DiscreteGpu`; Vulkan
/// reports integrated GPUs, APUs and Apple's unified memory as
/// `IntegratedGpu`, VMs as `VirtualGpu`, software rasterizers as `Cpu`),
/// not a software rasterizer by name, with a budget of at most
/// [`WGPU_DENSE_BUDGET`]. wgpu does not report a device's memory, so this is
/// a class rule, not a measured share: the denser plan fills the same
/// budget, which on such a card is at most a quarter of 8 GB.
pub(crate) fn wgpu_dense_plan(name: &str, device_type: &str, lim: JoinLimits) -> bool {
    device_type == "DiscreteGpu"
        && !crate::cubecl_backend::is_software_rasterizer(name)
        && lim.budget <= WGPU_DENSE_BUDGET
}

/// What `client`'s device allows the join: `CubeCL` reports its largest
/// buffer as `max_page_size`, on CUDA a quarter of the device's memory
/// ([`JoinLimits::vram_budget`]); a discrete wgpu adapter takes the same
/// plan where [`wgpu_dense_plan`] allows it.
pub(crate) fn limits_of<R: Runtime>(client: &ComputeClient<R>) -> JoinLimits {
    let lim = JoinLimits::for_buffer(client.properties().memory.max_page_size);
    let name = R::name(client);
    let dense_wgpu = name.contains("wgpu")
        && WGPU_ADAPTER
            .get()
            .is_some_and(|(n, t)| wgpu_dense_plan(n, t, lim));
    if name.contains("cuda") || dense_wgpu {
        lim.with_vram_budget()
    } else {
        lim
    }
}""", 1),
    ("""    /// The FD kernel's append ranks kept tops with a ballot only on planes""",
     """    /// Task D: the denser plan on wgpu takes discrete adapters only, by
    /// wgpu's device type, never a software rasterizer, and not past a 2 GiB
    /// budget.
    #[test]
    fn the_denser_plan_on_wgpu_takes_discrete_adapters_only() {
        let radv = JoinLimits::for_buffer(2_147_483_644);
        let big = JoinLimits::for_buffer(4 << 30);
        let small = JoinLimits::for_buffer(128 << 20);
        for (name, ty, lim, want) in [
            ("AMD Radeon RX 9070 XT (RADV GFX1201)", "DiscreteGpu", radv, true),
            ("NVIDIA GeForce RTX 3080", "DiscreteGpu", radv, true),
            ("Intel(R) Arc(tm) A770 Graphics (DG2)", "DiscreteGpu", radv, true),
            ("Apple M4", "IntegratedGpu", radv, false),
            ("AMD Radeon 780M (RADV PHOENIX)", "IntegratedGpu", radv, false),
            ("llvmpipe (LLVM 19.1.7, 256 bits)", "Cpu", small, false),
            ("llvmpipe (LLVM 19.1.7, 256 bits)", "DiscreteGpu", small, false),
            ("Microsoft Basic Render Driver", "VirtualGpu", radv, false),
            ("Apple Paravirtual device", "VirtualGpu", radv, false),
            ("Unknown", "Other", radv, false),
            ("NVIDIA GeForce RTX 3060 (Vulkan)", "DiscreteGpu", big, false),
        ] {
            assert_eq!(wgpu_dense_plan(name, ty, lim), want, "{name} {ty} {lim:?}");
        }
        assert!(radv.budget <= WGPU_DENSE_BUDGET && big.budget > WGPU_DENSE_BUDGET);
    }

    /// The FD kernel's append ranks kept tops with a ballot only on planes""", 1),
])
print('patched Task D', T)
