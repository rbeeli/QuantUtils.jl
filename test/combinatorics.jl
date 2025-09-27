using TestItemRunner

@testitem "params_combinations: type-stable keys/values" begin
    using Test
    using QuantUtils: params_combinations

    a_fixed = Dict(:wnd => [1.0, 2.0, 3.0], :mode => [1.0], :coef => [0.1, 0.5, 1.0])
    res = params_combinations(a_fixed)

    @test length(res) == 9

    for d in res
        @test typeof(d[:wnd]) == Float64
        @test typeof(d[:mode]) == Float64
        @test typeof(d[:coef]) == Float64
    end
end

@testitem "params_combinations: mixed types keys/values" begin
    using Test
    using QuantUtils: params_combinations

    a_mixed = Dict("wnd" => [1, 2, 3], :mode => ["A"], "coef" => [0.1, 0.5, 1.0])
    res = params_combinations(a_mixed)

    @test length(res) == 9

    for d in res
        @test typeof(d["wnd"]) == Int64
        @test typeof(d[:mode]) == String
        @test typeof(d["coef"]) == Float64
    end
end

@testitem "params_combinations: filtered" begin
    using Test
    using QuantUtils: params_combinations

    params = Dict{Any,Vector{Any}}(:wnd => [1, 2], :mode => ["A", "B"], :coef => [0.1, 0.5])
    res = params_combinations(params; filter=x -> x[:mode] != "A" && x[:wnd] > 1)

    @test length(res) == 2

    for d in res
        @test d[:mode] != "A" || d[:wnd] > 1
    end
end
