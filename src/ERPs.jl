# v 0.1 Nov 2019; 
# v 0.2 April 2025
# Part of the Eegle.jl package.
# Copyright Marco Congedo, CNRS, University Grenoble Alpes.

module ERPs

using   LinearAlgebra,
        Statistics,
        StatsBase,
        FourierAnalysis,
        PosDefManifold,
        Diagonalizations

using   Eegle.Preprocessing, Eegle.Processing

include("tools/Toeplitz_alg.jl") # used by `mean`
using .toeplitzAlgebra  # relative import with dot

include("tools/Tyler.jl") # used by `bss`
using .Tyler  # relative import with dot     

import Statistics: mean
import Base: merge

import Eegle

export
    mean,
    stim2mark,
    mark2stim,
    merge,
    trialsWeights,
    trials,
    reject,
    tfas,
    trialsCospectra,
    bss,
    extractTrials

"""
```julia
(1) function mean(  X::Matrix{T}, 
                    wl::S, 
                    mark::Vector{Vector{S}};
        overlapping :: Bool = false,
        offset :: S = 0,
        weights :: Union{Vector{Vector{R}}, Symbol}=:none) 
    where {T<:Real, S<:Int}

(2) function mean(  o::EEG; 
        overlapping :: Bool = false,
        offset :: S = 0,
        weights :: Union{Vector{Vector{T}}, Symbol} = :none,
        mark :: Union{Vector{Vector{S}}, Nothing} = nothing) 
    where {T<:Real, S<:Int}
```

Estimate the weighted mean ERPs (event-related potentials), as the standard arithmetic mean (default) 
or using the multivariate regression method, as detailed in [Congedo2016STCP](@cite).

**Tutorials**

xxx

**METHOD (1)**

**Arguments**
- `X`: the whole EEG recording, a matrix of size ``T×N``, where ``T`` and ``N`` denotes the number of samples and channels (sensors), respectively
- `wl`: the window (trial or ERP) length in samples
- `mark`: the [marker vectors](@ref).

!!! warning "Empty markers vectors"
    If `mark` holds empty vectors, they will be ignored and the mean will
    not be computed for those marks. The number of means therefore will
    be equal to the number of non-empty mark vectors.

**Optional Keyword Arguments**
- `overlapping`: see [overlapping](@ref)
- `offset`: see [offset](@ref)
- `weights`: can be used to obtain weighted means. By default, equal weights are used. It can be: 
    - a vector of vectors of non-negative real weights for the trials, with the same shape as `mark`, where the empty vectors of `mark` are ignored
    - `:a` : adaptive weights computed as the inverse of the squared Frobenius norm of the trials data, along the lines of [Congedo2016STCP](@cite).
       
!!! warning "offset"
    If `mark` has been created using an offset when reading the data using [`Eegle.InOut.readNY`](@ref), set offset to zero here.

    Markers which value plus the offset exceeds ``t`` minus the window length will be ignored, as they cannot define a complete ERP (or trial).

**Return**

A vector of mean ERPs, one for each non-empty vectors in `mark`. Each mean is a matrix of size 
``wl×n``, where ``n`` is the number of electrodes.

**METHOD (2)** 

The same as method (1), but taking as input an [`Eegle.InOut.EEG`](@ref) structure `o`,
which has fields providing the recording (`X`), the ERP duration in samples (`wl`) and the markers (`mark`).

Different markers can be used instead by passing [marker vectors](@ref) with the `mark` kwarg.

**See** [Eegle.ERPs.`stim2mark`](@ref), [`Eegle.ERPs.trialsWeights`](@ref)

**Examples**
```julia
using Eegle # or using Eegle.ERPs

# Method (1)

# Number of channels, sampling rate and window length
N, sr, wl = 19, 128, 128

# number of tags per class
nm=[30, 45, 28]

X=randn(sr*100, N)
mark=[[rand(1:sr*100-wl) for i=1:m] for m∈nm]

# compute the means for all classes with adaptive weighting
𝐌=mean(X, wl, mark; overlapping=true, weights=:a)

# compute the means for class 1 and 3
𝐌=mean(X, wl, [mark[1], mark[3]]; overlapping=true)

# compute the mean  with adaptive weighting only for the first class
# and return it as a matrix (not as a vector of matrices)
M=mean(X, wl, [mark[1]]; weights=:a)[1]

# Method (2)
# xxx Load a NY file
𝐌=mean(o; overlapping=true, weights=:a)
```
"""
function mean(X::Matrix{T}, wl::S, mark::Vector{Vector{S}};
            overlapping :: Bool = false,
            offset :: S = 0,
            weights:: Union{Vector{Vector{T}}, Symbol}=:none) where {T<:Real, S<:Int}

    weights isa Symbol && weights ∉ (:none, :a) && throw(ArgumentError("Eegle.ERPs, function `mean`: possible symbols for `weights` are :none and :a"))
    nc=count(x->!isempty(x), mark) # num of classes: ignore empty mark vectors
    nc<1 && throw(ArgumentError("Eegle.ERPs, function `mean`: the `mark` argument is empty"))
    nonempty=findall(!isempty, mark) # valid indeces: ignore empty mark vectors
    nonempty_mark = mark[nonempty] # Create mark with non empty marker
    nonempty_mark ≠ mark && @info "There are no markers for one or more classes"
    if !(weights isa Symbol)
        length(weights)==length(nonempty_mark) || throw(ArgumentError("Eegle.ERPs, function `mean`: `weights` must hold the same number of vectors as non-empty vectors in `mark`"))
        for i in eachindex(weights)
            length(weights[i])==length(nonempty_mark[i]) || throw(ArgumentError("Eegle.ERPs, function `mean`: the $(i)th vector of `weights` and non-empty vector of `mark` are not of the same size"))
        end
    end

    if overlapping # Multivariate Regression, see Congedo et al., 2016. use Toeplitz_Alg
        N = size(X, 2)
        L = size(X, 1)
        Tn = Vector{Toeplitz}(undef, nc)
        weights==:a && (weights=trialsWeights(X, mark, wl; offset=offset))
        for (i, marki) = enumerate(nonempty_mark)
                marki = marki .+ offset
                delete_ids = findall(e->(0>e || e>L-N+2), marki)
                if !isempty(delete_ids)
                        @warn "Element(s) showing incomplete diagonals will be deleted for mark[i] at index 'delete_ids'  with" i delete_ids marki[delete_ids]
                        deleteat!(marki, delete_ids)
                end
                weights == :none ?  Tn[i] = Toeplitz((wl, N), marki, :none) : #compute Tn
                                    Tn[i] = Toeplitz((wl, N), marki, weights[i]) # Compute

        end
        if weights==:none
            Xbar = Tn_time_Tn_transpose(Tn)\Tn_time_X(Tn,X)
        else
            w = [sum(weight.^2)/sum(weight) for weight in weights if !isempty(weight)]
            Xbar = Diagonal(vcat(fill.(w, wl)...)) * (Tn_time_Tn_transpose(Tn)\Tn_time_X(Tn,X))
        end
        return [Xbar[wl*(c-1)+1:wl*c, :] for c=1:nc]

    else # Arithmetic mean
        if  weights==:none
            return [mean(X[mark[c][j]+offset:mark[c][j]+offset+wl-1, :] for j=1:length(mark[c])) for c∈nonempty]
        else
            weights==:a && (weights = trialsWeights(X, mark, wl; offset=offset))
            w = [weight./sum(weight) for weight ∈ weights if !isempty(weight)]
            return [sum(X[mark[c][j]+offset:mark[c][j]+offset+wl-1, :]*w[c][j] for j=1:length(mark[c])) for c∈nonempty]
        end
    end
end


"""
```julia
    function stim2mark( stim::Vector{S}, 
                        wl::S;
        offset::S=0, code=nothing) 
    where S <: Int
```
Convert a [stimulation vector](@ref) into [marker vectors](@ref).

**Arguments**
- `stim`: the [stimulation vector](@ref) to be converted
- `wl`: the window (trial or ERP) length in samples.

**Optional Keyword Arguments**
- `code`: by default, the output will hold as many marker vectors as the largest tag (integers) in `stim`,
    which may or may not hold instances of all integers up to the largest.
    If there are missing integers, the corresponding marker vector will be empty.
    Alternatively, a vector of tags coding the classes of stimulations in `stim` can be passed as 
    kwarg `code`. In this case, arbitrary non-zero tags can be used (even negative)
    and the number of marker vectors will be equal to the number of
    unique integers in `code`. If `code` is provided, the marker vectors are arranged in the order given there,
    otherwise the first vector corresponds to the tag 1, the second to tag 2, etc.
    In ant case, in each vector, the samples are sorted in ascending order.

!!! warning "offset"
    Markers which value plus the offset is non-positive or exceeds the length of `stim` minus ``wl`` will be ignored,
    as they cannot define a complete ERP (or trial). If this happens, passing the output to [`mark2stim`](@ref) will not return
    `stim` back exactly. Actually, calling this function and reverting the operation with `mark2stim` ensures that the 
    stimulation vector is valid.

**Return**

A vector of ``z`` marker vectors, where ``z`` is the number of classes, i.e.,
the highest integer in `stim` or the number of non-zero elements in `code` if it is provided.

**See** [`mark2stim`](@ref)

**Examples**
```julia
using Eegle # or using Eegle.ERPs

sr, wl = 128, 256 # sampling rate, window length of trials
ns = sr*100 # number of samples of the recording

# simulate a valid stimulations vector for three classes
stim = vcat([rand()<0.01 ? rand(1:3) : 0 for i = 1:ns-wl], zeros(Int, wl))

mark = stim2mark(stim, wl)

stim2 = mark2stim(mark, ns) # is identical to stim
```

"""
function stim2mark(stim::Vector{S}, wl::S;
                offset::S=0, code=nothing) where S <: Int
    unic = code===nothing ? collect(1:maximum(unique(stim))) : sort(code)
    return [[i+offset for i ∈ eachindex(stim) if stim[i]==j && i+offset+wl-1<=length(stim) && i+offset>1] for j∈unic] 
end

"""
```julia
    function mark2stim( mark::Vector{Vector{S}}, 
                        ns::S;
        offset::S=0, code=nothing) 
    where S <: Int
```
Reverse transformation of [`stim2mark`](@ref).

!!! note
    If an `offset` has been used in `stim2mark`, -offset must be used here
    in order to get back to the original [stimulation vector](@ref).

If `code` is provided, it must not contain 0. 

**Examples** see [`stim2mark`](@ref)
"""
function mark2stim(mark::Vector{Vector{S}}, ns::S;
                offset::S=0, code=nothing) where S <: Int
    stim=zeros(S, ns)
    unic = code===nothing ? collect(0:length(mark)) : vcat([0], sort(code))
    for z=1:length(mark), j ∈ mark[z] 
        stim[j+offset] = unic[z+1] end
    return stim
end


"""
```julia
    function merge( mark::Vector{Vector{S}}, 
                    mergeClasses::Vector{Vector{S}})
    where S <: Int
```
Merge the vectors of [marker vectors](@ref) `mark` and sort the markers within each class.
Return another marker vectors.
The merging pattern is determined by `mergeClasses`.

As an example, suppose `mark` holds 4 vectors of markers and
`mergeClasses`=[[1, 2], [3, 4]],
then the result will hold two markers vectors, vectors 1 and 2 of `mark`
concatenated and sorted and vectors 3 and 4 of in `mark` concatenated and sorted.
Empty mark vectors will be ignored.

This can be used to merge classes in ERP and BCI experiments.

**Examples**
```julia
using Eegle # or using Eegle.ERPs
mark =  [   [128, 367], 
            [245, 765, 986],
            [467, 880, 1025, 1456],
            [728, 1230, 1330, 1550, 1980],  
        ]

merged = merge(mark, [[1, 2], [3, 4]])

# return: 2-element Vector{Vector{Int64}}:
#           [128, 245, 367, 765, 986]
#           [467, 728, 880, 1025, 1230, 1330, 1456, 1550, 1980]
```
"""
merge(mark::Vector{Vector{S}}, mergeClasses::Vector{Vector{S}}) where S <: Int =
    [sort(vcat(mark[m]...)) for m ∈ mergeClasses]

# Given `𝐓`, the output of `trials`, which is either a vector of trials or a vector of vectors of trials, one for each class
# (empty vectors are allowed), return `𝐓` if `linComb` is nothing (default), the `linComb` columns of the trials in `𝐓` if `linComb`
# is en integer or a linear combination given my vector `linComb` of the trials in `𝐓` if `linComb` is a vector of reals.
# xxx TO DO: allow readNY to call this function
function _linComb(𝐓, linComb::Union{Vector{R}, S, Nothing} = nothing) where {R<:Real, S<:Int}
    if      linComb === nothing
            return 𝐓
    elseif  linComb isa Int
            if 𝐓 isa Vector 
                return [t[:, linComb] for t ∈ 𝐓]
            else # vector of vectors
                return [isempty(r) ? [] : [t[:, linComb] for t ∈ r] for r ∈ 𝐑]
            end
    else
            e = "Eegle.ERPs, function `trials`: the length of `linComb` does not match the number of columns (electrodes) of the trials"
            if 𝐓 isa Vector 
                length(linComb)==size(𝐓[1]) || error(e)
                return [t*linComb for t ∈ 𝐓]
            else # vector of vector
                for i∈eachindex(𝐓)
                    !isempty(𝐓[i][1]) && (length(linComb)≠size(𝐓[i][1])) && error(e)
                end
                return [isempty(r) ? [] : [t*linComb for t ∈ r] for r ∈ 𝐑]
            end
    end
end

"""
```julia
    function trials(X::Matrix{R}, 
                    stimOrMark::Union{Vector{S}, Vector{Vector{S}}}, 
                    wl::S;
        shape::Symbol = :cat
        weights::Union{Vector{R}, Nothing} = nothing,
        linComb::Union{Vector{R}, S, Nothing} = nothing,
        offset::S = 0) 
    where {R<:Real, S<:Int}

```
Extract trials of duration `wl` from a tagged EEG recording `X`.
Optionally, multiply them by `weights` and compute a linear combination across sensors thereof.

!!! tip
    To extract trials and compute their mean, see [`mean`](@ref);
    for segmenting non-tagged data, see [`Eegle.Processing.epoching`](@ref).

**Arguments**
- `X`: the whole EEG recording, a matrix of size ``T×N``, where ``T`` is the number of samples and ``N`` the number of channels (sensors).
- `stimOrMark`: either a [stimulation vector](@ref) or [marker vectors](@ref). 
- `wl`: the window (trial, e.g., ERP) length in samples.

**Optional Keyword Arguments**
- `shape`: see below.
- `weights`: optional weights to be multiplied to the trials. It has the same size as `stimOrMark`. Adaptive weights can be obtained passing the [`Eegle.ERPs.trialsWeights`](@ref) function.

!!! warning "Weights normalization"
    If you provide custom weights, their mean should be 1 across trials with the same tag if `stimOrMark` is a stimumatios vector, within each vector if they are marker vectors.

- `linComb`: Optional linear combination to be applied to the trials, e.g., a spatial filter. It can be:
    - an integer: extract for each (weighted) trial only the data at the electrode indexed by `linComb` ``∈[1,..,n]`` (linear combination by a one-hot vector)
    - a vector ``f`` of ``N`` real elements: extract for each (weighted) trial the linear combination ``X_jf``.
- `offset`: see [offset](@ref).

**Return**

- if `stimOrMark` is a [stimulation vector](@ref), return a vector of trials or of linear combinations thereof.
- if `stimOrMark` is [marker vectors](@ref), return:
    - a vector of vectors of trials or of linear combinations threof if `shape` ≠ `:cat`,
    - all trials or the linear combinations threof concatenated in a single vector if `shape` == `:cat`.

By default `shape` is equal to `:cat`. Empty marker vectors are ignored if `shape` is equal to `:cat`, otherwise
an empty vector is returned in their corresponding positions.

Each extracted trial is a ``wl×N`` matrix if `linComb` is `nothing` (default), 
otherwise it a vector ``wl`` elements.

**Examples**
```julia
using Eegle # or using Eegle.ERPs
xxx # 
```
"""
trials( X::Matrix{R}, stim::Vector{S}, wl::S;
        weights::Union{Vector{R}, Nothing} = nothing,
        linComb::Union{Vector{R}, S, Nothing} = nothing,
        offset::S = 0) where {R<:Real, S<:Int} =
    if isempty(stim)
        return []
    else
        if weights===nothing
            return _linComb([X[stim[j]+offset:stim[j]+offset+wl-1, :] for j∈eachindex(stim)], linComb)
        else
            return _linComb([X[stim[j]+offset:stim[j]+offset+wl-1, :]*weights[j] for j∈eachindex(stim)], linComb)
        end
    end

trials( X::Matrix{R}, mark::Vector{Vector{S}}, wl::S;
        weights::Union{Vector{Vector{R}}, Nothing}=nothing,
        linComb::Union{Vector{R}, S, Nothing} = nothing,
        offset::S=0,
        shape::Symbol=:cat) where {R<:Real, S<:Int} =
    if shape==:cat
        if weights===nothing
            return _linComb([X[mark[i][j]+offset:mark[i][j]+offset+wl-1, :] for i∈eachindex(mark) for j∈eachindex(mark[i])], linComb)
        else
            return _linComb([X[mark[i][j]+offset:mark[i][j]+offset+wl-1, :]*weights[i][j] for i∈eachindex(mark) for j∈eachindex(mark[i])], linComb)
        end
    else
        if weights===nothing
            return _linComb([trials(X, m, wl; offset=offset) for m ∈ mark], linComb)
        else
            return _linComb([trials(X, m, wl; weights=w, offset=offset) for (m, w) ∈ zip(mark, weights)], linComb)
        end
    end


"""
```julia
    function trialsWeights( X::Matrix{R}, 
                            stimOrMark::Union{Vector{S}, Vector{Vector{S}}}, 
                            wl::S;
        M::Union{Matrix{R}, Nothing} = nothing,
        offset::S = 0) 
    where {R<:Real, S<:Int}

```
Compute adaptive weights for trials as the inverse of their squared
Frobenius norm, along the lines of [Congedo2016STCP](@cite).
The method is unsupervised, i.e., agnostic to class labels,
but a supervised version is available using the `M` arguments.

!!! tip "Mean ERPs"
    You don't need this function to compute weighted mean ERPs, as this function is called by [`mean`](@ref).

**Arguments**

- `X`: the whole EEG recording, a matrix of size ``T×N``, where ``T`` is the number of samples and ``N`` the number of channels (sensors), respectively
- `stimOrMark`: either a [stimulation vector](@ref) or [marker vectors](@ref). For empty mark vectors, an empty vector is returned
- `wl`: the window (trial or ERP) length in samples.

**Optional Keyword Arguments**

- `M`: (defalut = `nothing`)
    - if `stimOrMark` is a stimulation vector and a matrix is passed as `M`, then the weights are computed as the squared norm of ``X_j-M`` for all trials ``X_j``, ``j \\in \\{1, \\ldots, k\\}``, regardless their class
    - if `stimOrMark` are marker vectors and a vector of ``z`` matrices is passed as `M`, then the weights are computed as the squared norm of ``X_{j(i)}-M_i`` for all trials  ``X_{j(i)}``, ``j \\in \\{1, \\ldots, k\\}``, ``i \\in \\{i, \\ldots, z\\}`` for each class ``i`` separately.
- `offset`: see [offset](@ref).

**Examples**
```julia
using Eegle # or using Eegle.ERPs
xxx # 
```
"""
function trialsWeights(X::Matrix{R}, stim::Vector{S}, wl::S;
                        M::Union{Matrix{R}, Nothing} = nothing,
                        offset::S = 0) where {R<:Real, S<:Int}
    if isempty(stim)
        return []
    else
        if M===nothing
            w = [1/(norm(X[m+offset:m+offset+wl-1, :])^2) for m ∈ stim]
        else
            w = [1/(norm(X[m+offset:m+offset+wl-1, :]-M)^2) for m ∈ stim]
        end
        return w./mean(w)
    end
end


function trialsWeights(X::Matrix{R}, mark::Vector{Vector{S}}, wl::S;
                        M::Union{Vector{Matrix{R}}, Nothing} = nothing,
                        offset::S = 0) where {R<:Real, S<:Int}
    M===nothing || length(M)==length(mark) || throw(ArgumentError("The length of arguments `mark` and `𝐌` must be the same."))
    if M===nothing
        return [trialsWeights(X, m, wl; offset=offset) for m ∈ mark]
    else
        return [trialsWeights(X, m, wl; M=g, offset=offset) for (m, g) ∈ zip(mark, M)]
    end
end


"""
```julia
    function reject(X::Matrix{R}, 
                    stim::Vector{Int}, 
                    wl::S;
        offset::S = 0,
        upperLimit::Union{R, S} = 1.2,
        returnDetails::Bool=false) 
    where {R<:Real, S<:Int}
```
Automatic rejection of artefacted trials in tagged EEG data by automatic amplitude thresholding.

!!! tip "Read data and reject artifacts"
    This function is called by [`Eegle.InOut.readNY`](@ref) to perform artifact rejection while reading
    EEG data in the [NY format](#NY format).

**Arguments**
- `X`: the whole EEG recording, a matrix of size ``T×N``, where ``T`` is the number of samples and ``N`` the number of electrodes
- `stim`: a [stimulation vector](@ref)
- `wl`: the trial length, i.e., the ERPs or trial duration, in samples.

**Optioanl Keyword Arguments**
- `offset`: see [offset](@ref)
- `upperLimit`: modulate the definition of the upper threshold (see below). a reasonable value ∈[1, 1.6]
- `upperLimit`: determine the output (see below).

**Description**

Let ``v`` be the natural logarithm of the **field root mean square** (FRMS, see [`Eegle.Processing.globalFieldRMS`](@ref)) of `X` sorted in ascending order.

The lower threshold ``l`` is defined as the tenth value of ``v`` (robust minimum estimator).

The upper threshold ``h`` is defined as

``h=m+((m-l)u)``,

where:
- ``m`` is the mean of the ``2wl`` central values of ``v``, taken as a robust central tendency estimator
- ``u`` is [kwarg](#Acronyms) `upperlimit` (default=1.2).

All trials in which at least one sample of the log-FRMS exceeds ``h`` or in which ``l`` exceeds the log-FRMS are rejected.

**Return**
- if `returnDetails` is false (default), a 5-tuple holding the following objects:
    - the [stimulation vector](@ref) `stim` with the tags corresponding to rejected trials set to zero (accepted trials),
    - the [stimulation vector](@ref) `stim` with the tags corresponding to accepted trials set to zero (rejected trials),
    - the first object as [marker vectors](@ref),
    - the second object as [marker vectors](@ref),
    - the number of rejected trials per class as a vector of integers.
- if `returnDetails` is true, a 9-tuple holding the above 5 objects and, in addition:
    - the log-FMRS (not sorted),
    - the mean ``m``,
    - the lower threshold ``l``,
    - the upper threshold ``h``.

!!! tip "Algebraic relation"
    The elemet-wise sum of the first two returned objects is equal to the input [stimulation vector](@ref) `stim`.

**Examples**
```julia
using Eegle # or using Eegle.ERPs

xxx

cleanstim, rejecstim, cleanmark, rejecmark, rejected = reject(X, stim, wl; upperLimit=1.5)

R = reject(X, stim, wl; upperLimit=1.5, returnDetails = true) # R is a tuple of 9 objects

norm((R[1].+R[2]).-stim)==0 # should be true
```

**Tutorials**

xxx
"""
function reject(X::Matrix{R}, stim::Vector{Int}, wl::S;
                offset::S = 0,
                upperLimit::Union{R, S} = 1.2,
                returnDetails::Bool = false) where {R<:Real, S<:Int}

    (ns, ne), nc = size(X), length(unique(stim))-1 # stimulaion zero does not count as a class
    length(stim)≠ns && throw(ArgumentError("ERP.jl, function `reject`: the `stim` vector does not have the same number of elements as samples in `X`"))
    frms = Eegle.processing.globalFieldRMS(X; func=log)

    cleanstim = copy(stim)
    rejected = zeros(Int, nc)
    p = sortperm(frms)

    m = mean(frms[p][ns÷2-wl:ns÷2+wl]) # mean of 2*wl samples around the median
    thrDown = frms[p][10] # lower limit: smallest element, don't take the first one to avoid very small numbers due to log
    # thrDown = frms[p][findfirst(x->x>m/1e02, frms[p])] # use this if you don't take the log of the frms
    thrUp = m+((m-thrDown)*upperLimit) # upper limit
    #println("thrUp: ", thrUp)
   
    # argument code added 4 Avril 2025 to read MI files with arbitrary label numbers (not just 1, 2, 3...)
    classcode=sort(unique(stim))[2:end] 
    stim_to_index = Dict(val => i for (i, val) in enumerate(classcode)) # CREATE MAPPING TO AVOID INDEX ERROR 

    # reject epochs of wl samples starting at a sample whose frms<thrDown
    # this reject trials with samples with no signal (almost zero everywhere)
    skipUntil=0
    @inbounds for s=1:ns-wl+1
        s<skipUntil && continue
        if cleanstim[s]>0 && mean(frms[s:s+wl-1])<thrDown
            skipUntil = s+wl
            rejected[stim_to_index[cleanstim[s]]] += 1            
            for i=s:s+wl-1 cleanstim[i] = 0 end
        end
    end

    # reject epochs of wl samples starting at a sample whose frms>thrUp
    skipUntil=0
    @inbounds for s=1:ns-wl+1
        s<skipUntil && continue
        if cleanstim[s]>0 && maximum(frms[s:s+wl-1])>thrUp
          skipUntil = s+wl
          rejected[stim_to_index[cleanstim[s]]] += 1 
          for i=s:s+wl-1 cleanstim[i] = 0 end
        end
    end

    rejecstim = stim-cleanstim

    cleanmark = stim2mark(cleanstim, wl; offset=offset, code=classcode)
    # println(unique(stim))
    # println(unique(rejecstim))
    rejecmark = stim2mark(rejecstim, wl; offset=offset, code=classcode)

    # println("length(cleanmark):", length(cleanmark))
    # println("length(rejecmark):", length(cleanmark))

    if returnDetails
        return cleanstim, rejecstim, cleanmark, rejecmark, rejected, fmrs, m, thrDown, thrUp

    else
        return cleanstim, rejecstim, cleanmark, rejecmark, rejected
    end
end

#xxx
# Analytic Signal of a vector of vectors of data vectors `𝐓`.
# RETURN the corresponding vector of vectors of FourierAnalysis.jl
# TFanalyticsignal object.
# Each data vector in `𝐓` is tall with time along the first dimension.
# All data vectors in `𝐓` must have the same length.
# `sr` is the sampling rate of the data
# `wl` is the trial duration. The number of samples in the vector matrices
# may be equal of bigger then `wl`. In the latter case the trial must be
# centered in the data matrix.
# `bandwidth` and `fmax` are parameters passed to the TFanalyticsignal
# constructor of FourierAnalysis.jl.
# if `smooth` is true, the analytic signal estimations are smoothed both
# along time and along frequency, in this order.
function tfas(  𝐓::Vector{Vector{Vector{R}}},
                    sr::S, wl::S, bandwidth::Union{S, R};
                fmax::Union{S, R, Nothing} = nothing,
                smoothing::Bool = true) where {R<:Real, S<:Int}
      h = smoothing ? FourierAnalysis.hannSmoother : FourierAnalysis.noSmoother
      f, l = FourierAnalysis.TFanalyticsignal, length(𝐓[1][1])
      𝐘=[smooth(h, noSmoother, f(T, sr, l, bandwidth;
                fmax=fmax===nothing ? sr÷2 : fmax, tsmoothing=h)) for T ∈ 𝐓]
      flabels=𝐘[1][1].flabels
      tlabels=[(i-(l-wl)÷2-1)/sr*1000 for i ∈ 1:l]
      return flabels, tlabels, 𝐘
end


function tfas(  𝑻::Vector{Vector{Vector{Vector{R}}}},
                    sr::S, wl::S, bandwidth::Union{S, R};
                fmax::Union{S, R, Nothing} = nothing,
                smoothing::Bool = true) where {R<:Real, S<:Int}
      h = smoothing ? FourierAnalysis.hannSmoother : FourierAnalysis.noSmoother
      f, l = FourierAnalysis.TFanalyticsignal, length(𝑻[1][1][1])
      𝒀=[[smooth(h, noSmoother, f(T, sr, l, bandwidth;
        fmax=fmax===nothing ? sr÷2 : fmax, tsmoothing=h)) for T ∈ 𝐓] for 𝐓 ∈ 𝑻]
      flabels=𝒀[1][1][1].flabels
      tlabels=[(i-(l-wl)÷2-1)/sr*1000 for i ∈ 1:l]
      return flabels, tlabels, 𝒀
end


#xxx
## Compute all cospectra averaged across the trials in data matrix `X`
# marked in vector of vectors `marks`.
# `sr` is the sampling rate
# `wl` is the window length(trial duration in samples)
# Cospectra are estimated in band-pass [`fmin`, `fmax`]
# `tapering` is the tapering window for FFT computations.
# if `non-linear`, non-linear cospectra are computed (false by default).
# RETURN a vector of Hermitian matrices holding the cospectra
function trialsCospectra(X, marks, sr, wl, fmin, fmax;
            tapering  = harris4,
            nonlinear = false)
      #plan=Planner(plan_exhaustive, 8.0, o.wl, eltype(o.X)) # pre-compute a planner
      𝐑=trials(X, marks, wl; shape=:cat)
      𝙎=[crossSpectra(R, sr, wl; tapering=tapering) for R ∈ 𝐑]

      # average cospectra across trials in band-pass region (fmin, fmax)
      f=f2b(fmin, sr, wl):f2b(fmax, sr, wl)
      return ℍVector([ℍ(mean(real(𝙎[i].y[j]) for i=1:length(𝙎))) for j=f])
end


#xxx
# Blind Source Separation for ERPs.
# The method here implemented is a refinement of the method presented in
# https://hal.archives-ouvertes.fr/hal-01078589
# BSS is solved by approximate joint diagonalization (AJD) of a set of
# (1) Fourier cospectra (induced and background activity) and
# (2) covariance matrices of ERP means.
# `Xerp` is a tall data matrix used to extract ERP means for (2)
# `sensor` is a vector of electrode labels (string)
# `Xcospectra` is a tall data matrix used to extract cospectra for (1)
#       This may be the same as `Xerp`, however in general `Xerp` is the
#       data passed through a narrower band-pass filter (e.g., 1-16 Hz)
# `markERP` is a Vector of vectors of Integers with the markers
#       for extracting the trials used for (2). There are exactly as many
#       Vectors as ERP classes to be included in the AJD set.
# `markCospectra` is a vector of vectors of Integers with the markers
#       for extracting epochs used for (1). This may be equal t `markERP`,
#       but it may hold a larger set of markers. Also note that `markCospectra`
#       does not have to hold the same number of vectors as ``markERP` since
#       here all trials are used to estimate the cospectra.
# `sr` is the sampling rate of the data in `Xerp` and `Xcospectra`
# `wl` is the window length of the data in `Xerp` and `Xcospectra`
#       This is the length of the trials used both as window length for
#       Fourier co-spectra computations and for computing ERPs.
# KEYWORD ARGUMENTS :
# if `erpOverlap` is true the multivariate regression method is used to compute
#       ERP means. If false (default) the arithmetic mean is used
# if `erpWeights` = `:a`, the adaptive weighting is used for computing
#       the ERP means. It defaults to `:none` (equal weighting).
#       For this and the previous argument, see `Mean` in this module.
# `erpCovEst` is the covariance matrix estimation method used for the ERP means.
#       Possible choices are (defaulting to :nrtme) :
#       `:scm` = sample covariance matrix
#       `lse` = Ledoit and Wolf linear shrinkage
#       `:tme` = Tyler's M-estimator
#       `:nrtme` normalized regularized M-estimator of Zhang (see Tyler module)
# `cospectraBandPass` is the band-pass region in which cospectra are estimated.
#       The actual number of cospectra estimated depends on the Fourier
#       frequency resolution sr/wl. The default is `(1, 32)` (Hz).
#       For noisy data starting at 2Hz and/or stopping at 28 to 28 Hz
#       can give better results.
# `cospectraTapering` is the tapering window used for the FFT.
#       See the `cospectra` function in FourierAnalysis.jl
# `whiteningeVar` is the explained variance retained in the pre-whitening step.
#       Pre-whitening determines the number of sources to be estimated and
#       is a crucial hyper-parameter for this and similar BSS procedures.
#       If you pass a real number ∈(0, 1] the dimension will be adjusted to the
#       minimum integer guranteeing to explain at least the requested variance.
#       You can enforce e specific dimension passing it as an integer.
#       The default (0.999) is an appropriate choice in general
# `AJDalgorithm` is the AJD algorithm to be employed.
#       See Diagonalizations.jl for the options. The suggested choices are
#       :QNLogLike (default) and :LogLike.
# `AJDmaxIter` is the maximum number of iterations allowed for the AJD algorithm.
# If `verbose` is true (default), information on the convergence reached at
#       each iteration by all iterative algorithms employed is shown in the REPL.
function bss(Xerp::Matrix{R}, sensors::Vector{String}, Xcospectra::Matrix{R},
             markErp::Vector{Vector{Int}}, markCospectra::Vector{Vector{Int}},
             sr::Int, wl::Int;
                erpOverlap :: Bool = false,
                erpWeights :: Symbol = :none,
                erpCovEst :: Symbol = :nrtme,
                cospectraBandPass :: Tuple = (1, 32),
                cospectraTapering = slepians(sr, wl, golden),
                whiteningeVar :: Union{R, Int} = 0.999,
                AJDalgorithm :: Symbol = :QNLogLike,
                AJDmaxIter :: Int = 2000,
                verbose :: Bool = true) where R<:Real

      # Covariance matrix of ERP per condition
      𝐌 = mean(Xerp, wl, markErp, erpOverlap; weights=erpWeights)

      # Mean ERP covariances
      if          erpCovEst == :nrtme
                  𝐂 = [nrtme(M'; maxiter=500, verbose = verbose) for M ∈ 𝐌]
      elseif      erpCovEst == :tme
                  𝐂 = [tme(M'; maxiter=500, verbose = verbose) for M ∈ 𝐌]
      elseif      erpCovEst == :lse
                  𝐂 = _cov(𝐌; covEst = LinearShrinkage(ConstantCorrelation()),
                               dims = 1, meanX = 0)
      elseif      erpCovEst == :scm
                  𝐂 = _cov(𝐌; covEst = SimpleCovariance(), dims = 1, meanX = 0)
      else trhow(ArgumentError("`function `BSS`: keyword argument `erpCovEst` can be :scm, :lse, :tme or :nrtme"))
      end

      # average cospectra across all ERP trials in region [fmin, fmax]
      𝗦 = trialsCospectra(Xcospectra, markCospectra, sr, wl, cospectraBandPass...;
                  tapering=cospectraTapering, nonlinear = false)

      # Pre-whitening: noralize AJD set to unit trace. Base whitening on mean
      # ERP covariances regularized by mean cospectra
      set=vcat(𝗦, 𝐂)
      for S ∈ set S=tr1(S) end
      W=whitening(ℍ(tr1(mean(𝗦))*0.1+tr1(mean(𝐂))*0.9); eVar=whiteningeVar)
      nsources=minimum(size(W.F))
      slabels=[string(i) for i=1:nsources]

      # Whitened Mean ERP covariances
      W𝐂=ℍVector([ℍ(W.F'*C*W.F) for C∈𝐂])
      nERPcov=length(W𝐂)

      # Whitened cospectra
      W𝗦=ℍVector([ℍ(W.F'*S*W.F) for S∈𝗦])
      ncospectra=length(W𝗦)

      # get whitened spectra from cospectra (for plotting)
      wspectra=[W𝗦[i][j, j] for i=1:ncospectra, j=1:nsources]

      # cospectra smoothed non-diagonality weigths
      ndw=hannSmooth([nonD(S) for S ∈ W𝗦])

      # create plot of whitened cospectra and non-diagonality weights
      p1=plot(wspectra, labels=reshape(sensors, 1, length(sensors)),
                title="Whitened Spectra");
      p2=plot(ndw, legend=false,
                title="Non-Diagonality");
      plot1=(p1, p2)

      # uniform weights for ERP covariances
      mw=ones(Float64, nERPcov)
      # alternatively, give as weights the square root of number of trials
      # mw=[√(length(cleanmark[i])) for i=1:length(cleanmark)]

      # concatenate weights and create a StatsBase weights object
      w=weights([ndw/sum(ndw); mw/sum(mw)])

      # AJDset: whitened covariance matrices of average ERPs and cospectra
      Wset=vcat(W𝗦, W𝐂)
      for S ∈ Wset S=tr1(S) end

      # do AJD
      J=ajd(Wset;
            w=w, algorithm=AJDalgorithm, maxiter=AJDmaxIter, verbose=verbose)

      # demixing(B) and mixing(A) matrix
      B=W.F*J.F
      A=J.iF*W.iF

      # explained variance of the mean ERP energy (DISMISSED; use RATIO)
      #expVar=[evar(A, B, C, i) for i=1:nsources, C∈𝐂]
      #normalizeMean!(expVar; dims=1)
      # find key for sorting the average explained variance in desc. order
      #p=sortperm(reshape(sum(expVar, dims=2), :); rev=true)

      # explained variance RATIO of the mean ERP energy / mean Cospectra energy
      expVarERP=[evar(A, B, C, i) for i=1:nsources, C∈𝐂]
      normalizeMean!(expVarERP; dims=1)
      expVarBSS=[evar(A, B, C, i) for i=1:nsources, C∈𝗦]
      normalizeMean!(expVarBSS; dims=1)
      expVar=sum(expVarERP, dims=2)./sum(expVarBSS, dims=2)
      # find key for sorting the explained variance in desc. order
      p=sortperm(reshape(expVar, :); rev=true)

      # sort the columns of B, rows of A and rows of expVar using this key
      B=B[:, p]
      A=A[p, :]
      expVar[:]=expVar[p, :]

      # create plot of expected variance
      plot2 = plot(expVar, xticks = 1:1:nsources,
                    xtickfontsize=12, ytickfontsize=12,
                    legend=:none, title="source SNR");


      # Diagonal matrix with the square root of the mean source variance
      # across ERP means for all sources. Used to normalize A and B so that
      # B gives sources with unit mean variance
      D=Diagonal(inv.(sqrt.(mean([sum(abs2.(m)) for m ∈ eachcol(M*B)] for M ∈ 𝐌))))
      B[:]=B*D
      A[:]=inv(D)*A
      sourceERP=[M*B for M ∈ 𝐌]
      # check: the source variance must be now the identity matrix
      #D1=Diagonal(sqrt.(mean([sum(abs2.(m)) for m ∈ eachcol(M)] for M ∈ sourceERP)))

      # compute the reprojection in the sensor space of all sources
      reproMeans=[[(M*B[:, i])*A[i, :]' for M ∈ 𝐌] for i=1:nsources]

      # find out the sign of sources making them correlating with the
      # mean reprojected source and apply it to B, A, and sourceERP.
      # BEWARE: there is a chance that the repro EEG is bipolar (pos and neg),
      # in which case this solution may fail.
      for i=1:nsources
            meanSourceERPmax=mean(sourceERP)[:, i]
            meanReproMeans=reshape(mean(mean(reproMeans[i]); dims=2), :)
            c = cor(meanSourceERPmax, meanReproMeans)
            D[i, i] = c < 0. ? -1.0 : 1.0
      end
      B[:]=B*D
      A[:]=D*A
      for S∈sourceERP S[:]=S*D end

      return 𝐌, 𝐂, 𝗦, A, B, nsources, slabels, expVar, sourceERP, reproMeans,
             plot1, plot2
end




end # module


#=
push!(LOAD_PATH, homedir()*"\\Documents\\Code\\julia\\Modules")
using Eegle.Preprocessing, Eegle.InOut, EEGtopoPlot, Miscellaneous

X=Matrix(readASCII("C:\\temp\\data")')

XTt=Matrix(readASCII("C:\\temp\\XTt")')

stims=[Vector{Int64}(readASCII("C:\\temp\\stim1")[:]), Vector{Int}(readASCII("C:\\temp\\stim2")[:]) ]

A=mulTX(X, stims, 128)

using LinearAlgebra
norm(A-XTt)
=#
