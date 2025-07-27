```@meta
CurrentModule = Eegle
```

## Preprocessing.jl

This module implements **preprocessing** for EEG data.

**See also** [Processing.jl](@ref)

## Methods

|  Function      |           Description             |
|:-----------------------|:----------------------------------|
| [`Eegle.Preprocessing.resample`](@ref) | resample EEG data |
| [`Eegle.Preprocessing.standardize`](@ref) | standardize EEG data |
| [`Eegle.Preprocessing.removeChannels`](@ref) | remove channels from EEG data |
| [`Eegle.Preprocessing.removeSamples`](@ref) | remove samples from EEG data |
| [`Eegle.Preprocessing.embedLags`](@ref) | lag embedding of EEG data |

📖
```@docs
    Eegle.Preprocessing.standardize
    Eegle.Preprocessing.resample
    Eegle.Preprocessing.removeChannels
    Eegle.Preprocessing.removeSamples
    Eegle.Preprocessing.embedLags
```