println("\x1b[95m", "Testing module Eegle.Preprocessing.jl...")

## standardize
@testset "standardize" begin
        X = randn(128, 19)
        stX = standardize(X)
        m = mean(stX)
        v = var(stX; mean=m)
        @test m < tol
        @test v - 1 < tol
        stX = standardize(X; robust=true, prop=0.1) # execute only
end;

## resample (Downsampling tested and the other resampling cases executed only)
@testset "resample" begin
    sr = 128
    X1 = filtfilt(randn(sr*10, 19), sr, Bandpass(1, sr ÷ (3*4)); designMethod = Butterworth(8))
    Y = resample(X1, sr, 1//4) # downsample by a factor 4
    Z = resample(Y, sr ÷ 4, 4//1) # upsample by a factor of 4

    Xs =spectra(X1, sr, sr).y
    Zs = spectra(Z, sr, sr).y
    @test norm(Xs-Zs)/norm(Xs) < 0.001

    Y=resample(X1, sr, 2) # upsample by a factor 2, i.e., double the sampling rate
    Y=resample(X1, sr, 100/sr) # downsample to 100 samples per second
end;

## removeChannels (one case is tested and the others are executed only)
@testset "removeChannels" begin
        X2 = randn(128, 7)
        sensors=["F7", "F8", "C3", "Cz", "C4", "P7", "P8"]
        # remove second channel
        X2_, sensors_, ne = removeChannels(X2, 2, sensors)
        @test sensors_ == ["F7", "C3", "Cz", "C4", "P7", "P8"]
        @test norm(X2_ - hcat(X2[:, 1], X2[:, 3:end])) ≈ 0
        # remove the first five channels
        X2_, sensors_, ne = removeChannels(X2, collect(1:5), sensors)
        # remove the channel labeled as "Cz" in `sensors`
        X2_, sensors_, ne = removeChannels(X2, findfirst(x->x=="Cz", sensors), sensors)
        # remove the channels labeled as "C3", "Cz", and "C4" in `sensors`
        X2_, sensors_, ne = removeChannels(X2, findall(x->x∈("Cz", "C3", "C4"), sensors), sensors)
        # keep only channels labeled as "C3", "Cz", and "C4" in `sensors`
        X2_, sensors_, ne = removeChannels(X2, findall(x->x∉("Cz", "C3", "C4"), sensors), sensors)
end;


## embedLags (executed only, check visually the example)
@testset "removeChannels" begin
    X3 = randn(8, 2) # small example to see the effect
    elX = embedLags(X3, 3)
end;

