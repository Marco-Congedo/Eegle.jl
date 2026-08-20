println("\x1b[95m", "\nTesting module Eegle.Processing.jl...", "\x1b[0m")

## filtfilt: already tested in test_Preprocessing.jl


## filtfilt
@testset "filtfilt                       " begin   
    o = readNY(EXAMPLE_P300_1)
    X = filtfilt(o.X, o.sr, Bandpass(1, 24))
    @test X[1, 1] ≈ -23757.54529919358 atol=1e-9
    @test X[end, end] ≈ -4.418407673642761 atol=1e-9
end;

## centeringMatrix
@testset "car!                           " begin   
    X1 = randn(32, 19)
    # CAR
    X_car = car!(copy(X1))
    @test norm(mean(X_car; dims=2))/size(X1, 1) < tol
end;

## globalFieldPower
@testset "globalFieldPower               " begin       
    ne = 19
    X2 = car!(randn(128, ne))
    @test norm(globalFieldPower(X2)-sum(X2.^2; dims=2))/size(X2, 1) < tol
end;

@testset "globalFieldRMS                 " begin 
    ## globalFieldRMS
    ne = 19
    X3 = car!(randn(128, ne))
    @test norm(globalFieldRMS(X3)-sqrt.(sum(X3.^2; dims=2)./size(X3, 2)))/size(X3, 1) < tol
end;

## epoching
@testset "epoching                       " begin    
    X4 = randn(6144, 19)
    sr = 128
    # standard 1s epoching with 50% overlap
    ranges = epoching(X4, sr;
                wl = sr,
                slide = sr ÷ 2)
    @test ranges[1:3] == [1:128, 65:192, 129:256]

    ranges = epoching(X4, sr;
    wl = sr * 4)
    @test ranges[1:2]==[1:512, 513:1024]

    # adaptive epoching of θ (4Hz-7.5Hz) oscillations (execute only)
    Xθ = filtfilt(X4, sr, Bandpass(4, 7.5))
    ranges = epoching(Xθ, sr;
    minSize = round(Int, sr ÷ 4), # at least one θ cycle
    lowPass = 7.5)  # ignore minima due to higher frequencies
end;

