using TestItemRunner
using Test

@testsnippet SharedImputation begin
    function test_array(a, b)
        @test length(a) == length(b)
        for (i, j) in zip(a, b)
            if ismissing(i) || ismissing(j)
                @test ismissing(i) && ismissing(j)
            elseif isnan(i) || isnan(j)
                @test isnan(i) && isnan(j)
            else
                @test i == j
            end
        end
    end
end

@testitem "imputation: ffill" setup = [SharedImputation] begin
    using Test
    using DataFrames
    using QuantUtils: ffill

    df = DataFrame(; A=[1, NaN, 3, missing], B=[missing, 2, missing, 4])

    # Basic functionality test
    test_array(ffill(df).A, [1, 1, 3, 3])
    # Test with specific columns
    test_array(ffill(df; cols=[:B]).B, [missing, 2, 2, 4])
    test_array(ffill(df; cols=[:B]).A, df.A)
    # Test with ignore_cols
    test_array(ffill(df; ignore_cols=[:B]).A, [1, 1, 3, 3])
    test_array(ffill(df; ignore_cols=[:B]).B, df.B)
    # Custom where function
    test_array(ffill(df; where=ismissing).A, [1, NaN, 3, 3])
end

@testitem "imputation: ffill!" setup = [SharedImputation] begin
    using Test
    using DataFrames
    using QuantUtils: ffill!

    df = DataFrame(; A=[1, NaN, 3, missing], B=[missing, 2, missing, 4])

    # Basic functionality test
    test_array(ffill!(copy(df)).A, [1, 1, 3, 3])
    # Test with specific columns
    test_array(ffill!(copy(df); cols=[:B]).B, [missing, 2, 2, 4])
    test_array(ffill!(copy(df); cols=[:B]).A, df.A)
    # Test with ignore_cols
    test_array(ffill!(copy(df); ignore_cols=[:B]).A, [1, 1, 3, 3])
    test_array(ffill!(copy(df); ignore_cols=[:B]).B, df.B)
    # Custom where function
    test_array(ffill!(copy(df); where=ismissing).A, [1, NaN, 3, 3])
end

@testitem "imputation: bfill" setup = [SharedImputation] begin
    using Test
    using DataFrames
    using QuantUtils: bfill

    df = DataFrame(; A=[1, NaN, 3, missing], B=[missing, 2, missing, 4])

    # Basic functionality test
    test_array(bfill(df).A, [1, 3, 3, missing])
    # Test with specific columns
    test_array(bfill(df; cols=[:B]).B, [2, 2, 4, 4])
    test_array(bfill(df; cols=[:B]).A, df.A)
    # Test with ignore_cols
    test_array(bfill(df; ignore_cols=[:B]).A, [1, 3, 3, missing])
    test_array(bfill(df; ignore_cols=[:B]).B, df.B)
    # Custom where function
    test_array(bfill(df; where=ismissing).A, [1, NaN, 3, missing])
end

@testitem "imputation: bfill!" setup = [SharedImputation] begin
    using Test
    using DataFrames
    using QuantUtils: bfill!

    df = DataFrame(; A=[1, NaN, 3, missing], B=[missing, 2, missing, 4])

    # Basic functionality test
    test_array(bfill!(copy(df)).A, [1, 3, 3, missing])
    # Test with specific columns
    test_array(bfill!(copy(df); cols=[:B]).B, [2, 2, 4, 4])
    test_array(bfill!(copy(df); cols=[:B]).A, df.A)
    # Test with ignore_cols
    test_array(bfill!(copy(df); ignore_cols=[:B]).A, [1, 3, 3, missing])
    test_array(bfill!(copy(df); ignore_cols=[:B]).B, df.B)
    # Custom where function
    test_array(bfill!(copy(df); where=ismissing).A, [1, NaN, 3, missing])
end
