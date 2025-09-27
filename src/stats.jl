using Statistics
using DataStructures
using Random: AbstractRNG

"""
    mse(y, yhat)

Return the mean squared error between two equal-length series.
"""
function mse(y::AbstractVector{<:Real}, yhat::AbstractVector{<:Real})
    @assert length(y) == length(yhat) "inputs must have the same length"
    T = promote_type(eltype(y), eltype(yhat))
    s = zero(T)

    @inbounds for i in eachindex(y, yhat)
        diff = T(y[i]) - T(yhat[i])
        s += diff * diff
    end

    s / length(y)
end

"""
    sample_range_uniform(rng, min_value, max_value, step, current_value)

Pick a new value from the inclusive range, stepping by `step`, that differs from `current_value` when possible.
If only one value is available it returns that value.
"""
function sample_range_uniform(rng::AbstractRNG, min_value, max_value, step, current_value)
    @assert step != 0 "step must be non-zero"
    if min_value == max_value
        return min_value
    end
    choices = min_value:step:max_value
    if length(choices) == 1
        return first(choices)
    end
    value = current_value
    while value == current_value
        value = rand(rng, choices)
    end
    value
end

"""
    nanquantile(vec, q)

Return the `q` quantile of `vec`, skipping any `NaN` values.
Returns `NaN` if no valid numbers remain.
"""
function nanquantile(vec, q)
    clean = vec[.!isnan.(vec)]
    isempty(clean) && return float(eltype(vec))(NaN)
    quantile(clean, q)
end

"""
    iqr(data)

Return the interquartile range of `data`.
"""
function iqr(data)
    q3 = quantile(data, 0.75)
    q1 = quantile(data, 0.25)
    q3 - q1
end

"""
    calc_rolling_mean(series, window)

Compute the trailing moving average with window size `window`.
For the first `window-1` points it returns the average of the
available prefix (expanding window).
Returns a vector of the same element type as `float(eltype(series))`.
"""
function calc_rolling_mean(series::AbstractVector, window::Integer)
    @assert window > 0 "window must be a positive integer"

    n = length(series)
    T = float(eltype(series))
    out = Vector{T}(undef, n)
    runsum = zero(T)
    inv_win = inv(one(T) * window) # 1 / window  (pre-compute)

    @inbounds @simd for i in 1:n
        x = series[i]
        runsum += x
        if i > window
            runsum -= series[i - window]
        end

        # Use pre-computed reciprocal once the full window is reached
        out[i] = i < window ? runsum / i : runsum * inv_win
    end

    out
end

"""
    calc_rolling_std(series, window)

Numerically stable rolling sample standard deviation using
Welford's algorithm.
"""
function calc_rolling_std(series::AbstractVector, window::Integer)
    n = length(series)
    T = float(eltype(series))
    out = Vector{T}(undef, n)

    # Trivial fast path
    if window == 1
        fill!(out, zero(T))
        return out
    end

    buf = Vector{T}(undef, window)   # circular buffer
    idx = 1                          # slot holding the *oldest* sample
    count = 0                        # current window size (<= window)
    mean = zero(T)
    m2 = zero(T)                     # Σ (x - mean)²

    @inbounds for i in 1:n
        x = T(series[i])

        # -----------------------------------------------------------
        # 1. Remove the oldest value if the window is already full
        # -----------------------------------------------------------
        if count == window
            x_old = buf[idx]
            oldcnt = count                      # == window
            Δ_old = x_old - mean
            mean -= Δ_old / (oldcnt - 1)       # West (1979)
            m2 -= Δ_old * (x_old - mean)     # must use *new* mean
            count -= 1                          # now window-1 samples
        end

        # -----------------------------------------------------------
        # 2. Add the new value
        # -----------------------------------------------------------
        buf[idx] = x                            # overwrite the oldest slot
        count += 1
        Δ = x - mean
        mean += Δ / count
        m2 += Δ * (x - mean)

        # advance ring index to the next oldest element
        idx = (idx % window) + 1

        # -----------------------------------------------------------
        # 3. Emit sample standard deviation
        # -----------------------------------------------------------
        out[i] = (count > 1) & (m2 >= 0) ? sqrt(m2 / (count - 1)) : zero(T)
    end

    out
end

"""
    calc_ewm_mean(series, span; adjust=false)

Exponentially-weighted moving average (EWMA) identical to
`pandas.Series.ewm(span=span, adjust=adjust).mean()`.

* `series`  - any `AbstractVector`.
* `span`    - same meaning as Pandas:
              `alpha = 2 / (span + 1)`.
* `adjust`  - `false` (default): recursive form
              `yₜ = α·xₜ + (1-α)·yₜ₋₁`.
              `true` : divides by the running sum of weights so the
              result is an honest mean of the exponentially-decaying
              weights.

Returns a `Vector{float(eltype(series))}`.
"""
function calc_ewm_mean(series::AbstractVector, span::Real; adjust::Bool=true)
    @assert span > 0 "span must be positive"

    n = length(series)
    T = float(eltype(series))
    α = T(2) / (T(span) + one(T))       # α = 2/(span+1)
    onemα = one(T) - α                   # pre-compute 1-α

    out = Vector{T}(undef, n)

    if adjust
        # unbiased formulation: keep separate numerator & denominator
        num = zero(T)
        denom = zero(T)
        @inbounds @simd for i in 1:n
            x = T(series[i])
            num = i == 1 ? x : x + onemα * num
            denom = i == 1 ? one(T) : one(T) + onemα * denom
            out[i] = num / denom
        end
    else
        # recursive smoother (fast path, what most people expect)
        s = zero(T)
        @inbounds @simd for i in 1:n
            x = T(series[i])
            s = i == 1 ? x : α * x + onemα * s
            out[i] = s
        end
    end

    out
end

"""
    calc_ewm_std(series, span; bias=false)

Exponentially weighted moving standard deviation compatible with
`pandas.Series.ewm(span=span, adjust=false, bias=bias).std()`.

* `bias = false` - sample std (Bessel-corrected)
* `bias = true`  - population std

Time/space: O(1).
"""
function calc_ewm_std(series::AbstractVector, span; bias::Bool=false)
    α = 2 / (span + 1)
    decay = 1 - α
    T = float(eltype(series))
    out = similar(series, T)

    w = wsq = μ = m2 = zero(T)          # Σw, Σw², mean, Σw·(x-μ)²

    @inbounds for (i, x_raw) in pairs(series)
        x = T(x_raw)

        # decay previous aggregates
        w *= decay
        wsq *= decay^2
        m2 *= decay                     # same rate as weights

        # add new weight/observation
        w_new = α
        w += w_new
        wsq += w_new^2

        Δ = x - μ
        μ += (w_new / w) * Δ
        m2 += w_new * Δ * (x - μ)

        denom = bias ? w : w - wsq / w   # pandas’ effective-dof
        out[i] = denom > 0 ? sqrt(m2 / denom) : T(NaN)
    end

    out
end

"""
    calc_rolling_average(method, series, window)

Dispatch to the requested rolling statistic (`:sma`, `:ema`, or `:median`).
"""
function calc_rolling_average(
    method::Symbol, series::AbstractVector{T}, window::Integer
) where {T<:Real}
    if method === :sma
        calc_rolling_mean(series, window)
    elseif method === :ema
        calc_ewm_mean(series, window)
    elseif method === :median
        calc_rolling_median(series, window)
    else
        throw(ErrorException("rolling average method '$method' not supported."))
    end
end

"""
    calc_rolling_min(series, window)

Return the trailing minimum over `window` points with expanding warm-up.
"""
function calc_rolling_min(series::AbstractVector, window::Integer)
    @assert window > 0 "window must be a positive integer"

    n = length(series)
    out = similar(series, n)
    dq = CircularDeque{Int}(window)        # stores indices, min at the front

    @inbounds for i in 1:n
        # Drop expired index from the front
        if !isempty(dq) && first(dq) <= i - window
            popfirst!(dq)
        end

        # Maintain monotonicity: strip larger (or equal) elements from the back
        while !isempty(dq) && series[last(dq)] >= series[i]
            pop!(dq)
        end

        push!(dq, i)                    # push current index
        out[i] = series[first(dq)]          # current minimum
    end

    out
end

"""
    calc_rolling_max(series, window)

Return the trailing maximum over `window` points with expanding warm-up.
"""
function calc_rolling_max(series::AbstractVector, window::Integer)
    @assert window > 0 "window must be a positive integer"

    n = length(series)
    out = similar(series, n)
    dq = CircularDeque{Int}(window)        # max at the front

    @inbounds for i in 1:n
        if !isempty(dq) && first(dq) <= i - window
            popfirst!(dq)
        end

        while !isempty(dq) && series[last(dq)] <= series[i]
            pop!(dq)
        end

        push!(dq, i)
        out[i] = series[first(dq)]
    end

    out
end

# -------------------------------------------------------------

mutable struct RollingQuantile{T}
    q::Float64
    lo::BinaryMaxHeap{T}
    hi::BinaryMinHeap{T}
    delayed::Dict{T,Int}
    lo_sz::Int
    hi_sz::Int
end

function RollingQuantile{T}(q::Real) where {T}
    RollingQuantile{T}(Float64(q), BinaryMaxHeap{T}(), BinaryMinHeap{T}(), Dict{T,Int}(), 0, 0)
end

@inline function _rq_total(rq::RollingQuantile)
    rq.lo_sz + rq.hi_sz
end

@inline function _rq_prune!(
    heap::Union{BinaryMaxHeap{T},BinaryMinHeap{T}}, rq::RollingQuantile{T}, is_lo::Bool
) where {T}
    while !isempty(heap)
        v = first(heap)
        pending = get(rq.delayed, v, 0)
        pending == 0 && return nothing
        pop!(heap)
        if is_lo
            rq.lo_sz -= 1
        else
            rq.hi_sz -= 1
        end
        if pending == 1
            delete!(rq.delayed, v)
        else
            rq.delayed[v] = pending - 1
        end
    end
end

@inline function _rq_target(rq::RollingQuantile)
    cnt = _rq_total(rq)
    if cnt == 0
        return 0
    end
    clamp(floor(Int, (cnt - 1) * rq.q + 1), 1, cnt)
end

@inline function _rq_rebalance!(rq::RollingQuantile{T}) where {T}
    target = _rq_target(rq)

    while rq.lo_sz > target
        push!(rq.hi, pop!(rq.lo))
        rq.lo_sz -= 1
        rq.hi_sz += 1
    end
    while rq.lo_sz < target && rq.hi_sz > 0
        push!(rq.lo, pop!(rq.hi))
        rq.lo_sz += 1
        rq.hi_sz -= 1
    end

    _rq_prune!(rq.lo, rq, true)
    _rq_prune!(rq.hi, rq, false)
    return nothing
end

@inline function _rq_push!(rq::RollingQuantile{T}, x::T) where {T}
    _rq_prune!(rq.lo, rq, true)
    if rq.lo_sz == 0 || x <= first(rq.lo)
        push!(rq.lo, x)
        rq.lo_sz += 1
    else
        push!(rq.hi, x)
        rq.hi_sz += 1
    end
    _rq_rebalance!(rq)
end

@inline function _rq_remove!(rq::RollingQuantile{T}, x::T) where {T}
    _rq_prune!(rq.lo, rq, true)
    _rq_prune!(rq.hi, rq, false)
    if rq.lo_sz > 0 && x <= first(rq.lo)
        rq.lo_sz -= 1
    else
        rq.hi_sz -= 1
    end
    rq.delayed[x] = get(rq.delayed, x, 0) + 1
    _rq_rebalance!(rq)
end

@inline function _rq_value(rq::RollingQuantile{T}) where {T}
    cnt = _rq_total(rq)
    if cnt == 0
        return T(NaN)
    end

    _rq_prune!(rq.lo, rq, true)
    _rq_prune!(rq.hi, rq, false)
    lower = rq.lo_sz == 0 ? first(rq.hi) : first(rq.lo)

    pos = (cnt - 1) * rq.q + 1
    base = floor(Int, pos)
    gamma = pos - base

    if gamma == 0 || rq.hi_sz == 0
        return lower
    end

    upper = first(rq.hi)
    lower + T(gamma) * (upper - lower)
end

"""
    calc_rolling_zscore(series, window)

Return a trailing z-score where each point is scaled by the windowed mean and standard deviation.
"""
function calc_rolling_zscore(series::AbstractVector{T}, window::Integer) where {T<:Real}
    @assert window > 0 "window must be positive"

    OutT = float(T)
    n = length(series)
    n == 0 && return OutT[]

    out = Vector{OutT}(undef, n)

    if window == 1
        fill!(out, zero(OutT))
        return out
    end

    buf = Vector{OutT}(undef, window)
    idx = 1
    count = 0
    mean = zero(OutT)
    m2 = zero(OutT)

    @inbounds for i in 1:n
        x = OutT(series[i])

        if count == window
            x_old = buf[idx]
            oldcnt = count
            delta_old = x_old - mean
            mean -= delta_old / (oldcnt - 1)
            m2 -= delta_old * (x_old - mean)
            count -= 1
        end

        buf[idx] = x
        count += 1
        delta = x - mean
        mean += delta / count
        m2 += delta * (x - mean)
        idx = (idx % window) + 1

        if count > 1
            variance = max(m2 / (count - 1), zero(OutT))
            std = sqrt(variance)
            out[i] = std > zero(OutT) ? (x - mean) / std : zero(OutT)
        else
            out[i] = zero(OutT)
        end
    end

    out
end

"""
    calc_rolling_zscore(series, window, ::Val{:robust})

Return a trailing z-score where each point is scaled by the windowed median and IQR.
Falls back to zero when the window has no spread.
"""
function calc_rolling_zscore(
    series::AbstractVector{T}, window::Integer, ::Val{:robust}
) where {T<:Real}
    @assert window > 0 "window must be positive"

    OutT = float(T)
    n = length(series)
    n == 0 && return OutT[]

    out = Vector{OutT}(undef, n)
    rq_q1 = RollingQuantile{OutT}(0.25)
    rq_med = RollingQuantile{OutT}(0.5)
    rq_q3 = RollingQuantile{OutT}(0.75)

    @inbounds for i in 1:n
        x = OutT(series[i])
        _rq_push!(rq_q1, x)
        _rq_push!(rq_med, x)
        _rq_push!(rq_q3, x)

        if i > window
            old = OutT(series[i - window])
            _rq_remove!(rq_q1, old)
            _rq_remove!(rq_med, old)
            _rq_remove!(rq_q3, old)
        end

        if _rq_total(rq_med) < 2
            out[i] = zero(OutT)
            continue
        end

        μ = _rq_value(rq_med)
        q1 = _rq_value(rq_q1)
        q3 = _rq_value(rq_q3)

        # (x[end] - median(x)) / std(x)
        scale = q3 - q1
        out[i] = isfinite(scale) && !iszero(scale) ? (x - μ) / scale : zero(OutT)
    end

    out
end

"""
    calc_rolling_median(series, window)

Return the running median of `series` with a sliding window of length `window`.
The first `window-1` outputs are medians of the *partial* prefix (size `1, 2, …`).
"""
function calc_rolling_median(series::AbstractVector{T}, window::Integer) where {T<:Real}
    @assert window >= 1 "window must be positive"
    n = length(series)
    OutT = float(T)
    out = Vector{OutT}(undef, n)

    rq = RollingQuantile{OutT}(0.5)

    for i in 1:n
        # insert new value -------------------------------------------------
        x = OutT(series[i])
        _rq_push!(rq, x)

        # evict oldest if window exceeded ---------------------------------
        if i > window
            old = OutT(series[i - window])
            _rq_remove!(rq, old)
        end

        # emit median ------------------------------------------------------
        count = _rq_total(rq)
        out[i] = count == 0 ? zero(OutT) : _rq_value(rq)
    end

    out
end

export nanquantile,
    sample_range_uniform,
    iqr,
    mse,
    calc_rolling_zscore,
    calc_rolling_mean,
    calc_rolling_std,
    calc_ewm_mean,
    calc_ewm_std,
    calc_rolling_median,
    calc_rolling_average,
    calc_rolling_min,
    calc_rolling_max
