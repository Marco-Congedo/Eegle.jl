# Tutorial SA 2

[💻 Full Code](@ref "Code for Tutorial SA 2")

Sometimes the *power spectral density* is to be estimated on specific epochs (e.g., experimental trials).

This tutorial uses the [`EXAMPLE_MI_1`](@ref) Motor Imagery (MI) Brain-Computer Interface EEG file provided with **Eegle** and shows how to

1. read the MI example file (in [NY format](@ref))
2. compute and average the spectra across trials for all MI classes
3. plot the spectra.

!!! info
    For all options in computing spectra see the 
    [spectra](https://marco-congedo.github.io/FourierAnalysis.jl/dev/spectra/#FourierAnalysis.spectra) function. 

![](../assets/banner_SA.png)

Tell julia the package to be used

```julia
using Eegle, FourierAnalysis, CairoMakie
```

Load the example MI file by means of the `readNY` function of the **Eegle** [InOut.jl](@ref) module.

```julia
o = Eegle.readNY(EXAMPLE_MI_1)
```

Variable `o` holds an [`EEG`](@ref) structure with the data (`o.X`) and metadata, such as
- sampling rate: `o.sr`,
- trial duration: `o.wl`,
- sensor labels: `o.sensors`,
- class labels: `o.clabels`.

The file comprises trials from three classes, as it follows:

|Class Tag  | Class Label| Number of Trials |
|:----|:----|:----|
|1 | right_hand | 20|
|2 | feet | 20|
|3 | rest | 20|

Next, create an utility function to extract the EEG data of the trials for
a given `sensor`, for each class separately. For this, use the
`trials` function of the [ERPs.jl](@ref) module.

A call to the following function will therefore generate a vector of three elements, one for each class, each one holding
20 vectors, one for each trial, each one holding the trial data at the sought electrode (`e`). 

```julia
t(eeg, sensor) = trials(eeg.X, eeg.mark, eeg.wl; 
                        shape=:byClass, 
                        linComb=findfirst(==(sensor), eeg.sensors))
```

Compute power spectra for sensor "C3" and "Cz" at all trials
and classes using:
- 1 Hz frequency resolution (the window length `wl` is set equal to the sampling rate)
- the Welch method (93.75% overlapping sliding `wl`-long windows)
- the default Harris4 tapering window.

```julia
wl = o.sr
C3S = [spectra(c, o.sr, wl; slide=o.sr÷16) for c ∈ t(o, "C3")]
CzS = [spectra(c, o.sr, wl, slide=o.sr÷16) for c ∈ t(o, "Cz")]
```

Now, compute the mean power spectra across trials, separately for each class,
only from 1Hz to 36Hz. The bins in the spectra corresponding to these limits are found
with the help of function `f2b` in package **FourierAnalysis.jl**.

```julia
minb = f2b(1, o.sr, wl)
maxb = f2b(36, o.sr, wl)
C3s = [mean(𝑠.y[minb:maxb] for 𝑠 ∈ s) for s ∈ C3S] 
Czs = [mean(𝑠.y[minb:maxb] for 𝑠 ∈ s) for s ∈ CzS] 
```

Plot the average power spectra in the three class for electrode "C3" and "Cz" separately.

```julia
begin
    fig=Figure(size=(600, 600))
    
    xt = Base.OneTo(maxb)
    m = maximum
    hiy = map(x->x+x*0.05, max(m(m.(C3s)), m(m.(Czs))))

    ax1 = Axis(fig[1, 1]; 
                title = "C3", 
                limits=(nothing, (0, hiy)),
                ylabel = L"\text{Power}\ (\mu V^2)")
    for i=1:3
        lines!(ax1, xt, C3s[i], label = o.clabels[i])
    end
    axislegend(ax1)
    
    ax2 = Axis(fig[2, 1];
            title = "Cz", 
            limits=(nothing, (0, hiy)),
            xlabel = L"\text{Frequency}\ (Hz)",
            ylabel = L"\text{Power}\ (\mu V^2)")
    for i=1:3
        lines!(ax2, xt, Czs[i], label = o.clabels[i])
    end
    
    fig
end

# save the figure at 300 pixels per inch
save("spectra.png", fig, px_per_unit = 300/96)
```

![Figure 1](../assets/Fig1_Tutorial_Spectral_Analysis_2.jpg)

The expected ERD (Event-Related Desynchronization) related to right-hand movement imaging is expected to be better visible at electrode "C3", which is located near the contralateral sensorimotor cortex. The effect of the ERDs is seen as a lower power during "right hand' trials as compared to "rest" trials.

Similarly, the expected effect of the "feet" ERD is seen at midline electrode "Cz", which is the closest to the foot area of the sensorimotor cortex.

***
#### Code for Tutorial SA 2

```@example
using Eegle # hide
parseTutorial("Tutorial Spectral Analysis 2") # hide
```

[⬆️ Go to Top  ](@ref "Tutorial SA 2")
[🥳 More Tutorials](@ref "Tutorials")