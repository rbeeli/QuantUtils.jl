import Base: findmin, findmax

@inline function _findext(
    iter, # The iterable to search
    predicate::F, # The predicate function to filter elements
    better::B, # The comparison function to determine "better" element
) where {F<:Function,B<:Function}
    best_idx = -1
    best_val = nothing

    for (i, val) in enumerate(iter)
        predicate(val) || continue

        if best_idx == -1 || better(val, best_val)
            best_idx = i
            best_val = val
        end
    end

    best_val, best_idx
end

"""
    findmin(collection, predicate)

Return `(value, index)` only considering elements of `collection` for which
`predicate(value)` evaluates to `true`.
Returns `(nothing, -1)` if no element satisfies the predicate.
"""
@inline function findmin(collection, predicate::F) where {F<:Function}
    _findext(collection, predicate, isless)
end

"""
    findmax(collection, predicate)

Return `(value, index)` only considering elements of `collection` for which
`predicate(value)` evaluates to `true`.
Returns `(nothing, -1)` if no element satisfies the predicate.
"""
@inline function findmax(collection, predicate::F) where {F<:Function}
    _findext(collection, predicate, (a, b) -> isless(b, a))
end
