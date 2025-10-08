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

@testitem "ffill" setup = [SharedImputation] begin
    using Test
    using DataFrames
    using QuantUtils: ffill

    df = DataFrame(; A=[1, NaN, 3, missing], B=[missing, 2, missing, 4])

    # Basic functionality test
    test_array(ffill(df).A, [1, 1, 3, 3])
    # Test with skip_cols to target specific columns
    test_array(ffill(df; skip_cols=["A"]).B, [missing, 2, 2, 4])
    test_array(ffill(df; skip_cols=["A"]).A, df.A)
    # Test with skip_cols
    test_array(ffill(df; skip_cols=["B"]).A, [1, 1, 3, 3])
    test_array(ffill(df; skip_cols=["B"]).B, df.B)
    # Custom predicate function
    test_array(ffill(df; predicate=ismissing).A, [1, NaN, 3, 3])
end

@testitem "ffill!" setup = [SharedImputation] begin
    using Test
    using DataFrames
    using QuantUtils: ffill!

    df = DataFrame(; A=[1, NaN, 3, missing], B=[missing, 2, missing, 4])

    # Basic functionality test
    test_array(ffill!(copy(df)).A, [1, 1, 3, 3])
    # Test with skip_cols to target specific columns
    test_array(ffill!(copy(df); skip_cols=["A"]).B, [missing, 2, 2, 4])
    test_array(ffill!(copy(df); skip_cols=["A"]).A, df.A)
    # Test with skip_cols
    test_array(ffill!(copy(df); skip_cols=["B"]).A, [1, 1, 3, 3])
    test_array(ffill!(copy(df); skip_cols=["B"]).B, df.B)
    # Custom predicate function
    test_array(ffill!(copy(df); predicate=ismissing).A, [1, NaN, 3, 3])
end

@testitem "ffill vector" setup = [SharedImputation] begin
    using Test
    using QuantUtils: ffill, ffill!

    vec = [1, NaN, 3, missing]
    test_array(ffill(vec), [1, 1, 3, 3])
    test_array(vec, [1, NaN, 3, missing])

    vec_with_limit = [1, missing, missing, 4]
    test_array(ffill(vec_with_limit, 1), [1, 1, missing, 4])

    vec_predicate = [1.0, NaN, NaN, 4.0]
    test_array(ffill(vec_predicate; predicate=isnan), [1.0, 1.0, 1.0, 4.0])
    test_array(vec_predicate, [1.0, NaN, NaN, 4.0])

    vec_inplace = [1, missing, missing, 5]
    ffill!(vec_inplace, 2)
    test_array(vec_inplace, [1, 1, 1, 5])

    vec_inplace_predicate = [1.0, NaN, NaN, 5.0]
    ffill!(vec_inplace_predicate; predicate=isnan)
    test_array(vec_inplace_predicate, [1.0, 1.0, 1.0, 5.0])

    vec_noop = [1, missing, 3]
    ffill!(vec_noop, 0)
    test_array(vec_noop, [1, missing, 3])
end

@testitem "bfill" setup = [SharedImputation] begin
    using Test
    using DataFrames
    using QuantUtils: bfill

    df = DataFrame(; A=[1, NaN, 3, missing], B=[missing, 2, missing, 4])

    # Basic functionality test
    test_array(bfill(df).A, [1, 3, 3, missing])
    # Test with skip_cols to target specific columns
    test_array(bfill(df; skip_cols=["A"]).B, [2, 2, 4, 4])
    test_array(bfill(df; skip_cols=["A"]).A, df.A)
    # Test with skip_cols
    test_array(bfill(df; skip_cols=["B"]).A, [1, 3, 3, missing])
    test_array(bfill(df; skip_cols=["B"]).B, df.B)
    # Custom predicate function
    test_array(bfill(df; predicate=ismissing).A, [1, NaN, 3, missing])
end

@testitem "bfill!" setup = [SharedImputation] begin
    using Test
    using DataFrames
    using QuantUtils: bfill!

    df = DataFrame(; A=[1, NaN, 3, missing], B=[missing, 2, missing, 4])

    # Basic functionality test
    test_array(bfill!(copy(df)).A, [1, 3, 3, missing])
    # Test with skip_cols to target specific columns
    test_array(bfill!(copy(df); skip_cols=["A"]).B, [2, 2, 4, 4])
    test_array(bfill!(copy(df); skip_cols=["A"]).A, df.A)
    # Test with skip_cols
    test_array(bfill!(copy(df); skip_cols=["B"]).A, [1, 3, 3, missing])
    test_array(bfill!(copy(df); skip_cols=["B"]).B, df.B)
    # Custom predicate function
    test_array(bfill!(copy(df); predicate=ismissing).A, [1, NaN, 3, missing])
end

@testitem "bfill vector" setup = [SharedImputation] begin
    using Test
    using QuantUtils: bfill, bfill!

    vec = [missing, 2, missing, 4]
    test_array(bfill(vec), [2, 2, 4, 4])
    test_array(vec, [missing, 2, missing, 4])

    vec_with_limit = [missing, missing, 3]
    test_array(bfill(vec_with_limit, 1), [missing, 3, 3])

    vec_predicate = [0.0, NaN, NaN, 5.0]
    test_array(bfill(vec_predicate; predicate=isnan), [0.0, 5.0, 5.0, 5.0])
    test_array(vec_predicate, [0.0, NaN, NaN, 5.0])

    vec_inplace = [missing, missing, missing, 5]
    bfill!(vec_inplace, 2)
    test_array(vec_inplace, [missing, 5, 5, 5])

    vec_inplace_predicate = [0.0, NaN, NaN, 5.0]
    bfill!(vec_inplace_predicate; predicate=isnan)
    test_array(vec_inplace_predicate, [0.0, 5.0, 5.0, 5.0])

    vec_noop = [missing, 2, missing]
    bfill!(vec_noop, 0)
    test_array(vec_noop, [missing, 2, missing])
end

@testitem "fillnan vector" setup = [SharedImputation] begin
    using Test
    using QuantUtils: fillnan, fillnan!

    vec = [1.0, NaN, 3.0]
    test_array(fillnan(vec, 0.0), [1.0, 0.0, 3.0])
    test_array(vec, [1.0, NaN, 3.0])

    vec_inplace = [NaN, 2.0, NaN]
    fillnan!(vec_inplace, -1.0)
    test_array(vec_inplace, [-1.0, 2.0, -1.0])

    vec_with_missing = [missing, 5.0]
    fillnan!(vec_with_missing, 10.0)
    test_array(vec_with_missing, [missing, 5.0])
end

@testitem "fillnan dataframe" setup = [SharedImputation] begin
    using Test
    using DataFrames
    using QuantUtils: fillnan, fillnan!

    df = DataFrame(; A=[1.0, NaN, 3.0], B=["a", "b", "c"])
    df_filled = fillnan(df, 0.0)
    test_array(df_filled.A, [1.0, 0.0, 3.0])
    @test df_filled.B == df.B
    test_array(df.A, [1.0, NaN, 3.0])

    df_inplace = DataFrame(; A=[NaN, 2.0], B=[NaN, 4.0])
    fillnan!(df_inplace, 7.0; skip_cols=["B"])
    test_array(df_inplace.A, [7.0, 2.0])
    test_array(df_inplace.B, [NaN, 4.0])

    df_missing = DataFrame(; A=[missing, 1.0], B=[NaN, 3.0])
    fillnan!(df_missing, 9.0)
    test_array(df_missing.A, [missing, 1.0])
    test_array(df_missing.B, [9.0, 3.0])
end
