# Example Data

**Eegle** deploys example EEG data files in [NY format](@ref) to be used in examples and tutorials.
This format is read by fucntion [`readNY`](@ref), which creates an [`EEG`](@ref) structure including both the data and metadata. 
The complete path to the file is is accessible anywhere as Eegle.{CONSTANT},
where {CONSTANT} is one of the heading here below. See the [tutorials](@ref "Tutorials").

---
## `EXAMPLE_MI_1`

This is the file corresponding to the first [session](@ref) of [subject](@ref) 3
of motor-imagery Brain-Computer Interface database [Alex MI](@ref "Summary of MI Databases"):
- amplifier: *g.USBamp* (g.tec medical engineering GmbH, Graz, Austria)
- channels: 16 standard Ag/AgCl electrodes
- electrical reference: right ear lobe
- sampling rate: 256 samples per second
- pre-processing: Notch filter at 50Hz and band-pass filter 1Hz-83Hz
- duration: 63020 samples
- MI classes: 1="right_hand", 2="feet", 3="rest"
- number of trials per class: 1=20, 2=20, 3=20.

See [Tutorial ML 2](@ref).

---
## `EXAMPLE_P300_1`

This is the file corresponding to the first [session](@ref) of the first [subject](@ref) 
of P300 Brain-Computer Interface database [bi2012-T](@ref "bi2012"):

- amplifier: *NeXus-32* (TMSi, Oldenzaal, The Netherlands)
- channels: 16 standard Ag/AgCl electrodes
- electrical reference: hardware common average
- sampling rate: 128 samples per second
- pre-processing: High-pass filter 1Hz
- duration: 46804 samples
- MI classes: 1="nontarget", 2="target"
- number of trials per class: 1=640, 2=128.

---
## `EXAMPLE_Normative_1`

Eyes-close resting-state continuous EEG recording acquired on a 20yo healthy woman:
- amplifier: *Mitsar-EEG-201* (Mitsar Co. Ltd., St. Petersburg, Russia)
- channels: 19 standard Ag/AgCl electrodes (10-20 international system)
- electrical reference: right ear lobe
- sampling rate: 128 samples per second
- pre-processing: Notch filter at 50Hz, band-pass (1.5-32Hz) filter and manual artefact rejection using the *Eureka3!* software (Nova Tech EEG, Inc., Mesa, AZ, USA)
- duration: 80s.

This file is accompanied by file `EXAMPLE_Normative_1_sensors.txt` holding the sensor labels.

See [Tutorial SA 1](@ref).

---