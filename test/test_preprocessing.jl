using Eegle, Statistics, Test

# standardize
@testset "standardize" begin
        X = randn(128, 19)
        stX = standardize(X)
        @test (m = mean(stX)) < tol
        @test (v = var(stX; mean=m)) - 1 < tol
end;
stX = standardize(X; robust=true, prop=0.1) # execute only

## resample (execute only)
sr = 128
X = randn(sr*10, 19)
Y=resample(X, sr, 1//4) # downsample by a factor 4
Y=resample(X, sr, 2) # upsample by a factor 2, i.e., double the sampling rate
Y=resample(X, sr, 100/sr) # downsample to 100 samples per second
