# NY Metadata (YAML)

This document describes the standard dictionary structure used in `.yml` metadata files for EEG time series data in the [NY format](@ref).

## Overview

The YAML format has been employed for easily sharing EEG data metadata in Python and Julia environments. Each `.yml` file provides comprehensive metadata for its corresponding `.npz` data file.

## Dictionary Structure

The YAML file contains four main dictionaries:

### `acquisition`

Contains all technical information about the EEG data acquisition process.

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `filter` | String | Filter settings of the EEG acquisition machine | `"Low-Pass 83Hz (Butterworth order 4 zero phase) for downsampling"` |
| `ground` | String | Location of the ground electrode | `"Fpz"` or `"N/A"` |
| `reference` | String | Location of the reference electrode | `"A1"` or `"N/A"` |
| `hardware` | String | Commercial name and producer of EEG amplifier | `"g.tec EEG - g.USBamp EEG amplifier"` |
| `software` | String | Software used for data acquisition | `"OpenViBE, INRIA (France)"` or `"N/A"` |
| `samplingrate` | Integer | Sampling rate in Hz | `256` |
| `sensors` | Array of Strings | EEG electrode locations (excluding ground/reference) | `["Fpz", "F7", "F3", "Fz", ...]` |
| `sensortype` | String | Type and material of electrodes | `"Ag/AgCl Wet electrodes"` |

### `documentation`

Contains references and documentation links for the dataset.

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `description` | String | Link to dataset description | `"https://zenodo.org/records/806023"` |
| `doi` | String | Digital Object Identifier | `"https://theses.hal.science/tel-01196752"` |
| `investigators` | String | Principal investigators | `"Alexandre Barachant"` |
| `place` | String | Institution where experiment was conducted | `"GIPSA-lab..."` |
| `repository` | String | Link to data repository | `"https://zenodo.org/records/806023"` |

### `id`

Contains identification information for the specific recording.

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `condition` | String | Experimental condition | `"None"` or specific condition |
| `database` | String | Name of the database | `"AlexMI"` |
| `paradigm` | String | BCI paradigm type | `"MI"` or `"P300"` |
| `run` | Integer | Run number within session | `1` |
| `session` | Integer | Session number | `1` |
| `subject` | Integer | Subject identifier | `1` |
| `timestamp` | Integer | Year of data collection | `2012` |

### `stim`

Contains stimulation and labeling information.

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `labels` | Dictionary | Mapping of class names to numeric codes | `{"right_hand": 2, "feet": 3, "rest": 4}` |
| `nclasses` | Integer | Total number of stimulus classes | `3` |
| `trials_per_class` | Dictionary | Number of trials available for each class | `{"feet": 20, "rest": 20, "right_hand": 20}` |
| `offset` | Integer | Offset in samples from stimulation to trial start | `0` |
| `windowlength` | Integer | Trial duration in samples | `768` |

## Example Structure

```yaml
formatversion: 0.0.1

acquisition:
  filter: "Low-Pass 83Hz (Butterworth order 4 zero phase) for downsampling"
  ground: "N/A"
  hardware: "g.tec EEG - g.USBamp EEG amplifier"
  reference: "N/A"
  samplingrate: 256
  sensors: ["Fpz", "F7", "F3", "Fz", "F4", "F8", "T7", "C3", "Cz", "C4", "T8", "P7", "P3", "Pz", "P4", "P8"]
  sensortype: "Ag/AgCl Wet electrodes"
  software: "N/A"

documentation:
  description: "https://zenodo.org/records/806023"
  doi: "https://theses.hal.science/tel-01196752"
  investigators: "Alexandre Barachant"
  place: "Laboratoire Electronique et systeme pour la sante CEA-LETI dans l'Ecole Doctorale : EEATS, Universite de Grenoble"
  repository: "https://zenodo.org/records/806023"

id:
  condition: "None"
  database: "AlexMI"
  paradigm: "MI"
  run: 1
  session: 1
  subject: 1
  timestamp: 2012

stim:
  labels:
    right_hand: 2
    feet: 3
    rest: 4
  nclasses: 3
  trials_per_class:
    right_hand: 20
    feet: 20
    rest: 20
  offset: 0
  windowlength: 768
```