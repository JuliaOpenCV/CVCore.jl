module CVCore

export AbstractCvMat, MatExpr, Mat, UMat, depth, channels, flags, dims, rows,
    cols, clone, total, isContinuous, elemSize, Scalar, TermCriteria

#=
Naming convention:
  1. Cxx types should have prefix cv: e.g. cv::Mat -> cvMat
  2. Julia types should not have prefix cv: e.g. cv::Mat -> Mat
=#

using LibOpenCV
using Cxx

include("const.jl")

import Base: call, convert, eltype, size

### Cxx types ###

typealias cvScalar_{T} cxxt"cv::Scalar_<$T>"

const cvScalar = cxxt"cv::Scalar"
cvScalar(v) = icxx"return cv::Scalar($v);"

typealias AbstractCvScalar Union{cvScalar, cvScalar_}

typealias cvPoint_{T} cxxt"cv::Point_<$T>"
(::Type{cvPoint_{T}}){T}(x, y) = icxx"cv::Point_<$T>($x, $y);"
eltype{T}(p::cvPoint_{T}) = T

typealias cvPoint3_{T} cxxt"cv::Point3_<$T>"
(::Type{cvPoint3_{T}}){T}(x, y, z) = icxx"cv::Point3_<$T>($x, $y, $z);"
eltype{T}(p::cvPoint3_{T}) = T

typealias cvPoint cxxt"cv::Point"
cvPoint(x, y) = icxx"cv::Point($x, $y);"

typealias AbstractCvPoint Union{cvPoint, cvPoint_}

typealias cvSize_{T} cxxt"cv::Size_<$T>"
(::Type{cvSize_{T}}){T}(x, y) = icxx"cv::Size_<$T>($x, $y);"
eltype{T}(s::cvSize_{T}) = T

typealias cvSize cxxt"cv::Size"
cvSize(x, y) = icxx"cv::Size($x, $y);"

typealias AbstractCvSize Union{cvSize, cvSize_}

height(s::AbstractCvSize) = Int(@cxx s->height)
width(s::AbstractCvSize) = Int(@cxx s->width)
area(s::AbstractCvSize) = Int(@cxx s->area())

"""Determine julia type from the depth of cv::Mat
"""
function jltype(depth)
    if depth == CV_8U
        return UInt8
    elseif depth == CV_8S
        return Int8
    elseif depth == CV_16U
        return UInt16
    elseif depth == CV_16S
        return Int16
    elseif depth == CV_32S
        return Int32
    elseif depth == CV_32F
        return Float32
    elseif depth == CV_64F
        return Float64
    else
        error("This shouldn't happen")
    end
end

"""Determine cv::Mat depth from Julia type
"""
function cvdepth(T)
    if T == UInt8
        return CV_8U
    elseif T == Int8
        return CV_8S
    elseif T == UInt16
        return CV_16U
    elseif T == Int16
        return CV_16S
    elseif T == Int32
        return CV_32S
    elseif T == Float32
        return CV_32F
    elseif T == Float64
        return CV_64F
    else
        error("$T: not supported in cv::Mat")
    end
end

mat_depth(flags) = flags & CV_MAT_DEPTH_MASK
mat_channel(flags) = (flags & CV_MAT_CN_MASK) >> CV_CN_SHIFT + 1
maketype(depth, cn) = mat_depth(depth) + ((cn-1) << CV_CN_SHIFT)

### Scalar ###

# TODO: need to be subtype of cv::Vec
typealias Scalar cvScalar_
(::Type{Scalar{T}}){T}(s1=01,s2=0,s3=0,s4=0) =
    icxx"return cv::Scalar_<$T>($s1,$s2,$s3,$s4);"
(::Type{Scalar})(s1=0,s2=0,s3=0,s4=0) = Scalar{Float64}(s1,s2,s3,s4)
eltype{T}(s::Scalar{T}) = T

### cv::TermCriteria ###

const TERM_CRITERIA_COUNT = icxx"cv::TermCriteria::COUNT;"
const TERM_CRITERIA_MAX_ITER = icxx"cv::TermCriteria::MAX_ITER;"
const TERM_CRITERIA_EPS = icxx"cv::TermCriteria::EPS;"

typealias TermCriteria cxxt"cv::TermCriteria"
(::Type{TermCriteria})(typ, maxCount, epsilon) =
    icxx"cv::TermCriteria($typ, $maxCount, $epsilon);"

include("mat.jl")

end # module
