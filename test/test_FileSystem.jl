println("\x1b[95m", "\nTesting module Eegle.FileSystem.jl...", "\x1b[0m")

@testset "fileBase" begin
    path = "/home/user/myfile.txt"
    @test fileBase(path) == "/home/user/myfile"
    @test fileBase("noextension") == "noextension"
end

@testset "fileExt" begin
    @test fileExt("/home/user/myfile.txt") == ".txt"
    @test fileExt("archive.tar.gz") == ".gz"
end

@testset "changeFileExt" begin
    @test changeFileExt("/home/user/myfile.txt", ".csv") == "/home/user/myfile.csv"
    @test changeFileExt("/home/user/myfile", ".csv") == "/home/user/myfile.csv"
end

@testset "getFilesInDir" begin
    # Create temporary directory and files for testing
    tmpdir = mktempdir()
    touch(joinpath(tmpdir, "file1.txt"))
    touch(joinpath(tmpdir, "file2.jl"))
    
    files = getFilesInDir(tmpdir)
    @test length(files) == 2
    
    jl_files = getFilesInDir(tmpdir; ext=(".jl",))
    @test length(jl_files) == 1
    
    rm(tmpdir; recursive=true)
end




