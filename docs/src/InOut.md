```@meta
CurrentModule = Eegle
end
```

# InOut.jl

This module declares a structure for EEG-based BCI data and methods for reading and writing data

## Methods

|  Function      |           Description             |
|:-----------------------|:----------------------------------|
| [`Eegle.InOut.EEG`](@ref) | a structure for EEG-based BCI holding data and metadata |
| [`Eegle.InOut.readNY`](@ref) | read EEG/BCI data in [NY format](@ref) as an [`EEG`](@ref) structure|
| [`Eegle.InOut.readgTec`](@ref) | read EEG data recorded by the *g.Tec g.Recorder* software |
| [`Eegle.InOut.readASCII`](@ref) | read EEG data in ASCII text format (2 methods)|
| [`Eegle.InOut.readSensors`](@ref) | read EEG sensor labels from an ASCII text file |
| [`Eegle.InOut.writeASCII`](@ref) | write EEG data in ASCII text format (3 methods) |
📖
```@docs
    Eegle.InOut.EEG
    Eegle.InOut.readNY
    Eegle.InOut.readgTec
    Eegle.InOut.readASCII
    Eegle.InOut.readSensors
    Eegle.InOut.writeASCII
```
