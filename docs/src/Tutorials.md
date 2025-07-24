# Tutorials

Running the tutorials is the fastest way to learn how to use **Eegle** and to appreciate the way it integrates diverse packages for EEG analysis and classification.

Tutorials are organized by themes; start with those more closely ressambling to your research needs at hand.

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
|[Tutorial ML 1](@ref) | Select databases and run a cross-validation for all [sessions](@ref "session") in all selected [databases](@ref "database") |



