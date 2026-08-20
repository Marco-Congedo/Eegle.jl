println("\x1b[95m", "\nTesting module Eegle.Miscellaneous.jl...", "\x1b[0m")

@testset "minima" begin
    x = [2, 1, 2, 1, 2]
    idx, val = minima(x)
    @test idx == [2, 4]
    @test val == [1.0, 1.0]

    # no minima
    idx, val = minima([1, 2, 3, 4])
    @test isempty(idx)
    @test isempty(val)

    # single minimum
    idx, val = minima([3, 1, 3])
    @test idx == [2]
    @test val == [1.0]

    # too short
    idx, val = minima([1])
    @test isempty(idx)
    @test isempty(val)

    idx, val = minima([2, 1])
    @test isempty(idx)
    @test isempty(val)

    # Float input
    idx, val = minima([2.0, 1.5, 2.0])
    @test idx == [2]
    @test val == [1.5]
end


@testset "maxima" begin
    x = [1, 2, 1, 2, 1]
    idx, val = maxima(x)
    @test idx == [2, 4]
    @test val == [2.0, 2.0]

    # no maxima
    idx, val = maxima([4, 3, 2, 1])
    @test isempty(idx)
    @test isempty(val)

    # single maximum
    idx, val = maxima([1, 3, 1])
    @test idx == [2]
    @test val == [3.0]

    # too short
    idx, val = maxima([1])
    @test isempty(idx)
    @test isempty(val)

    idx, val = maxima([1, 2])
    @test isempty(idx)
    @test isempty(val)

    # Float input
    idx, val = maxima([1.0, 3.5, 1.0])
    @test idx == [2]
    @test val == [3.5]
end


@testset "waste" begin
    A = randn(20, 20)
    b = randn(100)

    # one object
    @test waste(A) === nothing

    # several objects
    @test waste(A, b, 3, "hello", nothing) === nothing
end


@testset "parseTutorial" begin

    #
    # Test the error path (easy and stable)
    #
    @test_throws ArgumentError parseTutorial("__this_file_does_not_exist__")

    #
    # Test successful parsing if documentation exists
    #
    docsdir = joinpath(dirname(dirname(@__DIR__)), "docs", "src", "Tutorials")

    if isdir(docsdir)
        mdfiles = filter(f -> endswith(f, ".md"), readdir(docsdir))

        if !isempty(mdfiles)
            tutorial = first(mdfiles)

            io = IOBuffer()

            redirect_stdout(io) do
                @test parseTutorial(fileBase(tutorial)) === nothing
            end

            output = String(take!(io))

            # The function should have printed something.
            @test !isempty(output)
        end
    end
end