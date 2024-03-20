# QuantUtils.jl

Utility functions commonly used in Quantitative Finance and Machine Learning.

The package aims to be lightweight with minimal dependencies.

## Dependencies

- [DataFrames.jl](https://dataframes.juliadata.org/stable/)

## Functions

### Combinatorics

* `params_combinations`

### Conversion

* `nan_to_x`
* `nan_to_zero`

### Imputation

* `ffill`
* `ffill!`
* `bfill`
* `bfill!`

### Partitioning

* `split_parts`
* `split_parts_to_indices`

### Window functions

* `rolling_look_around_apply`
* `rolling_apply`
* `rolling_apply_slices`
