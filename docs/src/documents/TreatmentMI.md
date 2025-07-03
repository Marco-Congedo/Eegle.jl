# Data Treatment for Motor Imagery Databases

This document describes all the changes applied to downloaded Motor Imagery databases from MOABB to achieve standardization in the CSV format.

## AlexMI

**Class Labels:**

- Original: 2-right_hand, 3-feet, 4-rest
- Modified: No changes required

**Sampling Rate:**

- Original: 512Hz
- Modified: Downsampled to 256Hz (decimation factor = 2)

**Specific Treatments:**

- **Epoch labeling correction**: In the original data, entire epochs were labeled with the corresponding event class, which could cause problems in [NY format](#NY-format) and misinterpretation during epoch slicing. This was corrected by maintaining the label only at the first sample of each epoch, setting all other samples in the labeled blocks to 0.

**Technical Note:** Typically, the stimulation channel has a non-zero value when an event is triggered (e.g., 1 for left-hand) at one specific sample. When data is sliced into epochs, an epoch starts at the trigger sample and ends at the trigger sample + window length samples (window length = trial length × sampling rate, e.g., for this database: trial length = 3s, sampling rate = 256Hz, window length = 3×256 = 768 samples).

## BNCI2014001

**Class Labels:**

- Original: 1-left_hand, 2-right_hand, 3-feet, 4-tongue
- Modified: 4-tongue → 6-tongue (standardization)

**Sampling Rate:**

- Original: 250Hz
- Modified: No changes required

**Specific Treatments:**

- **Offset addition**: 2-second offset added as per the original paper's instructions (first 2 seconds after trigger correspond to visual cue indicating incoming MI task)
- **Channel removal**: EOG channels removed
- **Session concatenation**: Runs concatenated into corresponding sessions (identical experimental conditions)

## BNCI2014002

**Class Labels:**

- Original: 1-right_hand, 2-feet
- Modified: 1-right_hand → 2-right_hand, 2-feet → 3-feet (standardization)

**Sampling Rate:**

- Original: 512Hz
- Modified: Downsampled to 256Hz (decimation factor = 2)

**Specific Treatments:**

- **Data cleaning**: Samples with NaN and/or zero values removed (first and last lines)
- **Offset addition**: 3-second offset added as per the original paper's instructions (first 3 seconds after trigger correspond to visual cue indicating incoming MI task)
- **Database separation**:

  - **BNCI2014002-Train**: Runs 1-5 (no feedback, used for classifier training)
  - **BNCI2014002-Test**: Runs 6-8 (with feedback, used for classifier testing)

## BNCI2014004

**Class Labels:**

- Original: 1-left_hand, 2-right_hand
- Modified: No changes required

**Sampling Rate:**

- Original: 250Hz
- Modified: No changes required

**Specific Treatments:**

- **Data cleaning**: Samples with NaN and/or zero values removed
- **Channel removal**: EOG channels removed
- **Offset addition**: 3-second offset added as per the original paper's instructions (first 3 seconds after trigger correspond to visual cue indicating incoming MI task)
- **Database separation**:
  - **BNCI2014004-Train**: Sessions 1-2 (no feedback, used for classifier training)
  - **BNCI2014004-Test**: Sessions 3-5 (with feedback, used for classifier testing)

**Warning:** Session 3 is labeled as training in MOABB but as testing in the original paper. We followed the original paper classification.

## BNCI2015001

**Class Labels:**

- Original: 1-right_hand, 2-feet
- Modified: 1-right_hand → 2-right_hand, 2-feet → 3-feet (standardization)

**Sampling Rate:**

- Original: 512Hz
- Modified: Downsampled to 256Hz (decimation factor = 2)

**Specific Treatments:**

- **Session handling**: 2-3 sessions per subject with identical experimental conditions (no separation required)

## Cho2017

**Class Labels:**

- Original: 1-left_hand, 2-right_hand
- Modified: No changes required

**Sampling Rate:**

- Original: 512Hz
- Modified: Downsampled to 256Hz (decimation factor = 2)

**Specific Treatments:**

- **Channel removal**: EMG channels removed

## GrossWentrup2009

**Class Labels:**

- Original: 1-left_hand, 2-right_hand
- Modified: No changes required

**Sampling Rate:**

- Original: 500Hz
- Modified: Downsampled to 250Hz (decimation factor = 2)

**Specific Treatments:**

- No additional changes required

## Lee2019MI

**Class Labels:**

- Original: 1-right_hand, 2-left_hand
- Modified: 1-right_hand → 2-right_hand, 2-left_hand → 1-left_hand (standardization)

**Sampling Rate:**

- Original: 1000Hz
- Modified: Downsampled to 200Hz (decimation factor = 5)

**Specific Treatments:**

- **Channel removal**: EMG channels removed
- **Session handling**: 2 sessions with identical experimental conditions (no separation required)

## PhysionetMI

**Class Labels:**

- Original: 1-rest, 2-left_hand, 3-right_hand, 4-both_hands, 5-feet
- Modified: 1-rest → 4-rest, 2-left_hand → 1-left_hand, 3-right_hand → 2-right_hand, 4-both_hands → 5-both_hands, 5-feet → 3-feet (standardization)

**Sampling Rate:**

- Original: 160Hz
- Modified: No changes required

**Specific Treatments:**

- **Data cleaning**: Samples with NaN and/or zero values removed
- **Task selection**: Only imagined movement tasks included (Tasks 1 and 3 with executed movements excluded)
- **Database separation**:
  - **PhysionetMI-T2**: Task 2 (left_hand and right_hand classes) - Runs 4, 8, 12 concatenated
  - **PhysionetMI-T4**: Task 4 (both_hands and feet classes) - Runs 6, 10, 14 concatenated

## Schirrmeister2017

**Class Labels:**

- Original: 1-feet, 2-left_hand, 3-rest, 4-right_hand
- Modified: 1-feet → 3-feet, 2-left_hand → 1-left_hand, 3-rest → 4-rest, 4-right_hand → 2-right_hand (standardization)

**Sampling Rate:**

- Original: 500Hz
- Modified: Downsampled to 250Hz (decimation factor = 2)

**Specific Treatments:**

- **Session concatenation**: Train and test runs concatenated into single session (identical experimental conditions)

**Warning:** When using `paradigm.get_data()` from MOABB for `.yml` metadata acquisition, class labels differ from the original paper. Original labels were used for CSV to NY conversion.

## Shin2017A

**Class Labels:**

- Original: 1-left_hand, 2-right_hand
- Modified: No changes required

**Sampling Rate:**

- Original: 200Hz
- Modified: No changes required

**Specific Treatments:**

- **Channel removal**: EOG channels removed
- **Session handling**: 3 sessions with identical experimental conditions (no separation required)

## Weibo2014

**Class Labels:**

- Original: 1-left_hand, 2-right_hand, 3-both_hands, 4-feet, 7-rest
- Modified: 3-both_hands → 5-both_hands, 4-feet → 3-feet, 7-rest → 4-rest (standardization)

**Sampling Rate:**

- Original: 200Hz
- Modified: No changes required

**Specific Treatments:**

- **Offset addition**: 3-second offset added as per the original paper's instructions (first 3 seconds after trigger correspond to visual cue indicating incoming MI task)
- **Channel removal**: EOG and CB channels removed (CB electrodes purpose unclear)
- **Data cleaning**: Samples with NaN and/or zero values removed

## Zhou2016

**Class Labels:**

- Original: 1-left_hand, 2-right_hand, 3-feet
- Modified: No changes required

**Sampling Rate:**

- Original: 250Hz
- Modified: No changes required

**Specific Treatments:**

- **Session concatenation**: 3 sessions of 2 runs each with identical conditions, runs concatenated into corresponding sessions
- **Channel removal**: EOG channels removed
