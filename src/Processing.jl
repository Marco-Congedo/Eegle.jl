module Processing

using StatsBase
using Statistics
using LinearAlgebra 
using PosDefManifold
using DSP

import DSP:filtfilt
import Eegle

# Module REPL text colors
const titleFont     = "\x1b[95m"
const separatorFont = "\x1b[35m"
const defaultFont   = "\x1b[0m"
const greyFont      = "\x1b[90m"

export
    filtfilt,
    car!,
    globalFieldPower,
    globalFieldRMS,
    minima,
    epoching

"""
```julia
function filtfilt(  X::Matrix, 
                    sr::Int, 
                    responseType::DSP.FilterType; 
    designMethod::DSP.ZeroPoleGain=Butterworth(2))
```
Apply a digital filter in a forward-backward manner to obtain a linear phase response.

**Arguments**
- `X`: the ``T×N`` EEG recording, where ``T`` and ``N`` denotes the number of samples and channels (sensors), respectively
- `sr`: the sampling rate of `X`
- `responseType`: a [filter response type](https://docs.juliadsp.org/stable/filters/#response-types) of the DSP.jl package: `Lowpass`, `Highpass`, `Bandpass`, or `Bandstop`
- `designMethod`: The [filter design method](https://docs.juliadsp.org/stable/filters/#Filter-design) of the DSP.jl package: `Butterworth`, `Chebyshev1`, `Chebyshev2`, `Elliptic`, or `FIRWindow`.

By default, `designMethod` is `Butterworth(2)`, that is, a second-order Butterworth filter.

For the analysis in the frequency domain, see the [FourierAnalysis](https://github.com/Marco-Congedo/FourierAnalysis.jl) package.

**Examples**
```julia
using Eegle

sr = 128 # sampling rate
X = randn(sr*8, 19)

filteredX = filtfilt(X, sr, Bandpass(1, 24))

filteredX = filtfilt(X, sr, Bandstop(49, 51))

filteredX = filtfilt(X, sr, Highpass(10))

filteredX = filtfilt(X, sr, Lowpass(10))

filteredX = filtfilt(X, sr, Bandstop(49, 51); 
                    designMethod = Chebyshev1(4, 0.5))

# Apply a filter bank
responses = [Bandpass(1, 4), Bandpass(4, 8), Bandpass(8, 12), Bandpass(12, 16)]
filterBank = [filtfilt(X, 128, r; designMethod = Butterworth(8)) for r ∈ responses]
```
"""
function filtfilt(  X::Matrix, sr::Int, responseType::DSP.FilterType; 
        designMethod::DSP.ZeroPoleGain=Butterworth(2))
    filtfilt(digitalfilter(responseType, designMethod; fs=sr), X)
end




"""
```julia
function car!(X::AbstractMatrix{T}; 
    correction::Union{Int, Real} = 0) 
where T<:Real 
```

Re-reference ``X`` to the *common average reference* (CAR), that is, set the mean of the rows of ``X`` to zero.

**Arguments**
- `X`: the ``T×N`` EEG recording, where ``T`` and ``N`` denotes the number of samples and channels (sensors), respectively

**Optional Keyword Arguments**
- `correction`: zero by default. It can be a positive number, in which case, from the rows of ``X`` it is not subtracted their
    sum divided by ``N``, but their sum divided by ``N``+`correction`.

When ``correction`` is equal to zero (default) we obtain the usual car reference — see [centeringMatrix](https://github.com/Marco-Congedo/Xloreta.jl?tab=readme-ov-file#centeringmatrix). 
When it is equal to 1, we obtain the reference method "B" of [Kim2023GhostICs](@cite).

It should be noted that the usual CAR yields data with rank ``N-1`` and zero row means, while the method of [Kim2023GhostICs](@cite) yields
full-rank data, but non-zero row mean. A value of ``correction`` between 0 and 1 yields intermediate situations. 


**Return** the re-referenced ``X`` matrix. Note that this function change the content of ``X``, does not generate another matrix.
If you want to keep the original data, use 

```julia
car!(copy(X))
```

**Examples**
```julia
using Eegle

X=randn(128, 19)

car!(X) # this also returns X

Y = car!(copy(X)) # does not change X

car!(X; correction = 1)
```
"""
function car!(X::AbstractMatrix{T}; 
    correction::Union{Int, Real} = 0) where T<:Real 

    correction < 0 && throw(ArgumentError("Eegle.Processing module, function `!car`: the `correction` argument must be non-negative"))
    avg = correction ≈ 0 ? (sum(X, dims=2) ./ size(X, 2)) : (sum(X, dims=2) ./ (size(X, 2) + correction))
    return X .-= avg
end


"""
```julia
function globalFieldPower(X::AbstractMatrix{T}; 
    func::Function = identity) 
where T<:Real 
```
The global field power (GFP) is the sample-by-sample total EEG power.

Let ``X`` be the ``T×N`` EEG recording, where ``T`` and ``N`` denotes the number of samples and channels, respectively,
and ``x_t`` be the vector of ``N`` potentials at sample ``t∈{1,...,T}``, then the GFP at each sample is given by

``x_t^Tx_t``.

Function `func` can be applied element-wise to the output (none by default).
[Anonymous functions](https://docs.julialang.org/en/v1/manual/functions/#man-anonymous-functions)
can be used.

Usually the GFP is computed on common average reference data — see [`car!`](@ref).

**Return** the vector comprising the ``T`` GFP values.

**See also** [`globalFieldRMS`](@ref)

**Examples**
```julia
using Eegle, Xloreta

X=randn(128, 19)

# using an anonymous function
# ℌ is an alias for centeringMatrix, exported from the Xloreta package
g = globalFieldPower(X * ℌ(size(X, 2)); func=x->sqrt(x/size(X, 2)))

```
"""
function globalFieldPower(X::AbstractMatrix{T}; 
                func::Function = identity) where T<:Real 
    func.([x⋅x for x ∈ eachrow(X)]) # field root mean square
end

"""
```julia
function globalFieldRMS(X::AbstractMatrix{T}; 
    func=identity) 
where T<:Real
```
The global field root mean square (GFRMS) is the square root of the [`globalFieldPower`](@ref) once
this has been divided by the number of electrodes.

Let ``X`` be the ``T×N`` EEG recording, where ``T`` and ``N`` denotes the number of samples and channels, respectively,
and let ``x_t`` be the vector of ``N`` potentials at sample ``t∈{1,...T}``, then the GFRMS at each sample is given by

``\\sqrt{\\frac{1}{N} (x_t^\\top x_t)}``.

Function `func` can be applied element-wise to the output (none by default).
[Anonymous functions](https://docs.julialang.org/en/v1/manual/functions/#man-anonymous-functions)
can be used.

Usually the GFRMS is computed on common average reference data — see [`car!`](@ref).

**Return** the vector comprising the ``T`` GFRMS values.

**See also** [`globalFieldPower`](@ref)

**Examples**
```julia
using Eegle, Xloreta

X=randn(128, 19)

# ℌ is an alias for centeringMatrix, exported from Xloreta package
g = globalFieldRMS(X * ℌ(size(X, 2)))


# return the natural log of the GFRMS
g = globalFieldRMS(X * ℌ(size(X, 2)); func=log)
```
"""
function globalFieldRMS(X::AbstractMatrix{T}; func=identity) where T<:Real
    func.(sqrt.(globalFieldPower(X)./size(X, 2))) # global field root mean square
end   





# Given EEG data in `X` and its sampling rate `sr`, computes the global field root mean square (GFRMS) 
# on data X that is low-pass filtered it using limit lowPass. Then find all local minima of the GFRMS. 
# Return a 3-tuple holding:
# - the vector of unitrange in samples unit delimiting successive minima, 
# where no two successive minima can comprise less than `minsamples` samples. These UnitRange delimits
# the epochs and determine a 1-sample overlapping. For example: [1:128, 128:350, 350:461,...]
# - the GFRMS computed on the low-pass filtered data and 
# - the vector of lengths of the intervals between all successive minima (to make an histogram, for example) 
# see [global field root mean square](@ref globalFieldRMS)
function _adaptiveEpochs(X::AbstractMatrix{T}, sr, minsamples::S, lowPass::Union{S, T}) where {T<:Real, S<:Int}

    # if low-pass limit is the Nyquist frequency do not filter
    gfrmsFilt = lowPass≥sr/2 ? globalFieldRMS(X) : globalFieldRMS(filtfilt(X, sr, Lowpass(lowPass)))

    mina, value = Eegle.Miscellaneous.minima(gfrmsFilt)
    #d=[(mina[i]-mina[i-1])/sr for i=2:length(mina)]
    #histogram(d)

    # ensure minimum window length
    i=1
    while i<length(mina)
        for j=1:length(mina)-1
            if mina[j+1]-mina[j]<minsamples
                #println("$i: $(mina[j+1]-mina[j]) $(j+1)")
                deleteat!(mina, j+1)
                i-=1
                break
            end
        end
        i+=1
        #println("$i:")
    end

    d=[(mina[i]-mina[i-1])/sr for i=2:length(mina)]
    seg=[mina[i-1]:mina[i] for i=2:length(mina)]

    return seg, gfrmsFilt, d 
end

"""
```julia
function epoching(X::AbstractMatrix{T}, sr;
    wl::Int = round(Int, sr*1.5),
    slide::Int = 0,
    minSize::S = round(Int, sr*1.5),
    lowPass::Union{T, S} = 14,
    richReturn::Bool = false) 
where {T<:Real, S<:Int}
```
Segment an EEG file in successive epochs and compute a vector of unit ranges delimiting the epochs.
This is used to extract epochs from spontaneous EEG recording. For tagged data (e.g., ERPs and BCI data), 
use [`Eegle.ERPs.trials`](@ref) instead.

Two segmentation methods are possible, the *standard* fixed-length epoching and the *adaptive* epoching based on the
local minima of the [global field root mean square](@ref globalFieldRMS) (GFRMS) computed on low-pass filtered data.

- *Standard (default):* `wl` is set to a positive integer (by default is `sr`*1.5), which determines the length in samples of the epochs.
    A positive value of `slide` (default=0) determines the number of overlapping 
    samples. By default there will be no overlapping. 
- *Adaptive:* if `wl`= 0, the GFRMS is computed on data that is low-pass filtered 
    using `lowPass` (in Hz) as the cut-off (default = 14 Hz), and segmented ensuring that the minimum epoch size (in samples) is `minSize`, 
    which default is the number of samples covering 1.5s. Set `LowPass` to `sr`/2 (Nyquist frequency) for no low-pass filtering of the GFRMS.

**Return**

- *Standard:* if `richReturn=false` (default) ``r``, else the 3-tuple (``r``, 0 and `wl`)
- *Adaptive:* if `richReturn=false` (default) ``r``, else the 3-tuple (``r``, ``m``, ``l``),

where ``r`` is the computed vector of unit ranges (a `Vector{UnitRange{Int64}}` type), 
``m`` the vector with the GFMRS of the low-pass filtered data and ``l`` the vector of epoch lengths.

!!! note "Epochs definition"
    With the *adaptive* method, the last sample of an epoch coincides with the first sample of the successive epoch,
    whereas with the *standard* method there is no overlapping if ``slide`` is equal to 0 (default).

**Examples**
```julia

using Eegle

X=randn(6144, 19)
sr = 128

# standard 1s epoching with 50% overlap
ranges = epoching(X, sr;
        wl = sr,
        slide = sr ÷ 2)
# return (1:64, 65:128, ...)

# standard 4s epoching with no overlap
ranges = epoching(X, sr;
        wl = sr * 4)
# return (1:512, 513:1024, ...)

# adaptive epoching of θ (Theta: 4Hz-7.5Hz) oscillations
Xθ = filtfilt(X, sr, Bandpass(4, 7.5))
rangesθ = epoching(Xθ, sr;
        wl = 0, # do not forget this
        minSize = round(Int, sr ÷ 4), # at least one θ cycle
        lowPass = 7.5)  # ignore minima due to higher frequencies

# Get the epochs from the above epoching:
𝐗 = [X[r, :] for r ∈ ranges] 
𝐗θ = [Xθ[r, :] for r ∈ rangesθ]

# Get the covariance matrices of the above epochs
𝐂 = covmat(𝐗) 
𝐂θ = covmat(𝐗θ)

# If only the covariance matrices are needed,
# a more memory-efficient way avoiding the extraction of 𝐗 is
𝐂 = ℍVector(covmat([view(X, r, :) for r ∈ ranges]))
𝐂θ = ℍVector(covmat([view(Xθ, r, :) for r ∈ rangesθ]))
```
**See** [`Eegle.BCI.covmat`](@ref)
"""
function epoching(X::AbstractMatrix{T}, sr;
                wl::Int=round(Int, sr*1.5),
                slide::Int=0,
                minSize::S=round(Int, sr*1.5),
                lowPass::Union{T, S}=14,
                richReturn::Bool=false) where {T<:Real, S<:Int}

    if  wl==0 # use segmentation based on the global field root mean square
        seg, gfrms, hsegments = _adaptiveEpochs(X, sr, minSize, min(lowPass, sr/2))
        return richReturn ? (seg, gfrms, hsegments) : seg 
    else # use normal segmentation in fixed length windows of length wl with overlapping slide (in samples)
        seg = slide>0 ? [i*slide+1:i*slide+wl for i=0:(size(X, 1)-wl)÷slide] :
                        [i*wl+1:i*wl+wl for i=0:(size(X, 1))÷wl-1]
        return richReturn ? (seg, 0, wl) : seg         
    end
end


end # module


