# Tutorials



!!! tip
    Tutorials are organized by [themes](@ref "Themes"); start with those that most closely resemble your current research needs:
    !!! details "How to copy the code of the tutorials to the Clipboard"
        To run an entire tutorial, click on the '💻 Full Code' link placed at the top of the page of each tutorial. This will scroll up to the bottom of the page, where the block containing the full code can be copied. Once copied, paste the code (e.g., CTRL+V in Windows) in the REPL or in a .jl script to be run.

---------------------------------------------------------------------------------------------------------------

# Themes

- [Spectral Analysis](@ref)
- [Spatial Filters](@ref)
- [Machine Learning](@ref) 

---------------------------------------------------------------------------------------------------------------

### Things to know
- We fully-qualify the name of functions (e.g., `FourierAnalysis.spectra`) or report in the text the package where they can be found. This is just to help you find the documentation of these functions if needed. In your code, you don't need to fully-qualify functions at all.

- For producing figures in these tutorials we use `Makie.jl` backends and some other useful packages. Install them first by executing in the REPL:

```julia
]add CairoMakie, GLMakie, ColorSchemes, Colors, EEGPlot
```

---------------------------------------------------------------------------------------------------------------

### Spectral Analysis

![](assets/banner_SA.png)

|Tutorial  | Description|
|:----|:----|
|[Tutorial SA 1](@ref) | compute and plot power spectra on continuous EEG recording |
|[Tutorial SA 2](@ref) | compute and plot power spectra on particular EEG epochs (e.g., experimental trials) |

### Spatial Filters

![](assets/banner_SF.png)

|Tutorial  | Description|
|:----|:----|
|[Tutorial SF 1](@ref) | construct new filters based on joint diagonalization (GEVD) |

### Machine Learning

![](assets/banner_ML.png)

|Tutorial  | Description|
|:----|:----|
|[Tutorial ML 1](@ref) | run a cross-validation comparing two Riemannian classifiers |
|[Tutorial ML 2](@ref) | select [databases](@ref "database") and [sessions](@ref "session"); run a cross-validation for all of them |

[Themes](@ref)



