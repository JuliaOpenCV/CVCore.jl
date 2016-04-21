# CVCore

[![Build Status](https://travis-ci.org/JuliaOpenCV/CVCore.jl.svg?branch=master)](https://travis-ci.org/JuliaOpenCV/CVCore.jl)

[![Coverage Status](https://coveralls.io/repos/JuliaOpenCV/CVCore.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaOpenCV/CVCore.jl?branch=master)

[![codecov.io](http://codecov.io/github/JuliaOpenCV/CVCore.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaOpenCV/CVCore.jl?branch=master)

OpenCV Core functionality

## Installation

See [JuliaOpenCV/OpenCV.jl](https://github.com/JuliaOpenCV/OpenCV.jl)

## Getting started

The primary export of the package is `Mat{T,N}`, which is the Julia type for `cv::Mat`. `Mat{T,N}` is designed to be a subtype of `AbstractArray{T,N}` so that it can be used as `AbstractArray{T,N}`.
It has element type (`T`) and dimension (`N`) as type parameters, whereas `cv::Mat` doesn't. Note that matrix construction interface is different between Julia and C++. `cv::Mat(3,3,CV_8U)` in C++ can be written in Julia as `Mat{UInt8}(3,3)`.

### Create uninitialized matrix:

```jl
using CVCore

julia> A = Mat{Float64}(3,3)
3×3 CVCore.Mat{Float64,2}:
   3.39519e-313  4.94066e-324   2.122e-314
 NaN             1.72723e-77   -2.32036e77
   1.97626e-323  0.0            0.0
```

### Create matrix filled with Scalar (`cv::Scalar`)

```jl
julia> A = Mat{Float64}(3,3,Scalar(1))
3×3 CVCore.Mat{Float64,2}:
 1.0  1.0  1.0
 1.0  1.0  1.0
 1.0  1.0  1.0
```

### Matirx operations

```jl
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

```jl
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

```jl
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
