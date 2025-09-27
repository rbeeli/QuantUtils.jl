using TestItemRunner

@testitem "split_parts: parts must sum to 1" begin
    using Test
    using QuantUtils: split_parts

    vec = [10, 11, 12, 13, 14, 15, 16]
    @test_throws ArgumentError split_parts(vec, (0.5, 0.5, 0.5))
    @test_throws ArgumentError split_parts(vec, (0.5,))
    @test_throws ArgumentError split_parts(vec, (0.5, 0.7))
end

@testitem "split_parts: parts must be positive" begin
    using Test
    using QuantUtils: split_parts

    vec = [10, 11, 12, 13, 14, 15, 16]
    @test_throws ArgumentError split_parts(vec, (-1.0, 0.5))
    @test_throws ArgumentError split_parts(vec, (-1.0, 1.0))
end

@testitem "split_parts: vector" begin
    using Test
    using QuantUtils: split_parts

    vec = [10, 11, 12, 13, 14, 15, 16]
    a, b = split_parts(vec, (0.5, 0.5))
    @test all(a .== [10, 11, 12])
    @test all(b .== [13, 14, 15, 16])
end

@testitem "split_parts: matrix axis=1" begin
    using Test
    using QuantUtils: split_parts

    mat = [
        10 11 12
        13 14 15
        16 17 18
        19 20 21
        22 23 24
        25 26 27
        28 29 30
        31 32 33
    ]
    a, b = split_parts(mat, (0.5, 0.5))
    @test all(a .== [10 11 12; 13 14 15; 16 17 18; 19 20 21])
    @test all(b .== [22 23 24; 25 26 27; 28 29 30; 31 32 33])
end

@testitem "split_parts: matrix axis=2" begin
    using Test
    using QuantUtils: split_parts

    mat = [
        10 11 12
        13 14 15
        16 17 18
        19 20 21
        22 23 24
        25 26 27
        28 29 30
    ]
    a, b = split_parts(mat, (0.7, 0.3); axis=2)
    @test all(a .== [10 11; 13 14; 16 17; 19 20; 22 23; 25 26; 28 29])
    @test all(b .== [12; 15; 18; 21; 24; 27; 30])
end

@testitem "split_parts: dataframe axis=1" begin
    using Test
    using DataFrames
    using QuantUtils: split_parts

    mat = [
        10 11 12
        13 14 15
        16 17 18
        19 20 21
        22 23 24
        25 26 27
        28 29 30
    ]
    df = DataFrame(mat, ["a", "b", "c"])
    a, b = split_parts(df, (0.5, 0.5))
    @test all(Matrix(a) .== [10 11 12; 13 14 15; 16 17 18])
    @test all(Matrix(b) .== [19 20 21; 22 23 24; 25 26 27; 28 29 30])
end

@testitem "split_parts: dataframe axis=2" begin
    using Test
    using DataFrames
    using QuantUtils: split_parts

    mat = [
        10 11 12
        13 14 15
        16 17 18
        19 20 21
        22 23 24
        25 26 27
        28 29 30
    ]
    df = DataFrame(mat, ["a", "b", "c"])
    a, b = split_parts(df, (0.7, 0.3); axis=2)
    @test all(Matrix(a) .== [10 11; 13 14; 16 17; 19 20; 22 23; 25 26; 28 29])
    @test all(Matrix(b) .== [12; 15; 18; 21; 24; 27; 30])
end
