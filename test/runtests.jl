using Test
using QuantUtils

# To run a subset of tests, call Pkg.test as follows:
#
#   Pkg.test("QuantUtils", test_args=["combinatorics.jl"])
#   Pkg.test("QuantUtils", test_args=["conversion.jl"])
#   Pkg.test("QuantUtils", test_args=["imputation.jl"])
#   Pkg.test("QuantUtils", test_args=["partition.jl"])
#   Pkg.test("QuantUtils", test_args=["rolling.jl"])

requested_tests = ARGS

if isempty(requested_tests)
    include("combinatorics.jl")
    include("conversion.jl")
    include("imputation.jl")
    include("partition.jl")
    include("rolling.jl")
else
    println('-' ^ 60)
    println("Running subset of tests:")
    for test in requested_tests
        println("  $test")
    end
    println('-' ^ 60)

    for test in requested_tests
        include(test)
    end
end
