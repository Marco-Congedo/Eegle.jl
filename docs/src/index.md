# Eegle Documentation

![Header 1](assets/header1.png)

The **EEG General Library** (Eegle) is a general-purpose package for
preprocessing and processing human Electroencephalography (EEG) data.

It promotes standardization, use of conventions and a learning approach based on simple examples and tutorials.

## 🔗 Reference

Congedo M. and Doumi F. (2026) Eegle: An open-source Julia integrative package for EEG data analysis and machine learning. Journal of Open Source Software, 11(124), 10388, doi: 10.21105/joss.10388. [pdf](https://doi.org/10.21105/joss.10388).

## 🧩 Requirements 

**Julia**: version ≥ 1.12

---

## ⚙️ Installation

Execute the following commands in Julia's REPL:

```julia
]add Eegle
```
then hit the 'back' keyboard key to exit the REPL package manager mode.

---

## —͟͟͞͞★ Quick Start
Read the [next page](@ref "Eegle") of this documentation for general informations, then work out the [tutorials](@ref "Tutorials").
When you need a function, check its documentation and the examples given therein.

---

## ✍️ About the Authors

[Marco Congedo](https://sites.google.com/site/marcocongedo), corresponding author, is a Research Director of [CNRS](http://www.cnrs.fr/en) (Centre National de la Recherche Scientifique), working at [UGA](https://www.univ-grenoble-alpes.fr/english/) (University of Grenoble Alpes). There is a non-negligible chance he has started working with EEG before you were born. **Contact**: first name dot last name at gmail dot com.

[Fahim Doumi](https://www.linkedin.com/in/fahim-doumi-4888a9251/?locale=fr_FR) is a PhD student at [University Federico II of Naples](https://www.unina.it/en_GB/home) and UGA.

---

## 🧑‍💻 Contributors

| Contributor | Contribution |
|:----------|:----------|
| [Abdeljalil Anajjar](https://github.com/AbdeljalilAnajjar) | web GUI for downloading the [FII BCI Corpus](@ref "FII BCI Corpus Overview") and Julia artifacts for data example files |
| [Alexandre Bleuzé](https://www.linkedin.com/in/alexandre-bleuz%C3%A9-069b37154/) | Toeplitz algebra for multivariate regression mean ERP estimations |

---

## 🌱 Contribute

To contribute, please check the section [How to Contribute](@ref).

---

## 🛠️ TroubleShoothing

| Problem   | Solution |
|:----------|:----------|
| No problem encountered so far | N.A.|

---

## 🧪 Package Test

```julia
using Pkg
Pkg.test("Eegle")
```

---

## ➡️ Contents

```@contents
Pages = [       "index.md",
                "Eegle.md",
                "Tutorials.md",
                "Preprocessing.md",
                "Processing.md",
                "ERPs.md",
                "BCI.md",
                "Database.md",
                "InOut.md",
                "FileSystem.md",
                "Miscellaneous.md",
				"references.md",
		]
Depth = 1
```

---

## 🧭 Index

```@index
```
