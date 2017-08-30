import Base: size, eltype, similar, convert, show, isempty

"""AbstractCvMat{T,N} represents `N`-dimentional arrays in OpenCV (cv::Mat,
cv::UMat, etc), which element type are bound to `T`.
"""
abstract type AbstractCvMat{T,N} <: AbstractArray{T,N} end

# NOTE: subtypes of AbstractCvMat should have `handle` as a member.
handle(m::AbstractCvMat) = m.handle

### Types and methods for C++ types ###

const cvMatExpr = cxxt"cv::MatExpr"
function _size(expr::cvMatExpr)
    s::cvSize = icxx"$expr.size();"
    height(s), width(s)
end
_type(m::cvMatExpr) = icxx"$m.type();"
depth(m::cvMatExpr) = mat_depth(_type(m))
channels(m::cvMatExpr) = mat_channel(_type(m))
eltype(m::cvMatExpr) = jltype(depth(m))

const cvMat = cxxt"cv::Mat"
const cvUMat = cxxt"cv::UMat"
const cvMatVariants = Union{cvMat, cvUMat}

@inline depth(m::cvMatVariants) = convert(Int, icxx"$m.depth();")
@inline channels(m::cvMatVariants) = convert(Int, icxx"$m.channels();")
@inline eltype(m::cvMatVariants) = jltype(depth(m))
@inline dims(m::cvMatVariants) = convert(Int, icxx"$m.dims;")

@inline data(m::cvMat) = icxx"$m.data;"

import Cxx: CppEnum

const UMatUsageFlags = CppEnum{Symbol("cv::UMatUsageFlags"),Int32}

const USAGE_DEFAULT = UMatUsageFlags(0)
const USAGE_ALLOCATE_HOST_MEMORY = UMatUsageFlags(1 << 0)
const USAGE_ALLOCATE_DEVICE_MEMORY = UMatUsageFlags(1 << 1)
const USAGE_ALLOCATE_SHARED_MEMORY = UMatUsageFlags(1 << 2)
const __UMAT_USAGE_FLAGS_32BIT = UMatUsageFlags(0x7fffffff)

cvUMat(usage_flags::UMatUsageFlags=USAGE_DEFAULT) = icxx"cv::UMat($usage_flags);"
cvUMat(m::cvUMat) = icxx"cv::UMat($m);"
usageFlags(m::cvUMat) = icxx"$m.usageFlags;"::UMatUsageFlags
elemSize1(m::cvUMat) = convert(Int, icxx"$m.elemSize1();")


### Methods for AbstractCvMat ###

flags(m::AbstractCvMat) = icxx"$(m.handle).flags;"
dims(m::AbstractCvMat) = icxx"$(m.handle).dims;"
rows(m::AbstractCvMat) = convert(Int, icxx"$(m.handle).rows;")
cols(m::AbstractCvMat) = convert(Int, icxx"$(m.handle).cols;")
_size(m::AbstractCvMat) = (Int(rows(m)), Int(cols(m)))

function size(m::Union{AbstractCvMat, cvMatExpr})
    cn = channels(m)
    if cn == 1
        return _size(m)
    else
        return (_size(m)..., cn)
    end
end

clone(m::AbstractCvMat) = Mat(icxx"$(m.handle).clone();")
total(m::AbstractCvMat) = convert(Int, icxx"$(m.handle).total();")
isContinuous(m::AbstractCvMat) = icxx"$(m.handle).isContinuous();"
elemSize(m::AbstractCvMat) = convert(Int, icxx"$(m.handle).elemSize();")
depth(m::AbstractCvMat) = convert(Int, icxx"$(m.handle).depth();")
channels(m::AbstractCvMat) = channels(handle(m))
empty(m::AbstractCvMat) = icxx"$(m.handle).empty();"
isempty(m::AbstractCvMat) = empty(m)


### MatExpr{T,N} ###

"""MatExpr{T,N} represents cv::MatExpr with encoded type information

`T` and `N` represents the element type and the dimension of Mat,
respectively.

TODO: should consder wherther I make this a subtype of AbstractCvMat{T,N}
"""
mutable struct MatExpr{T,N}
    handle::cvMatExpr
end

handle(m::MatExpr) = m.handle
channels(m::MatExpr) = channels(handle(m))
size(m::MatExpr) = size(handle(m))

function MatExpr(handle::cvMatExpr)
    # determin type parameters by value
    T = eltype(handle)
    N = length(size(handle))
    MatExpr{T,N}(handle)
end


"""Mat{T,N} represents cv::Mat with encoded type information

Mat{T,N} keeps cv::Mat instance with: element type `T` and dimention `N`.
Hence, in fact it behaves like cv::Mat_<T>. Note that Mat stores its
internal data in column-major order, while Julia's arrays are in row-major.

NOTE: Mat{T,N} supports multi-channel 2-dimentional matrices and
single-channel 2-dimentional matrices for now. Should be extended for
N-dimentional cases.
"""
mutable struct Mat{T,N} <: AbstractCvMat{T,N}
    handle::cvMat
end

### Constructors ###

"""Generic constructor"""
function Mat(handle::cvMat)
    # Determine dimention and element type by value and encode eit into type
    T = eltype(handle)
    cn = channels(handle)
    dims = Int(icxx"$handle.dims;")
    N = (cn == 1) ? dims : dims + 1
    Mat{T,N}(handle)
end

"""Empty mat constructor"""
function Mat{T,N}() where {T,N}
    handle = icxx"cv::Mat();"
    Mat{T,N}(handle)
end
function Mat{T}() where T
    handle = icxx"cv::Mat();"
    Mat{T,2}(handle)
end

"""Single-channel 2-dimentional mat constructor"""
function Mat{T}(rows::Int, cols::Int) where T
    typ = maketype(cvdepth(T), 1)
    handle = icxx"cv::Mat($rows, $cols, $typ);"
    Mat{T,2}(handle)
end

function Mat{T}(rows::Int, cols::Int, s::AbstractCvScalar) where T
    typ = maketype(cvdepth(T), 1)
    handle = icxx"cv::Mat($rows, $cols, $typ, $s);"
    Mat{T,2}(handle)
end

"""Multi-chanel 2-dimentional mat constructor"""
function Mat{T}(rows::Int, cols::Int, cn::Int) where T
    typ = maketype(cvdepth(T), cn)
    handle = icxx"cv::Mat($rows, $cols, $typ);"
    Mat{T,3}(handle)
end

function Mat{T}(rows::Int, cols::Int, cn::Int, s::AbstractCvScalar) where T
    typ = maketype(cvdepth(T), cn)
    handle = icxx"cv::Mat($rows, $cols, $typ, $s);"
    Mat{T,3}(handle)
end

"""Single-channel 2-dimentaionl mat constructor with user provided data"""
function Mat{T}(rows::Int, cols::Int, data::Ptr{T}, step=0) where T
    typ = maketype(cvdepth(T), 1)
    handle = icxx"cv::Mat($rows, $cols, $typ, $data, $step);"
    Mat{T,2}(handle)
end

"""Multi-channel 2-dimentaionl mat constructor with user provided data"""
function Mat{T}(rows::Int, cols::Int, cn::Int, data::Ptr{T},
        step=0) where T
    typ = maketype(cvdepth(T), cn)
    handle = icxx"cv::Mat($rows, $cols, $typ, $data, $step);"
    Mat{T,3}(handle)
end

Mat(m::Mat{T,N}) where {T,N} = Mat{T,N}(m.handle)

### Fallback show method

function Base.show(io::IO, ::MIME{Symbol("text/plain")}, m::AbstractCvMat)
    print(io, string(typeof(m)))
    print(io, "\n")
    Base.showarray(io, convert(Mat, m)::Mat, false; header=false)
end

### Mat-specific methods ###

Base.IndexStyle(m::Mat) = Base.IndexLinear()

similar(m::Mat{T}) where {T} = Mat{T}(size(m)...)
similar_empty(m::Mat) = similar(m)

Base.show(io::IO, m::Mat) = Base.showarray(io, m, false)

# Note that cv::UMat doesn't have `data` in members.
@inline data(m::Mat) = data(m.handle)

import Base: getindex, setindex!

getindex(m::Mat, i::Int) =
    convert(eltype(m), icxx"$(m.handle).at<$(eltype(m))>($i-1);")
getindex(m::Mat, i::Int, j::Int) =
    convert(eltype(m), icxx"$(m.handle).at<$(eltype(m))>($i-1, $j-1);")
function getindex(m::Mat{T}, i::Int, j::Int, k::Int) where T
    cn = Val{channels(m)}
    convert(eltype(m), icxx"$(m.handle).at<cv::Vec<$T,$cn>>($i-1, $j-1)[$k-1];")
end

setindex!(m::Mat, v, i::Int) =
    icxx"$(m.handle).at<$(eltype(m))>($i-1) = $v;"
setindex!(m::Mat, v, i::Int, j::Int) =
    icxx"$(m.handle).at<$(eltype(m))>($i-1, $j-1) = $v;"
function setindex!(m::Mat{T}, v, i::Int, j::Int, k::Int) where T
    cn = Val{channels(m)}
    icxx"$(m.handle).at<cv::Vec<$T,$cn>>($i-1, $j-1)[$k-1] = $v;"
end

### UMat{T,N} ###

"""UMat{T,N} represents cv::UMat with encoded type information

`T` and `N` represents the element type and the dimension of Mat,
respectively.
"""
mutable struct UMat{T,N} <: AbstractCvMat{T,N}
    handle::cvUMat
end

"""Generic constructor"""
function UMat(handle::UMat)
    # Determine dimention and element type by value and encode eit into type
    T = eltype(handle)
    cn = channels(handle)
    dims = Int(icxx"$handle.dims;")
    N = (cn == 1) ? dims : dims + 1
    UMat{T,N}(handle)
end

# """Empty mat constructor"""
function UMat{T}(;usage_flags::UMatUsageFlags=USAGE_DEFAULT) where T
    handle = icxx"cv::UMat($usage_flags);"
    UMat{T,0}(handle)
end

# """Single-channel 2-dimentional mat constructor"""
function UMat{T}(rows::Int, cols::Int;
             usage_flags::UMatUsageFlags=USAGE_DEFAULT) where T
    typ = maketype(cvdepth(T), 1)
    handle = icxx"cv::UMat($rows, $cols, $typ, $usage_flags);"
    UMat{T,2}(handle)
end

# """Multi-chanel 2-dimentional mat constructor"""
function UMat{T}(rows::Int, cols::Int, cn::Int;
             usage_flags::UMatUsageFlags=USAGE_DEFAULT) where T
    typ = maketype(cvdepth(T), cn)
    handle = icxx"cv::UMat($rows, $cols, $typ, $usage_flags);"
    UMat{T,3}(handle)
end

# UMat(m::UMat{T,N}) where {T,N} = UMat{T,N}(m.handle)
function UMat(m::Mat{T,N}, flags=ACCESS_READ) where {T,N}
    UMat{T,N}(
        icxx"$(m.handle).getUMat($flags);")
end

similar(m::UMat{T}) where {T} = UMat{T}(size(m)...)
similar_empty(m::UMat) = similar(m)


### MatExpr{T,N} to Mat{T,N} conversion ###

convert(::Type{Mat}, m::MatExpr) = Mat(
    icxx"return cv::Mat($(m.handle));")
function show(io::IO, m::MatExpr)
    print(io, string(typeof(m)))
    print(io, "\n")
    Base.showarray(io, convert(Mat, m)::Mat, false; header=false)
end


### AbstractCvMat{T,N} to MatExpr{T,N}

convert(::Type{MatExpr}, m::AbstractCvMat) = MatExpr(
    icxx"return cv::MatExpr($(m.handle));")
convert(::Type{MatExpr{T,N}}, m::AbstractCvMat{T,N}) where {T,N} = MatExpr{T,N}(
    icxx"return cv::MatExpr($(m.handle));")
convert(::Type{MatExpr}, m::UMat) = convert(MatExpr, convert(Mat, m))
convert(::Type{MatExpr{T,N}}, m::UMat{T,N}) where {T,N} = MatExpr{T,N}(
    icxx"return cv::MatExpr($(m.handle));")


### UMat{T,N} to Mat{T,N} conversion ###

convert(::Type{Mat}, m::UMat{T,N}, flags=ACCESS_READ) where {T,N} = Mat{T,N}(
    icxx"$(m.handle).getMat($flags);")


### Array{T,N} to Mat conversion ###

function convert(::Type{Mat}, arr::Array{T,N}) where {T,N}
    if N != 2 && N != 3
        error("Not supported conversion for now")
    end
    Mat{T}(reverse(size(arr))..., pointer(arr))
end


### Mat to Array{T,N} conversion

@generated function convert(::Type{Array}, m::Mat{T,N}) where {T,N}
    pt = Ptr{T}
    quote
        # TODO: not sure if this is a julia bug
        p = icxx"$(m.handle).data;"
        p = reinterpret($pt, icxx"$(m.handle).data;")
        unsafe_wrap(Array, p, reverse(size(m)))
    end
end


### Matrix operations ###

import Base: +, -, *, /, transpose, ctranspose
import Base: promote_rule, broadcast

promote_rule(::Type{Mat{T,N}}, ::Type{MatExpr{T,N}}) where {T,N} = MatExpr{T,N}
promote_rule(::Type{UMat{T,N}}, ::Type{MatExpr{T,N}}) where {T,N} = MatExpr{T,N}

# For convenience
@inline handle(x::Number) = x

# to avoid method ambiguity warnings
for op in [:+, :-, :*]
    @eval begin
        $op(x::AbstractCvMat{Bool}, y::Bool) = error("not supported")
        $op(x::Bool, y::AbstractCvMat{Bool}) = error("not supported")
    end
end

+(x::MatExpr, y::MatExpr) = MatExpr(icxx"$(x.handle) + $(y.handle);")
+(x::MatExpr, y::Number) = MatExpr(icxx"$(x.handle) + $(y);")
+(x::Number, y::MatExpr) = MatExpr(icxx"$(x) + $(y.handle);")
+(x::MatExpr) = x
+(x::AbstractCvMat) = MatExpr(x)

-(x::MatExpr, y::MatExpr) = MatExpr(icxx"$(x.handle) - $(y.handle);")
-(x::MatExpr, y::Number) = MatExpr(icxx"$(x.handle) - $(y);")
-(x::Number, y::MatExpr) = MatExpr(icxx"$(x) - $(y.handle);")
-(x::MatExpr) = MatExpr(
    icxx"0 - $(x.handle);")
-(x::AbstractCvMat) = -(MatExpr(x))

function broadcast(::typeof(*), x::MatExpr, y::MatExpr)
    MatExpr(icxx"$(x.handle).mul($(y.handle));")
end

broadcast(::typeof(*), x::MatExpr, y::Number) = MatExpr(icxx"$(x.handle) * $(y);")
broadcast(::typeof(*), x::Number, y::MatExpr) = MatExpr(icxx"$(x) * $(y.handle);")

broadcast(::typeof(/), x::MatExpr, y::MatExpr) = MatExpr(icxx"$(x.handle) / $(y.handle);")
broadcast(::typeof(/), x::MatExpr, y::Number) = MatExpr(icxx"$(x.handle) / $(y);")
broadcast(::typeof(/), x::Number, y::MatExpr) = MatExpr(icxx"$(x) / $(y.handle);")

*(x::MatExpr, y::MatExpr) = MatExpr(icxx"$(x.handle) * $(y.handle);")
*(x::MatExpr, y::Number) = broadcast(*, x, y)
*(x::Number, y::MatExpr) = broadcast(*, x, y)
/(x::MatExpr, y::Number) = broadcast(/, x, y)
/(x::Number, y::MatExpr) = broadcast(/, x, y)


# For AbstractCvMats
for op in [:+, :-, :*]
    @eval begin
        @inline $op(x::AbstractCvMat, y::AbstractCvMat) =
            $op(MatExpr(x), MatExpr(y))
        @inline $op(x::MatExpr, y::AbstractCvMat) = $op(promote(x, y)...)
        @inline $op(x::AbstractCvMat, y::MatExpr) = $op(promote(x, y)...)
    end
end
for op in [:/, :*]
    @eval begin
        broadcast(::typeof($op), x::AbstractCvMat, y::AbstractCvMat) =
            $op(MatExpr(x), MatExpr(y))
        broadcast(::typeof($op), x::MatExpr, y::AbstractCvMat) = $op(promote(x, y)...)
        broadcast(::typeof($op), x::AbstractCvMat, y::MatExpr) = $op(promote(x, y)...)
    end
end

# Mat and scalars
for op in [:+, :-, :*]
    @eval begin
        @inline $op(x::AbstractCvMat, y::Number) = $op(MatExpr(x), y)
        @inline $op(x::Number, y::AbstractCvMat) = $op(x, MatExpr(y))
    end
end
for op in [:/, :*]
    @eval begin
        broadcast(::typeof($op), x::AbstractCvMat, y::Number) = $op(MatExpr(x), y)
        broadcast(::typeof($op), x::Number, y::AbstractCvMat) = $op(x, MatExpr(y))
    end
end

transpose(x::MatExpr) = MatExpr(
    icxx"$(x.handle).t();")
transpose(x::AbstractCvMat) = transpose(MatExpr(x))
ctranspose(x::Union{MatExpr, AbstractCvMat}) = transpose(x)


### Linear algebra ###

import Base: inv, ^

inv(x::MatExpr, method=DECOMP_SVD) = MatExpr(
    icxx"$(x.handle).inv($method);")
inv(x::AbstractCvMat, method=DECOMP_SVD) = inv(MatExpr(x), method)

^(x::MatExpr, p::Integer) = (p == -1) ? inv(x) : error("not supported")
^(x::AbstractCvMat, p::Integer) = ^(MatExpr(x), p)
