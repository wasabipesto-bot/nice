// language: metal1.0
#include <metal_stdlib>
#include <simd/simd.h>

using metal::uint;

struct _mslBufferSizes {
    uint size0;
    uint size1;
    uint size2;
    uint size3;
    uint size4;
    uint size5;
    uint size6;
    uint size7;
    uint size8;
    uint size9;
    uint size10;
    uint size11;
    uint size12;
    uint size13;
    uint size14;
};

typedef uint type_1[1];
typedef metal::atomic_uint type_3[1];
struct type_4 {
    uint inner[4];
};
struct type_5 {
    uint inner[30];
};
struct info_st {
    type_4 scalars_u32_;
    type_5 static_meta;
};
struct type_6 {
    metal::atomic_uint inner[1];
};
struct type_7 {
    uint inner[256];
};
struct type_8 {
    uint inner[1024];
};
struct type_9 {
    uint inner[1];
};
struct type_11 {
    uint inner[2];
};
struct type_12 {
    uint inner[8];
};
constant uint WORKGROUP_SIZE_X = 256u;
constant uint WORKGROUP_SIZE_Y = 1u;
constant uint WORKGROUP_SIZE_Z = 1u;
uint naga_div(uint lhs, uint rhs) {
    return lhs / metal::select(rhs, 1u, rhs == 0u);
}

uint naga_mod(uint lhs, uint rhs) {
    return lhs % metal::select(rhs, 1u, rhs == 0u);
}


struct join_kernelInput {
};
kernel void join_kernel(
  metal::uint3 local_invocation_id [[thread_position_in_threadgroup]]
, metal::uint3 num_workgroups [[threadgroups_per_grid]]
, metal::uint3 workgroup_id [[threadgroup_position_in_grid]]
, uint subgroup_size [[threads_per_simdgroup]]
, uint subgroup_invocation_id [[thread_index_in_simdgroup]]
, device type_1 const& buffer_0_global [[user(fake0)]]
, device type_1 const& buffer_1_global [[user(fake0)]]
, device type_1 const& buffer_2_global [[user(fake0)]]
, device type_1 const& buffer_3_global [[user(fake0)]]
, device type_1 const& buffer_4_global [[user(fake0)]]
, device type_1 const& buffer_5_global [[user(fake0)]]
, device type_1 const& buffer_6_global [[user(fake0)]]
, device type_1 const& buffer_7_global [[user(fake0)]]
, device type_1 const& buffer_8_global [[user(fake0)]]
, device type_1 const& buffer_9_global [[user(fake0)]]
, device type_1& buffer_10_global [[user(fake0)]]
, device type_3& buffer_11_global [[user(fake0)]]
, device type_1 const& buffer_12_global [[user(fake0)]]
, device type_3& buffer_13_global [[user(fake0)]]
, device type_3& buffer_14_global [[user(fake0)]]
, device info_st const& info [[user(fake0)]]
, threadgroup type_6& shared_memory_8_
, threadgroup type_7& shared_memory_1_
, threadgroup type_7& shared_memory_2_
, threadgroup type_7& shared_memory_3_
, threadgroup type_7& shared_memory_4_
, threadgroup type_7& shared_memory_5_
, threadgroup type_8& shared_memory_6_
, threadgroup type_8& shared_memory_7_
, threadgroup type_7& shared_memory_0_
, threadgroup type_9& shared_memory_9_
, constant _mslBufferSizes& _buffer_sizes [[user(fake0)]]
) {
    if (metal::all(local_invocation_id == metal::uint3(0u))) {
        for (int __i0 = 0; __i0 < 1; __i0++) {
            metal::atomic_store_explicit(&shared_memory_8_.inner[__i0], 0, metal::memory_order_relaxed);
        }
        shared_memory_1_ = {};
        shared_memory_2_ = {};
        shared_memory_3_ = {};
        shared_memory_4_ = {};
        shared_memory_5_ = {};
        shared_memory_6_ = {};
        shared_memory_7_ = {};
        shared_memory_0_ = {};
        shared_memory_9_ = {};
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    type_11 a_67_ = {};
    type_11 a_68_ = {};
    type_11 a_69_ = {};
    type_11 a_70_ = {};
    type_11 a_152_ = {};
    type_12 a_266_ = {};
    type_12 a_277_ = {};
    type_12 a_661_ = {};
    type_12 a_670_ = {};
    uint l_mut_12_ = {};
    uint l_mut_45_ = {};
    uint l_mut_49_ = {};
    uint l_mut_64_ = {};
    uint l_mut_94_ = {};
    uint l_mut_101_ = {};
    uint l_mut_153_ = {};
    uint l_mut_154_ = {};
    uint l_mut_180_ = {};
    uint l_mut_241_ = {};
    uint l_mut_245_ = {};
    uint l_mut_246_ = {};
    uint l_mut_247_ = {};
    uint l_mut_267_ = {};
    uint l_mut_271_ = {};
    uint l_mut_278_ = {};
    uint l_mut_279_ = {};
    bool l_mut_404_ = {};
    ulong l_mut_86_ = {};
    bool local = {};
    bool local_1 = {};
    bool local_2 = {};
    bool local_3 = {};
    bool local_4 = {};
    bool local_5 = {};
    bool local_6 = {};
    bool local_7 = {};
    bool local_8 = {};
    bool local_9 = {};
    bool local_10 = {};
    bool local_11 = {};
    bool local_12 = {};
    bool local_13 = {};
    bool local_14 = {};
    bool local_15 = {};
    bool local_16 = {};
    bool local_17 = {};
    bool local_18 = {};
    bool local_19 = {};
    bool l_10_ = local_invocation_id.x == 0u;
    if (l_10_) {
        metal::atomic_store_explicit(&shared_memory_8_.inner[0], 0u, metal::memory_order_relaxed);
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    l_mut_12_ = workgroup_id.x;
    uint2 loop_bound = uint2(4294967295u);
    while(true) {
        if (metal::all(loop_bound == uint2(0u))) { break; }
        loop_bound -= uint2(loop_bound.y == 0u, 1u);
        uint _e40 = l_mut_12_;
        uint _e44 = info.scalars_u32_.inner[0];
        bool l_13_ = _e40 < _e44;
        bool l_14_ = !(l_13_);
        if (l_14_) {
            break;
        }
        uint _e48 = l_mut_12_;
        uint l_15_ = 4u * _e48;
        uint l_16_ = buffer_6_global[l_15_];
        uint _e54 = l_mut_12_;
        uint l_17_ = 4u * _e54;
        uint l_18_ = l_17_ + 1u;
        uint l_19_ = buffer_6_global[l_18_];
        uint _e62 = l_mut_12_;
        uint l_20_ = 4u * _e62;
        uint l_21_ = l_20_ + 2u;
        uint l_22_ = buffer_6_global[l_21_];
        uint _e70 = l_mut_12_;
        uint l_23_ = 4u * _e70;
        uint l_24_ = l_23_ + 3u;
        uint l_25_ = buffer_6_global[l_24_];
        uint l_26_ = naga_div(l_19_, 57u);
        uint l_27_ = l_26_ * 57u;
        uint l_28_ = l_19_ - l_27_;
        uint l_29_ = buffer_3_global[l_28_];
        uint l_30_ = l_28_ + 1u;
        uint l_31_ = buffer_3_global[l_30_];
        uint l_32_ = l_31_ - l_29_;
        uint l_33_ = l_16_ * 58u;
        uint l_34_ = l_33_ + l_26_;
        uint l_35_ = l_34_ * 57u;
        uint l_36_ = l_35_ + l_28_;
        uint l_37_ = buffer_5_global[l_36_];
        uint l_38_ = l_16_ * 58u;
        uint _e105 = info.scalars_u32_.inner[1];
        uint l_39_ = l_38_ * _e105;
        uint l_40_ = 58u * l_29_;
        uint l_41_ = l_39_ + l_40_;
        uint l_42_ = l_26_ * l_32_;
        uint l_43_ = l_41_ + l_42_;
        uint _e115 = info.scalars_u32_.inner[1];
        uint l_44_ = l_16_ * _e115;
        l_mut_45_ = l_22_;
        uint2 loop_bound_1 = uint2(4294967295u);
        while(true) {
            if (metal::all(loop_bound_1 == uint2(0u))) { break; }
            loop_bound_1 -= uint2(loop_bound_1.y == 0u, 1u);
            uint _e117 = l_mut_45_;
            bool l_46_ = _e117 < l_25_;
            bool l_47_ = !(l_46_);
            if (l_47_) {
                break;
            }
            uint _e120 = l_mut_45_;
            uint l_48_ = l_25_ - _e120;
            l_mut_49_ = l_48_;
            uint _e122 = l_mut_49_;
            bool l_50_ = _e122 > 256u;
            if (l_50_) {
                l_mut_49_ = 256u;
            }
            uint _e127 = l_mut_49_;
            bool l_51_ = local_invocation_id.x < _e127;
            if (l_51_) {
                uint _e129 = l_mut_45_;
                uint l_52_ = _e129 + local_invocation_id.x;
                uint l_53_ = buffer_7_global[l_52_];
                uint l_54_ = 2u * l_53_;
                uint l_55_ = buffer_8_global[l_54_];
                shared_memory_1_.inner[local_invocation_id.x] = l_55_;
                uint l_56_ = 2u * l_53_;
                uint l_57_ = l_56_ + 1u;
                uint l_58_ = buffer_8_global[l_57_];
                shared_memory_2_.inner[local_invocation_id.x] = l_58_;
                uint l_59_ = 2u * l_53_;
                uint l_60_ = buffer_9_global[l_59_];
                shared_memory_3_.inner[local_invocation_id.x] = l_60_;
                uint l_61_ = 2u * l_53_;
                uint l_62_ = l_61_ + 1u;
                uint l_63_ = buffer_9_global[l_62_];
                shared_memory_4_.inner[local_invocation_id.x] = l_63_;
                shared_memory_5_.inner[local_invocation_id.x] = l_53_;
            }
            metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
            l_mut_64_ = 0u;
            uint2 loop_bound_2 = uint2(4294967295u);
            while(true) {
                if (metal::all(loop_bound_2 == uint2(0u))) { break; }
                loop_bound_2 -= uint2(loop_bound_2.y == 0u, 1u);
                uint _e175 = l_mut_64_;
                bool l_65_ = _e175 < l_37_;
                bool l_66_ = !(l_65_);
                if (l_66_) {
                    break;
                }
                uint _e178 = l_mut_64_;
                uint l_71_ = _e178 + local_invocation_id.x;
                uint l_72_ = l_71_ + 0u;
                a_67_.inner[0] = 4294967295u;
                a_68_.inner[0] = 4294967295u;
                a_69_.inner[0] = 0u;
                a_70_.inner[0] = 0u;
                bool l_73_ = l_72_ < l_37_;
                if (l_73_) {
                    a_70_.inner[0] = 4294967295u;
                    uint l_74_ = l_43_ + l_72_;
                    uint l_75_ = buffer_4_global[l_74_];
                    uint l_76_ = l_44_ + l_75_;
                    uint l_77_ = 2u * l_76_;
                    uint l_78_ = l_77_ + 1u;
                    uint l_79_ = buffer_0_global[l_78_];
                    ulong l_80_ = static_cast<ulong>(l_79_);
                    ulong l_81_ = l_80_ << static_cast<uint>(as_type<ulong>(32uL));
                    uint l_82_ = 2u * l_76_;
                    uint l_83_ = buffer_0_global[l_82_];
                    ulong l_84_ = static_cast<ulong>(l_83_);
                    ulong l_85_ = l_81_ | l_84_;
                    l_mut_86_ = l_85_;
                    uint l_87_ = buffer_1_global[l_76_];
                    uint l_88_ = l_87_ & 255u;
                    uint l_89_ = l_87_ >> 16u;
                    uint l_90_ = l_89_ & 255u;
                    uint l_91_ = l_26_ * l_90_;
                    uint l_92_ = l_88_ + l_91_;
                    uint l_93_ = naga_mod(l_92_, 58u);
                    l_mut_94_ = l_93_;
                    uint l_95_ = l_87_ >> 8u;
                    uint l_96_ = l_95_ & 255u;
                    uint l_97_ = l_87_ >> 24u;
                    uint l_98_ = l_26_ * l_97_;
                    uint l_99_ = l_96_ + l_98_;
                    uint l_100_ = naga_mod(l_99_, 58u);
                    l_mut_101_ = l_100_;
                    uint _e241 = l_mut_94_;
                    ulong l_102_ = static_cast<ulong>(_e241);
                    ulong l_103_ = 1uL << static_cast<uint>(as_type<ulong>(l_102_));
                    uint _e247 = l_mut_101_;
                    ulong l_104_ = static_cast<ulong>(_e247);
                    ulong l_105_ = 1uL << static_cast<uint>(as_type<ulong>(l_104_));
                    ulong l_106_ = l_103_ | l_105_;
                    ulong _e254 = l_mut_86_;
                    l_mut_86_ = _e254 | l_106_;
                    ulong _e256 = l_mut_86_;
                    uint l_107_ = static_cast<uint>(as_type<ulong>(_e256));
                    a_67_.inner[0] = l_107_;
                    ulong _e260 = l_mut_86_;
                    ulong l_108_ = _e260 >> static_cast<uint>(as_type<ulong>(32uL));
                    uint l_109_ = static_cast<uint>(as_type<ulong>(l_108_));
                    a_68_.inner[0] = l_109_;
                    uint l_110_ = buffer_2_global[l_75_];
                    a_69_.inner[0] = l_110_;
                }
                uint _e272 = l_mut_64_;
                uint l_111_ = _e272 + local_invocation_id.x;
                uint l_112_ = l_111_ + 256u;
                a_67_.inner[1] = 4294967295u;
                a_68_.inner[1] = 4294967295u;
                a_69_.inner[1] = 0u;
                a_70_.inner[1] = 0u;
                bool l_113_ = l_112_ < l_37_;
                if (l_113_) {
                    a_70_.inner[1] = 4294967295u;
                    uint l_114_ = l_43_ + l_112_;
                    uint l_115_ = buffer_4_global[l_114_];
                    uint l_116_ = l_44_ + l_115_;
                    uint l_117_ = 2u * l_116_;
                    uint l_118_ = l_117_ + 1u;
                    uint l_119_ = buffer_0_global[l_118_];
                    ulong l_120_ = static_cast<ulong>(l_119_);
                    ulong l_121_ = l_120_ << static_cast<uint>(as_type<ulong>(32uL));
                    uint l_122_ = 2u * l_116_;
                    uint l_123_ = buffer_0_global[l_122_];
                    ulong l_124_ = static_cast<ulong>(l_123_);
                    ulong l_125_ = l_121_ | l_124_;
                    l_mut_86_ = l_125_;
                    uint l_126_ = buffer_1_global[l_116_];
                    uint l_127_ = l_126_ & 255u;
                    uint l_128_ = l_126_ >> 16u;
                    uint l_129_ = l_128_ & 255u;
                    uint l_130_ = l_26_ * l_129_;
                    uint l_131_ = l_127_ + l_130_;
                    uint l_132_ = naga_mod(l_131_, 58u);
                    l_mut_101_ = l_132_;
                    uint l_133_ = l_126_ >> 8u;
                    uint l_134_ = l_133_ & 255u;
                    uint l_135_ = l_126_ >> 24u;
                    uint l_136_ = l_26_ * l_135_;
                    uint l_137_ = l_134_ + l_136_;
                    uint l_138_ = naga_mod(l_137_, 58u);
                    l_mut_94_ = l_138_;
                    uint _e335 = l_mut_101_;
                    ulong l_139_ = static_cast<ulong>(_e335);
                    ulong l_140_ = 1uL << static_cast<uint>(as_type<ulong>(l_139_));
                    uint _e341 = l_mut_94_;
                    ulong l_141_ = static_cast<ulong>(_e341);
                    ulong l_142_ = 1uL << static_cast<uint>(as_type<ulong>(l_141_));
                    ulong l_143_ = l_140_ | l_142_;
                    ulong _e348 = l_mut_86_;
                    l_mut_86_ = _e348 | l_143_;
                    ulong _e350 = l_mut_86_;
                    uint l_144_ = static_cast<uint>(as_type<ulong>(_e350));
                    a_67_.inner[1] = l_144_;
                    ulong _e354 = l_mut_86_;
                    ulong l_145_ = _e354 >> static_cast<uint>(as_type<ulong>(32uL));
                    uint l_146_ = static_cast<uint>(as_type<ulong>(l_145_));
                    a_68_.inner[1] = l_146_;
                    uint l_147_ = buffer_2_global[l_115_];
                    a_69_.inner[1] = l_147_;
                }
                l_mut_101_ = 0u;
                uint2 loop_bound_3 = uint2(4294967295u);
                while(true) {
                    if (metal::all(loop_bound_3 == uint2(0u))) { break; }
                    loop_bound_3 -= uint2(loop_bound_3.y == 0u, 1u);
                    uint _e367 = l_mut_101_;
                    uint _e368 = l_mut_49_;
                    bool l_148_ = _e367 < _e368;
                    bool l_149_ = !(l_148_);
                    if (l_149_) {
                        break;
                    }
                    uint _e371 = l_mut_101_;
                    uint l_150_ = _e371 + 32u;
                    l_mut_94_ = l_150_;
                    uint _e374 = l_mut_94_;
                    uint _e375 = l_mut_49_;
                    bool l_151_ = _e374 > _e375;
                    if (l_151_) {
                        uint _e377 = l_mut_49_;
                        l_mut_94_ = _e377;
                    }
                    a_152_.inner[0] = 0u;
                    a_152_.inner[1] = 0u;
                    uint _e382 = l_mut_101_;
                    l_mut_153_ = _e382;
                    l_mut_154_ = 1u;
                    uint2 loop_bound_4 = uint2(4294967295u);
                    while(true) {
                        if (metal::all(loop_bound_4 == uint2(0u))) { break; }
                        loop_bound_4 -= uint2(loop_bound_4.y == 0u, 1u);
                        uint _e384 = l_mut_153_;
                        uint _e385 = l_mut_94_;
                        bool l_155_ = _e384 < _e385;
                        bool l_156_ = !(l_155_);
                        if (l_156_) {
                            break;
                        }
                        uint _e389 = l_mut_153_;
                        uint l_157_ = shared_memory_1_.inner[_e389];
                        uint _e393 = l_mut_153_;
                        uint l_158_ = shared_memory_2_.inner[_e393];
                        uint l_159_ = a_67_.inner[0];
                        uint l_160_ = l_159_ & l_157_;
                        uint l_161_ = a_68_.inner[0];
                        uint l_162_ = l_161_ & l_158_;
                        uint l_163_ = l_160_ | l_162_;
                        bool l_164_ = l_163_ == 0u;
                        uint _e406 = l_mut_154_;
                        uint l_165_ = l_164_ ? _e406 : 0u;
                        uint l_166_ = a_152_.inner[0];
                        uint l_167_ = l_166_ | l_165_;
                        a_152_.inner[0] = l_167_;
                        uint l_168_ = a_67_.inner[1];
                        uint l_169_ = l_168_ & l_157_;
                        uint l_170_ = a_68_.inner[1];
                        uint l_171_ = l_170_ & l_158_;
                        uint l_172_ = l_169_ | l_171_;
                        bool l_173_ = l_172_ == 0u;
                        uint _e422 = l_mut_154_;
                        uint l_174_ = l_173_ ? _e422 : 0u;
                        uint l_175_ = a_152_.inner[1];
                        uint l_176_ = l_175_ | l_174_;
                        a_152_.inner[1] = l_176_;
                        uint _e428 = l_mut_154_;
                        l_mut_154_ = _e428 << 1u;
                        uint _e431 = l_mut_153_;
                        l_mut_153_ = _e431 + 1u;
                    }
                    uint l_177_ = a_152_.inner[0];
                    uint l_178_ = a_70_.inner[0];
                    uint l_179_ = l_177_ & l_178_;
                    l_mut_180_ = l_179_;
                    uint l_181_ = a_69_.inner[0];
                    uint2 loop_bound_5 = uint2(4294967295u);
                    while(true) {
                        if (metal::all(loop_bound_5 == uint2(0u))) { break; }
                        loop_bound_5 -= uint2(loop_bound_5.y == 0u, 1u);
                        uint _e441 = l_mut_180_;
                        bool l_182_ = _e441 != 0u;
                        bool unnamed = metal::simd_any(l_182_);
                        bool l_184_ = !(unnamed);
                        if (l_184_) {
                            break;
                        }
                        uint _e446 = l_mut_180_;
                        bool l_185_ = _e446 != 0u;
                        if (l_185_) {
                            uint _e449 = l_mut_180_;
                            uint l_186_ = metal::ctz(_e449);
                            uint _e451 = l_mut_101_;
                            uint l_187_ = _e451 + l_186_;
                            uint _e453 = l_mut_180_;
                            uint l_188_ = _e453 - 1u;
                            uint _e456 = l_mut_180_;
                            l_mut_180_ = _e456 & l_188_;
                            uint l_189_ = shared_memory_3_.inner[l_187_];
                            bool l_190_ = l_181_ >= l_189_;
                            uint l_191_ = shared_memory_4_.inner[l_187_];
                            bool l_192_ = l_181_ < l_191_;
                            if (l_190_) {
                                local = l_192_;
                            } else {
                                local = false;
                            }
                            bool l_193_ = local;
                            if (l_193_) {
                                uint _e473 = metal::atomic_fetch_add_explicit(&shared_memory_8_.inner[0], 1u, metal::memory_order_relaxed);
                                bool l_196_ = _e473 < 1024u;
                                if (l_196_) {
                                    uint l_197_ = shared_memory_5_.inner[l_187_];
                                    shared_memory_6_.inner[_e473] = l_197_;
                                    shared_memory_7_.inner[_e473] = l_181_;
                                } else {
                                    uint _e486 = metal::atomic_fetch_add_explicit(&buffer_11_global[0], 1u, metal::memory_order_relaxed);
                                    uint _e490 = info.scalars_u32_.inner[2];
                                    bool l_200_ = _e486 < _e490;
                                    if (l_200_) {
                                        uint l_201_ = 2u * _e486;
                                        uint l_202_ = shared_memory_5_.inner[l_187_];
                                        buffer_10_global[l_201_] = l_202_;
                                        uint l_203_ = 2u * _e486;
                                        uint l_204_ = l_203_ + 1u;
                                        buffer_10_global[l_204_] = l_181_;
                                    }
                                }
                            }
                        }
                    }
                    uint l_205_ = a_152_.inner[1];
                    uint l_206_ = a_70_.inner[1];
                    uint l_207_ = l_205_ & l_206_;
                    l_mut_180_ = l_207_;
                    uint l_208_ = a_69_.inner[1];
                    uint2 loop_bound_6 = uint2(4294967295u);
                    while(true) {
                        if (metal::all(loop_bound_6 == uint2(0u))) { break; }
                        loop_bound_6 -= uint2(loop_bound_6.y == 0u, 1u);
                        uint _e512 = l_mut_180_;
                        bool l_209_ = _e512 != 0u;
                        bool unnamed_1 = metal::simd_any(l_209_);
                        bool l_211_ = !(unnamed_1);
                        if (l_211_) {
                            break;
                        }
                        uint _e517 = l_mut_180_;
                        bool l_212_ = _e517 != 0u;
                        if (l_212_) {
                            uint _e520 = l_mut_180_;
                            uint l_213_ = metal::ctz(_e520);
                            uint _e522 = l_mut_101_;
                            uint l_214_ = _e522 + l_213_;
                            uint _e524 = l_mut_180_;
                            uint l_215_ = _e524 - 1u;
                            uint _e527 = l_mut_180_;
                            l_mut_180_ = _e527 & l_215_;
                            uint l_216_ = shared_memory_3_.inner[l_214_];
                            bool l_217_ = l_208_ >= l_216_;
                            uint l_218_ = shared_memory_4_.inner[l_214_];
                            bool l_219_ = l_208_ < l_218_;
                            if (l_217_) {
                                local_1 = l_219_;
                            } else {
                                local_1 = false;
                            }
                            bool l_220_ = local_1;
                            if (l_220_) {
                                uint _e544 = metal::atomic_fetch_add_explicit(&shared_memory_8_.inner[0], 1u, metal::memory_order_relaxed);
                                bool l_223_ = _e544 < 1024u;
                                if (l_223_) {
                                    uint l_224_ = shared_memory_5_.inner[l_214_];
                                    shared_memory_6_.inner[_e544] = l_224_;
                                    shared_memory_7_.inner[_e544] = l_208_;
                                } else {
                                    uint _e557 = metal::atomic_fetch_add_explicit(&buffer_11_global[0], 1u, metal::memory_order_relaxed);
                                    uint _e561 = info.scalars_u32_.inner[2];
                                    bool l_227_ = _e557 < _e561;
                                    if (l_227_) {
                                        uint l_228_ = 2u * _e557;
                                        uint l_229_ = shared_memory_5_.inner[l_214_];
                                        buffer_10_global[l_228_] = l_229_;
                                        uint l_230_ = 2u * _e557;
                                        uint l_231_ = l_230_ + 1u;
                                        buffer_10_global[l_231_] = l_208_;
                                    }
                                }
                            }
                        }
                    }
                    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
                    uint l_233_ = metal::atomic_load_explicit(&shared_memory_8_.inner[0], metal::memory_order_relaxed);
                    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
                    bool l_234_ = l_233_ >= 512u;
                    if (l_234_) {
                        l_mut_180_ = l_233_;
                        uint _e581 = l_mut_180_;
                        bool l_235_ = _e581 > 1024u;
                        if (l_235_) {
                            l_mut_180_ = 1024u;
                        }
                        bool l_236_ = local_invocation_id.x == 0u;
                        if (l_236_) {
                            uint _e590 = l_mut_180_;
                            uint _e591 = metal::atomic_fetch_add_explicit(&buffer_13_global[0], _e590, metal::memory_order_relaxed);
                        }
                        uint l_239_ = naga_div(local_invocation_id.x, subgroup_size);
                        uint l_240_ = naga_div(WORKGROUP_SIZE_X, subgroup_size);
                        l_mut_241_ = 0u;
                        uint2 loop_bound_7 = uint2(4294967295u);
                        while(true) {
                            if (metal::all(loop_bound_7 == uint2(0u))) { break; }
                            loop_bound_7 -= uint2(loop_bound_7.y == 0u, 1u);
                            uint _e597 = l_mut_241_;
                            uint _e598 = l_mut_180_;
                            bool l_242_ = _e597 < _e598;
                            bool l_243_ = !(l_242_);
                            if (l_243_) {
                                break;
                            }
                            uint _e601 = l_mut_241_;
                            uint l_244_ = _e601 + local_invocation_id.x;
                            l_mut_245_ = 0u;
                            l_mut_246_ = 0u;
                            l_mut_247_ = 0u;
                            uint _e607 = l_mut_180_;
                            bool l_248_ = l_244_ < _e607;
                            if (l_248_) {
                                uint l_249_ = shared_memory_6_.inner[l_244_];
                                l_mut_246_ = l_249_;
                                uint l_250_ = shared_memory_7_.inner[l_244_];
                                l_mut_247_ = l_250_;
                                uint _e616 = l_mut_246_;
                                uint l_251_ = 2u * _e616;
                                uint l_252_ = buffer_12_global[l_251_];
                                l_mut_86_ = 0uL;
                                uint _e623 = l_mut_246_;
                                uint l_253_ = 2u * _e623;
                                uint l_254_ = l_253_ + 1u;
                                uint l_255_ = buffer_12_global[l_254_];
                                bool l_256_ = l_255_ != 0u;
                                if (l_256_) {
                                    uint _e633 = l_mut_246_;
                                    uint l_257_ = 2u * _e633;
                                    uint l_258_ = l_257_ + 1u;
                                    uint l_259_ = buffer_8_global[l_258_];
                                    ulong l_260_ = static_cast<ulong>(l_259_);
                                    ulong l_261_ = l_260_ << static_cast<uint>(as_type<ulong>(32uL));
                                    uint _e646 = l_mut_246_;
                                    uint l_262_ = 2u * _e646;
                                    uint l_263_ = buffer_8_global[l_262_];
                                    ulong l_264_ = static_cast<ulong>(l_263_);
                                    ulong l_265_ = l_261_ | l_264_;
                                    l_mut_86_ = l_265_;
                                }
                                uint _e653 = l_mut_247_;
                                l_mut_267_ = _e653;
                                uint _e654 = l_mut_267_;
                                uint l_268_ = naga_mod(_e654, 58u);
                                a_266_.inner[0] = l_268_;
                                uint _e658 = l_mut_267_;
                                l_mut_267_ = naga_div(_e658, 58u);
                                uint _e661 = l_mut_267_;
                                uint l_269_ = naga_mod(_e661, 58u);
                                a_266_.inner[1] = l_269_;
                                uint _e665 = l_mut_267_;
                                l_mut_267_ = naga_div(_e665, 58u);
                                uint _e668 = l_mut_267_;
                                uint l_270_ = naga_mod(_e668, 58u);
                                a_266_.inner[2] = l_270_;
                                uint _e672 = l_mut_267_;
                                l_mut_267_ = naga_div(_e672, 58u);
                                l_mut_271_ = l_252_;
                                uint _e675 = l_mut_271_;
                                uint l_272_ = naga_mod(_e675, 58u);
                                a_266_.inner[3] = l_272_;
                                uint _e679 = l_mut_271_;
                                l_mut_271_ = naga_div(_e679, 58u);
                                uint _e682 = l_mut_271_;
                                uint l_273_ = naga_mod(_e682, 58u);
                                a_266_.inner[4] = l_273_;
                                uint _e686 = l_mut_271_;
                                l_mut_271_ = naga_div(_e686, 58u);
                                uint _e689 = l_mut_271_;
                                uint l_274_ = naga_mod(_e689, 58u);
                                a_266_.inner[5] = l_274_;
                                uint _e693 = l_mut_271_;
                                l_mut_271_ = naga_div(_e693, 58u);
                                uint _e696 = l_mut_271_;
                                uint l_275_ = naga_mod(_e696, 58u);
                                a_266_.inner[6] = l_275_;
                                uint _e700 = l_mut_271_;
                                l_mut_271_ = naga_div(_e700, 58u);
                                uint _e703 = l_mut_271_;
                                uint l_276_ = naga_mod(_e703, 58u);
                                a_266_.inner[7] = l_276_;
                                uint _e707 = l_mut_271_;
                                l_mut_271_ = naga_div(_e707, 58u);
                                l_mut_278_ = 0u;
                                uint _e711 = l_mut_278_;
                                l_mut_279_ = _e711;
                                uint l_280_ = a_266_.inner[0];
                                uint l_281_ = a_266_.inner[0];
                                uint l_282_ = l_280_ * l_281_;
                                uint _e717 = l_mut_279_;
                                l_mut_279_ = _e717 + l_282_;
                                uint _e719 = l_mut_279_;
                                uint l_283_ = naga_mod(_e719, 58u);
                                a_277_.inner[0] = l_283_;
                                uint _e723 = l_mut_279_;
                                uint l_284_ = naga_div(_e723, 58u);
                                l_mut_278_ = l_284_;
                                uint _e726 = l_mut_278_;
                                l_mut_279_ = _e726;
                                uint l_285_ = a_266_.inner[0];
                                uint l_286_ = a_266_.inner[1];
                                uint l_287_ = l_285_ * l_286_;
                                uint _e732 = l_mut_279_;
                                l_mut_279_ = _e732 + l_287_;
                                uint l_288_ = a_266_.inner[1];
                                uint l_289_ = a_266_.inner[0];
                                uint l_290_ = l_288_ * l_289_;
                                uint _e739 = l_mut_279_;
                                l_mut_279_ = _e739 + l_290_;
                                uint _e741 = l_mut_279_;
                                uint l_291_ = naga_mod(_e741, 58u);
                                a_277_.inner[1] = l_291_;
                                uint _e745 = l_mut_279_;
                                uint l_292_ = naga_div(_e745, 58u);
                                l_mut_278_ = l_292_;
                                uint _e748 = l_mut_278_;
                                l_mut_279_ = _e748;
                                uint l_293_ = a_266_.inner[0];
                                uint l_294_ = a_266_.inner[2];
                                uint l_295_ = l_293_ * l_294_;
                                uint _e754 = l_mut_279_;
                                l_mut_279_ = _e754 + l_295_;
                                uint l_296_ = a_266_.inner[1];
                                uint l_297_ = a_266_.inner[1];
                                uint l_298_ = l_296_ * l_297_;
                                uint _e761 = l_mut_279_;
                                l_mut_279_ = _e761 + l_298_;
                                uint l_299_ = a_266_.inner[2];
                                uint l_300_ = a_266_.inner[0];
                                uint l_301_ = l_299_ * l_300_;
                                uint _e768 = l_mut_279_;
                                l_mut_279_ = _e768 + l_301_;
                                uint _e770 = l_mut_279_;
                                uint l_302_ = naga_mod(_e770, 58u);
                                a_277_.inner[2] = l_302_;
                                uint _e774 = l_mut_279_;
                                uint l_303_ = naga_div(_e774, 58u);
                                l_mut_278_ = l_303_;
                                uint _e777 = l_mut_278_;
                                l_mut_279_ = _e777;
                                uint l_304_ = a_266_.inner[0];
                                uint l_305_ = a_266_.inner[3];
                                uint l_306_ = l_304_ * l_305_;
                                uint _e783 = l_mut_279_;
                                l_mut_279_ = _e783 + l_306_;
                                uint l_307_ = a_266_.inner[1];
                                uint l_308_ = a_266_.inner[2];
                                uint l_309_ = l_307_ * l_308_;
                                uint _e790 = l_mut_279_;
                                l_mut_279_ = _e790 + l_309_;
                                uint l_310_ = a_266_.inner[2];
                                uint l_311_ = a_266_.inner[1];
                                uint l_312_ = l_310_ * l_311_;
                                uint _e797 = l_mut_279_;
                                l_mut_279_ = _e797 + l_312_;
                                uint l_313_ = a_266_.inner[3];
                                uint l_314_ = a_266_.inner[0];
                                uint l_315_ = l_313_ * l_314_;
                                uint _e804 = l_mut_279_;
                                l_mut_279_ = _e804 + l_315_;
                                uint _e806 = l_mut_279_;
                                uint l_316_ = naga_mod(_e806, 58u);
                                a_277_.inner[3] = l_316_;
                                uint _e810 = l_mut_279_;
                                uint l_317_ = naga_div(_e810, 58u);
                                l_mut_278_ = l_317_;
                                uint _e813 = l_mut_278_;
                                l_mut_279_ = _e813;
                                uint l_318_ = a_266_.inner[0];
                                uint l_319_ = a_266_.inner[4];
                                uint l_320_ = l_318_ * l_319_;
                                uint _e819 = l_mut_279_;
                                l_mut_279_ = _e819 + l_320_;
                                uint l_321_ = a_266_.inner[1];
                                uint l_322_ = a_266_.inner[3];
                                uint l_323_ = l_321_ * l_322_;
                                uint _e826 = l_mut_279_;
                                l_mut_279_ = _e826 + l_323_;
                                uint l_324_ = a_266_.inner[2];
                                uint l_325_ = a_266_.inner[2];
                                uint l_326_ = l_324_ * l_325_;
                                uint _e833 = l_mut_279_;
                                l_mut_279_ = _e833 + l_326_;
                                uint l_327_ = a_266_.inner[3];
                                uint l_328_ = a_266_.inner[1];
                                uint l_329_ = l_327_ * l_328_;
                                uint _e840 = l_mut_279_;
                                l_mut_279_ = _e840 + l_329_;
                                uint l_330_ = a_266_.inner[4];
                                uint l_331_ = a_266_.inner[0];
                                uint l_332_ = l_330_ * l_331_;
                                uint _e847 = l_mut_279_;
                                l_mut_279_ = _e847 + l_332_;
                                uint _e849 = l_mut_279_;
                                uint l_333_ = naga_mod(_e849, 58u);
                                a_277_.inner[4] = l_333_;
                                uint _e853 = l_mut_279_;
                                uint l_334_ = naga_div(_e853, 58u);
                                l_mut_278_ = l_334_;
                                uint _e856 = l_mut_278_;
                                l_mut_279_ = _e856;
                                uint l_335_ = a_266_.inner[0];
                                uint l_336_ = a_266_.inner[5];
                                uint l_337_ = l_335_ * l_336_;
                                uint _e862 = l_mut_279_;
                                l_mut_279_ = _e862 + l_337_;
                                uint l_338_ = a_266_.inner[1];
                                uint l_339_ = a_266_.inner[4];
                                uint l_340_ = l_338_ * l_339_;
                                uint _e869 = l_mut_279_;
                                l_mut_279_ = _e869 + l_340_;
                                uint l_341_ = a_266_.inner[2];
                                uint l_342_ = a_266_.inner[3];
                                uint l_343_ = l_341_ * l_342_;
                                uint _e876 = l_mut_279_;
                                l_mut_279_ = _e876 + l_343_;
                                uint l_344_ = a_266_.inner[3];
                                uint l_345_ = a_266_.inner[2];
                                uint l_346_ = l_344_ * l_345_;
                                uint _e883 = l_mut_279_;
                                l_mut_279_ = _e883 + l_346_;
                                uint l_347_ = a_266_.inner[4];
                                uint l_348_ = a_266_.inner[1];
                                uint l_349_ = l_347_ * l_348_;
                                uint _e890 = l_mut_279_;
                                l_mut_279_ = _e890 + l_349_;
                                uint l_350_ = a_266_.inner[5];
                                uint l_351_ = a_266_.inner[0];
                                uint l_352_ = l_350_ * l_351_;
                                uint _e897 = l_mut_279_;
                                l_mut_279_ = _e897 + l_352_;
                                uint _e899 = l_mut_279_;
                                uint l_353_ = naga_mod(_e899, 58u);
                                a_277_.inner[5] = l_353_;
                                uint _e903 = l_mut_279_;
                                uint l_354_ = naga_div(_e903, 58u);
                                l_mut_278_ = l_354_;
                                uint _e906 = l_mut_278_;
                                l_mut_279_ = _e906;
                                uint l_355_ = a_266_.inner[0];
                                uint l_356_ = a_266_.inner[6];
                                uint l_357_ = l_355_ * l_356_;
                                uint _e912 = l_mut_279_;
                                l_mut_279_ = _e912 + l_357_;
                                uint l_358_ = a_266_.inner[1];
                                uint l_359_ = a_266_.inner[5];
                                uint l_360_ = l_358_ * l_359_;
                                uint _e919 = l_mut_279_;
                                l_mut_279_ = _e919 + l_360_;
                                uint l_361_ = a_266_.inner[2];
                                uint l_362_ = a_266_.inner[4];
                                uint l_363_ = l_361_ * l_362_;
                                uint _e926 = l_mut_279_;
                                l_mut_279_ = _e926 + l_363_;
                                uint l_364_ = a_266_.inner[3];
                                uint l_365_ = a_266_.inner[3];
                                uint l_366_ = l_364_ * l_365_;
                                uint _e933 = l_mut_279_;
                                l_mut_279_ = _e933 + l_366_;
                                uint l_367_ = a_266_.inner[4];
                                uint l_368_ = a_266_.inner[2];
                                uint l_369_ = l_367_ * l_368_;
                                uint _e940 = l_mut_279_;
                                l_mut_279_ = _e940 + l_369_;
                                uint l_370_ = a_266_.inner[5];
                                uint l_371_ = a_266_.inner[1];
                                uint l_372_ = l_370_ * l_371_;
                                uint _e947 = l_mut_279_;
                                l_mut_279_ = _e947 + l_372_;
                                uint l_373_ = a_266_.inner[6];
                                uint l_374_ = a_266_.inner[0];
                                uint l_375_ = l_373_ * l_374_;
                                uint _e954 = l_mut_279_;
                                l_mut_279_ = _e954 + l_375_;
                                uint _e956 = l_mut_279_;
                                uint l_376_ = naga_mod(_e956, 58u);
                                a_277_.inner[6] = l_376_;
                                uint _e960 = l_mut_279_;
                                uint l_377_ = naga_div(_e960, 58u);
                                l_mut_278_ = l_377_;
                                uint _e963 = l_mut_278_;
                                l_mut_279_ = _e963;
                                uint l_378_ = a_266_.inner[0];
                                uint l_379_ = a_266_.inner[7];
                                uint l_380_ = l_378_ * l_379_;
                                uint _e969 = l_mut_279_;
                                l_mut_279_ = _e969 + l_380_;
                                uint l_381_ = a_266_.inner[1];
                                uint l_382_ = a_266_.inner[6];
                                uint l_383_ = l_381_ * l_382_;
                                uint _e976 = l_mut_279_;
                                l_mut_279_ = _e976 + l_383_;
                                uint l_384_ = a_266_.inner[2];
                                uint l_385_ = a_266_.inner[5];
                                uint l_386_ = l_384_ * l_385_;
                                uint _e983 = l_mut_279_;
                                l_mut_279_ = _e983 + l_386_;
                                uint l_387_ = a_266_.inner[3];
                                uint l_388_ = a_266_.inner[4];
                                uint l_389_ = l_387_ * l_388_;
                                uint _e990 = l_mut_279_;
                                l_mut_279_ = _e990 + l_389_;
                                uint l_390_ = a_266_.inner[4];
                                uint l_391_ = a_266_.inner[3];
                                uint l_392_ = l_390_ * l_391_;
                                uint _e997 = l_mut_279_;
                                l_mut_279_ = _e997 + l_392_;
                                uint l_393_ = a_266_.inner[5];
                                uint l_394_ = a_266_.inner[2];
                                uint l_395_ = l_393_ * l_394_;
                                uint _e1004 = l_mut_279_;
                                l_mut_279_ = _e1004 + l_395_;
                                uint l_396_ = a_266_.inner[6];
                                uint l_397_ = a_266_.inner[1];
                                uint l_398_ = l_396_ * l_397_;
                                uint _e1011 = l_mut_279_;
                                l_mut_279_ = _e1011 + l_398_;
                                uint l_399_ = a_266_.inner[7];
                                uint l_400_ = a_266_.inner[0];
                                uint l_401_ = l_399_ * l_400_;
                                uint _e1018 = l_mut_279_;
                                l_mut_279_ = _e1018 + l_401_;
                                uint _e1020 = l_mut_279_;
                                uint l_402_ = naga_mod(_e1020, 58u);
                                a_277_.inner[7] = l_402_;
                                uint _e1024 = l_mut_279_;
                                uint l_403_ = naga_div(_e1024, 58u);
                                l_mut_278_ = l_403_;
                                l_mut_404_ = true;
                                l_mut_278_ = 0u;
                                uint _e1029 = l_mut_278_;
                                l_mut_279_ = _e1029;
                                uint l_405_ = a_277_.inner[0];
                                uint l_406_ = a_266_.inner[0];
                                uint l_407_ = l_405_ * l_406_;
                                uint _e1035 = l_mut_279_;
                                l_mut_279_ = _e1035 + l_407_;
                                uint _e1037 = l_mut_279_;
                                uint l_408_ = naga_mod(_e1037, 58u);
                                uint _e1040 = l_mut_279_;
                                uint l_409_ = naga_div(_e1040, 58u);
                                l_mut_278_ = l_409_;
                                uint l_410_ = a_277_.inner[0];
                                ulong l_411_ = static_cast<ulong>(l_410_);
                                ulong l_412_ = 1uL << static_cast<uint>(as_type<ulong>(l_411_));
                                ulong l_413_ = static_cast<ulong>(l_408_);
                                ulong l_414_ = 1uL << static_cast<uint>(as_type<ulong>(l_413_));
                                ulong l_415_ = l_412_ | l_414_;
                                bool l_416_ = l_410_ == l_408_;
                                ulong _e1057 = l_mut_86_;
                                ulong l_417_ = _e1057 & l_415_;
                                bool l_418_ = l_417_ != 0uL;
                                if (!(l_416_)) {
                                    local_2 = l_418_;
                                } else {
                                    local_2 = true;
                                }
                                bool l_419_ = local_2;
                                if (l_419_) {
                                    l_mut_404_ = false;
                                }
                                ulong _e1067 = l_mut_86_;
                                l_mut_86_ = _e1067 | l_415_;
                                uint _e1069 = l_mut_278_;
                                l_mut_279_ = _e1069;
                                uint l_420_ = a_277_.inner[0];
                                uint l_421_ = a_266_.inner[1];
                                uint l_422_ = l_420_ * l_421_;
                                uint _e1075 = l_mut_279_;
                                l_mut_279_ = _e1075 + l_422_;
                                uint l_423_ = a_277_.inner[1];
                                uint l_424_ = a_266_.inner[0];
                                uint l_425_ = l_423_ * l_424_;
                                uint _e1082 = l_mut_279_;
                                l_mut_279_ = _e1082 + l_425_;
                                uint _e1084 = l_mut_279_;
                                uint l_426_ = naga_mod(_e1084, 58u);
                                uint _e1087 = l_mut_279_;
                                uint l_427_ = naga_div(_e1087, 58u);
                                l_mut_278_ = l_427_;
                                uint l_428_ = a_277_.inner[1];
                                ulong l_429_ = static_cast<ulong>(l_428_);
                                ulong l_430_ = 1uL << static_cast<uint>(as_type<ulong>(l_429_));
                                ulong l_431_ = static_cast<ulong>(l_426_);
                                ulong l_432_ = 1uL << static_cast<uint>(as_type<ulong>(l_431_));
                                ulong l_433_ = l_430_ | l_432_;
                                bool l_434_ = l_428_ == l_426_;
                                ulong _e1104 = l_mut_86_;
                                ulong l_435_ = _e1104 & l_433_;
                                bool l_436_ = l_435_ != 0uL;
                                if (!(l_434_)) {
                                    local_3 = l_436_;
                                } else {
                                    local_3 = true;
                                }
                                bool l_437_ = local_3;
                                if (l_437_) {
                                    l_mut_404_ = false;
                                }
                                ulong _e1114 = l_mut_86_;
                                l_mut_86_ = _e1114 | l_433_;
                                uint _e1116 = l_mut_278_;
                                l_mut_279_ = _e1116;
                                uint l_438_ = a_277_.inner[0];
                                uint l_439_ = a_266_.inner[2];
                                uint l_440_ = l_438_ * l_439_;
                                uint _e1122 = l_mut_279_;
                                l_mut_279_ = _e1122 + l_440_;
                                uint l_441_ = a_277_.inner[1];
                                uint l_442_ = a_266_.inner[1];
                                uint l_443_ = l_441_ * l_442_;
                                uint _e1129 = l_mut_279_;
                                l_mut_279_ = _e1129 + l_443_;
                                uint l_444_ = a_277_.inner[2];
                                uint l_445_ = a_266_.inner[0];
                                uint l_446_ = l_444_ * l_445_;
                                uint _e1136 = l_mut_279_;
                                l_mut_279_ = _e1136 + l_446_;
                                uint _e1138 = l_mut_279_;
                                uint l_447_ = naga_mod(_e1138, 58u);
                                uint _e1141 = l_mut_279_;
                                uint l_448_ = naga_div(_e1141, 58u);
                                l_mut_278_ = l_448_;
                                uint l_449_ = a_277_.inner[2];
                                ulong l_450_ = static_cast<ulong>(l_449_);
                                ulong l_451_ = 1uL << static_cast<uint>(as_type<ulong>(l_450_));
                                ulong l_452_ = static_cast<ulong>(l_447_);
                                ulong l_453_ = 1uL << static_cast<uint>(as_type<ulong>(l_452_));
                                ulong l_454_ = l_451_ | l_453_;
                                bool l_455_ = l_449_ == l_447_;
                                ulong _e1158 = l_mut_86_;
                                ulong l_456_ = _e1158 & l_454_;
                                bool l_457_ = l_456_ != 0uL;
                                if (!(l_455_)) {
                                    local_4 = l_457_;
                                } else {
                                    local_4 = true;
                                }
                                bool l_458_ = local_4;
                                if (l_458_) {
                                    l_mut_404_ = false;
                                }
                                ulong _e1168 = l_mut_86_;
                                l_mut_86_ = _e1168 | l_454_;
                                uint _e1170 = l_mut_278_;
                                l_mut_279_ = _e1170;
                                uint l_459_ = a_277_.inner[0];
                                uint l_460_ = a_266_.inner[3];
                                uint l_461_ = l_459_ * l_460_;
                                uint _e1176 = l_mut_279_;
                                l_mut_279_ = _e1176 + l_461_;
                                uint l_462_ = a_277_.inner[1];
                                uint l_463_ = a_266_.inner[2];
                                uint l_464_ = l_462_ * l_463_;
                                uint _e1183 = l_mut_279_;
                                l_mut_279_ = _e1183 + l_464_;
                                uint l_465_ = a_277_.inner[2];
                                uint l_466_ = a_266_.inner[1];
                                uint l_467_ = l_465_ * l_466_;
                                uint _e1190 = l_mut_279_;
                                l_mut_279_ = _e1190 + l_467_;
                                uint l_468_ = a_277_.inner[3];
                                uint l_469_ = a_266_.inner[0];
                                uint l_470_ = l_468_ * l_469_;
                                uint _e1197 = l_mut_279_;
                                l_mut_279_ = _e1197 + l_470_;
                                uint _e1199 = l_mut_279_;
                                uint l_471_ = naga_mod(_e1199, 58u);
                                uint _e1202 = l_mut_279_;
                                uint l_472_ = naga_div(_e1202, 58u);
                                l_mut_278_ = l_472_;
                                uint l_473_ = a_277_.inner[3];
                                ulong l_474_ = static_cast<ulong>(l_473_);
                                ulong l_475_ = 1uL << static_cast<uint>(as_type<ulong>(l_474_));
                                ulong l_476_ = static_cast<ulong>(l_471_);
                                ulong l_477_ = 1uL << static_cast<uint>(as_type<ulong>(l_476_));
                                ulong l_478_ = l_475_ | l_477_;
                                bool l_479_ = l_473_ == l_471_;
                                ulong _e1219 = l_mut_86_;
                                ulong l_480_ = _e1219 & l_478_;
                                bool l_481_ = l_480_ != 0uL;
                                if (!(l_479_)) {
                                    local_5 = l_481_;
                                } else {
                                    local_5 = true;
                                }
                                bool l_482_ = local_5;
                                if (l_482_) {
                                    l_mut_404_ = false;
                                }
                                ulong _e1229 = l_mut_86_;
                                l_mut_86_ = _e1229 | l_478_;
                                uint _e1231 = l_mut_278_;
                                l_mut_279_ = _e1231;
                                uint l_483_ = a_277_.inner[0];
                                uint l_484_ = a_266_.inner[4];
                                uint l_485_ = l_483_ * l_484_;
                                uint _e1237 = l_mut_279_;
                                l_mut_279_ = _e1237 + l_485_;
                                uint l_486_ = a_277_.inner[1];
                                uint l_487_ = a_266_.inner[3];
                                uint l_488_ = l_486_ * l_487_;
                                uint _e1244 = l_mut_279_;
                                l_mut_279_ = _e1244 + l_488_;
                                uint l_489_ = a_277_.inner[2];
                                uint l_490_ = a_266_.inner[2];
                                uint l_491_ = l_489_ * l_490_;
                                uint _e1251 = l_mut_279_;
                                l_mut_279_ = _e1251 + l_491_;
                                uint l_492_ = a_277_.inner[3];
                                uint l_493_ = a_266_.inner[1];
                                uint l_494_ = l_492_ * l_493_;
                                uint _e1258 = l_mut_279_;
                                l_mut_279_ = _e1258 + l_494_;
                                uint l_495_ = a_277_.inner[4];
                                uint l_496_ = a_266_.inner[0];
                                uint l_497_ = l_495_ * l_496_;
                                uint _e1265 = l_mut_279_;
                                l_mut_279_ = _e1265 + l_497_;
                                uint _e1267 = l_mut_279_;
                                uint l_498_ = naga_mod(_e1267, 58u);
                                uint _e1270 = l_mut_279_;
                                uint l_499_ = naga_div(_e1270, 58u);
                                l_mut_278_ = l_499_;
                                uint l_500_ = a_277_.inner[4];
                                ulong l_501_ = static_cast<ulong>(l_500_);
                                ulong l_502_ = 1uL << static_cast<uint>(as_type<ulong>(l_501_));
                                ulong l_503_ = static_cast<ulong>(l_498_);
                                ulong l_504_ = 1uL << static_cast<uint>(as_type<ulong>(l_503_));
                                ulong l_505_ = l_502_ | l_504_;
                                bool l_506_ = l_500_ == l_498_;
                                ulong _e1287 = l_mut_86_;
                                ulong l_507_ = _e1287 & l_505_;
                                bool l_508_ = l_507_ != 0uL;
                                if (!(l_506_)) {
                                    local_6 = l_508_;
                                } else {
                                    local_6 = true;
                                }
                                bool l_509_ = local_6;
                                if (l_509_) {
                                    l_mut_404_ = false;
                                }
                                ulong _e1297 = l_mut_86_;
                                l_mut_86_ = _e1297 | l_505_;
                                uint _e1299 = l_mut_278_;
                                l_mut_279_ = _e1299;
                                uint l_510_ = a_277_.inner[0];
                                uint l_511_ = a_266_.inner[5];
                                uint l_512_ = l_510_ * l_511_;
                                uint _e1305 = l_mut_279_;
                                l_mut_279_ = _e1305 + l_512_;
                                uint l_513_ = a_277_.inner[1];
                                uint l_514_ = a_266_.inner[4];
                                uint l_515_ = l_513_ * l_514_;
                                uint _e1312 = l_mut_279_;
                                l_mut_279_ = _e1312 + l_515_;
                                uint l_516_ = a_277_.inner[2];
                                uint l_517_ = a_266_.inner[3];
                                uint l_518_ = l_516_ * l_517_;
                                uint _e1319 = l_mut_279_;
                                l_mut_279_ = _e1319 + l_518_;
                                uint l_519_ = a_277_.inner[3];
                                uint l_520_ = a_266_.inner[2];
                                uint l_521_ = l_519_ * l_520_;
                                uint _e1326 = l_mut_279_;
                                l_mut_279_ = _e1326 + l_521_;
                                uint l_522_ = a_277_.inner[4];
                                uint l_523_ = a_266_.inner[1];
                                uint l_524_ = l_522_ * l_523_;
                                uint _e1333 = l_mut_279_;
                                l_mut_279_ = _e1333 + l_524_;
                                uint l_525_ = a_277_.inner[5];
                                uint l_526_ = a_266_.inner[0];
                                uint l_527_ = l_525_ * l_526_;
                                uint _e1340 = l_mut_279_;
                                l_mut_279_ = _e1340 + l_527_;
                                uint _e1342 = l_mut_279_;
                                uint l_528_ = naga_mod(_e1342, 58u);
                                uint _e1345 = l_mut_279_;
                                uint l_529_ = naga_div(_e1345, 58u);
                                l_mut_278_ = l_529_;
                                uint l_530_ = a_277_.inner[5];
                                ulong l_531_ = static_cast<ulong>(l_530_);
                                ulong l_532_ = 1uL << static_cast<uint>(as_type<ulong>(l_531_));
                                ulong l_533_ = static_cast<ulong>(l_528_);
                                ulong l_534_ = 1uL << static_cast<uint>(as_type<ulong>(l_533_));
                                ulong l_535_ = l_532_ | l_534_;
                                bool l_536_ = l_530_ == l_528_;
                                ulong _e1362 = l_mut_86_;
                                ulong l_537_ = _e1362 & l_535_;
                                bool l_538_ = l_537_ != 0uL;
                                if (!(l_536_)) {
                                    local_7 = l_538_;
                                } else {
                                    local_7 = true;
                                }
                                bool l_539_ = local_7;
                                if (l_539_) {
                                    l_mut_404_ = false;
                                }
                                ulong _e1372 = l_mut_86_;
                                l_mut_86_ = _e1372 | l_535_;
                                uint _e1374 = l_mut_278_;
                                l_mut_279_ = _e1374;
                                uint l_540_ = a_277_.inner[0];
                                uint l_541_ = a_266_.inner[6];
                                uint l_542_ = l_540_ * l_541_;
                                uint _e1380 = l_mut_279_;
                                l_mut_279_ = _e1380 + l_542_;
                                uint l_543_ = a_277_.inner[1];
                                uint l_544_ = a_266_.inner[5];
                                uint l_545_ = l_543_ * l_544_;
                                uint _e1387 = l_mut_279_;
                                l_mut_279_ = _e1387 + l_545_;
                                uint l_546_ = a_277_.inner[2];
                                uint l_547_ = a_266_.inner[4];
                                uint l_548_ = l_546_ * l_547_;
                                uint _e1394 = l_mut_279_;
                                l_mut_279_ = _e1394 + l_548_;
                                uint l_549_ = a_277_.inner[3];
                                uint l_550_ = a_266_.inner[3];
                                uint l_551_ = l_549_ * l_550_;
                                uint _e1401 = l_mut_279_;
                                l_mut_279_ = _e1401 + l_551_;
                                uint l_552_ = a_277_.inner[4];
                                uint l_553_ = a_266_.inner[2];
                                uint l_554_ = l_552_ * l_553_;
                                uint _e1408 = l_mut_279_;
                                l_mut_279_ = _e1408 + l_554_;
                                uint l_555_ = a_277_.inner[5];
                                uint l_556_ = a_266_.inner[1];
                                uint l_557_ = l_555_ * l_556_;
                                uint _e1415 = l_mut_279_;
                                l_mut_279_ = _e1415 + l_557_;
                                uint l_558_ = a_277_.inner[6];
                                uint l_559_ = a_266_.inner[0];
                                uint l_560_ = l_558_ * l_559_;
                                uint _e1422 = l_mut_279_;
                                l_mut_279_ = _e1422 + l_560_;
                                uint _e1424 = l_mut_279_;
                                uint l_561_ = naga_mod(_e1424, 58u);
                                uint _e1427 = l_mut_279_;
                                uint l_562_ = naga_div(_e1427, 58u);
                                l_mut_278_ = l_562_;
                                uint l_563_ = a_277_.inner[6];
                                ulong l_564_ = static_cast<ulong>(l_563_);
                                ulong l_565_ = 1uL << static_cast<uint>(as_type<ulong>(l_564_));
                                ulong l_566_ = static_cast<ulong>(l_561_);
                                ulong l_567_ = 1uL << static_cast<uint>(as_type<ulong>(l_566_));
                                ulong l_568_ = l_565_ | l_567_;
                                bool l_569_ = l_563_ == l_561_;
                                ulong _e1444 = l_mut_86_;
                                ulong l_570_ = _e1444 & l_568_;
                                bool l_571_ = l_570_ != 0uL;
                                if (!(l_569_)) {
                                    local_8 = l_571_;
                                } else {
                                    local_8 = true;
                                }
                                bool l_572_ = local_8;
                                if (l_572_) {
                                    l_mut_404_ = false;
                                }
                                ulong _e1454 = l_mut_86_;
                                l_mut_86_ = _e1454 | l_568_;
                                uint _e1456 = l_mut_278_;
                                l_mut_279_ = _e1456;
                                uint l_573_ = a_277_.inner[0];
                                uint l_574_ = a_266_.inner[7];
                                uint l_575_ = l_573_ * l_574_;
                                uint _e1462 = l_mut_279_;
                                l_mut_279_ = _e1462 + l_575_;
                                uint l_576_ = a_277_.inner[1];
                                uint l_577_ = a_266_.inner[6];
                                uint l_578_ = l_576_ * l_577_;
                                uint _e1469 = l_mut_279_;
                                l_mut_279_ = _e1469 + l_578_;
                                uint l_579_ = a_277_.inner[2];
                                uint l_580_ = a_266_.inner[5];
                                uint l_581_ = l_579_ * l_580_;
                                uint _e1476 = l_mut_279_;
                                l_mut_279_ = _e1476 + l_581_;
                                uint l_582_ = a_277_.inner[3];
                                uint l_583_ = a_266_.inner[4];
                                uint l_584_ = l_582_ * l_583_;
                                uint _e1483 = l_mut_279_;
                                l_mut_279_ = _e1483 + l_584_;
                                uint l_585_ = a_277_.inner[4];
                                uint l_586_ = a_266_.inner[3];
                                uint l_587_ = l_585_ * l_586_;
                                uint _e1490 = l_mut_279_;
                                l_mut_279_ = _e1490 + l_587_;
                                uint l_588_ = a_277_.inner[5];
                                uint l_589_ = a_266_.inner[2];
                                uint l_590_ = l_588_ * l_589_;
                                uint _e1497 = l_mut_279_;
                                l_mut_279_ = _e1497 + l_590_;
                                uint l_591_ = a_277_.inner[6];
                                uint l_592_ = a_266_.inner[1];
                                uint l_593_ = l_591_ * l_592_;
                                uint _e1504 = l_mut_279_;
                                l_mut_279_ = _e1504 + l_593_;
                                uint l_594_ = a_277_.inner[7];
                                uint l_595_ = a_266_.inner[0];
                                uint l_596_ = l_594_ * l_595_;
                                uint _e1511 = l_mut_279_;
                                l_mut_279_ = _e1511 + l_596_;
                                uint _e1513 = l_mut_279_;
                                uint l_597_ = naga_mod(_e1513, 58u);
                                uint _e1516 = l_mut_279_;
                                uint l_598_ = naga_div(_e1516, 58u);
                                l_mut_278_ = l_598_;
                                uint l_599_ = a_277_.inner[7];
                                ulong l_600_ = static_cast<ulong>(l_599_);
                                ulong l_601_ = 1uL << static_cast<uint>(as_type<ulong>(l_600_));
                                ulong l_602_ = static_cast<ulong>(l_597_);
                                ulong l_603_ = 1uL << static_cast<uint>(as_type<ulong>(l_602_));
                                ulong l_604_ = l_601_ | l_603_;
                                bool l_605_ = l_599_ == l_597_;
                                ulong _e1533 = l_mut_86_;
                                ulong l_606_ = _e1533 & l_604_;
                                bool l_607_ = l_606_ != 0uL;
                                if (!(l_605_)) {
                                    local_9 = l_607_;
                                } else {
                                    local_9 = true;
                                }
                                bool l_608_ = local_9;
                                if (l_608_) {
                                    l_mut_404_ = false;
                                }
                                ulong _e1543 = l_mut_86_;
                                l_mut_86_ = _e1543 | l_604_;
                                bool _e1545 = l_mut_404_;
                                if (_e1545) {
                                    l_mut_245_ = 1u;
                                }
                            }
                            uint _e1547 = l_mut_245_;
                            uint unnamed_2 = metal::simd_prefix_exclusive_sum(_e1547);
                            uint _e1549 = l_mut_245_;
                            uint unnamed_3 = metal::simd_sum(_e1549);
                            bool l_611_ = subgroup_invocation_id == 0u;
                            if (l_611_) {
                                shared_memory_0_.inner[l_239_] = unnamed_3;
                            }
                            metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
                            l_mut_279_ = 0u;
                            l_mut_278_ = 0u;
                            l_mut_271_ = 0u;
                            uint2 loop_bound_8 = uint2(4294967295u);
                            while(true) {
                                if (metal::all(loop_bound_8 == uint2(0u))) { break; }
                                loop_bound_8 -= uint2(loop_bound_8.y == 0u, 1u);
                                uint _e1558 = l_mut_271_;
                                bool l_612_ = _e1558 < l_240_;
                                bool l_613_ = !(l_612_);
                                if (l_613_) {
                                    break;
                                }
                                uint _e1562 = l_mut_271_;
                                uint l_614_ = shared_memory_0_.inner[_e1562];
                                uint _e1565 = l_mut_271_;
                                bool l_615_ = _e1565 < l_239_;
                                if (l_615_) {
                                    uint _e1567 = l_mut_279_;
                                    l_mut_279_ = _e1567 + l_614_;
                                }
                                uint _e1569 = l_mut_278_;
                                l_mut_278_ = _e1569 + l_614_;
                                uint _e1571 = l_mut_271_;
                                l_mut_271_ = _e1571 + 1u;
                            }
                            bool l_616_ = local_invocation_id.x == 0u;
                            uint _e1577 = l_mut_278_;
                            bool l_617_ = _e1577 > 0u;
                            if (l_616_) {
                                local_10 = l_617_;
                            } else {
                                local_10 = false;
                            }
                            bool l_618_ = local_10;
                            if (l_618_) {
                                uint _e1586 = l_mut_278_;
                                uint _e1587 = metal::atomic_fetch_add_explicit(&buffer_11_global[0], _e1586, metal::memory_order_relaxed);
                                shared_memory_9_.inner[0] = _e1587;
                            }
                            metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
                            uint _e1590 = l_mut_245_;
                            bool l_621_ = _e1590 != 0u;
                            if (l_621_) {
                                uint l_622_ = shared_memory_9_.inner[0];
                                uint _e1596 = l_mut_279_;
                                uint l_623_ = l_622_ + _e1596;
                                uint l_624_ = l_623_ + unnamed_2;
                                uint _e1602 = info.scalars_u32_.inner[2];
                                bool l_625_ = l_624_ < _e1602;
                                if (l_625_) {
                                    uint l_626_ = 2u * l_624_;
                                    uint _e1608 = l_mut_246_;
                                    buffer_10_global[l_626_] = _e1608;
                                    uint l_627_ = 2u * l_624_;
                                    uint l_628_ = l_627_ + 1u;
                                    uint _e1615 = l_mut_247_;
                                    buffer_10_global[l_628_] = _e1615;
                                }
                            }
                            uint _e1616 = l_mut_241_;
                            l_mut_241_ = _e1616 + WORKGROUP_SIZE_X;
                        }
                        metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
                        bool l_629_ = local_invocation_id.x == 0u;
                        if (l_629_) {
                            metal::atomic_store_explicit(&shared_memory_8_.inner[0], 0u, metal::memory_order_relaxed);
                        }
                        metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
                    }
                    uint _e1625 = l_mut_101_;
                    l_mut_101_ = _e1625 + 32u;
                }
                uint _e1628 = l_mut_64_;
                l_mut_64_ = _e1628 + 512u;
            }
            uint _e1631 = l_mut_45_;
            l_mut_45_ = _e1631 + 256u;
            metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
        }
        uint _e1634 = l_mut_12_;
        l_mut_12_ = _e1634 + num_workgroups.x;
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    uint l_632_ = metal::atomic_load_explicit(&shared_memory_8_.inner[0], metal::memory_order_relaxed);
    bool l_633_ = l_632_ > 0u;
    if (l_633_) {
        l_mut_279_ = l_632_;
        uint _e1642 = l_mut_279_;
        bool l_634_ = _e1642 > 1024u;
        if (l_634_) {
            l_mut_279_ = 1024u;
        }
        bool l_635_ = local_invocation_id.x == 0u;
        if (l_635_) {
            uint _e1651 = l_mut_279_;
            uint _e1652 = metal::atomic_fetch_add_explicit(&buffer_13_global[0], _e1651, metal::memory_order_relaxed);
        }
        uint l_638_ = naga_div(local_invocation_id.x, subgroup_size);
        uint l_639_ = naga_div(WORKGROUP_SIZE_X, subgroup_size);
        l_mut_278_ = 0u;
        uint2 loop_bound_9 = uint2(4294967295u);
        while(true) {
            if (metal::all(loop_bound_9 == uint2(0u))) { break; }
            loop_bound_9 -= uint2(loop_bound_9.y == 0u, 1u);
            uint _e1658 = l_mut_278_;
            uint _e1659 = l_mut_279_;
            bool l_640_ = _e1658 < _e1659;
            bool l_641_ = !(l_640_);
            if (l_641_) {
                break;
            }
            uint _e1662 = l_mut_278_;
            uint l_642_ = _e1662 + local_invocation_id.x;
            l_mut_271_ = 0u;
            l_mut_267_ = 0u;
            l_mut_247_ = 0u;
            uint _e1668 = l_mut_279_;
            bool l_643_ = l_642_ < _e1668;
            if (l_643_) {
                uint l_644_ = shared_memory_6_.inner[l_642_];
                l_mut_267_ = l_644_;
                uint l_645_ = shared_memory_7_.inner[l_642_];
                l_mut_247_ = l_645_;
                uint _e1677 = l_mut_267_;
                uint l_646_ = 2u * _e1677;
                uint l_647_ = buffer_12_global[l_646_];
                l_mut_86_ = 0uL;
                uint _e1684 = l_mut_267_;
                uint l_648_ = 2u * _e1684;
                uint l_649_ = l_648_ + 1u;
                uint l_650_ = buffer_12_global[l_649_];
                bool l_651_ = l_650_ != 0u;
                if (l_651_) {
                    uint _e1694 = l_mut_267_;
                    uint l_652_ = 2u * _e1694;
                    uint l_653_ = l_652_ + 1u;
                    uint l_654_ = buffer_8_global[l_653_];
                    ulong l_655_ = static_cast<ulong>(l_654_);
                    ulong l_656_ = l_655_ << static_cast<uint>(as_type<ulong>(32uL));
                    uint _e1707 = l_mut_267_;
                    uint l_657_ = 2u * _e1707;
                    uint l_658_ = buffer_8_global[l_657_];
                    ulong l_659_ = static_cast<ulong>(l_658_);
                    ulong l_660_ = l_656_ | l_659_;
                    l_mut_86_ = l_660_;
                }
                uint _e1714 = l_mut_247_;
                l_mut_246_ = _e1714;
                uint _e1715 = l_mut_246_;
                uint l_662_ = naga_mod(_e1715, 58u);
                a_661_.inner[0] = l_662_;
                uint _e1719 = l_mut_246_;
                l_mut_246_ = naga_div(_e1719, 58u);
                uint _e1722 = l_mut_246_;
                uint l_663_ = naga_mod(_e1722, 58u);
                a_661_.inner[1] = l_663_;
                uint _e1726 = l_mut_246_;
                l_mut_246_ = naga_div(_e1726, 58u);
                uint _e1729 = l_mut_246_;
                uint l_664_ = naga_mod(_e1729, 58u);
                a_661_.inner[2] = l_664_;
                uint _e1733 = l_mut_246_;
                l_mut_246_ = naga_div(_e1733, 58u);
                l_mut_245_ = l_647_;
                uint _e1736 = l_mut_245_;
                uint l_665_ = naga_mod(_e1736, 58u);
                a_661_.inner[3] = l_665_;
                uint _e1740 = l_mut_245_;
                l_mut_245_ = naga_div(_e1740, 58u);
                uint _e1743 = l_mut_245_;
                uint l_666_ = naga_mod(_e1743, 58u);
                a_661_.inner[4] = l_666_;
                uint _e1747 = l_mut_245_;
                l_mut_245_ = naga_div(_e1747, 58u);
                uint _e1750 = l_mut_245_;
                uint l_667_ = naga_mod(_e1750, 58u);
                a_661_.inner[5] = l_667_;
                uint _e1754 = l_mut_245_;
                l_mut_245_ = naga_div(_e1754, 58u);
                uint _e1757 = l_mut_245_;
                uint l_668_ = naga_mod(_e1757, 58u);
                a_661_.inner[6] = l_668_;
                uint _e1761 = l_mut_245_;
                l_mut_245_ = naga_div(_e1761, 58u);
                uint _e1764 = l_mut_245_;
                uint l_669_ = naga_mod(_e1764, 58u);
                a_661_.inner[7] = l_669_;
                uint _e1768 = l_mut_245_;
                l_mut_245_ = naga_div(_e1768, 58u);
                l_mut_241_ = 0u;
                uint _e1772 = l_mut_241_;
                l_mut_180_ = _e1772;
                uint l_671_ = a_661_.inner[0];
                uint l_672_ = a_661_.inner[0];
                uint l_673_ = l_671_ * l_672_;
                uint _e1778 = l_mut_180_;
                l_mut_180_ = _e1778 + l_673_;
                uint _e1780 = l_mut_180_;
                uint l_674_ = naga_mod(_e1780, 58u);
                a_670_.inner[0] = l_674_;
                uint _e1784 = l_mut_180_;
                uint l_675_ = naga_div(_e1784, 58u);
                l_mut_241_ = l_675_;
                uint _e1787 = l_mut_241_;
                l_mut_180_ = _e1787;
                uint l_676_ = a_661_.inner[0];
                uint l_677_ = a_661_.inner[1];
                uint l_678_ = l_676_ * l_677_;
                uint _e1793 = l_mut_180_;
                l_mut_180_ = _e1793 + l_678_;
                uint l_679_ = a_661_.inner[1];
                uint l_680_ = a_661_.inner[0];
                uint l_681_ = l_679_ * l_680_;
                uint _e1800 = l_mut_180_;
                l_mut_180_ = _e1800 + l_681_;
                uint _e1802 = l_mut_180_;
                uint l_682_ = naga_mod(_e1802, 58u);
                a_670_.inner[1] = l_682_;
                uint _e1806 = l_mut_180_;
                uint l_683_ = naga_div(_e1806, 58u);
                l_mut_241_ = l_683_;
                uint _e1809 = l_mut_241_;
                l_mut_180_ = _e1809;
                uint l_684_ = a_661_.inner[0];
                uint l_685_ = a_661_.inner[2];
                uint l_686_ = l_684_ * l_685_;
                uint _e1815 = l_mut_180_;
                l_mut_180_ = _e1815 + l_686_;
                uint l_687_ = a_661_.inner[1];
                uint l_688_ = a_661_.inner[1];
                uint l_689_ = l_687_ * l_688_;
                uint _e1822 = l_mut_180_;
                l_mut_180_ = _e1822 + l_689_;
                uint l_690_ = a_661_.inner[2];
                uint l_691_ = a_661_.inner[0];
                uint l_692_ = l_690_ * l_691_;
                uint _e1829 = l_mut_180_;
                l_mut_180_ = _e1829 + l_692_;
                uint _e1831 = l_mut_180_;
                uint l_693_ = naga_mod(_e1831, 58u);
                a_670_.inner[2] = l_693_;
                uint _e1835 = l_mut_180_;
                uint l_694_ = naga_div(_e1835, 58u);
                l_mut_241_ = l_694_;
                uint _e1838 = l_mut_241_;
                l_mut_180_ = _e1838;
                uint l_695_ = a_661_.inner[0];
                uint l_696_ = a_661_.inner[3];
                uint l_697_ = l_695_ * l_696_;
                uint _e1844 = l_mut_180_;
                l_mut_180_ = _e1844 + l_697_;
                uint l_698_ = a_661_.inner[1];
                uint l_699_ = a_661_.inner[2];
                uint l_700_ = l_698_ * l_699_;
                uint _e1851 = l_mut_180_;
                l_mut_180_ = _e1851 + l_700_;
                uint l_701_ = a_661_.inner[2];
                uint l_702_ = a_661_.inner[1];
                uint l_703_ = l_701_ * l_702_;
                uint _e1858 = l_mut_180_;
                l_mut_180_ = _e1858 + l_703_;
                uint l_704_ = a_661_.inner[3];
                uint l_705_ = a_661_.inner[0];
                uint l_706_ = l_704_ * l_705_;
                uint _e1865 = l_mut_180_;
                l_mut_180_ = _e1865 + l_706_;
                uint _e1867 = l_mut_180_;
                uint l_707_ = naga_mod(_e1867, 58u);
                a_670_.inner[3] = l_707_;
                uint _e1871 = l_mut_180_;
                uint l_708_ = naga_div(_e1871, 58u);
                l_mut_241_ = l_708_;
                uint _e1874 = l_mut_241_;
                l_mut_180_ = _e1874;
                uint l_709_ = a_661_.inner[0];
                uint l_710_ = a_661_.inner[4];
                uint l_711_ = l_709_ * l_710_;
                uint _e1880 = l_mut_180_;
                l_mut_180_ = _e1880 + l_711_;
                uint l_712_ = a_661_.inner[1];
                uint l_713_ = a_661_.inner[3];
                uint l_714_ = l_712_ * l_713_;
                uint _e1887 = l_mut_180_;
                l_mut_180_ = _e1887 + l_714_;
                uint l_715_ = a_661_.inner[2];
                uint l_716_ = a_661_.inner[2];
                uint l_717_ = l_715_ * l_716_;
                uint _e1894 = l_mut_180_;
                l_mut_180_ = _e1894 + l_717_;
                uint l_718_ = a_661_.inner[3];
                uint l_719_ = a_661_.inner[1];
                uint l_720_ = l_718_ * l_719_;
                uint _e1901 = l_mut_180_;
                l_mut_180_ = _e1901 + l_720_;
                uint l_721_ = a_661_.inner[4];
                uint l_722_ = a_661_.inner[0];
                uint l_723_ = l_721_ * l_722_;
                uint _e1908 = l_mut_180_;
                l_mut_180_ = _e1908 + l_723_;
                uint _e1910 = l_mut_180_;
                uint l_724_ = naga_mod(_e1910, 58u);
                a_670_.inner[4] = l_724_;
                uint _e1914 = l_mut_180_;
                uint l_725_ = naga_div(_e1914, 58u);
                l_mut_241_ = l_725_;
                uint _e1917 = l_mut_241_;
                l_mut_180_ = _e1917;
                uint l_726_ = a_661_.inner[0];
                uint l_727_ = a_661_.inner[5];
                uint l_728_ = l_726_ * l_727_;
                uint _e1923 = l_mut_180_;
                l_mut_180_ = _e1923 + l_728_;
                uint l_729_ = a_661_.inner[1];
                uint l_730_ = a_661_.inner[4];
                uint l_731_ = l_729_ * l_730_;
                uint _e1930 = l_mut_180_;
                l_mut_180_ = _e1930 + l_731_;
                uint l_732_ = a_661_.inner[2];
                uint l_733_ = a_661_.inner[3];
                uint l_734_ = l_732_ * l_733_;
                uint _e1937 = l_mut_180_;
                l_mut_180_ = _e1937 + l_734_;
                uint l_735_ = a_661_.inner[3];
                uint l_736_ = a_661_.inner[2];
                uint l_737_ = l_735_ * l_736_;
                uint _e1944 = l_mut_180_;
                l_mut_180_ = _e1944 + l_737_;
                uint l_738_ = a_661_.inner[4];
                uint l_739_ = a_661_.inner[1];
                uint l_740_ = l_738_ * l_739_;
                uint _e1951 = l_mut_180_;
                l_mut_180_ = _e1951 + l_740_;
                uint l_741_ = a_661_.inner[5];
                uint l_742_ = a_661_.inner[0];
                uint l_743_ = l_741_ * l_742_;
                uint _e1958 = l_mut_180_;
                l_mut_180_ = _e1958 + l_743_;
                uint _e1960 = l_mut_180_;
                uint l_744_ = naga_mod(_e1960, 58u);
                a_670_.inner[5] = l_744_;
                uint _e1964 = l_mut_180_;
                uint l_745_ = naga_div(_e1964, 58u);
                l_mut_241_ = l_745_;
                uint _e1967 = l_mut_241_;
                l_mut_180_ = _e1967;
                uint l_746_ = a_661_.inner[0];
                uint l_747_ = a_661_.inner[6];
                uint l_748_ = l_746_ * l_747_;
                uint _e1973 = l_mut_180_;
                l_mut_180_ = _e1973 + l_748_;
                uint l_749_ = a_661_.inner[1];
                uint l_750_ = a_661_.inner[5];
                uint l_751_ = l_749_ * l_750_;
                uint _e1980 = l_mut_180_;
                l_mut_180_ = _e1980 + l_751_;
                uint l_752_ = a_661_.inner[2];
                uint l_753_ = a_661_.inner[4];
                uint l_754_ = l_752_ * l_753_;
                uint _e1987 = l_mut_180_;
                l_mut_180_ = _e1987 + l_754_;
                uint l_755_ = a_661_.inner[3];
                uint l_756_ = a_661_.inner[3];
                uint l_757_ = l_755_ * l_756_;
                uint _e1994 = l_mut_180_;
                l_mut_180_ = _e1994 + l_757_;
                uint l_758_ = a_661_.inner[4];
                uint l_759_ = a_661_.inner[2];
                uint l_760_ = l_758_ * l_759_;
                uint _e2001 = l_mut_180_;
                l_mut_180_ = _e2001 + l_760_;
                uint l_761_ = a_661_.inner[5];
                uint l_762_ = a_661_.inner[1];
                uint l_763_ = l_761_ * l_762_;
                uint _e2008 = l_mut_180_;
                l_mut_180_ = _e2008 + l_763_;
                uint l_764_ = a_661_.inner[6];
                uint l_765_ = a_661_.inner[0];
                uint l_766_ = l_764_ * l_765_;
                uint _e2015 = l_mut_180_;
                l_mut_180_ = _e2015 + l_766_;
                uint _e2017 = l_mut_180_;
                uint l_767_ = naga_mod(_e2017, 58u);
                a_670_.inner[6] = l_767_;
                uint _e2021 = l_mut_180_;
                uint l_768_ = naga_div(_e2021, 58u);
                l_mut_241_ = l_768_;
                uint _e2024 = l_mut_241_;
                l_mut_180_ = _e2024;
                uint l_769_ = a_661_.inner[0];
                uint l_770_ = a_661_.inner[7];
                uint l_771_ = l_769_ * l_770_;
                uint _e2030 = l_mut_180_;
                l_mut_180_ = _e2030 + l_771_;
                uint l_772_ = a_661_.inner[1];
                uint l_773_ = a_661_.inner[6];
                uint l_774_ = l_772_ * l_773_;
                uint _e2037 = l_mut_180_;
                l_mut_180_ = _e2037 + l_774_;
                uint l_775_ = a_661_.inner[2];
                uint l_776_ = a_661_.inner[5];
                uint l_777_ = l_775_ * l_776_;
                uint _e2044 = l_mut_180_;
                l_mut_180_ = _e2044 + l_777_;
                uint l_778_ = a_661_.inner[3];
                uint l_779_ = a_661_.inner[4];
                uint l_780_ = l_778_ * l_779_;
                uint _e2051 = l_mut_180_;
                l_mut_180_ = _e2051 + l_780_;
                uint l_781_ = a_661_.inner[4];
                uint l_782_ = a_661_.inner[3];
                uint l_783_ = l_781_ * l_782_;
                uint _e2058 = l_mut_180_;
                l_mut_180_ = _e2058 + l_783_;
                uint l_784_ = a_661_.inner[5];
                uint l_785_ = a_661_.inner[2];
                uint l_786_ = l_784_ * l_785_;
                uint _e2065 = l_mut_180_;
                l_mut_180_ = _e2065 + l_786_;
                uint l_787_ = a_661_.inner[6];
                uint l_788_ = a_661_.inner[1];
                uint l_789_ = l_787_ * l_788_;
                uint _e2072 = l_mut_180_;
                l_mut_180_ = _e2072 + l_789_;
                uint l_790_ = a_661_.inner[7];
                uint l_791_ = a_661_.inner[0];
                uint l_792_ = l_790_ * l_791_;
                uint _e2079 = l_mut_180_;
                l_mut_180_ = _e2079 + l_792_;
                uint _e2081 = l_mut_180_;
                uint l_793_ = naga_mod(_e2081, 58u);
                a_670_.inner[7] = l_793_;
                uint _e2085 = l_mut_180_;
                uint l_794_ = naga_div(_e2085, 58u);
                l_mut_241_ = l_794_;
                l_mut_404_ = true;
                l_mut_241_ = 0u;
                uint _e2090 = l_mut_241_;
                l_mut_180_ = _e2090;
                uint l_795_ = a_670_.inner[0];
                uint l_796_ = a_661_.inner[0];
                uint l_797_ = l_795_ * l_796_;
                uint _e2096 = l_mut_180_;
                l_mut_180_ = _e2096 + l_797_;
                uint _e2098 = l_mut_180_;
                uint l_798_ = naga_mod(_e2098, 58u);
                uint _e2101 = l_mut_180_;
                uint l_799_ = naga_div(_e2101, 58u);
                l_mut_241_ = l_799_;
                uint l_800_ = a_670_.inner[0];
                ulong l_801_ = static_cast<ulong>(l_800_);
                ulong l_802_ = 1uL << static_cast<uint>(as_type<ulong>(l_801_));
                ulong l_803_ = static_cast<ulong>(l_798_);
                ulong l_804_ = 1uL << static_cast<uint>(as_type<ulong>(l_803_));
                ulong l_805_ = l_802_ | l_804_;
                bool l_806_ = l_800_ == l_798_;
                ulong _e2118 = l_mut_86_;
                ulong l_807_ = _e2118 & l_805_;
                bool l_808_ = l_807_ != 0uL;
                if (!(l_806_)) {
                    local_11 = l_808_;
                } else {
                    local_11 = true;
                }
                bool l_809_ = local_11;
                if (l_809_) {
                    l_mut_404_ = false;
                }
                ulong _e2128 = l_mut_86_;
                l_mut_86_ = _e2128 | l_805_;
                uint _e2130 = l_mut_241_;
                l_mut_180_ = _e2130;
                uint l_810_ = a_670_.inner[0];
                uint l_811_ = a_661_.inner[1];
                uint l_812_ = l_810_ * l_811_;
                uint _e2136 = l_mut_180_;
                l_mut_180_ = _e2136 + l_812_;
                uint l_813_ = a_670_.inner[1];
                uint l_814_ = a_661_.inner[0];
                uint l_815_ = l_813_ * l_814_;
                uint _e2143 = l_mut_180_;
                l_mut_180_ = _e2143 + l_815_;
                uint _e2145 = l_mut_180_;
                uint l_816_ = naga_mod(_e2145, 58u);
                uint _e2148 = l_mut_180_;
                uint l_817_ = naga_div(_e2148, 58u);
                l_mut_241_ = l_817_;
                uint l_818_ = a_670_.inner[1];
                ulong l_819_ = static_cast<ulong>(l_818_);
                ulong l_820_ = 1uL << static_cast<uint>(as_type<ulong>(l_819_));
                ulong l_821_ = static_cast<ulong>(l_816_);
                ulong l_822_ = 1uL << static_cast<uint>(as_type<ulong>(l_821_));
                ulong l_823_ = l_820_ | l_822_;
                bool l_824_ = l_818_ == l_816_;
                ulong _e2165 = l_mut_86_;
                ulong l_825_ = _e2165 & l_823_;
                bool l_826_ = l_825_ != 0uL;
                if (!(l_824_)) {
                    local_12 = l_826_;
                } else {
                    local_12 = true;
                }
                bool l_827_ = local_12;
                if (l_827_) {
                    l_mut_404_ = false;
                }
                ulong _e2175 = l_mut_86_;
                l_mut_86_ = _e2175 | l_823_;
                uint _e2177 = l_mut_241_;
                l_mut_180_ = _e2177;
                uint l_828_ = a_670_.inner[0];
                uint l_829_ = a_661_.inner[2];
                uint l_830_ = l_828_ * l_829_;
                uint _e2183 = l_mut_180_;
                l_mut_180_ = _e2183 + l_830_;
                uint l_831_ = a_670_.inner[1];
                uint l_832_ = a_661_.inner[1];
                uint l_833_ = l_831_ * l_832_;
                uint _e2190 = l_mut_180_;
                l_mut_180_ = _e2190 + l_833_;
                uint l_834_ = a_670_.inner[2];
                uint l_835_ = a_661_.inner[0];
                uint l_836_ = l_834_ * l_835_;
                uint _e2197 = l_mut_180_;
                l_mut_180_ = _e2197 + l_836_;
                uint _e2199 = l_mut_180_;
                uint l_837_ = naga_mod(_e2199, 58u);
                uint _e2202 = l_mut_180_;
                uint l_838_ = naga_div(_e2202, 58u);
                l_mut_241_ = l_838_;
                uint l_839_ = a_670_.inner[2];
                ulong l_840_ = static_cast<ulong>(l_839_);
                ulong l_841_ = 1uL << static_cast<uint>(as_type<ulong>(l_840_));
                ulong l_842_ = static_cast<ulong>(l_837_);
                ulong l_843_ = 1uL << static_cast<uint>(as_type<ulong>(l_842_));
                ulong l_844_ = l_841_ | l_843_;
                bool l_845_ = l_839_ == l_837_;
                ulong _e2219 = l_mut_86_;
                ulong l_846_ = _e2219 & l_844_;
                bool l_847_ = l_846_ != 0uL;
                if (!(l_845_)) {
                    local_13 = l_847_;
                } else {
                    local_13 = true;
                }
                bool l_848_ = local_13;
                if (l_848_) {
                    l_mut_404_ = false;
                }
                ulong _e2229 = l_mut_86_;
                l_mut_86_ = _e2229 | l_844_;
                uint _e2231 = l_mut_241_;
                l_mut_180_ = _e2231;
                uint l_849_ = a_670_.inner[0];
                uint l_850_ = a_661_.inner[3];
                uint l_851_ = l_849_ * l_850_;
                uint _e2237 = l_mut_180_;
                l_mut_180_ = _e2237 + l_851_;
                uint l_852_ = a_670_.inner[1];
                uint l_853_ = a_661_.inner[2];
                uint l_854_ = l_852_ * l_853_;
                uint _e2244 = l_mut_180_;
                l_mut_180_ = _e2244 + l_854_;
                uint l_855_ = a_670_.inner[2];
                uint l_856_ = a_661_.inner[1];
                uint l_857_ = l_855_ * l_856_;
                uint _e2251 = l_mut_180_;
                l_mut_180_ = _e2251 + l_857_;
                uint l_858_ = a_670_.inner[3];
                uint l_859_ = a_661_.inner[0];
                uint l_860_ = l_858_ * l_859_;
                uint _e2258 = l_mut_180_;
                l_mut_180_ = _e2258 + l_860_;
                uint _e2260 = l_mut_180_;
                uint l_861_ = naga_mod(_e2260, 58u);
                uint _e2263 = l_mut_180_;
                uint l_862_ = naga_div(_e2263, 58u);
                l_mut_241_ = l_862_;
                uint l_863_ = a_670_.inner[3];
                ulong l_864_ = static_cast<ulong>(l_863_);
                ulong l_865_ = 1uL << static_cast<uint>(as_type<ulong>(l_864_));
                ulong l_866_ = static_cast<ulong>(l_861_);
                ulong l_867_ = 1uL << static_cast<uint>(as_type<ulong>(l_866_));
                ulong l_868_ = l_865_ | l_867_;
                bool l_869_ = l_863_ == l_861_;
                ulong _e2280 = l_mut_86_;
                ulong l_870_ = _e2280 & l_868_;
                bool l_871_ = l_870_ != 0uL;
                if (!(l_869_)) {
                    local_14 = l_871_;
                } else {
                    local_14 = true;
                }
                bool l_872_ = local_14;
                if (l_872_) {
                    l_mut_404_ = false;
                }
                ulong _e2290 = l_mut_86_;
                l_mut_86_ = _e2290 | l_868_;
                uint _e2292 = l_mut_241_;
                l_mut_180_ = _e2292;
                uint l_873_ = a_670_.inner[0];
                uint l_874_ = a_661_.inner[4];
                uint l_875_ = l_873_ * l_874_;
                uint _e2298 = l_mut_180_;
                l_mut_180_ = _e2298 + l_875_;
                uint l_876_ = a_670_.inner[1];
                uint l_877_ = a_661_.inner[3];
                uint l_878_ = l_876_ * l_877_;
                uint _e2305 = l_mut_180_;
                l_mut_180_ = _e2305 + l_878_;
                uint l_879_ = a_670_.inner[2];
                uint l_880_ = a_661_.inner[2];
                uint l_881_ = l_879_ * l_880_;
                uint _e2312 = l_mut_180_;
                l_mut_180_ = _e2312 + l_881_;
                uint l_882_ = a_670_.inner[3];
                uint l_883_ = a_661_.inner[1];
                uint l_884_ = l_882_ * l_883_;
                uint _e2319 = l_mut_180_;
                l_mut_180_ = _e2319 + l_884_;
                uint l_885_ = a_670_.inner[4];
                uint l_886_ = a_661_.inner[0];
                uint l_887_ = l_885_ * l_886_;
                uint _e2326 = l_mut_180_;
                l_mut_180_ = _e2326 + l_887_;
                uint _e2328 = l_mut_180_;
                uint l_888_ = naga_mod(_e2328, 58u);
                uint _e2331 = l_mut_180_;
                uint l_889_ = naga_div(_e2331, 58u);
                l_mut_241_ = l_889_;
                uint l_890_ = a_670_.inner[4];
                ulong l_891_ = static_cast<ulong>(l_890_);
                ulong l_892_ = 1uL << static_cast<uint>(as_type<ulong>(l_891_));
                ulong l_893_ = static_cast<ulong>(l_888_);
                ulong l_894_ = 1uL << static_cast<uint>(as_type<ulong>(l_893_));
                ulong l_895_ = l_892_ | l_894_;
                bool l_896_ = l_890_ == l_888_;
                ulong _e2348 = l_mut_86_;
                ulong l_897_ = _e2348 & l_895_;
                bool l_898_ = l_897_ != 0uL;
                if (!(l_896_)) {
                    local_15 = l_898_;
                } else {
                    local_15 = true;
                }
                bool l_899_ = local_15;
                if (l_899_) {
                    l_mut_404_ = false;
                }
                ulong _e2358 = l_mut_86_;
                l_mut_86_ = _e2358 | l_895_;
                uint _e2360 = l_mut_241_;
                l_mut_180_ = _e2360;
                uint l_900_ = a_670_.inner[0];
                uint l_901_ = a_661_.inner[5];
                uint l_902_ = l_900_ * l_901_;
                uint _e2366 = l_mut_180_;
                l_mut_180_ = _e2366 + l_902_;
                uint l_903_ = a_670_.inner[1];
                uint l_904_ = a_661_.inner[4];
                uint l_905_ = l_903_ * l_904_;
                uint _e2373 = l_mut_180_;
                l_mut_180_ = _e2373 + l_905_;
                uint l_906_ = a_670_.inner[2];
                uint l_907_ = a_661_.inner[3];
                uint l_908_ = l_906_ * l_907_;
                uint _e2380 = l_mut_180_;
                l_mut_180_ = _e2380 + l_908_;
                uint l_909_ = a_670_.inner[3];
                uint l_910_ = a_661_.inner[2];
                uint l_911_ = l_909_ * l_910_;
                uint _e2387 = l_mut_180_;
                l_mut_180_ = _e2387 + l_911_;
                uint l_912_ = a_670_.inner[4];
                uint l_913_ = a_661_.inner[1];
                uint l_914_ = l_912_ * l_913_;
                uint _e2394 = l_mut_180_;
                l_mut_180_ = _e2394 + l_914_;
                uint l_915_ = a_670_.inner[5];
                uint l_916_ = a_661_.inner[0];
                uint l_917_ = l_915_ * l_916_;
                uint _e2401 = l_mut_180_;
                l_mut_180_ = _e2401 + l_917_;
                uint _e2403 = l_mut_180_;
                uint l_918_ = naga_mod(_e2403, 58u);
                uint _e2406 = l_mut_180_;
                uint l_919_ = naga_div(_e2406, 58u);
                l_mut_241_ = l_919_;
                uint l_920_ = a_670_.inner[5];
                ulong l_921_ = static_cast<ulong>(l_920_);
                ulong l_922_ = 1uL << static_cast<uint>(as_type<ulong>(l_921_));
                ulong l_923_ = static_cast<ulong>(l_918_);
                ulong l_924_ = 1uL << static_cast<uint>(as_type<ulong>(l_923_));
                ulong l_925_ = l_922_ | l_924_;
                bool l_926_ = l_920_ == l_918_;
                ulong _e2423 = l_mut_86_;
                ulong l_927_ = _e2423 & l_925_;
                bool l_928_ = l_927_ != 0uL;
                if (!(l_926_)) {
                    local_16 = l_928_;
                } else {
                    local_16 = true;
                }
                bool l_929_ = local_16;
                if (l_929_) {
                    l_mut_404_ = false;
                }
                ulong _e2433 = l_mut_86_;
                l_mut_86_ = _e2433 | l_925_;
                uint _e2435 = l_mut_241_;
                l_mut_180_ = _e2435;
                uint l_930_ = a_670_.inner[0];
                uint l_931_ = a_661_.inner[6];
                uint l_932_ = l_930_ * l_931_;
                uint _e2441 = l_mut_180_;
                l_mut_180_ = _e2441 + l_932_;
                uint l_933_ = a_670_.inner[1];
                uint l_934_ = a_661_.inner[5];
                uint l_935_ = l_933_ * l_934_;
                uint _e2448 = l_mut_180_;
                l_mut_180_ = _e2448 + l_935_;
                uint l_936_ = a_670_.inner[2];
                uint l_937_ = a_661_.inner[4];
                uint l_938_ = l_936_ * l_937_;
                uint _e2455 = l_mut_180_;
                l_mut_180_ = _e2455 + l_938_;
                uint l_939_ = a_670_.inner[3];
                uint l_940_ = a_661_.inner[3];
                uint l_941_ = l_939_ * l_940_;
                uint _e2462 = l_mut_180_;
                l_mut_180_ = _e2462 + l_941_;
                uint l_942_ = a_670_.inner[4];
                uint l_943_ = a_661_.inner[2];
                uint l_944_ = l_942_ * l_943_;
                uint _e2469 = l_mut_180_;
                l_mut_180_ = _e2469 + l_944_;
                uint l_945_ = a_670_.inner[5];
                uint l_946_ = a_661_.inner[1];
                uint l_947_ = l_945_ * l_946_;
                uint _e2476 = l_mut_180_;
                l_mut_180_ = _e2476 + l_947_;
                uint l_948_ = a_670_.inner[6];
                uint l_949_ = a_661_.inner[0];
                uint l_950_ = l_948_ * l_949_;
                uint _e2483 = l_mut_180_;
                l_mut_180_ = _e2483 + l_950_;
                uint _e2485 = l_mut_180_;
                uint l_951_ = naga_mod(_e2485, 58u);
                uint _e2488 = l_mut_180_;
                uint l_952_ = naga_div(_e2488, 58u);
                l_mut_241_ = l_952_;
                uint l_953_ = a_670_.inner[6];
                ulong l_954_ = static_cast<ulong>(l_953_);
                ulong l_955_ = 1uL << static_cast<uint>(as_type<ulong>(l_954_));
                ulong l_956_ = static_cast<ulong>(l_951_);
                ulong l_957_ = 1uL << static_cast<uint>(as_type<ulong>(l_956_));
                ulong l_958_ = l_955_ | l_957_;
                bool l_959_ = l_953_ == l_951_;
                ulong _e2505 = l_mut_86_;
                ulong l_960_ = _e2505 & l_958_;
                bool l_961_ = l_960_ != 0uL;
                if (!(l_959_)) {
                    local_17 = l_961_;
                } else {
                    local_17 = true;
                }
                bool l_962_ = local_17;
                if (l_962_) {
                    l_mut_404_ = false;
                }
                ulong _e2515 = l_mut_86_;
                l_mut_86_ = _e2515 | l_958_;
                uint _e2517 = l_mut_241_;
                l_mut_180_ = _e2517;
                uint l_963_ = a_670_.inner[0];
                uint l_964_ = a_661_.inner[7];
                uint l_965_ = l_963_ * l_964_;
                uint _e2523 = l_mut_180_;
                l_mut_180_ = _e2523 + l_965_;
                uint l_966_ = a_670_.inner[1];
                uint l_967_ = a_661_.inner[6];
                uint l_968_ = l_966_ * l_967_;
                uint _e2530 = l_mut_180_;
                l_mut_180_ = _e2530 + l_968_;
                uint l_969_ = a_670_.inner[2];
                uint l_970_ = a_661_.inner[5];
                uint l_971_ = l_969_ * l_970_;
                uint _e2537 = l_mut_180_;
                l_mut_180_ = _e2537 + l_971_;
                uint l_972_ = a_670_.inner[3];
                uint l_973_ = a_661_.inner[4];
                uint l_974_ = l_972_ * l_973_;
                uint _e2544 = l_mut_180_;
                l_mut_180_ = _e2544 + l_974_;
                uint l_975_ = a_670_.inner[4];
                uint l_976_ = a_661_.inner[3];
                uint l_977_ = l_975_ * l_976_;
                uint _e2551 = l_mut_180_;
                l_mut_180_ = _e2551 + l_977_;
                uint l_978_ = a_670_.inner[5];
                uint l_979_ = a_661_.inner[2];
                uint l_980_ = l_978_ * l_979_;
                uint _e2558 = l_mut_180_;
                l_mut_180_ = _e2558 + l_980_;
                uint l_981_ = a_670_.inner[6];
                uint l_982_ = a_661_.inner[1];
                uint l_983_ = l_981_ * l_982_;
                uint _e2565 = l_mut_180_;
                l_mut_180_ = _e2565 + l_983_;
                uint l_984_ = a_670_.inner[7];
                uint l_985_ = a_661_.inner[0];
                uint l_986_ = l_984_ * l_985_;
                uint _e2572 = l_mut_180_;
                l_mut_180_ = _e2572 + l_986_;
                uint _e2574 = l_mut_180_;
                uint l_987_ = naga_mod(_e2574, 58u);
                uint _e2577 = l_mut_180_;
                uint l_988_ = naga_div(_e2577, 58u);
                l_mut_241_ = l_988_;
                uint l_989_ = a_670_.inner[7];
                ulong l_990_ = static_cast<ulong>(l_989_);
                ulong l_991_ = 1uL << static_cast<uint>(as_type<ulong>(l_990_));
                ulong l_992_ = static_cast<ulong>(l_987_);
                ulong l_993_ = 1uL << static_cast<uint>(as_type<ulong>(l_992_));
                ulong l_994_ = l_991_ | l_993_;
                bool l_995_ = l_989_ == l_987_;
                ulong _e2594 = l_mut_86_;
                ulong l_996_ = _e2594 & l_994_;
                bool l_997_ = l_996_ != 0uL;
                if (!(l_995_)) {
                    local_18 = l_997_;
                } else {
                    local_18 = true;
                }
                bool l_998_ = local_18;
                if (l_998_) {
                    l_mut_404_ = false;
                }
                ulong _e2604 = l_mut_86_;
                l_mut_86_ = _e2604 | l_994_;
                bool _e2606 = l_mut_404_;
                if (_e2606) {
                    l_mut_271_ = 1u;
                }
            }
            uint _e2608 = l_mut_271_;
            uint unnamed_4 = metal::simd_prefix_exclusive_sum(_e2608);
            uint _e2610 = l_mut_271_;
            uint unnamed_5 = metal::simd_sum(_e2610);
            bool l_1001_ = subgroup_invocation_id == 0u;
            if (l_1001_) {
                shared_memory_0_.inner[l_638_] = unnamed_5;
            }
            metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
            l_mut_246_ = 0u;
            l_mut_245_ = 0u;
            l_mut_241_ = 0u;
            uint2 loop_bound_10 = uint2(4294967295u);
            while(true) {
                if (metal::all(loop_bound_10 == uint2(0u))) { break; }
                loop_bound_10 -= uint2(loop_bound_10.y == 0u, 1u);
                uint _e2619 = l_mut_241_;
                bool l_1002_ = _e2619 < l_639_;
                bool l_1003_ = !(l_1002_);
                if (l_1003_) {
                    break;
                }
                uint _e2623 = l_mut_241_;
                uint l_1004_ = shared_memory_0_.inner[_e2623];
                uint _e2626 = l_mut_241_;
                bool l_1005_ = _e2626 < l_638_;
                if (l_1005_) {
                    uint _e2628 = l_mut_246_;
                    l_mut_246_ = _e2628 + l_1004_;
                }
                uint _e2630 = l_mut_245_;
                l_mut_245_ = _e2630 + l_1004_;
                uint _e2632 = l_mut_241_;
                l_mut_241_ = _e2632 + 1u;
            }
            bool l_1006_ = local_invocation_id.x == 0u;
            uint _e2638 = l_mut_245_;
            bool l_1007_ = _e2638 > 0u;
            if (l_1006_) {
                local_19 = l_1007_;
            } else {
                local_19 = false;
            }
            bool l_1008_ = local_19;
            if (l_1008_) {
                uint _e2647 = l_mut_245_;
                uint _e2648 = metal::atomic_fetch_add_explicit(&buffer_11_global[0], _e2647, metal::memory_order_relaxed);
                shared_memory_9_.inner[0] = _e2648;
            }
            metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
            uint _e2651 = l_mut_271_;
            bool l_1011_ = _e2651 != 0u;
            if (l_1011_) {
                uint l_1012_ = shared_memory_9_.inner[0];
                uint _e2657 = l_mut_246_;
                uint l_1013_ = l_1012_ + _e2657;
                uint l_1014_ = l_1013_ + unnamed_4;
                uint _e2663 = info.scalars_u32_.inner[2];
                bool l_1015_ = l_1014_ < _e2663;
                if (l_1015_) {
                    uint l_1016_ = 2u * l_1014_;
                    uint _e2669 = l_mut_267_;
                    buffer_10_global[l_1016_] = _e2669;
                    uint l_1017_ = 2u * l_1014_;
                    uint l_1018_ = l_1017_ + 1u;
                    uint _e2676 = l_mut_247_;
                    buffer_10_global[l_1018_] = _e2676;
                }
            }
            uint _e2677 = l_mut_278_;
            l_mut_278_ = _e2677 + WORKGROUP_SIZE_X;
        }
        metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
        bool l_1019_ = local_invocation_id.x == 0u;
        if (l_1019_) {
            metal::atomic_store_explicit(&shared_memory_8_.inner[0], 0u, metal::memory_order_relaxed);
        }
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    bool l_1021_ = local_invocation_id.x == 0u;
    if (l_1021_) {
        uint _e2692 = metal::atomic_fetch_add_explicit(&buffer_14_global[4], 1u, metal::memory_order_relaxed);
        return;
    } else {
        return;
    }
}
