using TestItemRunner

@testitem "rolling_apply: Vectors running=false - Check return types" begin
    using Test
    using QuantUtils: rolling_apply

    vals = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    # automatic type detection
    res = rolling_apply(vals, 1, (x; i, r) -> sum(x))
    @test eltype(res) == Int64
    @test all(res .== vals)

    # type passed as parameter `item_type`
    res = rolling_apply(vals, 1, (x; i, r) -> sum(x); item_type=Float64)
    @test eltype(res) == Float64
    @test all(res .== vals)
end

@testitem "rolling_apply: Vectors running=false - Simple sum with window = 3, step = 1" begin
    using Test
    using QuantUtils: rolling_apply

    vals = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    res = rolling_apply(vals, 3, (x; i, r) -> sum(x))
    @test all(res .== [6, 9, 12, 15, 18, 21, 24, 27])
    @test eltype(res) == Int64
end

@testitem "rolling_apply: Vectors running=false - Minimum function with window = 4, step = 2" begin
    using Test
    using QuantUtils: rolling_apply

    vals = [10.0, 3, 5, 8, 2, 7, 9, 1]
    res = rolling_apply(vals, 4, (x; i, r) -> minimum(x); step=2)
    @test res == [3, 2, 1]
    @test eltype(res) == Float64
end

@testitem "rolling_apply: Vectors running=false - Custom function with window = 2, step = 1, item_type specified" begin
    using Test
    using QuantUtils: rolling_apply

    vals = [1.5, 2.5, 3.5, 4.5]
    custom_func(x) = x[1] * x[2]
    res = rolling_apply(vals, 2, (x; i, r) -> custom_func(x); item_type=Float64)
    @test res == [3.75, 8.75, 15.75]
    @test eltype(res) == Float64
end

@testitem "rolling_apply: Vectors running=false - Parallelized custom function with window = 2, step = 1, item_type specified" begin
    using Test
    using QuantUtils: rolling_apply

    vals = [1.5, 2.5, 3.5, 4.5]
    custom_func(x) = x[1] * x[2]
    res = rolling_apply(vals, 2, (x; i, r) -> custom_func(x); item_type=Float64, parallel=true)
    @test res == [3.75, 8.75, 15.75]
    @test eltype(res) == Float64
end

@testitem "rolling_apply: Vectors running=false - Empty vector" begin
    using Test
    using QuantUtils: rolling_apply

    vals = []
    res = rolling_apply(vals, 3, (x; i, r) -> sum(x))
    @test res == []
    @test eltype(res) == Any
end

@testitem "rolling_apply: Vectors running=false - Single element vector with window = 1" begin
    using Test
    using QuantUtils: rolling_apply

    vals = [42]
    res = rolling_apply(vals, 1, (x; i, r) -> x[1])
    @test res == [42]
    @test eltype(res) == Int64
end

@testitem "rolling_apply: Vectors running=true - Check return types" begin
    using Test
    using QuantUtils: rolling_apply

    vals = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    # automatic type detection
    res = rolling_apply(vals, 1, (x; i, r) -> sum(x); running=true)
    @test eltype(res) == Int64
    @test all(res .== vals)

    # type passed as parameter `item_type`
    res = rolling_apply(vals, 1, (x; i, r) -> sum(x); item_type=Float64, running=true)
    @test eltype(res) == Float64
    @test all(res .== vals)
end

@testitem "rolling_apply: Vectors running=true - Simple sum with window = 3, step = 1" begin
    using Test
    using QuantUtils: rolling_apply

    vals = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    res = rolling_apply(vals, 3, (x; i, r) -> sum(x); running=true)
    @test all(res .== [1, 3, 6, 9, 12, 15, 18, 21, 24, 27])
    @test eltype(res) == Int64
end

@testitem "rolling_apply: Vectors running=true - Minimum function with window = 4, step = 2" begin
    using Test
    using QuantUtils: rolling_apply

    vals = [10.0, 3, 5, 8, 2]
    res = rolling_apply(vals, 4, (x; i, r) -> sum(x); step=2, running=true)
    @test res == [10.0, 10 + 3 + 5, 3 + 5 + 8 + 2]
    @test eltype(res) == Float64
end

@testitem "rolling_apply: Vectors running=true - Custom function with window = 2, step = 1, item_type specified" begin
    using Test
    using QuantUtils: rolling_apply

    vals = [1.5, 2.5, 3.5, 4.5]
    custom_func(x) = length(x) > 1 ? x[1] * x[2] : x[1]
    res = rolling_apply(vals, 2, (x; i, r) -> custom_func(x); item_type=Float64, running=true)
    @test res == [1.5, 3.75, 8.75, 15.75]
    @test eltype(res) == Float64
end

@testitem "rolling_apply: Vectors running=true - Parallelized custom function with window = 2, step = 1, item_type specified" begin
    using Test
    using QuantUtils: rolling_apply

    vals = [1.5, 2.5, 3.5, 4.5]
    custom_func(x) = length(x) > 1 ? x[1] * x[2] : x[1]
    res = rolling_apply(
        vals, 2, (x; i, r) -> custom_func(x); item_type=Float64, running=true, parallel=true
    )
    @test res == [1.5, 3.75, 8.75, 15.75]
    @test eltype(res) == Float64
end

@testitem "rolling_apply: Vectors running=true - Empty vector" begin
    using Test
    using QuantUtils: rolling_apply

    vals = []
    res = rolling_apply(vals, 3, (x; i, r) -> sum(x); running=true)
    @test res == []
    @test eltype(res) == Any
end

@testitem "rolling_apply: Vectors running=true - Single element vector with window = 1" begin
    using Test
    using QuantUtils: rolling_apply

    vals = [42]
    res = rolling_apply(vals, 1, (x; i, r) -> x[1]; running=true)
    @test res == [42]
    @test eltype(res) == Int64
end

@testitem "rolling_apply: Matrix - Along first axis" begin
    using Test
    using QuantUtils: rolling_apply

    mat = [
        1 2 3
        4 5 6
        7 8 9
        10 11 12
    ]

    # Test with a window of 2 and step of 1
    result = rolling_apply(mat, 2, (x; i, r) -> sum(x; dims=1); dim=1)
    @test typeof(result) == Matrix{Int64}

    @test all(result .== [
        5 7 9
        11 13 15
        17 19 21
    ])
end

@testitem "rolling_apply: Matrix - Along second axis" begin
    using Test
    using QuantUtils: rolling_apply

    mat = [
        1 2 3
        4 5 6
        7 8 9
        10 11 12
    ]

    # Test with a window of 2 and step of 1
    result = rolling_apply(mat, 2, (x; i, r) -> sum(x; dims=2); dim=2)
    @test typeof(result) == Matrix{Int64}

    @test all(result .== [
        3 5
        9 11
        15 17
        21 23
    ])
end

@testitem "rolling_apply: Matrix - Parallelized along first axis" begin
    using Test
    using QuantUtils: rolling_apply

    mat = [
        1 2 3
        4 5 6
        7 8 9
        10 11 12
    ]

    # Test with a window of 2 and step of 1
    result = rolling_apply(mat, 2, (x; i, r) -> sum(x; dims=1); dim=1, parallel=true)
    @test typeof(result) == Matrix{Int64}

    @test all(result .== [
        5 7 9
        11 13 15
        17 19 21
    ])
end

@testitem "rolling_apply: Matrix - Parallelized along second axis" begin
    using Test
    using QuantUtils: rolling_apply

    mat = [
        1 2 3
        4 5 6
        7 8 9
        10 11 12
    ]

    # Test with a window of 2 and step of 1
    result = rolling_apply(mat, 2, (x; i, r) -> sum(x; dims=2); dim=2, parallel=true)
    @test typeof(result) == Matrix{Int64}

    @test all(result .== [
        3 5
        9 11
        15 17
        21 23
    ])
end

# @testset verbose = true "rolling_apply: Matrix slices running=false" begin
#     mat = [
#         1 2 3;
#         4 5 6;
#         7 8 9;
#         10 11 12
#     ]

#     # @testset "Sum along first axis" begin

#     #     # res = mapslices(x -> rolling_apply(x, 2, (x; i, r) -> sum(x)), mat, dims=1)
#     #     res = rolling_apply_slices(mat, 2, (x; i, r) -> sum(x))
#     #     display(res)

#     # end

# end
