# FII BCI Corpus Overview

This document outlines the rationale and content of the **FII BCI Corpus** Zenodo repositories for [Motor Imagery (MI)](https://doi.org/10.5281/zenodo.17801878) and [P300](https://doi.org/10.5281/zenodo.17250465) BCI paradigm. Those are selections of BCI databases, annotated and curated for research purposes in a collaborative project carried out at *University Federico II of Naples* and *University Grenoble Alpes of Grenoble*.

The corpus can be easily installed using **Eegle**'s download GUI — see [`Eegle.Database.downloadDB`](@ref).

Along with EEG data and class labels, the corpus provides comprehensive metadata that allow to select the data for the study at hand and extract relevant information. This makes it particularly easy to carry out machine learning research on BCI data — see for example [Tutorial ML 2](@ref). For comparing results, a [benchmark](@ref "BCI FII Corpus Benchmark") is provided.

The data curation included:
- discarding EEG recordings 
    - flagged by the database authors as problematic
    - holding corrupted data (e.g., NaN values during the trials)
    - yielding numerical problems with standard data manipulations procedures
    - offering close-to-chance performance in standard 2-class prediction tasks,
- conversion of data into *µ*V with Float32 precision,
- class re-labeling using a standardized scheme,
- downsampling (if applicable) to ≤ 256 samples per second preventing aliasing,
- removal of non-EEG channels, such as EOG, EMG, reference, or ground electrodes,
- concatenation of runs from the same session with identical experimental condition,
- cleaning of NaN and zero values at the beginning and ending of the recordings,
- conversion of the cleaned data from CSV to the [NY format](@ref), easily accessible in any programming language.

For the details on the discarding procedures for each file see the *@discarded.md* file for [MI](https://zenodo.org/records/17801878/files/@discarded.md?download=1) and [P300](https://zenodo.org/records/17793672/files/@discarded.md?download=1).

For the details on the treatment that has been carried out on each database, see [Treatment MI](@ref) and [Treatment P300](@ref).

# Inclusion and Exclusion Criteria

Databases have been extracted from MOABB[^1], excluding those recorded on clinical populations.

If a database included several experimental conditions, it was split so as to result in one database per condition (see [database](@ref) "database" for the rationale).

Motor Imagery databases contain various classes, sometimes including paradigm-specific movements (e.g., compound movements). Only databases that included at least two of these following standard classes were selected:

`left_hand` → 1, `right_hand` → 2, `feet` → 3, `rest` → 4, `both_hands` → 5, `tongue` → 6

If classes not included in the above list were available, they have been excluded.

P300 databases always contain only two classes:

`nontarget` → 1, `target` → 2

These class prevalence must maintain a high nontarget/target ratio for optimal P300 response elicitation. The typical ratio is 5:1. Databases with other ratios were excluded.

The above numbering of classes has been used across all databases.

Here below is the complete list of the selected databases in the V3 of the corpus.

For summary tables of databases for each paradigm, see [Summary of P300 Databases](@ref) and [Summary of MI Databases](@ref).

### Motor Imagery databases

- AlexMI[^2]
- BNCI2014001[^3]
- BNCI2014002[^4]: separated into 2 different databases (BNCI2014002-Train and BNCI2014002-Test) due to different experimental conditions
- BNCI2014004[^5]: separated into 2 different databases (BNCI2014004-Train and BNCI2014004-Test) due to different experimental conditions
- BNCI2015001[^6]
- Cho2017[^7]
- GrossWentrup2009[^8]
- Lee2019MI[^9]
- PhysionetMI[^10]: separated into 2 different databases (PhysionetMI-T2 and PhysionetMI-T4) due to different experimental conditions
- Schirrmeister2017[^11]
- Shin2017A[^12]
- SPSM2025[^24]
- Weibo2014[^13]
- Zhou2016[^14]

### P300 databases

- bi2012[^15]: separated into 2 different databases (bi2012-Training and bi2012-Online) due to different experimental conditions
- bi2013a[^16]: separated into 4 different databases (bi2013a-NAO, bi2013a-NAT, bi2013a-AO, and bi2013a-AT) due to different experimental conditions
- bi2014a[^17]
- bi2014b[^18]
- bi2015a[^19]: separated into 3 different databases (bi2015-1, bi2015a-2, and bi2015a-3) due to different experimental conditions
- BNCI2014009[^20]
- BNCI2015003[^21]: separated into 2 different databases (BNCI2015003-Train and BNCI2015003-Test) due to different experimental conditions
- Cattan2019[^22]: separated into 2 different databases (Cattan2019-PC and Cattan2019-VR) due to different experimental conditions
- EPFLP300[^23]: separated into 6 different databases (EPFLP300-1, EPFLP300-2, EPFLP300-3, EPFLP300-4, EPFLP300-5, and EPFLP300-6) due to different experimental conditions
- Lee2019ERP[^9]: separated into 2 different databases (Lee2019ERP-Test and Lee2019ERP-Train) due to different experimental conditions

## BCI DB References

[^1]: Aristimunha, B., Carrara, I., Guetschel, P., Sedlar, S., Rodrigues, P., Sosulski, J., Narayanan, D., Bjareholt, E., Quentin, B., Schirrmeister, R. T.,Kalunga, E., Darmet, L., Gregoire, C., Abdul Hussain, A., Gatti, R., Goncharenko, V., Thielen, J., Moreau, T., Roy, Y., Jayaram, V., Barachant,A., & Chevallier, S. Mother of all BCI Benchmarks (MOABB), 2023. DOI: 10.5281/zenodo.10034223.

[^2]: Barachant, A., 2012. Commande robuste d'un effecteur par une interface cerveau machine EEG asynchrone (Doctoral dissertation, Université de Grenoble): <https://tel.archives-ouvertes.fr/tel-01196752>

[^3]: Tangermann, M., Müller, K.R., Aertsen, A., Birbaumer, N., Braun, C., Brunner, C., Leeb, R., Mehring, C., Miller, K.J., Mueller-Putz, G. and Nolte, G., 2012. Review of the BCI competition IV. Frontiers in neuroscience, 6, p.55.

[^4]: Steyrl, D., Scherer, R., Faller, J. and Müller-Putz, G.R., 2016. Random forests in non-invasive sensorimotor rhythm brain-computer interfaces: a practical and convenient non-linear classifier. Biomedical Engineering/Biomedizinische Technique, 61(1), pp.77-86.

[^5]: R. Leeb, F. Lee, C. Keinrath, R. Scherer, H. Bischof, G. Pfurtscheller. Brain-computer communication: motivation, aim, and impact of exploring a virtual apartment. IEEE Transactions on Neural Systems and Rehabilitation Engineering 15, 473–482, 2007

[^6]: J. Faller, C. Vidaurre, T. Solis-Escalante, C. Neuper and R. Scherer (2012). Autocalibration and recurrent adaptation: Towards a plug and play online ERD- BCI. IEEE Transactions on Neural Systems and Rehabilitation Engineering, 20(3), 313-319.

[^7]: Cho, H., Ahn, M., Ahn, S., Kwon, M. and Jun, S.C., 2017. EEG datasets for motor imagery brain computer interface. GigaScience. <https://doi.org/10.1093/gigascience/gix034>

[^8]: Grosse-Wentrup, Moritz, et al. "Beamforming in noninvasive brain–computer interfaces." IEEE Transactions on Biomedical Engineering 56.4 (2009): 1209-1219.

[^9]: Lee, M. H., Kwon, O. Y., Kim, Y. J., Kim, H. K., Lee, Y. E., Williamson, J., … Lee, S. W. (2019). EEG dataset and OpenBMI toolbox for three BCI paradigms: An investigation into BCI illiteracy. GigaScience, 8(5), 1–16. <https://doi.org/10.1093/gigascience/giz002>

[^10]: Goldberger, A.L., Amaral, L.A., Glass, L., Hausdorff, J.M., Ivanov, P.C., Mark, R.G., Mietus, J.E., Moody, G.B., Peng, C.K., Stanley, H.E. and PhysioBank, P., PhysioNet: components of a new research resource for complex physiologic signals Circulation 2000 Volume 101 Issue 23 pp. E215–E220.

[^11]: Schirrmeister, Robin Tibor, et al. "Deep learning with convolutional neural networks for EEG decoding and visualization." Human brain mapping 38.11 (2017): 5391-5420.

[^12]: Shin, J., von Lühmann, A., Blankertz, B., Kim, D.W., Jeong, J., Hwang, H.J. and Müller, K.R., 2017. Open access dataset for EEG+NIRS single-trial classification. IEEE Transactions on Neural Systems and Rehabilitation Engineering, 25(10), pp.1735-1745.

[^13]: Weibo, Y., et al. "Evaluation of EEG oscillatory patterns and cognitive process during simple and compound limb motor imagery." PloS one 9.12 (2014). <https://doi.org/10.1371/journal.pone.0114853>

[^14]: Zhou B, Wu X, Lv Z, Zhang L, Guo X (2016) A Fully Automated Trial Selection Method for Optimization of Motor Imagery Based Brain-Computer Interface. PLoS ONE 11(9). <https://doi.org/10.1371/journal.pone.0162657>

[^15]: Van Veen, G., Barachant, A., Andreev, A., Cattan, G., Rodrigues, P. C., & Congedo, M. (2019). Building Brain Invaders: EEG data of an experimental validation. arXiv preprint arXiv:1905.05182.

[^16]: Vaineau, E., Barachant, A., Andreev, A., Rodrigues, P. C., Cattan, G. & Congedo, M. (2019). Brain invaders adaptive versus non-adaptive P300 brain-computer interface dataset. arXiv preprint arXiv:1904.09111.

[^17]: Korczowski, L., Ostaschenko, E., Andreev, A., Cattan, G., Rodrigues, P. L. C., Gautheret, V., & Congedo, M. (2019). Brain Invaders calibration-less P300-based BCI using dry EEG electrodes Dataset (BI2014a). <https://hal.archives-ouvertes.fr/hal-02171575>

[^18]: Korczowski, L., Ostaschenko, E., Andreev, A., Cattan, G., Rodrigues, P. L. C., Gautheret, V., & Congedo, M. (2019). Brain Invaders Solo versus Collaboration: Multi-User P300-Based Brain-Computer Interface Dataset (BI2014b). <https://hal.archives-ouvertes.fr/hal-02173958>

[^19]: Korczowski, L., Cederhout, M., Andreev, A., Cattan, G., Rodrigues, P. L. C., Gautheret, V., & Congedo, M. (2019). Brain Invaders calibration-less P300-based BCI with modulation of flash duration Dataset (BI2015a) <https://hal.archives-ouvertes.fr/hal-02172347>

[^20]: P Aricò, F Aloise, F Schettini, S Salinari, D Mattia and F Cincotti (2013). Influence of P300 latency jitter on event related potential- based brain–computer interface performance. Journal of Neural Engineering, vol. 11, number 3.

[^21]: C. Guger, S. Daban, E. Sellers, C. Holzner, G. Krausz, R. Carabalona, F. Gramatica, and G. Edlinger (2009). How many people are able to control a P300-based brain-computer interface (BCI)?. Neuroscience Letters, vol. 462, pp. 94–98.

[^22]: G. Cattan, A. Andreev, P. L. C. Rodrigues, and M. Congedo (2019). Dataset of an EEG-based BCI experiment in Virtual Reality and on a Personal Computer. Research Report, GIPSA-lab; IHMTEK. <https://doi.org/10.5281/zenodo.2605204>

[^23]: Hoffmann U, Vesin JM, Ebrahimi T, Diserens K. An efficient P300-based brain-computer interface for disabled subjects. J Neurosci Methods. 2008 Jan 15;167(1):115-25. doi: 10.1016/j.jneumeth.2007.03.005. Epub 2007 Mar 13. PMID: 17445904.

[^24]: Arpaia P, Esposito A, Galasso E, Galdieri F, Natalizio A. A wearable brain-computer interface to play an endless runner game by self-paced motor imagery. J Neural Eng. 2025 Mar 26;22(2). doi: 10.1088/1741-2552/adc205. PMID: 40101362.
