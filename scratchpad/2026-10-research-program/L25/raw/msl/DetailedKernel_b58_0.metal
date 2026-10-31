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
    metal::atomic_uint inner[236];
};
struct type_7 {
    uint inner[2304];
};
struct type_9 {
    uint inner[3];
};
struct type_10 {
    uint inner[9];
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
        for (int __i0 = 0; __i0 < 236; __i0++) {
            metal::atomic_store_explicit(&shared_memory_0_.inner[__i0], 0, metal::memory_order_relaxed);
        }
        shared_memory_22_ = {};
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    type_9 a_31_ = {};
    type_5 a_38_ = {};
    type_10 a_142_ = {};
    uint l_mut_1_ = {};
    uint l_mut_348_ = {};
    uint l_mut_394_ = {};
    uint l_mut_423_ = {};
    int l_mut_385_ = {};
    int l_mut_395_ = {};
    ulong l_mut_25_ = {};
    ulong l_mut_29_ = {};
    ulong l_mut_39_ = {};
    ulong l_mut_347_ = {};
    l_mut_1_ = local_invocation_id.x;
    uint2 loop_bound = uint2(4294967295u);
    while(true) {
        if (metal::all(loop_bound == uint2(0u))) { break; }
        loop_bound -= uint2(loop_bound.y == 0u, 1u);
        uint _e17 = l_mut_1_;
        bool l_2_ = _e17 < 236u;
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
    uint l_23_ = local_invocation_id.x * 9u;
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
        ulong l_34_ = l_28_ >> static_cast<uint>(as_type<ulong>(32uL));
        uint l_35_ = static_cast<uint>(as_type<ulong>(l_34_));
        a_31_.inner[1] = l_35_;
        ulong _e110 = l_mut_29_;
        ulong l_36_ = _e110 >> static_cast<uint>(as_type<ulong>(0uL));
        uint l_37_ = static_cast<uint>(as_type<ulong>(l_36_));
        a_31_.inner[2] = l_37_;
        a_38_.inner[0] = 0u;
        a_38_.inner[1] = 0u;
        a_38_.inner[2] = 0u;
        a_38_.inner[3] = 0u;
        a_38_.inner[4] = 0u;
        a_38_.inner[5] = 0u;
        l_mut_39_ = 0uL;
        uint l_40_ = a_31_.inner[0];
        ulong l_41_ = static_cast<ulong>(l_40_);
        uint l_42_ = a_31_.inner[0];
        ulong l_43_ = static_cast<ulong>(l_42_);
        ulong l_44_ = l_41_ * l_43_;
        uint l_45_ = a_38_.inner[0];
        ulong l_46_ = static_cast<ulong>(l_45_);
        ulong l_47_ = l_44_ + l_46_;
        ulong _e142 = l_mut_39_;
        ulong l_48_ = l_47_ + _e142;
        uint l_49_ = static_cast<uint>(as_type<ulong>(l_48_));
        a_38_.inner[0] = l_49_;
        ulong l_50_ = l_48_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_50_;
        uint l_51_ = a_31_.inner[0];
        ulong l_52_ = static_cast<ulong>(l_51_);
        uint l_53_ = a_31_.inner[1];
        ulong l_54_ = static_cast<ulong>(l_53_);
        ulong l_55_ = l_52_ * l_54_;
        uint l_56_ = a_38_.inner[1];
        ulong l_57_ = static_cast<ulong>(l_56_);
        ulong l_58_ = l_55_ + l_57_;
        ulong _e162 = l_mut_39_;
        ulong l_59_ = l_58_ + _e162;
        uint l_60_ = static_cast<uint>(as_type<ulong>(l_59_));
        a_38_.inner[1] = l_60_;
        ulong l_61_ = l_59_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_61_;
        uint l_62_ = a_31_.inner[0];
        ulong l_63_ = static_cast<ulong>(l_62_);
        uint l_64_ = a_31_.inner[2];
        ulong l_65_ = static_cast<ulong>(l_64_);
        ulong l_66_ = l_63_ * l_65_;
        uint l_67_ = a_38_.inner[2];
        ulong l_68_ = static_cast<ulong>(l_67_);
        ulong l_69_ = l_66_ + l_68_;
        ulong _e182 = l_mut_39_;
        ulong l_70_ = l_69_ + _e182;
        uint l_71_ = static_cast<uint>(as_type<ulong>(l_70_));
        a_38_.inner[2] = l_71_;
        ulong l_72_ = l_70_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_72_;
        ulong _e191 = l_mut_39_;
        uint l_73_ = static_cast<uint>(as_type<ulong>(_e191));
        a_38_.inner[3] = l_73_;
        l_mut_39_ = 0uL;
        uint l_74_ = a_31_.inner[1];
        ulong l_75_ = static_cast<ulong>(l_74_);
        uint l_76_ = a_31_.inner[0];
        ulong l_77_ = static_cast<ulong>(l_76_);
        ulong l_78_ = l_75_ * l_77_;
        uint l_79_ = a_38_.inner[1];
        ulong l_80_ = static_cast<ulong>(l_79_);
        ulong l_81_ = l_78_ + l_80_;
        ulong _e207 = l_mut_39_;
        ulong l_82_ = l_81_ + _e207;
        uint l_83_ = static_cast<uint>(as_type<ulong>(l_82_));
        a_38_.inner[1] = l_83_;
        ulong l_84_ = l_82_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_84_;
        uint l_85_ = a_31_.inner[1];
        ulong l_86_ = static_cast<ulong>(l_85_);
        uint l_87_ = a_31_.inner[1];
        ulong l_88_ = static_cast<ulong>(l_87_);
        ulong l_89_ = l_86_ * l_88_;
        uint l_90_ = a_38_.inner[2];
        ulong l_91_ = static_cast<ulong>(l_90_);
        ulong l_92_ = l_89_ + l_91_;
        ulong _e227 = l_mut_39_;
        ulong l_93_ = l_92_ + _e227;
        uint l_94_ = static_cast<uint>(as_type<ulong>(l_93_));
        a_38_.inner[2] = l_94_;
        ulong l_95_ = l_93_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_95_;
        uint l_96_ = a_31_.inner[1];
        ulong l_97_ = static_cast<ulong>(l_96_);
        uint l_98_ = a_31_.inner[2];
        ulong l_99_ = static_cast<ulong>(l_98_);
        ulong l_100_ = l_97_ * l_99_;
        uint l_101_ = a_38_.inner[3];
        ulong l_102_ = static_cast<ulong>(l_101_);
        ulong l_103_ = l_100_ + l_102_;
        ulong _e247 = l_mut_39_;
        ulong l_104_ = l_103_ + _e247;
        uint l_105_ = static_cast<uint>(as_type<ulong>(l_104_));
        a_38_.inner[3] = l_105_;
        ulong l_106_ = l_104_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_106_;
        ulong _e256 = l_mut_39_;
        uint l_107_ = static_cast<uint>(as_type<ulong>(_e256));
        a_38_.inner[4] = l_107_;
        l_mut_39_ = 0uL;
        uint l_108_ = a_31_.inner[2];
        ulong l_109_ = static_cast<ulong>(l_108_);
        uint l_110_ = a_31_.inner[0];
        ulong l_111_ = static_cast<ulong>(l_110_);
        ulong l_112_ = l_109_ * l_111_;
        uint l_113_ = a_38_.inner[2];
        ulong l_114_ = static_cast<ulong>(l_113_);
        ulong l_115_ = l_112_ + l_114_;
        ulong _e272 = l_mut_39_;
        ulong l_116_ = l_115_ + _e272;
        uint l_117_ = static_cast<uint>(as_type<ulong>(l_116_));
        a_38_.inner[2] = l_117_;
        ulong l_118_ = l_116_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_118_;
        uint l_119_ = a_31_.inner[2];
        ulong l_120_ = static_cast<ulong>(l_119_);
        uint l_121_ = a_31_.inner[1];
        ulong l_122_ = static_cast<ulong>(l_121_);
        ulong l_123_ = l_120_ * l_122_;
        uint l_124_ = a_38_.inner[3];
        ulong l_125_ = static_cast<ulong>(l_124_);
        ulong l_126_ = l_123_ + l_125_;
        ulong _e292 = l_mut_39_;
        ulong l_127_ = l_126_ + _e292;
        uint l_128_ = static_cast<uint>(as_type<ulong>(l_127_));
        a_38_.inner[3] = l_128_;
        ulong l_129_ = l_127_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_129_;
        uint l_130_ = a_31_.inner[2];
        ulong l_131_ = static_cast<ulong>(l_130_);
        uint l_132_ = a_31_.inner[2];
        ulong l_133_ = static_cast<ulong>(l_132_);
        ulong l_134_ = l_131_ * l_133_;
        uint l_135_ = a_38_.inner[4];
        ulong l_136_ = static_cast<ulong>(l_135_);
        ulong l_137_ = l_134_ + l_136_;
        ulong _e312 = l_mut_39_;
        ulong l_138_ = l_137_ + _e312;
        uint l_139_ = static_cast<uint>(as_type<ulong>(l_138_));
        a_38_.inner[4] = l_139_;
        ulong l_140_ = l_138_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_140_;
        ulong _e321 = l_mut_39_;
        uint l_141_ = static_cast<uint>(as_type<ulong>(_e321));
        a_38_.inner[5] = l_141_;
        a_142_.inner[0] = 0u;
        a_142_.inner[1] = 0u;
        a_142_.inner[2] = 0u;
        a_142_.inner[3] = 0u;
        a_142_.inner[4] = 0u;
        a_142_.inner[5] = 0u;
        a_142_.inner[6] = 0u;
        a_142_.inner[7] = 0u;
        a_142_.inner[8] = 0u;
        l_mut_39_ = 0uL;
        uint l_143_ = a_38_.inner[0];
        ulong l_144_ = static_cast<ulong>(l_143_);
        uint l_145_ = a_31_.inner[0];
        ulong l_146_ = static_cast<ulong>(l_145_);
        ulong l_147_ = l_144_ * l_146_;
        uint l_148_ = a_142_.inner[0];
        ulong l_149_ = static_cast<ulong>(l_148_);
        ulong l_150_ = l_147_ + l_149_;
        ulong _e355 = l_mut_39_;
        ulong l_151_ = l_150_ + _e355;
        uint l_152_ = static_cast<uint>(as_type<ulong>(l_151_));
        a_142_.inner[0] = l_152_;
        ulong l_153_ = l_151_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_153_;
        uint l_154_ = a_38_.inner[0];
        ulong l_155_ = static_cast<ulong>(l_154_);
        uint l_156_ = a_31_.inner[1];
        ulong l_157_ = static_cast<ulong>(l_156_);
        ulong l_158_ = l_155_ * l_157_;
        uint l_159_ = a_142_.inner[1];
        ulong l_160_ = static_cast<ulong>(l_159_);
        ulong l_161_ = l_158_ + l_160_;
        ulong _e375 = l_mut_39_;
        ulong l_162_ = l_161_ + _e375;
        uint l_163_ = static_cast<uint>(as_type<ulong>(l_162_));
        a_142_.inner[1] = l_163_;
        ulong l_164_ = l_162_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_164_;
        uint l_165_ = a_38_.inner[0];
        ulong l_166_ = static_cast<ulong>(l_165_);
        uint l_167_ = a_31_.inner[2];
        ulong l_168_ = static_cast<ulong>(l_167_);
        ulong l_169_ = l_166_ * l_168_;
        uint l_170_ = a_142_.inner[2];
        ulong l_171_ = static_cast<ulong>(l_170_);
        ulong l_172_ = l_169_ + l_171_;
        ulong _e395 = l_mut_39_;
        ulong l_173_ = l_172_ + _e395;
        uint l_174_ = static_cast<uint>(as_type<ulong>(l_173_));
        a_142_.inner[2] = l_174_;
        ulong l_175_ = l_173_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_175_;
        ulong _e404 = l_mut_39_;
        uint l_176_ = static_cast<uint>(as_type<ulong>(_e404));
        a_142_.inner[3] = l_176_;
        l_mut_39_ = 0uL;
        uint l_177_ = a_38_.inner[1];
        ulong l_178_ = static_cast<ulong>(l_177_);
        uint l_179_ = a_31_.inner[0];
        ulong l_180_ = static_cast<ulong>(l_179_);
        ulong l_181_ = l_178_ * l_180_;
        uint l_182_ = a_142_.inner[1];
        ulong l_183_ = static_cast<ulong>(l_182_);
        ulong l_184_ = l_181_ + l_183_;
        ulong _e420 = l_mut_39_;
        ulong l_185_ = l_184_ + _e420;
        uint l_186_ = static_cast<uint>(as_type<ulong>(l_185_));
        a_142_.inner[1] = l_186_;
        ulong l_187_ = l_185_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_187_;
        uint l_188_ = a_38_.inner[1];
        ulong l_189_ = static_cast<ulong>(l_188_);
        uint l_190_ = a_31_.inner[1];
        ulong l_191_ = static_cast<ulong>(l_190_);
        ulong l_192_ = l_189_ * l_191_;
        uint l_193_ = a_142_.inner[2];
        ulong l_194_ = static_cast<ulong>(l_193_);
        ulong l_195_ = l_192_ + l_194_;
        ulong _e440 = l_mut_39_;
        ulong l_196_ = l_195_ + _e440;
        uint l_197_ = static_cast<uint>(as_type<ulong>(l_196_));
        a_142_.inner[2] = l_197_;
        ulong l_198_ = l_196_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_198_;
        uint l_199_ = a_38_.inner[1];
        ulong l_200_ = static_cast<ulong>(l_199_);
        uint l_201_ = a_31_.inner[2];
        ulong l_202_ = static_cast<ulong>(l_201_);
        ulong l_203_ = l_200_ * l_202_;
        uint l_204_ = a_142_.inner[3];
        ulong l_205_ = static_cast<ulong>(l_204_);
        ulong l_206_ = l_203_ + l_205_;
        ulong _e460 = l_mut_39_;
        ulong l_207_ = l_206_ + _e460;
        uint l_208_ = static_cast<uint>(as_type<ulong>(l_207_));
        a_142_.inner[3] = l_208_;
        ulong l_209_ = l_207_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_209_;
        ulong _e469 = l_mut_39_;
        uint l_210_ = static_cast<uint>(as_type<ulong>(_e469));
        a_142_.inner[4] = l_210_;
        l_mut_39_ = 0uL;
        uint l_211_ = a_38_.inner[2];
        ulong l_212_ = static_cast<ulong>(l_211_);
        uint l_213_ = a_31_.inner[0];
        ulong l_214_ = static_cast<ulong>(l_213_);
        ulong l_215_ = l_212_ * l_214_;
        uint l_216_ = a_142_.inner[2];
        ulong l_217_ = static_cast<ulong>(l_216_);
        ulong l_218_ = l_215_ + l_217_;
        ulong _e485 = l_mut_39_;
        ulong l_219_ = l_218_ + _e485;
        uint l_220_ = static_cast<uint>(as_type<ulong>(l_219_));
        a_142_.inner[2] = l_220_;
        ulong l_221_ = l_219_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_221_;
        uint l_222_ = a_38_.inner[2];
        ulong l_223_ = static_cast<ulong>(l_222_);
        uint l_224_ = a_31_.inner[1];
        ulong l_225_ = static_cast<ulong>(l_224_);
        ulong l_226_ = l_223_ * l_225_;
        uint l_227_ = a_142_.inner[3];
        ulong l_228_ = static_cast<ulong>(l_227_);
        ulong l_229_ = l_226_ + l_228_;
        ulong _e505 = l_mut_39_;
        ulong l_230_ = l_229_ + _e505;
        uint l_231_ = static_cast<uint>(as_type<ulong>(l_230_));
        a_142_.inner[3] = l_231_;
        ulong l_232_ = l_230_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_232_;
        uint l_233_ = a_38_.inner[2];
        ulong l_234_ = static_cast<ulong>(l_233_);
        uint l_235_ = a_31_.inner[2];
        ulong l_236_ = static_cast<ulong>(l_235_);
        ulong l_237_ = l_234_ * l_236_;
        uint l_238_ = a_142_.inner[4];
        ulong l_239_ = static_cast<ulong>(l_238_);
        ulong l_240_ = l_237_ + l_239_;
        ulong _e525 = l_mut_39_;
        ulong l_241_ = l_240_ + _e525;
        uint l_242_ = static_cast<uint>(as_type<ulong>(l_241_));
        a_142_.inner[4] = l_242_;
        ulong l_243_ = l_241_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_243_;
        ulong _e534 = l_mut_39_;
        uint l_244_ = static_cast<uint>(as_type<ulong>(_e534));
        a_142_.inner[5] = l_244_;
        l_mut_39_ = 0uL;
        uint l_245_ = a_38_.inner[3];
        ulong l_246_ = static_cast<ulong>(l_245_);
        uint l_247_ = a_31_.inner[0];
        ulong l_248_ = static_cast<ulong>(l_247_);
        ulong l_249_ = l_246_ * l_248_;
        uint l_250_ = a_142_.inner[3];
        ulong l_251_ = static_cast<ulong>(l_250_);
        ulong l_252_ = l_249_ + l_251_;
        ulong _e550 = l_mut_39_;
        ulong l_253_ = l_252_ + _e550;
        uint l_254_ = static_cast<uint>(as_type<ulong>(l_253_));
        a_142_.inner[3] = l_254_;
        ulong l_255_ = l_253_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_255_;
        uint l_256_ = a_38_.inner[3];
        ulong l_257_ = static_cast<ulong>(l_256_);
        uint l_258_ = a_31_.inner[1];
        ulong l_259_ = static_cast<ulong>(l_258_);
        ulong l_260_ = l_257_ * l_259_;
        uint l_261_ = a_142_.inner[4];
        ulong l_262_ = static_cast<ulong>(l_261_);
        ulong l_263_ = l_260_ + l_262_;
        ulong _e570 = l_mut_39_;
        ulong l_264_ = l_263_ + _e570;
        uint l_265_ = static_cast<uint>(as_type<ulong>(l_264_));
        a_142_.inner[4] = l_265_;
        ulong l_266_ = l_264_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_266_;
        uint l_267_ = a_38_.inner[3];
        ulong l_268_ = static_cast<ulong>(l_267_);
        uint l_269_ = a_31_.inner[2];
        ulong l_270_ = static_cast<ulong>(l_269_);
        ulong l_271_ = l_268_ * l_270_;
        uint l_272_ = a_142_.inner[5];
        ulong l_273_ = static_cast<ulong>(l_272_);
        ulong l_274_ = l_271_ + l_273_;
        ulong _e590 = l_mut_39_;
        ulong l_275_ = l_274_ + _e590;
        uint l_276_ = static_cast<uint>(as_type<ulong>(l_275_));
        a_142_.inner[5] = l_276_;
        ulong l_277_ = l_275_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_277_;
        ulong _e599 = l_mut_39_;
        uint l_278_ = static_cast<uint>(as_type<ulong>(_e599));
        a_142_.inner[6] = l_278_;
        l_mut_39_ = 0uL;
        uint l_279_ = a_38_.inner[4];
        ulong l_280_ = static_cast<ulong>(l_279_);
        uint l_281_ = a_31_.inner[0];
        ulong l_282_ = static_cast<ulong>(l_281_);
        ulong l_283_ = l_280_ * l_282_;
        uint l_284_ = a_142_.inner[4];
        ulong l_285_ = static_cast<ulong>(l_284_);
        ulong l_286_ = l_283_ + l_285_;
        ulong _e615 = l_mut_39_;
        ulong l_287_ = l_286_ + _e615;
        uint l_288_ = static_cast<uint>(as_type<ulong>(l_287_));
        a_142_.inner[4] = l_288_;
        ulong l_289_ = l_287_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_289_;
        uint l_290_ = a_38_.inner[4];
        ulong l_291_ = static_cast<ulong>(l_290_);
        uint l_292_ = a_31_.inner[1];
        ulong l_293_ = static_cast<ulong>(l_292_);
        ulong l_294_ = l_291_ * l_293_;
        uint l_295_ = a_142_.inner[5];
        ulong l_296_ = static_cast<ulong>(l_295_);
        ulong l_297_ = l_294_ + l_296_;
        ulong _e635 = l_mut_39_;
        ulong l_298_ = l_297_ + _e635;
        uint l_299_ = static_cast<uint>(as_type<ulong>(l_298_));
        a_142_.inner[5] = l_299_;
        ulong l_300_ = l_298_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_300_;
        uint l_301_ = a_38_.inner[4];
        ulong l_302_ = static_cast<ulong>(l_301_);
        uint l_303_ = a_31_.inner[2];
        ulong l_304_ = static_cast<ulong>(l_303_);
        ulong l_305_ = l_302_ * l_304_;
        uint l_306_ = a_142_.inner[6];
        ulong l_307_ = static_cast<ulong>(l_306_);
        ulong l_308_ = l_305_ + l_307_;
        ulong _e655 = l_mut_39_;
        ulong l_309_ = l_308_ + _e655;
        uint l_310_ = static_cast<uint>(as_type<ulong>(l_309_));
        a_142_.inner[6] = l_310_;
        ulong l_311_ = l_309_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_311_;
        ulong _e664 = l_mut_39_;
        uint l_312_ = static_cast<uint>(as_type<ulong>(_e664));
        a_142_.inner[7] = l_312_;
        l_mut_39_ = 0uL;
        uint l_313_ = a_38_.inner[5];
        ulong l_314_ = static_cast<ulong>(l_313_);
        uint l_315_ = a_31_.inner[0];
        ulong l_316_ = static_cast<ulong>(l_315_);
        ulong l_317_ = l_314_ * l_316_;
        uint l_318_ = a_142_.inner[5];
        ulong l_319_ = static_cast<ulong>(l_318_);
        ulong l_320_ = l_317_ + l_319_;
        ulong _e680 = l_mut_39_;
        ulong l_321_ = l_320_ + _e680;
        uint l_322_ = static_cast<uint>(as_type<ulong>(l_321_));
        a_142_.inner[5] = l_322_;
        ulong l_323_ = l_321_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_323_;
        uint l_324_ = a_38_.inner[5];
        ulong l_325_ = static_cast<ulong>(l_324_);
        uint l_326_ = a_31_.inner[1];
        ulong l_327_ = static_cast<ulong>(l_326_);
        ulong l_328_ = l_325_ * l_327_;
        uint l_329_ = a_142_.inner[6];
        ulong l_330_ = static_cast<ulong>(l_329_);
        ulong l_331_ = l_328_ + l_330_;
        ulong _e700 = l_mut_39_;
        ulong l_332_ = l_331_ + _e700;
        uint l_333_ = static_cast<uint>(as_type<ulong>(l_332_));
        a_142_.inner[6] = l_333_;
        ulong l_334_ = l_332_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_334_;
        uint l_335_ = a_38_.inner[5];
        ulong l_336_ = static_cast<ulong>(l_335_);
        uint l_337_ = a_31_.inner[2];
        ulong l_338_ = static_cast<ulong>(l_337_);
        ulong l_339_ = l_336_ * l_338_;
        uint l_340_ = a_142_.inner[7];
        ulong l_341_ = static_cast<ulong>(l_340_);
        ulong l_342_ = l_339_ + l_341_;
        ulong _e720 = l_mut_39_;
        ulong l_343_ = l_342_ + _e720;
        uint l_344_ = static_cast<uint>(as_type<ulong>(l_343_));
        a_142_.inner[7] = l_344_;
        ulong l_345_ = l_343_ >> static_cast<uint>(as_type<ulong>(32uL));
        l_mut_39_ = l_345_;
        ulong _e729 = l_mut_39_;
        uint l_346_ = static_cast<uint>(as_type<ulong>(_e729));
        a_142_.inner[8] = l_346_;
        l_mut_39_ = 0uL;
        l_mut_347_ = 0uL;
        l_mut_348_ = 0u;
        uint2 loop_bound_2 = uint2(4294967295u);
        while(true) {
            if (metal::all(loop_bound_2 == uint2(0u))) { break; }
            loop_bound_2 -= uint2(loop_bound_2.y == 0u, 1u);
            uint _e736 = l_mut_348_;
            bool l_349_ = _e736 < 2u;
            bool l_350_ = !(l_349_);
            if (l_350_) {
                break;
            }
            uint _e740 = l_mut_348_;
            bool l_351_ = _e740 == 0u;
            if (l_351_) {
                uint l_352_ = l_23_ + 0u;
                uint l_353_ = a_38_.inner[0];
                shared_memory_22_.inner[l_352_] = l_353_;
                uint l_354_ = l_23_ + 1u;
                uint l_355_ = a_38_.inner[1];
                shared_memory_22_.inner[l_354_] = l_355_;
                uint l_356_ = l_23_ + 2u;
                uint l_357_ = a_38_.inner[2];
                shared_memory_22_.inner[l_356_] = l_357_;
                uint l_358_ = l_23_ + 3u;
                uint l_359_ = a_38_.inner[3];
                shared_memory_22_.inner[l_358_] = l_359_;
                uint l_360_ = l_23_ + 4u;
                uint l_361_ = a_38_.inner[4];
                shared_memory_22_.inner[l_360_] = l_361_;
                uint l_362_ = l_23_ + 5u;
                uint l_363_ = a_38_.inner[5];
                shared_memory_22_.inner[l_362_] = l_363_;
                uint l_364_ = l_23_ + 6u;
                shared_memory_22_.inner[l_364_] = 0u;
                uint l_365_ = l_23_ + 7u;
                shared_memory_22_.inner[l_365_] = 0u;
                uint l_366_ = l_23_ + 8u;
                shared_memory_22_.inner[l_366_] = 0u;
            } else {
                uint l_367_ = l_23_ + 0u;
                uint l_368_ = a_142_.inner[0];
                shared_memory_22_.inner[l_367_] = l_368_;
                uint l_369_ = l_23_ + 1u;
                uint l_370_ = a_142_.inner[1];
                shared_memory_22_.inner[l_369_] = l_370_;
                uint l_371_ = l_23_ + 2u;
                uint l_372_ = a_142_.inner[2];
                shared_memory_22_.inner[l_371_] = l_372_;
                uint l_373_ = l_23_ + 3u;
                uint l_374_ = a_142_.inner[3];
                shared_memory_22_.inner[l_373_] = l_374_;
                uint l_375_ = l_23_ + 4u;
                uint l_376_ = a_142_.inner[4];
                shared_memory_22_.inner[l_375_] = l_376_;
                uint l_377_ = l_23_ + 5u;
                uint l_378_ = a_142_.inner[5];
                shared_memory_22_.inner[l_377_] = l_378_;
                uint l_379_ = l_23_ + 6u;
                uint l_380_ = a_142_.inner[6];
                shared_memory_22_.inner[l_379_] = l_380_;
                uint l_381_ = l_23_ + 7u;
                uint l_382_ = a_142_.inner[7];
                shared_memory_22_.inner[l_381_] = l_382_;
                uint l_383_ = l_23_ + 8u;
                uint l_384_ = a_142_.inner[8];
                shared_memory_22_.inner[l_383_] = l_384_;
            }
            l_mut_385_ = 8;
            uint2 loop_bound_3 = uint2(4294967295u);
            while(true) {
                if (metal::all(loop_bound_3 == uint2(0u))) { break; }
                loop_bound_3 -= uint2(loop_bound_3.y == 0u, 1u);
                int _e849 = l_mut_385_;
                bool l_386_ = _e849 >= 0;
                bool l_387_ = !(l_386_);
                if (l_387_) {
                    break;
                }
                int _e853 = l_mut_385_;
                uint l_388_ = static_cast<uint>(_e853);
                uint l_389_ = l_23_ + l_388_;
                uint l_390_ = shared_memory_22_.inner[l_389_];
                bool l_391_ = l_390_ != 0u;
                if (l_391_) {
                    break;
                }
                int _e861 = l_mut_385_;
                l_mut_385_ = as_type<int>(as_type<uint>(_e861) - as_type<uint>(1));
            }
            uint2 loop_bound_4 = uint2(4294967295u);
            while(true) {
                if (metal::all(loop_bound_4 == uint2(0u))) { break; }
                loop_bound_4 -= uint2(loop_bound_4.y == 0u, 1u);
                int _e864 = l_mut_385_;
                bool l_392_ = _e864 >= 0;
                bool l_393_ = !(l_392_);
                if (l_393_) {
                    break;
                }
                l_mut_394_ = 0u;
                int _e869 = l_mut_385_;
                l_mut_395_ = _e869;
                uint2 loop_bound_5 = uint2(4294967295u);
                while(true) {
                    if (metal::all(loop_bound_5 == uint2(0u))) { break; }
                    loop_bound_5 -= uint2(loop_bound_5.y == 0u, 1u);
                    int _e870 = l_mut_395_;
                    bool l_396_ = _e870 >= 0;
                    bool l_397_ = !(l_396_);
                    if (l_397_) {
                        break;
                    }
                    int _e874 = l_mut_395_;
                    uint l_398_ = static_cast<uint>(_e874);
                    uint l_399_ = l_23_ + l_398_;
                    uint l_400_ = shared_memory_22_.inner[l_399_];
                    uint _e880 = l_mut_394_;
                    uint l_401_ = _e880 << 16u;
                    uint l_402_ = l_400_ >> 16u;
                    uint l_403_ = l_401_ | l_402_;
                    uint l_404_ = naga_div(l_403_, 3364u);
                    uint l_405_ = l_404_ * 3364u;
                    uint l_406_ = l_403_ - l_405_;
                    uint l_407_ = l_406_ << 16u;
                    uint l_408_ = l_400_ & 65535u;
                    uint l_409_ = l_407_ | l_408_;
                    uint l_410_ = naga_div(l_409_, 3364u);
                    uint l_411_ = l_410_ * 3364u;
                    uint l_412_ = l_409_ - l_411_;
                    l_mut_394_ = l_412_;
                    int _e901 = l_mut_395_;
                    uint l_413_ = static_cast<uint>(_e901);
                    uint l_414_ = l_23_ + l_413_;
                    uint l_415_ = l_404_ << 16u;
                    uint l_416_ = l_415_ | l_410_;
                    shared_memory_22_.inner[l_414_] = l_416_;
                    int _e909 = l_mut_395_;
                    l_mut_395_ = as_type<int>(as_type<uint>(_e909) - as_type<uint>(1));
                }
                uint2 loop_bound_6 = uint2(4294967295u);
                while(true) {
                    if (metal::all(loop_bound_6 == uint2(0u))) { break; }
                    loop_bound_6 -= uint2(loop_bound_6.y == 0u, 1u);
                    int _e912 = l_mut_385_;
                    bool l_417_ = _e912 >= 0;
                    bool l_418_ = !(l_417_);
                    if (l_418_) {
                        break;
                    }
                    int _e916 = l_mut_385_;
                    uint l_419_ = static_cast<uint>(_e916);
                    uint l_420_ = l_23_ + l_419_;
                    uint l_421_ = shared_memory_22_.inner[l_420_];
                    bool l_422_ = l_421_ != 0u;
                    if (l_422_) {
                        break;
                    }
                    int _e924 = l_mut_385_;
                    l_mut_385_ = as_type<int>(as_type<uint>(_e924) - as_type<uint>(1));
                }
                uint _e927 = l_mut_394_;
                l_mut_423_ = _e927;
                int _e928 = l_mut_385_;
                bool l_424_ = _e928 >= 0;
                if (l_424_) {
                    uint _e931 = l_mut_423_;
                    uint l_425_ = naga_div(_e931, 58u);
                    uint l_426_ = l_425_ * 58u;
                    uint _e936 = l_mut_423_;
                    uint l_427_ = _e936 - l_426_;
                    l_mut_423_ = l_425_;
                    ulong l_428_ = static_cast<ulong>(l_427_);
                    ulong l_429_ = 1uL << static_cast<uint>(as_type<ulong>(l_428_));
                    ulong _e943 = l_mut_39_;
                    l_mut_39_ = _e943 | l_429_;
                    uint _e945 = l_mut_423_;
                    uint l_430_ = naga_div(_e945, 58u);
                    uint l_431_ = l_430_ * 58u;
                    uint _e950 = l_mut_423_;
                    uint l_432_ = _e950 - l_431_;
                    l_mut_423_ = l_430_;
                    ulong l_433_ = static_cast<ulong>(l_432_);
                    ulong l_434_ = 1uL << static_cast<uint>(as_type<ulong>(l_433_));
                    ulong _e957 = l_mut_39_;
                    l_mut_39_ = _e957 | l_434_;
                } else {
                    uint2 loop_bound_7 = uint2(4294967295u);
                    while(true) {
                        if (metal::all(loop_bound_7 == uint2(0u))) { break; }
                        loop_bound_7 -= uint2(loop_bound_7.y == 0u, 1u);
                        uint _e959 = l_mut_423_;
                        bool l_435_ = _e959 != 0u;
                        bool l_436_ = !(l_435_);
                        if (l_436_) {
                            break;
                        }
                        uint _e963 = l_mut_423_;
                        uint l_437_ = naga_div(_e963, 58u);
                        uint l_438_ = l_437_ * 58u;
                        uint _e968 = l_mut_423_;
                        uint l_439_ = _e968 - l_438_;
                        l_mut_423_ = l_437_;
                        ulong l_440_ = static_cast<ulong>(l_439_);
                        ulong l_441_ = 1uL << static_cast<uint>(as_type<ulong>(l_440_));
                        ulong _e975 = l_mut_39_;
                        l_mut_39_ = _e975 | l_441_;
                    }
                }
            }
            uint _e977 = l_mut_348_;
            l_mut_348_ = _e977 + 1u;
        }
        ulong _e980 = l_mut_39_;
        uint l_442_ = static_cast<uint>(as_type<ulong>(_e980));
        uint l_443_ = metal::popcount(l_442_);
        ulong _e984 = l_mut_39_;
        ulong l_444_ = _e984 >> static_cast<uint>(as_type<ulong>(32uL));
        uint l_445_ = static_cast<uint>(as_type<ulong>(l_444_));
        uint l_446_ = metal::popcount(l_445_);
        uint l_447_ = l_443_ + l_446_;
        l_mut_423_ = l_447_;
        uint l_448_ = l_18_ * 59u;
        uint _e995 = l_mut_423_;
        uint l_449_ = l_448_ + _e995;
        uint _e1000 = metal::atomic_fetch_add_explicit(&shared_memory_0_.inner[l_449_], 1u, metal::memory_order_relaxed);
        uint _e1001 = l_mut_423_;
        bool l_452_ = _e1001 > 52u;
        if (l_452_) {
            uint _e1007 = metal::atomic_fetch_add_explicit(&buffer_1_global[0], 1u, metal::memory_order_relaxed);
            uint _e1011 = info.scalars_u32_.inner[6];
            bool l_455_ = _e1007 < _e1011;
            if (l_455_) {
                uint l_456_ = 5u * _e1007;
                uint l_457_ = static_cast<uint>(as_type<ulong>(l_28_));
                buffer_2_global[l_456_] = l_457_;
                uint l_458_ = l_456_ + 1u;
                ulong l_459_ = l_28_ >> static_cast<uint>(as_type<ulong>(32uL));
                uint l_460_ = static_cast<uint>(as_type<ulong>(l_459_));
                buffer_2_global[l_458_] = l_460_;
                uint l_461_ = l_456_ + 2u;
                ulong _e1031 = l_mut_29_;
                uint l_462_ = static_cast<uint>(as_type<ulong>(_e1031));
                buffer_2_global[l_461_] = l_462_;
                uint l_463_ = l_456_ + 3u;
                ulong _e1038 = l_mut_29_;
                ulong l_464_ = _e1038 >> static_cast<uint>(as_type<ulong>(32uL));
                uint l_465_ = static_cast<uint>(as_type<ulong>(l_464_));
                buffer_2_global[l_463_] = l_465_;
                uint l_466_ = l_456_ + 4u;
                uint _e1051 = l_mut_423_;
                buffer_2_global[l_466_] = _e1051;
            }
        }
        ulong _e1052 = l_mut_25_;
        l_mut_25_ = _e1052 + l_21_;
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    l_mut_423_ = local_invocation_id.x;
    uint2 loop_bound_8 = uint2(4294967295u);
    while(true) {
        if (metal::all(loop_bound_8 == uint2(0u))) { break; }
        loop_bound_8 -= uint2(loop_bound_8.y == 0u, 1u);
        uint _e1055 = l_mut_423_;
        bool l_467_ = _e1055 < 59u;
        bool l_468_ = !(l_467_);
        if (l_468_) {
            break;
        }
        l_mut_394_ = 0u;
        uint _e1061 = l_mut_423_;
        uint l_469_ = 0u + _e1061;
        uint l_471_ = metal::atomic_load_explicit(&shared_memory_0_.inner[l_469_], metal::memory_order_relaxed);
        uint _e1066 = l_mut_394_;
        l_mut_394_ = _e1066 + l_471_;
        uint _e1069 = l_mut_423_;
        uint l_472_ = 59u + _e1069;
        uint l_474_ = metal::atomic_load_explicit(&shared_memory_0_.inner[l_472_], metal::memory_order_relaxed);
        uint _e1074 = l_mut_394_;
        l_mut_394_ = _e1074 + l_474_;
        uint _e1077 = l_mut_423_;
        uint l_475_ = 118u + _e1077;
        uint l_477_ = metal::atomic_load_explicit(&shared_memory_0_.inner[l_475_], metal::memory_order_relaxed);
        uint _e1082 = l_mut_394_;
        l_mut_394_ = _e1082 + l_477_;
        uint _e1085 = l_mut_423_;
        uint l_478_ = 177u + _e1085;
        uint l_480_ = metal::atomic_load_explicit(&shared_memory_0_.inner[l_478_], metal::memory_order_relaxed);
        uint _e1090 = l_mut_394_;
        l_mut_394_ = _e1090 + l_480_;
        uint _e1092 = l_mut_394_;
        bool l_481_ = _e1092 != 0u;
        if (l_481_) {
            uint _e1096 = l_mut_423_;
            uint _e1098 = l_mut_394_;
            uint _e1099 = metal::atomic_fetch_add_explicit(&buffer_0_global[_e1096], _e1098, metal::memory_order_relaxed);
        }
        uint _e1100 = l_mut_423_;
        l_mut_423_ = _e1100 + WORKGROUP_SIZE_X;
    }
    return;
}
