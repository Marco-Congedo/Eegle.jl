|  <img src="docs/src/assets/logo.png" height="90">   | [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://Marco-Congedo.github.io/Eegle.jl/stable) | 
|:---:|:---:|

---

**Eegle** (EEG general library) is a pure-[**julia**](https://julialang.org/) package for human EEG (Electroencephalography) data analysis and classification.
It is the fundamental brick allowing the integration of several packages dedicated to human EEG.

<img src="docs/src/assets/Fig1_index.png" width="720" style="display: block; margin: auto;">

---
## Installation

Execute the following command in julia's REPL:

    ]add Eegle

---

The package is self-contained, as it re-exports several packages and all its submodules. The Eegle's sub-modules are:

| Code Unit   | Description |
|:------------|:------------|
| [CovarianceMatrix.jl](@ref) | covariance matrix estimations and Riemannian geometry encoding |
| [Database.jl](@ref) | utilities for handling databases |
| [ERPs.jl](@ref) | operations on Event-Related Potentials and BCI trials |
| [FileSystem.jl](@ref) | manipulation of files and directories |
| [InOut.jl](@ref) | reading and writing of data |
| [Miscellaneous.jl](@ref) | miscellaneous functions |
| [Preprocessing.jl](@ref) | EEG preprocessing |
| [Processing.jl](@ref) | EEG Processing |

## Quick Start

A large collection of tutorials (to come) will get you on track.

---
## About the authors

[Marco Congedo](https://sites.google.com/site/marcocongedo), corresponding author, is a Research Director of [CNRS](http://www.cnrs.fr/en) (Centre National de la Recherche Scientifique), working at [UGA](https://www.univ-grenoble-alpes.fr/english/) (University of Grenoble Alpes). **Contact**: first name dot last name at gmail dot com.

[Fahim Doumi](https://www.linkedin.com/in/fahim-doumi-4888a9251/?locale=fr_FR) at the time of writing was a research ingeneer at the Department of Enginnering of the [University federico II of Naples](https://www.unina.it/en_GB/home).

---
## Disclaimer

This version is a **pre-release** for testing purpose.

---
## Contribute

Please contact the authors if you are interested in contributing.

---
| **Documentation**  | 
|:---------------------------------------:|
| [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://Marco-Congedo.github.io/Eegle.jl/stable) |
