```@meta
CurrentModule = Eegle
```

# Processing.jl

This module implements **Processing** for EEG data.

**See also** [Preprocessing.jl](@ref)

## Methods

|  Function      |           Description             |
|:-----------------------|:----------------------------------|
| [`Eegle.Processing.filtfilt`](@ref) | digital filetring of EEG data |
| [`Eegle.Processing.centeringMatrix`](@ref) | the centering matrix (for computing the common average reference) |
| [`Eegle.Processing.globalFieldPower`](@ref) | global field power |
| [`Eegle.Processing.globalFieldRMS`](@ref) | global field root mean square |
| [`Eegle.Processing.expVar`](@ref) | explained variance of spatial filters and in blind source separation |
| [`Eegle.Processing.epoching`](@ref) | epoching of spontaneous EEG  |
📖

```@docs
    Eegle.Processing.filtfilt
    Eegle.Processing.centeringMatrix
    Eegle.Processing.globalFieldPower
    Eegle.Processing.globalFieldRMS
    Eegle.Processing.expVar
    Eegle.Processing.epoching
```
