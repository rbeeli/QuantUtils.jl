module QuantUtils

include("combinatorics.jl")
export params_combinations


include("conversion.jl")
export nan_to_x, nan_to_zero


include("imputation.jl")
export ffill, ffill!, bfill, bfill!


include("partition.jl")
export split_parts, split_parts_to_indices


include("rolling.jl")
export rolling_look_around_apply, rolling_apply, rolling_apply_slices

end