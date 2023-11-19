"""
    params_combinations(params; filter, shuffle)

Creates a list of Dict with all possible combinates of the provided
parameters. Each element of the list represents a parameter-set.
Optionally, a filter function can be supplied for invalid and/or
unwanted parameter-sets.

# Arguments
- `params`:  Dict where each key holds a list with all possible values.
- `filter`:  Optional function for filtering parameter-sets. Return false
             to omit a given parameter-set.
             Example: `filter=x -> x[:key1] > 0.5 || x[:key2] < 1.0`
- `shuffle`: Randomly shuffles returned combinations if set to true.

# Returns
List of Dict with (filtered) parameter-sets.

# Examples
```jldoctest
julia> params_combinations(Dict("wnd" => [1,2,3], :mode => ["A"], "coef" => [0.1, 0.5, 1.0]))
9-element Array{Dict{Any,Any},1}:
    Dict("wnd" => 1,:mode => "A","coef" => 0.1)
    Dict("wnd" => 1,:mode => "A","coef" => 0.5)
    Dict("wnd" => 1,:mode => "A","coef" => 1.0)
    Dict("wnd" => 2,:mode => "A","coef" => 0.1)
    Dict("wnd" => 2,:mode => "A","coef" => 0.5)
    Dict("wnd" => 2,:mode => "A","coef" => 1.0)
    Dict("wnd" => 3,:mode => "A","coef" => 0.1)
    Dict("wnd" => 3,:mode => "A","coef" => 0.5)
    Dict("wnd" => 3,:mode => "A","coef" => 1.0)
julia>
julia> params = Dict(:wnd => [1,2], :mode => ["A", "B"], :coef => [0.1, 0.5]);
julia> filter = x -> x[:mode] != "A" || x[:wnd] > 1;
julia> params_combinations(params; filter=filter)
6-element Array{Dict{Any,Any},1}:
    Dict(:mode => "A",:wnd => 2,:coef => 0.1)
    Dict(:mode => "A",:wnd => 2,:coef => 0.5)
    Dict(:mode => "B",:wnd => 1,:coef => 0.1)
    Dict(:mode => "B",:wnd => 1,:coef => 0.5)
    Dict(:mode => "B",:wnd => 2,:coef => 0.1)
    Dict(:mode => "B",:wnd => 2,:coef => 0.5)
```
"""
function params_combinations(
    params;      # ::Dict{Any, Vector{Any}};
    filter::TF=x -> true,
    shuffle=false
) where {TF<:Function}
    # recursive implementation
    result = Vector{Dict{keytype(params),eltype(valtype(params))}}()
    tmp_keys = collect(keys(params))
    tmp_values = Vector{eltype(valtype(params))}(undef, length(params))
    params_combinations_internal(params, filter, result, 1, tmp_keys, tmp_values)
    shuffle && shuffle!(result)
    result
end

function params_combinations_internal(
    params,
    filter::TF,
    result,
    key_pos,
    tmp_keys,
    tmp_values
) where {TF<:Function}
    if key_pos <= length(params)
        key_params = params[tmp_keys[key_pos]]
        for param in key_params
            # set param value for this iteration
            tmp_values[key_pos] = param

            # call recursively for next set of values of one parameter
            params_combinations_internal(params, filter, result, key_pos + 1, tmp_keys, tmp_values)
        end
    else
        # parameter-set finished, add to result set
        new_parameterset = Dict{keytype(params),eltype(valtype(params))}(zip(tmp_keys, tmp_values))

        # check filter function
        if filter(new_parameterset)
            push!(result, new_parameterset)
        end
    end
    return # if-block returns a value otherwise
end
