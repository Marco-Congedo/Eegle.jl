println("\x1b[95m", "\nTesting module Eegle.BCI.jl...", "\x1b[0m")

# covmat
@testset "covmat                         " begin
    t, ne = 128, 19 
    X = randn(t, ne)
    C_ = covmat(X; covtype=SCM)
    C = (1/t) * X'*X
    @test isapprox(norm(C_ - C), 0; atol=1e-12)
end;

# encode: just executed
@testset "encode                         " begin
    o = readNY(EXAMPLE_P300_1; bandPass=(1, 24), upperLimit=1.2)
    C = encode(o)
end;

# crval: test the MDM algorithm with Eegle's example MI and P300 data
@testset "crval                          " begin
    args = (bandPass = (8, 32), upperLimit = 1, classes=["feet", "right_hand"])
    @test (crval(EXAMPLE_MI_1; args...).avgAcc  - 0.7395833333333333) ≈ 0

    args = (bandPass = (8, 32), upperLimit = 1, classes=["feet", "right_hand"])
    @test (crval(EXAMPLE_P300_1; bandPass = (1, 24)).avgAcc - 0.7195312500000001) ≈ 0
end;


