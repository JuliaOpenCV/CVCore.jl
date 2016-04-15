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
    ex = Expr(:macrocall, symbol("@icxx_str"), string(name, ";"))
    @eval global const $name = $ex
end


#=
for name in [
    :ACCESS_READ,
    :ACCESS_WRITE,
    :ACCESS_RW,
    :ACCESS_MASK,
    :ACCESS_FAST,
    ]
    ex = Expr(:macrocall, symbol("@icxx_str"), string("cv::", name, ";"))
    @eval global $name = $ex
end

Cxx.jl has type translation bug? The above code doesn't work as expected:
julia> icxx"cv::ACCESS_READ;"
0x01000000

julia> icxx"std::cout << cv::ACCESS_READ << std::endl;";
16777216
=#

const ACCESS_READ   = 1<<24
const ACCESS_WRITE  = 1<<25
const ACCESS_RW     = 3<<24
const ACCESS_MASK   = ACCESS_RW
const ACCESS_FAST   = 1<<26
