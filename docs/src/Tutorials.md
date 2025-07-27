# Tutorials

Running the tutorials is the fastest way to learn how to use **Eegle** and to appreciate the way it integrates diverse packages for EEG analysis and classification.

Tutorials are organized by theme; start with those that most closely resemble your current research needs.

### Things to know
- We fully-qualify the name of functions or give the fully-qualified name as a comment. This way you can easily spot the package where they can be found. In your code, you don't need to do that.
- For producing figures in these tutorials we use CairoMakie or GLMakie. Install them first by executing in the REPL

```julia
]add CairoMakie, GLMakie
```

- For plotting EEG traces and topographic maps we use dedicated applications running only under Windows. The output is always given as a figure so that you can follow the tutorials also if you work with another OS.

# Themes

|Theme| Uses|
|:---|:---|
| [Machine Learning](@ref) | typically used in the field of brain-Computer interface |


## Machine Learning
|Tutorial | Description|
|:---|:---|
|[Tutorial ML 1](@ref) | Select [databases](@ref "database") and [sessions](@ref "session");run a cross-validation for all of them |



