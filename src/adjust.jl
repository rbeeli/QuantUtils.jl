"""
	shift!(series, shift; fill_value)

Edit `series` in-place by displacing every element by `shift` positions.

- `shift > 0` -> data move **forward** (toward larger indices)
- `shift < 0` -> data move **backward** (toward smaller indices)

The resulting gap on either end is filled with `fill_value` value.

Returns the mutated `series` to support call chaining.
"""
function shift!(
    series::AbstractVector{T}, #
    shift::Int;
    fill_value::T,
)::AbstractVector{T} where {T}
    n = length(series)
    n == 0 && return series

    if shift == 0
        return series
    end

    if abs(shift) ≥ n
        fill!(series, fill_value)
        return series
    end

    if shift > 0
        @inbounds for idx in n:-1:(shift + 1)
            series[idx] = series[idx - shift]
        end
        fill!(view(series, 1:shift), fill_value)
    else
        k = -shift
        @inbounds for idx in 1:(n - k)
            series[idx] = series[idx + k]
        end
        fill!(view(series, (n - k + 1):n), fill_value)
    end

    series
end

"""
	shift(series, shift; fill_value)

Return a **new** vector where every element of `series` is displaced by `shift` positions.

- `shift > 0` -> data move **forward** (toward larger indices)
- `shift < 0` -> data move **backward** (toward smaller indices)

The resulting gap on either end is filled with `fill_value` value.
"""
function shift(
    series::AbstractVector{T}, #
    shift::Int;
    fill_value::T,
)::AbstractVector{T} where {T}
    shift!(copy(series), shift; fill_value=fill_value)
end

export shift!, shift
