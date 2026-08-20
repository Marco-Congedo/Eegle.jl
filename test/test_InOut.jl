println("\x1b[95m", "\nTesting module Eegle.InOut.jl...", "\x1b[0m")

using Test

## readSensors
@testset "readSensors                    " begin
    tmp = tempname()

    open(tmp, "w") do io
        println(io, "3")
        println(io, "Fz")
        println(io, "Cz")
        println(io, "Pz")
    end

    s = readSensors(tmp)
    @test s == ["Fz", "Cz", "Pz"]

    s = readSensors(tmp; hasHeader=false)
    @test s == ["3", "Fz", "Cz", "Pz"]

    @test_throws ArgumentError readSensors(tempname())

    rm(tmp)
end;


## writeASCII/readASCII (Matrix{Float64})
@testset "write/read ASCII real          " begin
    X = randn(20,5)

    tmp = tempname()*".txt"

    writeASCII(X, tmp)

    Y = readASCII(tmp)

    @test size(Y) == size(X)
    @test maximum(abs.(X-Y)) < 1e-5

    rm(tmp)
end;


## overwrite protection
@testset "writeASCII overwrite           " begin
    tmp = tempname()*".txt"

    writeASCII(randn(2,2), tmp)

    @test isfile(tmp)

    writeASCII(randn(2,2), tmp; overwrite=true)

    rm(tmp)
end;


## Matrix{String}
@testset "writeASCII string matrix       " begin
    X = ["a" "b";
         "c" "d"]

    tmp = tempname()*".txt"

    writeASCII(X, tmp)

    lines = readlines(tmp)

    @test length(lines) == 2

    rm(tmp)
end;


## Vector{String}
@testset "writeASCII string vector       " begin
    v = ["one","two","three"]

    tmp = tempname()*".txt"

    writeASCII(v, tmp)

    @test readlines(tmp) == v

    writeASCII(v, tmp; overwrite=true, oneline=true)

    @test occursin("one two three", read(tmp,String))

    rm(tmp)
end;


## readASCII multiple files
@testset "readASCII multiple             " begin
    tmp1 = tempname()*".txt"
    tmp2 = tempname()*".txt"

    writeASCII(randn(5,2), tmp1)
    writeASCII(randn(6,2), tmp2)

    X = readASCII([tmp1,tmp2])

    @test length(X)==2

    X = readASCII([tmp1,tmp2]; skip=[2])

    @test length(X)==1

    rm(tmp1)
    rm(tmp2)
end;


## _standardizeClasses MI
@testset "_standardizeClasses MI         " begin

    stim = Int64[0,10,20,10,30]

    s,c = Eegle.InOut._standardizeClasses(
        :MI,
        ["left_hand","right_hand","feet"],
        [10,20,30],
        stim)

    @test c == ["left_hand","right_hand","feet"]
    @test s == [0,1,2,1,3]

end;


## already standardized
@testset "_standardizeClasses standard   " begin

    stim = Int64[0,1,2,1]

    s,c = Eegle.InOut._standardizeClasses(
        :P300,
        ["nontarget","target"],
        [1,2],
        stim)

    @test s == stim
    @test c == ["nontarget","target"]

end;



