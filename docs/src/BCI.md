```@meta
CurrentModule = Eegle
end
```

## BCI.jl

This module implements **machine learning** for EEG data and, particularly, brain-computer interface data, using Riemannian geometry. Data encoding is achieved
by estimating a form of covariance matrix for the EEG epochs or BCI trials.

For **tutorials**, see [Machine Learning](@ref). 

## Resources for Covariance Matrices

For **manipulating covariance matrices using Riemannian geometry** — see package [PosDefManifold.jl](https://github.com/Marco-Congedo/PosDefManifold.jl).

For **machine learning based on Riemannian geometry** — see package [PosDefManifoldML.jl](https://github.com/Marco-Congedo/PosDefManifoldML.jl).

For methods based on the **diagonalization of one or more covariance matrices**, see package [Diagonalizations.jl](https://github.com/Marco-Congedo/Diagonalizations.jl).

Fourier cross-spectra and coherence matrices are special forms of covariance matrices. For producing them, see [FourierAnalysis.jl](https://github.com/Marco-Congedo/FourierAnalysis.jl).


## Methods

|  Function      |           Description             |
|:-----------------------|:----------------------------------|
| [`Eegle.BCI.covmat`](@ref) | Many covariance matrix estimators (2 methods)|
| [`Eegle.BCI.encode`](@ref) | Encode all trials in a given EEG recording using Riemannian geometry|
| [`Eegle.BCI.crval`](@ref) | Encode all trials in a given EEG recording using Riemannian geometry|

📖
```@docs
    Eegle.BCI.covmat
    Eegle.BCI.encode
    Eegle.BCI.crval
```
