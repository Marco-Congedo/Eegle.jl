```@meta
CurrentModule = Eegle
end
```

## BCI.jl

This module implements **machine learning** for EEG data and, particularly, brain-computer interface data, using Riemannian geometry. Data encoding is achieved
by estimating a form of covariance matrix for the EEG epochs or BCI trials.

For **tutorials**, see [Machine Learning](@ref). 

## Resources for Covariance Matrices

| Package  | Description | 
|:---------|:---------|
| [PosDefManifold.jl](https://github.com/Marco-Congedo/PosDefManifold.jl)     | low-level manipulation of covariance matrices using Riemannian geometry |
| [Diagonalizations.jl](https://github.com/Marco-Congedo/Diagonalizations.jl) |  methods based on the diagonalization of one or more covariance matrices |
| [FourierAnalysis.jl](https://github.com/Marco-Congedo/FourierAnalysis.jl)   |  Fourier cross-spectra and coherence matrices (special forms of covariance matrices) |

## Methods

|  Function                   |           Description             |
|:----------------------------|:----------------------------------|
| [`Eegle.BCI.covmat`](@ref)  | many covariance matrix estimators (2 methods)|
| [`Eegle.BCI.encode`](@ref)  | encode all trials in a given EEG recording using Riemannian geometry|
| [`Eegle.BCI.crval`](@ref)   | perform a cross-validation of a Riemannian machine learning model on a BCI session|

📖
```@docs
    Eegle.BCI.covmat
    Eegle.BCI.encode
    Eegle.BCI.crval
```
