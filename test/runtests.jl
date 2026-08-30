using Eegle, Statistics, LinearAlgebra, Test, Random

tol = 1e-12

include("test_FileSystem.jl")
include("test_Preprocessing.jl")
include("test_Processing.jl")
include("test_ERPs.jl")
include("test_BCI.jl")
include("test_InOut.jl")
include("test_Miscellaneous.jl")

