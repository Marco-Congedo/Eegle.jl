# Treatment P300

This document describes all the changes applied to downloaded P300 databases from MOABB or base repository.

## BNCI2014009

!!! details "show me"

    **Class Labels:**

    - Original: 1-Non-Target, 2-Target
    - Modified: "nontarget" → 1, "target" → 2 (standardization)

    **Sampling Rate:**

    - Original: 256Hz
    - Modified: No changes required

    **Specific Treatments:**

    - **Channel removal**: Flash channel removed
    - **Session handling**: 3 sessions with identical experimental conditions (no separation required)
    - **Epoch labeling correction**: In the original data, multiple sample from each epochs were flagged with the corresponding event class, which could cause problems in [NY format](@ref) and misinterpretation during epoch slicing. This was corrected by maintaining the label only at the first sample of each epoch, setting all other samples in the labeled blocks to 0.
    **Technical Note:** Typically, the stimulation channel has a non-zero value when an event is triggered (e.g., 1 for nontarget) at one specific sample. When data is sliced into epochs, an epoch starts at the trigger sample and ends at the trigger sample + window length samples (window length = trial length × sampling rate, e.g., for this database: trial length = 0.8s, sampling rate = 256Hz, window length = 0.8×256 ≈ 205 samples).

## BNCI2015003

!!! details "show me"

    **Class Labels:**

    - Original: 1-Non-Target, 2-Target
    - Modified: "nontarget" → 1, "target" → 2 (standardization)

    **Sampling Rate:**

    - Original: 256Hz
    - Modified: No changes required

    **Specific Treatments:**

    - **Channel removal**: Flash channel removed
    - **Epoch labeling correction**: In the original data, multiple sample from each epochs were flagged with the corresponding event class, which could cause problems in [NY format](@ref) and misinterpretation during epoch slicing. This was corrected by maintaining the label only at the first sample of each epoch, setting all other samples in the labeled blocks to 0.
    - **Database separation**:
    - **BNCI2015003-Train**: User attempted to spell "WATER" with no feedback (classifier training)
    - **BNCI2015003-Test**: User attempted to spell "LUCAS" with feedback (classifier testing)

## Cattan2019

!!! details "show me"

    **Class Labels:**

    - Original: 1-Non-Target, 1-Target
    - Modified: "nontarget" → 1, "target" → 2 (standardization)

    **Sampling Rate:**

    - Original: 512Hz
    - Modified: Downsampled to 256Hz (decimation factor = 2)

    **Specific Treatments:**

    - **Data cleaning**: Samples with NaN and/or zero values removed (first and last lines)
    - **Channel merging**: Original file contained separate nontarget and target stimulation channels (both using value 1 at the beginning of the trial). These were merged into a single stimulation channel with standardized labels.
    - **Channel removal**: Event channel and two irrelevant final columns removed
    - **Database separation**:
    - **Cattan2019-PC**: P300 signals displayed on personal computer
    - **Cattan2019-VR**: P300 signals displayed on VR headset

## EPFLP300

!!! details "show me"

    **Class Labels:**

    - Original: 1-Non-Target, 1-Target
    - Modified: 1-Target → 2-Target (standardization)

    **Sampling Rate:**

    - Original: 2048Hz
    - Modified: Downsampled to 256Hz (decimation factor = 8)

    **Specific Treatments:**

    - **Referencing**: Referencing was done substracting the mean of both Mastoid electrodes (MA1 and MA2) as it was done in the original paper.
    - **Channel removal**: MA1 and MA2 were removed after referencing
    - **Database separation**: 4 sessions with 6 runs per subject. Sessions were experimentally identical, but runs differed based on target image focus.
    - **Separated into 6 databases**: EPFLP300-1 to EPFLP300-6, corresponding to different target images (e.g., run 1 focused on television image)
    - **Sequence Balancing**: To address the target/non-target ratio imbalance and insufficient signal length at the end of the recording, the goal was to indentify incomplete sequences using a modulo 12 calculation on the stimulation channel. The final fix involved excluding (by setting labels to 0) both these residual trials and the last 12 trials of the final block. This restored the strict 5:1 ratio while ensuring that every retained stimulus met the minimum window length requirement for epoch extraction.

## Lee2019ERP

!!! details "show me"

    **Class Labels:**

    - Original: 2-Non-Target, 1-Target
    - Modified: "nontarget" → 1, "target" → 2. (standardization)

    **Sampling Rate:**

    - Original: 1000Hz
    - Modified: Downsampled to 200Hz (decimation factor = 5)

    **Specific Treatments:**

    - **Channel removal**: EMG channels removed
    - **Database separation**:
    - **Lee2019ERP-Train**: User copy-spelled "NEURAL NETWORKS AND DEEP LEARNING" (classifier training)
    - **Lee2019ERP-Test**: User copy-spelled "PATTERN RECOGNITION MACHINE LEARNING" (classifier testing)

## bi2012

!!! details "show me"

    **Class Labels:**

    - Original: 1-Non-Target, 1-Target
    - Modified: "nontarget" → 1, "target" → 2 (standardization)

    **Sampling Rate:**

    - Original: 128Hz
    - Modified: No changes required

    **Specific Treatments:**

    - **Data cleaning**: Samples with NaN and/or zero values removed (first and last lines)
    - **Channel merging**: Original file contained separate nontarget and target stimulation channels (both using value 1 at trial beginning). These were merged into a single stimulation channel with standardized labels.
    - **Channel removal**: Fz channel (ground) removed
    - **Database separation**:
    - **bi2012-T**: Offline training session (offline, predefined target sequence)
    - **bi2012-O**: Online testing session (online, randomized sequence)

## bi2013a

!!! details "show me"

    **Class Labels:**

    - Original: 33286-Non-Target, 33285-Target
    - Modified: "nontarget" → 1, "target" → 2. (standardization)

    **Sampling Rate:**

    - Original: 512Hz
    - Modified: Downsampled to 256Hz (decimation factor = 2)

    **Specific Treatments:**

    - **Database separation**: 4 sessions with different experimental conditions:
    - **bi2013a-NAT**: Non-Adaptive Training (offline, predefined target sequence)
    - **bi2013a-NAO**: Non-Adaptive Online (online, randomized sequence)
    - **bi2013a-AT**: Adaptive Training (offline, predefined target sequence)
    - **bi2013a-AO**: Adaptive Online (online, randomized sequence)

## bi2014a

!!! details "show me"

    **Class Labels:**

    - Original: 1-Non-Target, 2-Target
    - Modified: "nontarget" → 1, "target" → 2 (standardization)

    **Sampling Rate:**

    - Original: 512Hz
    - Modified: Downsampled to 256Hz (decimation factor = 2)

    **Specific Treatments:**

    - **Channel removal**: Event column removed
    - **Session handling**: Single session with 1 run (no separation required)

## bi2014b

!!! details "show me"

    **Class Labels:**

    - Original: 1-Non-Target, 2-Target
    - Modified: "nontarget" → 1, "target" → 2 (standardization)

    **Sampling Rate:**

    - Original: 512Hz
    - Modified: Downsampled to 256Hz (decimation factor = 2)

    **Specific Treatments:**

    - **Session selection**: Originally a multiplayer version of bi2014a, but one solo session per subject was recorded and were included as they were the only ones respecting the oddball paradigm
    - **Subject separation**: Original files contained both subjects with interleaved EEG channels (half for subject 1, half for subject 2). These were separated into distinct files for standardization.

## bi2015a

!!! details "show me"

    **Class Labels:**

    - Original: 1-Non-Target, 2-Target
    - Modified: "nontarget" → 1, "target" → 2 (standardization)

    **Sampling Rate:**

    - Original: 512Hz
    - Modified: Downsampled to 256Hz (decimation factor = 2)

    **Specific Treatments:**

    - **Channel merging**: Original file contained separate non-target and target stimulation channels (both using value 1 at trial beginning). These were merged into a single stimulation channel with standardized labels.
    - **Database separation**: 3 sessions with different flash durations (different experimental conditions):
    - **bi2015a-1**: 110ms flash duration
    - **bi2015a-2**: 80ms flash duration
    - **bi2015a-3**: 50ms flash duration
