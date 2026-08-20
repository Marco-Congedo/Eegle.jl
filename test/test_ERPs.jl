println("\x1b[95m", "\nTesting module Eegle.ERPs.jl...", "\x1b[0m")


## mean
@testset "mean                           " begin
    ## Method 2

    # read the example file for the P300 BCI paradigm
    o = readNY(EXAMPLE_P300_1)

    # compute means (adaptive weights and multivariate regression)
    M = mean(o; overlapping=true, weights=:a)

    # target average ERP
    T_ERP = M[findfirst(isequal("target"), o.clabels)] 

    # nontarget average ERP
    NT_ERP = M[findfirst(isequal("nontarget"), o.clabels)]

    @test T_ERP[1, 1] ≈ 0.6818436918672789 atol=1e-9
    @test T_ERP[end, end] ≈ -0.5171464616398405 atol=1e-9

    ## Method 1
    M = mean(o.X, o.wl, o.mark; overlapping=true, weights=:a)

    # target average ERP
    T_ERP = M[findfirst(isequal("target"), o.clabels)] 

    # nontarget average ERP
    NT_ERP = M[findfirst(isequal("nontarget"), o.clabels)]

    @test T_ERP[1, 1] ≈ 0.6818436918672789 atol=1e-9
    @test T_ERP[end, end] ≈ -0.5171464616398405 atol=1e-9
end;

@testset "mean (additional)" begin
    o = readNY(EXAMPLE_P300_1)

    # arithmetic mean
    M = mean(o.X, o.wl, o.mark)

    @test length(M) == length(o.mark)
    @test size(M[1]) == (o.wl, size(o.X,2))

    # custom weights
    w = [ones(length(m)) for m in o.mark]
    Mw = mean(o.X, o.wl, o.mark; weights=w)

    @test size(Mw[1]) == size(M[1])

    # ignore empty classes
    mark = copy(o.mark)
    push!(mark, Int[])

    M2 = mean(o.X, o.wl, mark)

    @test length(M2) == length(o.mark)

    # invalid symbol
    @test_throws ArgumentError mean(o.X,o.wl,o.mark; weights=:bad)

    # wrong number of weight vectors
    @test_throws ArgumentError mean(o.X,o.wl,o.mark;
        weights=[ones(3)])

end

## stim2mark and mark2stim
@testset "stim2mark and mark2stim        " begin
    sr, wl = 128, 256 # sampling rate, window length of trials
    ns = sr*100 # number of samples of the recording
    # simulate stimulations for three classes
    stim = vcat([rand()<0.01 ? rand(1:3) : 0 for i = 1:ns-wl], zeros(Int, wl))
    mark = stim2mark(stim, wl)
    stim2 = mark2stim(mark, ns)
    @test norm(stim.-stim2) ≈ 0 atol = 0.01

    # with offset
    sr, wl = 128, 256 # sampling rate, window length of trials
    ns = sr*100 # number of samples of the recording
    # simulate stimulations for three classes
    stim = vcat([rand()<0.01 ? rand(1:3) : 0 for i = 1:ns-wl], zeros(Int, wl))
    for off = 1:32 # check for many offsets
        mark = stim2mark(stim, wl; offset = 3)
        stim2 = mark2stim(mark, ns; offset = -3)
        @test norm(stim.-stim2) ≈ 0 atol = 0.01
    end
end;

@testset "stim2mark code" begin

    stim = [0,10,0,20,10,0,20,0]

    mark = stim2mark(stim,1; code=[10,20])

    @test mark[1] == [2,5]
    @test mark[2] == [4,7]

end

@testset "stim2mark missing classes" begin
    stim = [0,1,0,3,0]

    mark = stim2mark(stim,1)

    @test length(mark)==3
    @test isempty(mark[2])
end

@testset "mark2stim code" begin

    mark = [[2,5],[4,7]]

    stim = mark2stim(mark,8; code=[10,20])

    @test stim == [0,10,0,20,10,0,20,0]

end

## merge
@testset "merge                          " begin
    mark =  [   [128, 367], 
                [245, 765, 986],
                [467, 880, 1025, 1456],
                [728, 1230, 1330, 1550, 1980],  
            ]
    merged = merge(mark, [[1, 2], [3, 4]])
    @test merged[1] == [128, 245, 367, 765, 986] && merged[2] == [467, 728, 880, 1025, 1230, 1330, 1456, 1550, 1980]
end;

@testset "merge empty" begin

    mark = [[1,4],Int[],[8]]

    m = merge(mark, [[1,2],[3]])

    @test m[1] == [1,4]
    @test m[2] == [8]

end

## trials
@testset "trials                         " begin  
    # Example P300 BCI session 
    o = readNY(EXAMPLE_P300_1)

    # Extract 1-s trials starting at samples specified in `mymark`
    mymark = [[245, 658, 987], [258, 758, 1987]]

    # since `shape=:cat` (default),
    # `𝐗` will hold the six trials concatenated 
    𝐗 = trials(o.X, mymark, o.sr)

    𝐗_ =    [o.X[245:245+o.sr-1, :], o.X[658:658+o.sr-1, :], o.X[987:987+o.sr-1, :],
            o.X[258:258+o.sr-1, :], o.X[758:758+o.sr-1, :], o.X[1987:1987+o.sr-1, :]]

    @test mean(norm(X-X_) for (X, X_) ∈ zip(𝐗, 𝐗_)) ≈ 0 

    X = trials(o.X,mymark,o.sr; shape=:byClass)

    @test length(X)==2
    @test length(X[1])==3
    @test length(X[2])==3

    X = trials(o.X,mymark,o.sr; linComb=1)

    @test X[1] isa Vector
    @test length(X[1])==o.sr   
    
    f = ones(size(o.X,2))

    X = trials(o.X,mymark,o.sr; linComb=f)

    @test X[1] isa Vector    

    weights=[ones(3),ones(3)]

    X = trials(o.X,mymark,o.sr; weights=weights)

    @test length(X)==6    

 
end;

## trialsWeights
@testset "trialsWeights                  " begin
    o = readNY(EXAMPLE_P300_1)

    weights = trialsWeights(o.X, o.mark, o.wl) 

    # weights[1] and weights[2] are the weights for class
    # "non-target" and "target", respectively.

    # The mean of weights within each class is 1
    @test mean(weights[1]) ≈ 1
    @test mean(weights[2]) ≈ 1
end;

@testset "trialsWeights supervised" begin

    o = readNY(EXAMPLE_P300_1)

    M = mean(o)

    w = trialsWeights(o.X,o.mark,o.wl; M=M)

    @test mean(w[1])≈1
    @test mean(w[2])≈1

    @test_throws ArgumentError trialsWeights(
        o.X,o.mark,o.wl;
        M=[M[1]]
    )

end

## reject
@testset "reject                         " begin
    o = readNY(EXAMPLE_P300_1)

    R = reject(o.X, o.stim, o.wl; upperLimit=1.2, returnDetails = true) # R is a tuple of 9 objects

    @test norm((R[1].+R[2]).-o.stim) ≈ 0 

    R = reject(o.X,o.stim,o.wl)

    @test length(R)==5    

    R = reject(o.X,o.stim,o.wl)

    @test length(R)==5    
end;




