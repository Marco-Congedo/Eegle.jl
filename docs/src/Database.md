```@meta
CurrentModule = Eegle
```

## Database.jl

This module implements tools to facilitate the work with EEG databases, in particular, **BCI databases** in **NY format** — see the [FII BCI Corpus Overview](@ref).

To learn how to use BCI databases, see [Tutorial ML 2](@ref).

Most functionalities of this module are also encapsulated in the [pyLittleEegle](https://github.com/FhmDmi/pyLittleEegle) package for the Python language.


## Structures

|  Function            |           Description             |
|:---------------------|:----------------------------------|
|[`Eegle.Database.InfoDB`](@ref)      | structure holding the information summarizing an EEG-BCI database |

## Methods

|  Function            |           Description             |
|:---------------------|:----------------------------------|
|[`Eegle.Database.loadDB`](@ref)        | return a list of *.npz* files in a directory (this is considered a [database](@ref)) |
|[`Eegle.Database.infoDB`](@ref)        | print, save and return metadata about a database |
|[`Eegle.Database.selectDB`](@ref)      | select databases and sessions based on inclusion criteria
|[`Eegle.Database.weightsDB`](@ref)     | get weights for each session of a database for statistical analysis |
|[`Eegle.Database.downloadDB`](@ref)    | run a web-based GUI to download the FII BCI corpus |
|[`Eegle.Database.corpusDir`](@ref)     | return the directory where the FII BCI corpus has been downloaded |

📖
```@docs
    Eegle.Database.InfoDB
    Eegle.Database.loadDB
    Eegle.Database.infoDB
    Eegle.Database.selectDB
    Eegle.Database.weightsDB
    Eegle.Database.downloadDB
    Eegle.Database.corpusDir
```
