# All constants defined in the file are exported

for name in [
    ### Matrix types from cvdef.h ###
    :CV_CN_MAX,
    :CV_CN_SHIFT,
    :CV_DEPTH_MAX,

    :CV_8U,
    :CV_8S,
    :CV_16U,
    :CV_16S,
    :CV_32S,
    :CV_32F,
    :CV_64F,
    :CV_USRTYPE1,

    :CV_MAT_DEPTH_MASK,

    :CV_8UC1,
    :CV_8UC2,
    :CV_8UC3,
    :CV_8UC4,

    :CV_16UC1,
    :CV_16UC2,
    :CV_16UC3,
    :CV_16UC4,

    :CV_16SC1,
    :CV_16SC2,
    :CV_16SC3,
    :CV_16SC4,

    :CV_32SC1,
    :CV_32SC2,
    :CV_32SC3,
    :CV_32SC4,

    :CV_32FC1,
    :CV_32FC2,
    :CV_32FC3,
    :CV_32FC4,

    :CV_64FC1,
    :CV_64FC2,
    :CV_64FC3,
    :CV_64FC4,

    :CV_MAT_CN_MASK,
    :CV_MAT_TYPE_MASK,
    :CV_MAT_CONT_FLAG_SHIFT,
    :CV_MAT_CONT_FLAG,
    :CV_SUBMAT_FLAG_SHIFT,
    :CV_SUBMAT_FLAG,
    ]
    ex = Expr(:macrocall, Symbol("@icxx_str"), string(name, ";"))
    @eval begin
        global const $name = $ex
        export $name
    end
end

const BorderTypes = Cxx.CppEnum{Symbol("cv::BorderTypes"),UInt32}
const CmpTypes = Cxx.CppEnum{Symbol("cv::CmpTypes"),UInt32}
const DecompTypes = Cxx.CppEnum{Symbol("cv::DecompTypes"),UInt32}
const DftFlags = Cxx.CppEnum{Symbol("cv::DftFlags"),UInt32}
const GemmFlags = Cxx.CppEnum{Symbol("cv::GemmFlags"),UInt32}

for name in [
    :ACCESS_READ,
    :ACCESS_WRITE,
    :ACCESS_RW,
    :ACCESS_MASK,
    :ACCESS_FAST,

    :BORDER_CONSTANT,
    :BORDER_REPLICATE,
    :BORDER_REFLECT,
    :BORDER_WRAP,
    :BORDER_REFLECT_101,
    :BORDER_TRANSPARENT,
    :BORDER_REFLECT101,
    :BORDER_DEFAULT,
    :BORDER_ISOLATED,

    :CMP_EQ,
    :CMP_GT,
    :CMP_GE,
    :CMP_LT,
    :CMP_LE,
    :CMP_NE,

    :DECOMP_LU,
    :DECOMP_SVD,
    :DECOMP_EIG,
    :DECOMP_CHOLESKY,
    :DECOMP_QR,
    :DECOMP_NORMAL,

    :DFT_INVERSE,
    :DFT_SCALE,
    :DFT_ROWS,
    :DFT_COMPLEX_OUTPUT,
    :DFT_REAL_OUTPUT,
    :DCT_INVERSE,
    :DCT_ROWS,

    :GEMM_1_T,
    :GEMM_2_T,
    :GEMM_3_T,

    :NORM_INF,
    :NORM_L1,
    :NORM_L2,
    :NORM_L2SQR,
    :NORM_HAMMING,
    :NORM_HAMMING2,
    :NORM_TYPE_MASK,
    :NORM_RELATIVE,
    :NORM_MINMAX,
    ]
    ex = Expr(:macrocall, Symbol("@icxx_str"), string("cv::", name, ";"))
    @eval global const $name = $ex
end
