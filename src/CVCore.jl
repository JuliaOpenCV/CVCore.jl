"""
Core functionality

## Basic usage

The primary export of the package is `Mat{T,N}`, which is the Julia type for
`cv::Mat`. `Mat{T,N}` is designed to be a subtype of `AbstractArray{T,N}`. It
has element type (`T`) and dimension (`N`) as type parameters, whereas
`cv::Mat` doesn't. Note that matrix construction interface is different between
Julia and C++. `cv::Mat(3,3,CV_8U)` in C++ can be translated in Julia as
`Mat{UInt8}(3,3)`.

### Create uninitialized matrix:

```julia
using CVCore

julia> A = Mat{Float64}(3,3)
3×3 CVCore.Mat{Float64,2}:
   3.39519e-313  4.94066e-324   2.122e-314
 NaN             1.72723e-77   -2.32036e77
   1.97626e-323  0.0            0.0
```

### Create matrix filled with Scalar (`cv::Scalar`)

```julia
julia> A = Mat{Float64}(3,3,Scalar(1))
3×3 CVCore.Mat{Float64,2}:
 1.0  1.0  1.0
 1.0  1.0  1.0
 1.0  1.0  1.0
```

### Matirx operations

```julia
julia> A * A
CVCore.MatExpr{Float64,2}
3×3 CVCore.Mat{Float64,2}:
 3.0  3.0  3.0
 3.0  3.0  3.0
 3.0  3.0  3.0

julia> A + A
CVCore.MatExpr{Float64,2}
3×3 CVCore.Mat{Float64,2}:
 2.0  2.0  2.0
 2.0  2.0  2.0
 2.0  2.0  2.0

julia> A - A
CVCore.MatExpr{Float64,2}
3×3 CVCore.Mat{Float64,2}:
 0.0  0.0  0.0
 0.0  0.0  0.0
 0.0  0.0  0.0
```

### Create multi-channel matrix

```julia
julia> A = Mat{Float64}(3,3,3,Scalar(1,2,3))
3×3×3 CVCore.Mat{Float64,3}:
[:, :, 1] =
 1.0  1.0  1.0
 1.0  1.0  1.0
 1.0  1.0  1.0

[:, :, 2] =
 2.0  2.0  2.0
 2.0  2.0  2.0
 2.0  2.0  2.0

[:, :, 3] =
 3.0  3.0  3.0
 3.0  3.0  3.0
 3.0  3.0  3.0
```

### Conversion between `Mat{T,N}` and `Array{T,N}`

```julia
julia> B = Array(A)
3×3 Array{Float64,2}:
 1.0  1.0  1.0
 1.0  1.0  1.0
 1.0  1.0  1.0

julia> C = Mat(B)
3×3 CVCore.Mat{Float64,2}:
 1.0  1.0  1.0
 1.0  1.0  1.0
 1.0  1.0  1.0
```

Note that `Mat(B)` where `B` is an array shares the underlying data.

"""
module CVCore

export AbstractCvMat, MatExpr, Mat, UMat, depth, channels, flags, dims, rows,
    cols, clone, total, isContinuous, elemSize, Scalar, TermCriteria,
    convertScaleAbs!, convertScaleAbs, addWeighted!, addWeighted

#=
Naming convention:
  1. Cxx types should have prefix cv: e.g. cv::Mat -> cvMat
  2. Julia types should not have prefix cv: e.g. cv::Mat -> Mat
=#

using LibOpenCV
using Cxx

"""
Returns a refrence of the interal structure
"""
function handle end

include("macros.jl")
include("const.jl")

import Base: call, convert, eltype, size

### Cxx types ###

cvScalar_{T} =  cxxt"cv::Scalar_<$T>"

const cvScalar = cxxt"cv::Scalar"
cvScalar(v) = icxx"return cv::Scalar($v);"

const AbstractCvScalar = Union{cvScalar, cvScalar_}

cvPoint_{T} =  cxxt"cv::Point_<$T>"
cvPoint_{T}(x, y) where {T} = icxx"cv::Point_<$T>($x, $y);"
eltype(p::cvPoint_{T}) where {T} = T

cvPoint3_{T} =  cxxt"cv::Point3_<$T>"
cvPoint3_{T}(x, y, z) where {T} = icxx"cv::Point3_<$T>($x, $y, $z);"
eltype(p::cvPoint3_{T}) where {T} = T

const cvPoint = cxxt"cv::Point"
cvPoint(x, y) = icxx"cv::Point($x, $y);"

const AbstractCvPoint = Union{cvPoint, cvPoint_}

cvSize_{T} =  cxxt"cv::Size_<$T>"
cvSize_{T}(x, y) where {T} = icxx"cv::Size_<$T>($x, $y);"
eltype(s::cvSize_{T}) where {T} = T

const cvSize = cxxt"cv::Size"
cvSize(x, y) = icxx"cv::Size($x, $y);"

const AbstractCvSize = Union{cvSize, cvSize_}

height(s::AbstractCvSize) = Int(icxx"$s.height;")
width(s::AbstractCvSize) = Int(icxx"$s.width;")
area(s::AbstractCvSize) = Int(icxx"$s.area();")

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
const Scalar = cvScalar_
Scalar{T}(s1=01,s2=0,s3=0,s4=0) where {T} =
    icxx"return cv::Scalar_<$T>($s1,$s2,$s3,$s4);"
Scalar(s1=0,s2=0,s3=0,s4=0) = Scalar{Float64}(s1,s2,s3,s4)
eltype(s::Scalar{T}) where {T} = T

### cv::TermCriteria ###

const TERM_CRITERIA_COUNT = icxx"cv::TermCriteria::COUNT;"
const TERM_CRITERIA_MAX_ITER = icxx"cv::TermCriteria::MAX_ITER;"
const TERM_CRITERIA_EPS = icxx"cv::TermCriteria::EPS;"

const TermCriteria = cxxt"cv::TermCriteria"
TermCriteria(typ, maxCount, epsilon) =
    icxx"cv::TermCriteria($typ, $maxCount, $epsilon);"

include("mat.jl")

@gencxxf(convertScaleAbs!(src::AbstractCvMat, dst::AbstractCvMat,
    alpha=1,beta=0), "cv::convertScaleAbs")
function convertScaleAbs(src::AbstractCvMat, alpha=1, beta=0)
    dst = similar_empty(src)
    convertScaleAbs!(src, dst, alpha, beta)
    dst
end

@gencxxf(addWeighted!(src1::AbstractCvMat, alpha, src2::AbstractCvMat, beta,
    gamma, dst::AbstractCvMat, dtype=-1), "cv::addWeighted")
function addWeighted(src1::AbstractCvMat, alpha, src2::AbstractCvMat, beta,
    gamma, dtype=-1)
    dst = similar_empty(src)
    addWeighted!(src1, alpha, src2, beta, gamma, dst, dtype)
    dst
end

end # module
