# Nota Bene: Run it while in the \docs environment

using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(path=joinpath(@__DIR__, ".."))  # local Eegle
Pkg.instantiate() 

using Documenter, DocumenterCitations, DocumenterInterLinks, DocumenterTools
## ADD HERE ALL MODULES!
using   Eegle, 
        Eegle.Preprocessing,
        Eegle.Processing, 
        Eegle.FileSystem, 
        Eegle.Miscellaneous, 
        Eegle.ERPs, 
        Eegle.InOut, 
        Eegle.BCI

CI = get(ENV, "CI", "false") == "true"        

bib = CitationBibliography(
    joinpath(@__DIR__, "src", "refs.bib");
    style=:authoryear #:numeric
)

makedocs(;
   plugins=[bib],
   sitename="Eegle",
   authors="Marco Congedo, Fahim Doumi and Contributors",
   format = Documenter.HTML(; prettyurls = CI,),
   #format = Documenter.HTML(repolink = "...")
                            #assets = ["assets/custom.css"],   
                            #theme = "mytheme",
   #),
   modules = [Eegle, Eegle.Miscellaneous, Eegle.Processing, Eegle.FileSystem, 
               Eegle.Preprocessing, Eegle.ERPs, Eegle.InOut, 
               Eegle.BCI],
   # remotes = nothing, # ELIMINATE for deploying
 pages = [
        "index.md",
        "🦅 Eegle Package" => "Eegle.md",
        "💡 Tutorials" => "Tutorials.md", 
        "🧠 Eegle Modules" => [
            "Preprocessing" => "Preprocessing.md",
            "Processing" => "Processing.md",
            "Event-Related Potentials" => "ERPs.md",
            "Brain-Computer Interface" => "BCI.md",
        ],
        "🔧 Utilities" => [
            "Input/Output" => "InOut.md",
            "File System" => "FileSystem.md",
            "Miscellaneous" => "Miscellaneous.md",
        ],
        "🗄️ Data" => [
            "Example Data" => "documents/Example Data.md",
        ],
        "🎓 References" => "references.md"
    ]
)

if CI
    deploydocs(
    # root
    # target = "build", # add this folder to .gitignore!
    repo = "github.com/Marco-Congedo/Eegle.jl.git",
    branch = "gh-pages",
    push_preview = false,
    # osname = "linux",
    # deps = Deps.pip("pygments", "mkdocs"),
    # devbranch = "master", # RESTORE
    # devurl = "dev", # RESTORE
    # versions = ["stable" => "v^", "v#.#", devurl => devurl],
    )
else
    include("local_run.jl")  # optional local run
end
