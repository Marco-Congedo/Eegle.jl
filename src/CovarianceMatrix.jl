#= 
    CovMat.jl - version 0.1, April 2025  
    Part of the Eegle.jl package  
    Copyright Marco Congedo, CNRS, University Grenoble Alpes  

Estimation of covariance matrices for EEG trials, including regularized and prototype-based covariance estimation.
=#

module CovarianceMatrix

using Base.Threads: @threads
using LinearAlgebra: eigvecs, BLAS
using PosDefManifold
using CovarianceEstimation
using Diagonalizations: SCM, LShrLW, NShrLW
using PosDefManifoldML: PosDefManifoldML, transform!, Tikhonov

using Eegle.Preprocessing, Eegle.InOut, Eegle.ERPs

include("tools/Tyler.jl")
using .Tyler  # relative import with dot     

import Eegle

# Module REPL text colors
const titleFont     = "\x1b[95m"
const separatorFont = "\x1b[35m"
const defaultFont   = "\x1b[0m"
const greyFont      = "\x1b[90m"


export  covmat, 
        encode

"""
```julia
(1) function covmat(X::AbstractMatrix{T};
        covtype = SCM,
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
- `covtype`: covariance estimator (default = `SCM`):
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
using Eegle # or using Eegle.CovarianceMatrix

# Method (1)

C = covmat(randn(128, 19)) # sample covariance matrix

C = covmat(randn(128, 19); covtype=LShrLW)

C = covmat(randn(128, 19); covtype=:Tyler)

# Method (2)

𝐗 = [randn(128, 19) for k=1:10]

𝐂 = covmat(𝐗)

C = covmat(𝐗; covtype=LShrLW)

C = covmat(𝐗; covtype=:Tyler)
```    
"""
function covmat(X::AbstractMatrix{T};
                covtype = SCM,
                prototype::Union{AbstractMatrix, Nothing} = nothing,
                standardize::Bool = false,
                useBLAS::Bool = true,
                threaded::Bool = true, # not used. included for homogeneity with the other method
                reg::Symbol = :rmt,
                tol::Real = real(T)(1e-6),
                maxiter::Int = 200,
                verbose::Bool = false) where T<:Union{Real, Complex}

    T<:Complex && covtype≠SCM && throw(ArgumentError("Eegle.CovarianceMatrix, function `covmat`: for complex data only `covtype=SCM` is supported"))

    transform = standardize ? Eegle.Preprocessing.standardizeEEG : identity

    if (covtype==SCM && useBLAS) # fast computations of the sample covariance matrix
        Y = prototype == nothing ? transform(X) : [transform(X) prototype]
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
        return ℍ(CovarianceEstimation.cov(covtype, prototype == nothing ? transform(X) : [transform(X) prototype]))
    end
end


function covmat(𝐗::AbstractVector{<:AbstractArray{T}}; 
                covtype=SCM, 
                prototype::Union{AbstractMatrix, Nothing}=nothing, 
                standardize::Bool = false, 
                useBLAS:: Bool = true,
                threaded::Bool = true, # for homogeneity with the other method
                reg::Symbol = :rmt,
                tol::Real = real(T)(1e-6),
                maxiter::Int = 200,
                verbose::Bool = false) where T<:Union{Real, Complex}

    T<:Complex && covtype≠SCM && throw(ArgumentError("Eegle.CovarianceMatrix, function `covmat`: for complex data only `covtype=SCM` is supported"))

    transform = standardize ? Eegle.Preprocessing.standardizeEEG : identity
    
    defineTrial(i, prototype) = prototype == nothing ? transform(𝐗[i]) : [transform(𝐗[i]) prototype]

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
    function encode(o::EEG, paradigm::Symbol;
        covtype=SCM,
        targetLabel::String = "",
        overlapping::Bool = false,
        weights = :a,
        pcadim::Int = 8,
        standardize::Bool = false,
        tikh = 0,
        useBLAS = true,
        threaded = true,
        reg::Symbol = :rmt,
        tol::Real = real(T)(1e-6),
        maxiter::Int = 200,
        verbose::Bool = false)
```
Encode all trials in an EEG recording as covariance matrices for a given BCI paradigm.
This is used in Riemannian geometry machine learning.
The supported BCI paradigms are *Motor Imagery (MI)*, *Event-Related Potentials (ERP)* and *P300*.
For details, see *Appendix I* in [Congedo2017Review](@cite).

**Arguments**
- `o`: an instance of the [`EEG`](@ref) data structure containing trials and metadata
- `paradigm`: [BCI paradigm](@ref), either `:ERP`, `:P300`, or `:MI`:
    - for `:ERP`, prototypes for all classes are stacked and covariance is computed on super-trials
    - for `:P300`, only the target class prototype is stacked
    - for `:MI`, no prototype is used; covariance is computed on the trial as it is.

**Optional Keyword Arguments**
- `covtype`, `useBLAS`, `tol`, `maxiter` and `verbose` — see [`Eegle.CovarianceMatrix.covmat`](@ref), to which they are passed.
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
using Eegle # or using Eegle.CovarianceMatrix
xxx
```
"""
function encode(o::EEG, paradigm::Symbol;
                covtype=SCM,
                # for ERP modality only
                targetLabel::String = "", 
                overlapping::Bool = false,
                weights =:a, 
                pcadim::Int = 8, 
                # for both ERP and MI modality
                standardize::Bool = false,
                tikh = 0, 
                useBLAS = true,
                threaded = true)

    o.trials===nothing && throw(ArgumentError("Eegle.CovarianceMatrix, function `encode`: The `EEG` structure given as first argument does not holds the trials. Make sure argument `getTrials` is not set to false when you open the EEG data in NY format using the `readNY` function"))

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
        
        return tikh≈0 ? covmat(o.trials; covtype, prototype=Y, standardize, threaded) : 
                PosDefManifoldML.transform!(covmat(o.trials; covtype, prototype=Y, standardize, threaded), Tikhonov(tikh; threaded))
                
    elseif paradigm==:P300

        # get indeces for target class labels"
        TargetIndex = findfirst(isequal(targetLabel), o.clabels)
        TargetIndex === nothing && throw(ArgumentError("Eegle.CovarianceMatrix, function `encode`: target label $targetLabel not found in the class labels of the EEG structure o."))

        # multivariate regression or arithmetic average TARGET ERP mean with data-driven weights
        # multiplied by the square root of the # of target trials to recover the amplitude
        Y=Eegle.ERPs.mean(o.X, o.wl, o.mark; overlapping, weights)[TargetIndex]*sqrt(count(x->x==TargetIndex, o.stim))
        standardize && (Y = Eegle.Preprocessing.standardizeEEG(Y))
        if 0<pcadim<o.ne
            Y=Y*eigvecs(CovarianceEstimation.cov(CovarianceEstimation.SimpleCovariance(), Y))[:, o.ne-pcadim+1:o.ne] # PCA to keep only certain components
        end
        
        return tikh≈0 ? covmat(o.trials; covtype, prototype=Y, standardize, threaded) : 
                PosDefManifoldML.transform!(covmat(o.trials; covtype, prototype=Y, standardize, threaded), Tikhonov(tikh; threaded))

    elseif paradigm==:MI

        return tikh≈0 ? covmat(o.trials; covtype, standardize, threaded) :
                PosDefManifoldML.transform!(covmat(o.trials; covtype, standardize, threaded), Tikhonov(tikh; threaded))

    else
        throw(ArgumentError("Eegle.CovarianceMatrix, function `encode`: only the :ERP, :P300 and :MI BCI paradigm are supported"))
    end
end

end # module
