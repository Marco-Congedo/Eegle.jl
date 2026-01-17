---
title: 'Eegle: An open-source Julia integrative package for EEG data analysis and machine learning'
tags:
  - Julia
  - EEG
  - Electroencephalography
  - Data Science
  - Machine Learning
authors:
  - name: Marco Congedo
    orcid: 0000-0003-2196-0409
    equal-contrib: true
    corresponding: true # (This is how to denote the corresponding author)
    affiliation: 1 
  - name: Fahim Doumi
    equal-contrib: true # (This is how you can denote equal contributions between multiple authors)
    affiliation: "1, 2" # (Multiple affiliations must be quoted)
affiliations:
 - name: University Grenoble Alpes, CNRS, Grenoble-INP, Grenoble, France
   index: 1
 - name: University Federico II, Naples, Italy. 
   index: 2
date: 18 January 2026
bibliography: paper.bib

---

# Summary

Existing since the 1920's, Electroencephalography (EEG) is the first non-invasive neuroimaging modality developed by the mankind. Despite many more sophisticated others have been developed since, to date EEG is still by far the most widely used. This is due to a number of distinct advantages over other modalities, such as the low price and encombrement of equipment, its silent operation, which is possible virtually everywhere, and its truly non-invasive operation that has no medical counter-indications.
The recent explosion of the research on EEG-based Brain-Computer Interfaces (BCIs) has fostered the need of efficient tools for EEG analysis and machine learning. While such tools exists for older languages such as Python and Matlab, they are not available for the more recent Julia language, which has been specifically created with these needs in mind. *Eegle.jl* leverages the rich scientific Julia eco-system and integrate it to offer a simple and unified framework for both EEG data analysis and machine learning. We also release *pyLittleEegle* a Python version of the BCI-related capabilities of Eegle.jl. Both packages work seamlessly with the *FII BCI Corpus*, the first large curated and annotated databases for the motor imagery and P300 BCI modalities.

# Statement of need

In 1893, Hans Berger fell off his horse during his training with the German military and was nearly trampled. 
On that same day, his sister had a bad feeling about Hans and wrote him a telegram asking if everything was all right.
To the 19y.o. Hans Berger, the coincidence appeared stunning. He thoughts that he had somehow transmitted his feelings to the sister with some form of 'telepathy' [@Bouszaki:2006]. He then decided to become a psychiatrist and to study the phenomenon seriously. Based upon previous research of Richard Caton on the electrical activity of the exposed cortex of monkeys [@Caton:1875], he obtained the first human electroencephalographic recording in the middle of the 1920's [@Berger:1929].

Berger would have never imagined that a century later his creature would be the cornerstone of a modern form of 'telepathy': Brain-Computer Interface (BCIs). By means of an EEG-based BCI, a human can send a command to a machine relying entirely on the EEG readings. That is, without using at all the muscles or the peripheral nerves (which, for instance, controls the movements of the eyes) [@WolpawWolpaw:2012]. The EEG has been instrumental to the flourishing research on EEG in the past 20 years, thanks to its unique characteristics:
- High temporal resolution (~1ms)
- Instantaneous measure of brain electrical potentials (no delay in the measure)
- High consistency (e.g., same EEG power spectra on the same individuals in two successive days at the same hour)
- Sensitiveness (for example, it is very useful for the detection of epilepsy and minimal consciousness states)
- Solid research tradition (one century-long)
- Total silentness and truly non-invasiveness (e.g., allowing daily use on anybody, including new-born children and patients with any condition)
- Need of small, light and inexpensive equipment (the size of EEG electronics can be reduced to the size of a common chip)
- Use of wireless recording in natural (out-of-the-Lab) environments.

While BCI research is relatively new, EEG has a long-standing tradition in the clinical and cognitive brain research. All-in-all, a search on PubMed for the terms ("EEG" or "electroencephalography") yielded 217075 results on Jan 17 2026, with a positive trend starting at the dawn of the third millennium,
a phenomenon that we name the 're-birth of EEG'.

Older languages such as Python and Matlab have their eco-system for EEG data analysis and machine learning. Here below are the most frequently adopted software:

## Python
| Package   | Description |
|:------------|:------------|
| MNE[@mne:2013] | Open-source Python package for exploring, visualizing, and analyzing human neurophysiological data: MEG, EEG, sEEG, ECoG, NIRS, and more |
| scikit-learn[@scikit-learn:2011] | Machine learning in Python (generic, not specific to EEG)|
| Braindecode[@braindecode:2025] | Braindecode: toolbox for decoding raw electrophysiological brain data with deep learning models |

## Matlab
| Package   | Description |
|:------------|:------------|
| EEGLAB[@eeglab:2004] | 1n interactive Matlab toolbox for processing continuous and event-related EEG, MEG |
| FieldTrip[@fieldtrip:2011] | Open source software for advanced analysis of MEG, EEG, and invasive electrophysiological data |
| Brainstorm[@brainstorm2011] | A user-friendly application for MEG/EEG analysis |

In the julia language, instead, the ecosystem for EEG data is poor and scattered. However, the use of Julia may greatly benefit the field.
Julia is a young open-source and cross-platform language specifically conceived for scientific computing, which is rapidly gaining momentum in the
data science community thanks to its efficiency and compatibility with the best available computing protocols [@julia2017].
It is an high-level language, like Python and Matlab, however it is (just-in-time) compiled, thus it can be very efficient.
Typically, Julia code runs at a speed within a factor of two relative to fully optimized C code, thus in can be an order
of magnitude faster as compared to Python or R and about 4 times faster as compared to Matlab.

# Software design

In this context, we have created the EEG General Library (**Eegle**) for the julia language. `Eegle.jl` is a general-purpose package for EEG data analysis and machine learning. It is the foundational building block that enables the integration of diverse state-of-the-art packages specifically conceived for EEG data, and leveraging the powerful Julia scientific eco-system.

![Julia package eco-system integrated by **Eegle**.](figure1.png){ width=60% }

`Eegle.jl` is organized as a collection of independent modules. They are all re-exported, along with fundamental external packages.

### Internal modules

| Code Unit   | Description |
|:------------|:------------|
| [BCI.jl](@ref) | Brain-Computer Interface machine learning based on Riemannian geometry |
| [Database.jl](@ref) | utilities for handling databases and the [FII BCI Corpus](@ref "FII BCI Corpus Overview")|
| [ERPs.jl](@ref) | operations on Event-Related Potentials and BCI trials |
| [FileSystem.jl](@ref) | manipulation of files and directories |
| [InOut.jl](@ref) | reading and writing of data |
| [Miscellaneous.jl](@ref) | miscellaneous functions |
| [Preprocessing.jl](@ref) | EEG preprocessing |
| [Processing.jl](@ref) | EEG processing |

### Re-exported external packages

| Package | Scope |
|:-----------------------|:-----------------------|
| [CovarianceEstimation](https://github.com/mateuszbaran/CovarianceEstimation.jl) | covariance matrix estimations |
| [Diagonalizations](https://github.com/Marco-Congedo/Diagonalizations.jl) | spatial filters, (approximate joint) diagonalization algorithms |
| [Distributions](https://github.com/JuliaStats/Distributions.jl) | Julia standard package for statistical distributions |
| [DSP](https://github.com/JuliaDSP/DSP.jl) | Julia standard package for digital signal processing |
| [FourierAnalysis](https://github.com/Marco-Congedo/FourierAnalysis.jl) | FFT-based frequency domain and time-frequency domain analysis |
| [LinearAlgebra](https://bit.ly/2W5Wq8W) | Julia standard package for matrix types and linear algebra (BLAS, LAPACK) |
| [NPZ](https://github.com/fhs/NPZ.jl) | support for the *NPZ* (NumPy) binary data format |
| [PermutationTests](https://github.com/Marco-Congedo/PermutationTests.jl) | low-level statistics, very fast (multiple comparison) permutation tests |
| [PosDefManifold](https://github.com/Marco-Congedo/PosDefManifold.jl) | more linear algebra, operations on the manifold of positive-definite matrices |
| [PosDefManifoldML](https://github.com/Marco-Congedo/PosDefManifoldML.jl) | machine learning on the manifold of positive-definite matrices |
| [StatsBase](https://github.com/JuliaStats/StatsBase.jl) | Julia standard package for basic statistics |
| [Statistics](https://bit.ly/2Oem3li) | Julia standard package for statistics |

This organization follows the spirit of Julia: it allows to centralize all the above resources under a single package, yet, it allows each package to be fully independent (including the documentation) so as to allow the independent development and maintenance of each package.
As a consequence of this organization, `Eegle.jl` is a relatively small and agile package.

# FII BCI Corpus

`Eegle.jl` features a GUI for downloading the **FII BCI Corpus**[@FIIBCICorpusMI:2025; @FIIBCICorpusP300:2025]. The corpus comprise a selection of BCI databases annotated and curated for both the motor imagery and P300 BCI paradigm. Along with EEG data and class labels, the corpus provides comprehensive metadata that allow to select the data for the study at hand and extract relevant information. This makes it particularly easy and principled to carry out machine learning research on BCI data — see for example the [Tutorial ML 2](https://marco-congedo.github.io/Eegle.jl/stable/Tutorials/Tutorial%20Machine%20Learning%202/#Tutorial-ML-2) of `Eegle.jl`.

# pyLittleEegle

The capabilities of `Eegle.jl` related to database selection using the  **FII BCI Corpus**, as well as all its the machine learning capabilities, have been cloned and translated in the Python language, yielding the **pyLittleEegle** package [@pyLittleEegle:2025]. This package is fully compatible with scikit-learn[@scikit-learn:2011], thus it makes the corpus easily accessible in Python as well. 

# License

`Eegle.jl` is released under the MIT license.

# AI usage disclosure

Generative AI tools were used in the development of this software only for hastening the writing of non-computing routines, 
such as the the download GUI and some routines for the automatic generation of code blocks in the tutorials.
For writing the manuscript, generative AI tools have been used only for spelling and grammar error checking.

# Acknowledgements

We acknowledge the contributions to `Eegle.jl` of Dr. Alexandre Bleuzé and of Abdeljalil Anajjar.

# References