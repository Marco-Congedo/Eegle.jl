# Nota Bene: Run it while in the \docs environment (ALT+Enter)

push!(LOAD_PATH,"../src/")
push!(LOAD_PATH,"docs/src/")

using Documenter, DocumenterCitations, DocumenterInterLinks, DocumenterTools, Revise

## ADD HERE ALL MODULES!
using   Eegle, 
        Eegle.Preprocessing,
        Eegle.Processing, 
        Eegle.FileSystem, 
        Eegle.Miscellaneous, 
        Eegle.ERPs, 
        Eegle.InOut, 
        Eegle.BCI,
        Eegle.Database

bib = CitationBibliography(
    joinpath(@__DIR__, "src", "refs.bib");
    style=:authoryear #:numeric
)

makedocs(;
    plugins=[bib],
    sitename="Eegle",
    authors="Marco Congedo, Fahim Doumi and Contributors",
    format = Documenter.HTML(repolink = "...", 
                            assets = ["assets/custom.css"],   
                            #theme = "mytheme",
    ),
    modules = [Eegle, Eegle.Miscellaneous, Eegle.Processing, Eegle.FileSystem, 
               Eegle.Preprocessing, Eegle.ERPs, Eegle.InOut, 
               Eegle.BCI, Eegle.Database],
    remotes = nothing, # ELIMINATE for deploying
 pages = [
        "index.md",
        "Eegle Package" => "Eegle.md",
        "Tutorials" => "Tutorials.md", 
        "Eegle Modules" => [
            "Preprocessing" => "Preprocessing.md",
            "Processing" => "Processing.md",
            "Event-Related Potentials" => "ERPs.md",
            "Brain-Computer Interface" => "BCI.md",
            "Database" => "Database.md",
        ],
        "Utilities" => [
            "Input/Output" => "InOut.md",
            "File System" => "FileSystem.md",
            "Miscellaneous" => "Miscellaneous.md",
        ],
        "Data" => [
            "Example Data" => "documents/Example Data.md",
            "FII BCI Corpus" => [
                "FII BCI Corpus" => "documents/FII BCI Corpus Overview.md",
                "Terminology" => "documents/Terminology.md",
                "Summary of MI Databases" => "documents/Summary of MI Databases.md",
                "Treatment MI" => "documents/Treatment MI.md",
                "Summary of P300 Databases" => "documents/Summary of P300 Databases.md",
                "Treatment P300" => "documents/Treatment P300.md",
                "NY format"=> "documents/NY format.md",
                "NY metadata (YAML)" => "documents/yamlstruct.md",
                "Benchmark" => "documents/Benchmark.md",
            ]
        ],
        "References" => "references.md"
    ]
)

