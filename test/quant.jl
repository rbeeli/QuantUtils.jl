using TestItemRunner

@testitem "multi_minimum and multi_maximum" begin
    using Test
    using QuantUtils: multi_minimum, multi_maximum

    a = [3, -1, 5]
    b = [2, 0, -4]
    c = [10, 8, 7]

    @test multi_minimum(a, b, c) == -4
    @test multi_maximum(a, b, c) == 10
end

@testitem "prod1p and cumprod1p" begin
    using Test
    using QuantUtils: prod1p, cumprod1p

    returns = [0.1, -0.2, 0.05]

    @test isapprox(prod1p(returns), 0.924, atol=1e-12)
    @test cumprod1p(returns) ≈ [1.1, 0.88, 0.924]
end

@testitem "nancumprod1p ignores NaNs" begin
    using Test
    using QuantUtils: nancumprod1p

    returns = [0.1, NaN, 0.05]
    result = nancumprod1p(returns)

    @test result[1] ≈ 1.1
    @test result[2] ≈ 1.1
    @test result[3] ≈ 1.155
end

@testitem "pct_change handles defaults and overrides" begin
    using Test
    using QuantUtils: pct_change

    prices = [100.0, 110.0, 99.0]
    changes = pct_change(prices)

    @test isnan(changes[1])
    @test changes[2] ≈ 0.1
    @test changes[3] ≈ -0.1

    int_prices = [10, 15, 30]
    changes_with_fill = pct_change(int_prices; first_value=0.0)

    @test changes_with_fill[1] == 0.0
    @test changes_with_fill[2:3] ≈ [0.5, 1.0]
end

@testitem "calc_returns simple and log returns" begin
    using Test
    using DataFrames
    using QuantUtils: calc_returns

    dates = collect(1:4)
    df = DataFrame(;
        date=dates, assetA=[100.0, 110.0, 121.0, 133.1], assetB=[50.0, 55.0, 66.0, 66.0]
    )

    simple = calc_returns(df; skip_cols=["date"])
    @test simple.date == dates
    @test isnan(simple.assetA[1]) && isnan(simple.assetB[1])
    @test simple.assetA[2:4] ≈ [0.1, 0.1, 0.1]
    @test simple.assetB[2:4] ≈ [0.1, 0.2, 0.0]

    log_df = DataFrame(df)
    log_returns = calc_returns(log_df; skip_cols=["date"], log_returns=true)
    @test log_returns.date == dates
    @test isnan(log_returns.assetA[1]) && isnan(log_returns.assetB[1])
    @test log_returns.assetA[2] ≈ log(1.1)
    @test log_returns.assetB[3] ≈ log(66.0 / 55.0)
end

@testitem "calc_returns skip_cols accepts multiple formats" begin
    using Test
    using DataFrames
    using QuantUtils: calc_returns

    df = DataFrame(Any[1:3, ["A", "A", "A"], [100.0, 110.0, 121.0]], ["date", "ticker", "price"])
    res = calc_returns(df; skip_cols=["date", "ticker"])

    @test res[!, "date"] == 1:3
    @test res[!, "ticker"] == ["A", "A", "A"]
    @test isnan(res[!, "price"][1])
    @test res[!, "price"][2:3] ≈ [0.1, 0.1]
end

@testitem "calc_returns gap skipping respects max_nan_skip" begin
    using Test
    using DataFrames
    using QuantUtils: calc_returns

    dates = collect(1:5)
    prices = [100.0, 110.0, NaN, NaN, 150.0]
    df = DataFrame(; date=dates, price=prices)

    skip_one = calc_returns(df; skip_cols=["date"], max_nan_skip=1)
    @test isnan(skip_one.price[1])
    @test skip_one.price[2] ≈ 0.1
    @test isnan(skip_one.price[5])

    skip_two = calc_returns(df; skip_cols=["date"], max_nan_skip=2)
    @test skip_two.price[2] ≈ 0.1
    @test skip_two.price[5] ≈ 150.0 / 110.0 - 1
end
