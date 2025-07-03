# v 0.1 Nov 2019
# v 0.2 June 2025
# Part of the Eegle.jl package.
# Copyright Marco Congedo, CNRS, University Grenoble Alpes.


module Preprocessing

using StatsBase, Statistics, LinearAlgebra, DSP, PosDefManifold

import DSP:resample
import StatsBase.standardize

import Eegle

# Module REPL text colors
const titleFont     = "\x1b[95m"
const separatorFont = "\x1b[35m"
const defaultFont   = "\x1b[0m"
const greyFont      = "\x1b[90m"

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
- the arithmetic mean and standard deviation of all data in `X` if `robust` is false (default)
- the Winsorized (trimmed) mean and standard deviation of all data in `X` if `robust` is true.

The trimmed statistics are computed excluding the `prop` proportion of data at both sides (default=0.2),
thus, `prop` is used only if `robust` is true.

**Example**
```julia
using Eegle # or using Eegle.Preprocessing

X = randn(1024, 19)

stX = standardize(X)

stX = standardize(X; robust=true, prop=0.1)
```
"""
function standardize(X::AbstractArray{T}; robust = false, prop::Real=0.20) where T<:Real
    vec=X[:]
    if robust
        μ = mean(winsor(vec; prop=prop))
        σ = √trimvar(vec; prop=prop)
    else
        μ = mean(vec)
        σ = std(vec; mean=μ)
    end

    return  (X.-μ)./σ
end

"""
```julia
    function resample(  X::AbstractMatrix{T},
                        sr::S,
                        rate::Union{T, S, Rational};
        Nϕ::Integer = 32,
        rel_bw::Float64 = 1.0,
        attenuation::Int = 60,
        stim::Union{Vector{S}, Nothing} = nothing) 
    where {T<:Real, S<:Int}
```
Resampling of an EEG data matrix using the polyphase FIR filter with Kaiser window filter taps,  
as per the [resample](https://docs.juliadsp.org/stable/filters/#DSP.Filters.resample) method in DSP.jl.

**Arguments**
- `X`: the ``T×N`` EEG matrix, where ``T`` and ``N`` denotes the number of samples and channels (sensors), respectively
- `sr`: the original sampling rate of `X`
- `rate`: the resampled data will have sampling rate `sr` * `rate`.

**Optional Keyword Arguments**
- `Nϕ`, `rel_bw` and `attenuation`: see [resample](https://docs.juliadsp.org/stable/filters/#DSP.Filters.resample).
- a [stimulation vector](@ref). If it is passed, it will be resampled so as to match the resampling of `X` as precisely as possible. `stim` must be a vector of ``T`` integers.

!!! tip "Resampling"
    If you need to work with individual trials (or epochs), do not resample trials individually; rather, resample the whole EEG recording and then
    extract the trials — see [`Eegle.ERPs.trials`](@ref). Function [`Eegle.InOut.readNY`](@ref) allows you to do resampling and extract trials this way.

!!! warning "Downsampling"
    Downsampling must be always preceeded by low-pass filtering to ensure the suppression of all energies above the Nyquist frequency (``s/2``),
    where ``s`` is the new sampling rate after downsampling. The cut_off frequencies is usually taken as ``s/3`` and a sharp filter is used (see examples). 
    This applies also if you wish to apply downsampling by decimation — see the examples for decimating in [`Eegle.Miscellaneous.remove`](@ref) and [`removeSamples`](@ref).

**Return** the resampled data matrix.   

**Examples**
```julia
using Eegle # or using Eegle.Preprocessing

sr = 512
X = randn(sr*10, 19)

# low-pass filter at s/3 = sr/(4*3) Hz and downsample by a factor 4
Z = filtfilt(X, sr, Bandpass(1, sr/(4*3)); designMethod = Butterworth(8))
Y = resample(Z, sr, 1//4) 

Y = resample(X, sr, 2) # upsample by a factor 2, i.e., double the sampling rate

sr = 100
X = randn(sr*10, 19)
Y = resample(X, sr, 128/sr) # upsample to 128 samples per second
```
"""
function resample(X::AbstractMatrix{T},
                  sr::S,
                  rate::Union{T, S, Rational};
                Nϕ::Integer = 32,
                rel_bw::T = 1.0,
                attenuation::S = 60,
                stim::Union{Vector{S}, Nothing} = nothing) where {T<:Real, S<:Int}


    if rate≈1 return stim===nothing ? X : (X, stim) end
    newsr = round(Int, sr*rate)

    # This may be necessary: must be tested with rate a real number
    # sr*rate-newsr≠0 && throw(ArgumentError("resample function: sr*rate must be an integer"))

    # resample data
    ne = size(X, 2) # of electrodes
    h = (rate isa Int || rate isa Rational) ?   DSP.resample_filter(rate, rel_bw, attenuation) :
                                                DSP.resample_filter(rate, Nϕ, rel_bw, attenuation)
                                                    
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
        newstim = zeros(Int, t) 
        for i = 1:length(stim)
            if stim[i]≠0
                newsample = clamp(round(Int, i/sr*newsr), 1, t)
                newstim[newsample] = stim[i]
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

For the use of [kwarg](#Acronyms) `what`, see method [`Eegle.Miscellaneous.remove`](@ref), which can be used instead of this function
if you do not need to remove channels from a sensor labels vector.

Return the 3-tuple (`newX`, `s`, `ne`), where `newX` is the new EEG recording, `s` is the new sensor labels vector and
`ne` is the new number of channels (sensors) in `newX` (`s`).

**See Also** [`Eegle.InOut.readSensors`](@ref)

**Examples**
```julia
using Eegle # or using Eegle.Preprocessing

using Eegle # or using Eegle.Preprocessing

X = randn(128, 7)
sensors = ["F7", "F8", "C3", "Cz", "C4", "P7", "P8"]

# remove second channel
X_, sensors_, ne = removeChannels(X, 2, sensors)

# remove the first five channels
X_, sensors_, ne = removeChannels(X, collect(1:5), sensors)

# remove the channel labeled as "Cz" in `sensors`
X_, sensors_, ne = removeChannels(X, findfirst(x->x=="Cz", sensors), sensors)

# remove the channels labeled as "C3", "Cz", and "C4" in `sensors`
X_, sensors_, ne = removeChannels(X, findall(x->x∈("Cz", "C3", "C4"), sensors), sensors)

# keep only channels labeled as "C3", "Cz", and "C4" in `sensors`
X_, sensors_, ne = removeChannels(X, findall(x->x∉("Cz", "C3", "C4"), sensors), sensors)
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
                            stim::Vector{S}) 
    where {T<:Real, S<:Int}

```
Remove one or more samples, i.e., rows, from the ``T×N`` EEG recording `X`, 
where ``T`` and ``N`` denotes the number of samples and channels (sensors), respectively,
and remove the corresponding elements from `stim`, the associated [stimulation vector](@ref).

For the use of [kwarg](#Acronyms) `what`, see method [`Eegle.Miscellaneous.remove`](@ref), which can be used instead of this function
if you do not need to remove tags from a stimulation vector.

Print a warning if elements in `what` correspond to non-zero tags in `stim`.

Return the 3-tuple (`newX`, `s`, `ne`), where `newX` is the new data, `s` is the new stimulation vector and
`ns` is the new number of samples in `newX`.

**Examples**
```julia
using Eegle

sr, ne = 256, 7
X = randn(sr, ne)
stim = rand(0:3, sr)

# remove second sample
X_, stim_, ns = removeSamples(X, 2, stim)

# remove the first 128 samples
X_, stim_, ns = removeSamples(X, collect(1:128), stim)

# remove every other sample (decimation by a factor of 2)
X_, stim_, ns = removeSamples(X, collect(1:2:length(stim)), stim)
```
"""
function removeSamples(X::AbstractMatrix{T}, what::Union{Int, Vector{S}},
                       stim::Vector{S}) where {T<:Real, S<:Int}
    di = findfirst(length(stim).==(size(X)))
    X = Eegle.Miscellaneous.remove(X, what; dims=di)
    if what isa Int
        stim[what]==0 || @warn "Eegle.Preprocessing, `removeSample` function: tag at position $(what) with value $(stim[what]) has been removed"
    else
        positions = [i for i∈what if stim[i]≠0]
        tags = [stim[i] for i∈what if stim[i]≠0]
        isempty(positions) || @warn "Eegle.Preprocessing, `removeSample` function: tags have been removed" positions tags
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

**Tutorials** xxx, xxx

**Description**

Given the ``T×N`` EEG recording `X`, where ``T`` and ``N`` denotes the number of samples and channels (sensors), respectively, 
and ``L>0`` `lags`, the ``T×N(L+1)`` lag-embedded data matrix is

```math
X_{\\text{lags}} = \\left[ 
X^{(0)} \\;\\; X^{(1)} \\;\\; \\cdots \\;\\; X^{(L)}
\\right],
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

**Return** the ``T×N(L+1)`` lag-embedded data matrix ``X_{\\text{lags}}``.

**Example**
```julia
using Eegle # or using Eegle.Preprocessing

X = randn(8, 2) # small example to see the effect

elX = embedLags(X, 3)
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
