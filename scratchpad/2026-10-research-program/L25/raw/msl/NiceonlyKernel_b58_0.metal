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
    type_8 a_135_ = {};
    type_9 a_142_ = {};
    bool l_mut_119_ = {};
    ulong l_mut_28_ = {};
    ulong l_mut_39_ = {};
    ulong l_mut_44_ = {};
    ulong l_mut_91_ = {};
    ulong l_mut_132_ = {};
    ulong l_mut_133_ = {};
    ulong l_mut_143_ = {};
    uint l_mut_16_ = {};
    uint l_mut_46_ = {};
    uint l_mut_94_ = {};
    uint l_mut_268_ = {};
    uint l_mut_297_ = {};
    int l_mut_258_ = {};
    int l_mut_269_ = {};
    int l_mut_584_ = {};
    bool local = {};
    bool local_1 = {};
    bool local_2 = {};
    bool local_3 = {};
    bool local_4 = {};
    bool local_5 = {};
    uint _e25 = info.scalars_u32_.inner[7];
    uint l_0_ = 1u << _e25;
    uint l_1_ = l_0_ - 1u;
    uint l_2_ = global_id.x & l_1_;
    uint l_3_ = num_workgroups.x * WORKGROUP_SIZE_X;
    uint _e37 = info.scalars_u32_.inner[7];
    uint l_4_ = l_3_ >> _e37;
    uint _e42 = info.scalars_u32_.inner[1];
    ulong l_5_ = static_cast<ulong>(_e42);
    ulong l_6_ = l_5_ << static_cast<uint>(as_type<ulong>(32uL));
    uint _e51 = info.scalars_u32_.inner[0];
    ulong l_7_ = static_cast<ulong>(_e51);
    ulong l_8_ = l_6_ | l_7_;
    uint _e57 = info.scalars_u32_.inner[3];
    ulong l_9_ = static_cast<ulong>(_e57);
    ulong l_10_ = l_9_ << static_cast<uint>(as_type<ulong>(32uL));
    uint _e66 = info.scalars_u32_.inner[2];
    ulong l_11_ = static_cast<ulong>(_e66);
    ulong l_12_ = l_10_ | l_11_;
    uint l_14_ = local_invocation_id.x * 9u;
    uint _e76 = info.scalars_u32_.inner[7];
    uint l_15_ = global_id.x >> _e76;
    l_mut_16_ = l_15_;
    uint2 loop_bound = uint2(4294967295u);
    while(true) {
        if (metal::all(loop_bound == uint2(0u))) { break; }
        loop_bound -= uint2(loop_bound.y == 0u, 1u);
        uint _e78 = l_mut_16_;
        uint _e82 = info.scalars_u32_.inner[5];
        bool l_17_ = _e78 < _e82;
        bool l_18_ = !(l_17_);
        if (l_18_) {
            break;
        }
        uint _e86 = l_mut_16_;
        uint l_19_ = 2u * _e86;
        uint l_20_ = buffer_1_global[l_19_];
        uint _e92 = l_mut_16_;
        uint l_21_ = 2u * _e92;
        uint l_22_ = l_21_ + 1u;
        uint l_23_ = buffer_1_global[l_22_];
        ulong l_24_ = static_cast<ulong>(l_23_);
        ulong l_25_ = l_24_ << static_cast<uint>(as_type<ulong>(32uL));
        ulong l_26_ = static_cast<ulong>(l_20_);
        ulong l_27_ = l_25_ | l_26_;
        l_mut_28_ = 0uL;
        uint _e108 = l_mut_16_;
        uint l_29_ = 2u * _e108;
        uint l_30_ = l_29_ + 1u;
        uint l_31_ = buffer_6_global[l_30_];
        ulong l_32_ = static_cast<ulong>(l_31_);
        ulong l_33_ = l_32_ << static_cast<uint>(as_type<ulong>(32uL));
        uint _e121 = l_mut_16_;
        uint l_34_ = 2u * _e121;
        uint l_35_ = buffer_6_global[l_34_];
        ulong l_36_ = static_cast<ulong>(l_35_);
        ulong l_37_ = l_33_ | l_36_;
        l_mut_28_ = l_37_;
        ulong l_38_ = l_8_ + l_27_;
        l_mut_39_ = l_12_;
        bool l_40_ = l_38_ < l_8_;
        if (l_40_) {
            ulong _e130 = l_mut_39_;
            l_mut_39_ = _e130 + 1uL;
        }
        uint _e134 = l_mut_16_;
        uint l_41_ = buffer_2_global[_e134];
        ulong l_42_ = static_cast<ulong>(l_41_);
        ulong l_43_ = l_38_ + l_42_;
        ulong _e139 = l_mut_39_;
        l_mut_44_ = _e139;
        bool l_45_ = l_43_ < l_38_;
        if (l_45_) {
            ulong _e141 = l_mut_44_;
            l_mut_44_ = _e141 + 1uL;
        }
        l_mut_46_ = 0u;
        uint _e145 = l_mut_46_;
        uint l_47_ = _e145 << 8u;
        uint l_48_ = l_23_ >> 24u;
        uint l_49_ = l_48_ & 255u;
        uint l_50_ = l_47_ | l_49_;
        uint l_51_ = naga_mod(l_50_, 11121384u);
        l_mut_46_ = l_51_;
        uint _e155 = l_mut_46_;
        uint l_52_ = _e155 << 8u;
        uint l_53_ = l_23_ >> 16u;
        uint l_54_ = l_53_ & 255u;
        uint l_55_ = l_52_ | l_54_;
        uint l_56_ = naga_mod(l_55_, 11121384u);
        l_mut_46_ = l_56_;
        uint _e165 = l_mut_46_;
        uint l_57_ = _e165 << 8u;
        uint l_58_ = l_23_ >> 8u;
        uint l_59_ = l_58_ & 255u;
        uint l_60_ = l_57_ | l_59_;
        uint l_61_ = naga_mod(l_60_, 11121384u);
        l_mut_46_ = l_61_;
        uint _e175 = l_mut_46_;
        uint l_62_ = _e175 << 8u;
        uint l_63_ = l_23_ >> 0u;
        uint l_64_ = l_63_ & 255u;
        uint l_65_ = l_62_ | l_64_;
        uint l_66_ = naga_mod(l_65_, 11121384u);
        l_mut_46_ = l_66_;
        uint _e185 = l_mut_46_;
        uint l_67_ = _e185 << 8u;
        uint l_68_ = l_20_ >> 24u;
        uint l_69_ = l_68_ & 255u;
        uint l_70_ = l_67_ | l_69_;
        uint l_71_ = naga_mod(l_70_, 11121384u);
        l_mut_46_ = l_71_;
        uint _e195 = l_mut_46_;
        uint l_72_ = _e195 << 8u;
        uint l_73_ = l_20_ >> 16u;
        uint l_74_ = l_73_ & 255u;
        uint l_75_ = l_72_ | l_74_;
        uint l_76_ = naga_mod(l_75_, 11121384u);
        l_mut_46_ = l_76_;
        uint _e205 = l_mut_46_;
        uint l_77_ = _e205 << 8u;
        uint l_78_ = l_20_ >> 8u;
        uint l_79_ = l_78_ & 255u;
        uint l_80_ = l_77_ | l_79_;
        uint l_81_ = naga_mod(l_80_, 11121384u);
        l_mut_46_ = l_81_;
        uint _e215 = l_mut_46_;
        uint l_82_ = _e215 << 8u;
        uint l_83_ = l_20_ >> 0u;
        uint l_84_ = l_83_ & 255u;
        uint l_85_ = l_82_ | l_84_;
        uint l_86_ = naga_mod(l_85_, 11121384u);
        l_mut_46_ = l_86_;
        uint _e228 = info.scalars_u32_.inner[4];
        uint _e229 = l_mut_46_;
        uint l_87_ = _e228 + _e229;
        uint l_88_ = naga_mod(l_87_, 11121384u);
        ulong l_89_ = static_cast<ulong>(l_88_);
        ulong l_90_ = l_38_ - l_89_;
        ulong _e235 = l_mut_39_;
        l_mut_91_ = _e235;
        ulong l_92_ = static_cast<ulong>(l_88_);
        bool l_93_ = l_38_ < l_92_;
        if (l_93_) {
            ulong _e238 = l_mut_91_;
            l_mut_91_ = _e238 - 1uL;
        }
        l_mut_46_ = 0u;
        l_mut_94_ = 569040u;
        uint2 loop_bound_1 = uint2(4294967295u);
        while(true) {
            if (metal::all(loop_bound_1 == uint2(0u))) { break; }
            loop_bound_1 -= uint2(loop_bound_1.y == 0u, 1u);
            uint _e243 = l_mut_46_;
            uint _e244 = l_mut_94_;
            bool l_95_ = _e243 < _e244;
            bool l_96_ = !(l_95_);
            if (l_96_) {
                break;
            }
            uint _e247 = l_mut_46_;
            uint _e248 = l_mut_94_;
            uint l_97_ = _e247 + _e248;
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
        uint _e258 = l_mut_46_;
        uint l_102_ = _e258 + l_2_;
        l_mut_46_ = l_102_;
        uint2 loop_bound_2 = uint2(4294967295u);
        while(true) {
            if (metal::all(loop_bound_2 == uint2(0u))) { break; }
            loop_bound_2 -= uint2(loop_bound_2.y == 0u, 1u);
            uint _e260 = l_mut_46_;
            uint l_103_ = naga_div(_e260, 569040u);
            uint l_104_ = l_103_ * 569040u;
            uint _e265 = l_mut_46_;
            uint l_105_ = _e265 - l_104_;
            ulong l_106_ = static_cast<ulong>(l_103_);
            ulong l_108_ = l_106_ * 11121384uL;
            uint l_109_ = buffer_0_global[l_105_];
            ulong l_110_ = static_cast<ulong>(l_109_);
            ulong l_111_ = l_108_ + l_110_;
            ulong l_112_ = l_90_ + l_111_;
            ulong _e276 = l_mut_91_;
            l_mut_39_ = _e276;
            bool l_113_ = l_112_ < l_90_;
            if (l_113_) {
                ulong _e278 = l_mut_39_;
                l_mut_39_ = _e278 + 1uL;
            }
            ulong _e281 = l_mut_39_;
            ulong _e282 = l_mut_44_;
            bool l_114_ = _e281 > _e282;
            ulong _e284 = l_mut_39_;
            ulong _e285 = l_mut_44_;
            bool l_115_ = _e284 == _e285;
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
            ulong _e317 = l_mut_28_;
            ulong l_129_ = l_128_ & _e317;
            bool l_130_ = l_129_ != 0uL;
            if (l_130_) {
                l_mut_119_ = true;
            }
            bool _e322 = l_mut_119_;
            bool l_131_ = !(_e322);
            if (l_131_) {
                l_mut_119_ = true;
                l_mut_132_ = 0uL;
                l_mut_133_ = 0uL;
                bool _e327 = l_mut_119_;
                if (_e327) {
                    local_2 = true;
                } else {
                    local_2 = false;
                }
                bool l_134_ = local_2;
                if (l_134_) {
                    ulong l_136_ = l_112_ >> static_cast<uint>(as_type<ulong>(0uL));
                    uint l_137_ = static_cast<uint>(as_type<ulong>(l_136_));
                    a_135_.inner[0] = l_137_;
                    ulong l_138_ = l_112_ >> static_cast<uint>(as_type<ulong>(32uL));
                    uint l_139_ = static_cast<uint>(as_type<ulong>(l_138_));
                    a_135_.inner[1] = l_139_;
                    ulong _e347 = l_mut_39_;
                    ulong l_140_ = _e347 >> static_cast<uint>(as_type<ulong>(0uL));
                    uint l_141_ = static_cast<uint>(as_type<ulong>(l_140_));
                    a_135_.inner[2] = l_141_;
                    a_142_.inner[0] = 0u;
                    a_142_.inner[1] = 0u;
                    a_142_.inner[2] = 0u;
                    a_142_.inner[3] = 0u;
                    a_142_.inner[4] = 0u;
                    a_142_.inner[5] = 0u;
                    l_mut_143_ = 0uL;
                    uint l_144_ = a_135_.inner[0];
                    ulong l_145_ = static_cast<ulong>(l_144_);
                    uint l_146_ = a_135_.inner[0];
                    ulong l_147_ = static_cast<ulong>(l_146_);
                    ulong l_148_ = l_145_ * l_147_;
                    uint l_149_ = a_142_.inner[0];
                    ulong l_150_ = static_cast<ulong>(l_149_);
                    ulong l_151_ = l_148_ + l_150_;
                    ulong _e379 = l_mut_143_;
                    ulong l_152_ = l_151_ + _e379;
                    uint l_153_ = static_cast<uint>(as_type<ulong>(l_152_));
                    a_142_.inner[0] = l_153_;
                    ulong l_154_ = l_152_ >> static_cast<uint>(as_type<ulong>(32uL));
                    l_mut_143_ = l_154_;
                    uint l_155_ = a_135_.inner[0];
                    ulong l_156_ = static_cast<ulong>(l_155_);
                    uint l_157_ = a_135_.inner[1];
                    ulong l_158_ = static_cast<ulong>(l_157_);
                    ulong l_159_ = l_156_ * l_158_;
                    uint l_160_ = a_142_.inner[1];
                    ulong l_161_ = static_cast<ulong>(l_160_);
                    ulong l_162_ = l_159_ + l_161_;
                    ulong _e399 = l_mut_143_;
                    ulong l_163_ = l_162_ + _e399;
                    uint l_164_ = static_cast<uint>(as_type<ulong>(l_163_));
                    a_142_.inner[1] = l_164_;
                    ulong l_165_ = l_163_ >> static_cast<uint>(as_type<ulong>(32uL));
                    l_mut_143_ = l_165_;
                    uint l_166_ = a_135_.inner[0];
                    ulong l_167_ = static_cast<ulong>(l_166_);
                    uint l_168_ = a_135_.inner[2];
                    ulong l_169_ = static_cast<ulong>(l_168_);
                    ulong l_170_ = l_167_ * l_169_;
                    uint l_171_ = a_142_.inner[2];
                    ulong l_172_ = static_cast<ulong>(l_171_);
                    ulong l_173_ = l_170_ + l_172_;
                    ulong _e419 = l_mut_143_;
                    ulong l_174_ = l_173_ + _e419;
                    uint l_175_ = static_cast<uint>(as_type<ulong>(l_174_));
                    a_142_.inner[2] = l_175_;
                    ulong l_176_ = l_174_ >> static_cast<uint>(as_type<ulong>(32uL));
                    l_mut_143_ = l_176_;
                    ulong _e428 = l_mut_143_;
                    uint l_177_ = static_cast<uint>(as_type<ulong>(_e428));
                    a_142_.inner[3] = l_177_;
                    l_mut_143_ = 0uL;
                    uint l_178_ = a_135_.inner[1];
                    ulong l_179_ = static_cast<ulong>(l_178_);
                    uint l_180_ = a_135_.inner[0];
                    ulong l_181_ = static_cast<ulong>(l_180_);
                    ulong l_182_ = l_179_ * l_181_;
                    uint l_183_ = a_142_.inner[1];
                    ulong l_184_ = static_cast<ulong>(l_183_);
                    ulong l_185_ = l_182_ + l_184_;
                    ulong _e444 = l_mut_143_;
                    ulong l_186_ = l_185_ + _e444;
                    uint l_187_ = static_cast<uint>(as_type<ulong>(l_186_));
                    a_142_.inner[1] = l_187_;
                    ulong l_188_ = l_186_ >> static_cast<uint>(as_type<ulong>(32uL));
                    l_mut_143_ = l_188_;
                    uint l_189_ = a_135_.inner[1];
                    ulong l_190_ = static_cast<ulong>(l_189_);
                    uint l_191_ = a_135_.inner[1];
                    ulong l_192_ = static_cast<ulong>(l_191_);
                    ulong l_193_ = l_190_ * l_192_;
                    uint l_194_ = a_142_.inner[2];
                    ulong l_195_ = static_cast<ulong>(l_194_);
                    ulong l_196_ = l_193_ + l_195_;
                    ulong _e464 = l_mut_143_;
                    ulong l_197_ = l_196_ + _e464;
                    uint l_198_ = static_cast<uint>(as_type<ulong>(l_197_));
                    a_142_.inner[2] = l_198_;
                    ulong l_199_ = l_197_ >> static_cast<uint>(as_type<ulong>(32uL));
                    l_mut_143_ = l_199_;
                    uint l_200_ = a_135_.inner[1];
                    ulong l_201_ = static_cast<ulong>(l_200_);
                    uint l_202_ = a_135_.inner[2];
                    ulong l_203_ = static_cast<ulong>(l_202_);
                    ulong l_204_ = l_201_ * l_203_;
                    uint l_205_ = a_142_.inner[3];
                    ulong l_206_ = static_cast<ulong>(l_205_);
                    ulong l_207_ = l_204_ + l_206_;
                    ulong _e484 = l_mut_143_;
                    ulong l_208_ = l_207_ + _e484;
                    uint l_209_ = static_cast<uint>(as_type<ulong>(l_208_));
                    a_142_.inner[3] = l_209_;
                    ulong l_210_ = l_208_ >> static_cast<uint>(as_type<ulong>(32uL));
                    l_mut_143_ = l_210_;
                    ulong _e493 = l_mut_143_;
                    uint l_211_ = static_cast<uint>(as_type<ulong>(_e493));
                    a_142_.inner[4] = l_211_;
                    l_mut_143_ = 0uL;
                    uint l_212_ = a_135_.inner[2];
                    ulong l_213_ = static_cast<ulong>(l_212_);
                    uint l_214_ = a_135_.inner[0];
                    ulong l_215_ = static_cast<ulong>(l_214_);
                    ulong l_216_ = l_213_ * l_215_;
                    uint l_217_ = a_142_.inner[2];
                    ulong l_218_ = static_cast<ulong>(l_217_);
                    ulong l_219_ = l_216_ + l_218_;
                    ulong _e509 = l_mut_143_;
                    ulong l_220_ = l_219_ + _e509;
                    uint l_221_ = static_cast<uint>(as_type<ulong>(l_220_));
                    a_142_.inner[2] = l_221_;
                    ulong l_222_ = l_220_ >> static_cast<uint>(as_type<ulong>(32uL));
                    l_mut_143_ = l_222_;
                    uint l_223_ = a_135_.inner[2];
                    ulong l_224_ = static_cast<ulong>(l_223_);
                    uint l_225_ = a_135_.inner[1];
                    ulong l_226_ = static_cast<ulong>(l_225_);
                    ulong l_227_ = l_224_ * l_226_;
                    uint l_228_ = a_142_.inner[3];
                    ulong l_229_ = static_cast<ulong>(l_228_);
                    ulong l_230_ = l_227_ + l_229_;
                    ulong _e529 = l_mut_143_;
                    ulong l_231_ = l_230_ + _e529;
                    uint l_232_ = static_cast<uint>(as_type<ulong>(l_231_));
                    a_142_.inner[3] = l_232_;
                    ulong l_233_ = l_231_ >> static_cast<uint>(as_type<ulong>(32uL));
                    l_mut_143_ = l_233_;
                    uint l_234_ = a_135_.inner[2];
                    ulong l_235_ = static_cast<ulong>(l_234_);
                    uint l_236_ = a_135_.inner[2];
                    ulong l_237_ = static_cast<ulong>(l_236_);
                    ulong l_238_ = l_235_ * l_237_;
                    uint l_239_ = a_142_.inner[4];
                    ulong l_240_ = static_cast<ulong>(l_239_);
                    ulong l_241_ = l_238_ + l_240_;
                    ulong _e549 = l_mut_143_;
                    ulong l_242_ = l_241_ + _e549;
                    uint l_243_ = static_cast<uint>(as_type<ulong>(l_242_));
                    a_142_.inner[4] = l_243_;
                    ulong l_244_ = l_242_ >> static_cast<uint>(as_type<ulong>(32uL));
                    l_mut_143_ = l_244_;
                    ulong _e558 = l_mut_143_;
                    uint l_245_ = static_cast<uint>(as_type<ulong>(_e558));
                    a_142_.inner[5] = l_245_;
                    uint l_246_ = l_14_ + 0u;
                    uint l_247_ = a_142_.inner[0];
                    shared_memory_13_.inner[l_246_] = l_247_;
                    uint l_248_ = l_14_ + 1u;
                    uint l_249_ = a_142_.inner[1];
                    shared_memory_13_.inner[l_248_] = l_249_;
                    uint l_250_ = l_14_ + 2u;
                    uint l_251_ = a_142_.inner[2];
                    shared_memory_13_.inner[l_250_] = l_251_;
                    uint l_252_ = l_14_ + 3u;
                    uint l_253_ = a_142_.inner[3];
                    shared_memory_13_.inner[l_252_] = l_253_;
                    uint l_254_ = l_14_ + 4u;
                    uint l_255_ = a_142_.inner[4];
                    shared_memory_13_.inner[l_254_] = l_255_;
                    uint l_256_ = l_14_ + 5u;
                    uint l_257_ = a_142_.inner[5];
                    shared_memory_13_.inner[l_256_] = l_257_;
                    l_mut_258_ = 5;
                    uint2 loop_bound_3 = uint2(4294967295u);
                    while(true) {
                        if (metal::all(loop_bound_3 == uint2(0u))) { break; }
                        loop_bound_3 -= uint2(loop_bound_3.y == 0u, 1u);
                        int _e599 = l_mut_258_;
                        bool l_259_ = _e599 >= 0;
                        bool l_260_ = !(l_259_);
                        if (l_260_) {
                            break;
                        }
                        int _e603 = l_mut_258_;
                        uint l_261_ = static_cast<uint>(_e603);
                        uint l_262_ = l_14_ + l_261_;
                        uint l_263_ = shared_memory_13_.inner[l_262_];
                        bool l_264_ = l_263_ != 0u;
                        if (l_264_) {
                            break;
                        }
                        int _e611 = l_mut_258_;
                        l_mut_258_ = as_type<int>(as_type<uint>(_e611) - as_type<uint>(1));
                    }
                    uint2 loop_bound_4 = uint2(4294967295u);
                    while(true) {
                        if (metal::all(loop_bound_4 == uint2(0u))) { break; }
                        loop_bound_4 -= uint2(loop_bound_4.y == 0u, 1u);
                        int _e614 = l_mut_258_;
                        bool l_265_ = _e614 >= 0;
                        if (l_265_) {
                            bool _e619 = l_mut_119_;
                            local_3 = _e619;
                        } else {
                            local_3 = false;
                        }
                        bool l_266_ = local_3;
                        bool l_267_ = !(l_266_);
                        if (l_267_) {
                            break;
                        }
                        l_mut_268_ = 0u;
                        int _e624 = l_mut_258_;
                        l_mut_269_ = _e624;
                        uint2 loop_bound_5 = uint2(4294967295u);
                        while(true) {
                            if (metal::all(loop_bound_5 == uint2(0u))) { break; }
                            loop_bound_5 -= uint2(loop_bound_5.y == 0u, 1u);
                            int _e625 = l_mut_269_;
                            bool l_270_ = _e625 >= 0;
                            bool l_271_ = !(l_270_);
                            if (l_271_) {
                                break;
                            }
                            int _e629 = l_mut_269_;
                            uint l_272_ = static_cast<uint>(_e629);
                            uint l_273_ = l_14_ + l_272_;
                            uint l_274_ = shared_memory_13_.inner[l_273_];
                            uint _e635 = l_mut_268_;
                            uint l_275_ = _e635 << 16u;
                            uint l_276_ = l_274_ >> 16u;
                            uint l_277_ = l_275_ | l_276_;
                            uint l_278_ = naga_div(l_277_, 3364u);
                            uint l_279_ = l_278_ * 3364u;
                            uint l_280_ = l_277_ - l_279_;
                            uint l_281_ = l_280_ << 16u;
                            uint l_282_ = l_274_ & 65535u;
                            uint l_283_ = l_281_ | l_282_;
                            uint l_284_ = naga_div(l_283_, 3364u);
                            uint l_285_ = l_284_ * 3364u;
                            uint l_286_ = l_283_ - l_285_;
                            l_mut_268_ = l_286_;
                            int _e656 = l_mut_269_;
                            uint l_287_ = static_cast<uint>(_e656);
                            uint l_288_ = l_14_ + l_287_;
                            uint l_289_ = l_278_ << 16u;
                            uint l_290_ = l_289_ | l_284_;
                            shared_memory_13_.inner[l_288_] = l_290_;
                            int _e664 = l_mut_269_;
                            l_mut_269_ = as_type<int>(as_type<uint>(_e664) - as_type<uint>(1));
                        }
                        uint2 loop_bound_6 = uint2(4294967295u);
                        while(true) {
                            if (metal::all(loop_bound_6 == uint2(0u))) { break; }
                            loop_bound_6 -= uint2(loop_bound_6.y == 0u, 1u);
                            int _e667 = l_mut_258_;
                            bool l_291_ = _e667 >= 0;
                            bool l_292_ = !(l_291_);
                            if (l_292_) {
                                break;
                            }
                            int _e671 = l_mut_258_;
                            uint l_293_ = static_cast<uint>(_e671);
                            uint l_294_ = l_14_ + l_293_;
                            uint l_295_ = shared_memory_13_.inner[l_294_];
                            bool l_296_ = l_295_ != 0u;
                            if (l_296_) {
                                break;
                            }
                            int _e679 = l_mut_258_;
                            l_mut_258_ = as_type<int>(as_type<uint>(_e679) - as_type<uint>(1));
                        }
                        uint _e682 = l_mut_268_;
                        l_mut_297_ = _e682;
                        l_mut_143_ = 0uL;
                        int _e684 = l_mut_258_;
                        bool l_298_ = _e684 >= 0;
                        if (l_298_) {
                            uint _e687 = l_mut_297_;
                            uint l_299_ = naga_div(_e687, 58u);
                            uint l_300_ = l_299_ * 58u;
                            uint _e692 = l_mut_297_;
                            uint l_301_ = _e692 - l_300_;
                            l_mut_297_ = l_299_;
                            ulong l_302_ = static_cast<ulong>(l_301_);
                            ulong l_303_ = 1uL << static_cast<uint>(as_type<ulong>(l_302_));
                            ulong _e699 = l_mut_132_;
                            ulong l_304_ = _e699 & l_303_;
                            ulong _e701 = l_mut_143_;
                            l_mut_143_ = _e701 | l_304_;
                            ulong _e703 = l_mut_132_;
                            l_mut_132_ = _e703 | l_303_;
                            uint _e705 = l_mut_297_;
                            uint l_305_ = naga_div(_e705, 58u);
                            uint l_306_ = l_305_ * 58u;
                            uint _e710 = l_mut_297_;
                            uint l_307_ = _e710 - l_306_;
                            l_mut_297_ = l_305_;
                            ulong l_308_ = static_cast<ulong>(l_307_);
                            ulong l_309_ = 1uL << static_cast<uint>(as_type<ulong>(l_308_));
                            ulong _e717 = l_mut_132_;
                            ulong l_310_ = _e717 & l_309_;
                            ulong _e719 = l_mut_143_;
                            l_mut_143_ = _e719 | l_310_;
                            ulong _e721 = l_mut_132_;
                            l_mut_132_ = _e721 | l_309_;
                        } else {
                            uint2 loop_bound_7 = uint2(4294967295u);
                            while(true) {
                                if (metal::all(loop_bound_7 == uint2(0u))) { break; }
                                loop_bound_7 -= uint2(loop_bound_7.y == 0u, 1u);
                                uint _e723 = l_mut_297_;
                                bool l_311_ = _e723 != 0u;
                                bool l_312_ = !(l_311_);
                                if (l_312_) {
                                    break;
                                }
                                uint _e727 = l_mut_297_;
                                uint l_313_ = naga_div(_e727, 58u);
                                uint l_314_ = l_313_ * 58u;
                                uint _e732 = l_mut_297_;
                                uint l_315_ = _e732 - l_314_;
                                l_mut_297_ = l_313_;
                                ulong l_316_ = static_cast<ulong>(l_315_);
                                ulong l_317_ = 1uL << static_cast<uint>(as_type<ulong>(l_316_));
                                ulong _e739 = l_mut_132_;
                                ulong l_318_ = _e739 & l_317_;
                                ulong _e741 = l_mut_143_;
                                l_mut_143_ = _e741 | l_318_;
                                ulong _e743 = l_mut_132_;
                                l_mut_132_ = _e743 | l_317_;
                            }
                        }
                        ulong _e745 = l_mut_143_;
                        bool l_319_ = _e745 != 0uL;
                        if (l_319_) {
                            l_mut_119_ = false;
                        }
                    }
                    bool _e749 = l_mut_119_;
                    if (_e749) {
                        uint l_320_ = l_14_ + 0u;
                        shared_memory_13_.inner[l_320_] = 0u;
                        uint l_321_ = l_14_ + 1u;
                        shared_memory_13_.inner[l_321_] = 0u;
                        uint l_322_ = l_14_ + 2u;
                        shared_memory_13_.inner[l_322_] = 0u;
                        uint l_323_ = l_14_ + 3u;
                        shared_memory_13_.inner[l_323_] = 0u;
                        uint l_324_ = l_14_ + 4u;
                        shared_memory_13_.inner[l_324_] = 0u;
                        uint l_325_ = l_14_ + 5u;
                        shared_memory_13_.inner[l_325_] = 0u;
                        uint l_326_ = l_14_ + 6u;
                        shared_memory_13_.inner[l_326_] = 0u;
                        uint l_327_ = l_14_ + 7u;
                        shared_memory_13_.inner[l_327_] = 0u;
                        uint l_328_ = l_14_ + 8u;
                        shared_memory_13_.inner[l_328_] = 0u;
                        l_mut_143_ = 0uL;
                        uint l_329_ = a_142_.inner[0];
                        ulong l_330_ = static_cast<ulong>(l_329_);
                        uint l_331_ = a_135_.inner[0];
                        ulong l_332_ = static_cast<ulong>(l_331_);
                        ulong l_333_ = l_330_ * l_332_;
                        uint l_334_ = l_14_ + 0u;
                        uint l_335_ = shared_memory_13_.inner[l_334_];
                        ulong l_336_ = static_cast<ulong>(l_335_);
                        ulong l_337_ = l_333_ + l_336_;
                        ulong _e810 = l_mut_143_;
                        ulong l_338_ = l_337_ + _e810;
                        uint l_339_ = l_14_ + 0u;
                        uint l_340_ = static_cast<uint>(as_type<ulong>(l_338_));
                        shared_memory_13_.inner[l_339_] = l_340_;
                        ulong l_341_ = l_338_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_341_;
                        uint l_342_ = a_142_.inner[0];
                        ulong l_343_ = static_cast<ulong>(l_342_);
                        uint l_344_ = a_135_.inner[1];
                        ulong l_345_ = static_cast<ulong>(l_344_);
                        ulong l_346_ = l_343_ * l_345_;
                        uint l_347_ = l_14_ + 1u;
                        uint l_348_ = shared_memory_13_.inner[l_347_];
                        ulong l_349_ = static_cast<ulong>(l_348_);
                        ulong l_350_ = l_346_ + l_349_;
                        ulong _e836 = l_mut_143_;
                        ulong l_351_ = l_350_ + _e836;
                        uint l_352_ = l_14_ + 1u;
                        uint l_353_ = static_cast<uint>(as_type<ulong>(l_351_));
                        shared_memory_13_.inner[l_352_] = l_353_;
                        ulong l_354_ = l_351_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_354_;
                        uint l_355_ = a_142_.inner[0];
                        ulong l_356_ = static_cast<ulong>(l_355_);
                        uint l_357_ = a_135_.inner[2];
                        ulong l_358_ = static_cast<ulong>(l_357_);
                        ulong l_359_ = l_356_ * l_358_;
                        uint l_360_ = l_14_ + 2u;
                        uint l_361_ = shared_memory_13_.inner[l_360_];
                        ulong l_362_ = static_cast<ulong>(l_361_);
                        ulong l_363_ = l_359_ + l_362_;
                        ulong _e862 = l_mut_143_;
                        ulong l_364_ = l_363_ + _e862;
                        uint l_365_ = l_14_ + 2u;
                        uint l_366_ = static_cast<uint>(as_type<ulong>(l_364_));
                        shared_memory_13_.inner[l_365_] = l_366_;
                        ulong l_367_ = l_364_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_367_;
                        uint l_368_ = l_14_ + 3u;
                        ulong _e876 = l_mut_143_;
                        uint l_369_ = static_cast<uint>(as_type<ulong>(_e876));
                        shared_memory_13_.inner[l_368_] = l_369_;
                        l_mut_143_ = 0uL;
                        uint l_370_ = a_142_.inner[1];
                        ulong l_371_ = static_cast<ulong>(l_370_);
                        uint l_372_ = a_135_.inner[0];
                        ulong l_373_ = static_cast<ulong>(l_372_);
                        ulong l_374_ = l_371_ * l_373_;
                        uint l_375_ = l_14_ + 1u;
                        uint l_376_ = shared_memory_13_.inner[l_375_];
                        ulong l_377_ = static_cast<ulong>(l_376_);
                        ulong l_378_ = l_374_ + l_377_;
                        ulong _e896 = l_mut_143_;
                        ulong l_379_ = l_378_ + _e896;
                        uint l_380_ = l_14_ + 1u;
                        uint l_381_ = static_cast<uint>(as_type<ulong>(l_379_));
                        shared_memory_13_.inner[l_380_] = l_381_;
                        ulong l_382_ = l_379_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_382_;
                        uint l_383_ = a_142_.inner[1];
                        ulong l_384_ = static_cast<ulong>(l_383_);
                        uint l_385_ = a_135_.inner[1];
                        ulong l_386_ = static_cast<ulong>(l_385_);
                        ulong l_387_ = l_384_ * l_386_;
                        uint l_388_ = l_14_ + 2u;
                        uint l_389_ = shared_memory_13_.inner[l_388_];
                        ulong l_390_ = static_cast<ulong>(l_389_);
                        ulong l_391_ = l_387_ + l_390_;
                        ulong _e922 = l_mut_143_;
                        ulong l_392_ = l_391_ + _e922;
                        uint l_393_ = l_14_ + 2u;
                        uint l_394_ = static_cast<uint>(as_type<ulong>(l_392_));
                        shared_memory_13_.inner[l_393_] = l_394_;
                        ulong l_395_ = l_392_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_395_;
                        uint l_396_ = a_142_.inner[1];
                        ulong l_397_ = static_cast<ulong>(l_396_);
                        uint l_398_ = a_135_.inner[2];
                        ulong l_399_ = static_cast<ulong>(l_398_);
                        ulong l_400_ = l_397_ * l_399_;
                        uint l_401_ = l_14_ + 3u;
                        uint l_402_ = shared_memory_13_.inner[l_401_];
                        ulong l_403_ = static_cast<ulong>(l_402_);
                        ulong l_404_ = l_400_ + l_403_;
                        ulong _e948 = l_mut_143_;
                        ulong l_405_ = l_404_ + _e948;
                        uint l_406_ = l_14_ + 3u;
                        uint l_407_ = static_cast<uint>(as_type<ulong>(l_405_));
                        shared_memory_13_.inner[l_406_] = l_407_;
                        ulong l_408_ = l_405_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_408_;
                        uint l_409_ = l_14_ + 4u;
                        ulong _e962 = l_mut_143_;
                        uint l_410_ = static_cast<uint>(as_type<ulong>(_e962));
                        shared_memory_13_.inner[l_409_] = l_410_;
                        l_mut_143_ = 0uL;
                        uint l_411_ = a_142_.inner[2];
                        ulong l_412_ = static_cast<ulong>(l_411_);
                        uint l_413_ = a_135_.inner[0];
                        ulong l_414_ = static_cast<ulong>(l_413_);
                        ulong l_415_ = l_412_ * l_414_;
                        uint l_416_ = l_14_ + 2u;
                        uint l_417_ = shared_memory_13_.inner[l_416_];
                        ulong l_418_ = static_cast<ulong>(l_417_);
                        ulong l_419_ = l_415_ + l_418_;
                        ulong _e982 = l_mut_143_;
                        ulong l_420_ = l_419_ + _e982;
                        uint l_421_ = l_14_ + 2u;
                        uint l_422_ = static_cast<uint>(as_type<ulong>(l_420_));
                        shared_memory_13_.inner[l_421_] = l_422_;
                        ulong l_423_ = l_420_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_423_;
                        uint l_424_ = a_142_.inner[2];
                        ulong l_425_ = static_cast<ulong>(l_424_);
                        uint l_426_ = a_135_.inner[1];
                        ulong l_427_ = static_cast<ulong>(l_426_);
                        ulong l_428_ = l_425_ * l_427_;
                        uint l_429_ = l_14_ + 3u;
                        uint l_430_ = shared_memory_13_.inner[l_429_];
                        ulong l_431_ = static_cast<ulong>(l_430_);
                        ulong l_432_ = l_428_ + l_431_;
                        ulong _e1008 = l_mut_143_;
                        ulong l_433_ = l_432_ + _e1008;
                        uint l_434_ = l_14_ + 3u;
                        uint l_435_ = static_cast<uint>(as_type<ulong>(l_433_));
                        shared_memory_13_.inner[l_434_] = l_435_;
                        ulong l_436_ = l_433_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_436_;
                        uint l_437_ = a_142_.inner[2];
                        ulong l_438_ = static_cast<ulong>(l_437_);
                        uint l_439_ = a_135_.inner[2];
                        ulong l_440_ = static_cast<ulong>(l_439_);
                        ulong l_441_ = l_438_ * l_440_;
                        uint l_442_ = l_14_ + 4u;
                        uint l_443_ = shared_memory_13_.inner[l_442_];
                        ulong l_444_ = static_cast<ulong>(l_443_);
                        ulong l_445_ = l_441_ + l_444_;
                        ulong _e1034 = l_mut_143_;
                        ulong l_446_ = l_445_ + _e1034;
                        uint l_447_ = l_14_ + 4u;
                        uint l_448_ = static_cast<uint>(as_type<ulong>(l_446_));
                        shared_memory_13_.inner[l_447_] = l_448_;
                        ulong l_449_ = l_446_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_449_;
                        uint l_450_ = l_14_ + 5u;
                        ulong _e1048 = l_mut_143_;
                        uint l_451_ = static_cast<uint>(as_type<ulong>(_e1048));
                        shared_memory_13_.inner[l_450_] = l_451_;
                        l_mut_143_ = 0uL;
                        uint l_452_ = a_142_.inner[3];
                        ulong l_453_ = static_cast<ulong>(l_452_);
                        uint l_454_ = a_135_.inner[0];
                        ulong l_455_ = static_cast<ulong>(l_454_);
                        ulong l_456_ = l_453_ * l_455_;
                        uint l_457_ = l_14_ + 3u;
                        uint l_458_ = shared_memory_13_.inner[l_457_];
                        ulong l_459_ = static_cast<ulong>(l_458_);
                        ulong l_460_ = l_456_ + l_459_;
                        ulong _e1068 = l_mut_143_;
                        ulong l_461_ = l_460_ + _e1068;
                        uint l_462_ = l_14_ + 3u;
                        uint l_463_ = static_cast<uint>(as_type<ulong>(l_461_));
                        shared_memory_13_.inner[l_462_] = l_463_;
                        ulong l_464_ = l_461_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_464_;
                        uint l_465_ = a_142_.inner[3];
                        ulong l_466_ = static_cast<ulong>(l_465_);
                        uint l_467_ = a_135_.inner[1];
                        ulong l_468_ = static_cast<ulong>(l_467_);
                        ulong l_469_ = l_466_ * l_468_;
                        uint l_470_ = l_14_ + 4u;
                        uint l_471_ = shared_memory_13_.inner[l_470_];
                        ulong l_472_ = static_cast<ulong>(l_471_);
                        ulong l_473_ = l_469_ + l_472_;
                        ulong _e1094 = l_mut_143_;
                        ulong l_474_ = l_473_ + _e1094;
                        uint l_475_ = l_14_ + 4u;
                        uint l_476_ = static_cast<uint>(as_type<ulong>(l_474_));
                        shared_memory_13_.inner[l_475_] = l_476_;
                        ulong l_477_ = l_474_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_477_;
                        uint l_478_ = a_142_.inner[3];
                        ulong l_479_ = static_cast<ulong>(l_478_);
                        uint l_480_ = a_135_.inner[2];
                        ulong l_481_ = static_cast<ulong>(l_480_);
                        ulong l_482_ = l_479_ * l_481_;
                        uint l_483_ = l_14_ + 5u;
                        uint l_484_ = shared_memory_13_.inner[l_483_];
                        ulong l_485_ = static_cast<ulong>(l_484_);
                        ulong l_486_ = l_482_ + l_485_;
                        ulong _e1120 = l_mut_143_;
                        ulong l_487_ = l_486_ + _e1120;
                        uint l_488_ = l_14_ + 5u;
                        uint l_489_ = static_cast<uint>(as_type<ulong>(l_487_));
                        shared_memory_13_.inner[l_488_] = l_489_;
                        ulong l_490_ = l_487_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_490_;
                        uint l_491_ = l_14_ + 6u;
                        ulong _e1134 = l_mut_143_;
                        uint l_492_ = static_cast<uint>(as_type<ulong>(_e1134));
                        shared_memory_13_.inner[l_491_] = l_492_;
                        l_mut_143_ = 0uL;
                        uint l_493_ = a_142_.inner[4];
                        ulong l_494_ = static_cast<ulong>(l_493_);
                        uint l_495_ = a_135_.inner[0];
                        ulong l_496_ = static_cast<ulong>(l_495_);
                        ulong l_497_ = l_494_ * l_496_;
                        uint l_498_ = l_14_ + 4u;
                        uint l_499_ = shared_memory_13_.inner[l_498_];
                        ulong l_500_ = static_cast<ulong>(l_499_);
                        ulong l_501_ = l_497_ + l_500_;
                        ulong _e1154 = l_mut_143_;
                        ulong l_502_ = l_501_ + _e1154;
                        uint l_503_ = l_14_ + 4u;
                        uint l_504_ = static_cast<uint>(as_type<ulong>(l_502_));
                        shared_memory_13_.inner[l_503_] = l_504_;
                        ulong l_505_ = l_502_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_505_;
                        uint l_506_ = a_142_.inner[4];
                        ulong l_507_ = static_cast<ulong>(l_506_);
                        uint l_508_ = a_135_.inner[1];
                        ulong l_509_ = static_cast<ulong>(l_508_);
                        ulong l_510_ = l_507_ * l_509_;
                        uint l_511_ = l_14_ + 5u;
                        uint l_512_ = shared_memory_13_.inner[l_511_];
                        ulong l_513_ = static_cast<ulong>(l_512_);
                        ulong l_514_ = l_510_ + l_513_;
                        ulong _e1180 = l_mut_143_;
                        ulong l_515_ = l_514_ + _e1180;
                        uint l_516_ = l_14_ + 5u;
                        uint l_517_ = static_cast<uint>(as_type<ulong>(l_515_));
                        shared_memory_13_.inner[l_516_] = l_517_;
                        ulong l_518_ = l_515_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_518_;
                        uint l_519_ = a_142_.inner[4];
                        ulong l_520_ = static_cast<ulong>(l_519_);
                        uint l_521_ = a_135_.inner[2];
                        ulong l_522_ = static_cast<ulong>(l_521_);
                        ulong l_523_ = l_520_ * l_522_;
                        uint l_524_ = l_14_ + 6u;
                        uint l_525_ = shared_memory_13_.inner[l_524_];
                        ulong l_526_ = static_cast<ulong>(l_525_);
                        ulong l_527_ = l_523_ + l_526_;
                        ulong _e1206 = l_mut_143_;
                        ulong l_528_ = l_527_ + _e1206;
                        uint l_529_ = l_14_ + 6u;
                        uint l_530_ = static_cast<uint>(as_type<ulong>(l_528_));
                        shared_memory_13_.inner[l_529_] = l_530_;
                        ulong l_531_ = l_528_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_531_;
                        uint l_532_ = l_14_ + 7u;
                        ulong _e1220 = l_mut_143_;
                        uint l_533_ = static_cast<uint>(as_type<ulong>(_e1220));
                        shared_memory_13_.inner[l_532_] = l_533_;
                        l_mut_143_ = 0uL;
                        uint l_534_ = a_142_.inner[5];
                        ulong l_535_ = static_cast<ulong>(l_534_);
                        uint l_536_ = a_135_.inner[0];
                        ulong l_537_ = static_cast<ulong>(l_536_);
                        ulong l_538_ = l_535_ * l_537_;
                        uint l_539_ = l_14_ + 5u;
                        uint l_540_ = shared_memory_13_.inner[l_539_];
                        ulong l_541_ = static_cast<ulong>(l_540_);
                        ulong l_542_ = l_538_ + l_541_;
                        ulong _e1240 = l_mut_143_;
                        ulong l_543_ = l_542_ + _e1240;
                        uint l_544_ = l_14_ + 5u;
                        uint l_545_ = static_cast<uint>(as_type<ulong>(l_543_));
                        shared_memory_13_.inner[l_544_] = l_545_;
                        ulong l_546_ = l_543_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_546_;
                        uint l_547_ = a_142_.inner[5];
                        ulong l_548_ = static_cast<ulong>(l_547_);
                        uint l_549_ = a_135_.inner[1];
                        ulong l_550_ = static_cast<ulong>(l_549_);
                        ulong l_551_ = l_548_ * l_550_;
                        uint l_552_ = l_14_ + 6u;
                        uint l_553_ = shared_memory_13_.inner[l_552_];
                        ulong l_554_ = static_cast<ulong>(l_553_);
                        ulong l_555_ = l_551_ + l_554_;
                        ulong _e1266 = l_mut_143_;
                        ulong l_556_ = l_555_ + _e1266;
                        uint l_557_ = l_14_ + 6u;
                        uint l_558_ = static_cast<uint>(as_type<ulong>(l_556_));
                        shared_memory_13_.inner[l_557_] = l_558_;
                        ulong l_559_ = l_556_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_559_;
                        uint l_560_ = a_142_.inner[5];
                        ulong l_561_ = static_cast<ulong>(l_560_);
                        uint l_562_ = a_135_.inner[2];
                        ulong l_563_ = static_cast<ulong>(l_562_);
                        ulong l_564_ = l_561_ * l_563_;
                        uint l_565_ = l_14_ + 7u;
                        uint l_566_ = shared_memory_13_.inner[l_565_];
                        ulong l_567_ = static_cast<ulong>(l_566_);
                        ulong l_568_ = l_564_ + l_567_;
                        ulong _e1292 = l_mut_143_;
                        ulong l_569_ = l_568_ + _e1292;
                        uint l_570_ = l_14_ + 7u;
                        uint l_571_ = static_cast<uint>(as_type<ulong>(l_569_));
                        shared_memory_13_.inner[l_570_] = l_571_;
                        ulong l_572_ = l_569_ >> static_cast<uint>(as_type<ulong>(32uL));
                        l_mut_143_ = l_572_;
                        uint l_573_ = l_14_ + 8u;
                        ulong _e1306 = l_mut_143_;
                        uint l_574_ = static_cast<uint>(as_type<ulong>(_e1306));
                        shared_memory_13_.inner[l_573_] = l_574_;
                        l_mut_269_ = 8;
                        uint2 loop_bound_8 = uint2(4294967295u);
                        while(true) {
                            if (metal::all(loop_bound_8 == uint2(0u))) { break; }
                            loop_bound_8 -= uint2(loop_bound_8.y == 0u, 1u);
                            int _e1312 = l_mut_269_;
                            bool l_575_ = _e1312 >= 0;
                            bool l_576_ = !(l_575_);
                            if (l_576_) {
                                break;
                            }
                            int _e1316 = l_mut_269_;
                            uint l_577_ = static_cast<uint>(_e1316);
                            uint l_578_ = l_14_ + l_577_;
                            uint l_579_ = shared_memory_13_.inner[l_578_];
                            bool l_580_ = l_579_ != 0u;
                            if (l_580_) {
                                break;
                            }
                            int _e1324 = l_mut_269_;
                            l_mut_269_ = as_type<int>(as_type<uint>(_e1324) - as_type<uint>(1));
                        }
                        uint2 loop_bound_9 = uint2(4294967295u);
                        while(true) {
                            if (metal::all(loop_bound_9 == uint2(0u))) { break; }
                            loop_bound_9 -= uint2(loop_bound_9.y == 0u, 1u);
                            int _e1327 = l_mut_269_;
                            bool l_581_ = _e1327 >= 0;
                            if (l_581_) {
                                bool _e1332 = l_mut_119_;
                                local_4 = _e1332;
                            } else {
                                local_4 = false;
                            }
                            bool l_582_ = local_4;
                            bool l_583_ = !(l_582_);
                            if (l_583_) {
                                break;
                            }
                            l_mut_297_ = 0u;
                            int _e1337 = l_mut_269_;
                            l_mut_584_ = _e1337;
                            uint2 loop_bound_10 = uint2(4294967295u);
                            while(true) {
                                if (metal::all(loop_bound_10 == uint2(0u))) { break; }
                                loop_bound_10 -= uint2(loop_bound_10.y == 0u, 1u);
                                int _e1338 = l_mut_584_;
                                bool l_585_ = _e1338 >= 0;
                                bool l_586_ = !(l_585_);
                                if (l_586_) {
                                    break;
                                }
                                int _e1342 = l_mut_584_;
                                uint l_587_ = static_cast<uint>(_e1342);
                                uint l_588_ = l_14_ + l_587_;
                                uint l_589_ = shared_memory_13_.inner[l_588_];
                                uint _e1348 = l_mut_297_;
                                uint l_590_ = _e1348 << 16u;
                                uint l_591_ = l_589_ >> 16u;
                                uint l_592_ = l_590_ | l_591_;
                                uint l_593_ = naga_div(l_592_, 3364u);
                                uint l_594_ = l_593_ * 3364u;
                                uint l_595_ = l_592_ - l_594_;
                                uint l_596_ = l_595_ << 16u;
                                uint l_597_ = l_589_ & 65535u;
                                uint l_598_ = l_596_ | l_597_;
                                uint l_599_ = naga_div(l_598_, 3364u);
                                uint l_600_ = l_599_ * 3364u;
                                uint l_601_ = l_598_ - l_600_;
                                l_mut_297_ = l_601_;
                                int _e1369 = l_mut_584_;
                                uint l_602_ = static_cast<uint>(_e1369);
                                uint l_603_ = l_14_ + l_602_;
                                uint l_604_ = l_593_ << 16u;
                                uint l_605_ = l_604_ | l_599_;
                                shared_memory_13_.inner[l_603_] = l_605_;
                                int _e1377 = l_mut_584_;
                                l_mut_584_ = as_type<int>(as_type<uint>(_e1377) - as_type<uint>(1));
                            }
                            uint2 loop_bound_11 = uint2(4294967295u);
                            while(true) {
                                if (metal::all(loop_bound_11 == uint2(0u))) { break; }
                                loop_bound_11 -= uint2(loop_bound_11.y == 0u, 1u);
                                int _e1380 = l_mut_269_;
                                bool l_606_ = _e1380 >= 0;
                                bool l_607_ = !(l_606_);
                                if (l_607_) {
                                    break;
                                }
                                int _e1384 = l_mut_269_;
                                uint l_608_ = static_cast<uint>(_e1384);
                                uint l_609_ = l_14_ + l_608_;
                                uint l_610_ = shared_memory_13_.inner[l_609_];
                                bool l_611_ = l_610_ != 0u;
                                if (l_611_) {
                                    break;
                                }
                                int _e1392 = l_mut_269_;
                                l_mut_269_ = as_type<int>(as_type<uint>(_e1392) - as_type<uint>(1));
                            }
                            uint _e1395 = l_mut_297_;
                            l_mut_268_ = _e1395;
                            l_mut_143_ = 0uL;
                            int _e1397 = l_mut_269_;
                            bool l_612_ = _e1397 >= 0;
                            if (l_612_) {
                                uint _e1400 = l_mut_268_;
                                uint l_613_ = naga_div(_e1400, 58u);
                                uint l_614_ = l_613_ * 58u;
                                uint _e1405 = l_mut_268_;
                                uint l_615_ = _e1405 - l_614_;
                                l_mut_268_ = l_613_;
                                ulong l_616_ = static_cast<ulong>(l_615_);
                                ulong l_617_ = 1uL << static_cast<uint>(as_type<ulong>(l_616_));
                                ulong _e1412 = l_mut_132_;
                                ulong l_618_ = _e1412 & l_617_;
                                ulong _e1414 = l_mut_143_;
                                l_mut_143_ = _e1414 | l_618_;
                                ulong _e1416 = l_mut_132_;
                                l_mut_132_ = _e1416 | l_617_;
                                uint _e1418 = l_mut_268_;
                                uint l_619_ = naga_div(_e1418, 58u);
                                uint l_620_ = l_619_ * 58u;
                                uint _e1423 = l_mut_268_;
                                uint l_621_ = _e1423 - l_620_;
                                l_mut_268_ = l_619_;
                                ulong l_622_ = static_cast<ulong>(l_621_);
                                ulong l_623_ = 1uL << static_cast<uint>(as_type<ulong>(l_622_));
                                ulong _e1430 = l_mut_132_;
                                ulong l_624_ = _e1430 & l_623_;
                                ulong _e1432 = l_mut_143_;
                                l_mut_143_ = _e1432 | l_624_;
                                ulong _e1434 = l_mut_132_;
                                l_mut_132_ = _e1434 | l_623_;
                            } else {
                                uint2 loop_bound_12 = uint2(4294967295u);
                                while(true) {
                                    if (metal::all(loop_bound_12 == uint2(0u))) { break; }
                                    loop_bound_12 -= uint2(loop_bound_12.y == 0u, 1u);
                                    uint _e1436 = l_mut_268_;
                                    bool l_625_ = _e1436 != 0u;
                                    bool l_626_ = !(l_625_);
                                    if (l_626_) {
                                        break;
                                    }
                                    uint _e1440 = l_mut_268_;
                                    uint l_627_ = naga_div(_e1440, 58u);
                                    uint l_628_ = l_627_ * 58u;
                                    uint _e1445 = l_mut_268_;
                                    uint l_629_ = _e1445 - l_628_;
                                    l_mut_268_ = l_627_;
                                    ulong l_630_ = static_cast<ulong>(l_629_);
                                    ulong l_631_ = 1uL << static_cast<uint>(as_type<ulong>(l_630_));
                                    ulong _e1452 = l_mut_132_;
                                    ulong l_632_ = _e1452 & l_631_;
                                    ulong _e1454 = l_mut_143_;
                                    l_mut_143_ = _e1454 | l_632_;
                                    ulong _e1456 = l_mut_132_;
                                    l_mut_132_ = _e1456 | l_631_;
                                }
                            }
                            ulong _e1458 = l_mut_143_;
                            bool l_633_ = _e1458 != 0uL;
                            if (l_633_) {
                                l_mut_119_ = false;
                            }
                        }
                    }
                }
                bool _e1462 = l_mut_119_;
                if (_e1462) {
                    ulong _e1463 = l_mut_132_;
                    uint l_634_ = static_cast<uint>(as_type<ulong>(_e1463));
                    uint l_635_ = metal::popcount(l_634_);
                    ulong _e1467 = l_mut_132_;
                    ulong l_636_ = _e1467 >> static_cast<uint>(as_type<ulong>(32uL));
                    uint l_637_ = static_cast<uint>(as_type<ulong>(l_636_));
                    uint l_638_ = metal::popcount(l_637_);
                    uint l_639_ = l_635_ + l_638_;
                    l_mut_297_ = l_639_;
                    uint _e1476 = l_mut_297_;
                    bool l_640_ = _e1476 == 58u;
                    if (true) {
                        local_5 = l_640_;
                    } else {
                        local_5 = true;
                    }
                    bool l_641_ = local_5;
                    if (l_641_) {
                        uint _e1487 = metal::atomic_fetch_add_explicit(&buffer_4_global[0], 1u, metal::memory_order_relaxed);
                        uint _e1491 = info.scalars_u32_.inner[6];
                        bool l_644_ = _e1487 < _e1491;
                        if (l_644_) {
                            uint l_645_ = 4u * _e1487;
                            uint l_646_ = static_cast<uint>(as_type<ulong>(l_112_));
                            buffer_3_global[l_645_] = l_646_;
                            uint l_647_ = l_645_ + 1u;
                            ulong l_648_ = l_112_ >> static_cast<uint>(as_type<ulong>(32uL));
                            uint l_649_ = static_cast<uint>(as_type<ulong>(l_648_));
                            buffer_3_global[l_647_] = l_649_;
                            uint l_650_ = l_645_ + 2u;
                            ulong _e1511 = l_mut_39_;
                            uint l_651_ = static_cast<uint>(as_type<ulong>(_e1511));
                            buffer_3_global[l_650_] = l_651_;
                            uint l_652_ = l_645_ + 3u;
                            ulong _e1518 = l_mut_39_;
                            ulong l_653_ = _e1518 >> static_cast<uint>(as_type<ulong>(32uL));
                            uint l_654_ = static_cast<uint>(as_type<ulong>(l_653_));
                            buffer_3_global[l_652_] = l_654_;
                        }
                    }
                }
            }
            uint _e1527 = l_mut_46_;
            l_mut_46_ = _e1527 + l_0_;
        }
        uint _e1529 = l_mut_16_;
        l_mut_16_ = _e1529 + l_4_;
    }
    return;
}
