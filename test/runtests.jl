using CVCore
using Base.Test

import CVCore: mat_depth, mat_channel, maketype

@testset "Scalar{T}" begin
    # Eltype should be Float64
    @test eltype(Scalar(0)) == Float64
    @test eltype(Scalar(Int(0))) == Float64

    # with explicit type paramter
    for typ in [Int32, Int, Float32, Float64]
        @test eltype(Scalar{typ}(1)) == typ
    end
end

@testset "Mat{T,N}" begin
    mat = Mat{Float64}()
    @test isempty(mat)

    mat = Mat{UInt8}(10, 20)
    @test size(mat) == (10, 20)
    @test channels(mat) == 1
    @test rows(mat) == 10
    @test cols(mat) == 20
    @test total(mat) == length(mat)
    @test isContinuous(mat)
    @test elemSize(mat) == sizeof(UInt8)*channels(mat)
    @test dims(mat) == 2
    @test !isempty(mat)

    mat = Mat{Float32}(10, 20, 2)
    @test channels(mat) == 2
    @test size(mat) == (10, 20, 2)
    @test elemSize(mat) == sizeof(Float32)*channels(mat)
    @test dims(mat) == 2

    mat = Mat{Float64}(10, 20, 3, Scalar(1,0.5,0.3))
    @test channels(mat) == 3
    @test size(mat) == (10, 20, 3)
    @test elemSize(mat) == sizeof(Float64)*channels(mat)

    matclone = clone(mat)
    @test isa(matclone, typeof(mat))
    @test matclone == mat

    @testset "Array to cv::Mat conversion" begin
        arr = rand(Float64, 10, 2)
        m = Mat(arr)
        @test eltype(m) == eltype(arr)
        @test size(arr) == reverse(size(m))
    end

    mat = Mat{UInt8}(10,10, Scalar(0))
    @test all(mat .== 0)
    mat = Mat{UInt8}(10,10, Scalar(1))
    @test all(mat .== 1)
end

@testset "UMat{T,N}" begin
    umat = UMat{UInt8}(3, 3)
    mat = Mat(umat)
    @test isa(mat, Mat)
    @test size(umat) == (3, 3)
end

macro mat_op_testdata()
    #=
    2x12 Array{Float64,2}:
     1.0  3.0  5.0  7.0   9.0  11.0  13.0  15.0  17.0  19.0  21.0  23.0
     2.0  4.0  6.0  8.0  10.0  12.0  14.0  16.0  18.0  20.0  22.0  24.0
    =#
    esc(quote
        x = map(Float64, reshape([1:24;], 2,3*4))
        xt = x'
        m = Mat(xt)
    end)
end

@testset "Matrix operations" begin
    @testset "+" begin
        @mat_op_testdata
        ret = m + m
        retmat = Mat(ret)
        @test all(retmat .== 2x)
    end

    @testset "-" begin
        @mat_op_testdata
        ret = m - m
        retmat = Mat(ret)
        @test all(retmat .== 0)
    end

    @testset ".*" begin
        @mat_op_testdata
        ret = m .* 5
        @test isa(ret, MatExpr)
        retmat = Mat(ret)
        @test all(retmat .== 5x)
    end

    @testset "./" begin
        @mat_op_testdata
        ret = m ./ 2
        @test isa(ret, MatExpr)
        retmat = Mat(ret)
        expected = x ./ 2
        @test all(retmat .== expected)
    end

    @testset "*" begin
        @mat_op_testdata
        @test Mat(m * m') == x * x'
    end

    @testset "transpose" begin
        @mat_op_testdata
        retexpr = m'
        retmat = Mat(retexpr)
        @test all(retmat .== x')
    end

    @testset "inv" begin
        @mat_op_testdata
        square_mat = m * m'
        #=
        2x2 Array{Float64,2}:
        2300.0  2444.0
        2444.0  2600.0
        =#
        inv_x = inv(x * xt)
        ret = inv(square_mat)
        inv_m = Mat(ret)
        @test_approx_eq inv_x inv_m
    end
end

@testset "Matrix channels" begin
    @test mat_channel(CV_32FC1) == 1
    @test mat_channel(CV_32FC2) == 2
    @test mat_channel(CV_32FC3) == 3
    @test mat_channel(CV_32FC4) == 4

    @test mat_channel(CV_8UC1) == 1
    @test mat_channel(CV_8UC2) == 2
    @test mat_channel(CV_8UC3) == 3
    @test mat_channel(CV_8UC4) == 4
end

@testset "Matrix depth" begin
    for flags in [
            CV_32FC1,
            CV_32FC2,
            CV_32FC3,
            CV_32FC4
            ]
        @test mat_depth(flags) == CV_32F
    end

    for flags in [
            CV_8UC1,
            CV_8UC2,
            CV_8UC3,
            CV_8UC4
            ]
        @test mat_depth(flags) == CV_8U
    end
end

@testset "maketype" begin
    @test maketype(CV_8U, 1) == CV_8UC1
    @test maketype(CV_8U, 2) == CV_8UC2
    @test maketype(CV_8U, 3) == CV_8UC3
    @test maketype(CV_8U, 4) == CV_8UC4

    @test maketype(CV_32F, 1) == CV_32FC1
    @test maketype(CV_32F, 2) == CV_32FC2
    @test maketype(CV_32F, 3) == CV_32FC3
    @test maketype(CV_32F, 4) == CV_32FC4
end

@testset "cv::TermCriteria" begin
    criteria = TermCriteria(CVCore.TERM_CRITERIA_EPS, 30, 0.001)
    @test isa(criteria, Cxx.CppValue)
end
