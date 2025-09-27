using DataFrames

"""
Return the smallest value that appears in any of the provided series.

Accepts any mix of iterable inputs.
"""
@inline multi_minimum(series...) = mapreduce(minimum, min, series)

"""
Return the largest value that appears in any of the provided series.

Use when you need the overall ceiling across multiple scenarios.
"""
@inline multi_maximum(series...) = mapreduce(maximum, max, series)

"""
Return the combined growth factor implied by the incremental returns in `vec`.

Each element is interpreted as a fractional change (0.05 ≈ 5%).
"""
function prod1p(vec)
    s = one(eltype(vec))
    @inbounds for x in vec
        s *= one(x) + x
    end
    s
end

"""
Return the running combined growth factor derived from the values in `vec`.

Useful for turning periodic returns into a growth curve.
"""
function cumprod1p(vec::AbstractVector{T}) where {T}
    n = length(vec)
    out = similar(vec, T, n)
    acc = one(T)
    @inbounds for i in 1:n
        acc *= one(T) + vec[i]
        out[i] = acc
    end
    out
end

"""
Calculates cumprod(1 + x) where NaN values are ignored.
"""
function nancumprod1p(series::AbstractVector{<:AbstractFloat})
    res = similar(series)
    acc = one(eltype(series))
    @inbounds for (i, x) in pairs(series)
        if isnan(x)
            res[i] = acc
        else
            acc *= one(eltype(series)) + x
            res[i] = acc
        end
    end
    res
end

"""
Return percentage changes between consecutive entries of `x`.

The first value is set to `first_value` (default `NaN`); empty inputs stay empty.
"""
function pct_change(x::AbstractVector; first_value=NaN)
    n = length(x)
    y = similar(x, promote_type(eltype(x), Float64))
    n == 0 && return y
    @inbounds y[1] = first_value
    @inbounds @simd for i in 2:n
        y[i] = x[i] / x[i - 1] - 1
    end
    y
end

"""
Calculate simple or log returns for the price columns in `df`.

The first observation in each series is marked with `NaN`. Use `skip_cols`
for identifiers that should pass through untouched, and `max_nan_skip` to
avoid computing across long data gaps.
"""
function calc_returns(
    ::Type{T}, #
    df::AbstractDataFrame;
    skip_cols=nothing,
    log_returns::Bool=false,
    max_nan_skip::Int=0,
) where {T<:AbstractFloat}
    df = copy(df)
    skip_set = isnothing(skip_cols) ? nothing : Set(skip_cols)
    @inbounds for col in names(df)
        skip_set !== nothing && col in skip_set && continue

        prices = df[!, col]
        returns = fill(T(NaN), length(prices))

        # track the last valid price and consecutive NaN count
        last_valid_price = T(NaN)
        nan_count = 0

        @inbounds for i in eachindex(prices)
            raw_price = prices[i]

            if ismissing(raw_price)
                nan_count += 1
                continue
            end

            price = T(raw_price)

            # If current price is NaN, increment NaN counter
            if isnan(price)
                nan_count += 1
                continue
            end

            # If we have a valid price now
            if !isnan(last_valid_price)
                # Check if we've exceeded the max NaN skip limit
                if nan_count <= max_nan_skip
                    # Calculate return despite NaN values in between
                    if log_returns
                        if last_valid_price > 0
                            returns[i] = log(price / last_valid_price)
                        end
                    else
                        if last_valid_price != 0
                            returns[i] = price / last_valid_price - 1
                        end
                    end
                end
                # Reset NaN counter since we found a valid price
                nan_count = 0
            end

            # Update last valid price
            last_valid_price = price
        end

        df[!, col] = returns
    end
    df
end

function calc_returns(
    df::AbstractDataFrame; #
    skip_cols=nothing,
    log_returns::Bool=false,
    max_nan_skip::Int=0,
)
    calc_returns(
        Float64, #
        df;
        skip_cols=skip_cols,
        log_returns=log_returns,
        max_nan_skip=max_nan_skip,
    )
end

export multi_minimum, multi_maximum, prod1p, cumprod1p, nancumprod1p, pct_change, calc_returns
