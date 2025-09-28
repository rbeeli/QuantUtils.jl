using TestItemRunner
using Test

@testitem "predicate findmin/findmax" begin
    using QuantUtils

    data = [4, -1, 7, -3, 2]
    isneg(x) = x < 0

    min_val, min_idx = findmin(data, isneg)
    @test min_val == -3
    @test min_idx == 4

    max_val, max_idx = findmax(data, isneg)
    @test max_val == -1
    @test max_idx == 2

    arr = reshape(collect(1:9), 3, 3)
    divisible_by_three(x) = x % 3 == 0

    min_three_val, min_three_idx = findmin(arr, divisible_by_three)
    @test min_three_val == 3
    @test min_three_idx == 3

    max_three_val, max_three_idx = findmax(arr, divisible_by_three)
    @test max_three_val == 9
    @test max_three_idx == 9

    @test findmin(data, x -> false) == (nothing, -1)
    @test findmax(data, x -> false) == (nothing, -1)

    empty_vec = Int[]
    @test findmin(empty_vec, x -> true) == (nothing, -1)
    @test findmax(empty_vec, x -> true) == (nothing, -1)
end
