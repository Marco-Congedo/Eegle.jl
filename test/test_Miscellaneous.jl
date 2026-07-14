println("\x1b[95m", "\nTesting module Eegle.Miscellaneous.jl...", "\x1b[0m")

## minima: 
@testset "minima                         " begin  
    x = [2, 1, 2, 1, 2]
    m = minima(x)
    @test norm(m[1] .- [2, 4]) ≈ 0
end;


## maxima: 
@testset "maxima                         " begin         
    x = [1, 2, 1, 2, 1]
    m = maxima(x)
    @test norm(m[1] .- [2, 4]) ≈ 0
end;


## waste: execute only
@testset "waste                          " begin       
    x = randn(10, 10)
    waste(x)
    @test 0==0 # dummy test
end;

## parseTutorial
@testset "parseTutorial                  " begin    
   # skip as it is only needed for documentation 
   @test 0==0 # dummy test
end;
