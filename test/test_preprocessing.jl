## standardize
@testset "standardize" begin
        X = randn(128, 19)
        stX = standardize(X)
        @test (m = mean(stX)) < tol
        @test (v = var(stX; mean=m)) - 1 < tol
end;
stX = standardize(X; robust=true, prop=0.1) # execute only

## resample (Downsampling tested and the other resampling cases executed only)
sr = 128
X = filtfilt(randn(sr*10, 19), sr, Bandpass(1, sr ÷ (3*4)); designMethod = Butterworth(8))
Y = resample(X, sr, 1//4) # downsample by a factor 4
Z = resample(Y, sr ÷ 4, 4//1) # upsample by a factor of 4

Xs =spectra(X, sr, sr).y
Zs = spectra(Z, sr, sr).y
@test norm(Xs-Zs)/norm(Xs) < 0.001

Y=resample(X, sr, 2) # upsample by a factor 2, i.e., double the sampling rate
Y=resample(X, sr, 100/sr) # downsample to 100 samples per second

## removeChannels (one case is tested and the others are executed only)
X = randn(128, 7)
sensors=["F7", "F8", "C3", "Cz", "C4", "P7", "P8"]

@testset "removeChannels" begin
        # remove second channel
        X_, sensors_, ne = removeChannels(X, 2, sensors)
        @test sensors_ == ["F7", "C3", "Cz", "C4", "P7", "P8"]
        @test norm(X_ - hcat(X[:, 1], X[:, 3:end])) ≈ 0
end;

# remove the first five channels
X_, sensors_, ne = removeChannels(X, collect(1:5), sensors)

# remove the channel labeled as "Cz" in `sensors`
X_, sensors_, ne = removeChannels(X, findfirst(x->x=="Cz", sensors), sensors)

# remove the channels labeled as "C3", "Cz", and "C4" in `sensors`
X_, sensors_, ne = removeChannels(X, findall(x->x∈("Cz", "C3", "C4"), sensors), sensors)

# keep only channels labeled as "C3", "Cz", and "C4" in `sensors`
X_, sensors_, ne = removeChannels(X, findall(x->x∉("Cz", "C3", "C4"), sensors), sensors)

## emdedLags (executed only, check visually the example)
using Eegle # or using Eegle.Preprocessing

X = randn(8, 2) # small example to see the effect

elX = emdedLags(X, 3)

