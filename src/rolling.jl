
# # helper function to get the least specific return type of a function
# @inline fn_return_type(fn) = Base.return_types(fn)[max(1, end-1)]
# @inline fn_return_type(fn, typs) = Base.return_types(fn, typs)[max(1, end-1)]

function rolling_apply(
    vec::V,
    window::Int,
    fn::F;
    step::Int=1,
    item_type=eltype(vec),
    running::Bool=false,
    parallel::Bool=false,
) where {V<:AbstractVector,F<:Function}
    n = length(vec)

    if running
        # start at index `1` and
        # expand window until window length is reached
        n_out = max(0, ceil(Int, n / step))
        start_index = firstindex(vec)
    else
        # start at index `window` in order to
        # always have a full window
        n_out = max(0, ceil(Int, (n - window + 1) / step))
        start_index = firstindex(vec) + window - 1
    end

    # pre-allocate typed output vector
    output = Vector{item_type}(undef, n_out)

    # iterate over indices and use views to get window data
    function loop_body(ix, i)
        # get window data as view
        wnd_range = max(1, i - window + 1):i
        wnd_vals = @view vec[wnd_range]

        # apply window function
        output[ix] = fn(wnd_vals; i=i, r=wnd_range)
    end

    if parallel
        # multi-threading
        @inbounds Threads.@threads for (ix, i) in
                                       collect(enumerate(start_index:step:lastindex(vec)))
            loop_body(ix, i)
        end
    else
        @inbounds for (ix, i) in collect(enumerate(start_index:step:lastindex(vec)))
            loop_body(ix, i)
        end
    end

    output
end

function rolling_apply(
    mat::M,
    window::Int,
    fn::F;
    dim::Int=1, # dimension to apply function along (1=rows, 2=columns)
    step::Int=1,
    item_type=eltype(mat),
    running::Bool=false,
    parallel::Bool=false,
) where {M<:AbstractMatrix,F<:Function}
    n = size(mat, dim)

    if running
        # start at index `1` and
        # expand window until window length is reached
        n_out = max(0, ceil(Int, n / step))
        start_index = firstindex(mat, dim)
    else
        # start at index `window` in order to
        # always have a full window
        n_out = max(0, ceil(Int, (n - window + 1) / step))
        start_index = firstindex(mat, dim) + window - 1
    end

    # pre-allocate typed output matrix
    if dim == 1
        output = Matrix{item_type}(undef, n_out, size(mat, 2))
    else
        output = Matrix{item_type}(undef, size(mat, 1), n_out)
    end

    # iterate over indices and use views to get window data
    function loop_body(ix, i)
        # get window data as view
        wnd_range = max(1, i - window + 1):i
        wnd_vals = selectdim(mat, dim, wnd_range)

        # apply window function
        fn_out = fn(wnd_vals; i=i, r=wnd_range)

        if dim == 1
            output[ix, :] .= view(fn_out, :) # flatten if matrix
        else
            output[:, ix] .= view(fn_out, :) # flatten if matrix
        end
    end

    if parallel
        # multi-threading
        @inbounds Threads.@threads for (ix, i) in
                                       collect(enumerate(start_index:step:lastindex(mat, dim)))
            loop_body(ix, i)
        end
    else
        @inbounds for (ix, i) in enumerate(start_index:step:lastindex(mat, dim))
            loop_body(ix, i)
        end
    end

    output
end

# function rolling_apply_slices(
#     mat::V,
#     window::Int,
#     fn::F
#     ;
#     dim::Int=1, # dimension to apply function along (1=rows, 2=columns)
#     step::Int=1,
#     slice_item_type=eltype(mat),
#     running::Bool=false
# ) where {V<:AbstractMatrix,F<:Function}
#     reduce(vcat, map(x -> rolling_apply(
#             x, window, fn
#             ;
#             step=step,
#             item_type=slice_item_type,
#             running=running
#         ), eachslice(mat; dims=dim)))
# end

# function rolling_apply(
#     mat::Matrix
#     ;
#     look_back::Int,
#     fn::F,
#     step::Int=1,
#     eltype::Type=eltype(mat)
# ) where {F<:Function}
#     n_source = size(mat, 1)
#     n_out = max(0, ceil(Int, (n_source - look_back + 1) / step))
#     outputs = Vector{eltype}(undef, n_out) # pre-allocate
#     @inbounds for (index, i) in enumerate(look_back:step:n_source)
#         wnd_range = i-look_back+1:i
#         wnd_vals = @view mat[wnd_range, :]
#         output = fn(wnd_vals; i=i, r=wnd_range)
#         outputs[index] = output
#     end
#     outputs
# end

# function rolling_apply(df::AbstractDataFrame; look_back::Int, fn::F, step::Int=1, eltype::Type=Any) where {F<:Function}
#     n_source = nrow(df)
#     n_out = max(0, ceil(Int, (n_source - look_back + 1) / step))
#     outputs = Vector{eltype}(undef, n_out) # pre-allocate
#     @inbounds for (index, i) in enumerate(look_back:step:n_source)
#         wnd_range = i-look_back+1:i
#         wnd_vals = @view df[wnd_range, :]
#         output = fn(wnd_vals; i=i, r=wnd_range)
#         outputs[index] = output
#     end
#     outputs
# end

# function rolling_look_around_apply(df::AbstractDataFrame, look_back::Int, look_ahead::Int, fn::Function; step::Int=1)
#     outputs = []
#     @inbounds for i = look_back:step:nrow(df)-look_ahead
#         range_back = i-look_back+1:i
#         range_ahead = i+1:i+look_ahead
#         df_back = @view df[range_back, :]
#         df_ahead = @view df[range_ahead, :]
#         output = fn(df_back, df_ahead, i, range_back, range_ahead)
#         push!(outputs, output)
#     end
#     outputs
# end

# function rolling_look_around_apply(mat::Matrix, look_back::Int, look_ahead::Int, fn::Function; step::Int=1)
#     outputs = []
#     @inbounds for i = look_back:step:size(mat, 1)-look_ahead
#         range_back = i-look_back+1:i
#         range_ahead = i+1:i+look_ahead
#         mat_back = @view mat[range_back, :]
#         mat_ahead = @view mat[range_ahead, :]
#         output = fn(mat_back, mat_ahead, i, range_back, range_ahead)
#         push!(outputs, output)
#     end
#     outputs
# end

export rolling_apply
