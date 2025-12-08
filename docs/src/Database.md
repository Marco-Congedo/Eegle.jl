```@meta
CurrentModule = Eegle
```

## Database.jl

This module implements tools to facilitate the work with EEG databases, in particular, **BCI databases** in **NY format** — see the [FII BCI Corpus Overview](@ref).

To learn how to use BCI databases, see [Tutorial ML 2](@ref).


## Methods

|  Function            |           Description             |
|:---------------------|:----------------------------------|
|[`Eegle.Database.infoDB`](@ref)      | immutable structure holding the information summarizing an EEG database |
|[`Eegle.Database.loadNYdb`](@ref)    | return a list of *.npz* files in a directory (this is considered a [database](@ref)) |
|[`Eegle.Database.infoNYdb`](@ref)    | print, save and return metadata about a database |
|[`Eegle.Database.selectDB`](@ref)    | select databases and sessions based on inclusion criteria
|[`Eegle.Database.weightsDB`](@ref)   | get weights for each session of a database for statistical analysis |
|[`Eegle.Database.downloadDB`](@ref)  | run a web-based GUI to dowload the FII BCI corpus. |

📖
```@docs
    Eegle.Database.infoDB
    Eegle.Database.loadNYdb
    Eegle.Database.infoNYdb
    Eegle.Database.selectDB
    Eegle.Database.weightsDB
    Eegle.Database.downloadDB
```
