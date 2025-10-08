# QuantUtils.jl

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Utility functions commonly used in Quantitative Finance and Machine Learning.
The functions make use of multiple dispatch and aim to be type stable for best performance.

The package aims to be lightweight with minimal dependencies.

## Functions

### Combinatorics

```julia
params_combinations(params; filter, shuffle)
```

### Conversion

```julia
nan_to_zero(x)
nan_to_one(x)
nan_to_x(x, nan_value)
inf_to_nan(x)
```

### Imputation

```julia
ffill(df::AbstractDataFrame; predicate=x -> ismissing(x) || isnan(x), skip_cols=nothing)
ffill!(df::AbstractDataFrame; predicate=x -> ismissing(x) || isnan(x), skip_cols=nothing)
bfill(df::AbstractDataFrame; predicate=x -> ismissing(x) || isnan(x), skip_cols=nothing)
bfill!(df::AbstractDataFrame; predicate=x -> ismissing(x) || isnan(x), skip_cols=nothing)
ffill(vec::AbstractVector, limit::Int=typemax(Int); predicate=x -> ismissing(x) || isnan(x))
ffill!(vec::AbstractVector, limit::Int=typemax(Int); predicate=x -> ismissing(x) || isnan(x))
bfill(vec::AbstractVector, limit::Int=typemax(Int); predicate=x -> ismissing(x) || isnan(x))
bfill!(vec::AbstractVector, limit::Int=typemax(Int); predicate=x -> ismissing(x) || isnan(x))
fillnan(df::AbstractDataFrame, value; skip_cols=nothing)
fillnan!(df::AbstractDataFrame, value; skip_cols=nothing)
fillnan(vec::AbstractVector, value)
fillnan!(vec::AbstractVector, value)
```

### Partitioning

```julia
split_parts(mat::AbstractMatrix, parts; axis=1)
split_parts(vec::AbstractVector, parts; axis=1)
split_parts(df::AbstractDataFrame, parts; axis=1)
split_parts_to_indices(total_length, parts)
```

### Window functions

```julia
rolling_apply(
    vec::V,
    window::Int,
    fn::F
    ;
    step::Int=1,
    item_type=eltype(vec),
    running::Bool=false,
    parallel::Bool=false
) where {V<:AbstractVector,F<:Function}

rolling_apply(
    mat::M,
    window::Int,
    fn::F
    ;
    dim::Int=1, # dimension to apply function along (1=rows, 2=columns)
    step::Int=1,
    item_type=eltype(mat),
    running::Bool=false,
    parallel::Bool=false
) where {M<:AbstractMatrix,F<:Function}
```

## Dependencies

- [DataFrames.jl](https://dataframes.juliadata.org/stable/)
