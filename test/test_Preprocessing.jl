println("\x1b[95m", "\nTesting module Eegle.Preprocessing.jl...", "\x1b[0m")

## standardize
@testset "standardize                    " begin      
        X = randn(128, 19)
        stX = standardize(X)
        m = mean(stX)
        v = var(stX; mean=m)
        @test m < tol
        @test v - 1 < tol
        stX = standardize(X; robust=true, prop=0.1) # execute only
end;

@testset "standardize" begin
    X = randn(128, 19)

    stX = standardize(X)

    @test abs(mean(stX)) < tol
    @test abs(var(stX) - 1) < tol

end

## resample (Downsampling tested and the other resampling cases executed only)
#=
@testset "resample                       " begin      
    sr = 128
    X1 = filtfilt(randn(sr*10, 19), sr, Bandpass(1, sr ÷ (3*4)); designMethod = Butterworth(8))
    Y = resample(X1, sr, 1//4) # downsample by a factor 4
    Z = resample(Y, sr ÷ 4, 4) # upsample by a factor of 4

    Xs =spectra(X1, sr, sr).y
    Zs = spectra(Z, sr, sr).y
    @test norm(Xs-Zs)/norm(Xs) < 0.001

    Y=resample(X1, sr, 2) # upsample by a factor 2, i.e., double the sampling rate
    Y=resample(X1, sr, 100/sr) # downsample to 100 samples per second

    @test X1 === resample(X1, sr, 1)    

    stim = zeros(Int, size(X1,1))
    stim[100] = 1
    stim[500] = 2

    Y, stim2 = resample(X1, sr, 1//2; stim=stim)

    @test size(Y,1) == length(stim2)
    @test sort(unique(stim2)) == [0,1,2]    

    Y, stim2 = resample(X1, sr, 1; stim=stim)

    @test Y === X1
    @test stim2 === stim    
end;
=#

## removeChannels (one case is tested and the others are executed only)
@testset "removeChannels                 " begin  
        X2 = randn(128, 7)
        sensors=["F7", "F8", "C3", "Cz", "C4", "P7", "P8"]
        
        # remove second channel
        X2_, sensors_, ne = removeChannels(X2, 2, sensors)
        @test sensors_ == ["F7", "C3", "Cz", "C4", "P7", "P8"]
        @test norm(X2_ - hcat(X2[:, 1], X2[:, 3:end])) ≈ 0
        
        # remove the first five channels
        X2_, sensors_, ne = removeChannels(X2, collect(1:5), sensors)
        @test ne == 2
        @test sensors_ == ["P7","P8"]
        @test size(X2_) == (128,2)        
        
        # remove the channel labeled as "Cz" in `sensors`
        X2_, sensors_, ne = removeChannels(X2, findfirst(x->x=="Cz", sensors), sensors)
        @test ne == 6
        @test sensors_ == ["F7", "F8", "C3", "C4", "P7", "P8"]
        @test size(X2_) == (128,6)  
        
        # remove the channels labeled as "C3", "Cz", and "C4" in `sensors`
        X2_, sensors_, ne = removeChannels(X2, findall(x->x∈("Cz", "C3", "C4"), sensors), sensors)
        @test ne == 4
        @test sensors_ == ["F7", "F8", "P7", "P8"]
        @test size(X2_) == (128,4)          
        
        # keep only channels labeled as "C3", "Cz", and "C4" in `sensors`
        X2_, sensors_, ne = removeChannels(X2, findall(x->x∉("Cz", "C3", "C4"), sensors), sensors)
        @test ne == 3
        @test sensors_ == ["C3", "Cz", "C4"]
        @test size(X2_) == (128,3)  

end;


@testset "removeSamples" begin

    X = float.(reshape(1:50,10,5))

    stim = [0,1,0,2,0,3,0,0,1,0]

    #
    # remove one sample
    #
    X2, stim2, ns = removeSamples(X,2,copy(stim))

    @test ns == 9
    @test length(stim2)==9
    @test size(X2,1)==9

    #
    # remove several samples
    #
    X3, stim3, ns = removeSamples(
        X,
        [1,3,5],
        copy(stim)
    )

    @test ns==7
    @test size(X3,1)==7
    @test length(stim3)==7

    @test_logs (:warn,) begin
        removeSamples(X,2,copy(stim))
    end

    @test_logs (:warn,) begin
        removeSamples(X,[2,4,6],copy(stim))
    end    

end

## embedLags (executed only, check visually the example)
@testset "removeChannels                 " begin
    X3 = randn(8, 2) # small example to see the effect
    elX = embedLags(X3, 3)

    @test embedLags(X3, 0) === X3

    X = float.(reshape(1:8,4,2))

    Y = embedLags(X,1)

    @test Y[:,1:2] ==
    [
    0 0
    1 5
    2 6
    3 7
    ]

    @test Y[:,3:4] ==
    [
    1 5
    2 6
    3 7
    0 0
    ]    
end;

