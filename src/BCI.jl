#= 
    CovMat.jl - version 0.1, April 2025  
    Part of the Eegle.jl package  
    Copyright Marco Congedo, CNRS, University Grenoble Alpes  

Estimation of covariance matrices for EEG trials, including regularized and prototype-based covariance estimation.
=#

module BCI

using Base.Threads: @threads
using LinearAlgebra: eigvecs, BLAS
using PosDefManifold
using CovarianceEstimation
using Diagonalizations: SCM, LShrLW, NShrLW
using PosDefManifold: Fisher
using PosDefManifoldML: PosDefManifoldML, transform!, Tikhonov, MLmodel, Pipeline, MDM
using DSP: DSP, ZeroPoleGain, Butterworth


using Eegle.Preprocessing, Eegle.InOut, Eegle.ERPs

include("tools/Tyler.jl")
using .Tyler  # relative import with dot     

import Eegle

import PosDefManifoldML.crval

# Module REPL text colors
const titleFont     = "\x1b[95m"
const separatorFont = "\x1b[35m"
const defaultFont   = "\x1b[0m"
const greyFont      = "\x1b[90m"


export  covmat, 
        encode,
        crval

"""
```julia
(1) function covmat(X::AbstractMatrix{T};
        covtype = LShrLW,
        prototype::Union{AbstractMatrix, Nothing} = nothing,
        standardize::Bool = false,
        useBLAS::Bool = true,
        threaded::Bool = true,
        reg::Symbol = :rmt,
        tol::Real = real(T)(1e-6),
        maxiter::Int = 200,
        verbose::Bool = false) 
    where T<:Union{Real, Complex}

(2)  function covmat(𝐗::AbstractVector{<:AbstractArray{T}};
        < same arguments as method (1) > ...
```
Covariance matrix estimation(s) of a single data matrix (e.g., a trial) `X` (1) or of a vector of ``K`` data matrices `𝐗` (2).

**Arguments**
- (1) `X`: ``N×T`` real data matrix, where ``N`` and ``T`` denotes the number of samples and channels, respectively
- (2) `𝐗`: a vector holding ``k`` such matrices.

**Optional Keyword Arguments**
- `covtype`: covariance estimator (default = `LShrLW`):
    - `SCM` : sample covariance matrix (maximum likelihood)
    - `LShrLW` : linear shrinkage estimator of [LedoitWolf2004](@cite)
    - `NShrLW` : non-linear shrinkage estimator of [LedoitWolf2020](@cite)
    - `:Tyler`: Tyler's M-estimator [tyler1987](@cite)
    - `:nrTyler`: normalized regularized Tyler's M-Estimator [zhang2016automatic](@cite)
    - or any estimator from the [CovarianceEstimation.jl](https://github.com/mateuszbaran/CovarianceEstimation.jl) package.
- `prototype`: optional matrix to be stacked to the data matrix (or matrices) to form a super-trial — see *Appendix I* in [Congedo2017Review](@cite). Default = `nothing`
- `standardize`: if true, standardize the data matrix(ces) (global mean = 0 and global sd = 1 for each matrix) before estimating the covariance. Default = `false`
- `useBLAS`: optimize the SCM covariance computations using BLAS. Default = `true`
- `threaded`: enable multi-threading across the ``k`` matrices. For (2) only. Default = `true`
- Only for M-estimators:
    - `tol`: the tolerance for the stopping criterion of the iterative algorithm (default = `1e-6`)
    - `maxiter`: the maximum number of iterations allowed (default = `200`)
    - `verbose`: if true, information about convergence is printed in the REPL (default = `false`).
- Only for the normalized regularized Tyler's M-Estimator. Default = `:rmt`:
    - `reg`: if it is `:rmt`, the random matrix theory shrinkage is used, otherwise the Ledoit and Wolf linear shrinkage is used.

**Return**

- (1): The covariance matrix estimation as a Julia [Hermitian](https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/#LinearAlgebra.Hermitian) matrix
- (2): A vector of ``K`` covariance matrix estimations as an [HermitianVector](https://marco-congedo.github.io/PosDefManifold.jl/stable/MainModule/#%E2%84%8DVector-type) type.

**Examples**
```julia
using Eegle # or using Eegle.BCI

# Method (1)

C = covmat(randn(128, 19)) # linear shrinkage estimator by default

C = covmat(randn(128, 19); covtype=SCM)

C = covmat(randn(128, 19); covtype=:Tyler)

# Method (2)

𝐗 = [randn(128, 19) for k=1:10]

𝐂 = covmat(𝐗)

C = covmat(𝐗; covtype=SCM)

C = covmat(𝐗; covtype=:Tyler)
```    
"""
function covmat(X::AbstractMatrix{T};
                covtype = LShrLW,
                prototype::Union{AbstractMatrix, Nothing} = nothing,
                standardize::Bool = false,
                useBLAS::Bool = true,
                threaded::Bool = true, # not used. included for homogeneity with the other method
                reg::Symbol = :rmt,
                tol::Real = real(T)(1e-6),
                maxiter::Int = 200,
                verbose::Bool = false) where T<:Union{Real, Complex}

    T<:Complex && covtype≠SCM && throw(ArgumentError("Eegle.BCI, function `covmat`: for complex data only `covtype=SCM` is supported"))

    transform = standardize ? Eegle.Preprocessing.standardizeEEG : identity

    if (covtype==SCM && useBLAS) # fast computations of the sample covariance matrix
        Y = isnothing(prototype) ? transform(X) : [transform(X) prototype]
        den = 1.0/size(Y, 1)
        if BLAS.get_num_threads()==1
            return size(Y, 2) < 64 ? ℍ(BLAS.gemm('T', 'N', Y, Y)*den) : ℍ((Y'*Y)*den)
        else # if BLAS is multithreded always use BLAS
            return ℍ(BLAS.gemm('T', 'N', Y, Y)*den)
        end
    elseif covtype == :Tyler
        return tme(X'; tol, maxiter, verbose) # tme takes a wide matrix
    elseif covtype == :nrTyler
        return nrtme(X'; reg, tol, maxiter, verbose) # nrtme takes a wide matrix
    else # any other estimator
        return ℍ(CovarianceEstimation.cov(covtype, isnothing(prototype) ? transform(X) : [transform(X) prototype]))
    end
end


function covmat(𝐗::AbstractVector{<:AbstractArray{T}}; 
                covtype = LShrLW, 
                prototype::Union{AbstractMatrix, Nothing}=nothing, 
                standardize::Bool = false, 
                useBLAS:: Bool = true,
                threaded::Bool = true, # for homogeneity with the other method
                reg::Symbol = :rmt,
                tol::Real = real(T)(1e-6),
                maxiter::Int = 200,
                verbose::Bool = false) where T<:Union{Real, Complex}

    T<:Complex && covtype≠SCM && throw(ArgumentError("Eegle.BCI, function `covmat`: for complex data only `covtype=SCM` is supported"))

    transform = standardize ? Eegle.Preprocessing.standardizeEEG : identity
    
    defineTrial(i, prototype) = isnothing(prototype) ? transform(𝐗[i]) : [transform(𝐗[i]) prototype]

    𝐂 = PosDefManifold.HermitianVector(undef, length(𝐗))

    if threaded 
        @threads for i ∈ eachindex(𝐗) 
            𝐂[i] = covmat(𝐗[i]; covtype, prototype, standardize, useBLAS, reg, tol, maxiter, verbose)
        end
    else
        @simd for i ∈ eachindex(𝐗) 
            @inbounds 𝐂[i] = covmat(𝐗[i]; covtype, prototype, standardize, useBLAS, reg, tol, maxiter, verbose)
        end
    end

    return 𝐂
end


"""
```julia
    function encode(o::EEG;
        paradigm::Symbol = o.paradigm,
        covtype = LShrLW,
        targetLabel::String = "",
        overlapping::Bool = false,
        weights = :a,
        pcadim::Int = 8,
        standardize::Bool = false,
        tikh :: Union{Real, Int} = 0,
        useBLAS :: Bool = true,
        threaded = true,
        reg::Symbol = :rmt,
        tol::Real = 1e-6,
        maxiter::Int = 200,
        verbose::Bool = false)
```
Encode all trials in an EEG recording as covariance matrices for a given BCI paradigm.
This is used in Riemannian geometry machine learning.
The supported BCI paradigms are *Motor Imagery (MI)*, *Event-Related Potentials (ERP)* and *P300*.
For details, see *Appendix I* in [Congedo2017Review](@cite).

**Arguments**
- `o`: an instance of the [`EEG`](@ref) data structure containing trials and metadata

**Optional Keyword Arguments**
- `paradigm`: [BCI paradigm](@ref), either `:ERP`, `:P300`, or `:MI`. By default it is used the paradigm stored in `o`.
    - for `:ERP`, prototypes for all classes are stacked and covariance is computed on super-trials
    - for `:P300`, only the target class prototype is stacked
    - for `:MI`, no prototype is used; covariance is computed on the trial as it is.
- `covtype`, `standardize`, `useBLAS`, `reg`, `tol`, `maxiter` and `verbose` — see [`Eegle.BCI.covmat`](@ref), to which they are passed.
- `targetLabel`: mandatory label of the target class (P300 paradigm only, usually: "target")
- `overlapping`: for prototype mean ERP estimations (ERP/P300 only). Default = false:
    - if true, use multivariate regression
    - if false, use the arithmetic average — see [`mean`](@ref).
- `weights`: weights for prototype mean ERP estimations (ERP/P300 only). Default = `:a` — see [`mean`](@ref)
- `pcadim`: number of PCA components of the prototype. They replace the prototype (ERP/P300 only, default = 0, which does not apply PCA)
- `standardize`: standardize trials and prototype (global mean 0 and sd 1) before covariance estimation (default: false)
- `tikh`: Tikhonov regularization parameter (0, the default, does not apply regularization). It is applied after covariance estimation
- `threaded`: enable multi-threaded covariance estimations across trials (default: true). 

**Throw**
- `ArgumentError` if class label `targetLabel` is not found in `o.clabels` (for P300 paradigm).
- `ArgumentError` if paradigm is not one of `:ERP`, `:P300`, or `:MI`.

**Return**
A vector of ``k`` covariance matrix estimations as a [HermitianVector](https://marco-congedo.github.io/PosDefManifold.jl/stable/MainModule/#%E2%84%8DVector-type) type.

**Examples**
```julia
using Eegle # or using Eegle.BCI
xxx
```
"""
function encode(o::EEG;
        paradigm::Symbol = o.paradigm,
        covtype = LShrLW,
        targetLabel::String = "",
        overlapping::Bool = false,
        weights = :a,
        pcadim::Int = 8,
        standardize::Bool = false,
        tikh :: Union{Real, Int} = 0,
        useBLAS :: Bool = true,
        threaded = true,
        reg::Symbol = :rmt,
        tol::Real = 1e-6,
        maxiter::Int = 200,
        verbose::Bool = false)

    isnothing(o.trials) && throw(ArgumentError("Eegle.BCI, function `encode`: The `EEG` structure given as first argument does not holds the trials. Make sure argument `getTrials` is not set to false when you open the EEG data in NY format using the `readNY` function"))

    paradigm ∉ (:ERP, :P300, :MI) && throw(ArgumentError("Eegle.BCI, function `encode`: The `paradigm` must be one of the following symbols: :ERP, :P300, :MI. If you did not pass this argument, it means the paradigm stored in the `o` EEG structure is not supported by `encode`"))

    args = (covtype=covtype, standardize=standardize, useBLAS=useBLAS, threaded=threaded, 
            reg=reg, tol=tol, maxiter=maxiter, verbose=verbose)

    if paradigm==:ERP
        # multivariate regression or arithmetic average ERP mean for ALL CLASSES with data-driven weights
        # multiplied by the square root of the # of target trials to recover the amplitude
        𝐘=Eegle.ERPs.mean(o.X, o.wl, o.mark; overlapping, weights)
        labels=sort(unique(o.stim))[2:end]
        for (l, Y) in enumerate(𝐘)
            𝐘[l]*=sqrt(count(x->x==labels[l], o.stim))
            standardize && (𝐘[l] = Eegle.Preprocessing.standardizeEEG(𝐘[l]))
            if 0<pcadim<o.ne
                𝐘[l]=𝐘[l]*eigvecs(CovarianceEstimation.cov(SimpleCovariance(), 𝐘[l]))[:, o.ne-pcadim+1:o.ne] # PCA to keep only certain components
            end
        end

        Y=hcat(𝐘...) # stack all class ERP means
        
        return tikh≈0 ? covmat(o.trials; prototype=Y, args...) : 
                PosDefManifoldML.transform!(covmat(o.trials; prototype=Y, args...), Tikhonov(tikh; threaded))
                
    elseif paradigm==:P300

        # get indeces for target class labels"
        TargetIndex = findfirst(isequal(lowercase(targetLabel)), lowercase.(o.clabels)) 
        isnothing(TargetIndex) && throw(ArgumentError("Eegle.BCI, function `encode`: target label $targetLabel not found in the class labels of the EEG structure o."))

        # multivariate regression or arithmetic average TARGET ERP mean with data-driven weights
        # multiplied by the square root of the # of target trials to recover the amplitude
        Y=Eegle.ERPs.mean(o.X, o.wl, o.mark; overlapping, weights)[TargetIndex]*sqrt(count(x->x==TargetIndex, o.stim))
        standardize && (Y = Eegle.Preprocessing.standardizeEEG(Y))
        if 0<pcadim<o.ne
            Y=Y*eigvecs(CovarianceEstimation.cov(CovarianceEstimation.SimpleCovariance(), Y))[:, o.ne-pcadim+1:o.ne] # PCA to keep only certain components
        end
        
        return tikh≈0 ? covmat(o.trials; prototype=Y, args...) : 
                PosDefManifoldML.transform!(covmat(o.trials; prototype=Y, args...), Tikhonov(tikh; threaded))

    elseif paradigm==:MI

        return tikh≈0 ? covmat(o.trials; args...) :
                PosDefManifoldML.transform!(covmat(o.trials; args...), Tikhonov(tikh; threaded))

    else
        throw(ArgumentError("Eegle.BCI, function `encode`: only the :ERP, :P300 and :MI BCI paradigm are supported"))
    end
end


"""
```julia
    function crval( filename    :: AbstractString, 
                    model       :: MLmodel = MDM(Fisher);
            # Arguments passed to both encode and crval
            verbose     :: Bool = true,
            threaded    :: Bool = true,
            # Arguments passed to readNY
            toFloat64   :: Bool = true,
            bandStop    :: Tuple = (),
            bandPass    :: Tuple = (),
            bsDesign    :: DSP.ZeroPoleGain = Butterworth(8),
            bpDesign    :: DSP.ZeroPoleGain = Butterworth(4),
            rate        :: Union{Real, Rational, Int} = 1,
            upperLimit  :: Union{Real, Int} = 0,
            getTrials   :: Union{Bool, Vector{String}} = true, 
            stdClass    :: Bool = true, 
            msg         :: String="",
            # Arguments passed to encode
            covtype = LShrLW,
            targetLabel :: String = "target",
            overlapping :: Bool = false,
            weights = :a,
            pcadim      :: Int = 8,
            standardize :: Bool = false,
            tikh        :: Union{Real, Int} = 0,
            useBLAS     :: Bool = true,
            reg         :: Symbol = :rmt,
            tol         :: Real = 1e-6,
            maxiter     :: Int = 200,
            # Arguments passed to crval
            pipeline    :: Union{Pipeline, Nothing} = nothing,
            nFolds      :: Int     = 8,
            shuffle     :: Bool    = false,
            scoring     :: Symbol  = :b,
            hypTest     :: Union{Symbol, Nothing} = :Bayle,
            outModels   :: Bool    = false,
            fitArgs...)
```

Run in sequence the following three functions

1. [`Eegle.InOut.readNY`](@ref)
2. [`encode`](@ref) (from this module)
3. [crval](https://marco-congedo.github.io/PosDefManifoldML.jl/stable/cv/#PosDefManifoldML.crval)

This allows to perform any supported types of cross-validations for a whatever BCI [session](@ref)
in [NY format](@ref). 

**Arguments**

- `filename`: the complete path of either the *.npz* or the *.yml* file of the recording to be used
- `model` : any classifier of type [MLmodel](https://marco-congedo.github.io/PosDefManifoldML.jl/stable/MainModule/#MLmodel). Default: the default [MDM](https://marco-congedo.github.io/PosDefManifoldML.jl/stable/mdm/#PosDefManifoldML.MDM) classifier.

!!! note "BCI paradigm"
    The [BCI paradigm](@ref) is assumed to be the one stored in the file `filename` (either `:ERP`, `:P300`, or `:MI`)

**Optional Keyword Arguments**

A reminder only is given here. For details, see the function each [kwarg](@ref "Acronyms") is passed to.

- The following are passed to [`Eegle.InOut.readNY`](@ref) for reading and pre-processing the data: 
    - `toFloat64`: conversion of data to Float64
    - `bandStop`, `bandPass`, `bsDesign`, `bpDesign`: (filter settings)
    - `rate`: resampling
    - `upperLimit`: artifact rejection
    - `getTrials`: classes to be read from the file
    - `stdClass`: standardization of class labels according to **Eegle**'s conventions
    - `msg`: meassage to be printed once the data has been read.
- the following are passed to [`encode`](@ref) to encode the trials as covariance matrices: 
    - `covtype`: type of covariance matrix estimation 
    - `targetLabel`: label of the *target* class (for the P300 paradigm only). Default: `target` 
    - `overlapping`: type of mean *target* ERP estimator used as a prototype (ERP and P300 only)
    - `weights`: whether to use an adaptive weighted mean *target* ERP estimation (ERP and P300 only)
    - `pcadim`: whether to reduce the dimension of the prototype by [PCA](@ref "Acronyms") (ERP and P300 only)
    - `standardize`: whether to standardize the trials before estimating the covariance matrices
    - `tikh`: whether to apply a Tikhonov regularization to the covariance matrices
    - `useBLAS`: whether to use BLAS for computing the [SCM](@ref "Acronyms") covariance estimator
    - `reg`: , `tol`, `maxiter`, `verbose`: options for covariance M-Estimators.
- the following are passed to [crval](https://marco-congedo.github.io/PosDefManifoldML.jl/stable/cv/#PosDefManifoldML.crval): 
    `pipeline`: pre-conditioners for hastening the computations
    `nFolds`: number of cross-validation stratified folds (default: 8)
    `shuffle`: how the folds are generated
    `scoring`: performance index to be computed
    `hypTest`: statistical test of the performance against the chance level
    `outModels`: modulate the output
    `fitArgs...`: additional arguments handed to the `fit` function of the `model`.
- the following are passed to both `encode` and `crval`:
        `verbose`: print informations about some computations
        `threaded`: run the functions in multithreaded mode (in `crval` it is named with unice character ⏩).

!!! note "`nFolds`" 
    The default for all these kwargs are the same as in the functions they are passed to, except `nFolds` (the number of startified folds for the cross-validation), which default, differently from `crval` in *PosDefManifoldML.jl*, is 8.

!!! tip "`fitArgs...`"
    Function `crval` hands any additional kwargs to the `fit` function of the `model`. See [crval](https://marco-congedo.github.io/PosDefManifoldML.jl/stable/cv/#PosDefManifoldML.crval) for details.
    If you pass an invalid arguments, an error will be raised.

**Return**
If `outModels` is false (default), a [CVres](https://marco-congedo.github.io/PosDefManifoldML.jl/stable/cv/#PosDefManifoldML.CVres) structure 
with the results of the cross-validation, otherwise a 2-tuple holding this `CVres` structure and a vector of the `nFolds` models fitted for each fold.

**Examples**
```julia
# Using the example files provided by Eegle

crval(EXAMPLE_P300_1; bandPass = (1, 24), upperLimit = 1, covtype = SCM)

crval(EXAMPLE_MI_1; bandPass = (8, 32), upperLimit = 1, covtype = SCM)
```
"""    
function crval( filename    :: AbstractString, 
                model       :: MLmodel = MDM(Fisher);
        # Arguments passed to both encode and crval
        verbose     :: Bool = true,
        threaded    :: Bool = true,
	    # Arguments passed to readNY
        toFloat64   :: Bool = true,
        bandStop    :: Tuple = (),
        bandPass    :: Tuple = (),
        bsDesign    :: DSP.ZeroPoleGain = Butterworth(8),
        bpDesign    :: DSP.ZeroPoleGain = Butterworth(4),
        rate        :: Union{Real, Rational, Int} = 1,
        upperLimit  :: Union{Real, Int} = 0,
        getTrials   :: Union{Bool, Vector{String}} = true, 
        stdClass    :: Bool = true, 
        msg         :: String="",
	    # Arguments passed to encode
        covtype = LShrLW,
        targetLabel :: String = "target",
        overlapping :: Bool = false,
        weights = :a,
        pcadim      :: Int = 8,
        standardize :: Bool = false,
        tikh        :: Union{Real, Int} = 0,
        useBLAS     :: Bool = true,
        reg         :: Symbol = :rmt,
        tol         :: Real = 1e-6,
        maxiter     :: Int = 200,
	    # Arguments passed to crval
        pipeline    :: Union{Pipeline, Nothing} = nothing,
        nFolds      :: Int     = 8,
        shuffle     :: Bool    = false,
        scoring     :: Symbol  = :b,
        hypTest     :: Union{Symbol, Nothing} = :Bayle,
        outModels   :: Bool    = false,
        fitArgs...)

    # Read session data: Eegle.InOut.readNY
    o = readNY( filename; 
                toFloat64, 
                bandStop, bandPass, bsDesign, bpDesign,
                rate,
                upperLimit,
                getTrials,
                stdClass,
                msg)

    # Encode trials: 
    𝐂 = encode( o;
                # paradigm = o.paradigm,
                covtype,
                targetLabel,
                overlapping,
                weights,
                pcadim,
                standardize,
                tikh,
                useBLAS,
                reg,
                tol,
                maxiter,
                verbose,
                threaded)

    # Cross-validation: PosDefManifoldML.crval                
    return crval(model, 𝐂, o.y; 
                pipeline,
                nFolds,
                shuffle,
                scoring,
                hypTest,
                outModels,
                verbose,
                ⏩ = threaded,
                fitArgs...)
    
end

end # module
