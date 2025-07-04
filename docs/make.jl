# Nota Bene: Run it while in the \docs environment

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
        Eegle.CovarianceMatrix,
        Eegle.Database

bib = CitationBibliography(
    joinpath(@__DIR__, "src", "refs.bib");
    style=:authoryear #:numeric
)

makedocs(;
   plugins=[bib],
   sitename="Eegle",
   authors="Marco Congedo, Fahim Doumi and Contributors",
   format = Documenter.HTML(),
   #format = Documenter.HTML(repolink = "...")
                            #assets = ["assets/custom.css"],   
                            #theme = "mytheme",
   #),
   modules = [Eegle, Eegle.Miscellaneous, Eegle.Processing, Eegle.FileSystem, 
               Eegle.Preprocessing, Eegle.ERPs, Eegle.InOut, 
               Eegle.CovarianceMatrix, Eegle.Database],
   # remotes = nothing, # ELIMINATE for deploying
    pages = [
        "index.md",
        "Eegle Package" => "Eegle.md",
        "Tutorials" => [
            "Overwiew" => "Tutorials.md",
            "Machine Learning" => [
                "Tutorial Machine Learning 1" => "Tutorial Machine Learning 1.md",
            ]
        ],
        "Eegle Modules" => [
            "Preprocessing" => "Preprocessing.md",
            "Processing" => "Processing.md",
            "Event-Related Potentials" => "ERPs.md",
            "Covariance Matrices" => "CovarianceMatrix.md",
            "Database" => "Database.md",
        ],
        "Utilities" => [
            "Input/Output" => "InOut.md",
            "File System" => "FileSystem.md",
            "Miscellaneous" => "Miscellaneous.md",
        ],
        "Data" => [
            "Example Data" => "documents/Example Data.md",
            "BCI DBs Documentation" => [
                "BCI DBs Overview" => "documents/BCI Databases Overview.md",
                "databases Summary MI" => "documents/Databases Summary MI.md",
                "TreatmentMI" => "documents/TreatmentMI.md",
                "databases Summary P300" => "documents/Databases Summary P300.md",
                "TreatmentP300" => "documents/TreatmentP300.md",
                "NY metadata (YAML)" => "documents/yamlstruct.md",
            ]
        ],
        "References" => "references.md"
    ]
)

deploydocs(
   # root
   # target = "build", # add this folder to .gitignore!
   repo = "github.com/Marco-Congedo/Eegle.jl.git",
   branch = "gh-pages",
   push_preview = true,
   # osname = "linux",
   # deps = Deps.pip("pygments", "mkdocs"),
   devbranch = "master",
   devurl = "dev",
   # versions = ["stable" => "v^", "v#.#", devurl => devurl],
)
