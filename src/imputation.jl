using DataFrames

"""
    ffill!(df::AbstractDataFrame, where=isnan; cols=names(df), ignore_cols=nothing, fill=(curr, prev) -> prev)

Forward-fill missing values in a dataframe.
The operation is performed in-place.
Note that the very first value is never filled.

Parameters
----------
- `df`: The data frame to modify.
- `where`: A function to check if a value is considered missing. Default fills "missing" and "NaN" values.
- `cols`: Columns to apply the forward-filling. Default is all columns.
- `ignore_cols`: Columns to skip from forward-filling. Default is `nothing` (don't skip any columns).
- `fill`: Function to get fill value. Default is to use preceding value.
"""
function ffill!(
    df::AbstractDataFrame;
    where=x -> ismissing(x) || isnan(x),
    cols=names(df),
    ignore_cols=nothing,
    fill::F=(curr, prev) -> prev,
) where {F<:Function}
    !isnothing(ignore_cols) && (ignore_cols = Set(String(x) for x in ignore_cols))
    for col in cols
        !isnothing(ignore_cols) && (String(col) in ignore_cols) && continue
        vals = df[!, col]
        @inbounds for i in (firstindex(vals) + 1):lastindex(vals)
            if where(vals[i])
                vals[i] = fill(vals[i], vals[i - 1])
            end
        end
    end
    df
end

"""
    ffill(df::AbstractDataFrame, where=isnan; cols=names(df), ignore_cols=nothing, fill=(curr, prev) -> prev)

Forward-fill missing values in a dataframe.
The operation is performed on a copy of the dataframe.
Note that the very first value is never filled.

Parameters
----------
- `df`: The data frame to modify.
- `where`: A function to check if a value is considered missing. Default fills "missing" and "NaN" values.
- `cols`: Columns to apply the forward-filling. Default is all columns.
- `ignore_cols`: Columns to skip from forward-filling. Default is `nothing` (don't skip any columns).
- `fill`: Function to get fill value. Default is to use preceding value.
"""
function ffill(
    df::AbstractDataFrame;
    where=x -> ismissing(x) || isnan(x),
    cols=names(df),
    ignore_cols=nothing,
    fill::F=(curr, prev) -> prev,
) where {F<:Function}
    ffill!(copy(df); where=where, cols=cols, ignore_cols=ignore_cols, fill=fill)
end

"""
    bfill!(df::AbstractDataFrame, where=isnan; cols=names(df), ignore_cols=nothing, fill=(curr, prev) -> prev)

Backward-fill missing values in a dataframe.
The operation is performed in-place.
Note that the very last value is never filled.

Parameters
----------
- `df`: The data frame to modify.
- `where`: A function to check if a value is considered missing. Default fills "missing" and "NaN" values.
- `cols`: Columns to apply the backward-filling. Default is all columns.
- `ignore_cols`: Columns to skip from backward-filling. Default is `nothing` (don't skip any columns).
- `fill`: Function to get fill value. Default is to use preceding value.
"""
function bfill!(
    df::AbstractDataFrame;
    where=x -> ismissing(x) || isnan(x),
    cols=names(df),
    ignore_cols=nothing,
    fill::F=(curr, prev) -> prev,
) where {F<:Function}
    !isnothing(ignore_cols) && (ignore_cols = Set(String(x) for x in ignore_cols))
    for col in cols
        !isnothing(ignore_cols) && (String(col) in ignore_cols) && continue
        vals = df[!, col]
        @inbounds for i in (lastindex(vals) - 1):-1:firstindex(vals)
            if where(vals[i])
                vals[i] = fill(vals[i], vals[i + 1])
            end
        end
    end
    df
end

"""
    bfill(df::AbstractDataFrame, where=isnan; cols=names(df), ignore_cols=nothing, fill=(curr, prev) -> prev)

Backward-fill missing values in a dataframe.
The operation is performed on a copy of the dataframe.
Note that the very last value is never filled.

Parameters
----------
- `df`: The data frame to modify.
- `where`: A function to check if a value is considered missing. Default fills "missing" and "NaN" values.
- `cols`: Columns to apply the backward-filling. Default is all columns.
- `ignore_cols`: Columns to skip from backward-filling. Default is `nothing` (don't skip any columns).
- `fill`: Function to get fill value. Default is to use preceding value.
"""
function bfill(
    df::AbstractDataFrame;
    where=x -> ismissing(x) || isnan(x),
    cols=names(df),
    ignore_cols=nothing,
    fill::F=(curr, prev) -> prev,
) where {F<:Function}
    bfill!(copy(df); where=where, cols=cols, ignore_cols=ignore_cols, fill=fill)
end

export ffill, ffill!, bfill, bfill!