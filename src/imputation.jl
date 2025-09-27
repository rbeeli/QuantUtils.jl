using DataFrames

"""
        ffill!(df::AbstractDataFrame; predicate=x -> ismissing(x) || isnan(x), skip_cols=nothing)

Mutate `df` in-place by replacing every value that satisfies `predicate` with the
most recent preceding value in the same column that does not satisfy `predicate`.
The first row of each column is left unchanged because there is no earlier value
to copy from.

Arguments
---------
- `df`: Data frame whose columns are forward-filled column-by-column.
- `predicate`: Function used to decide which entries are considered missing and
    should be replaced. The default treats `missing` and `NaN` as fill targets.
- `skip_cols`: Optional collection of column identifiers that should be skipped
    entirely. Any identifiers accepted by `names(df)` are allowed.

Returns
-------
- The modified `df`, to allow call chaining.
"""
function ffill!(
    df::AbstractDataFrame; #
    predicate=x -> ismissing(x) || isnan(x),
    skip_cols=nothing,
)
    skip_set = isnothing(skip_cols) ? nothing : Set(skip_cols)
    for col in names(df)
        skip_set !== nothing && (col in skip_set) && continue
        vals = df[!, col]
        @inbounds for i in (firstindex(vals) + 1):lastindex(vals)
            if predicate(vals[i]) && !predicate(vals[i - 1])
                vals[i] = vals[i - 1]
            end
        end
    end
    df
end

"""
        ffill(df::AbstractDataFrame; predicate=x -> ismissing(x) || isnan(x), skip_cols=nothing)

Create and return a new data frame in which each column of `df` has been
forward-filled: every value that satisfies `predicate` is replaced by the most
recent preceding value in the same column that does not satisfy `predicate`.
Columns listed in `skip_cols` are left unmodified in the result.

Arguments
---------
- `df`: Data frame whose copy will be forward-filled.
- `predicate`: Function that marks values requiring imputation. Defaults to
    replacing `missing` and `NaN` entries.
- `skip_cols`: Optional collection of column identifiers that should be
    excluded from the operation.

Returns
-------
- A new `DataFrame` with the requested columns forward-filled.
"""
function ffill(
    df::AbstractDataFrame; #
    predicate=x -> ismissing(x) || isnan(x),
    skip_cols=nothing,
)
    ffill!(copy(df); predicate=predicate, skip_cols=skip_cols)
end

"""
        ffill!(vec::AbstractVector, limit=typemax(Int); predicate=x -> ismissing(x) || isnan(x))

Mutate `vec` by scanning from left to right and replacing consecutive values
that satisfy `predicate` with the most recent preceding value that does not
satisfy it. The first element always remains unchanged.

Arguments
---------
- `vec`: Vector whose contents are updated in-place.
- `limit`: Maximum number of consecutive replacements allowed after each valid
    value. Set to `typemax(Int)` (the default) to allow unlimited filling or to `0`
    to disable filling altogether.
- `predicate`: Function that labels values as missing. Defaults to treating
    `missing` and `NaN` entries as fill targets.

Returns
-------
- The mutated `vec`, enabling call chaining.
"""
function ffill!(
    vec::AbstractVector, #
    limit::Int=typemax(Int);
    predicate=x -> ismissing(x) || isnan(x),
)
    isempty(vec) && return vec
    limit <= 0 && return vec
    last_idx = firstindex(vec)
    has_last = false
    consecutive = 0
    @inbounds for idx in eachindex(vec)
        val = vec[idx]
        if predicate(val)
            if has_last && consecutive < limit
                prev_val = vec[last_idx]
                if !predicate(prev_val)
                    vec[idx] = prev_val
                    last_idx = idx
                    has_last = true
                    consecutive += 1
                end
            end
        else
            last_idx = idx
            has_last = true
            consecutive = 0
        end
    end
    vec
end

"""
    ffill(vec::AbstractVector, limit=typemax(Int); predicate=x -> ismissing(x) || isnan(x))

Return a copy of `vec` in which consecutive entries that satisfy `predicate`
are replaced by the most recent preceding value that does not satisfy it. The
first element is preserved, and the number of consecutive replacements is
limited by `limit` just as in `ffill!`.

Arguments
---------
- `vec`: Vector from which the copy is created.
- `limit`: Maximum number of consecutive replacements performed while scanning.
- `predicate`: Function that identifies values to replace; defaults to filling
    `missing` and `NaN` values.

Returns
-------
- A new vector containing the forward-filled data.
"""
function ffill(
    vec::AbstractVector, #
    limit::Int=typemax(Int);
    predicate=x -> ismissing(x) || isnan(x),
)
    ffill!(copy(vec), limit; predicate=predicate)
end

"""
        bfill!(df::AbstractDataFrame; predicate=x -> ismissing(x) || isnan(x), skip_cols=nothing)

Mutate `df` in-place by replacing every value that satisfies `predicate` with the
next non-matching value found when scanning downward within the same column. The
last row of each column is left unchanged for lack of a following value.

Arguments
---------
- `df`: Data frame whose columns are backward-filled column-by-column.
- `predicate`: Function used to identify values that should be replaced. The
    default targets `missing` and `NaN` values.
- `skip_cols`: Optional collection of column identifiers to leave untouched.

Returns
-------
- The modified `df`, allowing call chaining.
"""
function bfill!(
    df::AbstractDataFrame; #
    predicate=x -> ismissing(x) || isnan(x),
    skip_cols=nothing,
)
    skip_set = isnothing(skip_cols) ? nothing : Set(skip_cols)
    for col in names(df)
        skip_set !== nothing && (col in skip_set) && continue
        vals = df[!, col]
        @inbounds for i in (lastindex(vals) - 1):-1:firstindex(vals)
            if predicate(vals[i]) && !predicate(vals[i + 1])
                vals[i] = vals[i + 1]
            end
        end
    end
    df
end

"""
        bfill(df::AbstractDataFrame; predicate=x -> ismissing(x) || isnan(x), skip_cols=nothing)

Create and return a new data frame in which each column of `df` has been
backward-filled: every value that satisfies `predicate` is replaced by the next
value in the same column that does not satisfy `predicate`. Columns specified in
`skip_cols` remain untouched.

Arguments
---------
- `df`: Data frame whose copy will be backward-filled.
- `predicate`: Function designating values for replacement, defaulting to
    `missing` and `NaN`.
- `skip_cols`: Optional collection of column identifiers to exclude from the
    operation.

Returns
-------
- A new `DataFrame` with the requested columns backward-filled.
"""
function bfill(
    df::AbstractDataFrame; #
    predicate=x -> ismissing(x) || isnan(x),
    skip_cols=nothing,
)
    bfill!(copy(df); predicate=predicate, skip_cols=skip_cols)
end

"""
        bfill!(vec::AbstractVector, limit=typemax(Int); predicate=x -> ismissing(x) || isnan(x))

Mutate `vec` by scanning from right to left and replacing consecutive values
that satisfy `predicate` with the next value that does not satisfy it. The final
element is never modified because there is no later value available.

Arguments
---------
- `vec`: Vector whose contents are updated in-place.
- `limit`: Maximum length of each backward-filling streak. Use `typemax(Int)`
    (default) for no limit or `0` to disable filling.
- `predicate`: Function labelling values for replacement. Defaults to treating
    `missing` and `NaN` values as fill targets.

Returns
-------
- The mutated `vec`, so the call can be chained.
"""
function bfill!(
    vec::AbstractVector, #
    limit::Int=typemax(Int);
    predicate=x -> ismissing(x) || isnan(x),
)
    isempty(vec) && return vec
    limit <= 0 && return vec
    next_idx = lastindex(vec)
    has_next = false
    consecutive = 0
    @inbounds for idx in reverse(eachindex(vec))
        val = vec[idx]
        if predicate(val)
            if has_next && consecutive < limit
                next_val = vec[next_idx]
                if !predicate(next_val)
                    vec[idx] = next_val
                    next_idx = idx
                    has_next = true
                    consecutive += 1
                end
            end
        else
            next_idx = idx
            has_next = true
            consecutive = 0
        end
    end
    vec
end

"""
    bfill(vec::AbstractVector, limit=typemax(Int); predicate=x -> ismissing(x) || isnan(x))

Return a copy of `vec` where sequences of values that satisfy `predicate` are
replaced by the next value that does not satisfy it. The last element is
preserved, and the `limit` keyword bounds the number of consecutive
replacements.

Arguments
---------
- `vec`: Vector from which the copy is created.
- `limit`: Maximum number of consecutive replacements allowed while scanning
    backward.
- `predicate`: Function indicating which values should be replaced, defaulting
    to `missing` and `NaN` targets.

Returns
-------
- A new vector containing the backward-filled data.
"""
function bfill(
    vec::AbstractVector, #
    limit::Int=typemax(Int);
    predicate=x -> ismissing(x) || isnan(x),
)
    bfill!(copy(vec), limit; predicate=predicate)
end

export ffill, ffill!, bfill, bfill!