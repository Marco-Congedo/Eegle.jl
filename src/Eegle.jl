module Eegle

using Reexport

# Eegle Basic Eco-System
@reexport using CovarianceEstimation,
                Diagonalizations,
                Distributions,
                DSP,
                FourierAnalysis,
                LinearAlgebra,
                NPZ,
                PermutationTests,
                PosDefManifold, 
                PosDefManifoldML, 
                Statistics,
                StatsBase

# Package REPL text colors
const titleFont     = "\x1b[95m"
const separatorFont = "\x1b[35m"
const defaultFont   = "\x1b[0m"
const greyFont      = "\x1b[90m"

export Eegle

include("FileSystem.jl");       @reexport using .FileSystem
include("Miscellaneous.jl");    @reexport using .Miscellaneous
include("Preprocessing.jl");    @reexport using .Preprocessing
include("Processing.jl");       @reexport using .Processing


# modules with internal dependencies
include("ERPs.jl");             @reexport using .ERPs
include("InOut.jl");            @reexport using .InOut
include("CovarianceMatrix.jl"); @reexport using .CovarianceMatrix
include("Database.jl");         @reexport using .Database


# export 

end # module
