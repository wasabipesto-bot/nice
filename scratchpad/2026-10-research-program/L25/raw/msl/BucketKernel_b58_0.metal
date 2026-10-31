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
};

typedef uint type_1[1];
typedef metal::atomic_uint type_3[1];
struct type_4 {
    uint inner[4];
};
struct type_5 {
    uint inner[18];
};
struct info_st {
    type_4 scalars_u32_;
    type_5 static_meta;
};
struct type_6 {
    metal::atomic_uint inner[64];
};
struct type_8 {
    uint inner[6];
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


struct bucket_kernelInput {
};
kernel void bucket_kernel(
  metal::uint3 local_invocation_id [[thread_position_in_threadgroup]]
, metal::uint3 workgroup_id [[threadgroup_position_in_grid]]
, device type_1 const& buffer_0_global [[user(fake0)]]
, device type_1 const& buffer_1_global [[user(fake0)]]
, device type_1 const& buffer_2_global [[user(fake0)]]
, device type_1 const& buffer_3_global [[user(fake0)]]
, device type_1& buffer_4_global [[user(fake0)]]
, device type_1& buffer_5_global [[user(fake0)]]
, device type_1& buffer_6_global [[user(fake0)]]
, device type_1& buffer_7_global [[user(fake0)]]
, device type_3& buffer_8_global [[user(fake0)]]
, device info_st const& info [[user(fake0)]]
, threadgroup type_6& shared_memory_4_
, constant _mslBufferSizes& _buffer_sizes [[user(fake0)]]
) {
    if (metal::all(local_invocation_id == metal::uint3(0u))) {
        for (int __i0 = 0; __i0 < 64; __i0++) {
            metal::atomic_store_explicit(&shared_memory_4_.inner[__i0], 0, metal::memory_order_relaxed);
        }
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    type_8 a_31_ = {};
    type_8 a_39_ = {};
    type_8 a_117_ = {};
    uint l_mut_17_ = {};
    uint l_mut_32_ = {};
    uint l_mut_36_ = {};
    uint l_mut_40_ = {};
    uint l_mut_41_ = {};
    uint l_mut_243_ = {};
    uint l_mut_244_ = {};
    uint l_mut_247_ = {};
    uint l_mut_248_ = {};
    ulong l_mut_30_ = {};
    bool l_mut_193_ = {};
    bool local = {};
    bool local_1 = {};
    bool local_2 = {};
    uint _e19 = info.scalars_u32_.inner[2];
    ulong l_0_ = static_cast<ulong>(_e19);
    ulong l_1_ = l_0_ << static_cast<uint>(as_type<ulong>(32uL));
    uint _e28 = info.scalars_u32_.inner[1];
    ulong l_2_ = static_cast<ulong>(_e28);
    ulong l_3_ = l_1_ | l_2_;
    bool l_5_ = local_invocation_id.x < 64u;
    if (l_5_) {
        metal::atomic_store_explicit(&shared_memory_4_.inner[local_invocation_id.x], 0u, metal::memory_order_relaxed);
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    uint l_7_ = buffer_2_global[workgroup_id.x];
    uint l_8_ = workgroup_id.x + 1u;
    uint l_9_ = buffer_2_global[l_8_];
    uint l_10_ = l_9_ - l_7_;
    uint l_11_ = workgroup_id.y * 58u;
    uint _e55 = info.scalars_u32_.inner[0];
    uint l_12_ = l_11_ * _e55;
    uint l_13_ = 58u * l_7_;
    uint l_14_ = l_12_ + l_13_;
    uint l_15_ = buffer_3_global[workgroup_id.y];
    uint l_16_ = l_7_ + local_invocation_id.x;
    l_mut_17_ = l_16_;
    uint2 loop_bound = uint2(4294967295u);
    while(true) {
        if (metal::all(loop_bound == uint2(0u))) { break; }
        loop_bound -= uint2(loop_bound.y == 0u, 1u);
        uint _e66 = l_mut_17_;
        bool l_18_ = _e66 < l_9_;
        bool l_19_ = !(l_18_);
        if (l_19_) {
            break;
        }
        uint _e70 = l_mut_17_;
        uint l_20_ = buffer_0_global[_e70];
        uint _e74 = l_mut_17_;
        uint l_21_ = 2u * _e74;
        uint l_22_ = l_21_ + 1u;
        uint l_23_ = buffer_1_global[l_22_];
        ulong l_24_ = static_cast<ulong>(l_23_);
        ulong l_25_ = l_24_ << static_cast<uint>(as_type<ulong>(32uL));
        uint _e87 = l_mut_17_;
        uint l_26_ = 2u * _e87;
        uint l_27_ = buffer_1_global[l_26_];
        ulong l_28_ = static_cast<ulong>(l_27_);
        ulong l_29_ = l_25_ | l_28_;
        l_mut_30_ = l_29_;
        l_mut_32_ = l_20_;
        uint _e94 = l_mut_32_;
        uint l_33_ = naga_mod(_e94, 58u);
        a_31_.inner[0] = l_33_;
        uint _e98 = l_mut_32_;
        l_mut_32_ = naga_div(_e98, 58u);
        uint _e101 = l_mut_32_;
        uint l_34_ = naga_mod(_e101, 58u);
        a_31_.inner[1] = l_34_;
        uint _e105 = l_mut_32_;
        l_mut_32_ = naga_div(_e105, 58u);
        uint _e108 = l_mut_32_;
        uint l_35_ = naga_mod(_e108, 58u);
        a_31_.inner[2] = l_35_;
        uint _e112 = l_mut_32_;
        l_mut_32_ = naga_div(_e112, 58u);
        l_mut_36_ = l_15_;
        uint _e115 = l_mut_36_;
        uint l_37_ = naga_mod(_e115, 58u);
        a_31_.inner[3] = l_37_;
        uint _e119 = l_mut_36_;
        l_mut_36_ = naga_div(_e119, 58u);
        uint _e122 = l_mut_36_;
        uint l_38_ = naga_mod(_e122, 58u);
        a_31_.inner[4] = l_38_;
        uint _e126 = l_mut_36_;
        l_mut_36_ = naga_div(_e126, 58u);
        a_31_.inner[5] = 0u;
        l_mut_40_ = 0u;
        uint _e132 = l_mut_40_;
        l_mut_41_ = _e132;
        uint l_42_ = a_31_.inner[0];
        uint l_43_ = a_31_.inner[0];
        uint l_44_ = l_42_ * l_43_;
        uint _e138 = l_mut_41_;
        l_mut_41_ = _e138 + l_44_;
        uint _e140 = l_mut_41_;
        uint l_45_ = naga_mod(_e140, 58u);
        a_39_.inner[0] = l_45_;
        uint _e144 = l_mut_41_;
        uint l_46_ = naga_div(_e144, 58u);
        l_mut_40_ = l_46_;
        uint _e147 = l_mut_40_;
        l_mut_41_ = _e147;
        uint l_47_ = a_31_.inner[0];
        uint l_48_ = a_31_.inner[1];
        uint l_49_ = l_47_ * l_48_;
        uint _e153 = l_mut_41_;
        l_mut_41_ = _e153 + l_49_;
        uint l_50_ = a_31_.inner[1];
        uint l_51_ = a_31_.inner[0];
        uint l_52_ = l_50_ * l_51_;
        uint _e160 = l_mut_41_;
        l_mut_41_ = _e160 + l_52_;
        uint _e162 = l_mut_41_;
        uint l_53_ = naga_mod(_e162, 58u);
        a_39_.inner[1] = l_53_;
        uint _e166 = l_mut_41_;
        uint l_54_ = naga_div(_e166, 58u);
        l_mut_40_ = l_54_;
        uint _e169 = l_mut_40_;
        l_mut_41_ = _e169;
        uint l_55_ = a_31_.inner[0];
        uint l_56_ = a_31_.inner[2];
        uint l_57_ = l_55_ * l_56_;
        uint _e175 = l_mut_41_;
        l_mut_41_ = _e175 + l_57_;
        uint l_58_ = a_31_.inner[1];
        uint l_59_ = a_31_.inner[1];
        uint l_60_ = l_58_ * l_59_;
        uint _e182 = l_mut_41_;
        l_mut_41_ = _e182 + l_60_;
        uint l_61_ = a_31_.inner[2];
        uint l_62_ = a_31_.inner[0];
        uint l_63_ = l_61_ * l_62_;
        uint _e189 = l_mut_41_;
        l_mut_41_ = _e189 + l_63_;
        uint _e191 = l_mut_41_;
        uint l_64_ = naga_mod(_e191, 58u);
        a_39_.inner[2] = l_64_;
        uint _e195 = l_mut_41_;
        uint l_65_ = naga_div(_e195, 58u);
        l_mut_40_ = l_65_;
        uint _e198 = l_mut_40_;
        l_mut_41_ = _e198;
        uint l_66_ = a_31_.inner[0];
        uint l_67_ = a_31_.inner[3];
        uint l_68_ = l_66_ * l_67_;
        uint _e204 = l_mut_41_;
        l_mut_41_ = _e204 + l_68_;
        uint l_69_ = a_31_.inner[1];
        uint l_70_ = a_31_.inner[2];
        uint l_71_ = l_69_ * l_70_;
        uint _e211 = l_mut_41_;
        l_mut_41_ = _e211 + l_71_;
        uint l_72_ = a_31_.inner[2];
        uint l_73_ = a_31_.inner[1];
        uint l_74_ = l_72_ * l_73_;
        uint _e218 = l_mut_41_;
        l_mut_41_ = _e218 + l_74_;
        uint l_75_ = a_31_.inner[3];
        uint l_76_ = a_31_.inner[0];
        uint l_77_ = l_75_ * l_76_;
        uint _e225 = l_mut_41_;
        l_mut_41_ = _e225 + l_77_;
        uint _e227 = l_mut_41_;
        uint l_78_ = naga_mod(_e227, 58u);
        a_39_.inner[3] = l_78_;
        uint _e231 = l_mut_41_;
        uint l_79_ = naga_div(_e231, 58u);
        l_mut_40_ = l_79_;
        uint _e234 = l_mut_40_;
        l_mut_41_ = _e234;
        uint l_80_ = a_31_.inner[0];
        uint l_81_ = a_31_.inner[4];
        uint l_82_ = l_80_ * l_81_;
        uint _e240 = l_mut_41_;
        l_mut_41_ = _e240 + l_82_;
        uint l_83_ = a_31_.inner[1];
        uint l_84_ = a_31_.inner[3];
        uint l_85_ = l_83_ * l_84_;
        uint _e247 = l_mut_41_;
        l_mut_41_ = _e247 + l_85_;
        uint l_86_ = a_31_.inner[2];
        uint l_87_ = a_31_.inner[2];
        uint l_88_ = l_86_ * l_87_;
        uint _e254 = l_mut_41_;
        l_mut_41_ = _e254 + l_88_;
        uint l_89_ = a_31_.inner[3];
        uint l_90_ = a_31_.inner[1];
        uint l_91_ = l_89_ * l_90_;
        uint _e261 = l_mut_41_;
        l_mut_41_ = _e261 + l_91_;
        uint l_92_ = a_31_.inner[4];
        uint l_93_ = a_31_.inner[0];
        uint l_94_ = l_92_ * l_93_;
        uint _e268 = l_mut_41_;
        l_mut_41_ = _e268 + l_94_;
        uint _e270 = l_mut_41_;
        uint l_95_ = naga_mod(_e270, 58u);
        a_39_.inner[4] = l_95_;
        uint _e274 = l_mut_41_;
        uint l_96_ = naga_div(_e274, 58u);
        l_mut_40_ = l_96_;
        uint _e277 = l_mut_40_;
        l_mut_41_ = _e277;
        uint l_97_ = a_31_.inner[0];
        uint l_98_ = a_31_.inner[5];
        uint l_99_ = l_97_ * l_98_;
        uint _e283 = l_mut_41_;
        l_mut_41_ = _e283 + l_99_;
        uint l_100_ = a_31_.inner[1];
        uint l_101_ = a_31_.inner[4];
        uint l_102_ = l_100_ * l_101_;
        uint _e290 = l_mut_41_;
        l_mut_41_ = _e290 + l_102_;
        uint l_103_ = a_31_.inner[2];
        uint l_104_ = a_31_.inner[3];
        uint l_105_ = l_103_ * l_104_;
        uint _e297 = l_mut_41_;
        l_mut_41_ = _e297 + l_105_;
        uint l_106_ = a_31_.inner[3];
        uint l_107_ = a_31_.inner[2];
        uint l_108_ = l_106_ * l_107_;
        uint _e304 = l_mut_41_;
        l_mut_41_ = _e304 + l_108_;
        uint l_109_ = a_31_.inner[4];
        uint l_110_ = a_31_.inner[1];
        uint l_111_ = l_109_ * l_110_;
        uint _e311 = l_mut_41_;
        l_mut_41_ = _e311 + l_111_;
        uint l_112_ = a_31_.inner[5];
        uint l_113_ = a_31_.inner[0];
        uint l_114_ = l_112_ * l_113_;
        uint _e318 = l_mut_41_;
        l_mut_41_ = _e318 + l_114_;
        uint _e320 = l_mut_41_;
        uint l_115_ = naga_mod(_e320, 58u);
        a_39_.inner[5] = l_115_;
        uint _e324 = l_mut_41_;
        uint l_116_ = naga_div(_e324, 58u);
        l_mut_40_ = l_116_;
        l_mut_40_ = 0u;
        uint _e328 = l_mut_40_;
        l_mut_41_ = _e328;
        uint l_118_ = a_39_.inner[0];
        uint l_119_ = a_31_.inner[0];
        uint l_120_ = l_118_ * l_119_;
        uint _e334 = l_mut_41_;
        l_mut_41_ = _e334 + l_120_;
        uint _e336 = l_mut_41_;
        uint l_121_ = naga_mod(_e336, 58u);
        a_117_.inner[0] = l_121_;
        uint _e340 = l_mut_41_;
        uint l_122_ = naga_div(_e340, 58u);
        l_mut_40_ = l_122_;
        uint _e343 = l_mut_40_;
        l_mut_41_ = _e343;
        uint l_123_ = a_39_.inner[0];
        uint l_124_ = a_31_.inner[1];
        uint l_125_ = l_123_ * l_124_;
        uint _e349 = l_mut_41_;
        l_mut_41_ = _e349 + l_125_;
        uint l_126_ = a_39_.inner[1];
        uint l_127_ = a_31_.inner[0];
        uint l_128_ = l_126_ * l_127_;
        uint _e356 = l_mut_41_;
        l_mut_41_ = _e356 + l_128_;
        uint _e358 = l_mut_41_;
        uint l_129_ = naga_mod(_e358, 58u);
        a_117_.inner[1] = l_129_;
        uint _e362 = l_mut_41_;
        uint l_130_ = naga_div(_e362, 58u);
        l_mut_40_ = l_130_;
        uint _e365 = l_mut_40_;
        l_mut_41_ = _e365;
        uint l_131_ = a_39_.inner[0];
        uint l_132_ = a_31_.inner[2];
        uint l_133_ = l_131_ * l_132_;
        uint _e371 = l_mut_41_;
        l_mut_41_ = _e371 + l_133_;
        uint l_134_ = a_39_.inner[1];
        uint l_135_ = a_31_.inner[1];
        uint l_136_ = l_134_ * l_135_;
        uint _e378 = l_mut_41_;
        l_mut_41_ = _e378 + l_136_;
        uint l_137_ = a_39_.inner[2];
        uint l_138_ = a_31_.inner[0];
        uint l_139_ = l_137_ * l_138_;
        uint _e385 = l_mut_41_;
        l_mut_41_ = _e385 + l_139_;
        uint _e387 = l_mut_41_;
        uint l_140_ = naga_mod(_e387, 58u);
        a_117_.inner[2] = l_140_;
        uint _e391 = l_mut_41_;
        uint l_141_ = naga_div(_e391, 58u);
        l_mut_40_ = l_141_;
        uint _e394 = l_mut_40_;
        l_mut_41_ = _e394;
        uint l_142_ = a_39_.inner[0];
        uint l_143_ = a_31_.inner[3];
        uint l_144_ = l_142_ * l_143_;
        uint _e400 = l_mut_41_;
        l_mut_41_ = _e400 + l_144_;
        uint l_145_ = a_39_.inner[1];
        uint l_146_ = a_31_.inner[2];
        uint l_147_ = l_145_ * l_146_;
        uint _e407 = l_mut_41_;
        l_mut_41_ = _e407 + l_147_;
        uint l_148_ = a_39_.inner[2];
        uint l_149_ = a_31_.inner[1];
        uint l_150_ = l_148_ * l_149_;
        uint _e414 = l_mut_41_;
        l_mut_41_ = _e414 + l_150_;
        uint l_151_ = a_39_.inner[3];
        uint l_152_ = a_31_.inner[0];
        uint l_153_ = l_151_ * l_152_;
        uint _e421 = l_mut_41_;
        l_mut_41_ = _e421 + l_153_;
        uint _e423 = l_mut_41_;
        uint l_154_ = naga_mod(_e423, 58u);
        a_117_.inner[3] = l_154_;
        uint _e427 = l_mut_41_;
        uint l_155_ = naga_div(_e427, 58u);
        l_mut_40_ = l_155_;
        uint _e430 = l_mut_40_;
        l_mut_41_ = _e430;
        uint l_156_ = a_39_.inner[0];
        uint l_157_ = a_31_.inner[4];
        uint l_158_ = l_156_ * l_157_;
        uint _e436 = l_mut_41_;
        l_mut_41_ = _e436 + l_158_;
        uint l_159_ = a_39_.inner[1];
        uint l_160_ = a_31_.inner[3];
        uint l_161_ = l_159_ * l_160_;
        uint _e443 = l_mut_41_;
        l_mut_41_ = _e443 + l_161_;
        uint l_162_ = a_39_.inner[2];
        uint l_163_ = a_31_.inner[2];
        uint l_164_ = l_162_ * l_163_;
        uint _e450 = l_mut_41_;
        l_mut_41_ = _e450 + l_164_;
        uint l_165_ = a_39_.inner[3];
        uint l_166_ = a_31_.inner[1];
        uint l_167_ = l_165_ * l_166_;
        uint _e457 = l_mut_41_;
        l_mut_41_ = _e457 + l_167_;
        uint l_168_ = a_39_.inner[4];
        uint l_169_ = a_31_.inner[0];
        uint l_170_ = l_168_ * l_169_;
        uint _e464 = l_mut_41_;
        l_mut_41_ = _e464 + l_170_;
        uint _e466 = l_mut_41_;
        uint l_171_ = naga_mod(_e466, 58u);
        a_117_.inner[4] = l_171_;
        uint _e470 = l_mut_41_;
        uint l_172_ = naga_div(_e470, 58u);
        l_mut_40_ = l_172_;
        uint _e473 = l_mut_40_;
        l_mut_41_ = _e473;
        uint l_173_ = a_39_.inner[0];
        uint l_174_ = a_31_.inner[5];
        uint l_175_ = l_173_ * l_174_;
        uint _e479 = l_mut_41_;
        l_mut_41_ = _e479 + l_175_;
        uint l_176_ = a_39_.inner[1];
        uint l_177_ = a_31_.inner[4];
        uint l_178_ = l_176_ * l_177_;
        uint _e486 = l_mut_41_;
        l_mut_41_ = _e486 + l_178_;
        uint l_179_ = a_39_.inner[2];
        uint l_180_ = a_31_.inner[3];
        uint l_181_ = l_179_ * l_180_;
        uint _e493 = l_mut_41_;
        l_mut_41_ = _e493 + l_181_;
        uint l_182_ = a_39_.inner[3];
        uint l_183_ = a_31_.inner[2];
        uint l_184_ = l_182_ * l_183_;
        uint _e500 = l_mut_41_;
        l_mut_41_ = _e500 + l_184_;
        uint l_185_ = a_39_.inner[4];
        uint l_186_ = a_31_.inner[1];
        uint l_187_ = l_185_ * l_186_;
        uint _e507 = l_mut_41_;
        l_mut_41_ = _e507 + l_187_;
        uint l_188_ = a_39_.inner[5];
        uint l_189_ = a_31_.inner[0];
        uint l_190_ = l_188_ * l_189_;
        uint _e514 = l_mut_41_;
        l_mut_41_ = _e514 + l_190_;
        uint _e516 = l_mut_41_;
        uint l_191_ = naga_mod(_e516, 58u);
        a_117_.inner[5] = l_191_;
        uint _e520 = l_mut_41_;
        uint l_192_ = naga_div(_e520, 58u);
        l_mut_40_ = l_192_;
        l_mut_193_ = true;
        uint l_194_ = a_39_.inner[3];
        uint l_195_ = a_117_.inner[3];
        ulong l_196_ = static_cast<ulong>(l_194_);
        ulong l_197_ = 1uL << static_cast<uint>(as_type<ulong>(l_196_));
        ulong l_198_ = static_cast<ulong>(l_195_);
        ulong l_199_ = 1uL << static_cast<uint>(as_type<ulong>(l_198_));
        ulong l_200_ = l_197_ | l_199_;
        bool l_201_ = l_194_ == l_195_;
        ulong _e540 = l_mut_30_;
        ulong l_202_ = _e540 | l_3_;
        ulong l_203_ = l_202_ & l_200_;
        bool l_204_ = l_203_ != 0uL;
        if (!(l_201_)) {
            local = l_204_;
        } else {
            local = true;
        }
        bool l_205_ = local;
        if (l_205_) {
            l_mut_193_ = false;
        }
        ulong _e551 = l_mut_30_;
        l_mut_30_ = _e551 | l_200_;
        uint l_206_ = a_39_.inner[4];
        uint l_207_ = a_117_.inner[4];
        ulong l_208_ = static_cast<ulong>(l_206_);
        ulong l_209_ = 1uL << static_cast<uint>(as_type<ulong>(l_208_));
        ulong l_210_ = static_cast<ulong>(l_207_);
        ulong l_211_ = 1uL << static_cast<uint>(as_type<ulong>(l_210_));
        ulong l_212_ = l_209_ | l_211_;
        bool l_213_ = l_206_ == l_207_;
        ulong _e569 = l_mut_30_;
        ulong l_214_ = _e569 | l_3_;
        ulong l_215_ = l_214_ & l_212_;
        bool l_216_ = l_215_ != 0uL;
        if (!(l_213_)) {
            local_1 = l_216_;
        } else {
            local_1 = true;
        }
        bool l_217_ = local_1;
        if (l_217_) {
            l_mut_193_ = false;
        }
        ulong _e580 = l_mut_30_;
        l_mut_30_ = _e580 | l_212_;
        bool _e582 = l_mut_193_;
        bool l_218_ = !(_e582);
        if (l_218_) {
            l_mut_30_ = as_type<ulong>(-1L);
        }
        ulong _e586 = l_mut_30_;
        ulong l_219_ = _e586 | l_3_;
        uint _e592 = info.scalars_u32_.inner[0];
        uint l_220_ = workgroup_id.y * _e592;
        uint _e594 = l_mut_17_;
        uint l_221_ = l_220_ + _e594;
        uint l_222_ = 2u * l_221_;
        ulong _e598 = l_mut_30_;
        uint l_223_ = static_cast<uint>(as_type<ulong>(_e598));
        buffer_4_global[l_222_] = l_223_;
        uint l_224_ = 2u * l_221_;
        uint l_225_ = l_224_ + 1u;
        ulong _e607 = l_mut_30_;
        ulong l_226_ = _e607 >> static_cast<uint>(as_type<ulong>(32uL));
        uint l_227_ = static_cast<uint>(as_type<ulong>(l_226_));
        buffer_4_global[l_225_] = l_227_;
        uint l_228_ = a_39_.inner[5];
        uint l_229_ = a_117_.inner[5];
        uint l_230_ = a_31_.inner[0];
        uint l_231_ = 2u * l_230_;
        uint l_232_ = naga_mod(l_231_, 58u);
        uint l_233_ = l_230_ * l_230_;
        uint l_234_ = naga_mod(l_233_, 58u);
        uint l_235_ = 3u * l_234_;
        uint l_236_ = naga_mod(l_235_, 58u);
        uint l_237_ = l_229_ << 8u;
        uint l_238_ = l_228_ | l_237_;
        uint l_239_ = l_232_ << 16u;
        uint l_240_ = l_238_ | l_239_;
        uint l_241_ = l_236_ << 24u;
        uint l_242_ = l_240_ | l_241_;
        buffer_5_global[l_221_] = l_242_;
        bool _e644 = l_mut_193_;
        if (_e644) {
            l_mut_41_ = l_228_;
            l_mut_243_ = l_229_;
            l_mut_244_ = 0u;
            uint2 loop_bound_1 = uint2(4294967295u);
            while(true) {
                if (metal::all(loop_bound_1 == uint2(0u))) { break; }
                loop_bound_1 -= uint2(loop_bound_1.y == 0u, 1u);
                uint _e646 = l_mut_244_;
                bool l_245_ = _e646 < 58u;
                bool l_246_ = !(l_245_);
                if (l_246_) {
                    break;
                }
                uint _e650 = l_mut_41_;
                l_mut_247_ = _e650;
                uint _e651 = l_mut_243_;
                l_mut_248_ = _e651;
                uint _e652 = l_mut_247_;
                ulong l_249_ = static_cast<ulong>(_e652);
                ulong l_250_ = 1uL << static_cast<uint>(as_type<ulong>(l_249_));
                uint _e658 = l_mut_248_;
                ulong l_251_ = static_cast<ulong>(_e658);
                ulong l_252_ = 1uL << static_cast<uint>(as_type<ulong>(l_251_));
                ulong l_253_ = l_250_ | l_252_;
                uint _e665 = l_mut_247_;
                uint _e666 = l_mut_248_;
                bool l_254_ = _e665 != _e666;
                ulong l_255_ = l_219_ & l_253_;
                bool l_256_ = l_255_ == 0uL;
                if (l_254_) {
                    local_2 = l_256_;
                } else {
                    local_2 = false;
                }
                bool l_257_ = local_2;
                if (l_257_) {
                    uint _e676 = l_mut_244_;
                    uint _e679 = metal::atomic_fetch_add_explicit(&shared_memory_4_.inner[_e676], 1u, metal::memory_order_relaxed);
                    uint _e680 = l_mut_244_;
                    uint l_260_ = _e680 * l_10_;
                    uint l_261_ = l_14_ + l_260_;
                    uint l_262_ = l_261_ + _e679;
                    uint _e686 = l_mut_17_;
                    buffer_6_global[l_262_] = _e686;
                }
                uint _e687 = l_mut_41_;
                l_mut_41_ = _e687 + l_232_;
                uint _e689 = l_mut_41_;
                bool l_263_ = _e689 >= 58u;
                if (l_263_) {
                    uint _e692 = l_mut_41_;
                    l_mut_41_ = _e692 - 58u;
                }
                uint _e695 = l_mut_243_;
                l_mut_243_ = _e695 + l_236_;
                uint _e697 = l_mut_243_;
                bool l_264_ = _e697 >= 58u;
                if (l_264_) {
                    uint _e700 = l_mut_243_;
                    l_mut_243_ = _e700 - 58u;
                }
                uint _e703 = l_mut_244_;
                l_mut_244_ = _e703 + 1u;
            }
        }
        uint _e706 = l_mut_17_;
        l_mut_17_ = _e706 + WORKGROUP_SIZE_X;
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    bool l_265_ = local_invocation_id.x < 58u;
    if (l_265_) {
        uint l_266_ = workgroup_id.y * 58u;
        uint l_267_ = l_266_ + local_invocation_id.x;
        uint l_268_ = l_267_ * 57u;
        uint l_269_ = l_268_ + workgroup_id.x;
        uint l_271_ = metal::atomic_load_explicit(&shared_memory_4_.inner[local_invocation_id.x], metal::memory_order_relaxed);
        buffer_7_global[l_269_] = l_271_;
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    bool l_272_ = local_invocation_id.x == 0u;
    if (l_272_) {
        uint _e733 = metal::atomic_fetch_add_explicit(&buffer_8_global[3], 1u, metal::memory_order_relaxed);
        return;
    } else {
        return;
    }
}
