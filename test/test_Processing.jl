## filtfilt: already tested in test_Preprocessing.jl

## centeringMatrix
X = randn(32, 19)
# CAR
X_car = X * centeringMatrix(size(X, 2))
@test norm(mean(X_car; dims=2))/size(X, 1) < tol

## globalFieldPower
using Eegle
X=randn(128, 19)*ℌ(size(X, 2))
@test norm(globalFieldPower(X)-sum(X.^2; dims=2))/size(X, 1) < tol

## globalFieldRMS
using Eegle
X=randn(128, 19)*ℌ(size(X, 2))
@test norm(globalFieldRMS(X)-sqrt.(sum(X.^2; dims=2)./size(X, 2)))/size(X, 1) < tol

## epoching
using Eegle

X=randn(6144, 19)
sr = 128

# standard 1s epoching with 50% overlap
ranges = epoching(X, sr;
        wl = sr,
        slide = sr ÷ 2)
@test ranges[1:3] == [1:128, 65:192, 129:256]

ranges = epoching(X, sr;
        wl = sr * 4)
@test ranges[1:2]==[1:512, 513:1024]

# adaptive epoching of θ (4Hz-7.5Hz) oscillations (execute only)
Xθ = filtfilt(X, sr, Bandpass(4, 7.5))
ranges = epoching(Xθ, sr;
        minSize = round(Int, sr ÷ 4), # at least one θ cycle
        lowPass = 7.5)  # ignore minima due to higher frequencies