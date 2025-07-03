println("\x1b[95m", "Testing module Eegle.ERPs.jl...")

## mean: just executed
@testset "mean" begin
    sr, wl, ne = 128, 128, 19 
    ns = sr*20
    X = randn(ns, ne)
    stim = zeros(Int, ns)
    # simulate stimulations for three classes
    for i = 1:20
        stim[rand(1:ns-wl)] = rand(1:3)
    end
    mark = stim2mark(stim, wl)

    M = mean(X, wl, mark; overlapping=true, weights=:a)
    M = mean(X, wl, mark; overlapping=false)
end;

## stim2mark and mark2stim
@testset "stim2mark and mark2stim" begin
    sr, wl = 128, 256 # sampling rate, window length of trials
    ns = sr*100 # number of samples of the recording
    # simulate stimulations for three classes
    stim = vcat([rand()<0.01 ? rand(1:3) : 0 for i = 1:ns-wl], zeros(Int, wl))
    mark = stim2mark(stim, wl)
    stim2 = mark2stim(mark, ns)
    @test norm(stim-stim2) ≈ 0

    # with offset
    offset = 32
    mark = stim2mark(stim, wl; offset)
    stim2 = mark2stim(mark, ns; offset = -offset)
    @test norm(stim-stim2) ≈ 0
end;


@testset "stim2mark and mark2stim" begin
    sr, wl = 128, 256 # sampling rate, window length of trials
    ns = sr*100 # number of samples of the recording
    # simulate stimulations for three classes
    stim = vcat([rand()<0.01 ? rand(1:3) : 0 for i = 1:ns-wl], zeros(Int, wl))
    mark = stim2mark(stim, wl)
    stim2 = vcat([rand()<0.01 ? rand(4:6) : 0 for i = 1:ns-wl], zeros(Int, wl))
    mark2 = stim2mark(stim2, wl)
    mergedmark = merge(mar, mark2)

    stim2 = mark2stim(mark, ns)
    @test norm(stim-stim2) ≈ 0

    # with offset
    offset = 32
    mark = stim2mark(stim, wl; offset)
    stim2 = mark2stim(mark, ns; offset = -offset)
    @test norm(stim-stim2) ≈ 0
end;

@testset "merge" begin
    mark =  [   [128, 367], 
                [245, 765, 986],
                [467, 880, 1025, 1456],
                [728, 1230, 1330, 1550, 1980],  
            ]
    merged = merge(mark, [[1, 2], [3, 4]])
    @test merged[1] == [128, 245, 367, 765, 986] && merged[2] == [467, 728, 880, 1025, 1230, 1330, 1456, 1550, 1980]
end;

# xxx add trials
# xxx add trialsWeights
# xxx add reject



