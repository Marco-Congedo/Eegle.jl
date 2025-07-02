# Eegle

**Eegle** is organized as a collection of independent modules. They are all re-exported, along with fundamental external packages,
forming an integrated library. Thus, if you state

```julia
using Eegle
```

you have access of all functions exported by all **Eegle** modules and by all re-exported external packages.

Like external packages, **Eegle** modules can be used individually. 
For example, if you only need some functions for preprocessing
and signal processing, you can state

```julia
    using Eegle.preprocessing, DSP
```

In this case, however, you must install DSP.jl as well.

## Eegle Integrated Library

### Internal modules

| Code Unit   | Description |
|:------------|:------------|
| [CovarianceMatrix.jl](@ref) | covariance matrix estimations and Riemannian geometry encoding |
| [Database.jl](@ref) | utilities for handling databases |
| [ERPs.jl](@ref) | operations on Event-Related Potentials and BCI trials |
| [FileSystem.jl](@ref) | manipulation of files and directories |
| [InOut.jl](@ref) | reading and writing of data |
| [Miscellaneous.jl](@ref) | miscellaneous functions |
| [Preprocessing.jl](@ref) | EEG preprocessing |
| [Processing.jl](@ref) | EEG Processing |

### Re-exported external packages

|  Package | Scope |
|:-----------------------|:-----------------------|
| [CovarianceEstimation](https://github.com/mateuszbaran/CovarianceEstimation.jl) | covariance matrix estimations |
| [Diagonalizations](https://github.com/Marco-Congedo/Diagonalizations.jl) |  spatial filters, (approximate joint) diagonalization |
| [Distributions](https://github.com/JuliaStats/Distributions.jl) | statistical distributions|
| [DSP](https://github.com/JuliaDSP/DSP.jl) | Julia standard package for digital signal processing|
| [FourierAnalysis](https://github.com/Marco-Congedo/FourierAnalysis.jl) | FFT-based Frequency domain and time-frequency domain |
| [LinearAlgebra](https://bit.ly/2W5Wq8W) | Julia standard package for matrix type and algebra, BLAS, LAPACK  |
| [NPZ](https://github.com/fhs/NPZ.jl)| support for the *NPZ* (NumPy) bynary format |
| [PermutationTests](https://github.com/Marco-Congedo/PermutationTests.jl) | ow-level statistics, (multiple comparison) permutation tests |
| [PosDefManifold](https://github.com/Marco-Congedo/PosDefManifold.jl) |  ore linear algebra, operations on the manifold of positive-definite matrices|
| [PosDefManifoldML](https://github.com/Marco-Congedo/PosDefManifoldML.jl) |  machine learning on the manifold of positive-definite matrices |
| [StatsBase](https://github.com/JuliaStats/StatsBase.jl) |  Julia standard package for basic statistics |
| [Statistics](https://bit.ly/2Oem3li) | Julia standard package for statistics |


### Used but not re-exported external packages

|  Package | Scope |
|:-----------------------|:-----------------------|
| [CSV](https://github.com/JuliaData/CSV.jl) | support for *CSV* format |
| [DataFrames](https://github.com/JuliaData/DataFrames.jl) | manipulation of tables|
| [Dates](https://github.com/JuliaStdlibs/Dates.jl)| standard Julia support for dates and time manipulation |
| [EzXML](https://github.com/JuliaIO/EzXML.jl)| support for *XML*/*HTML* data formats |
| [Folds](https://github.com/JuliaFolds/Folds.jl)| multi-threaded basic functions |
| [HDF5](https://github.com/JuliaIO/HDF5.jl)| Support for the *HDF5* data format |
| [PrettyTables](https://github.com/ronisbr/PrettyTables.jl)| print data in tables and matrices in a human-readable format |
| [Random](https://github.com/JuliaStdlibs/Random.jl) | random generators |
| [Reexport](https://github.com/simonster/Reexport.jl)| julia macro to re-export symbols (purely internal)|
| [Revise](https://github.com/timholy/Revise.jl)| for development: automatically update function definitions in a running Julia session |
| [Test](https://github.com/JuliaLang/julia/tree/master/stdlib/Test)| for development: Julia standard library for integrating package testing |
| [YAML](https://github.com/JuliaData/YAML.jl)| support for YAML format |

### Other resources

There are many other Julia's packages that can be useful for EEG data analysis and classification.
Here is a non-exhaustive list of links to find resources:

|  Package | Scope |
|:-----------------------|:-----------------------|
| [Julia Neuro](https://julianeuro.github.io/packages) | A collection of packages gor Neuroscience data  |
| [Unfold.jl](https://github.com/unfoldtoolbox/Unfold.jl?tab=readme-ov-file) | An ecosystem for ERP analysis |

## Tips & Tricks

### General T&T

Julia is a just-in-time compiled, column-major, 1-based indexing language.
In practice for using this package this means that:
- The first time you execute a function, it will be compiled. From the second on, it will go fast
- EEG data are organized in ``T×N`` matrices, where ``T`` and ``N`` denotes the number of samples and channels, respectively
- `for` loops starts at 1. For indexing, whenever possible, in Julia you should prefer using [eachindex](https://docs.julialang.org/en/v1/base/arrays/#Base.eachindex).

### ℍ and the ℍVector type

Covariance matrices and vectors thereof play an important role in EEG data analysis and classification.
**Eegle** follows the framework of package [PosDefManifold](https://github.com/Marco-Congedo/PosDefManifold.jl), which requires flagging these matrices as `Hermitian`.
Reading this documentation on [typecasting matrices](https://marco-congedo.github.io/PosDefManifold.jl/dev/MainModule/#typecasting-matrices-1)
can turn useful.

## How to Contribute

### Code conventions

- When using a method of the **Eegle** package, qualify the module it is taken from, for example: 
    - `Eegle.FileSystem.getFilesInDir(dbDir; ext=(".npz", ), isin)`
- Communicate the module and function when printing a messages within a function, for example: 
    - `@warn "Eegle.Database, function loadNYdb: the $filemane files has not been found:\n"`
- The name of internal functions (not-exported) begins by an underscore, for example: 
    - `function _weightsDB(...)`
- The name of functions modifying one or more arguments ends with an exclamation mark, for example:
    - `function myFunc!(...)`
- Whenever appropriate, methods should give feedback to the user. Use meaningful symbols such as:
    - `✓`, `✗`, `⊘`, `⚠️` — see [here](https://docs.julialang.org/en/v1/manual/unicode-input/) for a list of supported unicode symbols
- For name of functions composed by several words, capitalize the words starting from the second, for example:
    - `function myFunc(...)`
- Acronyms in name of functions may or may not be fully capitalized, for example: 
    - `function weightsDB(...)`
- If you add a method in a module, update the commented "CONTENT" section in the module's header
- If you add a new public function in a module, make sure: 
    - you add the documentation right on top of the function (no blank lines)
    - you add the function in the `export` section of the module
    - you add the function in the docstring of the module's .md file in the docs/src directory.
- Leave an empty space around the `=` sign
- Follows Julia general conventions:
    - functions starts by a lower-case letter, while structures and modules by a capital letter 
    - in general, constants are fully capitalized
    - functions modifying one or more of the arguments start by `!`
    - internal functions start by `_`.

### Documentation

- For simple functions and methods, the documentation should be short and rather illustrated by examples
- For complex functions and methods (four or more arguments), the documentation can comprise up to six sections: 
    - **Tutorial** (if tutorials are available)
    - **Description** (if the method is not simple and common knowledge)
    - **Arguments** (if applicable) 
    - **Optional Keyword Arguments** (if applicable)
    - **Return** (always)
    - **Examples** (unless it is trivial). 
- Whenever relevant, the documentation of functions should include (before the **Examples** section):
    - a **See** line providing the link to related functions in **Eegle**
    - a **See Also** line providing the link to somehow related functions or to function not in **Eegle**
- Always start the **Examples** section with line:
```julia 
using Eegle 
```
- When a function has more then two arguments and optional keyword arguments (kargs), they are given as a list 
    and their possible values, whenever relevant, as a sub-list 
- Enclose functions, arguments and optional keyword arguments in backticks, for example, `mean`
- Use acronym and refer to the [Acronyms](@ref) section, e.g., [BSS](@ref Acronyms)
- Do not confuse the em dash hyphen — (a long dash used in text punctuation) with the usual en dash, used, for example, to make lists in markdown.
- Only the last item of a list or sub-list should ened with a dot
- The first word of the title of admonitions ('tip', 'warning', etc.) is capitalized, unless it is a function or argument.
- Fully qualify links to functions of other modules, for example: [`Eegle.Preprocessing.removeSamples`](@ref), except:
    - functions whose name is imported from an existing external package, for example: [`mean`](@ref)
    - functions defined in the same module you are writing the documentation in.
- End a list without punctuation, except for the last item of the list, like in the list you are reading now
- For Markdown text:
    - headings of level 1 and 2 capitalze all words
    - headings of level 3 capitalize only the first word
    - headings of level 4 do not capitalize any words. 

To get started, use the existing documentation as a template.

### Notation & Nomenclature

The following notation is followed throughout the code:

- **quantities** are denoted by upper case letters and their index by lower-case letters, e.g., ``n∈[1..N]``
- **vectors** are denoted using lower-case letters, e.g., `y`,
- **matrices** using upper case letters, e.g., `X`
- **sets (vectors) of matrices** using bold upper-case letters, e.g., `𝐗` (escape sequence \bfX).

In the code examples, bold upper-case letters may replaced by
upper case letters in order to facilitate testing the code in the REPL.

The following nomenclature is used consistently:

- `X`: an **EEG data matrix** (`𝐗`: a vector of **EEG data matrices**)
- `C`, `P`, `Q`: **positive-definite matrices** (idem)
- `D`: a **diagonal matrix** (idem)
- `U`: an **orthogonal matrix** (idem)
- `λ`: an **eigenvalue** (idem)
- `o`: an **EEG data structure** (idem)
- `y`: a vector of **class labels**
- `z`: **number of classes** for ERP or BCI data
- `k`: **number of matrices** in a set

## Acronyms

- AI: affine-invariant (also known as Fisher-Rao metric)
- BCI: brain-computer interface
- BSS: Blind Source Separation
- CAR: common average reference
- cv: cross-validation
- EEG: electroencephalography
- ENLR: elastic-net gogistic regression
- ERP: event-related potential
- kwarg: (optional) keyword argument
- MDM: minimum distance to mean
- MI: motor Imagery (a BCI paradigm)
- P300: the P300 BCI paradigm
- SVM: support-vector machine
