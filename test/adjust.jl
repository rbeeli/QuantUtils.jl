using TestItemRunner
using Test

@testitem "shift" begin
    using QuantUtils: shift, shift!

    series = [1, 2, 3, 4]
    @test shift(series, 1; fill_value=0) == [0, 1, 2, 3]
    @test shift(series, -2; fill_value=9) == [3, 4, 9, 9]

    zero_shift = shift(series, 0; fill_value=-1)
    @test zero_shift == series
    @test zero_shift !== series

    all_filled = shift(series, 10; fill_value=7)
    @test all_filled == fill(7, length(series))

    negative_all = shift(series, -10; fill_value=-5)
    @test negative_all == fill(-5, length(series))

    # ensure original series unchanged
    @test series == [1, 2, 3, 4]

    inplace_forward = [1, 2, 3, 4]
    result_forward = shift!(inplace_forward, 1; fill_value=0)
    @test result_forward === inplace_forward
    @test inplace_forward == [0, 1, 2, 3]

    inplace_backward = [1, 2, 3, 4]
    shift!(inplace_backward, -2; fill_value=9)
    @test inplace_backward == [3, 4, 9, 9]

    inplace_zero = [1, 2, 3]
    result_zero = shift!(inplace_zero, 0; fill_value=5)
    @test result_zero === inplace_zero
    @test inplace_zero == [1, 2, 3]

    inplace_full = [1, 2, 3]
    shift!(inplace_full, 5; fill_value=7)
    @test inplace_full == fill(7, 3)

    inplace_full_neg = [1, 2, 3]
    shift!(inplace_full_neg, -5; fill_value=-2)
    @test inplace_full_neg == fill(-2, 3)

    empty_vec = Int[]
    shift!(empty_vec, 2; fill_value=0)
    @test isempty(empty_vec)
end
