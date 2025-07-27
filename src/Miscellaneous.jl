# v 0.1 Nov 2019
# Part of the Eegle.jl package.
# Copyright Marco Congedo, CNRS, University Grenoble Alpes.

module Miscellaneous

using PosDefManifold: AnyMatrix

# ? ¤ CONTENT ¤ ? 

# waste     | free the memory for all objects passed as arguments
# charlie   | exit a function printing a message in one line
# remove    | remove one or several elements from arrays
# isSquare  | check if a matrix is square
# minima    | local minima of a sequence
# maxima    | local maxima of a sequence


import Eegle

# Module REPL text colors
const titleFont     = "\x1b[95m"
const separatorFont = "\x1b[35m"
const defaultFont   = "\x1b[0m"
const greyFont      = "\x1b[90m"

export
    remove,
    isSquare,
    minima,
    maxima,
    waste,
    charlie

"""
```julia
    function remove(X::Union{Vector, Matrix}, 
                    what::Union{Int, Vector{Int}}; 
        dims=1)
```
Return vector `X` removing one or more elements, or matrix `X` removing one or more
columns or rows.

If `X` is a matrix, `dims`=1 (default) remove rows,
`dims`=2 remove columns.

If `X` is a Vector, `dims` has no effect.

The `what` argument can be either an integer or a vector of integers

**See Also** [`Eegle.Preprocessing.removeSamples`](@ref), [`Eegle.Preprocessing.removeChannels`](@ref)

**Examples**
```julia
using Eegle # or using Eegle.Miscellaneous

a=randn(5)
b=remove(a, 2) # remove second element
b=remove(a, collect(1:3)) # remove rows 1 to 3

A=randn(3, 3)
B=remove(A, 2) # remove second row
B=remove(A, 2; dims=2) # remove second column

A=randn(5, 5)
B=remove(A, collect(1:2:5)) # remove rows 1, 3 and 5
C=remove(A, [1, 4]) # remove rows 1 and 4

# remove columns 2, 3, 8, 9, 10
A=randn(10, 10)
B=remove(A, [collect(2:3); collect(8:10)]; dims=2)

# remove every other sample (decimation by a factor of 2)
A=randn(10, 10)
B=remove(A, collect(1:2:size(A, 1)); dims=1)

# NB: before decimating the data must be low-pass filtered,
# see the documentation of `resample`
```
"""
function remove(X::Union{Vector, Matrix}, what::Union{Int, Vector{Int}}; dims=1)
    1<dims<2 && throw(ArgumentError("function `remove`: the `dims` keyword argument must be 1 or 2"))
    di = X isa Vector ? 1 : dims
    d = size(X, di)
    mi, ma = minimum(what), maximum(what)
    (1≤mi≤d && 1≤ma≤d) || throw(ArgumentError("function `remove`: the second argument must hold elements comprised in between 1 and $d. Check also the `dims` keyword"))
    b = filter(what isa Int ? x->x≠what : x->x∉what, 1:d)
    return X isa Vector ? X[b] : X[di==1 ? b : 1:end, di==2 ? b : 1:end]
end

"""
```julia
  function isSquare(X)
```
Return true if `X` is an [AnyMatrix](https://marco-congedo.github.io/PosDefManifold.jl/stable/MainModule/#AnyMatrix-type)
and is square, false otherwise.
"""
function isSquare(X) 
  X isa PosDefManifold.AnyMatrix && (size(X, 1)==size(X, 2))
end


"""
```julia
    function minima(v::AbstractVector{T}) 
    where T<:Real
```
Return the 2-tuple formed by the vector of local minima of vector `v` and the
vector of the indices of `v` corresponding to the minima.

This is useful in several situations. For example, **Eegle** uses it to segment spontaneous EEG data (see [`Eegle.Processing.epoching`](@ref)).
"""
function minima(v::AbstractVector{T}) where T<:Real
    m=Int[]
    value=Float64[]
    for i=2:length(v)-1
        if v[i-1]>v[i]<v[i+1] 
            push!(m, i)
            push!(value, v[i])
        end
    end
    return m, value
end

"""
```julia
    function maxima(v::AbstractVector{T}) 
    where T<:Real
```
Return the 2-tuple formed by the vector of local maxima of vector `v` and the
vector of the indices of `v` corresponding to the maxima.

"""
function maxima(v::AbstractVector{T}) where T<:Real
    m=Int[]
    value=Float64[]
    for i=2:length(v)-1
        if v[i-1]<v[i]>v[i+1] 
            push!(m, i)
            push!(value, v[i])
        end
    end
    return m, value
end


# xxx
# Force garbage collector to free memory for all arguments passed as `args...`.
# Must be revised.
# See [here](https://github.com/JuliaCI/BenchmarkTools.jl/pull/22)
function waste(args...)
  for a in args a=nothing end
  for i=1:4 GC.gc(true) end
end

# xxx
# if b is true, print a warning with the `msg` and return true,
# otherwise return false. This is used within functions
# to make a check and if necessary print a message and return.
# Example: charlie(type ≠ :s && type ≠ :t, "my message") && return
charlie(b::Bool, msg::String; fb::Symbol=:warn) =
  if        fb==:warn b ? (@warn msg; return true) : return false
  elseif    fb==:error b ? (@error msg; return true) : return false
  elseif    fb==:info b ? (@info msg; return true) : return false
  end


end # module
