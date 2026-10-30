// language: metal1.0
#include <metal_stdlib>
#include <simd/simd.h>

using metal::uint;

struct _mslBufferSizes {
    uint size0;
    uint size1;
    uint size2;
};

typedef metal::atomic_uint type_2[1];
typedef uint type_3[1];
struct type_4 {
    uint inner[8];
};
struct type_5 {
    uint inner[6];
};
struct info_st {
    type_4 scalars_u32_;
    type_5 static_meta;
};
struct type_6 {
    metal::atomic_uint inner[44];
};
struct type_7 {
    uint inner[768];
};
struct type_9 {
    uint inner[1];
};
struct type_10 {
    uint inner[2];
};
struct type_11 {
    uint inner[3];
};
constant uint WORKGROUP_SIZE_X = 256u;
constant uint WORKGROUP_SIZE_Y = 1u;
constant uint WORKGROUP_SIZE_Z = 1u;
uint naga_mod(uint lhs, uint rhs) {
    return lhs % metal::select(rhs, 1u, rhs == 0u);
}

uint naga_div(uint lhs, uint rhs) {
    return lhs / metal::select(rhs, 1u, rhs == 0u);
}


struct detailed_kernelInput {
};
kernel void detailed_kernel(
  metal::uint3 global_id [[thread_position_in_grid]]
, metal::uint3 local_invocation_id [[thread_position_in_threadgroup]]
, metal::uint3 num_workgroups [[threadgroups_per_grid]]
, device type_2& buffer_0_global [[user(fake0)]]
, device type_2& buffer_1_global [[user(fake0)]]
, device type_3& buffer_2_global [[user(fake0)]]
, device info_st const& info [[user(fake0)]]
, threadgroup type_6& shared_memory_0_
, threadgroup type_7& shared_memory_22_
, constant _mslBufferSizes& _buffer_sizes [[user(fake0)]]
) {
    if (metal::all(local_invocation_id == metal::uint3(0u))) {
        for (int __i0 = 0; __i0 < 44; __i0++) {
            metal::atomic_store_explicit(&shared_memory_0_.inner[__i0], 0, metal::memory_order_relaxed);
        }
        shared_memory_22_ = {};
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    type_9 a_31_ = {};
    type_10 a_34_ = {};
    type_11 a_48_ = {};
    uint l_mut_1_ = {};
    uint l_mut_74_ = {};
    uint l_mut_98_ = {};
    uint l_mut_127_ = {};
    int l_mut_89_ = {};
    int l_mut_99_ = {};
    ulong l_mut_25_ = {};
    ulong l_mut_29_ = {};
    ulong l_mut_35_ = {};
    ulong l_mut_73_ = {};
    l_mut_1_ = local_invocation_id.x;
    uint2 loop_bound = uint2(4294967295u);
    while(true) {
        if (metal::all(loop_bound == uint2(0u))) { break; }
        loop_bound -= uint2(loop_bound.y == 0u, 1u);
        uint _e17 = l_mut_1_;
        bool l_2_ = _e17 < 44u;
        bool l_3_ = !(l_2_);
        if (l_3_) {
            break;
        }
        uint _e22 = l_mut_1_;
        metal::atomic_store_explicit(&shared_memory_0_.inner[_e22], 0u, metal::memory_order_relaxed);
        uint _e25 = l_mut_1_;
        l_mut_1_ = _e25 + WORKGROUP_SIZE_X;
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    uint _e31 = info.scalars_u32_.inner[1];
    ulong l_5_ = static_cast<ulong>(_e31);
    ulong l_6_ = l_5_ << static_cast<uint>(as_type<ulong>(32uL));
    uint _e40 = info.scalars_u32_.inner[0];
    ulong l_7_ = static_cast<ulong>(_e40);
    ulong l_8_ = l_6_ | l_7_;
    uint _e46 = info.scalars_u32_.inner[3];
    ulong l_9_ = static_cast<ulong>(_e46);
    ulong l_10_ = l_9_ << static_cast<uint>(as_type<ulong>(32uL));
    uint _e55 = info.scalars_u32_.inner[2];
    ulong l_11_ = static_cast<ulong>(_e55);
    ulong l_12_ = l_10_ | l_11_;
    uint _e61 = info.scalars_u32_.inner[5];
    ulong l_13_ = static_cast<ulong>(_e61);
    ulong l_14_ = l_13_ << static_cast<uint>(as_type<ulong>(32uL));
    uint _e70 = info.scalars_u32_.inner[4];
    ulong l_15_ = static_cast<ulong>(_e70);
    ulong l_16_ = l_14_ | l_15_;
    uint l_17_ = local_invocation_id.x >> 5u;
    uint l_18_ = naga_mod(l_17_, 4u);
    ulong l_19_ = static_cast<ulong>(num_workgroups.x);
    ulong l_21_ = l_19_ * 256uL;
    uint l_23_ = local_invocation_id.x * 3u;
    ulong l_24_ = static_cast<ulong>(global_id.x);
    l_mut_25_ = l_24_;
    uint2 loop_bound_1 = uint2(4294967295u);
    while(true) {
        if (metal::all(loop_bound_1 == uint2(0u))) { break; }
        loop_bound_1 -= uint2(loop_bound_1.y == 0u, 1u);
        ulong _e87 = l_mut_25_;
        bool l_26_ = _e87 < l_16_;
        bool l_27_ = !(l_26_);
        if (l_27_) {
            break;
        }
        ulong _e90 = l_mut_25_;
        ulong l_28_ = l_8_ + _e90;
        l_mut_29_ = l_12_;
        bool l_30_ = l_28_ < l_8_;
        if (l_30_) {
            ulong _e93 = l_mut_29_;
            l_mut_29_ = _e93 + 1uL;
        }
        ulong l_32_ = l_28_ >> static_cast<uint>(as_type<ulong>(0uL));
        uint l_33_ = static_cast<uint>(as_type<ulong>(l_32_));
        a_31_.inner[0] = l_33_;
        a_34_.inner[0] = 0u;
        a_34_.inner[1] = 0u;
        l_mut_35_ = 0uL;
        uint l_36_ = a_31_.inner[0];
        ulong l_37_ = static_cast<ulong>(l_36_);
        uint l_38_ = a_31_.inner[0];
        ulong l_39_ = static_cast<ulong>(l_38_);
        ulong l_40_ = l_37_ * l_39_;
        uint l_41_ = a_34_.inner[0];
        ulong l_42_ = static_cast<ulong>(l_41_);
        ulong l_43_ = l_40_ + l_42_;
        ulong _e119 = l_mut_35_;
        ulong l_44_ = l_43_ + _e119;
        uint l_45_ = static_cast<uint>(as_type<ulong>(l_44_));
        a_34_.inner[0] = l_45_;
        ulong l_46_ = l_44_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_35_ = l_46_;
        ulong _e128 = l_mut_35_;
        uint l_47_ = static_cast<uint>(as_type<ulong>(_e128));
        a_34_.inner[1] = l_47_;
        a_48_.inner[0] = 0u;
        a_48_.inner[1] = 0u;
        a_48_.inner[2] = 0u;
        l_mut_35_ = 0uL;
        uint l_49_ = a_34_.inner[0];
        ulong l_50_ = static_cast<ulong>(l_49_);
        uint l_51_ = a_31_.inner[0];
        ulong l_52_ = static_cast<ulong>(l_51_);
        ulong l_53_ = l_50_ * l_52_;
        uint l_54_ = a_48_.inner[0];
        ulong l_55_ = static_cast<ulong>(l_54_);
        ulong l_56_ = l_53_ + l_55_;
        ulong _e150 = l_mut_35_;
        ulong l_57_ = l_56_ + _e150;
        uint l_58_ = static_cast<uint>(as_type<ulong>(l_57_));
        a_48_.inner[0] = l_58_;
        ulong l_59_ = l_57_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_35_ = l_59_;
        ulong _e159 = l_mut_35_;
        uint l_60_ = static_cast<uint>(as_type<ulong>(_e159));
        a_48_.inner[1] = l_60_;
        l_mut_35_ = 0uL;
        uint l_61_ = a_34_.inner[1];
        ulong l_62_ = static_cast<ulong>(l_61_);
        uint l_63_ = a_31_.inner[0];
        ulong l_64_ = static_cast<ulong>(l_63_);
        ulong l_65_ = l_62_ * l_64_;
        uint l_66_ = a_48_.inner[1];
        ulong l_67_ = static_cast<ulong>(l_66_);
        ulong l_68_ = l_65_ + l_67_;
        ulong _e175 = l_mut_35_;
        ulong l_69_ = l_68_ + _e175;
        uint l_70_ = static_cast<uint>(as_type<ulong>(l_69_));
        a_48_.inner[1] = l_70_;
        ulong l_71_ = l_69_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_35_ = l_71_;
        ulong _e184 = l_mut_35_;
        uint l_72_ = static_cast<uint>(as_type<ulong>(_e184));
        a_48_.inner[2] = l_72_;
        l_mut_35_ = 0uL;
        l_mut_73_ = 0uL;
        l_mut_74_ = 0u;
        uint2 loop_bound_2 = uint2(4294967295u);
        while(true) {
            if (metal::all(loop_bound_2 == uint2(0u))) { break; }
            loop_bound_2 -= uint2(loop_bound_2.y == 0u, 1u);
            uint _e191 = l_mut_74_;
            bool l_75_ = _e191 < 2u;
            bool l_76_ = !(l_75_);
            if (l_76_) {
                break;
            }
            uint _e195 = l_mut_74_;
            bool l_77_ = _e195 == 0u;
            if (l_77_) {
                uint l_78_ = l_23_ + 0u;
                uint l_79_ = a_34_.inner[0];
                shared_memory_22_.inner[l_78_] = l_79_;
                uint l_80_ = l_23_ + 1u;
                uint l_81_ = a_34_.inner[1];
                shared_memory_22_.inner[l_80_] = l_81_;
                uint l_82_ = l_23_ + 2u;
                shared_memory_22_.inner[l_82_] = 0u;
            } else {
                uint l_83_ = l_23_ + 0u;
                uint l_84_ = a_48_.inner[0];
                shared_memory_22_.inner[l_83_] = l_84_;
                uint l_85_ = l_23_ + 1u;
                uint l_86_ = a_48_.inner[1];
                shared_memory_22_.inner[l_85_] = l_86_;
                uint l_87_ = l_23_ + 2u;
                uint l_88_ = a_48_.inner[2];
                shared_memory_22_.inner[l_87_] = l_88_;
            }
            l_mut_89_ = 2;
            uint2 loop_bound_3 = uint2(4294967295u);
            while(true) {
                if (metal::all(loop_bound_3 == uint2(0u))) { break; }
                loop_bound_3 -= uint2(loop_bound_3.y == 0u, 1u);
                int _e234 = l_mut_89_;
                bool l_90_ = _e234 >= 0;
                bool l_91_ = !(l_90_);
                if (l_91_) {
                    break;
                }
                int _e238 = l_mut_89_;
                uint l_92_ = static_cast<uint>(_e238);
                uint l_93_ = l_23_ + l_92_;
                uint l_94_ = shared_memory_22_.inner[l_93_];
                bool l_95_ = l_94_ != 0u;
                if (l_95_) {
                    break;
                }
                int _e246 = l_mut_89_;
                l_mut_89_ = as_type<int>(as_type<uint>(_e246) - as_type<uint>(1));
            }
            uint2 loop_bound_4 = uint2(4294967295u);
            while(true) {
                if (metal::all(loop_bound_4 == uint2(0u))) { break; }
                loop_bound_4 -= uint2(loop_bound_4.y == 0u, 1u);
                int _e249 = l_mut_89_;
                bool l_96_ = _e249 >= 0;
                bool l_97_ = !(l_96_);
                if (l_97_) {
                    break;
                }
                l_mut_98_ = 0u;
                int _e254 = l_mut_89_;
                l_mut_99_ = _e254;
                uint2 loop_bound_5 = uint2(4294967295u);
                while(true) {
                    if (metal::all(loop_bound_5 == uint2(0u))) { break; }
                    loop_bound_5 -= uint2(loop_bound_5.y == 0u, 1u);
                    int _e255 = l_mut_99_;
                    bool l_100_ = _e255 >= 0;
                    bool l_101_ = !(l_100_);
                    if (l_101_) {
                        break;
                    }
                    int _e259 = l_mut_99_;
                    uint l_102_ = static_cast<uint>(_e259);
                    uint l_103_ = l_23_ + l_102_;
                    uint l_104_ = shared_memory_22_.inner[l_103_];
                    uint _e265 = l_mut_98_;
                    uint l_105_ = _e265 << 16u;
                    uint l_106_ = l_104_ >> 16u;
                    uint l_107_ = l_105_ | l_106_;
                    uint l_108_ = naga_div(l_107_, 10000u);
                    uint l_109_ = l_108_ * 10000u;
                    uint l_110_ = l_107_ - l_109_;
                    uint l_111_ = l_110_ << 16u;
                    uint l_112_ = l_104_ & 65535u;
                    uint l_113_ = l_111_ | l_112_;
                    uint l_114_ = naga_div(l_113_, 10000u);
                    uint l_115_ = l_114_ * 10000u;
                    uint l_116_ = l_113_ - l_115_;
                    l_mut_98_ = l_116_;
                    int _e286 = l_mut_99_;
                    uint l_117_ = static_cast<uint>(_e286);
                    uint l_118_ = l_23_ + l_117_;
                    uint l_119_ = l_108_ << 16u;
                    uint l_120_ = l_119_ | l_114_;
                    shared_memory_22_.inner[l_118_] = l_120_;
                    int _e294 = l_mut_99_;
                    l_mut_99_ = as_type<int>(as_type<uint>(_e294) - as_type<uint>(1));
                }
                uint2 loop_bound_6 = uint2(4294967295u);
                while(true) {
                    if (metal::all(loop_bound_6 == uint2(0u))) { break; }
                    loop_bound_6 -= uint2(loop_bound_6.y == 0u, 1u);
                    int _e297 = l_mut_89_;
                    bool l_121_ = _e297 >= 0;
                    bool l_122_ = !(l_121_);
                    if (l_122_) {
                        break;
                    }
                    int _e301 = l_mut_89_;
                    uint l_123_ = static_cast<uint>(_e301);
                    uint l_124_ = l_23_ + l_123_;
                    uint l_125_ = shared_memory_22_.inner[l_124_];
                    bool l_126_ = l_125_ != 0u;
                    if (l_126_) {
                        break;
                    }
                    int _e309 = l_mut_89_;
                    l_mut_89_ = as_type<int>(as_type<uint>(_e309) - as_type<uint>(1));
                }
                uint _e312 = l_mut_98_;
                l_mut_127_ = _e312;
                int _e313 = l_mut_89_;
                bool l_128_ = _e313 >= 0;
                if (l_128_) {
                    uint _e316 = l_mut_127_;
                    uint l_129_ = naga_div(_e316, 10u);
                    uint l_130_ = l_129_ * 10u;
                    uint _e321 = l_mut_127_;
                    uint l_131_ = _e321 - l_130_;
                    l_mut_127_ = l_129_;
                    ulong l_132_ = static_cast<ulong>(l_131_);
                    ulong l_133_ = 1uL << static_cast<uint>(as_type<ulong>(l_132_));
                    ulong _e328 = l_mut_35_;
                    l_mut_35_ = _e328 | l_133_;
                    uint _e330 = l_mut_127_;
                    uint l_134_ = naga_div(_e330, 10u);
                    uint l_135_ = l_134_ * 10u;
                    uint _e335 = l_mut_127_;
                    uint l_136_ = _e335 - l_135_;
                    l_mut_127_ = l_134_;
                    ulong l_137_ = static_cast<ulong>(l_136_);
                    ulong l_138_ = 1uL << static_cast<uint>(as_type<ulong>(l_137_));
                    ulong _e342 = l_mut_35_;
                    l_mut_35_ = _e342 | l_138_;
                    uint _e344 = l_mut_127_;
                    uint l_139_ = naga_div(_e344, 10u);
                    uint l_140_ = l_139_ * 10u;
                    uint _e349 = l_mut_127_;
                    uint l_141_ = _e349 - l_140_;
                    l_mut_127_ = l_139_;
                    ulong l_142_ = static_cast<ulong>(l_141_);
                    ulong l_143_ = 1uL << static_cast<uint>(as_type<ulong>(l_142_));
                    ulong _e356 = l_mut_35_;
                    l_mut_35_ = _e356 | l_143_;
                    uint _e358 = l_mut_127_;
                    uint l_144_ = naga_div(_e358, 10u);
                    uint l_145_ = l_144_ * 10u;
                    uint _e363 = l_mut_127_;
                    uint l_146_ = _e363 - l_145_;
                    l_mut_127_ = l_144_;
                    ulong l_147_ = static_cast<ulong>(l_146_);
                    ulong l_148_ = 1uL << static_cast<uint>(as_type<ulong>(l_147_));
                    ulong _e370 = l_mut_35_;
                    l_mut_35_ = _e370 | l_148_;
                } else {
                    uint2 loop_bound_7 = uint2(4294967295u);
                    while(true) {
                        if (metal::all(loop_bound_7 == uint2(0u))) { break; }
                        loop_bound_7 -= uint2(loop_bound_7.y == 0u, 1u);
                        uint _e372 = l_mut_127_;
                        bool l_149_ = _e372 != 0u;
                        bool l_150_ = !(l_149_);
                        if (l_150_) {
                            break;
                        }
                        uint _e376 = l_mut_127_;
                        uint l_151_ = naga_div(_e376, 10u);
                        uint l_152_ = l_151_ * 10u;
                        uint _e381 = l_mut_127_;
                        uint l_153_ = _e381 - l_152_;
                        l_mut_127_ = l_151_;
                        ulong l_154_ = static_cast<ulong>(l_153_);
                        ulong l_155_ = 1uL << static_cast<uint>(as_type<ulong>(l_154_));
                        ulong _e388 = l_mut_35_;
                        l_mut_35_ = _e388 | l_155_;
                    }
                }
            }
            uint _e390 = l_mut_74_;
            l_mut_74_ = _e390 + 1u;
        }
        ulong _e393 = l_mut_35_;
        uint l_156_ = static_cast<uint>(as_type<ulong>(_e393));
        uint l_157_ = metal::popcount(l_156_);
        ulong _e397 = l_mut_35_;
        ulong l_158_ = _e397 >> static_cast<uint>(as_type<ulong>(32uL));
        uint l_159_ = static_cast<uint>(as_type<ulong>(l_158_));
        uint l_160_ = metal::popcount(l_159_);
        uint l_161_ = l_157_ + l_160_;
        l_mut_127_ = l_161_;
        uint l_162_ = l_18_ * 11u;
        uint _e408 = l_mut_127_;
        uint l_163_ = l_162_ + _e408;
        uint _e413 = metal::atomic_fetch_add_explicit(&shared_memory_0_.inner[l_163_], 1u, metal::memory_order_relaxed);
        uint _e414 = l_mut_127_;
        bool l_166_ = _e414 > 9u;
        if (l_166_) {
            uint _e420 = metal::atomic_fetch_add_explicit(&buffer_1_global[0], 1u, metal::memory_order_relaxed);
            uint _e424 = info.scalars_u32_.inner[6];
            bool l_169_ = _e420 < _e424;
            if (l_169_) {
                uint l_170_ = 5u * _e420;
                uint l_171_ = static_cast<uint>(as_type<ulong>(l_28_));
                buffer_2_global[l_170_] = l_171_;
                uint l_172_ = l_170_ + 1u;
                ulong l_173_ = l_28_ >> static_cast<uint>(as_type<ulong>(32uL));
                uint l_174_ = static_cast<uint>(as_type<ulong>(l_173_));
                buffer_2_global[l_172_] = l_174_;
                uint l_175_ = l_170_ + 2u;
                ulong _e444 = l_mut_29_;
                uint l_176_ = static_cast<uint>(as_type<ulong>(_e444));
                buffer_2_global[l_175_] = l_176_;
                uint l_177_ = l_170_ + 3u;
                ulong _e451 = l_mut_29_;
                ulong l_178_ = _e451 >> static_cast<uint>(as_type<ulong>(32uL));
                uint l_179_ = static_cast<uint>(as_type<ulong>(l_178_));
                buffer_2_global[l_177_] = l_179_;
                uint l_180_ = l_170_ + 4u;
                uint _e464 = l_mut_127_;
                buffer_2_global[l_180_] = _e464;
            }
        }
        ulong _e465 = l_mut_25_;
        l_mut_25_ = _e465 + l_21_;
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    l_mut_127_ = local_invocation_id.x;
    uint2 loop_bound_8 = uint2(4294967295u);
    while(true) {
        if (metal::all(loop_bound_8 == uint2(0u))) { break; }
        loop_bound_8 -= uint2(loop_bound_8.y == 0u, 1u);
        uint _e468 = l_mut_127_;
        bool l_181_ = _e468 < 11u;
        bool l_182_ = !(l_181_);
        if (l_182_) {
            break;
        }
        l_mut_98_ = 0u;
        uint _e474 = l_mut_127_;
        uint l_183_ = 0u + _e474;
        uint l_185_ = metal::atomic_load_explicit(&shared_memory_0_.inner[l_183_], metal::memory_order_relaxed);
        uint _e479 = l_mut_98_;
        l_mut_98_ = _e479 + l_185_;
        uint _e482 = l_mut_127_;
        uint l_186_ = 11u + _e482;
        uint l_188_ = metal::atomic_load_explicit(&shared_memory_0_.inner[l_186_], metal::memory_order_relaxed);
        uint _e487 = l_mut_98_;
        l_mut_98_ = _e487 + l_188_;
        uint _e490 = l_mut_127_;
        uint l_189_ = 22u + _e490;
        uint l_191_ = metal::atomic_load_explicit(&shared_memory_0_.inner[l_189_], metal::memory_order_relaxed);
        uint _e495 = l_mut_98_;
        l_mut_98_ = _e495 + l_191_;
        uint _e498 = l_mut_127_;
        uint l_192_ = 33u + _e498;
        uint l_194_ = metal::atomic_load_explicit(&shared_memory_0_.inner[l_192_], metal::memory_order_relaxed);
        uint _e503 = l_mut_98_;
        l_mut_98_ = _e503 + l_194_;
        uint _e505 = l_mut_98_;
        bool l_195_ = _e505 != 0u;
        if (l_195_) {
            uint _e509 = l_mut_127_;
            uint _e511 = l_mut_98_;
            uint _e512 = metal::atomic_fetch_add_explicit(&buffer_0_global[_e509], _e511, metal::memory_order_relaxed);
        }
        uint _e513 = l_mut_127_;
        l_mut_127_ = _e513 + WORKGROUP_SIZE_X;
    }
    return;
}
