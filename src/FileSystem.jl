# v 0.4 May 2023
# v 0.5 May 2025
# Part of the Eegle.jl package.
# Copyright Marco Congedo, CNRS, University Grenoble Alpes.

module FileSystem

# Functions:

# fileBase | remove the extension from a file name
# fileExt | get the extension (with dot) of a file
# ChangeFileExt | change the file extension
# getFilesInDir | get all files in a directory 
# getFoldersInDir | get all folders in a directory

import Eegle

# Module REPL text colors
const titleFont     = "\x1b[95m"
const separatorFont = "\x1b[35m"
const defaultFont   = "\x1b[0m"
const greyFont      = "\x1b[90m"


export
    fileBase,
    fileExt,
    changeFileExt,
    getFilesInDir,
    getFoldersInDir,
    writeVector

"""
```julia
    function fileBase(file::String)
```
Return `file`, including the complete path, without the extension.

!!! tip "basename"
    Julia's `basename` function returns instead the file name with no path and with extension

**Example**
```julia
fileBase(joinpath(homedir(), "myfile.txt"))
# return (joinpath(homedir(), "myfile"))
```
"""
fileBase(file::String) = file[begin:findlast(==('.'), file)-1]

"""
```julia
    function fileExt(file::String)
```
Return the extension of a `file`, including the dot.

**Example**
```julia
fileExt(joinpath(homedir(), "myfile.txt")) 
# return ".txt" 
```
"""
fileExt(file::String) = file[findlast(==('.'), file):end]

"""
```julia
    function changeFileExt(file::String, ext::String)
```

Return the complete path of `file` with extension changed to `ext`.

**Example**
```julia
changeFileExt(joinpath(homedir(), "myfile.txt"), ".csv") 
# return joinpath(homedir(), "myfile.csv")
```
"""
changeFileExt(file::String, ext::String) = fileBase(file) * ext

"""
```julia
    function getFilesInDir(dir::Union{String, Vector{String}}; 
        ext::Tuple=(), isin::String="")
```

Return a vector of strings comprising the complete path of all files in directory `dir`.

**Arguments**
- `dir`, which can be a directory or a vector of directories.

**Optional Keyword Arguments**
- `ext` is an optional tuple of file extensions. If it is provided, return only the files with those extensions. The extensions must be entered in lowercase.
- If a string is provided as `isin`, return only those files whose name contains the string.

**Examples**
```julia
using Eegle # or using Eegle.FileSystem

S=getFilesInDir(@__DIR__) # start at current directory.

S=getFilesInDir(@__DIR__; ext=(".txt", ))

S=getFilesInDir(@__DIR__; ext=(".txt", ".jl"), isin="Analysis")
```
"""
getFilesInDir(dir::String; ext::Tuple=(), isin::String="") =
if !isdir(dir) @error "Eegle package, function `getFilesInDir`: input directory is incorrect!"
else
    S=[]
    for (root, dirs, files) in walkdir(dir)
        if root==dir
            for file in files
                if ext==() || ( lowercase(string(file[last(findlast(".", file)): end])) ∈ ext )
                    if occursin(isin, file) # if isin=="" this is always true
                        push!(S, joinpath(root, file)) # complete path and file name
                    end
                end
            end
        end
    end
    isempty(S) && @warn "Eegle package, function `getFilesInDir`: input directory does not contain any files"
    return Vector{String}(S)
end

# return a vector containing all files in all directories in `dirs`
# See getFilesInDir here above for arguments `ext` and `isin`
function getFilesInDir(dirs::Vector{String}; ext::Tuple=(), isin::String="")
    S = [getFilesInDir(dir; ext = ext, isin = isin) for dir ∈ dirs]
    return reduce(vcat, S)
end

"""
```julia
    function getFoldersInDir(dir::String; isin::String="")
```

Return a vector of strings comprising the complete path of all directories in directory `dir`.

If a string is provided as kwarg `isin`, return only the directories whose name
contains the string.

**Examples**
```julia
using Eegle # or using Eegle.FileSystem

S=getFoldersInDir(@__DIR__)

S=getFoldersInDir(@__DIR__; isin="Analysis")
```
"""
getFoldersInDir(dir::String; isin::String="") =
if !isdir(dir) @error "Function `getFoldersInDir`: input directory is incorrect!"
else
    S=[]
    for (root, dirs, files) in walkdir(dir)
        if root==dir
            for dir in dirs
                if occursin(isin, dir) # if isin=="" this is always true
                    push!(S, joinpath(root, dir)) # complete path and file name
                end
            end
        end
    end
    isempty(S) && @warn "Function `getFoldersInDir`: input directory does not contain any folders"
    return Vector{String}(S)
end



end # module
