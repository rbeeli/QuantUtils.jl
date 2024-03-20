using Test


@testset "nan_to_zero: scalars" begin
    @test nan_to_zero(NaN) === 0.0
    @test nan_to_zero(5.0) === 5.0
    @test nan_to_zero(3) === 3
end


@testset "nan_to_zero: broadcasting" begin
    @test all(nan_to_zero.([NaN, 5.0, 3]) .== [0.0, 5.0, 3.0])
    @test all(nan_to_zero.([NaN, 5.0, 3.0]) .== [0.0, 5.0, 3.0])
    @test all(nan_to_zero.([NaN, 5, 3]) .== [0.0, 5.0, 3.0])
end


@testset "nan_to_one: scalars" begin
    @test nan_to_one(NaN) === 1.0
    @test nan_to_one(5.0) === 5.0
    @test nan_to_one(3) === 3
end


@testset "nan_to_one: broadcasting" begin
    @test all(nan_to_one.([NaN, 5.0, 3]) .== [1.0, 5.0, 3.0])
    @test all(nan_to_one.([NaN, 5.0, 3.0]) .== [1.0, 5.0, 3.0])
    @test all(nan_to_one.([NaN, 5, 3]) .== [1.0, 5.0, 3.0])
end


@testset "nan_to_x: scalars" begin
    @test nan_to_x(NaN, 10) === 10
    @test nan_to_x(5.0, 10) === 5.0
    @test nan_to_x(3, 10) === 3
end


@testset "nan_to_x: broadcasting" begin
    @test all(nan_to_x.([NaN, 5.0, 3], 10) .== [10.0, 5.0, 3.0])
    @test all(nan_to_x.([NaN, 5.0, 3.0], 10) .== [10.0, 5.0, 3.0])
    @test all(nan_to_x.([NaN, 5, 3], 10) .== [10.0, 5.0, 3.0])
end
