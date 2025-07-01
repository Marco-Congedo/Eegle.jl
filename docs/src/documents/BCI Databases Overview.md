# BCI Databases Overview

This document outlines the structure and content of the 'BCI Databases' repository, which encompasses multiple datasets across various paradigms. Currently, it focuses on P300 and Motor Imagery (MI) data.

<!-- future sections to add when available:
- Cleared data
- deprecated data
- GitHub repository -->

## Terminology

#### BCI paradigm  
It is a kind of BCI exploiting a specific electrophysiological phenomenon in order to achieve decoding of EEG data. 

The most widespread paradigms are MI, P300 and SSVEP. The experimental conditions under which a BCI may run within the same paradigm may be substantially different, contributing in promoting the variability of BCI data. For example, in MI trial duration and instructions given to the subject are diverse and so are in P300 the inter-stimulus interval, the flash duration, the number of flashing items, their meaning, etc. The number, position and type of electrodes, the EEG amplifier, the experimental procedure, environmental factors and subjects (e.g., healthy vs. unhealthy) are all confounding factors in BCI data.

#### BCI trial 
It is an EEG epoch (time interval) providing the elementary object of encoding and decoding approaches. These epochs are in general positioned in time relative to a stimulation or a cue, depending on the BCI paradigm, but may also be unrelated to any specific time position (e.g., in neurofeedback and self-paced MI). Typically, the duration of the trials is fixed in a given experiment and may last from a few hundred milliseconds to a few seconds.

#### run
A collection of trials forms a **run**, which encompasses the time period during which an experimental subject is engaged in a task without interruption. Typically, a run lasts from a few minutes to a few tens of minutes.

#### session
It comprises all runs performed while EEG electrodes remain attached to a subject's head. A session may include one or more runs, with possible pauses in between them. EEG recording files typically enclose a session. In any case, in this documentation it is assumed so. A session typically lasts a few tens of minutes to a few hours.

#### subject
It is a unique individual performing an experiment. A subject may provide one or several sessions. When several sessions are recorded from the same subject, they are typically recorded on different days.

#### dataset 
It is an EEG recording, typically comprising a whole session. In this documentation the term dataset will not be used as it will always be synonymous with session.

#### database
It is a collection of datasets recorded under experimental conditions held as constant as possible on one or more subjects. 

Typically, the number of datasets corresponds to the number of sessions and this number does not need to match the number of unique subjects, that is, the number of sessions per subject may be different. We require that all sessions in a database have at least the following experimental parameters held constant: number of classes, trial duration, number of electrodes, type of electrodes, EEG amplifier. The interface should also be fixed as well as paradigm-specific experimental parameters, such as inter-stimulus interval and flash duration for P300, experimental instructions for MI, etc. Since in general experiments are run to manipulate experimental conditions, a single experiment will typically result in as many databases as experimental conditions. From a statistical point of view, these precautions make the sessions within the same database as homogeneous as possible, allowing to consider the accuracy achieved in those sessions as random samples drawn from the same population. This is important if any conclusions are to be drawn comparing the accuracy results between databases, e.g., between experimental conditions, and also if the databases are treated as observation units in comparing pipelines, as it is currently done in MOABB[^1].

## Databases Selection

Based on the [terminology](#Terminology) section, we have selected and separated multiple databases primarily acquired from MOABB[^1] and supplemented by databases from their original repositories. Currently, our collection includes only P300 and Motor Imagery (MI) databases. This work was originally conducted for heterogeneous transfer learning research with the goal of "universalizing" BCI Databases, which guided our selection criteria. However, all data can be used for any purpose. For all paradigms, we have only included databases with healthy subjects.

Motor Imagery databases contain various classes, sometimes including paradigm-specific movements (e.g., compound movements). We selected only databases that included at least two of these following standard classes: 

"left\\_hand" → 1, "right\\_hand" → 2, "feet" → 3, "rest" → 4, "both\\_hands" → 5, "tongue" → 6

Other classes were excluded. Additionally, databases containing executed movements or mental tasks (rather than imagined movements) were also excluded.

P300 databases contain only two classes: 

"nontarget" → 1, "target" → 2. 

These classes must maintain a specific ratio for optimal P300 response elicitation: typically 5:1 (nontarget:target). This imbalanced ratio is essential for the oddball paradigm, as the infrequent target stimuli generate the characteristic P300 event-related potential. Databases where the ratio was lower or higher than 5:1 were excluded.

Here is an exhaustive list of our selected databases:

### Sixteen Motor Imagery databases

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
- Weibo2014[^13]
- Zhou2016[^14]

### Twenty-Four P300 databases

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

You can find summary tables of databases for each paradigm in here : [P300](Databases Summary P300.md) / [MI](Databases Summary MI.md).

## Repository Structure

The BCI Databases repository is organized into two main folders: 'CSV' and 'NY'.
It also contains two other Markdown files related to the treatments applied to databases: [TreatmentMI](TreatmentMI.md) and [TreatmentP300](TreatmentP300.md).
The repository includes summary tables for each paradigm comprising all main characteristics of all databases.

### CSV format

The goal with the CSV format is to universalize the raw data of each database and establish a common structure format.
The CSV files are organized as follows:

- First column: timestamps of the samples
- Middle columns: EEG electrodes data
- Last column: stimulation containing labels for each class when an event is triggered
- Lines correspond to samples of the acquired data.

Here are the common treatments applied to all databases:

- Data is stored in Volts and Float64 format (to facilitate use with MNE Python[^24], which only supports data in Volt)
- Classes were re-labeled to match the standardized numbering scheme described in the [Databases Selection](#Databases Selection) section
- Data with sampling rates below 256 Hz was kept unchanged, while data above 256 Hz was downsampled using integer decimation factors to obtain integer sampling rates ≤ 256 Hz. For downsampling, we applied a zero-phase low-pass filter before decimation using MNE Python[^24], with cutoff frequency less than 1/3 of the desired sampling rate to prevent aliasing artifacts (e.g., original sampling rate 1000 Hz, desired sampling rate 200 Hz → low-pass filter cutoff <66 Hz before applying decimation factor of 5).
- Irrelevant electrodes were removed (reference or ground electrodes, EMG and EOG electrodes)
- Data from different runs within the same session with identical experimental conditions were concatenated into a single session file
- Irrelevant classes were removed (their labels were changed to 0)
- Samples where the sum of all EEG columns equaled 0 or that contained NaN values were removed (such artifacts never coincided with trigger events in the stimulation column and were found at the beginning or end of recordings)

Stimulation column labeling was specific to the BCI paradigm:

- MI was labeled as "left\\_hand" → 1, "right\\_hand" → 2, "feet" → 3, "rest" → 4, "both\\_hands" → 5, "tongue" → 6
- P300 was labeled as "nontarget" → 1, "target" → 2
- Remaining samples were labeled as 0

Once all databases were converted to the [CSV format](#CSV format), they were transcribed to NY format.

### NY format

This format is tailor-made for BCI data, ensuring compatibility and ease of use in both Julia and Python environments.

When converted to NY format, the EEG signal is stored in microvolts (µV) as it is the standard in the EEG community.

The NY format consists of two essential files:

- **`.npz File`**: Contains the raw data and stimulation vector, crucial for BCI data analysis. This .npz file follows the standard NumPy[^25] compressed archive format, which stores multiple arrays in a single file using ZIP compression. The file contains two arrays:
  - `X`: EEG data matrix of shape (n_samples, n_channels) in µV and Float32 format
  - `stim`: Stimulation vector of shape (n_samples,) with integer labels

  This format is natively supported in Python through NumPy and easily readable in Julia via the [NPZ.jl](https://github.com/fhs/NPZ.jl) package.

- **`.yml File`**: Stores metadata offering a comprehensive overview of the dataset's characteristics. The dictionary structure can be viewed in detail here: [YAML Structure](yamlstruct.md)

## Converters

All scripts designed for data conversion between formats (Base repository/MOABB to CSV and CSV to NY) tailored to each dataset's requirements are available in the 'Converters' folder and in [GitHub repository](https://github.com/FhmDmi/BCI-Databases).

These scripts facilitate the data pre-processing workflow:

- **MOABB/BASE to CSV**: Python scripts with comprehensive comments guide the users through the conversion process from downloaded raw data (MOABB or original repositories) to the defined [CSV format](#CSV format)
- **CSV to NY**: Python scripts with comprehensive comments guide the users through the conversion process from CSV to NY format.

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

[^13]: Yi, Weibo, et al. "Evaluation of EEG oscillatory patterns and cognitive process during simple and compound limb motor imagery." PloS one 9.12 (2014). <https://doi.org/10.1371/journal.pone.0114853>

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

[^24]: Alexandre Gramfort, Martin Luessi, Eric Larson, Denis A. Engemann, Daniel Strohmeier, Christian Brodbeck, Roman Goj, Mainak Jas, Teon Brooks, Lauri Parkkonen, and Matti S. Hämäläinen. MEG and EEG data analysis with MNE-Python. Frontiers in Neuroscience, 7(267):1–13, 2013. doi:10.3389/fnins.2013.00267.

[^25]: Harris, C. R., Millman, K. J., van der Walt, S. J., Gommers, R., Virtanen, P., Cournapeau, D., … Oliphant, T. E. (2020). Array programming with NumPy. Nature, 585, 357–362. <https://doi.org/10.1038/s41586-020-2649-2>
