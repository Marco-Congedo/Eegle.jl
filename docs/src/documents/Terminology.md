# Terminology

This page holds a detailed definition of terms used in relation to BCI databases. These definitions are used consistently throughout thee **Eegle** documentation and will be often referred to.

## BCI paradigm  
It is a kind of BCI exploiting a specific electrophysiological phenomenon in order to achieve decoding of EEG data. 

The most widespread paradigms are MI (Motor Imagery), P300 and SSVEP (steady-state visually evoked potentials). The experimental conditions under which a BCI may run within the same paradigm may be substantially different, contributing in promoting the variability of BCI data. For example in MI, trial duration and instructions given to the subject are diverse and so are in P300 the inter-stimulus interval, the flash duration, the number of flashing items, their meaning, etc. The number, position and type of electrodes, the EEG amplifier, the experimental procedure, environmental factors and subjects (e.g., healthy vs. unhealthy) are all confounding factors in BCI data.

## BCI trial 
It is an EEG epoch (time interval) providing the elementary object of encoding and decoding approaches. These epochs are in general positioned in time relative to a stimulation or a cue, depending on the [BCI paradigm](@ref), but may also be unrelated to any specific time position (e.g., in neurofeedback and self-paced MI). Typically, the duration of the trials is fixed in a given experiment and may last from a few hundred milliseconds to a few seconds.

## run
It is a collection of [trials](@ref "BCI trial") encompassing the time period during which an experimental [subject](@ref) is engaged in a task without interruption. Typically, a run lasts from a few minutes to a few tens of minutes.

## session
It comprises all [runs](@ref "run") performed while EEG electrodes remain attached to a subject's head. A session may include one or more runs, with possible pauses in between them. EEG recording files (datasets) typically enclose a session. In any case, in this documentation it is assumed so. A session typically lasts a few tens of minutes to a few hours.

## dataset 
It is an EEG recording, typically comprising a whole [sessions](@ref "session"). In this documentation the term dataset will not be used as it will always be synonymous with session.

## subject
It is a unique individual performing an experiment. A subject may provide one or several [sessions](@ref "session"). When several sessions are recorded from the same subject, they are typically recorded on different days.

## database
It is a collection of [sessions](@ref "session") recorded under experimental conditions held as constant as possible on one or more subjects. 

Typically, the number of sessions does not need to match the number of unique [subjects](@ref "subject"), that is, the number of sessions per subject may be different. We require that all sessions in a database have at least the following experimental parameters held constant: 
- number of classes, 
- trial duration, 
- number of electrodes, 
- type of electrodes, 
- EEG amplifier,
- sampling rate,
- temporal filtering. 

The interface should also be fixed as well as paradigm-specific experimental parameters, such as inter-stimulus interval and flash duration for P300, experimental instructions for MI, etc. Since in general experiments are carried out to manipulate experimental conditions, a single experiment will typically result in as many databases as experimental conditions. From a statistical point of view, these precautions make the sessions within the same database as homogeneous as possible, allowing to consider the accuracy achieved in those sessions as random samples drawn from the same population. This is important if any conclusions are to be drawn comparing the accuracy results between databases, e.g., between experimental conditions, and also if the databases are treated as observation units in comparing pipelines, as it is currently done in [MOABB](https://moabb.neurotechx.com/docs/index.html).