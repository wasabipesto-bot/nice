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
};

typedef uint type_1[1];
typedef metal::atomic_uint type_3[1];
struct type_4 {
    uint inner[4];
};
struct type_5 {
    uint inner[12];
};
struct info_st {
    type_4 scalars_u32_;
    type_5 static_meta;
};
struct type_6 {
    uint inner[2304];
};
struct type_8 {
    uint inner[3];
};
struct type_9 {
    uint inner[6];
};
constant uint WORKGROUP_SIZE_X = 256u;
constant uint WORKGROUP_SIZE_Y = 1u;
constant uint WORKGROUP_SIZE_Z = 1u;
uint naga_div(uint lhs, uint rhs) {
    return lhs / metal::select(rhs, 1u, rhs == 0u);
}


struct check_kernelInput {
};
kernel void check_kernel(
  metal::uint3 global_id [[thread_position_in_grid]]
, metal::uint3 local_invocation_id [[thread_position_in_threadgroup]]
, metal::uint3 num_workgroups [[threadgroups_per_grid]]
, device type_1 const& buffer_0_global [[user(fake0)]]
, device type_3 const& buffer_1_global [[user(fake0)]]
, device type_1 const& buffer_2_global [[user(fake0)]]
, device type_1& buffer_3_global [[user(fake0)]]
, device type_3& buffer_4_global [[user(fake0)]]
, device type_3& buffer_5_global [[user(fake0)]]
, device info_st const& info [[user(fake0)]]
, threadgroup type_6& shared_memory_0_
, constant _mslBufferSizes& _buffer_sizes [[user(fake0)]]
) {
    if (metal::all(local_invocation_id == metal::uint3(0u))) {
        shared_memory_0_ = {};
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    type_8 a_37_ = {};
    type_9 a_44_ = {};
    bool l_mut_33_ = {};
    int l_mut_160_ = {};
    int l_mut_171_ = {};
    int l_mut_486_ = {};
    ulong l_mut_28_ = {};
    ulong l_mut_34_ = {};
    ulong l_mut_35_ = {};
    ulong l_mut_45_ = {};
    uint l_mut_4_ = {};
    uint l_mut_7_ = {};
    uint l_mut_170_ = {};
    uint l_mut_199_ = {};
    bool local = {};
    bool local_1 = {};
    bool local_2 = {};
    bool local_3 = {};
    uint l_1_ = local_invocation_id.x * 9u;
    uint l_3_ = metal::atomic_load_explicit(&buffer_1_global[0], metal::memory_order_relaxed);
    l_mut_4_ = l_3_;
    uint _e23 = l_mut_4_;
    uint _e27 = info.scalars_u32_.inner[0];
    bool l_5_ = _e23 > _e27;
    if (l_5_) {
        uint _e32 = info.scalars_u32_.inner[0];
        l_mut_4_ = _e32;
    }
    uint l_6_ = num_workgroups.x * WORKGROUP_SIZE_X;
    l_mut_7_ = global_id.x;
    uint2 loop_bound = uint2(4294967295u);
    while(true) {
        if (metal::all(loop_bound == uint2(0u))) { break; }
        loop_bound -= uint2(loop_bound.y == 0u, 1u);
        uint _e37 = l_mut_7_;
        uint _e38 = l_mut_4_;
        bool l_8_ = _e37 < _e38;
        bool l_9_ = !(l_8_);
        if (l_9_) {
            break;
        }
        uint _e42 = l_mut_7_;
        uint l_10_ = 2u * _e42;
        uint l_11_ = buffer_0_global[l_10_];
        uint _e48 = l_mut_7_;
        uint l_12_ = 2u * _e48;
        uint l_13_ = l_12_ + 1u;
        uint l_14_ = buffer_0_global[l_13_];
        uint l_15_ = 2u * l_11_;
        uint l_16_ = buffer_2_global[l_15_];
        ulong l_17_ = static_cast<ulong>(l_16_);
        uint l_18_ = 2u * l_11_;
        uint l_19_ = l_18_ + 1u;
        uint l_20_ = buffer_2_global[l_19_];
        ulong l_21_ = static_cast<ulong>(l_20_);
        uint _e72 = info.scalars_u32_.inner[2];
        ulong l_22_ = static_cast<ulong>(_e72);
        ulong l_23_ = l_17_ * l_22_;
        ulong l_24_ = l_21_ * l_22_;
        ulong l_25_ = l_24_ << static_cast<uint>(as_type<ulong>(32uL));
        ulong l_26_ = l_23_ + l_25_;
        ulong l_27_ = l_24_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_28_ = l_27_;
        bool l_29_ = l_26_ < l_23_;
        if (l_29_) {
            ulong _e86 = l_mut_28_;
            l_mut_28_ = _e86 + 1uL;
        }
        ulong l_30_ = static_cast<ulong>(l_14_);
        ulong l_31_ = l_26_ + l_30_;
        bool l_32_ = l_31_ < l_26_;
        if (l_32_) {
            ulong _e92 = l_mut_28_;
            l_mut_28_ = _e92 + 1uL;
        }
        l_mut_33_ = true;
        l_mut_34_ = 0uL;
        l_mut_35_ = 0uL;
        bool _e98 = l_mut_33_;
        if (_e98) {
            local = true;
        } else {
            local = false;
        }
        bool l_36_ = local;
        if (l_36_) {
            ulong l_38_ = l_31_ >> static_cast<uint>(as_type<ulong>(0uL));
            uint l_39_ = static_cast<uint>(as_type<ulong>(l_38_));
            a_37_.inner[0] = l_39_;
            ulong l_40_ = l_31_ >> static_cast<uint>(as_type<ulong>(32uL));
            uint l_41_ = static_cast<uint>(as_type<ulong>(l_40_));
            a_37_.inner[1] = l_41_;
            ulong _e118 = l_mut_28_;
            ulong l_42_ = _e118 >> static_cast<uint>(as_type<ulong>(0uL));
            uint l_43_ = static_cast<uint>(as_type<ulong>(l_42_));
            a_37_.inner[2] = l_43_;
            a_44_.inner[0] = 0u;
            a_44_.inner[1] = 0u;
            a_44_.inner[2] = 0u;
            a_44_.inner[3] = 0u;
            a_44_.inner[4] = 0u;
            a_44_.inner[5] = 0u;
            l_mut_45_ = 0uL;
            uint l_46_ = a_37_.inner[0];
            ulong l_47_ = static_cast<ulong>(l_46_);
            uint l_48_ = a_37_.inner[0];
            ulong l_49_ = static_cast<ulong>(l_48_);
            ulong l_50_ = l_47_ * l_49_;
            uint l_51_ = a_44_.inner[0];
            ulong l_52_ = static_cast<ulong>(l_51_);
            ulong l_53_ = l_50_ + l_52_;
            ulong _e150 = l_mut_45_;
            ulong l_54_ = l_53_ + _e150;
            uint l_55_ = static_cast<uint>(as_type<ulong>(l_54_));
            a_44_.inner[0] = l_55_;
            ulong l_56_ = l_54_ >> static_cast<uint>(as_type<ulong>(32uL));
            l_mut_45_ = l_56_;
            uint l_57_ = a_37_.inner[0];
            ulong l_58_ = static_cast<ulong>(l_57_);
            uint l_59_ = a_37_.inner[1];
            ulong l_60_ = static_cast<ulong>(l_59_);
            ulong l_61_ = l_58_ * l_60_;
            uint l_62_ = a_44_.inner[1];
            ulong l_63_ = static_cast<ulong>(l_62_);
            ulong l_64_ = l_61_ + l_63_;
            ulong _e170 = l_mut_45_;
            ulong l_65_ = l_64_ + _e170;
            uint l_66_ = static_cast<uint>(as_type<ulong>(l_65_));
            a_44_.inner[1] = l_66_;
            ulong l_67_ = l_65_ >> static_cast<uint>(as_type<ulong>(32uL));
            l_mut_45_ = l_67_;
            uint l_68_ = a_37_.inner[0];
            ulong l_69_ = static_cast<ulong>(l_68_);
            uint l_70_ = a_37_.inner[2];
            ulong l_71_ = static_cast<ulong>(l_70_);
            ulong l_72_ = l_69_ * l_71_;
            uint l_73_ = a_44_.inner[2];
            ulong l_74_ = static_cast<ulong>(l_73_);
            ulong l_75_ = l_72_ + l_74_;
            ulong _e190 = l_mut_45_;
            ulong l_76_ = l_75_ + _e190;
            uint l_77_ = static_cast<uint>(as_type<ulong>(l_76_));
            a_44_.inner[2] = l_77_;
            ulong l_78_ = l_76_ >> static_cast<uint>(as_type<ulong>(32uL));
            l_mut_45_ = l_78_;
            ulong _e199 = l_mut_45_;
            uint l_79_ = static_cast<uint>(as_type<ulong>(_e199));
            a_44_.inner[3] = l_79_;
            l_mut_45_ = 0uL;
            uint l_80_ = a_37_.inner[1];
            ulong l_81_ = static_cast<ulong>(l_80_);
            uint l_82_ = a_37_.inner[0];
            ulong l_83_ = static_cast<ulong>(l_82_);
            ulong l_84_ = l_81_ * l_83_;
            uint l_85_ = a_44_.inner[1];
            ulong l_86_ = static_cast<ulong>(l_85_);
            ulong l_87_ = l_84_ + l_86_;
            ulong _e215 = l_mut_45_;
            ulong l_88_ = l_87_ + _e215;
            uint l_89_ = static_cast<uint>(as_type<ulong>(l_88_));
            a_44_.inner[1] = l_89_;
            ulong l_90_ = l_88_ >> static_cast<uint>(as_type<ulong>(32uL));
            l_mut_45_ = l_90_;
            uint l_91_ = a_37_.inner[1];
            ulong l_92_ = static_cast<ulong>(l_91_);
            uint l_93_ = a_37_.inner[1];
            ulong l_94_ = static_cast<ulong>(l_93_);
            ulong l_95_ = l_92_ * l_94_;
            uint l_96_ = a_44_.inner[2];
            ulong l_97_ = static_cast<ulong>(l_96_);
            ulong l_98_ = l_95_ + l_97_;
            ulong _e235 = l_mut_45_;
            ulong l_99_ = l_98_ + _e235;
            uint l_100_ = static_cast<uint>(as_type<ulong>(l_99_));
            a_44_.inner[2] = l_100_;
            ulong l_101_ = l_99_ >> static_cast<uint>(as_type<ulong>(32uL));
            l_mut_45_ = l_101_;
            uint l_102_ = a_37_.inner[1];
            ulong l_103_ = static_cast<ulong>(l_102_);
            uint l_104_ = a_37_.inner[2];
            ulong l_105_ = static_cast<ulong>(l_104_);
            ulong l_106_ = l_103_ * l_105_;
            uint l_107_ = a_44_.inner[3];
            ulong l_108_ = static_cast<ulong>(l_107_);
            ulong l_109_ = l_106_ + l_108_;
            ulong _e255 = l_mut_45_;
            ulong l_110_ = l_109_ + _e255;
            uint l_111_ = static_cast<uint>(as_type<ulong>(l_110_));
            a_44_.inner[3] = l_111_;
            ulong l_112_ = l_110_ >> static_cast<uint>(as_type<ulong>(32uL));
            l_mut_45_ = l_112_;
            ulong _e264 = l_mut_45_;
            uint l_113_ = static_cast<uint>(as_type<ulong>(_e264));
            a_44_.inner[4] = l_113_;
            l_mut_45_ = 0uL;
            uint l_114_ = a_37_.inner[2];
            ulong l_115_ = static_cast<ulong>(l_114_);
            uint l_116_ = a_37_.inner[0];
            ulong l_117_ = static_cast<ulong>(l_116_);
            ulong l_118_ = l_115_ * l_117_;
            uint l_119_ = a_44_.inner[2];
            ulong l_120_ = static_cast<ulong>(l_119_);
            ulong l_121_ = l_118_ + l_120_;
            ulong _e280 = l_mut_45_;
            ulong l_122_ = l_121_ + _e280;
            uint l_123_ = static_cast<uint>(as_type<ulong>(l_122_));
            a_44_.inner[2] = l_123_;
            ulong l_124_ = l_122_ >> static_cast<uint>(as_type<ulong>(32uL));
            l_mut_45_ = l_124_;
            uint l_125_ = a_37_.inner[2];
            ulong l_126_ = static_cast<ulong>(l_125_);
            uint l_127_ = a_37_.inner[1];
            ulong l_128_ = static_cast<ulong>(l_127_);
            ulong l_129_ = l_126_ * l_128_;
            uint l_130_ = a_44_.inner[3];
            ulong l_131_ = static_cast<ulong>(l_130_);
            ulong l_132_ = l_129_ + l_131_;
            ulong _e300 = l_mut_45_;
            ulong l_133_ = l_132_ + _e300;
            uint l_134_ = static_cast<uint>(as_type<ulong>(l_133_));
            a_44_.inner[3] = l_134_;
            ulong l_135_ = l_133_ >> static_cast<uint>(as_type<ulong>(32uL));
            l_mut_45_ = l_135_;
            uint l_136_ = a_37_.inner[2];
            ulong l_137_ = static_cast<ulong>(l_136_);
            uint l_138_ = a_37_.inner[2];
            ulong l_139_ = static_cast<ulong>(l_138_);
            ulong l_140_ = l_137_ * l_139_;
            uint l_141_ = a_44_.inner[4];
            ulong l_142_ = static_cast<ulong>(l_141_);
            ulong l_143_ = l_140_ + l_142_;
            ulong _e320 = l_mut_45_;
            ulong l_144_ = l_143_ + _e320;
            uint l_145_ = static_cast<uint>(as_type<ulong>(l_144_));
            a_44_.inner[4] = l_145_;
            ulong l_146_ = l_144_ >> static_cast<uint>(as_type<ulong>(32uL));
            l_mut_45_ = l_146_;
            ulong _e329 = l_mut_45_;
            uint l_147_ = static_cast<uint>(as_type<ulong>(_e329));
            a_44_.inner[5] = l_147_;
            uint l_148_ = l_1_ + 0u;
            uint l_149_ = a_44_.inner[0];
            shared_memory_0_.inner[l_148_] = l_149_;
            uint l_150_ = l_1_ + 1u;
            uint l_151_ = a_44_.inner[1];
            shared_memory_0_.inner[l_150_] = l_151_;
            uint l_152_ = l_1_ + 2u;
            uint l_153_ = a_44_.inner[2];
            shared_memory_0_.inner[l_152_] = l_153_;
            uint l_154_ = l_1_ + 3u;
            uint l_155_ = a_44_.inner[3];
            shared_memory_0_.inner[l_154_] = l_155_;
            uint l_156_ = l_1_ + 4u;
            uint l_157_ = a_44_.inner[4];
            shared_memory_0_.inner[l_156_] = l_157_;
            uint l_158_ = l_1_ + 5u;
            uint l_159_ = a_44_.inner[5];
            shared_memory_0_.inner[l_158_] = l_159_;
            l_mut_160_ = 5;
            uint2 loop_bound_1 = uint2(4294967295u);
            while(true) {
                if (metal::all(loop_bound_1 == uint2(0u))) { break; }
                loop_bound_1 -= uint2(loop_bound_1.y == 0u, 1u);
                int _e370 = l_mut_160_;
                bool l_161_ = _e370 >= 0;
                bool l_162_ = !(l_161_);
                if (l_162_) {
                    break;
                }
                int _e374 = l_mut_160_;
                uint l_163_ = static_cast<uint>(_e374);
                uint l_164_ = l_1_ + l_163_;
                uint l_165_ = shared_memory_0_.inner[l_164_];
                bool l_166_ = l_165_ != 0u;
                if (l_166_) {
                    break;
                }
                int _e382 = l_mut_160_;
                l_mut_160_ = as_type<int>(as_type<uint>(_e382) - as_type<uint>(1));
            }
            uint2 loop_bound_2 = uint2(4294967295u);
            while(true) {
                if (metal::all(loop_bound_2 == uint2(0u))) { break; }
                loop_bound_2 -= uint2(loop_bound_2.y == 0u, 1u);
                int _e385 = l_mut_160_;
                bool l_167_ = _e385 >= 0;
                if (l_167_) {
                    bool _e390 = l_mut_33_;
                    local_1 = _e390;
                } else {
                    local_1 = false;
                }
                bool l_168_ = local_1;
                bool l_169_ = !(l_168_);
                if (l_169_) {
                    break;
                }
                l_mut_170_ = 0u;
                int _e395 = l_mut_160_;
                l_mut_171_ = _e395;
                uint2 loop_bound_3 = uint2(4294967295u);
                while(true) {
                    if (metal::all(loop_bound_3 == uint2(0u))) { break; }
                    loop_bound_3 -= uint2(loop_bound_3.y == 0u, 1u);
                    int _e396 = l_mut_171_;
                    bool l_172_ = _e396 >= 0;
                    bool l_173_ = !(l_172_);
                    if (l_173_) {
                        break;
                    }
                    int _e400 = l_mut_171_;
                    uint l_174_ = static_cast<uint>(_e400);
                    uint l_175_ = l_1_ + l_174_;
                    uint l_176_ = shared_memory_0_.inner[l_175_];
                    uint _e406 = l_mut_170_;
                    uint l_177_ = _e406 << 16u;
                    uint l_178_ = l_176_ >> 16u;
                    uint l_179_ = l_177_ | l_178_;
                    uint l_180_ = naga_div(l_179_, 3364u);
                    uint l_181_ = l_180_ * 3364u;
                    uint l_182_ = l_179_ - l_181_;
                    uint l_183_ = l_182_ << 16u;
                    uint l_184_ = l_176_ & 65535u;
                    uint l_185_ = l_183_ | l_184_;
                    uint l_186_ = naga_div(l_185_, 3364u);
                    uint l_187_ = l_186_ * 3364u;
                    uint l_188_ = l_185_ - l_187_;
                    l_mut_170_ = l_188_;
                    int _e427 = l_mut_171_;
                    uint l_189_ = static_cast<uint>(_e427);
                    uint l_190_ = l_1_ + l_189_;
                    uint l_191_ = l_180_ << 16u;
                    uint l_192_ = l_191_ | l_186_;
                    shared_memory_0_.inner[l_190_] = l_192_;
                    int _e435 = l_mut_171_;
                    l_mut_171_ = as_type<int>(as_type<uint>(_e435) - as_type<uint>(1));
                }
                uint2 loop_bound_4 = uint2(4294967295u);
                while(true) {
                    if (metal::all(loop_bound_4 == uint2(0u))) { break; }
                    loop_bound_4 -= uint2(loop_bound_4.y == 0u, 1u);
                    int _e438 = l_mut_160_;
                    bool l_193_ = _e438 >= 0;
                    bool l_194_ = !(l_193_);
                    if (l_194_) {
                        break;
                    }
                    int _e442 = l_mut_160_;
                    uint l_195_ = static_cast<uint>(_e442);
                    uint l_196_ = l_1_ + l_195_;
                    uint l_197_ = shared_memory_0_.inner[l_196_];
                    bool l_198_ = l_197_ != 0u;
                    if (l_198_) {
                        break;
                    }
                    int _e450 = l_mut_160_;
                    l_mut_160_ = as_type<int>(as_type<uint>(_e450) - as_type<uint>(1));
                }
                uint _e453 = l_mut_170_;
                l_mut_199_ = _e453;
                l_mut_45_ = 0uL;
                int _e455 = l_mut_160_;
                bool l_200_ = _e455 >= 0;
                if (l_200_) {
                    uint _e458 = l_mut_199_;
                    uint l_201_ = naga_div(_e458, 58u);
                    uint l_202_ = l_201_ * 58u;
                    uint _e463 = l_mut_199_;
                    uint l_203_ = _e463 - l_202_;
                    l_mut_199_ = l_201_;
                    ulong l_204_ = static_cast<ulong>(l_203_);
                    ulong l_205_ = 1uL << static_cast<uint>(as_type<ulong>(l_204_));
                    ulong _e470 = l_mut_34_;
                    ulong l_206_ = _e470 & l_205_;
                    ulong _e472 = l_mut_45_;
                    l_mut_45_ = _e472 | l_206_;
                    ulong _e474 = l_mut_34_;
                    l_mut_34_ = _e474 | l_205_;
                    uint _e476 = l_mut_199_;
                    uint l_207_ = naga_div(_e476, 58u);
                    uint l_208_ = l_207_ * 58u;
                    uint _e481 = l_mut_199_;
                    uint l_209_ = _e481 - l_208_;
                    l_mut_199_ = l_207_;
                    ulong l_210_ = static_cast<ulong>(l_209_);
                    ulong l_211_ = 1uL << static_cast<uint>(as_type<ulong>(l_210_));
                    ulong _e488 = l_mut_34_;
                    ulong l_212_ = _e488 & l_211_;
                    ulong _e490 = l_mut_45_;
                    l_mut_45_ = _e490 | l_212_;
                    ulong _e492 = l_mut_34_;
                    l_mut_34_ = _e492 | l_211_;
                } else {
                    uint2 loop_bound_5 = uint2(4294967295u);
                    while(true) {
                        if (metal::all(loop_bound_5 == uint2(0u))) { break; }
                        loop_bound_5 -= uint2(loop_bound_5.y == 0u, 1u);
                        uint _e494 = l_mut_199_;
                        bool l_213_ = _e494 != 0u;
                        bool l_214_ = !(l_213_);
                        if (l_214_) {
                            break;
                        }
                        uint _e498 = l_mut_199_;
                        uint l_215_ = naga_div(_e498, 58u);
                        uint l_216_ = l_215_ * 58u;
                        uint _e503 = l_mut_199_;
                        uint l_217_ = _e503 - l_216_;
                        l_mut_199_ = l_215_;
                        ulong l_218_ = static_cast<ulong>(l_217_);
                        ulong l_219_ = 1uL << static_cast<uint>(as_type<ulong>(l_218_));
                        ulong _e510 = l_mut_34_;
                        ulong l_220_ = _e510 & l_219_;
                        ulong _e512 = l_mut_45_;
                        l_mut_45_ = _e512 | l_220_;
                        ulong _e514 = l_mut_34_;
                        l_mut_34_ = _e514 | l_219_;
                    }
                }
                ulong _e516 = l_mut_45_;
                bool l_221_ = _e516 != 0uL;
                if (l_221_) {
                    l_mut_33_ = false;
                }
            }
            bool _e520 = l_mut_33_;
            if (_e520) {
                uint l_222_ = l_1_ + 0u;
                shared_memory_0_.inner[l_222_] = 0u;
                uint l_223_ = l_1_ + 1u;
                shared_memory_0_.inner[l_223_] = 0u;
                uint l_224_ = l_1_ + 2u;
                shared_memory_0_.inner[l_224_] = 0u;
                uint l_225_ = l_1_ + 3u;
                shared_memory_0_.inner[l_225_] = 0u;
                uint l_226_ = l_1_ + 4u;
                shared_memory_0_.inner[l_226_] = 0u;
                uint l_227_ = l_1_ + 5u;
                shared_memory_0_.inner[l_227_] = 0u;
                uint l_228_ = l_1_ + 6u;
                shared_memory_0_.inner[l_228_] = 0u;
                uint l_229_ = l_1_ + 7u;
                shared_memory_0_.inner[l_229_] = 0u;
                uint l_230_ = l_1_ + 8u;
                shared_memory_0_.inner[l_230_] = 0u;
                l_mut_45_ = 0uL;
                uint l_231_ = a_44_.inner[0];
                ulong l_232_ = static_cast<ulong>(l_231_);
                uint l_233_ = a_37_.inner[0];
                ulong l_234_ = static_cast<ulong>(l_233_);
                ulong l_235_ = l_232_ * l_234_;
                uint l_236_ = l_1_ + 0u;
                uint l_237_ = shared_memory_0_.inner[l_236_];
                ulong l_238_ = static_cast<ulong>(l_237_);
                ulong l_239_ = l_235_ + l_238_;
                ulong _e581 = l_mut_45_;
                ulong l_240_ = l_239_ + _e581;
                uint l_241_ = l_1_ + 0u;
                uint l_242_ = static_cast<uint>(as_type<ulong>(l_240_));
                shared_memory_0_.inner[l_241_] = l_242_;
                ulong l_243_ = l_240_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_243_;
                uint l_244_ = a_44_.inner[0];
                ulong l_245_ = static_cast<ulong>(l_244_);
                uint l_246_ = a_37_.inner[1];
                ulong l_247_ = static_cast<ulong>(l_246_);
                ulong l_248_ = l_245_ * l_247_;
                uint l_249_ = l_1_ + 1u;
                uint l_250_ = shared_memory_0_.inner[l_249_];
                ulong l_251_ = static_cast<ulong>(l_250_);
                ulong l_252_ = l_248_ + l_251_;
                ulong _e607 = l_mut_45_;
                ulong l_253_ = l_252_ + _e607;
                uint l_254_ = l_1_ + 1u;
                uint l_255_ = static_cast<uint>(as_type<ulong>(l_253_));
                shared_memory_0_.inner[l_254_] = l_255_;
                ulong l_256_ = l_253_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_256_;
                uint l_257_ = a_44_.inner[0];
                ulong l_258_ = static_cast<ulong>(l_257_);
                uint l_259_ = a_37_.inner[2];
                ulong l_260_ = static_cast<ulong>(l_259_);
                ulong l_261_ = l_258_ * l_260_;
                uint l_262_ = l_1_ + 2u;
                uint l_263_ = shared_memory_0_.inner[l_262_];
                ulong l_264_ = static_cast<ulong>(l_263_);
                ulong l_265_ = l_261_ + l_264_;
                ulong _e633 = l_mut_45_;
                ulong l_266_ = l_265_ + _e633;
                uint l_267_ = l_1_ + 2u;
                uint l_268_ = static_cast<uint>(as_type<ulong>(l_266_));
                shared_memory_0_.inner[l_267_] = l_268_;
                ulong l_269_ = l_266_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_269_;
                uint l_270_ = l_1_ + 3u;
                ulong _e647 = l_mut_45_;
                uint l_271_ = static_cast<uint>(as_type<ulong>(_e647));
                shared_memory_0_.inner[l_270_] = l_271_;
                l_mut_45_ = 0uL;
                uint l_272_ = a_44_.inner[1];
                ulong l_273_ = static_cast<ulong>(l_272_);
                uint l_274_ = a_37_.inner[0];
                ulong l_275_ = static_cast<ulong>(l_274_);
                ulong l_276_ = l_273_ * l_275_;
                uint l_277_ = l_1_ + 1u;
                uint l_278_ = shared_memory_0_.inner[l_277_];
                ulong l_279_ = static_cast<ulong>(l_278_);
                ulong l_280_ = l_276_ + l_279_;
                ulong _e667 = l_mut_45_;
                ulong l_281_ = l_280_ + _e667;
                uint l_282_ = l_1_ + 1u;
                uint l_283_ = static_cast<uint>(as_type<ulong>(l_281_));
                shared_memory_0_.inner[l_282_] = l_283_;
                ulong l_284_ = l_281_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_284_;
                uint l_285_ = a_44_.inner[1];
                ulong l_286_ = static_cast<ulong>(l_285_);
                uint l_287_ = a_37_.inner[1];
                ulong l_288_ = static_cast<ulong>(l_287_);
                ulong l_289_ = l_286_ * l_288_;
                uint l_290_ = l_1_ + 2u;
                uint l_291_ = shared_memory_0_.inner[l_290_];
                ulong l_292_ = static_cast<ulong>(l_291_);
                ulong l_293_ = l_289_ + l_292_;
                ulong _e693 = l_mut_45_;
                ulong l_294_ = l_293_ + _e693;
                uint l_295_ = l_1_ + 2u;
                uint l_296_ = static_cast<uint>(as_type<ulong>(l_294_));
                shared_memory_0_.inner[l_295_] = l_296_;
                ulong l_297_ = l_294_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_297_;
                uint l_298_ = a_44_.inner[1];
                ulong l_299_ = static_cast<ulong>(l_298_);
                uint l_300_ = a_37_.inner[2];
                ulong l_301_ = static_cast<ulong>(l_300_);
                ulong l_302_ = l_299_ * l_301_;
                uint l_303_ = l_1_ + 3u;
                uint l_304_ = shared_memory_0_.inner[l_303_];
                ulong l_305_ = static_cast<ulong>(l_304_);
                ulong l_306_ = l_302_ + l_305_;
                ulong _e719 = l_mut_45_;
                ulong l_307_ = l_306_ + _e719;
                uint l_308_ = l_1_ + 3u;
                uint l_309_ = static_cast<uint>(as_type<ulong>(l_307_));
                shared_memory_0_.inner[l_308_] = l_309_;
                ulong l_310_ = l_307_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_310_;
                uint l_311_ = l_1_ + 4u;
                ulong _e733 = l_mut_45_;
                uint l_312_ = static_cast<uint>(as_type<ulong>(_e733));
                shared_memory_0_.inner[l_311_] = l_312_;
                l_mut_45_ = 0uL;
                uint l_313_ = a_44_.inner[2];
                ulong l_314_ = static_cast<ulong>(l_313_);
                uint l_315_ = a_37_.inner[0];
                ulong l_316_ = static_cast<ulong>(l_315_);
                ulong l_317_ = l_314_ * l_316_;
                uint l_318_ = l_1_ + 2u;
                uint l_319_ = shared_memory_0_.inner[l_318_];
                ulong l_320_ = static_cast<ulong>(l_319_);
                ulong l_321_ = l_317_ + l_320_;
                ulong _e753 = l_mut_45_;
                ulong l_322_ = l_321_ + _e753;
                uint l_323_ = l_1_ + 2u;
                uint l_324_ = static_cast<uint>(as_type<ulong>(l_322_));
                shared_memory_0_.inner[l_323_] = l_324_;
                ulong l_325_ = l_322_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_325_;
                uint l_326_ = a_44_.inner[2];
                ulong l_327_ = static_cast<ulong>(l_326_);
                uint l_328_ = a_37_.inner[1];
                ulong l_329_ = static_cast<ulong>(l_328_);
                ulong l_330_ = l_327_ * l_329_;
                uint l_331_ = l_1_ + 3u;
                uint l_332_ = shared_memory_0_.inner[l_331_];
                ulong l_333_ = static_cast<ulong>(l_332_);
                ulong l_334_ = l_330_ + l_333_;
                ulong _e779 = l_mut_45_;
                ulong l_335_ = l_334_ + _e779;
                uint l_336_ = l_1_ + 3u;
                uint l_337_ = static_cast<uint>(as_type<ulong>(l_335_));
                shared_memory_0_.inner[l_336_] = l_337_;
                ulong l_338_ = l_335_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_338_;
                uint l_339_ = a_44_.inner[2];
                ulong l_340_ = static_cast<ulong>(l_339_);
                uint l_341_ = a_37_.inner[2];
                ulong l_342_ = static_cast<ulong>(l_341_);
                ulong l_343_ = l_340_ * l_342_;
                uint l_344_ = l_1_ + 4u;
                uint l_345_ = shared_memory_0_.inner[l_344_];
                ulong l_346_ = static_cast<ulong>(l_345_);
                ulong l_347_ = l_343_ + l_346_;
                ulong _e805 = l_mut_45_;
                ulong l_348_ = l_347_ + _e805;
                uint l_349_ = l_1_ + 4u;
                uint l_350_ = static_cast<uint>(as_type<ulong>(l_348_));
                shared_memory_0_.inner[l_349_] = l_350_;
                ulong l_351_ = l_348_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_351_;
                uint l_352_ = l_1_ + 5u;
                ulong _e819 = l_mut_45_;
                uint l_353_ = static_cast<uint>(as_type<ulong>(_e819));
                shared_memory_0_.inner[l_352_] = l_353_;
                l_mut_45_ = 0uL;
                uint l_354_ = a_44_.inner[3];
                ulong l_355_ = static_cast<ulong>(l_354_);
                uint l_356_ = a_37_.inner[0];
                ulong l_357_ = static_cast<ulong>(l_356_);
                ulong l_358_ = l_355_ * l_357_;
                uint l_359_ = l_1_ + 3u;
                uint l_360_ = shared_memory_0_.inner[l_359_];
                ulong l_361_ = static_cast<ulong>(l_360_);
                ulong l_362_ = l_358_ + l_361_;
                ulong _e839 = l_mut_45_;
                ulong l_363_ = l_362_ + _e839;
                uint l_364_ = l_1_ + 3u;
                uint l_365_ = static_cast<uint>(as_type<ulong>(l_363_));
                shared_memory_0_.inner[l_364_] = l_365_;
                ulong l_366_ = l_363_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_366_;
                uint l_367_ = a_44_.inner[3];
                ulong l_368_ = static_cast<ulong>(l_367_);
                uint l_369_ = a_37_.inner[1];
                ulong l_370_ = static_cast<ulong>(l_369_);
                ulong l_371_ = l_368_ * l_370_;
                uint l_372_ = l_1_ + 4u;
                uint l_373_ = shared_memory_0_.inner[l_372_];
                ulong l_374_ = static_cast<ulong>(l_373_);
                ulong l_375_ = l_371_ + l_374_;
                ulong _e865 = l_mut_45_;
                ulong l_376_ = l_375_ + _e865;
                uint l_377_ = l_1_ + 4u;
                uint l_378_ = static_cast<uint>(as_type<ulong>(l_376_));
                shared_memory_0_.inner[l_377_] = l_378_;
                ulong l_379_ = l_376_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_379_;
                uint l_380_ = a_44_.inner[3];
                ulong l_381_ = static_cast<ulong>(l_380_);
                uint l_382_ = a_37_.inner[2];
                ulong l_383_ = static_cast<ulong>(l_382_);
                ulong l_384_ = l_381_ * l_383_;
                uint l_385_ = l_1_ + 5u;
                uint l_386_ = shared_memory_0_.inner[l_385_];
                ulong l_387_ = static_cast<ulong>(l_386_);
                ulong l_388_ = l_384_ + l_387_;
                ulong _e891 = l_mut_45_;
                ulong l_389_ = l_388_ + _e891;
                uint l_390_ = l_1_ + 5u;
                uint l_391_ = static_cast<uint>(as_type<ulong>(l_389_));
                shared_memory_0_.inner[l_390_] = l_391_;
                ulong l_392_ = l_389_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_392_;
                uint l_393_ = l_1_ + 6u;
                ulong _e905 = l_mut_45_;
                uint l_394_ = static_cast<uint>(as_type<ulong>(_e905));
                shared_memory_0_.inner[l_393_] = l_394_;
                l_mut_45_ = 0uL;
                uint l_395_ = a_44_.inner[4];
                ulong l_396_ = static_cast<ulong>(l_395_);
                uint l_397_ = a_37_.inner[0];
                ulong l_398_ = static_cast<ulong>(l_397_);
                ulong l_399_ = l_396_ * l_398_;
                uint l_400_ = l_1_ + 4u;
                uint l_401_ = shared_memory_0_.inner[l_400_];
                ulong l_402_ = static_cast<ulong>(l_401_);
                ulong l_403_ = l_399_ + l_402_;
                ulong _e925 = l_mut_45_;
                ulong l_404_ = l_403_ + _e925;
                uint l_405_ = l_1_ + 4u;
                uint l_406_ = static_cast<uint>(as_type<ulong>(l_404_));
                shared_memory_0_.inner[l_405_] = l_406_;
                ulong l_407_ = l_404_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_407_;
                uint l_408_ = a_44_.inner[4];
                ulong l_409_ = static_cast<ulong>(l_408_);
                uint l_410_ = a_37_.inner[1];
                ulong l_411_ = static_cast<ulong>(l_410_);
                ulong l_412_ = l_409_ * l_411_;
                uint l_413_ = l_1_ + 5u;
                uint l_414_ = shared_memory_0_.inner[l_413_];
                ulong l_415_ = static_cast<ulong>(l_414_);
                ulong l_416_ = l_412_ + l_415_;
                ulong _e951 = l_mut_45_;
                ulong l_417_ = l_416_ + _e951;
                uint l_418_ = l_1_ + 5u;
                uint l_419_ = static_cast<uint>(as_type<ulong>(l_417_));
                shared_memory_0_.inner[l_418_] = l_419_;
                ulong l_420_ = l_417_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_420_;
                uint l_421_ = a_44_.inner[4];
                ulong l_422_ = static_cast<ulong>(l_421_);
                uint l_423_ = a_37_.inner[2];
                ulong l_424_ = static_cast<ulong>(l_423_);
                ulong l_425_ = l_422_ * l_424_;
                uint l_426_ = l_1_ + 6u;
                uint l_427_ = shared_memory_0_.inner[l_426_];
                ulong l_428_ = static_cast<ulong>(l_427_);
                ulong l_429_ = l_425_ + l_428_;
                ulong _e977 = l_mut_45_;
                ulong l_430_ = l_429_ + _e977;
                uint l_431_ = l_1_ + 6u;
                uint l_432_ = static_cast<uint>(as_type<ulong>(l_430_));
                shared_memory_0_.inner[l_431_] = l_432_;
                ulong l_433_ = l_430_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_433_;
                uint l_434_ = l_1_ + 7u;
                ulong _e991 = l_mut_45_;
                uint l_435_ = static_cast<uint>(as_type<ulong>(_e991));
                shared_memory_0_.inner[l_434_] = l_435_;
                l_mut_45_ = 0uL;
                uint l_436_ = a_44_.inner[5];
                ulong l_437_ = static_cast<ulong>(l_436_);
                uint l_438_ = a_37_.inner[0];
                ulong l_439_ = static_cast<ulong>(l_438_);
                ulong l_440_ = l_437_ * l_439_;
                uint l_441_ = l_1_ + 5u;
                uint l_442_ = shared_memory_0_.inner[l_441_];
                ulong l_443_ = static_cast<ulong>(l_442_);
                ulong l_444_ = l_440_ + l_443_;
                ulong _e1011 = l_mut_45_;
                ulong l_445_ = l_444_ + _e1011;
                uint l_446_ = l_1_ + 5u;
                uint l_447_ = static_cast<uint>(as_type<ulong>(l_445_));
                shared_memory_0_.inner[l_446_] = l_447_;
                ulong l_448_ = l_445_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_448_;
                uint l_449_ = a_44_.inner[5];
                ulong l_450_ = static_cast<ulong>(l_449_);
                uint l_451_ = a_37_.inner[1];
                ulong l_452_ = static_cast<ulong>(l_451_);
                ulong l_453_ = l_450_ * l_452_;
                uint l_454_ = l_1_ + 6u;
                uint l_455_ = shared_memory_0_.inner[l_454_];
                ulong l_456_ = static_cast<ulong>(l_455_);
                ulong l_457_ = l_453_ + l_456_;
                ulong _e1037 = l_mut_45_;
                ulong l_458_ = l_457_ + _e1037;
                uint l_459_ = l_1_ + 6u;
                uint l_460_ = static_cast<uint>(as_type<ulong>(l_458_));
                shared_memory_0_.inner[l_459_] = l_460_;
                ulong l_461_ = l_458_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_461_;
                uint l_462_ = a_44_.inner[5];
                ulong l_463_ = static_cast<ulong>(l_462_);
                uint l_464_ = a_37_.inner[2];
                ulong l_465_ = static_cast<ulong>(l_464_);
                ulong l_466_ = l_463_ * l_465_;
                uint l_467_ = l_1_ + 7u;
                uint l_468_ = shared_memory_0_.inner[l_467_];
                ulong l_469_ = static_cast<ulong>(l_468_);
                ulong l_470_ = l_466_ + l_469_;
                ulong _e1063 = l_mut_45_;
                ulong l_471_ = l_470_ + _e1063;
                uint l_472_ = l_1_ + 7u;
                uint l_473_ = static_cast<uint>(as_type<ulong>(l_471_));
                shared_memory_0_.inner[l_472_] = l_473_;
                ulong l_474_ = l_471_ >> static_cast<uint>(as_type<ulong>(32uL));
                l_mut_45_ = l_474_;
                uint l_475_ = l_1_ + 8u;
                ulong _e1077 = l_mut_45_;
                uint l_476_ = static_cast<uint>(as_type<ulong>(_e1077));
                shared_memory_0_.inner[l_475_] = l_476_;
                l_mut_171_ = 8;
                uint2 loop_bound_6 = uint2(4294967295u);
                while(true) {
                    if (metal::all(loop_bound_6 == uint2(0u))) { break; }
                    loop_bound_6 -= uint2(loop_bound_6.y == 0u, 1u);
                    int _e1083 = l_mut_171_;
                    bool l_477_ = _e1083 >= 0;
                    bool l_478_ = !(l_477_);
                    if (l_478_) {
                        break;
                    }
                    int _e1087 = l_mut_171_;
                    uint l_479_ = static_cast<uint>(_e1087);
                    uint l_480_ = l_1_ + l_479_;
                    uint l_481_ = shared_memory_0_.inner[l_480_];
                    bool l_482_ = l_481_ != 0u;
                    if (l_482_) {
                        break;
                    }
                    int _e1095 = l_mut_171_;
                    l_mut_171_ = as_type<int>(as_type<uint>(_e1095) - as_type<uint>(1));
                }
                uint2 loop_bound_7 = uint2(4294967295u);
                while(true) {
                    if (metal::all(loop_bound_7 == uint2(0u))) { break; }
                    loop_bound_7 -= uint2(loop_bound_7.y == 0u, 1u);
                    int _e1098 = l_mut_171_;
                    bool l_483_ = _e1098 >= 0;
                    if (l_483_) {
                        bool _e1103 = l_mut_33_;
                        local_2 = _e1103;
                    } else {
                        local_2 = false;
                    }
                    bool l_484_ = local_2;
                    bool l_485_ = !(l_484_);
                    if (l_485_) {
                        break;
                    }
                    l_mut_199_ = 0u;
                    int _e1108 = l_mut_171_;
                    l_mut_486_ = _e1108;
                    uint2 loop_bound_8 = uint2(4294967295u);
                    while(true) {
                        if (metal::all(loop_bound_8 == uint2(0u))) { break; }
                        loop_bound_8 -= uint2(loop_bound_8.y == 0u, 1u);
                        int _e1109 = l_mut_486_;
                        bool l_487_ = _e1109 >= 0;
                        bool l_488_ = !(l_487_);
                        if (l_488_) {
                            break;
                        }
                        int _e1113 = l_mut_486_;
                        uint l_489_ = static_cast<uint>(_e1113);
                        uint l_490_ = l_1_ + l_489_;
                        uint l_491_ = shared_memory_0_.inner[l_490_];
                        uint _e1119 = l_mut_199_;
                        uint l_492_ = _e1119 << 16u;
                        uint l_493_ = l_491_ >> 16u;
                        uint l_494_ = l_492_ | l_493_;
                        uint l_495_ = naga_div(l_494_, 3364u);
                        uint l_496_ = l_495_ * 3364u;
                        uint l_497_ = l_494_ - l_496_;
                        uint l_498_ = l_497_ << 16u;
                        uint l_499_ = l_491_ & 65535u;
                        uint l_500_ = l_498_ | l_499_;
                        uint l_501_ = naga_div(l_500_, 3364u);
                        uint l_502_ = l_501_ * 3364u;
                        uint l_503_ = l_500_ - l_502_;
                        l_mut_199_ = l_503_;
                        int _e1140 = l_mut_486_;
                        uint l_504_ = static_cast<uint>(_e1140);
                        uint l_505_ = l_1_ + l_504_;
                        uint l_506_ = l_495_ << 16u;
                        uint l_507_ = l_506_ | l_501_;
                        shared_memory_0_.inner[l_505_] = l_507_;
                        int _e1148 = l_mut_486_;
                        l_mut_486_ = as_type<int>(as_type<uint>(_e1148) - as_type<uint>(1));
                    }
                    uint2 loop_bound_9 = uint2(4294967295u);
                    while(true) {
                        if (metal::all(loop_bound_9 == uint2(0u))) { break; }
                        loop_bound_9 -= uint2(loop_bound_9.y == 0u, 1u);
                        int _e1151 = l_mut_171_;
                        bool l_508_ = _e1151 >= 0;
                        bool l_509_ = !(l_508_);
                        if (l_509_) {
                            break;
                        }
                        int _e1155 = l_mut_171_;
                        uint l_510_ = static_cast<uint>(_e1155);
                        uint l_511_ = l_1_ + l_510_;
                        uint l_512_ = shared_memory_0_.inner[l_511_];
                        bool l_513_ = l_512_ != 0u;
                        if (l_513_) {
                            break;
                        }
                        int _e1163 = l_mut_171_;
                        l_mut_171_ = as_type<int>(as_type<uint>(_e1163) - as_type<uint>(1));
                    }
                    uint _e1166 = l_mut_199_;
                    l_mut_170_ = _e1166;
                    l_mut_45_ = 0uL;
                    int _e1168 = l_mut_171_;
                    bool l_514_ = _e1168 >= 0;
                    if (l_514_) {
                        uint _e1171 = l_mut_170_;
                        uint l_515_ = naga_div(_e1171, 58u);
                        uint l_516_ = l_515_ * 58u;
                        uint _e1176 = l_mut_170_;
                        uint l_517_ = _e1176 - l_516_;
                        l_mut_170_ = l_515_;
                        ulong l_518_ = static_cast<ulong>(l_517_);
                        ulong l_519_ = 1uL << static_cast<uint>(as_type<ulong>(l_518_));
                        ulong _e1183 = l_mut_34_;
                        ulong l_520_ = _e1183 & l_519_;
                        ulong _e1185 = l_mut_45_;
                        l_mut_45_ = _e1185 | l_520_;
                        ulong _e1187 = l_mut_34_;
                        l_mut_34_ = _e1187 | l_519_;
                        uint _e1189 = l_mut_170_;
                        uint l_521_ = naga_div(_e1189, 58u);
                        uint l_522_ = l_521_ * 58u;
                        uint _e1194 = l_mut_170_;
                        uint l_523_ = _e1194 - l_522_;
                        l_mut_170_ = l_521_;
                        ulong l_524_ = static_cast<ulong>(l_523_);
                        ulong l_525_ = 1uL << static_cast<uint>(as_type<ulong>(l_524_));
                        ulong _e1201 = l_mut_34_;
                        ulong l_526_ = _e1201 & l_525_;
                        ulong _e1203 = l_mut_45_;
                        l_mut_45_ = _e1203 | l_526_;
                        ulong _e1205 = l_mut_34_;
                        l_mut_34_ = _e1205 | l_525_;
                    } else {
                        uint2 loop_bound_10 = uint2(4294967295u);
                        while(true) {
                            if (metal::all(loop_bound_10 == uint2(0u))) { break; }
                            loop_bound_10 -= uint2(loop_bound_10.y == 0u, 1u);
                            uint _e1207 = l_mut_170_;
                            bool l_527_ = _e1207 != 0u;
                            bool l_528_ = !(l_527_);
                            if (l_528_) {
                                break;
                            }
                            uint _e1211 = l_mut_170_;
                            uint l_529_ = naga_div(_e1211, 58u);
                            uint l_530_ = l_529_ * 58u;
                            uint _e1216 = l_mut_170_;
                            uint l_531_ = _e1216 - l_530_;
                            l_mut_170_ = l_529_;
                            ulong l_532_ = static_cast<ulong>(l_531_);
                            ulong l_533_ = 1uL << static_cast<uint>(as_type<ulong>(l_532_));
                            ulong _e1223 = l_mut_34_;
                            ulong l_534_ = _e1223 & l_533_;
                            ulong _e1225 = l_mut_45_;
                            l_mut_45_ = _e1225 | l_534_;
                            ulong _e1227 = l_mut_34_;
                            l_mut_34_ = _e1227 | l_533_;
                        }
                    }
                    ulong _e1229 = l_mut_45_;
                    bool l_535_ = _e1229 != 0uL;
                    if (l_535_) {
                        l_mut_33_ = false;
                    }
                }
            }
        }
        bool _e1233 = l_mut_33_;
        if (_e1233) {
            ulong _e1234 = l_mut_34_;
            uint l_536_ = static_cast<uint>(as_type<ulong>(_e1234));
            uint l_537_ = metal::popcount(l_536_);
            ulong _e1238 = l_mut_34_;
            ulong l_538_ = _e1238 >> static_cast<uint>(as_type<ulong>(32uL));
            uint l_539_ = static_cast<uint>(as_type<ulong>(l_538_));
            uint l_540_ = metal::popcount(l_539_);
            uint l_541_ = l_537_ + l_540_;
            l_mut_199_ = l_541_;
            uint _e1247 = l_mut_199_;
            bool l_542_ = _e1247 == 58u;
            if (true) {
                local_3 = l_542_;
            } else {
                local_3 = true;
            }
            bool l_543_ = local_3;
            if (l_543_) {
                uint _e1258 = metal::atomic_fetch_add_explicit(&buffer_4_global[0], 1u, metal::memory_order_relaxed);
                uint _e1262 = info.scalars_u32_.inner[1];
                bool l_546_ = _e1258 < _e1262;
                if (l_546_) {
                    uint l_547_ = 4u * _e1258;
                    uint l_548_ = static_cast<uint>(as_type<ulong>(l_31_));
                    buffer_3_global[l_547_] = l_548_;
                    uint l_549_ = l_547_ + 1u;
                    ulong l_550_ = l_31_ >> static_cast<uint>(as_type<ulong>(32uL));
                    uint l_551_ = static_cast<uint>(as_type<ulong>(l_550_));
                    buffer_3_global[l_549_] = l_551_;
                    uint l_552_ = l_547_ + 2u;
                    ulong _e1282 = l_mut_28_;
                    uint l_553_ = static_cast<uint>(as_type<ulong>(_e1282));
                    buffer_3_global[l_552_] = l_553_;
                    uint l_554_ = l_547_ + 3u;
                    ulong _e1289 = l_mut_28_;
                    ulong l_555_ = _e1289 >> static_cast<uint>(as_type<ulong>(32uL));
                    uint l_556_ = static_cast<uint>(as_type<ulong>(l_555_));
                    buffer_3_global[l_554_] = l_556_;
                }
            }
        }
        uint _e1298 = l_mut_7_;
        l_mut_7_ = _e1298 + l_6_;
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    bool l_557_ = local_invocation_id.x == 0u;
    if (l_557_) {
        uint _e1306 = metal::atomic_fetch_add_explicit(&buffer_5_global[5], 1u, metal::memory_order_relaxed);
        return;
    } else {
        return;
    }
}
