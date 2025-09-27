"""
    nan_to_zero(x)

Converts `NaN` to `0` and leaves other values unchanged.
Zero is evaluated based on the type of `x` for type stability.
"""
@inline nan_to_zero(x) = isnan(x) ? zero(x) : x

"""
    nan_to_one(x)

Converts `NaN` to `1` and leaves other values unchanged.
Zero is evaluated based on the type of `x` for type stability.
"""
@inline nan_to_one(x) = isnan(x) ? one(x) : x

"""
    nan_to_x(x, nan_value)

Converts `NaN` to `nan_value` and leaves other values unchanged.
"""
@inline nan_to_x(x, nan_value) = isnan(x) ? nan_value : x

"""
    inf_to_nan(x)

Converts `Inf` and `-Inf` to `NaN` and leaves other values unchanged.
NaN values are left unchanged.
"""
@inline inf_to_nan(x) = isinf(x) ? NaN : x

export nan_to_x, nan_to_zero, nan_to_one
