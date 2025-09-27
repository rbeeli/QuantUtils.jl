"""
    split_parts(mat::AbstractMatrix, parts; axis=1)

Split a matrix `mat` into multiple parts along the specified `axis`.

Parameters
----------
- `mat`: The matrix to split.
- `parts`: The number of parts or a sequence of breakpoints.
- `axis`: Axis along which to split (1 for rows, 2 for columns). Default is 1.

Returns a tuple of split matrices.
"""
function split_parts(mat::T, parts; axis=1) where {T<:AbstractMatrix}
    splits = split_parts_to_indices(size(mat, axis), parts)

    # split matrix into parts
    if axis == 1
        tuple([mat[(splits[i] + 1):splits[i + 1], :] for i in 1:(length(splits) - 1)]...)
    elseif axis == 2
        tuple([mat[:, (splits[i] + 1):splits[i + 1]] for i in 1:(length(splits) - 1)]...)
    else
        throw(ArgumentError("Invalid axis parameter: $axis"))
    end
end

"""
    split_parts(vec::AbstractVector, parts; axis=1)

Split a vector `vec` into multiple parts.

Parameters
----------
- `vec`: The vector to split.
- `parts`: The number of parts or a sequence of breakpoints.
- `axis`: Only 1 is valid for vectors.

Returns a tuple of split vectors.
"""
function split_parts(vec::T, parts; axis=1) where {T<:AbstractVector}
    axis == 1 || error("Vectors can only be split along the first axis (axis=1)")
    splits = split_parts_to_indices(size(vec, axis), parts)
    tuple([vec[(splits[i] + 1):splits[i + 1]] for i in 1:(length(splits) - 1)]...)
end

"""
    split_parts(df::AbstractDataFrame, parts; axis=1)

Split a data frame `df` into multiple parts along the specified `axis`.

Parameters
----------
- `df`: The data frame to split.
- `parts`: The number of parts or a sequence of breakpoints.
- `axis`: Axis along which to split (1 for rows, 2 for columns). Default is 1.

Returns a tuple of split data frames.
"""
function split_parts(df::T, parts; axis=1) where {T<:AbstractDataFrame}
    splits = split_parts_to_indices(size(df, axis), parts)

    # split dataframe into parts
    if axis == 1
        tuple([df[(splits[i] + 1):splits[i + 1], :] for i in 1:(length(splits) - 1)]...)
    elseif axis == 2
        tuple([df[:, (splits[i] + 1):splits[i + 1]] for i in 1:(length(splits) - 1)]...)
    else
        throw(ArgumentError("Invalid axis parameter: $axis"))
    end
end

"""
    split_parts_to_indices(total_length, parts)

Split a sequence of length `total_length` into multiple parts.
The passed `parts` parameter must be non-negative fractions which must sum to 1.

Parameters
----------
- `total_length`: The total length of the sequence to partition.
- `parts`: List of fractions to split sequence by. Must sum to 1.
"""
function split_parts_to_indices(total_length, parts)
    sum(parts) ≈ 1.0 || throw(ArgumentError("Parts do not sum to 1."))
    all(parts .>= 0.0) || throw(ArgumentError("Parts cannot be negative."))

    # compute split indices
    splits = [0; cumsum(floor.(Int, [x * total_length for x in parts]))]

    # adjust last split to always include last row/column due to rounding
    splits[end] = total_length

    splits
end

export split_parts, split_parts_to_indices