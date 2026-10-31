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
};

typedef uint type_1[1];
typedef metal::atomic_uint type_3[1];
struct type_4 {
    uint inner[8];
};
struct type_5 {
    uint inner[14];
};
struct info_st {
    type_4 scalars_u32_;
    type_5 static_meta;
};
struct type_6 {
    uint inner[1792];
};
struct type_8 {
    uint inner[2];
};
struct type_9 {
    uint inner[3];
};
struct type_10 {
    uint inner[4];
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


struct niceonly_kernelInput {
};
kernel void niceonly_kernel(
  metal::uint3 global_id [[thread_position_in_grid]]
, metal::uint3 local_invocation_id [[thread_position_in_threadgroup]]
, metal::uint3 num_workgroups [[threadgroups_per_grid]]
, device type_1 const& buffer_0_global [[user(fake0)]]
, device type_1 const& buffer_1_global [[user(fake0)]]
, device type_1 const& buffer_2_global [[user(fake0)]]
, device type_1& buffer_3_global [[user(fake0)]]
, device type_3& buffer_4_global [[user(fake0)]]
, device type_1 const& buffer_5_global [[user(fake0)]]
, device type_1 const& buffer_6_global [[user(fake0)]]
, device info_st const& info [[user(fake0)]]
, threadgroup type_6& shared_memory_13_
, constant _mslBufferSizes& _buffer_sizes [[user(fake0)]]
) {
    if (metal::all(local_invocation_id == metal::uint3(0u))) {
        shared_memory_13_ = {};
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    type_8 a_132_ = {};
    type_9 a_137_ = {};
    type_9 a_217_ = {};
    type_9 a_266_ = {};
    type_8 a_369_ = {};
    type_10 a_374_ = {};
    bool l_mut_119_ = {};
    int l_mut_429_ = {};
    int l_mut_439_ = {};
    int l_mut_622_ = {};
    ulong l_mut_28_ = {};
    ulong l_mut_39_ = {};
    ulong l_mut_44_ = {};
    ulong l_mut_91_ = {};
    ulong l_mut_315_ = {};
    ulong l_mut_316_ = {};
    ulong l_mut_317_ = {};
    uint l_mut_16_ = {};
    uint l_mut_46_ = {};
    uint l_mut_94_ = {};
    uint l_mut_138_ = {};
    uint l_mut_322_ = {};
    uint l_mut_324_ = {};
    bool local = {};
    bool local_1 = {};
    bool local_2 = {};
    bool local_3 = {};
    bool local_4 = {};
    bool local_5 = {};
    uint _e30 = info.scalars_u32_.inner[7];
    uint l_0_ = 1u << _e30;
    uint l_1_ = l_0_ - 1u;
    uint l_2_ = global_id.x & l_1_;
    uint l_3_ = num_workgroups.x * WORKGROUP_SIZE_X;
    uint _e42 = info.scalars_u32_.inner[7];
    uint l_4_ = l_3_ >> _e42;
    uint _e47 = info.scalars_u32_.inner[1];
    ulong l_5_ = static_cast<ulong>(_e47);
    ulong l_6_ = l_5_ << static_cast<uint>(as_type<ulong>(32uL));
    uint _e56 = info.scalars_u32_.inner[0];
    ulong l_7_ = static_cast<ulong>(_e56);
    ulong l_8_ = l_6_ | l_7_;
    uint _e62 = info.scalars_u32_.inner[3];
    ulong l_9_ = static_cast<ulong>(_e62);
    ulong l_10_ = l_9_ << static_cast<uint>(as_type<ulong>(32uL));
    uint _e71 = info.scalars_u32_.inner[2];
    ulong l_11_ = static_cast<ulong>(_e71);
    ulong l_12_ = l_10_ | l_11_;
    uint l_14_ = local_invocation_id.x * 7u;
    uint _e81 = info.scalars_u32_.inner[7];
    uint l_15_ = global_id.x >> _e81;
    l_mut_16_ = l_15_;
    uint2 loop_bound = uint2(4294967295u);
    while(true) {
        if (metal::all(loop_bound == uint2(0u))) { break; }
        loop_bound -= uint2(loop_bound.y == 0u, 1u);
        uint _e83 = l_mut_16_;
        uint _e87 = info.scalars_u32_.inner[5];
        bool l_17_ = _e83 < _e87;
        bool l_18_ = !(l_17_);
        if (l_18_) {
            break;
        }
        uint _e91 = l_mut_16_;
        uint l_19_ = 2u * _e91;
        uint l_20_ = buffer_1_global[l_19_];
        uint _e97 = l_mut_16_;
        uint l_21_ = 2u * _e97;
        uint l_22_ = l_21_ + 1u;
        uint l_23_ = buffer_1_global[l_22_];
        ulong l_24_ = static_cast<ulong>(l_23_);
        ulong l_25_ = l_24_ << static_cast<uint>(as_type<ulong>(32uL));
        ulong l_26_ = static_cast<ulong>(l_20_);
        ulong l_27_ = l_25_ | l_26_;
        l_mut_28_ = 0uL;
        uint _e113 = l_mut_16_;
        uint l_29_ = 2u * _e113;
        uint l_30_ = l_29_ + 1u;
        uint l_31_ = buffer_6_global[l_30_];
        ulong l_32_ = static_cast<ulong>(l_31_);
        ulong l_33_ = l_32_ << static_cast<uint>(as_type<ulong>(32uL));
        uint _e126 = l_mut_16_;
        uint l_34_ = 2u * _e126;
        uint l_35_ = buffer_6_global[l_34_];
        ulong l_36_ = static_cast<ulong>(l_35_);
        ulong l_37_ = l_33_ | l_36_;
        l_mut_28_ = l_37_;
        ulong l_38_ = l_8_ + l_27_;
        l_mut_39_ = l_12_;
        bool l_40_ = l_38_ < l_8_;
        if (l_40_) {
            ulong _e135 = l_mut_39_;
            l_mut_39_ = _e135 + 1uL;
        }
        uint _e139 = l_mut_16_;
        uint l_41_ = buffer_2_global[_e139];
        ulong l_42_ = static_cast<ulong>(l_41_);
        ulong l_43_ = l_38_ + l_42_;
        ulong _e144 = l_mut_39_;
        l_mut_44_ = _e144;
        bool l_45_ = l_43_ < l_38_;
        if (l_45_) {
            ulong _e146 = l_mut_44_;
            l_mut_44_ = _e146 + 1uL;
        }
        l_mut_46_ = 0u;
        uint _e150 = l_mut_46_;
        uint l_47_ = _e150 << 8u;
        uint l_48_ = l_23_ >> 24u;
        uint l_49_ = l_48_ & 255u;
        uint l_50_ = l_47_ | l_49_;
        uint l_51_ = naga_mod(l_50_, 2496000u);
        l_mut_46_ = l_51_;
        uint _e160 = l_mut_46_;
        uint l_52_ = _e160 << 8u;
        uint l_53_ = l_23_ >> 16u;
        uint l_54_ = l_53_ & 255u;
        uint l_55_ = l_52_ | l_54_;
        uint l_56_ = naga_mod(l_55_, 2496000u);
        l_mut_46_ = l_56_;
        uint _e170 = l_mut_46_;
        uint l_57_ = _e170 << 8u;
        uint l_58_ = l_23_ >> 8u;
        uint l_59_ = l_58_ & 255u;
        uint l_60_ = l_57_ | l_59_;
        uint l_61_ = naga_mod(l_60_, 2496000u);
        l_mut_46_ = l_61_;
        uint _e180 = l_mut_46_;
        uint l_62_ = _e180 << 8u;
        uint l_63_ = l_23_ >> 0u;
        uint l_64_ = l_63_ & 255u;
        uint l_65_ = l_62_ | l_64_;
        uint l_66_ = naga_mod(l_65_, 2496000u);
        l_mut_46_ = l_66_;
        uint _e190 = l_mut_46_;
        uint l_67_ = _e190 << 8u;
        uint l_68_ = l_20_ >> 24u;
        uint l_69_ = l_68_ & 255u;
        uint l_70_ = l_67_ | l_69_;
        uint l_71_ = naga_mod(l_70_, 2496000u);
        l_mut_46_ = l_71_;
        uint _e200 = l_mut_46_;
        uint l_72_ = _e200 << 8u;
        uint l_73_ = l_20_ >> 16u;
        uint l_74_ = l_73_ & 255u;
        uint l_75_ = l_72_ | l_74_;
        uint l_76_ = naga_mod(l_75_, 2496000u);
        l_mut_46_ = l_76_;
        uint _e210 = l_mut_46_;
        uint l_77_ = _e210 << 8u;
        uint l_78_ = l_20_ >> 8u;
        uint l_79_ = l_78_ & 255u;
        uint l_80_ = l_77_ | l_79_;
        uint l_81_ = naga_mod(l_80_, 2496000u);
        l_mut_46_ = l_81_;
        uint _e220 = l_mut_46_;
        uint l_82_ = _e220 << 8u;
        uint l_83_ = l_20_ >> 0u;
        uint l_84_ = l_83_ & 255u;
        uint l_85_ = l_82_ | l_84_;
        uint l_86_ = naga_mod(l_85_, 2496000u);
        l_mut_46_ = l_86_;
        uint _e233 = info.scalars_u32_.inner[4];
        uint _e234 = l_mut_46_;
        uint l_87_ = _e233 + _e234;
        uint l_88_ = naga_mod(l_87_, 2496000u);
        ulong l_89_ = static_cast<ulong>(l_88_);
        ulong l_90_ = l_38_ - l_89_;
        ulong _e240 = l_mut_39_;
        l_mut_91_ = _e240;
        ulong l_92_ = static_cast<ulong>(l_88_);
        bool l_93_ = l_38_ < l_92_;
        if (l_93_) {
            ulong _e243 = l_mut_91_;
            l_mut_91_ = _e243 - 1uL;
        }
        l_mut_46_ = 0u;
        l_mut_94_ = 144064u;
        uint2 loop_bound_1 = uint2(4294967295u);
        while(true) {
            if (metal::all(loop_bound_1 == uint2(0u))) { break; }
            loop_bound_1 -= uint2(loop_bound_1.y == 0u, 1u);
            uint _e248 = l_mut_46_;
            uint _e249 = l_mut_94_;
            bool l_95_ = _e248 < _e249;
            bool l_96_ = !(l_95_);
            if (l_96_) {
                break;
            }
            uint _e252 = l_mut_46_;
            uint _e253 = l_mut_94_;
            uint l_97_ = _e252 + _e253;
            uint l_98_ = l_97_ >> 1u;
            uint l_99_ = buffer_0_global[l_98_];
            bool l_100_ = l_99_ < l_88_;
            if (l_100_) {
                uint l_101_ = l_98_ + 1u;
                l_mut_46_ = l_101_;
            } else {
                l_mut_94_ = l_98_;
            }
        }
        uint _e263 = l_mut_46_;
        uint l_102_ = _e263 + l_2_;
        l_mut_46_ = l_102_;
        uint2 loop_bound_2 = uint2(4294967295u);
        while(true) {
            if (metal::all(loop_bound_2 == uint2(0u))) { break; }
            loop_bound_2 -= uint2(loop_bound_2.y == 0u, 1u);
            uint _e265 = l_mut_46_;
            uint l_103_ = naga_div(_e265, 144064u);
            uint l_104_ = l_103_ * 144064u;
            uint _e270 = l_mut_46_;
            uint l_105_ = _e270 - l_104_;
            ulong l_106_ = static_cast<ulong>(l_103_);
            ulong l_108_ = l_106_ * 2496000uL;
            uint l_109_ = buffer_0_global[l_105_];
            ulong l_110_ = static_cast<ulong>(l_109_);
            ulong l_111_ = l_108_ + l_110_;
            ulong l_112_ = l_90_ + l_111_;
            ulong _e281 = l_mut_91_;
            l_mut_39_ = _e281;
            bool l_113_ = l_112_ < l_90_;
            if (l_113_) {
                ulong _e283 = l_mut_39_;
                l_mut_39_ = _e283 + 1uL;
            }
            ulong _e286 = l_mut_39_;
            ulong _e287 = l_mut_44_;
            bool l_114_ = _e286 > _e287;
            ulong _e289 = l_mut_39_;
            ulong _e290 = l_mut_44_;
            bool l_115_ = _e289 == _e290;
            bool l_116_ = l_112_ >= l_43_;
            if (l_115_) {
                local = l_116_;
            } else {
                local = false;
            }
            bool l_117_ = local;
            if (!(l_114_)) {
                local_1 = l_117_;
            } else {
                local_1 = true;
            }
            bool l_118_ = local_1;
            if (l_118_) {
                break;
            }
            l_mut_119_ = false;
            uint l_120_ = 2u * l_105_;
            uint l_121_ = l_120_ + 1u;
            uint l_122_ = buffer_5_global[l_121_];
            ulong l_123_ = static_cast<ulong>(l_122_);
            ulong l_124_ = l_123_ << static_cast<uint>(as_type<ulong>(32uL));
            uint l_125_ = 2u * l_105_;
            uint l_126_ = buffer_5_global[l_125_];
            ulong l_127_ = static_cast<ulong>(l_126_);
            ulong l_128_ = l_124_ | l_127_;
            ulong _e322 = l_mut_28_;
            ulong l_129_ = l_128_ & _e322;
            bool l_130_ = l_129_ != 0uL;
            if (l_130_) {
                l_mut_119_ = true;
            }
            bool _e327 = l_mut_119_;
            bool l_131_ = !(_e327);
            if (l_131_) {
                l_mut_119_ = true;
                bool _e330 = l_mut_119_;
                if (_e330) {
                    ulong l_133_ = l_112_ >> static_cast<uint>(as_type<ulong>(0uL));
                    uint l_134_ = static_cast<uint>(as_type<ulong>(l_133_));
                    a_132_.inner[0] = l_134_;
                    ulong l_135_ = l_112_ >> static_cast<uint>(as_type<ulong>(32uL));
                    uint l_136_ = static_cast<uint>(as_type<ulong>(l_135_));
                    a_132_.inner[1] = l_136_;
                    l_mut_138_ = 0u;
                    uint l_139_ = a_132_.inner[1];
                    uint _e348 = l_mut_138_;
                    uint l_140_ = _e348 << 16u;
                    uint l_141_ = l_139_ >> 16u;
                    uint l_142_ = l_140_ | l_141_;
                    uint l_143_ = naga_div(l_142_, 64000u);
                    uint l_144_ = naga_mod(l_142_, 64000u);
                    uint l_145_ = l_144_ << 16u;
                    uint l_146_ = l_139_ & 65535u;
                    uint l_147_ = l_145_ | l_146_;
                    uint l_148_ = naga_mod(l_147_, 64000u);
                    l_mut_138_ = l_148_;
                    uint l_149_ = l_143_ << 16u;
                    uint l_150_ = naga_div(l_147_, 64000u);
                    uint l_151_ = l_149_ | l_150_;
                    a_132_.inner[1] = l_151_;
                    uint l_152_ = a_132_.inner[0];
                    uint _e373 = l_mut_138_;
                    uint l_153_ = _e373 << 16u;
                    uint l_154_ = l_152_ >> 16u;
                    uint l_155_ = l_153_ | l_154_;
                    uint l_156_ = naga_div(l_155_, 64000u);
                    uint l_157_ = naga_mod(l_155_, 64000u);
                    uint l_158_ = l_157_ << 16u;
                    uint l_159_ = l_152_ & 65535u;
                    uint l_160_ = l_158_ | l_159_;
                    uint l_161_ = naga_mod(l_160_, 64000u);
                    l_mut_138_ = l_161_;
                    uint l_162_ = l_156_ << 16u;
                    uint l_163_ = naga_div(l_160_, 64000u);
                    uint l_164_ = l_162_ | l_163_;
                    a_132_.inner[0] = l_164_;
                    uint _e397 = l_mut_138_;
                    a_137_.inner[0] = _e397;
                    l_mut_138_ = 0u;
                    uint l_165_ = a_132_.inner[1];
                    uint _e401 = l_mut_138_;
                    uint l_166_ = _e401 << 16u;
                    uint l_167_ = l_165_ >> 16u;
                    uint l_168_ = l_166_ | l_167_;
                    uint l_169_ = naga_div(l_168_, 64000u);
                    uint l_170_ = naga_mod(l_168_, 64000u);
                    uint l_171_ = l_170_ << 16u;
                    uint l_172_ = l_165_ & 65535u;
                    uint l_173_ = l_171_ | l_172_;
                    uint l_174_ = naga_mod(l_173_, 64000u);
                    l_mut_138_ = l_174_;
                    uint l_175_ = l_169_ << 16u;
                    uint l_176_ = naga_div(l_173_, 64000u);
                    uint l_177_ = l_175_ | l_176_;
                    a_132_.inner[1] = l_177_;
                    uint l_178_ = a_132_.inner[0];
                    uint _e426 = l_mut_138_;
                    uint l_179_ = _e426 << 16u;
                    uint l_180_ = l_178_ >> 16u;
                    uint l_181_ = l_179_ | l_180_;
                    uint l_182_ = naga_div(l_181_, 64000u);
                    uint l_183_ = naga_mod(l_181_, 64000u);
                    uint l_184_ = l_183_ << 16u;
                    uint l_185_ = l_178_ & 65535u;
                    uint l_186_ = l_184_ | l_185_;
                    uint l_187_ = naga_mod(l_186_, 64000u);
                    l_mut_138_ = l_187_;
                    uint l_188_ = l_182_ << 16u;
                    uint l_189_ = naga_div(l_186_, 64000u);
                    uint l_190_ = l_188_ | l_189_;
                    a_132_.inner[0] = l_190_;
                    uint _e450 = l_mut_138_;
                    a_137_.inner[1] = _e450;
                    l_mut_138_ = 0u;
                    uint l_191_ = a_132_.inner[1];
                    uint _e454 = l_mut_138_;
                    uint l_192_ = _e454 << 16u;
                    uint l_193_ = l_191_ >> 16u;
                    uint l_194_ = l_192_ | l_193_;
                    uint l_195_ = naga_div(l_194_, 64000u);
                    uint l_196_ = naga_mod(l_194_, 64000u);
                    uint l_197_ = l_196_ << 16u;
                    uint l_198_ = l_191_ & 65535u;
                    uint l_199_ = l_197_ | l_198_;
                    uint l_200_ = naga_mod(l_199_, 64000u);
                    l_mut_138_ = l_200_;
                    uint l_201_ = l_195_ << 16u;
                    uint l_202_ = naga_div(l_199_, 64000u);
                    uint l_203_ = l_201_ | l_202_;
                    a_132_.inner[1] = l_203_;
                    uint l_204_ = a_132_.inner[0];
                    uint _e479 = l_mut_138_;
                    uint l_205_ = _e479 << 16u;
                    uint l_206_ = l_204_ >> 16u;
                    uint l_207_ = l_205_ | l_206_;
                    uint l_208_ = naga_div(l_207_, 64000u);
                    uint l_209_ = naga_mod(l_207_, 64000u);
                    uint l_210_ = l_209_ << 16u;
                    uint l_211_ = l_204_ & 65535u;
                    uint l_212_ = l_210_ | l_211_;
                    uint l_213_ = naga_mod(l_212_, 64000u);
                    l_mut_138_ = l_213_;
                    uint l_214_ = l_208_ << 16u;
                    uint l_215_ = naga_div(l_212_, 64000u);
                    uint l_216_ = l_214_ | l_215_;
                    a_132_.inner[0] = l_216_;
                    uint _e503 = l_mut_138_;
                    a_137_.inner[2] = _e503;
                    a_217_.inner[0] = 0u;
                    a_217_.inner[1] = 0u;
                    a_217_.inner[2] = 0u;
                    l_mut_138_ = 0u;
                    uint l_218_ = a_137_.inner[0];
                    uint l_219_ = a_137_.inner[0];
                    uint l_220_ = l_218_ * l_219_;
                    uint l_221_ = a_217_.inner[0];
                    uint l_222_ = l_220_ + l_221_;
                    uint _e519 = l_mut_138_;
                    uint l_223_ = l_222_ + _e519;
                    uint l_224_ = naga_mod(l_223_, 64000u);
                    a_217_.inner[0] = l_224_;
                    uint l_225_ = naga_div(l_223_, 64000u);
                    l_mut_138_ = l_225_;
                    uint l_226_ = a_137_.inner[0];
                    uint l_227_ = a_137_.inner[1];
                    uint l_228_ = l_226_ * l_227_;
                    uint l_229_ = a_217_.inner[1];
                    uint l_230_ = l_228_ + l_229_;
                    uint _e534 = l_mut_138_;
                    uint l_231_ = l_230_ + _e534;
                    uint l_232_ = naga_mod(l_231_, 64000u);
                    a_217_.inner[1] = l_232_;
                    uint l_233_ = naga_div(l_231_, 64000u);
                    l_mut_138_ = l_233_;
                    uint l_234_ = a_137_.inner[0];
                    uint l_235_ = a_137_.inner[2];
                    uint l_236_ = l_234_ * l_235_;
                    uint l_237_ = a_217_.inner[2];
                    uint l_238_ = l_236_ + l_237_;
                    uint _e549 = l_mut_138_;
                    uint l_239_ = l_238_ + _e549;
                    uint l_240_ = naga_mod(l_239_, 64000u);
                    a_217_.inner[2] = l_240_;
                    uint l_241_ = naga_div(l_239_, 64000u);
                    l_mut_138_ = l_241_;
                    l_mut_138_ = 0u;
                    uint l_242_ = a_137_.inner[1];
                    uint l_243_ = a_137_.inner[0];
                    uint l_244_ = l_242_ * l_243_;
                    uint l_245_ = a_217_.inner[1];
                    uint l_246_ = l_244_ + l_245_;
                    uint _e565 = l_mut_138_;
                    uint l_247_ = l_246_ + _e565;
                    uint l_248_ = naga_mod(l_247_, 64000u);
                    a_217_.inner[1] = l_248_;
                    uint l_249_ = naga_div(l_247_, 64000u);
                    l_mut_138_ = l_249_;
                    uint l_250_ = a_137_.inner[1];
                    uint l_251_ = a_137_.inner[1];
                    uint l_252_ = l_250_ * l_251_;
                    uint l_253_ = a_217_.inner[2];
                    uint l_254_ = l_252_ + l_253_;
                    uint _e580 = l_mut_138_;
                    uint l_255_ = l_254_ + _e580;
                    uint l_256_ = naga_mod(l_255_, 64000u);
                    a_217_.inner[2] = l_256_;
                    uint l_257_ = naga_div(l_255_, 64000u);
                    l_mut_138_ = l_257_;
                    l_mut_138_ = 0u;
                    uint l_258_ = a_137_.inner[2];
                    uint l_259_ = a_137_.inner[0];
                    uint l_260_ = l_258_ * l_259_;
                    uint l_261_ = a_217_.inner[2];
                    uint l_262_ = l_260_ + l_261_;
                    uint _e596 = l_mut_138_;
                    uint l_263_ = l_262_ + _e596;
                    uint l_264_ = naga_mod(l_263_, 64000u);
                    a_217_.inner[2] = l_264_;
                    uint l_265_ = naga_div(l_263_, 64000u);
                    l_mut_138_ = l_265_;
                    a_266_.inner[0] = 0u;
                    a_266_.inner[1] = 0u;
                    a_266_.inner[2] = 0u;
                    l_mut_138_ = 0u;
                    uint l_267_ = a_217_.inner[0];
                    uint l_268_ = a_137_.inner[0];
                    uint l_269_ = l_267_ * l_268_;
                    uint l_270_ = a_266_.inner[0];
                    uint l_271_ = l_269_ + l_270_;
                    uint _e618 = l_mut_138_;
                    uint l_272_ = l_271_ + _e618;
                    uint l_273_ = naga_mod(l_272_, 64000u);
                    a_266_.inner[0] = l_273_;
                    uint l_274_ = naga_div(l_272_, 64000u);
                    l_mut_138_ = l_274_;
                    uint l_275_ = a_217_.inner[0];
                    uint l_276_ = a_137_.inner[1];
                    uint l_277_ = l_275_ * l_276_;
                    uint l_278_ = a_266_.inner[1];
                    uint l_279_ = l_277_ + l_278_;
                    uint _e633 = l_mut_138_;
                    uint l_280_ = l_279_ + _e633;
                    uint l_281_ = naga_mod(l_280_, 64000u);
                    a_266_.inner[1] = l_281_;
                    uint l_282_ = naga_div(l_280_, 64000u);
                    l_mut_138_ = l_282_;
                    uint l_283_ = a_217_.inner[0];
                    uint l_284_ = a_137_.inner[2];
                    uint l_285_ = l_283_ * l_284_;
                    uint l_286_ = a_266_.inner[2];
                    uint l_287_ = l_285_ + l_286_;
                    uint _e648 = l_mut_138_;
                    uint l_288_ = l_287_ + _e648;
                    uint l_289_ = naga_mod(l_288_, 64000u);
                    a_266_.inner[2] = l_289_;
                    uint l_290_ = naga_div(l_288_, 64000u);
                    l_mut_138_ = l_290_;
                    l_mut_138_ = 0u;
                    uint l_291_ = a_217_.inner[1];
                    uint l_292_ = a_137_.inner[0];
                    uint l_293_ = l_291_ * l_292_;
                    uint l_294_ = a_266_.inner[1];
                    uint l_295_ = l_293_ + l_294_;
                    uint _e664 = l_mut_138_;
                    uint l_296_ = l_295_ + _e664;
                    uint l_297_ = naga_mod(l_296_, 64000u);
                    a_266_.inner[1] = l_297_;
                    uint l_298_ = naga_div(l_296_, 64000u);
                    l_mut_138_ = l_298_;
                    uint l_299_ = a_217_.inner[1];
                    uint l_300_ = a_137_.inner[1];
                    uint l_301_ = l_299_ * l_300_;
                    uint l_302_ = a_266_.inner[2];
                    uint l_303_ = l_301_ + l_302_;
                    uint _e679 = l_mut_138_;
                    uint l_304_ = l_303_ + _e679;
                    uint l_305_ = naga_mod(l_304_, 64000u);
                    a_266_.inner[2] = l_305_;
                    uint l_306_ = naga_div(l_304_, 64000u);
                    l_mut_138_ = l_306_;
                    l_mut_138_ = 0u;
                    uint l_307_ = a_217_.inner[2];
                    uint l_308_ = a_137_.inner[0];
                    uint l_309_ = l_307_ * l_308_;
                    uint l_310_ = a_266_.inner[2];
                    uint l_311_ = l_309_ + l_310_;
                    uint _e695 = l_mut_138_;
                    uint l_312_ = l_311_ + _e695;
                    uint l_313_ = naga_mod(l_312_, 64000u);
                    a_266_.inner[2] = l_313_;
                    uint l_314_ = naga_div(l_312_, 64000u);
                    l_mut_138_ = l_314_;
                    l_mut_315_ = 0uL;
                    l_mut_316_ = 0uL;
                    l_mut_317_ = 0uL;
                    l_mut_138_ = 0u;
                    uint2 loop_bound_3 = uint2(4294967295u);
                    while(true) {
                        if (metal::all(loop_bound_3 == uint2(0u))) { break; }
                        loop_bound_3 -= uint2(loop_bound_3.y == 0u, 1u);
                        uint _e706 = l_mut_138_;
                        bool l_318_ = _e706 < 2u;
                        bool l_319_ = !(l_318_);
                        if (l_319_) {
                            break;
                        }
                        uint _e710 = l_mut_138_;
                        bool l_320_ = _e710 == 0u;
                        if (l_320_) {
                            uint l_321_ = a_217_.inner[0];
                            l_mut_322_ = l_321_;
                        } else {
                            uint l_323_ = a_266_.inner[0];
                            l_mut_322_ = l_323_;
                        }
                        uint _e717 = l_mut_322_;
                        l_mut_324_ = _e717;
                        uint _e718 = l_mut_324_;
                        uint l_325_ = naga_mod(_e718, 40u);
                        uint _e721 = l_mut_324_;
                        l_mut_324_ = naga_div(_e721, 40u);
                        ulong l_326_ = static_cast<ulong>(l_325_);
                        ulong l_327_ = 1uL << static_cast<uint>(as_type<ulong>(l_326_));
                        ulong _e729 = l_mut_315_;
                        ulong l_328_ = _e729 & l_327_;
                        ulong _e731 = l_mut_317_;
                        l_mut_317_ = _e731 | l_328_;
                        ulong _e733 = l_mut_315_;
                        l_mut_315_ = _e733 | l_327_;
                        uint _e735 = l_mut_324_;
                        uint l_329_ = naga_mod(_e735, 40u);
                        uint _e738 = l_mut_324_;
                        l_mut_324_ = naga_div(_e738, 40u);
                        ulong l_330_ = static_cast<ulong>(l_329_);
                        ulong l_331_ = 1uL << static_cast<uint>(as_type<ulong>(l_330_));
                        ulong _e746 = l_mut_315_;
                        ulong l_332_ = _e746 & l_331_;
                        ulong _e748 = l_mut_317_;
                        l_mut_317_ = _e748 | l_332_;
                        ulong _e750 = l_mut_315_;
                        l_mut_315_ = _e750 | l_331_;
                        uint _e752 = l_mut_324_;
                        uint l_333_ = naga_mod(_e752, 40u);
                        uint _e755 = l_mut_324_;
                        l_mut_324_ = naga_div(_e755, 40u);
                        ulong l_334_ = static_cast<ulong>(l_333_);
                        ulong l_335_ = 1uL << static_cast<uint>(as_type<ulong>(l_334_));
                        ulong _e763 = l_mut_315_;
                        ulong l_336_ = _e763 & l_335_;
                        ulong _e765 = l_mut_317_;
                        l_mut_317_ = _e765 | l_336_;
                        ulong _e767 = l_mut_315_;
                        l_mut_315_ = _e767 | l_335_;
                        uint _e769 = l_mut_138_;
                        bool l_337_ = _e769 == 0u;
                        if (l_337_) {
                            uint l_338_ = a_217_.inner[1];
                            l_mut_324_ = l_338_;
                        } else {
                            uint l_339_ = a_266_.inner[1];
                            l_mut_324_ = l_339_;
                        }
                        uint _e776 = l_mut_324_;
                        l_mut_322_ = _e776;
                        uint _e777 = l_mut_322_;
                        uint l_340_ = naga_mod(_e777, 40u);
                        uint _e780 = l_mut_322_;
                        l_mut_322_ = naga_div(_e780, 40u);
                        ulong l_341_ = static_cast<ulong>(l_340_);
                        ulong l_342_ = 1uL << static_cast<uint>(as_type<ulong>(l_341_));
                        ulong _e788 = l_mut_315_;
                        ulong l_343_ = _e788 & l_342_;
                        ulong _e790 = l_mut_317_;
                        l_mut_317_ = _e790 | l_343_;
                        ulong _e792 = l_mut_315_;
                        l_mut_315_ = _e792 | l_342_;
                        uint _e794 = l_mut_322_;
                        uint l_344_ = naga_mod(_e794, 40u);
                        uint _e797 = l_mut_322_;
                        l_mut_322_ = naga_div(_e797, 40u);
                        ulong l_345_ = static_cast<ulong>(l_344_);
                        ulong l_346_ = 1uL << static_cast<uint>(as_type<ulong>(l_345_));
                        ulong _e805 = l_mut_315_;
                        ulong l_347_ = _e805 & l_346_;
                        ulong _e807 = l_mut_317_;
                        l_mut_317_ = _e807 | l_347_;
                        ulong _e809 = l_mut_315_;
                        l_mut_315_ = _e809 | l_346_;
                        uint _e811 = l_mut_322_;
                        uint l_348_ = naga_mod(_e811, 40u);
                        uint _e814 = l_mut_322_;
                        l_mut_322_ = naga_div(_e814, 40u);
                        ulong l_349_ = static_cast<ulong>(l_348_);
                        ulong l_350_ = 1uL << static_cast<uint>(as_type<ulong>(l_349_));
                        ulong _e822 = l_mut_315_;
                        ulong l_351_ = _e822 & l_350_;
                        ulong _e824 = l_mut_317_;
                        l_mut_317_ = _e824 | l_351_;
                        ulong _e826 = l_mut_315_;
                        l_mut_315_ = _e826 | l_350_;
                        uint _e828 = l_mut_138_;
                        bool l_352_ = _e828 == 0u;
                        if (l_352_) {
                            uint l_353_ = a_217_.inner[2];
                            l_mut_324_ = l_353_;
                        } else {
                            uint l_354_ = a_266_.inner[2];
                            l_mut_324_ = l_354_;
                        }
                        uint _e835 = l_mut_324_;
                        l_mut_322_ = _e835;
                        uint _e836 = l_mut_322_;
                        uint l_355_ = naga_mod(_e836, 40u);
                        uint _e839 = l_mut_322_;
                        l_mut_322_ = naga_div(_e839, 40u);
                        ulong l_356_ = static_cast<ulong>(l_355_);
                        ulong l_357_ = 1uL << static_cast<uint>(as_type<ulong>(l_356_));
                        ulong _e847 = l_mut_315_;
                        ulong l_358_ = _e847 & l_357_;
                        ulong _e849 = l_mut_317_;
                        l_mut_317_ = _e849 | l_358_;
                        ulong _e851 = l_mut_315_;
                        l_mut_315_ = _e851 | l_357_;
                        uint _e853 = l_mut_322_;
                        uint l_359_ = naga_mod(_e853, 40u);
                        uint _e856 = l_mut_322_;
                        l_mut_322_ = naga_div(_e856, 40u);
                        ulong l_360_ = static_cast<ulong>(l_359_);
                        ulong l_361_ = 1uL << static_cast<uint>(as_type<ulong>(l_360_));
                        ulong _e864 = l_mut_315_;
                        ulong l_362_ = _e864 & l_361_;
                        ulong _e866 = l_mut_317_;
                        l_mut_317_ = _e866 | l_362_;
                        ulong _e868 = l_mut_315_;
                        l_mut_315_ = _e868 | l_361_;
                        uint _e870 = l_mut_322_;
                        uint l_363_ = naga_mod(_e870, 40u);
                        uint _e873 = l_mut_322_;
                        l_mut_322_ = naga_div(_e873, 40u);
                        ulong l_364_ = static_cast<ulong>(l_363_);
                        ulong l_365_ = 1uL << static_cast<uint>(as_type<ulong>(l_364_));
                        ulong _e881 = l_mut_315_;
                        ulong l_366_ = _e881 & l_365_;
                        ulong _e883 = l_mut_317_;
                        l_mut_317_ = _e883 | l_366_;
                        ulong _e885 = l_mut_315_;
                        l_mut_315_ = _e885 | l_365_;
                        uint _e887 = l_mut_138_;
                        l_mut_138_ = _e887 + 1u;
                    }
                    ulong _e890 = l_mut_317_;
                    bool l_367_ = _e890 != 0uL;
                    if (l_367_) {
                        l_mut_119_ = false;
                    }
                }
                l_mut_317_ = 0uL;
                l_mut_316_ = 0uL;
                bool _e896 = l_mut_119_;
                if (_e896) {
                    local_2 = true;
                } else {
                    local_2 = false;
                }
                bool l_368_ = local_2;
                if (l_368_) {
                    ulong l_370_ = l_112_ >> static_cast<uint>(as_type<ulong>(0uL));
                    uint l_371_ = static_cast<uint>(as_type<ulong>(l_370_));
                    a_369_.inner[0] = l_371_;
                    ulong l_372_ = l_112_ >> static_cast<uint>(as_type<ulong>(32uL));
                    uint l_373_ = static_cast<uint>(as_type<ulong>(l_372_));
                    a_369_.inner[1] = l_373_;
                    a_374_.inner[0] = 0u;
                    a_374_.inner[1] = 0u;
                    a_374_.inner[2] = 0u;
                    a_374_.inner[3] = 0u;
                    l_mut_315_ = 0uL;
                    uint l_375_ = a_369_.inner[0];
                    ulong l_376_ = static_cast<ulong>(l_375_);
                    uint l_377_ = a_369_.inner[0];
                    ulong l_378_ = static_cast<ulong>(l_377_);
                    ulong l_379_ = l_376_ * l_378_;
                    uint l_380_ = a_374_.inner[0];
                    ulong l_381_ = static_cast<ulong>(l_380_);
                    ulong l_382_ = l_379_ + l_381_;
                    ulong _e936 = l_mut_315_;
                    ulong l_383_ = l_382_ + _e936;
                    uint l_384_ = static_cast<uint>(as_type<ulong>(l_383_));
                    a_374_.inner[0] = l_384_;
                    ulong l_385_ = l_383_ >> static_cast<uint>(as_type<ulong>(32uL));
                    l_mut_315_ = l_385_;
                    uint l_386_ = a_369_.inner[0];
                    ulong l_387_ = static_cast<ulong>(l_386_);
                    uint l_388_ = a_369_.inner[1];
                    ulong l_389_ = static_cast<ulong>(l_388_);
                    ulong l_390_ = l_387_ * l_389_;
                    uint l_391_ = a_374_.inner[1];
                    ulong l_392_ = static_cast<ulong>(l_391_);
                    ulong l_393_ = l_390_ + l_392_;
                    ulong _e956 = l_mut_315_;
                    ulong l_394_ = l_393_ + _e956;
                    uint l_395_ = static_cast<uint>(as_type<ulong>(l_394_));
                    a_374_.inner[1] = l_395_;
                    ulong l_396_ = l_394_ >> static_cast<uint>(as_type<ulong>(32uL));
                    l_mut_315_ = l_396_;
                    ulong _e965 = l_mut_315_;
                    uint l_397_ = static_cast<uint>(as_type<ulong>(_e965));
                    a_374_.inner[2] = l_397_;
                    l_mut_315_ = 0uL;
                    uint l_398_ = a_369_.inner[1];
                    ulong l_399_ = static_cast<ulong>(l_398_);
                    uint l_400_ = a_369_.inner[0];
                    ulong l_401_ = static_cast<ulong>(l_400_);
                    ulong l_402_ = l_399_ * l_401_;
                    uint l_403_ = a_374_.inner[1];
                    ulong l_404_ = static_cast<ulong>(l_403_);
                    ulong l_405_ = l_402_ + l_404_;
                    ulong _e981 = l_mut_315_;
                    ulong l_406_ = l_405_ + _e981;
                    uint l_407_ = static_cast<uint>(as_type<ulong>(l_406_));
                    a_374_.inner[1] = l_407_;
                    ulong l_408_ = l_406_ >> static_cast<uint>(as_type<ulong>(32uL));
                    l_mut_315_ = l_408_;
                    uint l_409_ = a_369_.inner[1];
                    ulong l_410_ = static_cast<ulong>(l_409_);
                    uint l_411_ = a_369_.inner[1];
                    ulong l_412_ = static_cast<ulong>(l_411_);
                    ulong l_413_ = l_410_ * l_412_;
                    uint l_414_ = a_374_.inner[2];
                    ulong l_415_ = static_cast<ulong>(l_414_);
                    ulong l_416_ = l_413_ + l_415_;
                    ulong _e1001 = l_mut_315_;
                    ulong l_417_ = l_416_ + _e1001;
                    uint l_418_ = static_cast<uint>(as_type<ulong>(l_417_));
                    a_374_.inner[2] = l_418_;
                    ulong l_419_ = l_417_ >> static_cast<uint>(as_type<ulong>(32uL));
                    l_mut_315_ = l_419_;
                    ulong _e1010 = l_mut_315_;
                    uint l_420_ = static_cast<uint>(as_type<ulong>(_e1010));
                    a_374_.inner[3] = l_420_;
                    uint l_421_ = l_14_ + 0u;
                    uint l_422_ = a_374_.inner[0];
                    shared_memory_13_.inner[l_421_] = l_422_;
                    uint l_423_ = l_14_ + 1u;
                    uint l_424_ = a_374_.inner[1];
                    shared_memory_13_.inner[l_423_] = l_424_;
                    uint l_425_ = l_14_ + 2u;
                    uint l_426_ = a_374_.inner[2];
                    shared_memory_13_.inner[l_425_] = l_426_;
                    uint l_427_ = l_14_ + 3u;
                    uint l_428_ = a_374_.inner[3];
                    shared_memory_13_.inner[l_427_] = l_428_;
                    l_mut_429_ = 3;
                    uint2 loop_bound_4 = uint2(4294967295u);
                    while(true) {
                        if (metal::all(loop_bound_4 == uint2(0u))) { break; }
                        loop_bound_4 -= uint2(loop_bound_4.y == 0u, 1u);
                        int _e1039 = l_mut_429_;
                        bool l_430_ = _e1039 >= 0;
                        bool l_431_ = !(l_430_);
                        if (l_431_) {
                            break;
                        }
                        int _e1043 = l_mut_429_;
                        uint l_432_ = static_cast<uint>(_e1043);
                        uint l_433_ = l_14_ + l_432_;
                        uint l_434_ = shared_memory_13_.inner[l_433_];
                        bool l_435_ = l_434_ != 0u;
                        if (l_435_) {
                            break;
                        }
                        int _e1051 = l_mut_429_;
                        l_mut_429_ = as_type<int>(as_type<uint>(_e1051) - as_type<uint>(1));
                    }
                    uint2 loop_bound_5 = uint2(4294967295u);
                    while(true) {
                        if (metal::all(loop_bound_5 == uint2(0u))) { break; }
                        loop_bound_5 -= uint2(loop_bound_5.y == 0u, 1u);
                        int _e1054 = l_mut_429_;
                        bool l_436_ = _e1054 >= 0;
                        if (l_436_) {
                            bool _e1059 = l_mut_119_;
                            local_3 = _e1059;
                        } else {
                            local_3 = false;
                        }
                        bool l_437_ = local_3;
                        bool l_438_ = !(l_437_);
                        if (l_438_) {
                            break;
                        }
                        l_mut_324_ = 0u;
                        int _e1064 = l_mut_429_;
                        l_mut_439_ = _e1064;
                        uint2 loop_bound_6 = uint2(4294967295u);
                        while(true) {
                            if (metal::all(loop_bound_6 == uint2(0u))) { break; }
                            loop_bound_6 -= uint2(loop_bound_6.y == 0u, 1u);
                            int _e1065 = l_mut_439_;
                            bool l_440_ = _e1065 >= 0;
                            bool l_441_ = !(l_440_);
                            if (l_441_) {
                                break;
                            }
                            int _e1069 = l_mut_439_;
                            uint l_442_ = static_cast<uint>(_e1069);
                            uint l_443_ = l_14_ + l_442_;
                            uint l_444_ = shared_memory_13_.inner[l_443_];
                            uint _e1075 = l_mut_324_;
                            uint l_445_ = _e1075 << 16u;
                            uint l_446_ = l_444_ >> 16u;
                            uint l_447_ = l_445_ | l_446_;
                            uint l_448_ = naga_div(l_447_, 64000u);
                            uint l_449_ = l_448_ * 64000u;
                            uint l_450_ = l_447_ - l_449_;
                            uint l_451_ = l_450_ << 16u;
                            uint l_452_ = l_444_ & 65535u;
                            uint l_453_ = l_451_ | l_452_;
                            uint l_454_ = naga_div(l_453_, 64000u);
                            uint l_455_ = l_454_ * 64000u;
                            uint l_456_ = l_453_ - l_455_;
                            l_mut_324_ = l_456_;
                            int _e1096 = l_mut_439_;
                            uint l_457_ = static_cast<uint>(_e1096);
                            uint l_458_ = l_14_ + l_457_;
                            uint l_459_ = l_448_ << 16u;
                            uint l_460_ = l_459_ | l_454_;
                            shared_memory_13_.inner[l_458_] = l_460_;
                            int _e1104 = l_mut_439_;
                            l_mut_439_ = as_type<int>(as_type<uint>(_e1104) - as_type<uint>(1));
                        }
                        uint2 loop_bound_7 = uint2(4294967295u);
                        while(true) {
                            if (metal::all(loop_bound_7 == uint2(0u))) { break; }
                            loop_bound_7 -= uint2(loop_bound_7.y == 0u, 1u);
                            int _e1107 = l_mut_429_;
                            bool l_461_ = _e1107 >= 0;
                            bool l_462_ = !(l_461_);
                            if (l_462_) {
                                break;
                            }
                            int _e1111 = l_mut_429_;
                            uint l_463_ = static_cast<uint>(_e1111);
                            uint l_464_ = l_14_ + l_463_;
                            uint l_465_ = shared_memory_13_.inner[l_464_];
                            bool l_466_ = l_465_ != 0u;
                            if (l_466_) {
                                break;
                            }
                            int _e1119 = l_mut_429_;
                            l_mut_429_ = as_type<int>(as_type<uint>(_e1119) - as_type<uint>(1));
                        }
                        uint _e1122 = l_mut_324_;
                        l_mut_322_ = _e1122;
                        l_mut_315_ = 0uL;
                        int _e1124 = l_mut_429_;
                        bool l_467_ = _e1124 >= 0;
                        if (l_467_) {
                            uint _e1127 = l_mut_322_;
                            uint l_468_ = naga_div(_e1127, 40u);
                            uint l_469_ = l_468_ * 40u;
                            uint _e1132 = l_mut_322_;
                            uint l_470_ = _e1132 - l_469_;
                            l_mut_322_ = l_468_;
                            ulong l_471_ = static_cast<ulong>(l_470_);
                            ulong l_472_ = 1uL << static_cast<uint>(as_type<ulong>(l_471_));
                            ulong _e1139 = l_mut_317_;
                            ulong l_473_ = _e1139 & l_472_;
                            ulong _e1141 = l_mut_315_;
                            l_mut_315_ = _e1141 | l_473_;
                            ulong _e1143 = l_mut_317_;
                            l_mut_317_ = _e1143 | l_472_;
                            uint _e1145 = l_mut_322_;
                            uint l_474_ = naga_div(_e1145, 40u);
                            uint l_475_ = l_474_ * 40u;
                            uint _e1150 = l_mut_322_;
                            uint l_476_ = _e1150 - l_475_;
                            l_mut_322_ = l_474_;
                            ulong l_477_ = static_cast<ulong>(l_476_);
                            ulong l_478_ = 1uL << static_cast<uint>(as_type<ulong>(l_477_));
                            ulong _e1157 = l_mut_317_;
                            ulong l_479_ = _e1157 & l_478_;
                            ulong _e1159 = l_mut_315_;
                            l_mut_315_ = _e1159 | l_479_;
                            ulong _e1161 = l_mut_317_;
                            l_mut_317_ = _e1161 | l_478_;
                            uint _e1163 = l_mut_322_;
                            uint l_480_ = naga_div(_e1163, 40u);
                            uint l_481_ = l_480_ * 40u;
                            uint _e1168 = l_mut_322_;
                            uint l_482_ = _e1168 - l_481_;
                            l_mut_322_ = l_480_;
                            ulong l_483_ = static_cast<ulong>(l_482_);
                            ulong l_484_ = 1uL << static_cast<uint>(as_type<ulong>(l_483_));
                            ulong _e1175 = l_mut_317_;
                            ulong l_485_ = _e1175 & l_484_;
                            ulong _e1177 = l_mut_315_;
                            l_mut_315_ = _e1177 | l_485_;
                            ulong _e1179 = l_mut_317_;
                            l_mut_317_ = _e1179 | l_484_;
                        } else {
                            uint2 loop_bound_8 = uint2(4294967295u);
                            while(true) {
                                if (metal::all(loop_bound_8 == uint2(0u))) { break; }
                                loop_bound_8 -= uint2(loop_bound_8.y == 0u, 1u);
                                uint _e1181 = l_mut_322_;
                                bool l_486_ = _e1181 != 0u;
                                bool l_487_ = !(l_486_);
                                if (l_487_) {
                                    break;
                                }
                                uint _e1185 = l_mut_322_;
                                uint l_488_ = naga_div(_e1185, 40u);
                                uint l_489_ = l_488_ * 40u;
                                uint _e1190 = l_mut_322_;
                                uint l_490_ = _e1190 - l_489_;
                                l_mut_322_ = l_488_;
                                ulong l_491_ = static_cast<ulong>(l_490_);
                                ulong l_492_ = 1uL << static_cast<uint>(as_type<ulong>(l_491_));
                                ulong _e1197 = l_mut_317_;
                                ulong l_493_ = _e1197 & l_492_;
                                ulong _e1199 = l_mut_315_;
                                l_mut_315_ = _e1199 | l_493_;
                                ulong _e1201 = l_mut_317_;
                                l_mut_317_ = _e1201 | l_492_;
                            }
                        }
                        ulong _e1203 = l_mut_315_;
                        bool l_494_ = _e1203 != 0uL;
                        if (l_494_) {
                            l_mut_119_ = false;
                        }
                    }
                    bool _e1207 = l_mut_119_;
                    if (_e1207) {
                        uint l_495_ = l_14_ + 0u;
                        shared_memory_13_.inner[l_495_] = 0u;
                        uint l_496_ = l_14_ + 1u;
                        shared_memory_13_.inner[l_496_] = 0u;
                        uint l_497_ = l_14_ + 2u;
                        shared_memory_13_.inner[l_497_] = 0u;
                        uint l_498_ = l_14_ + 3u;
                        shared_memory_13_.inner[l_498_] = 0u;
                        uint l_499_ = l_14_ + 4u;
                        shared_memory_13_.inner[l_499_] = 0u;
                        uint l_500_ = l_14_ + 5u;
                        shared_memory_13_.inner[l_500_] = 0u;
                        l_mut_315_ = 0uL;
                        uint l_501_ = a_374_.inner[0];
                        ulong l_502_ = static_cast<ulong>(l_501_);
                        uint l_503_ = a_369_.inner[0];
                        ulong l_504_ = static_cast<ulong>(l_503_);
                        ulong l_505_ = l_502_ * l_504_;
                        uint l_506_ = l_14_ + 0u;
                        uint l_507_ = shared_memory_13_.inner[l_506_];
                        ulong l_508_ = static_cast<ulong>(l_507_);
                        ulong l_509_ = l_505_ + l_508_;
                        ulong _e1253 = l_mut_315_;
                        ulong l_510_ = l_509_ + _e1253;
                        uint l_511_ = l_14_ + 0u;
                        uint l_512_ = static_cast<uint>(as_type<ulong>(l_510_));
                        shared_memory_13_.inner[l_511_] = l_512_;
                        ulong l_513_ = l_510_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_315_ = l_513_;
                        uint l_514_ = a_374_.inner[0];
                        ulong l_515_ = static_cast<ulong>(l_514_);
                        uint l_516_ = a_369_.inner[1];
                        ulong l_517_ = static_cast<ulong>(l_516_);
                        ulong l_518_ = l_515_ * l_517_;
                        uint l_519_ = l_14_ + 1u;
                        uint l_520_ = shared_memory_13_.inner[l_519_];
                        ulong l_521_ = static_cast<ulong>(l_520_);
                        ulong l_522_ = l_518_ + l_521_;
                        ulong _e1279 = l_mut_315_;
                        ulong l_523_ = l_522_ + _e1279;
                        uint l_524_ = l_14_ + 1u;
                        uint l_525_ = static_cast<uint>(as_type<ulong>(l_523_));
                        shared_memory_13_.inner[l_524_] = l_525_;
                        ulong l_526_ = l_523_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_315_ = l_526_;
                        uint l_527_ = l_14_ + 2u;
                        ulong _e1293 = l_mut_315_;
                        uint l_528_ = static_cast<uint>(as_type<ulong>(_e1293));
                        shared_memory_13_.inner[l_527_] = l_528_;
                        l_mut_315_ = 0uL;
                        uint l_529_ = a_374_.inner[1];
                        ulong l_530_ = static_cast<ulong>(l_529_);
                        uint l_531_ = a_369_.inner[0];
                        ulong l_532_ = static_cast<ulong>(l_531_);
                        ulong l_533_ = l_530_ * l_532_;
                        uint l_534_ = l_14_ + 1u;
                        uint l_535_ = shared_memory_13_.inner[l_534_];
                        ulong l_536_ = static_cast<ulong>(l_535_);
                        ulong l_537_ = l_533_ + l_536_;
                        ulong _e1313 = l_mut_315_;
                        ulong l_538_ = l_537_ + _e1313;
                        uint l_539_ = l_14_ + 1u;
                        uint l_540_ = static_cast<uint>(as_type<ulong>(l_538_));
                        shared_memory_13_.inner[l_539_] = l_540_;
                        ulong l_541_ = l_538_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_315_ = l_541_;
                        uint l_542_ = a_374_.inner[1];
                        ulong l_543_ = static_cast<ulong>(l_542_);
                        uint l_544_ = a_369_.inner[1];
                        ulong l_545_ = static_cast<ulong>(l_544_);
                        ulong l_546_ = l_543_ * l_545_;
                        uint l_547_ = l_14_ + 2u;
                        uint l_548_ = shared_memory_13_.inner[l_547_];
                        ulong l_549_ = static_cast<ulong>(l_548_);
                        ulong l_550_ = l_546_ + l_549_;
                        ulong _e1339 = l_mut_315_;
                        ulong l_551_ = l_550_ + _e1339;
                        uint l_552_ = l_14_ + 2u;
                        uint l_553_ = static_cast<uint>(as_type<ulong>(l_551_));
                        shared_memory_13_.inner[l_552_] = l_553_;
                        ulong l_554_ = l_551_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_315_ = l_554_;
                        uint l_555_ = l_14_ + 3u;
                        ulong _e1353 = l_mut_315_;
                        uint l_556_ = static_cast<uint>(as_type<ulong>(_e1353));
                        shared_memory_13_.inner[l_555_] = l_556_;
                        l_mut_315_ = 0uL;
                        uint l_557_ = a_374_.inner[2];
                        ulong l_558_ = static_cast<ulong>(l_557_);
                        uint l_559_ = a_369_.inner[0];
                        ulong l_560_ = static_cast<ulong>(l_559_);
                        ulong l_561_ = l_558_ * l_560_;
                        uint l_562_ = l_14_ + 2u;
                        uint l_563_ = shared_memory_13_.inner[l_562_];
                        ulong l_564_ = static_cast<ulong>(l_563_);
                        ulong l_565_ = l_561_ + l_564_;
                        ulong _e1373 = l_mut_315_;
                        ulong l_566_ = l_565_ + _e1373;
                        uint l_567_ = l_14_ + 2u;
                        uint l_568_ = static_cast<uint>(as_type<ulong>(l_566_));
                        shared_memory_13_.inner[l_567_] = l_568_;
                        ulong l_569_ = l_566_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_315_ = l_569_;
                        uint l_570_ = a_374_.inner[2];
                        ulong l_571_ = static_cast<ulong>(l_570_);
                        uint l_572_ = a_369_.inner[1];
                        ulong l_573_ = static_cast<ulong>(l_572_);
                        ulong l_574_ = l_571_ * l_573_;
                        uint l_575_ = l_14_ + 3u;
                        uint l_576_ = shared_memory_13_.inner[l_575_];
                        ulong l_577_ = static_cast<ulong>(l_576_);
                        ulong l_578_ = l_574_ + l_577_;
                        ulong _e1399 = l_mut_315_;
                        ulong l_579_ = l_578_ + _e1399;
                        uint l_580_ = l_14_ + 3u;
                        uint l_581_ = static_cast<uint>(as_type<ulong>(l_579_));
                        shared_memory_13_.inner[l_580_] = l_581_;
                        ulong l_582_ = l_579_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_315_ = l_582_;
                        uint l_583_ = l_14_ + 4u;
                        ulong _e1413 = l_mut_315_;
                        uint l_584_ = static_cast<uint>(as_type<ulong>(_e1413));
                        shared_memory_13_.inner[l_583_] = l_584_;
                        l_mut_315_ = 0uL;
                        uint l_585_ = a_374_.inner[3];
                        ulong l_586_ = static_cast<ulong>(l_585_);
                        uint l_587_ = a_369_.inner[0];
                        ulong l_588_ = static_cast<ulong>(l_587_);
                        ulong l_589_ = l_586_ * l_588_;
                        uint l_590_ = l_14_ + 3u;
                        uint l_591_ = shared_memory_13_.inner[l_590_];
                        ulong l_592_ = static_cast<ulong>(l_591_);
                        ulong l_593_ = l_589_ + l_592_;
                        ulong _e1433 = l_mut_315_;
                        ulong l_594_ = l_593_ + _e1433;
                        uint l_595_ = l_14_ + 3u;
                        uint l_596_ = static_cast<uint>(as_type<ulong>(l_594_));
                        shared_memory_13_.inner[l_595_] = l_596_;
                        ulong l_597_ = l_594_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_315_ = l_597_;
                        uint l_598_ = a_374_.inner[3];
                        ulong l_599_ = static_cast<ulong>(l_598_);
                        uint l_600_ = a_369_.inner[1];
                        ulong l_601_ = static_cast<ulong>(l_600_);
                        ulong l_602_ = l_599_ * l_601_;
                        uint l_603_ = l_14_ + 4u;
                        uint l_604_ = shared_memory_13_.inner[l_603_];
                        ulong l_605_ = static_cast<ulong>(l_604_);
                        ulong l_606_ = l_602_ + l_605_;
                        ulong _e1459 = l_mut_315_;
                        ulong l_607_ = l_606_ + _e1459;
                        uint l_608_ = l_14_ + 4u;
                        uint l_609_ = static_cast<uint>(as_type<ulong>(l_607_));
                        shared_memory_13_.inner[l_608_] = l_609_;
                        ulong l_610_ = l_607_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_315_ = l_610_;
                        uint l_611_ = l_14_ + 5u;
                        ulong _e1473 = l_mut_315_;
                        uint l_612_ = static_cast<uint>(as_type<ulong>(_e1473));
                        shared_memory_13_.inner[l_611_] = l_612_;
                        l_mut_439_ = 5;
                        uint2 loop_bound_9 = uint2(4294967295u);
                        while(true) {
                            if (metal::all(loop_bound_9 == uint2(0u))) { break; }
                            loop_bound_9 -= uint2(loop_bound_9.y == 0u, 1u);
                            int _e1479 = l_mut_439_;
                            bool l_613_ = _e1479 >= 0;
                            bool l_614_ = !(l_613_);
                            if (l_614_) {
                                break;
                            }
                            int _e1483 = l_mut_439_;
                            uint l_615_ = static_cast<uint>(_e1483);
                            uint l_616_ = l_14_ + l_615_;
                            uint l_617_ = shared_memory_13_.inner[l_616_];
                            bool l_618_ = l_617_ != 0u;
                            if (l_618_) {
                                break;
                            }
                            int _e1491 = l_mut_439_;
                            l_mut_439_ = as_type<int>(as_type<uint>(_e1491) - as_type<uint>(1));
                        }
                        uint2 loop_bound_10 = uint2(4294967295u);
                        while(true) {
                            if (metal::all(loop_bound_10 == uint2(0u))) { break; }
                            loop_bound_10 -= uint2(loop_bound_10.y == 0u, 1u);
                            int _e1494 = l_mut_439_;
                            bool l_619_ = _e1494 >= 0;
                            if (l_619_) {
                                bool _e1499 = l_mut_119_;
                                local_4 = _e1499;
                            } else {
                                local_4 = false;
                            }
                            bool l_620_ = local_4;
                            bool l_621_ = !(l_620_);
                            if (l_621_) {
                                break;
                            }
                            l_mut_324_ = 0u;
                            int _e1504 = l_mut_439_;
                            l_mut_622_ = _e1504;
                            uint2 loop_bound_11 = uint2(4294967295u);
                            while(true) {
                                if (metal::all(loop_bound_11 == uint2(0u))) { break; }
                                loop_bound_11 -= uint2(loop_bound_11.y == 0u, 1u);
                                int _e1505 = l_mut_622_;
                                bool l_623_ = _e1505 >= 0;
                                bool l_624_ = !(l_623_);
                                if (l_624_) {
                                    break;
                                }
                                int _e1509 = l_mut_622_;
                                uint l_625_ = static_cast<uint>(_e1509);
                                uint l_626_ = l_14_ + l_625_;
                                uint l_627_ = shared_memory_13_.inner[l_626_];
                                uint _e1515 = l_mut_324_;
                                uint l_628_ = _e1515 << 16u;
                                uint l_629_ = l_627_ >> 16u;
                                uint l_630_ = l_628_ | l_629_;
                                uint l_631_ = naga_div(l_630_, 64000u);
                                uint l_632_ = l_631_ * 64000u;
                                uint l_633_ = l_630_ - l_632_;
                                uint l_634_ = l_633_ << 16u;
                                uint l_635_ = l_627_ & 65535u;
                                uint l_636_ = l_634_ | l_635_;
                                uint l_637_ = naga_div(l_636_, 64000u);
                                uint l_638_ = l_637_ * 64000u;
                                uint l_639_ = l_636_ - l_638_;
                                l_mut_324_ = l_639_;
                                int _e1536 = l_mut_622_;
                                uint l_640_ = static_cast<uint>(_e1536);
                                uint l_641_ = l_14_ + l_640_;
                                uint l_642_ = l_631_ << 16u;
                                uint l_643_ = l_642_ | l_637_;
                                shared_memory_13_.inner[l_641_] = l_643_;
                                int _e1544 = l_mut_622_;
                                l_mut_622_ = as_type<int>(as_type<uint>(_e1544) - as_type<uint>(1));
                            }
                            uint2 loop_bound_12 = uint2(4294967295u);
                            while(true) {
                                if (metal::all(loop_bound_12 == uint2(0u))) { break; }
                                loop_bound_12 -= uint2(loop_bound_12.y == 0u, 1u);
                                int _e1547 = l_mut_439_;
                                bool l_644_ = _e1547 >= 0;
                                bool l_645_ = !(l_644_);
                                if (l_645_) {
                                    break;
                                }
                                int _e1551 = l_mut_439_;
                                uint l_646_ = static_cast<uint>(_e1551);
                                uint l_647_ = l_14_ + l_646_;
                                uint l_648_ = shared_memory_13_.inner[l_647_];
                                bool l_649_ = l_648_ != 0u;
                                if (l_649_) {
                                    break;
                                }
                                int _e1559 = l_mut_439_;
                                l_mut_439_ = as_type<int>(as_type<uint>(_e1559) - as_type<uint>(1));
                            }
                            uint _e1562 = l_mut_324_;
                            l_mut_322_ = _e1562;
                            l_mut_315_ = 0uL;
                            int _e1564 = l_mut_439_;
                            bool l_650_ = _e1564 >= 0;
                            if (l_650_) {
                                uint _e1567 = l_mut_322_;
                                uint l_651_ = naga_div(_e1567, 40u);
                                uint l_652_ = l_651_ * 40u;
                                uint _e1572 = l_mut_322_;
                                uint l_653_ = _e1572 - l_652_;
                                l_mut_322_ = l_651_;
                                ulong l_654_ = static_cast<ulong>(l_653_);
                                ulong l_655_ = 1uL << static_cast<uint>(as_type<ulong>(l_654_));
                                ulong _e1579 = l_mut_317_;
                                ulong l_656_ = _e1579 & l_655_;
                                ulong _e1581 = l_mut_315_;
                                l_mut_315_ = _e1581 | l_656_;
                                ulong _e1583 = l_mut_317_;
                                l_mut_317_ = _e1583 | l_655_;
                                uint _e1585 = l_mut_322_;
                                uint l_657_ = naga_div(_e1585, 40u);
                                uint l_658_ = l_657_ * 40u;
                                uint _e1590 = l_mut_322_;
                                uint l_659_ = _e1590 - l_658_;
                                l_mut_322_ = l_657_;
                                ulong l_660_ = static_cast<ulong>(l_659_);
                                ulong l_661_ = 1uL << static_cast<uint>(as_type<ulong>(l_660_));
                                ulong _e1597 = l_mut_317_;
                                ulong l_662_ = _e1597 & l_661_;
                                ulong _e1599 = l_mut_315_;
                                l_mut_315_ = _e1599 | l_662_;
                                ulong _e1601 = l_mut_317_;
                                l_mut_317_ = _e1601 | l_661_;
                                uint _e1603 = l_mut_322_;
                                uint l_663_ = naga_div(_e1603, 40u);
                                uint l_664_ = l_663_ * 40u;
                                uint _e1608 = l_mut_322_;
                                uint l_665_ = _e1608 - l_664_;
                                l_mut_322_ = l_663_;
                                ulong l_666_ = static_cast<ulong>(l_665_);
                                ulong l_667_ = 1uL << static_cast<uint>(as_type<ulong>(l_666_));
                                ulong _e1615 = l_mut_317_;
                                ulong l_668_ = _e1615 & l_667_;
                                ulong _e1617 = l_mut_315_;
                                l_mut_315_ = _e1617 | l_668_;
                                ulong _e1619 = l_mut_317_;
                                l_mut_317_ = _e1619 | l_667_;
                            } else {
                                uint2 loop_bound_13 = uint2(4294967295u);
                                while(true) {
                                    if (metal::all(loop_bound_13 == uint2(0u))) { break; }
                                    loop_bound_13 -= uint2(loop_bound_13.y == 0u, 1u);
                                    uint _e1621 = l_mut_322_;
                                    bool l_669_ = _e1621 != 0u;
                                    bool l_670_ = !(l_669_);
                                    if (l_670_) {
                                        break;
                                    }
                                    uint _e1625 = l_mut_322_;
                                    uint l_671_ = naga_div(_e1625, 40u);
                                    uint l_672_ = l_671_ * 40u;
                                    uint _e1630 = l_mut_322_;
                                    uint l_673_ = _e1630 - l_672_;
                                    l_mut_322_ = l_671_;
                                    ulong l_674_ = static_cast<ulong>(l_673_);
                                    ulong l_675_ = 1uL << static_cast<uint>(as_type<ulong>(l_674_));
                                    ulong _e1637 = l_mut_317_;
                                    ulong l_676_ = _e1637 & l_675_;
                                    ulong _e1639 = l_mut_315_;
                                    l_mut_315_ = _e1639 | l_676_;
                                    ulong _e1641 = l_mut_317_;
                                    l_mut_317_ = _e1641 | l_675_;
                                }
                            }
                            ulong _e1643 = l_mut_315_;
                            bool l_677_ = _e1643 != 0uL;
                            if (l_677_) {
                                l_mut_119_ = false;
                            }
                        }
                    }
                }
                bool _e1647 = l_mut_119_;
                if (_e1647) {
                    ulong _e1648 = l_mut_317_;
                    uint l_678_ = static_cast<uint>(as_type<ulong>(_e1648));
                    uint l_679_ = metal::popcount(l_678_);
                    ulong _e1652 = l_mut_317_;
                    ulong l_680_ = _e1652 >> static_cast<uint>(as_type<ulong>(32uL));
                    uint l_681_ = static_cast<uint>(as_type<ulong>(l_680_));
                    uint l_682_ = metal::popcount(l_681_);
                    uint l_683_ = l_679_ + l_682_;
                    l_mut_324_ = l_683_;
                    uint _e1661 = l_mut_324_;
                    bool l_684_ = _e1661 == 40u;
                    if (true) {
                        local_5 = l_684_;
                    } else {
                        local_5 = true;
                    }
                    bool l_685_ = local_5;
                    if (l_685_) {
                        uint _e1672 = metal::atomic_fetch_add_explicit(&buffer_4_global[0], 1u, metal::memory_order_relaxed);
                        uint _e1676 = info.scalars_u32_.inner[6];
                        bool l_688_ = _e1672 < _e1676;
                        if (l_688_) {
                            uint l_689_ = 4u * _e1672;
                            uint l_690_ = static_cast<uint>(as_type<ulong>(l_112_));
                            buffer_3_global[l_689_] = l_690_;
                            uint l_691_ = l_689_ + 1u;
                            ulong l_692_ = l_112_ >> static_cast<uint>(as_type<ulong>(32uL));
                            uint l_693_ = static_cast<uint>(as_type<ulong>(l_692_));
                            buffer_3_global[l_691_] = l_693_;
                            uint l_694_ = l_689_ + 2u;
                            ulong _e1696 = l_mut_39_;
                            uint l_695_ = static_cast<uint>(as_type<ulong>(_e1696));
                            buffer_3_global[l_694_] = l_695_;
                            uint l_696_ = l_689_ + 3u;
                            ulong _e1703 = l_mut_39_;
                            ulong l_697_ = _e1703 >> static_cast<uint>(as_type<ulong>(32uL));
                            uint l_698_ = static_cast<uint>(as_type<ulong>(l_697_));
                            buffer_3_global[l_696_] = l_698_;
                        }
                    }
                }
            }
            uint _e1712 = l_mut_46_;
            l_mut_46_ = _e1712 + l_0_;
        }
        uint _e1714 = l_mut_16_;
        l_mut_16_ = _e1714 + l_4_;
    }
    return;
}
