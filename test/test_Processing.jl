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
