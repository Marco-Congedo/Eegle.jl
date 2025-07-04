```@meta
CurrentModule = Eegle
end
```

## CovarianceMatrix.jl

This module implements **covariance matrix estimations** for EEG data and **encoding of BCI trials** in the form of covariance matrices.

Covariance matrices are essential objects in EEG data analysis and BCI data classification.

## Resources for Covariance Matrices

For **manipulating covariance matrices using Riemannian geometry** — see package [PosDefManifold.jl](https://github.com/Marco-Congedo/PosDefManifold.jl).

For **machine learning based on Riemannian geometry** — see package [PosDefManifoldML.jl](https://github.com/Marco-Congedo/PosDefManifoldML.jl).

For methods based on the **diagonalization of one or more covariance matrices**, see package [Diagonalizations.jl](https://github.com/Marco-Congedo/Diagonalizations.jl).

Fourier cross-spectra and coherence matrices are special forms of covariance matrices. For producing them, see [FourierAnalysis.jl](https://github.com/Marco-Congedo/FourierAnalysis.jl).


## Methods

|  Function      |           Description             |
|:-----------------------|:----------------------------------|
| [`Eegle.CovarianceMatrix.covmat`](@ref) | Many covariance matrix estimators (2 methods)|
| [`Eegle.CovarianceMatrix.encode`](@ref) | Encode all trials in a given EEG recording |
📖
```@docs
    Eegle.CovarianceMatrix.covmat
    Eegle.CovarianceMatrix.encode
```
