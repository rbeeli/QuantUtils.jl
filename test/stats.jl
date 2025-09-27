using TestItemRunner

@testitem "nanquantile ignores NaNs" begin
    using Test
    using QuantUtils: nanquantile

    data = [1.0, NaN, 3.0, NaN, 5.0]
    @test nanquantile(data, 0.5) == 3.0
    @test isnan(nanquantile(fill(NaN, 3), 0.5))
end

@testitem "sample_range_uniform picks alternative value" begin
    using Test
    using Random
    using QuantUtils: sample_range_uniform

    rng = MersenneTwister(42)
    @test sample_range_uniform(rng, 0, 1, 1, 0) == 1
    @test sample_range_uniform(rng, 5, 5, 1, 5) == 5
end

@testitem "iqr and mse basic checks" begin
    using Test
    using Statistics
    using QuantUtils: iqr, mse

    data = [1, 2, 4, 7, 11]
    @test iqr(data) == quantile(data, 0.75) - quantile(data, 0.25)

    y = [1.0, 3.0, 5.0]
    yhat = [1.0, 2.0, 4.0]
    @test mse(y, yhat) ≈ 2 / 3
end

@testitem "calc_rolling_mean matches expanding average" begin
    using Test
    using Statistics
    using QuantUtils: calc_rolling_mean

    series = [1, 2, 3, 4, 5]
    window = 3

    result = calc_rolling_mean(series, window)
    expected = Float64[]
    for i in eachindex(series)
        start = max(1, i - window + 1)
        slice = series[start:i]
        push!(expected, mean(slice))
    end

    @test result ≈ expected
end

@testitem "calc_rolling_std matches sample std" begin
    using Test
    using Statistics
    using QuantUtils: calc_rolling_std

    series = Float64[2, 4, 4, 4, 5, 5, 7]
    window = 4

    result = calc_rolling_std(series, window)
    expected = Float64[]
    for i in eachindex(series)
        start = max(1, i - window + 1)
        slice = series[start:i]
        push!(expected, length(slice) < 2 ? 0.0 : std(slice; corrected=true))
    end

    @test isapprox(result, expected; atol=1e-10)
end

@testitem "calc_ewm_mean reproduces manual recursion" begin
    using Test
    using QuantUtils: calc_ewm_mean

    series = Float64[1, 2, 3, 4]
    span = 2

    expected_adjust = let α = 2 / (span + 1), onem = 1 - α
        num = 0.0
        denom = 0.0
        out = similar(series)
        for (i, x) in enumerate(series)
            if i == 1
                num = x
                denom = 1.0
            else
                num = x + onem * num
                denom = 1.0 + onem * denom
            end
            out[i] = num / denom
        end
        out
    end

    expected_recursive = let α = 2 / (span + 1)
        s = 0.0
        out = similar(series)
        for (i, x) in enumerate(series)
            s = i == 1 ? x : α * x + (1 - α) * s
            out[i] = s
        end
        out
    end

    @test calc_ewm_mean(series, span) ≈ expected_adjust
    @test calc_ewm_mean(series, span; adjust=false) ≈ expected_recursive
end

@testitem "calc_ewm_std follows incremental update" begin
    using Test
    using QuantUtils: calc_ewm_std

    series = Float64[1, 5, 2, 8]
    span = 3

    function manual(series, span; bias=false)
        α = 2 / (span + 1)
        decay = 1 - α
        T = Float64
        out = similar(series)
        w = wsq = μ = m2 = zero(T)
        for (i, x_raw) in pairs(series)
            x = T(x_raw)
            w *= decay
            wsq *= decay^2
            m2 *= decay
            w_new = α
            w += w_new
            wsq += w_new^2
            Δ = x - μ
            μ += (w_new / w) * Δ
            m2 += w_new * Δ * (x - μ)
            denom = bias ? w : w - wsq / w
            out[i] = denom > 0 ? sqrt(m2 / denom) : T(NaN)
        end
        out
    end

    function arrays_match(a, b)
        all(((x, y) -> (isnan(x) && isnan(y)) || isapprox(x, y; atol=1e-10)).(a, b))
    end

    @test arrays_match(calc_ewm_std(series, span), manual(series, span))
    @test arrays_match(calc_ewm_std(series, span; bias=true), manual(series, span; bias=true))
end

@testitem "calc_rolling_median matches Statistics.median" begin
    using Test
    using Statistics
    using QuantUtils: calc_rolling_median

    series = [1, 3, 5, 7, 9]
    window = 3

    result = calc_rolling_median(series, window)
    expected = Float64[]
    for i in eachindex(series)
        start = max(1, i - window + 1)
        slice = Float64.(series[start:i])
        push!(expected, median(slice))
    end

    @test eltype(result) == Float64
    @test result ≈ expected
end

@testitem "calc_rolling_zscore matches mean/std z-score" begin
    using Test
    using Statistics
    using QuantUtils: calc_rolling_zscore

    series = Float64[1, 2, 4, 7, 11]
    window = 3

    result = calc_rolling_zscore(series, window)
    expected = Float64[]
    for i in eachindex(series)
        start = max(1, i - window + 1)
        slice = series[start:i]
        if length(slice) < 2
            push!(expected, 0.0)
        else
            μ = mean(slice)
            σ = std(slice; corrected=true)
            push!(expected, σ == 0 ? 0.0 : (series[i] - μ) / σ)
        end
    end

    @test isapprox(result, expected; atol=1e-10)
end

@testitem "calc_rolling_zscore robust uses median/IQR" begin
    using Test
    using Statistics
    using QuantUtils: calc_rolling_zscore

    series = Float64[2, 4, 6, 8, 10, 12]
    window = 3

    result = calc_rolling_zscore(series, window, Val(:robust))
    expected = Float64[]
    for i in eachindex(series)
        start = max(1, i - window + 1)
        slice = series[start:i]
        med = median(slice)
        q1 = quantile(slice, 0.25)
        q3 = quantile(slice, 0.75)
        scale = q3 - q1
        push!(expected, scale == 0 ? 0.0 : (series[i] - med) / scale)
    end

    @test isapprox(result, expected; atol=1e-10)
end

@testitem "calc_rolling_min and calc_rolling_max" begin
    using Test
    using QuantUtils: calc_rolling_min, calc_rolling_max

    series = [5, 1, 3, 2, 4]
    window = 3

    min_expected = Int[]
    max_expected = Int[]
    for i in eachindex(series)
        start = max(1, i - window + 1)
        slice = series[start:i]
        push!(min_expected, minimum(slice))
        push!(max_expected, maximum(slice))
    end

    @test calc_rolling_min(series, window) == min_expected
    @test calc_rolling_max(series, window) == max_expected
end

@testitem "calc_rolling_average" begin
    using Test
    using QuantUtils: calc_rolling_average, calc_rolling_mean, calc_rolling_median

    series = [1, 2, 3, 4]
    window = 2

    @test calc_rolling_average(:sma, series, window) == calc_rolling_mean(series, window)
    @test calc_rolling_average(:median, series, window) == calc_rolling_median(series, window)
end
