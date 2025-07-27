```@meta
CurrentModule = Eegle
```

## ERPs.jl

This module implements basic tools fo the analysis of **Event-Related Potentials** (ERPs). 
Many of these tools are useful for working with tagged EEG data in general, for example, with BCI data.

## Extract ERPs

ERPs are EEG potentials time and phase-locked to the presentation of sensory stimuli.

They are extracted averaging **EEG epochs** (**trials**) of fixed duration starting at a fixed position in time with respect to the presentation of stimuli.

**Eegle** handles two ways to extract ERPs:
using a **stimulation vector** or using **marker vectors**. You can swicth from one representation to the other using
the [`stim2mark`](@ref) and [`mark2stim`](@ref) functions.

### stimulation vector

This is an accessory channel holding as many samples as there are in the EEG recording. The value
is zero everywhere, except at samples corresponding to a stimulus presentation, where the value is
a natural number (1, 2, ...), each one coding a stimulus class. We name these numbers the **tag** of each sample.

```
# Toy example of a stimulation vector for two classes
[0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0]
```

### marker vectors

Equivalently, we can cosider a vector holding ``z`` vectors, each one listing the serial numbers
of the samples belonging to each of the possible ``z`` classes.

```
# Representation of the above stimulation vector as markers vector
[[13, 18], [6]]
```

### offset

Several **Eegle** methods allow setting an **offset** to determine the starting sample of all evoked potentials (or trials).
The offset is always to be given in samples. It can be 
- zero (default): it does not affect the stimulations and corresponding markers, 
- negative: the stimulations and markers are shifted back,
- positive: the stimulations and markers are shifted forth.

```
# Example with `offet=-3`; the above stimulation vector and marker vectors becomes
[0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]
[[10, 15], [3]]
```

!!! warning "Data in NY format"
    When data in [NY format](@ref) is read, the offset is applied and reset to zero — see [`readNY`](@ref).

### overlapping

The ERPs are said **overlapping** if the minimum inter-stimulus interval is shorter than the ERP window length,
that is, if a stimulus can be presented before the preceeding evoked response has ended.
In this situation, the multivariate regression (MR) method can provide better ERP estimates as compared 
to the standard arithmetic average (AE) [Congedo2016STCP](@cite).

Methods estimating ERPs in **Eegle** feature the `overlapping` boolean [kwarg](@ref "Acronyms"), by which you can switch
between the AE (false) and MR method (true).

!!! note "Overlapping"
    If the ERPs are overlapping and you set `overlapping` to true, all means should be estimated at once;
    In fact, the advantage of the MR method vanishes if the means are computed individually. 
    
    In general, do not set `overlapping` to true for computing only one mean, even if the stumulations are overlapping.
    In this case the AE and MR methods are equivalent, but the AE is faster and more accurate.
    
    For the same reason, do not set `overlapping` to true if the ERPs do not actually overlap.

## Resources for ERPs

For **classifying ERPs using Riemannian geometry** — see package [PosDefManifoldML.jl](https://github.com/Marco-Congedo/PosDefManifoldML.jl).

For **spatial filters** increasing the signal-to-noise ratio of ERPs — see the `CSP` and `CSTP` functions in package [Diagonalizations.jl](https://github.com/Marco-Congedo/Diagonalizations.jl) and article [Congedo2016STCP](@cite).

For the analysis of **time-locked and phase-locked components of ERPs**, as well as **ERP synchronization measures**, in the time-frequency domain — see package [FourierAnalysis.jl](https://github.com/Marco-Congedo/FourierAnalysis.jl) and companion article [congedo2018non](@cite).

[Unfold](https://github.com/unfoldtoolbox/Unfold.jl) is a package dedicated to ERP analysis.


## Methods

|  Function      |           Description             |
|:-----------------------|:----------------------------------|
| [`Eegle.ERPs.mean`](@ref) | compute ERPs from an EEG recording (2 methods)|
| [`Eegle.ERPs.stim2mark`](@ref) | convert a [stimulation vector](@ref) into [marker vectors](@ref)|
| [`Eegle.ERPs.mark2stim`](@ref) | convert [marker vectors](@ref) into a [stimulation vector](@ref) |
| [`Eegle.ERPs.merge`](@ref) | merge and reorganize [marker vectors](@ref) |
| [`Eegle.ERPs.trialsWeights`](@ref) | compute adaptive weights for average ERP estimations |
| [`Eegle.ERPs.trials`](@ref) | extract trials (e.g., ERPs) from a  tagged EEG recording |
| [`Eegle.ERPs.reject`](@ref) | reject trials (e.g., ERPs) in a tagged EEG recording |
📖
```@docs
    Eegle.ERPs.mean
    Eegle.ERPs.stim2mark
    Eegle.ERPs.mark2stim
    Eegle.ERPs.merge
    Eegle.ERPs.trials
    Eegle.ERPs.trialsWeights
    Eegle.ERPs.reject
```
