# Tutorials

Running the tutorials is the fastest way to learn how to use **Eegle** and to appreciate the way it integrates diverse packages for EEG analysis and classification.

To run tutorials, copy the code blocks therein (there is a button at the right end of each block) and paste them (e.g., CTRL+V in Windows) in the REPL or in a .jl script to be run.

Tutorials are organized by theme; start with those that most closely resemble your current research needs.

### Things to know
- We fully-qualify the name of functions (e.g., `FourierAnalysis.spectra`) or report in the text the package where they can be found. This is just to help you find the documentation of these functions if needed. In your code, you don't need to fully-qualify functions at all.
- For producing figures in these tutorials we use `Makie.jl` and some other useful packages. Install them first by executing in the REPL

```julia
]add CairoMakie, GLMakie, ColorSchemes, Colors
```

- For plotting EEG traces and topographic maps we use dedicated applications running only under Windows. The output is always given as a figure so that you can follow the tutorials also if you work with another OS.

# Themes

|Theme| Uses|
|:----|:----|
| [Spectral Analysis](@ref) | traditional spectral analysis of EEG based on FFT |
| [Machine Learning](@ref) | typically used in the field of brain-Computer interface |

### Spectral Analysis
|Tutorial  | Description|
|:----|:----|
|[Tutorial SA 1](@ref) | compute and plot power spectra on continuous EEG recording |
|[Tutorial SA 2](@ref) | compute and plot power spectra on particular EEG epochs (e.g., experimental trials) |


### Machine Learning
|Tutorial  | Description|
|:----|:----|
|[Tutorial ML 1](@ref) | run a cross-validation comparing two Riemannian classifiers |
|[Tutorial ML 2](@ref) | select [databases](@ref "database") and [sessions](@ref "session"); run a cross-validation for all of them |





