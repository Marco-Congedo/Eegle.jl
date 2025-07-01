# v 0.1 Nov 2019
# v 0.2 June 2025
# Part of the Eegle.jl package.
# Copyright Marco Congedo, CNRS, University Grenoble Alpes.


module Preprocessing

using StatsBase, Statistics, LinearAlgebra, DSP, PosDefManifold

import DSP:resample
import StatsBase.standardize

export
    standardize,
    resample,
    removeChannels,
    removeSamples,
    embedLags

"""
```julia
    function standardize(X::AbstractArray{T}; 
        robust = false,
        prop::Real = 0.2) 
    where T<:Real
```
Standardize the whole ``T×N`` EEG recording `X`, where ``T`` and ``N`` denotes the number of samples and channels (sensors), respectively, using: 
- the arithmetic mean and standard deviation if `robust` is false (default)
- the Winsorized (trimmed) mean and standard deviation if `robust` is true.

The trimmed statistics are computed excluding the `prop` proportion of data at both sides (default=0.2),
thus, `prop` is used only if `robust` is true.

**Example**
```julia
using Eegle # or using Eegle.Preprocessing

X=randn(1024, 19)

stX=standardize(X)

stX=standardize(X; robust=true, prop=0.1)
```
"""
function standardize(X::AbstractArray{T}; robust = false, prop::Real=0.20) where T<:Real
    vec=X[:]
    if robust
        μ=mean(winsor(vec; prop=prop))
        σ=√trimvar(vec; prop=prop)
    else
        μ=mean(vec)
        σ=std(vec; mean=μ)
    end

    return  ((X.-μ)./σ) 
end

"""
```julia
    function resample(  X::AbstractMatrix{T},
                        sr::S,
                        rate::Union{T, S, Rational};
        rel_bw::Float64 = 1.0,
        attenuation::Int = 60,
        stim::Union{Vector{S}, Nothing} = nothing) 
    where {T<:Real, S<:Int}
```
Resampling of the ``T×N`` EEG recording `X`, where ``T`` and ``N`` denotes the number of samples and channels (sensors), respectively,
using the polyphase FIR filter with Kaiser window filter taps,  
as per the [resample](https://docs.juliadsp.org/stable/filters/#DSP.Filters.resample) method in DSP.jl.

For [kwarg](#Acronyms) `rel_bw` and `attenuation` — see [resample](https://docs.juliadsp.org/stable/filters/#DSP.Filters.resample).

If a [stimulation vector](@ref) `stim` is passed as kwarg, It will be resampled so as to match the resampling of `X`
as precisely as possible. `stim` must be a vector of ``T`` integers.

!!! tip "Resampling"
    If you need to work with individual trials, do not resample trials individually; rather, resample the whole EEG recording and then
    extract the trials. Function [`Eegle.InOut.readNY`](@ref) allows you to do resampling and extract trials this way.

!!! warning "Real resampling rate"
    The use of real resampling rates need to be tested

**Examples**
```julia
using Eegle # or using Eegle.Preprocessing

sr = 128
X = randn(sr*10, 19)

Y=resample(X, sr, 1//4) # downsample by a factor 4

Y=resample(X, sr, 2) # upsample by a factor 2, i.e., double the sampling rate
```
"""
function resample(X::AbstractMatrix{T},
                  sr::S,
                  rate::Union{T, S, Rational};
                  rel_bw::T = 1.0,
                  attenuation::S = 60,
                  stim::Union{Vector{S}, Nothing} = nothing) where {T<:Real, S<:Int}


    if rate==1 return stim===nothing ? X : (X, stim) end
    newsr=round(Int, sr*rate)

    # This may be necessary: must be tested with rate a real number
    # sr*rate-newsr≠0 && throw(ArgumentError("resample function: sr*rate must be an integer"))

    # resample data
    ne = size(X, 2) # of electrodes
    h = DSP.resample_filter(rate, rel_bw, attenuation)
    # first see how long will be the resampled data
    x = DSP.resample(X[:, 1], rate, h)
    t = length(x)
    Y = Matrix{eltype(X)}(undef, t, ne)
    Y[:, 1] = x
    for i=2:ne
        Y[:, i] = DSP.resample(X[:, i], rate, h)
    end

    # resample stimulation channel
    if stim≠nothing
        newstim=zeros(Int, t) 
        for i=1:length(stim)
            if stim[i]≠0
                newsample=clamp(round(Int, i/sr*newsr), 1, t)
                newstim[newsample]=stim[i]
            end
        end
    end
    return stim===nothing ? Y : (Y, newstim)

end



"""
```julia
    function removeChannels(X::AbstractMatrix{T}, 
                            what::Union{Int, Vector{S}},
                            sensors::Vector{String}) 
    where {T<:Real, S<:Int}

```
Remove one or more channels, i.e., columns, from the ``T×N`` EEG recording `X`, 
where ``T`` and ``N`` denotes the number of samples and channels (sensors), respectively,
and remove the corresponding elements from `sensors`, the provided associated vector of ``N`` sensor labels.

For the use of [kwarg](#Acronyms) `what` — see method [`Eegle.Miscellaneous.remove`](@ref), which can be used if all you need is to remove channels from `X`.

Return the 3-tuple (`newX`, `s`, `ne`), where `newX` is the new EEG recording, `s` is the new sensor labels vector and
`ne` is the new number of channels (sensors) in `newX`.

**See Also** [`Eegle.InOut.readSensors`](@ref)

**Examples**
```julia
using Eegle # or using Eegle.Preprocessing

# xxx load data

# remove second channel
X, sensors, ne = removeChannels(X, 2, sensors)

# remove the first five channels
X, sensors, ne = removeChannels(X, collect(1:5), sensors)

# remove the channel labeled as 'Cz' in `sensors`
X, sensors, ne = removeChannels(X, findfirst(x->x=="Cz", sensors), sensors)
```
"""
function removeChannels(X::AbstractMatrix{T}, what::Union{Int, Vector{S}},
                       sensors::Vector{String}) where {T<:Real, S<:Int}
    di = findfirst(length(sensors).==(size(X)))
    X = Eegle.Miscellaneous.remove(X, what; dims=di)
    return X, Eegle.Miscellaneous.remove(sensors, what), size(X, di)
end


"""
```julia
    function removeSamples( X::AbstractMatrix{T}, 
                            what::Union{Int, Vector{S}},
                            stim::Vector{String}) 
    where {T<:Real, S<:Int}

```
Remove one or more samples, i.e., rows, from the ``T×N`` EEG recording `X`, 
where ``T`` and ``N`` denotes the number of samples and channels (sensors), respectively,
and remove the corresponding elements from `stim`, the associated [stimulation vector](@ref).

For the use of kwarg `what` — see method [`Eegle.Miscellaneous.remove`](@ref), which can be used instead if all you need is to remove samples from `X`.

Print a warning if elements in `what` correspond to non-zero tags in `stim`.

Return the 3-tuple (`newX`, `s`, `ne`), where `newX` is the new data, `s` is the new stimulation vector and
`ns` is the new number of samples in `newX`.

**Examples**
```julia
using Eegle

# load data xxx

# remove second sample
X, stim, ne = removeSamples(X, 2, stim)

# remove the first 128 samples
X, stim, ne = removeSamples(X, collect(1:128), stim)

# remove every other sample
X, stim, ne = removeSamples(X, collect(1:2:length(stim)), stim)
```
"""
function removeSamples(X::AbstractMatrix{T}, what::Union{Int, Vector{S}},
                       stim::Vector{String}) where {T<:Real, S<:Int}
    di = findfirst(length(stim).==(size(X)))
    X = Eegle.Miscellaneous.remove(X, what; dims=di)
    if what isa Int
        stim[what]==0 || @warn "Eegle.Preprocessing, `removeSample` function: tag at position $(what) with value $(stim[what]) has been removed"
    else
        positions = [i for i∈what if stim[i]≠0]
        tags = [stim[i] for i∈what if stim[i]≠0]
        isempty(check) || @warn "Eegle.Preprocessing, `removeSample` function: tags have been removed" positions tags
    end
    return X, Eegle.Miscellaneous.remove(stim, what), size(X, di)
end


"""
```julia
    function embedLags( X::AbstractMatrix{T}, 
                        lags = 0) 
    where T<:Real 
```
Lag-embedding is a technique to augment the data. Second-order statistics of the augmented data, that is, covariance or cross-spectral matrices,
hold information not only of volume condution and instantaneous connectivity, but also of lagged connectivity.
These matrices can be used, for example, in blind source separation
and Riemannian classification.

Given the ``T×N`` EEG recording `X`, where ``T`` and ``N`` denotes the number of samples and channels (sensors), respectively, 
and ``L>0`` `lags`, return the ``T×N(L+1)`` lag-embedded data matrix 

```math
X_{\\text{lags}} = \\left[ 
X^{(0)} \\;\\; X^{(1)} \\;\\; \\cdots \\;\\; X^{(L)}
\\right]
```

where, letting ``\\mathbf{0}_{A \\times B}`` the ``A \\times B`` matrix of zeros,
for each ``l = 0, \\ldots, L``, the ``T×N`` lagged partition ``X^{(l)}`` is defined as

```math
X^{(l)} = \\left[
\\begin{matrix}
\\mathbf{0}_{(L - l) \\times N} \\\\
X[1:(T - L), \\: :] \\\\
\\mathbf{0}_{l \\times N}
\\end{matrix}
\\right].
```

Notice that the are no zeros appended to the first partition and no zeros prepended to the last partition.
Notice also that the lag-embedded data has the same size of the input, however the last ``L`` samples are lost.

**Example**
```julia
using Eegle # or using Eegle.Preprocessing

X=randn(1024, 19)

elX=emdedLags(X, 4)
```
"""
function embedLags(X::AbstractMatrix{T}, lags = 0) where T<:Real 
    ne = size(X, 2)
    if lags>0
        return hcat((vcat(zeros(T, lags-l, ne), X[1:end-lags, :], zeros(T, l, ne)) for l=0:lags)...)
    else
        return X
    end
end


end # module


# useful code:

# of classes, 0 is no stimulation and is excluded
# z=length(unique(stim))-1

# vector with number of stim. for each class 1, 2, ...
# nTrials=counts(stim, z) # or: [count(x->x==i, stim) for i=1:z]
