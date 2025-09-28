using TestItemRunner
using Test

@testitem "predicate findmin/findmax" begin
    using QuantUtils

    data = [4, -1, 7, -3, 2]
    isneg(x) = x < 0

    min_idx, min_val = findmin(data, isneg)
    @test min_idx == 4
    @test min_val == -3

    max_idx, max_val = findmax(data, isneg)
    @test max_idx == 2
    @test max_val == -1

    arr = reshape(collect(1:9), 3, 3)
    divisible_by_three(x) = x % 3 == 0

    min_three_idx, min_three_val = findmin(arr, divisible_by_three)
    @test min_three_idx == 3
    @test min_three_val == 3

    max_three_idx, max_three_val = findmax(arr, divisible_by_three)
    @test max_three_idx == 9
    @test max_three_val == 9

    @test findmin(data, x -> false) == (-1, nothing)
    @test findmax(data, x -> false) == (-1, nothing)

    empty_vec = Int[]
    @test findmin(empty_vec, x -> true) == (-1, nothing)
    @test findmax(empty_vec, x -> true) == (-1, nothing)
end
