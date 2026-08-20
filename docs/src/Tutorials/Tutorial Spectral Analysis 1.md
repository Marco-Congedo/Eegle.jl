# Tutorial SA 1

[💻 Full Code](@ref "Code for Tutorial SA 1")

A standard task in the analysis of continuous EEG recording is to estimate the *power spectral density*.

This tutorial uses the [`EXAMPLE_Normative_1`](@ref) example normative EEG file provided with **Eegle** and shows how to

1. read the example file (in ASCII text format) and associated file of sensor labels
2. compute the spectra with the [Welch method](https://en.wikipedia.org/wiki/Welch%27s_method)
3. plot the spectra.

!!! info
    As an example of possible options for computing spectra, it is shown how to use the [Hann](https://en.wikipedia.org/wiki/Hann_function) tapering window or the [Slepian](https://en.wikipedia.org/wiki/Slepian_function) multi-taper window. For other options see the 
    [spectra](https://marco-congedo.github.io/FourierAnalysis.jl/dev/spectra/#FourierAnalysis.spectra) function. 

![](../assets/banner_SA.png)

Tell julia the package to be used

```julia
using Eegle, GLMakie, Colors
```

Load the example file and the associated sensor labels file.

This is a 80s recording on a 20yo woman with
- *sampling rate* : 128 
- *number of electrodes*: 19
- *high-pass filter*: 1.5 Hz. 

The following functions are in **Eegle** module [InOut.jl](@ref).

```julia
X = readASCII(EXAMPLE_Normative_1)

sensors = readSensors(EXAMPLE_Normative_1_sensors)
```

Compute amplitude spectra (square root of the power spectra) using;
- the Welch method (50% overlapping sliding window, which is the default), 
- 0.5 Hz frequency resolution (`fr`)
- Hann tapering windows.

```julia
sr, fr, ne = 128, 2, length(sensors)

S = spectra(X, sr, sr*fr; 
            tapering = FourierAnalysis.hann,
            func = √) # any function can be used here
```

Select the spectra from 1.5 (`minf`) to 32 Hz (`maxf`). The function `f2b` in package **FourierAnalysis.jl** finds the bin in the spectra corresponding to `minf` and `maxf`.
The data is retrieved as the .y field of [Spectra](https://marco-congedo.github.io/FourierAnalysis.jl/dev/spectra/#Spectra) object `S`.

```julia
minf, maxf = 1.5, 32
minb = f2b(minf, sr, sr*fr)
maxb = f2b(maxf, sr, sr*fr)
S_ = S.y[minb:maxb, :]
```

Plot the spectra using **GLMakie**. 

!!! note 
    The figure will open in a new window. It is resizable and can be inspected, by zooming and panning (right mouse click). Use CTRL+click to reset the plot. Click on a legend element to toggle its visibility.

```julia
begin  
    fig=Figure(size=(700, 400))
    
    xt = collect(ceil(Int, minf):1:maxf) # x-ticks

    hiy = map(x->x+x*0.05, maximum(S_)) # max y-axis

    # Use `ne` maximally distinguishable colors.
    c = Colors.distinguishable_colors(ne, 
                    [RGB(1,1,1), RGB(0,0,0)], 
                    dropseed=true)

    # Utility to draw thicker spectra for midline electrodes 
    mylinewidth(s) = s ∈ ["FZ", "CZ", "PZ"] ? 3 : 1.6

    ax1 = Axis(fig[1, 1]; 
            title = "Amplitude Spectra", 
            limits = (nothing, (0, hiy)),
            xticks = (xt, string.(xt)),
            xlabel = L"\text{Frequency}\ (Hz)",
            ylabel = L"\text{Amplitude}\ (\mu V)")

    for i = 1:ne
        lines!(ax1, S.flabels[minb:maxb], S_[:, i]; 
                label = sensors[i], 
                joinstyle = :round,
                linecap = :round,
                alpha = 0.618034,
                linewidth = mylinewidth(sensors[i]),
                color = c[i])
    end
    axislegend(ax1; 
                labelsize = 12, 
                rowgap = 0, 
                colgap = 5,
                nbanks = 2)
    fig
end

# save the figure at 300 pixels per inch
save("spectra.png", fig; px_per_unit = 300/96)
```

![Figure 1](../assets/Fig1_Tutorial_Spectral_Analysis_1.jpg)

For using Slepian multi-tapering, you would use instead

```julia
S = spectra(X, sr, sr*fr; 
            tapering = slepians(sr, sr*fr, 1.5),
            func = √)
```

and the spectra would be

![Figure 2](../assets/Fig2_Tutorial_Spectral_Analysis_1.jpg)

Note that the spectra obtained using the Slepian windows are smoother and have larger lobes,
due to the fact that they reduce the variance of the estimator at the expenses of the main lobe 
band-width.

***
#### Code for Tutorial SA 1

```@example
using Eegle # hide
parseTutorial("Tutorial Spectral Analysis 1") # hide
```

[⬆️ Go to Top  ](@ref "Tutorial SA 1")
[🥳 More Tutorials](@ref "Tutorials")