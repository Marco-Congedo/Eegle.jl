```@meta
CurrentModule = Eegle
```

# Database.jl

This module implements tools to work with EEG databases, in particular, **BCI databases** in **NY format** — see the [BCI Databases Overview](@ref).

To learn how to use BCI databases, see the **tutorials** xxx.


## Methods

|  Function            |           Description             |
|:---------------------|:----------------------------------|
|[`Eegle.Database.infoDB`](@ref)      | immutable structure holding the information summarizing an EEG database |
|[`Eegle.Database.loadNYdb`](@ref)    | return a list of .npz files in a directory (this is considered a 'database') |
|[`Eegle.Database.infoNYdb`](@ref)    | print, save and return metadata about a database |
|[`Eegle.Database.selectDB`](@ref)    | select database folders based on paradigm and class requirements
|[`Eegle.Database.weightsDB`](@ref)   | get weights for each session of a database for statistical analysis |
📖
```@docs
    Eegle.Database.infoDB
    Eegle.Database.loadNYdb
    Eegle.Database.infoNYdb
    Eegle.Database.selectDB
    Eegle.Database.weightsDB
```
