```@meta
CurrentModule = Eegle
```

# FileSystem.jl

This module implements utilities for **working with files and directories**.

It is a complement to the standard
[Julia FileSystem](https://docs.julialang.org/en/v1/base/file/) module.

|  Function      |           Description             |
|:-----------------------|:----------------------------------|
| [`Eegle.FileSystem.fileBase`](@ref) | get a file path without the extension|
| [`Eegle.FileSystem.fileExt`](@ref) | extract the extension from a file name, including the dot |
| [`Eegle.FileSystem.changeFileExt`](@ref) | change the extension of a file |
| [`Eegle.FileSystem.getFilesInDir`](@ref) | search for files in a directory and its subdirectories |
| [`Eegle.FileSystem.getFoldersInDir`](@ref) | search for directories in a directory and its subdirectories |
📖
```@docs
    Eegle.FileSystem.fileBase
    Eegle.FileSystem.fileExt
    Eegle.FileSystem.changeFileExt
    Eegle.FileSystem.getFilesInDir
    Eegle.FileSystem.getFoldersInDir
```
