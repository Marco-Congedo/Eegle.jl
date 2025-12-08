# BCI FII Corpus Benchmark

This document reports the results of a benchmark run on the [FII BCI Corpus](@ref "FII BCI Corpus Overview") using **Eegle**.

Only subjects/sessions that passed *all exclusion criteria* described in the *@discarded.md* file (see it for [MI](https://zenodo.org/records/17801878/files/@discarded.md?download=1) and [P300](https://zenodo.org/records/17793672/files/@discarded.md?download=1)) were included in this benchmark.

Individual subject/session accuracies are included in the `.yml` [metadata files](@ref "NY Metadata (YAML)") and are also available in CSV format in this [GitHub repository](https://github.com/FhmDmi/Eegle-Tools/tree/master/Within-Session-Evaluation/results). The repository also hosts the scripts used to make this benchmark and more information. 

This document reports the mean(±sd) balanced accuracies for each database according to the analyzed tasks:
    - MI: "right_hand" vs. "feet" and "left_hand" vs. "right_hand" 
    - P300: target vs nontarget.

## Available Classifiers

The benchmark has employed three Riemannian classifiers, all adopting the affine-invariant (Fisher-Rao) [metric](https://marco-congedo.github.io/PosDefManifold.jl/stable/introToRiemannianGeometry/):

**Native classifiers** (acting on the manifold); the metric is used for computing distances and barycenters:

- **MDM** (Minimum Distance to Mean).

**Tangent space classifiers**; the metric is used to compute a barycenter for projecting the data onto the tangent space:

- **ENLR** (Elastic Net Logistic Regression) 
- **Linear SVM** (Linear Support Vector Machine).

---

## Processing Pipelines

For both MI and P300 the default pipeline implementd by the [`crval`](@ref) function has bene used with the following two customizations:

- Stratified K-Fold (K=10) instead of the default 8-fold
- Seed set to 109 (instead of default 1234).

---

## Motor Imagery (MI) Benchmark Results

### Task: right_hand vs. feet

| Database | MDM (%) | ENLR (%) | SVM (%) |
|----------|---------|----------|----------|
| AlexMI-None | 73.75 ± 18.03 | 80.62 ± 14.0 | 75.31 ± 13.39 |
| BNCI2014001-None | 85.13 ± 12.2 | 87.7 ± 9.65 | 86.33 ± 11.05 |
| BNCI2014002-Test | 80.77 ± 15.81 | 81.54 ± 16.88 | 81.92 ± 14.58 |
| BNCI2014002-Train | 77.07 ± 11.4 | 77.54 ± 11.38 | 74.07 ± 13.87 |
| BNCI2015001-None | 81.62 ± 13.08 | 84.53 ± 10.23 | 78.94 ± 12.42 |
| Schirrmeister2017-None | 86.13 ± 12.67 | 96.48 ± 4.52 | 97.07 ± 3.62 |
| Weibo2014-None | 61.94 ± 9.56 | 86.5 ± 8.9 | 81.72 ± 8.32 |
| Zhou2016-None | 87.33 ± 6.76 | 92.89 ± 3.66 | 87.45 ± 8.41 |

### Task: left_hand vs. right_hand

| Database | MDM (%) | ENLR (%) | SVM (%) |
|----------|---------|----------|----------|
| BNCI2014001-None | 77.75 ± 13.99 | 78.26 ± 15.33 | 78.85 ± 14.27 |
| BNCI2014004-Test | 78.9 ± 12.41 | 80.95 ± 11.53 | 78.59 ± 12.58 |
| BNCI2014004-Train | 66.15 ± 9.95 | 68.73 ± 9.74 | 66.92 ± 9.63 |
| Cho2017-None | 64.96 ± 9.42 | 73.7 ± 10.26 | 69.54 ± 10.07 |
| GrosseWentrup2009-None | 60.12 ± 8.38 | 86.21 ± 10.73 | 82.23 ± 10.81 |
| Lee2019_MI-Train | 66.22 ± 13.23 | 79.74 ± 11.64 | 75.35 ± 13.21 |
| PhysionetMI-Task 2 | 55.1 ± 16.48 | 76.77 ± 11.58 | 62.99 ± 12.83 |
| SPSM2025-None | 62.49 ± 7.5 | 66.67 ± 7.91 | 60.08 ± 9.14 |
| Schirrmeister2017-None | 65.26 ± 16.51 | 83.11 ± 11.92 | 82.08 ± 12.21 |
| Shin2017A-None | 61.67 ± 18.58 | 79.74 ± 15.77 | 73.08 ± 17.46 |
| Weibo2014-None | 55.14 ± 11.93 | 82.0 ± 10.36 | 74.52 ± 16.58 |
| Zhou2016-None | 84.52 ± 7.76 | 86.92 ± 8.18 | 82.46 ± 9.31 |

---

## P300 Benchmark Results

| Database | MDM (%) | ENLR (%) |
|----------|---------|----------|
| BNCI2014009-None | 80.11 ± 7.67 | 82.87 ± 6.22 |
| BNCI2015003-Test | 77.18 ± 9.18 | 72.89 ± 6.89 |
| BNCI2015003-Train | 77.76 ± 6.23 | 72.65 ± 6.29 |
| Cattan2019-Personal Computer (PC) | 81.93 ± 7.76 | 82.1 ± 8.36 |
| Cattan2019-Virtual Reality (VR) | 79.07 ± 6.8 | 81.07 ± 6.38 |
| EPFLP300-Run 1 - Television | 68.51 ± 10.75 | 68.75 ± 7.65 |
| EPFLP300-Run 2 - Telephone | 68.25 ± 10.75 | 71.49 ± 8.58 |
| EPFLP300-Run 3 - Lamp | 68.51 ± 13.74 | 71.84 ± 11.07 |
| EPFLP300-Run 4 - Door | 68.06 ± 9.49 | 66.25 ± 7.17 |
| EPFLP300-Run 5 - Window | 69.8 ± 9.17 | 76.18 ± 8.25 |
| EPFLP300-Run 6 - Radio | 67.92 ± 9.77 | 70.4 ± 11.08 |
| bi2012-Online | 77.66 ± 5.15 | 82.9 ± 7.69 |
| bi2012-Training | 73.52 ± 3.28 | 80.55 ± 5.38 |
| bi2013a-Adaptative - Online | 86.95 ± 4.71 | 83.65 ± 6.23 |
| bi2013a-Adaptative - Training | 84.74 ± 5.49 | 84.47 ± 5.51 |
| bi2013a-Non Adaptative - Online | 86.64 ± 6.34 | 83.09 ± 6.27 |
| bi2013a-Non Adaptative - Training | 84.58 ± 5.08 | 84.37 ± 5.28 |
| bi2014a-None | 74.49 ± 7.33 | 77.58 ± 6.66 |
| bi2014b-Solo | 72.76 ± 13.67 | 73.78 ± 12.67 |
| bi2015a-Flash Duration 110ms | 80.01 ± 6.33 | 81.84 ± 6.5 |
| bi2015a-Flash Duration 50ms | 79.96 ± 6.85 | 81.46 ± 6.85 |
| bi2015a-Flash Duration 80ms | 79.38 ± 6.07 | 81.53 ± 6.59 |
