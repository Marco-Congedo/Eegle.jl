println("\x1b[95m", "\nTesting module Eegle.FileSystem.jl...", "\x1b[0m")

@testset "fileBase" begin
    @test fileBase("/home/user/myfile.txt") == "/home/user/myfile"
    @test fileBase("noextension") == "noextension"

    # multiple extensions
    @test fileBase("archive.tar.gz") == "archive.tar"

    # hidden file
    @test fileBase(".gitignore") == ""

    # directory containing dots
    @test fileBase("/tmp.v1/file.txt") == "/tmp.v1/file"
end


@testset "fileExt" begin
    @test fileExt("/home/user/myfile.txt") == ".txt"
    @test fileExt("archive.tar.gz") == ".gz"
    @test fileExt(".gitignore") == ".gitignore"
end


@testset "changeFileExt" begin
    @test changeFileExt("/home/user/myfile.txt", ".csv") ==
          "/home/user/myfile.csv"

    @test changeFileExt("/home/user/myfile", ".csv") ==
          "/home/user/myfile.csv"

    @test changeFileExt("archive.tar.gz", ".zip") ==
          "archive.tar.zip"
end


@testset "getFilesInDir" begin
    tmpdir = mktempdir()

    touch(joinpath(tmpdir, "file1.txt"))
    touch(joinpath(tmpdir, "file2.jl"))
    touch(joinpath(tmpdir, "Analysis.txt"))

    mkdir(joinpath(tmpdir, "subdir"))
    touch(joinpath(tmpdir, "subdir", "nested.txt"))

    files = getFilesInDir(tmpdir)
    @test length(files) == 3          # nested file ignored

    @test all(isfile, files)

    jl_files = getFilesInDir(tmpdir; ext=(".jl",))
    @test length(jl_files) == 1
    @test endswith(jl_files[1], "file2.jl")

    txt_files = getFilesInDir(tmpdir; ext=(".txt",))
    @test length(txt_files) == 2

    analysis = getFilesInDir(tmpdir; isin="Analysis")
    @test length(analysis) == 1
    @test occursin("Analysis", basename(analysis[1]))

    filtered = getFilesInDir(tmpdir; ext=(".txt",), isin="Analysis")
    @test length(filtered) == 1

    rm(tmpdir; recursive=true)
end


@testset "getFilesInDir with multiple directories" begin
    dir1 = mktempdir()
    dir2 = mktempdir()

    touch(joinpath(dir1, "a.txt"))
    touch(joinpath(dir2, "b.txt"))
    touch(joinpath(dir2, "c.jl"))

    files = getFilesInDir([dir1, dir2])

    @test length(files) == 3

    txt = getFilesInDir([dir1, dir2]; ext=(".txt",))
    @test length(txt) == 2

    rm(dir1; recursive=true)
    rm(dir2; recursive=true)
end


@testset "getFilesInDir warnings/errors" begin
    emptydir = mktempdir()

    @test_logs (:warn,) begin
        files = getFilesInDir(emptydir)
        @test isempty(files)
    end

    rm(emptydir; recursive=true)

    @test_logs (:error,) begin
        getFilesInDir("this_directory_does_not_exist")
    end
end


@testset "getFoldersInDir" begin
    tmpdir = mktempdir()

    mkdir(joinpath(tmpdir, "FolderA"))
    mkdir(joinpath(tmpdir, "FolderB"))
    mkdir(joinpath(tmpdir, "AnalysisFolder"))

    folders = getFoldersInDir(tmpdir)

    @test length(folders) == 3
    @test all(isdir, folders)

    analysis = getFoldersInDir(tmpdir; isin="Analysis")

    @test length(analysis) == 1
    @test occursin("Analysis", basename(analysis[1]))

    rm(tmpdir; recursive=true)
end


@testset "getFoldersInDir warnings/errors" begin
    emptydir = mktempdir()

    @test_logs (:warn,) begin
        folders = getFoldersInDir(emptydir)
        @test isempty(folders)
    end

    rm(emptydir; recursive=true)

    @test_logs (:error,) begin
        getFoldersInDir("this_directory_does_not_exist")
    end
end