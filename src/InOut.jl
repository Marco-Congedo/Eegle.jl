# v 0.2 April 2023
# v 0.3 April 2025
# v 0.4 June 2025
# Part of the Eegle.jl package.
# Copyright Marco Congedo, Fahim Doumi, CNRS, University Grenoble Alpes.

# ? ¤ CONTENT ¤ ? 

# STRUCTURES
# EEG | holds data and metadata of an EEG recording

# FUNCTIONS:
# readNY        | read an EEG recording in [NY format](@ref)
# readgTec      | read an EEG recording from a HDF5 file saved by g.Tec g.Recorder software
# readSensors   | read a list of electrodes from an ICoN electrodes ASCII file
# readASCII (2 methods) | read one ASCII file or all ASCII files in a directory
# writeASCII    | write one abstractArray data matrix in ASCII format
# writeASCII    | write a vector of strings in ASCII format (in 1 line or multiple lines)
# writeVector   | write a vector of strings as an ASCII file
##### Methods of the EEG structure
# mean          | mean ERPs

module InOut

using NPZ, YAML, HDF5, EzXML, DSP 

# Eegle modules
using Eegle.FileSystem, Eegle.Preprocessing, Eegle.ERPs

import Statistics: mean
import Eegle

# Module REPL text colors
const titleFont     = "\x1b[95m"
const separatorFont = "\x1b[35m"
const defaultFont   = "\x1b[0m"
const greyFont      = "\x1b[90m"


export
    EEG,
    readNY,
    readSensors,
    readgTec,
    readASCII,
    writeASCII,
    writeVector,
    # EEG structure methods
    mean

"""
```julia
    struct EEG
        id              :: Dict{Any,Any} 
        acquisition     :: Dict{Any,Any} 
        documentation   :: Dict{Any,Any} 
        formatversion   :: String        

        # the following fields are those most useful in practice
        db              :: String  
        paradigm        :: Symbol      
        subject         :: Int           
        session         :: Int           
        run             :: Int           
        sensors         :: Vector{String}
        sr              :: Int           
        ne              :: Int           
        ns              :: Int           
        wl              :: Int           
        offset          :: Int           
        nc              :: Int           
        clabels         :: Vector{String} 
        stim            :: Vector{Int}    
        mark            :: Vector{Vector{Int}}  
        y               :: Vector{Int}          
        X               :: Matrix{T} where T<:Real 
        trials          :: Union{Vector{Matrix{T}}, Nothing} 
    where T<:Real 
```
Data structure for an EEG BCI (Brain-Computer Interface) [session](@ref), holding data and metadata.

It is written by [`readNY`](@ref).

While conceived specifically for BCI sessions, the structure can be used also for general EEG recordings.

**Fields**

- `db`: name of the [database](@ref) to which the recording belongs
- `paradigm`: BCI paradigm
- `subject`: serial number of the present [subject](@ref) in the above database
- `session`: serial number of the present [session](@ref) for the above subject
- `run`: serial number of the present [run](@ref) of the above session
- `sensors`: labels of the scalp electrode leads in standard notation (10-20, 10-10,...)
- `sr`: sampling rate in samples
- `ne`: number of electrode leads
- `ns`: number of samples 
- `wl`: window length in samples. Typically, the duration of a BCI trial
- `offset`: see [offset](@ref)
- `nc`: number of classes (non-zero tags)
- `clabels`: labels of the classes
- `stim`: the [stimulation vector](@ref)
- `mark`: the [marker vectors](@ref) 
- `y`: the markers in vectors `mark` concatenated in an unique vector
- `X`: the ``T×N`` EEG data, with ``T`` and ``N`` the number of samples and channels (sensors), respectively
- `trials`: a vector of trials, each of size ``N×wl``, extracted in the order of tags given in `stim` (optional)
- the keys for dictionaries `id`, `acquisition`, and `documentation` are — see [NY Metadata (YAML)](@ref)):

| id          | acquisition   |documentation  |
|:------------|:--------------|:--------------|
| "run"       | "sensors"     |"doi"          |
| "timestamp" | "software"    |"repository"   |
| "database"  | "ground"      |"description"  |
| "subject"   | "reference"   |"investigators"|
| "session"   | "filter"      |"place"        |
| "condition" | "sensortype"  ||
| "paradigm"  | "samplingrate"||
|             | "hardware"    ||

In Julia, a structure has a default constructor taking all fields as arguments.
A simplified constructor is also available, as

```julia
    EEG(    X::Matrix{T}, 
            sr::Int, 
            sensors::Vector{String};
        db::String = "",
        paradigm::Symbol = :NA,
        subject::Int = 0,
        session::Int = 1,
        run::Int = 1,
        wl::Int = sr,
        offset::Int = 0,
        nc::Int = 1,
        clabels::Vector{String} = [""],
        stim::Vector{Int} = ["0"],
        mark::Vector{Vector{Int}} = [[""]],
        y::Vector{Int} = [0])
    where T<:Real
```
The above creates an EEG structure providing, *ad minima*:
- the EEG data `X`
- the sampling rate `sr`
- the sensor labels `sensors`.

The [kwarg](@ref "Acronyms") of this constructor are useful fields that can be filled.
The dictionaries of the structure are left empty.

"""
struct EEG
    id              :: Dict{Any,Any} # `id` Dictionary of the .yml file
    # it includes keys:   "run", "other", "database", "subject", "session"
    acquisition     :: Dict{Any,Any} # `acquisition` Dictionary of the .yml file
    # it includes keys:   "sensors", "software", "ground", "reference",
    #                      "filter", "sensortype", "samplingrate", "hardware"
    documentation   :: Dict{Any,Any} # `acquisition` Dictionary of the .yml file
    # it includes keys:   "doi", "repository", "description"
    formatversion   :: String        # `formatversion` field of the .yml file

    # the following fields are what is useful in practice
    db              :: String        # name of the database to which this file belongs
    paradigm        :: Symbol        # BCI paradigm
    subject         :: Int           # serial number of the subject in database
    session         :: Int           # serial number of the session of this subject
    run             :: Int           # serial number of the run of this session
    sensors         :: Vector{String}# electrode leads on the scalp in standard 10-10 notation
    sr              :: Int           # sampling rate
    ne              :: Int           # number of electrodes (excluding reference and ground)
    ns              :: Int           # number of samples
    wl              :: Int           # window length: typically, the duration of the trials
    offset          :: Int           # each trial start at `stim` sample + offset
    nc              :: Int           # number of classes
    clabels         :: Vector{String} # class labels given as strings
    stim            :: Vector{Int}    # stimulations for each sample (0, 1, 2...). 0 means no stimulation
    mark            :: Vector{Vector{Int}}  # markers (in sample) for class 1, 2...
    y               :: Vector{Int}          # the vectors in `mark` concatenated
    X               :: Matrix{T} where T<:Real # whole recording EEG data (ns x ne)
    trials          :: Union{Vector{Matrix{T}}, Nothing} where T<:Real # all trials in order of `stims` (optional)
end


EEG(X::Matrix{T}, sr::Int, sensors::Vector{String};
    db::String = "",
    paradigm::Symbol = :NA,
    subject::Int = 0,
    session::Int = 1,
    run::Int = 1,
    wl::Int = sr,
    offset::Int = 0,
    nc::Int = 1,
    clabels::Vector{String} = [""],
    stim::Vector{Int} = ["0"],
    mark::Vector{Vector{Int}} = [[""]],
    y::Vector{Int} = [0]) where T<:Real =
    EEG(Dict(), Dict(), Dict(), "0.0.1", db, paradigm, subject,
        session, run, sensors, sr, size(X, 2), size(X, 1), wl, offset,
        nc, clabels, stim, mark, y, X, nothing)

# `_standardizeClasses` function is exclusively used within `readNY` (from the InOut.jl package) 
# to normalize EEG data numerical codes according to standard conventions.
# It takes an experimental paradigm (MI, P300, ERP), class names (`clabels`), the related numerical values(`clabelsval`), 
# and the stim vector, then applies a uniform mapping (e.g., "left_hand" → 1, "right_hand" → 2 for MI). 
# The function verifies class compatibility with the chosen paradigm, detects if data is already standardized, 
# and returns a normalized stim vector, thereby facilitating model training across heterogeneous databases.
# This function is case insensitive but you need to respect the correct spelling of classes.
# MI : left_hand, right_hand, feet, rest, both_hands, tongue
# P300 : nontarget, target
# ERP : not currently supported.
# Return a new standardized stim vector and clabels if it was not already the same mapping.
function _standardizeClasses(paradigm::Symbol, 
                            clabels::Vector{String}, 
                            clabelsval::Vector{Int64}, 
                            stim::Vector{Int64})

    # Define standardized mappings for each paradigm
    if paradigm == :MI
        standard_mapping = Dict("left_hand" => 1, "right_hand" => 2, "feet" => 3, "rest" => 4, "both_hands" => 5, "tongue" => 6)
        supported_classes = keys(standard_mapping)
    elseif paradigm == :P300
        standard_mapping = Dict("nontarget" => 1, "target" => 2)
        supported_classes = keys(standard_mapping)
    elseif paradigm == :ERP
        throw(ArgumentError("Eegle.InOut package, internal function `_standardizeClasses` called by `readNY`: ERP paradigm not supported yet for class standardization"))
    else
        throw(ArgumentError("Eegle.InOut package, internal function `_standardizeClasses` called by `readNY`: Unknown paradigm: $paradigm. Supported paradigms: MI, P300"))
    end
    
    clabels_lower = lowercase.(clabels)
    unsupported_classes = [label for label in clabels_lower if !haskey(standard_mapping, label)]

    # Throw error if unsupported classes found
    if !isempty(unsupported_classes)
        error_msg = "Eegle.InOut package, internal function `_standardizeClasses` called by `readNY`: only these classes are compatible with standardization for $paradigm paradigm: " *
                   "$(join(supported_classes, ", ")). " *
                   "\nUnsupported classes found: $(join(unsupported_classes, ", ")). " *
                   "\nPlease verify the correct spelling of your classes (case insensitive)"
        throw(ArgumentError("Eegle.InOut, internal function `_standardizeClasses` called by `readNY`: "* error_msg))
    end
    
    # Create mapping and check if already standardized
    value_mapping = Dict{Int64, Int64}(clabelsval[i] => standard_mapping[clabels_lower[i]] for i in eachindex(clabels_lower))
    already_standardized = all(k == v for (k, v) in value_mapping)
    stim_standardized, clabels_standardized = copy(stim), copy(clabels)

    if already_standardized
        println("\n✓ Class labels in file follows Eegle's conventions.")
    else
        @inbounds for i in eachindex(stim_standardized)
            stim_standardized[i] != 0 && haskey(value_mapping, stim_standardized[i]) && (stim_standardized[i] = value_mapping[stim_standardized[i]])
        end
        # Reorder clabels and clabelsval according to standardized mapping
        sorted_indices = sortperm([standard_mapping[clabels_lower[i]] for i in eachindex(clabels_lower)])
        clabels_standardized = clabels[sorted_indices]
        mapping_display = ["$(clabels[findfirst(==(k), clabelsval)])($k->$v)" for (k,v) in value_mapping]
        println("\n✓ Class labels have been formatted according to Eegle's convention\nMapping applied: $(join(mapping_display, ", "))")
    end
    return stim_standardized, clabels_standardized
end


"""
```julia
    function readNY(filename :: AbstractString;
        toFloat64   :: Bool = true,
        bandStop    :: Tuple = (),
        bandPass    :: Tuple = (),
        bsDesign    :: DSP.ZeroPoleGain = Butterworth(8),
        bpDesign    :: DSP.ZeroPoleGain = Butterworth(4),
        rate        :: Union{Real, Rational, Int} = 1,
        upperLimit  :: Union{Real, Int} = 0,
        getTrials   :: Union{Bool, Vector{String}} = true, 
        stdClass    :: Bool = true, 
        msg         :: String="") 
```
Read EEG/BCI data in [NY format](#NY-format), prepreprocess them if desired, and create an [`EEG`](@ref) structure.

If requested, the preprocessing operations are performed in the order of the [kwargs](@ref Acronyms).

**Arguments**
- `filename`: the complete path of either the *.npz* or the *.yml* file of the recording to be read.

**Optional Keyword Arguments**
- `toFloat64`: if true, the EEG data is converted to Float64 if it is not already (default: true)
- `bandStop`: a 2-tuple holding the limits in Hz of a notch filter (default: no filter)
- `bandPass`: a 2-tuple holding the limits in Hz of a band-pass filter (default: no filter)
- `bsDesign`: the filter design method for the notch filter passed to [`filtfilt`](@ref) (default: Butterworth(8))
- `bpDesign`: the filter design method for the band-pass filter passed to [`filtfilt`](@ref) (default: Butterworth(4))
- `rate`: argument passed to [`resample`](@ref) for resampling the data (default: 1, no resampling)
- `upperLimit`: argument passed to [`Eegle.ERPs.reject`](@ref) for artifact rejection (default: 0, no artifact rejection)
- `getTrials`: 
    - if true (default), the `.trials` field of the [`EEG`](@ref) structure is filled with the trials for all classes
    - If it is a vector of class labels (strings), only the trials with those class labels will be stored 
        For example, `getTrials=["left_hand", "right_hand"]` will store only the trials corresponding to "left\\_hand" class label
        and "right\\_hand" class label. The tags corresponding to each class labels will be replaced by natural numbers (1, 2,...) 
        and written in the `.stim` field of the output — see [stimulation vector](@ref)
    - If false, the field `trials` of the returned EEG structure will be set to `nothing`.
- `stdClass`: 
    - if true (default), class labels are standardized according to predefined conventions to facilitate transfer learning
        and model training across heterogeneous databases.
        The standardization applies uniform numerical codes regardless of the original database encoding:
        - **MI paradigm**: "left\\_hand" → 1, "right\\_hand" → 2, "feet" → 3, "rest" → 4, "both\\_hands" → 5, "tongue" → 6
        - **P300 paradigm**: "nontarget" → 1, "target" → 2
        - **ERP paradigm**: not currently supported
    - if false, original class labels and their corresponding numerical values are preserved as found in the database
    The standardization is case-insensitive but requires correct spelling of class names.
    When used with `getTrials` as a vector of class labels, standardization is applied after class selection.
    If class labels are already standardized, the original mapping is preserved.
    Ii is recommended to set `stdClass` to true when all relevant classes are available in your database configuration.
- `msg`: print string `msg` on exit if it is not empty. By default it is empty.

!!! note "Resampling"
    If you use resampling, the new sampling rate will be rounded to the nearest integer.

!!! warning "stim and mark" 
    If the field `offset` of the NY file is different from zero,
    the stimulations in `stim` and markers in `mark` will be shifted to account for the offset - see [stimulation vector](@ref).
    Offset will then be reset to zero. 

**Return** an [`EEG`](@ref) data structure.

**See Also** [`readASCII`](@ref), [`readgTec`](@ref), [`Eegle.ERPs.mark2stim`](@ref), [`Eegle.ERPs.stim2mark`](@ref)

**Examples**
```julia
# Using examples data provided by Eegle
o = readNY(EXAMPLE_P300_1)

# filter the data and do artifact-rejection
# by adaptive amplitude thresholding
o = readNY(EXAMPLE_P300_1; bandPass=(1, 24), upperLimit = 1)

```
xxx
"""
function readNY(filename    :: AbstractString;
                toFloat64   :: Bool = true,
                bandStop    :: Tuple = (),
                bandPass    :: Tuple = (),
                bsDesign    :: DSP.ZeroPoleGain = Butterworth(8),
                bpDesign    :: DSP.ZeroPoleGain = Butterworth(4),
                rate        :: Union{Real, Rational, Int} = 1,
                upperLimit  :: Union{Real, Int} = 0,
                getTrials   :: Union{Bool, Vector{String}} = true, 
                stdClass    :: Bool = true, 
                msg         :: String="")
    # xxx: add a notch filter

  data = npzread(splitext(filename)[1]*".npz") # read data file
  info = YAML.load(open(splitext(filename)[1]*".yml")) # read info file

  sr = info["acquisition"]["samplingrate"]
  if sr-round(Int, sr) ≠ 0 || !(sr isa Int)
    @warn "Eegle.InOut, function `readNY`: the sampling rate is not an integer. It will be rounded to the nearest integer"
    sr=round(Int, sr)
  end

  stim = data["stim"]                # stimulations
  
  paradigm = Symbol(info["id"]["paradigm"]) # June 2025, added for stdClass

  (ns, ne) = size(data["data"])       # of sample, # of electrodes)
  
  os = info["stim"]["offset"]        # offset for trial starting sample

  if os-round(Int, os) ≠ 0 || !(os isa Int)
    @warn "Eegle.InOut, function `readNY`: the offset is not an integer. It will be rounded to the nearest integer"
    os = round(Int, os)
  end

  wl = info["stim"]["windowlength"]  # trial duration
  if wl-round(Int, wl) ≠ 0 || !(wl isa Int)
    @warn "Eegle.InOut, function `readNY`: the trial duration (windowlength) is not an integer. It will be rounded to the nearest integer"
    wl = round(Int, wl)
  end

  # convert to Float64 and band-pass the data if requested
  
  X = nothing
  conversion = eltype(data["data"])≠Float64 && toFloat64
  
  if !isempty(bandStop)
    BSfilter = digitalfilter(Bandstop(first(bandStop)/(sr/2), last(bandStop)/(sr/2)), bsDesign)
    X        = filtfilt(BSfilter, conversion ? Float64.(data["data"]) : data["data"])
  end

  if !isempty(bandPass)
    BPfilter = digitalfilter(Bandpass(first(bandPass)/(sr/2), last(bandPass)/(sr/2)), bpDesign)
    X        = filtfilt(BPfilter, conversion ? Float64.(data["data"]) : data["data"])
  end

  if isempty(bandStop) && isempty(bandPass)
    X = conversion ? Float64.(data["data"]) : data["data"]
  end

  # added Avril-June 2025 to allow loading a file keeping only the chosen classes
  stim = Vector{Int64}(stim);
  nc      = info["stim"]["nclasses"]; 
  labels_dict = sort(collect(info["stim"]["labels"]), by=x->x[2])
  clabels = [pair[1] for pair in labels_dict]
  clabelsval = [pair[2] for pair in labels_dict]

  if getTrials isa Vector # June 2025: getTrials is now a Union :: Bool, Vector{String} (before Vector{Int}) in order to accept classes from Database.jl
    missing_classes = setdiff(getTrials, clabels)
    if !isempty(missing_classes)
        error_msg = "Eegle.InOut, function `readNY`: classes not found: $(join(missing_classes, ", ")). Available classes: $(join(clabels, ", "))"
        throw(ArgumentError(error_msg))
    end

    getTrials_val = Int64[] # memory efficient to declare typeof
    getTrials_val = [clabelsval[findfirst(x -> x == c, clabels)] for c in getTrials] # get stim values corresponding to classes selected in getTrials from clabelsval/clabels

    un = sort(unique(stim))[2:end]
    if isempty(intersect(un, getTrials_val))
        throw(ArgumentError("Eegle.InOut, function `readNY`: the stimulations do not contain the classes requested in getTrials"))
    end
    elimina = setdiff(un, getTrials_val)
    if !isempty(elimina)
        for c ∈ elimina, i ∈ eachindex(stim) stim[i] == c && (stim[i]=0) end
    end

    nc = length(getTrials)
    clabels = [c for c in clabels if c in getTrials]
    clabelsval = [c for c in clabelsval if c in getTrials_val] # needed for stdClass

    if stdClass     # STANDARDIZE classes if stdClass is set to true and getTrials isa Vector
        stim, clabels = _standardizeClasses(paradigm, clabels, clabelsval, stim)
    end
  else
    if stdClass     # STANDARDIZE classes if stdClass is set to true and getTrials isa Bool
        stim, clabels = _standardizeClasses(paradigm, clabels, clabelsval, stim)
    end
  end

  # make sure all stimulations+offset+wl does not exceed the recording duration
  for s ∈ eachindex(stim)
    if stim[s]>0 && s+os+wl-1>size(X, 1)
        stim[s] = 0
        @warn "Eegle.InOut, function `readNY`: the $(s)th stimulation at sample $(stim[s]) with offset $os and trial duration $wl defines a trial exceeding the recording length. The stimulation has been eliminated."
    end
  end

  # resample data if requested
  if rate≠1
    X, stim   = resample(X, sr, rate; stim)
    (ns, ne)  = size(X)
    wl        = round(Int, wl*rate)
    os        = round(Int, os*rate)
    sr        = round(Int, sr*rate) 
  end

  length(unique(stim))-1==nc || @error "Eegle.InOut, function `readNY`: the number of classes in .nc does not correspond to the unique non-zero labels in .stim"

  if upperLimit≠0
      # artefact rejection; change stim and compute mark (it finds the marks using code argument as stim2mark here below)
      stim, rejecstim, mark, rejecmark, rejected =
            reject(X, stim, wl; offset=os, upperLimit=upperLimit)
  else
      # only mark, i.e., samples where the trials start for each class 1, 2,...
      # argument code added 4 Avril 2025 to read MI files with arbitrary label numbers (not just 1, 2, 3...)
      mark = stim2mark(stim, wl; offset=os, code=sort(unique(stim))[2:end]) 
      #mark=[[i+os for i in eachindex(stim) if stim[i]==j && i+os+wl<=ns] for j=1:nc]
  end

  stim = mark2stim(mark, ns); # new stim with offset taken into account 

  if os≠0 # offset reset to 0
    println("✓ Initial offset ($os samples) has been applied and `offset` has been reset to 0")
    os = 0
  end

  length(mark) == nc || @error "Eegle.InOut, function `readNY`: the number of classes in .mark does not correspond to the number of markers found in .stim"

  trials = !(getTrials===false) ? [X[mark[i][j]:mark[i][j]+wl-1, :] for i=1:nc for j=1:length(mark[i])] : nothing

  if !isempty(msg) println(msg) end
  println("$(repeat("═", 65))") # (printing stdClass if true and offset if !=0)
  # this creates the `EEG` structure
  EEG(
     info["id"],
     info["acquisition"],
     info["documentation"],
     info["formatversion"],

     info["id"]["database"],
     paradigm,
     info["id"]["subject"],
     info["id"]["session"],
     info["id"]["run"],
     info["acquisition"]["sensors"],
     sr,
     ne,
     ns,
     wl,
     os, # trials offset
     nc,
     #collect(keys(info["stim"]["labels"])), # clabels
     clabels,
     stim,
     mark,
     [i for i=1:nc for j=1:length(mark[i])], # y: all labels
     X, # whole EEG recording
     trials # all trials, by class, if requested, nothing otherwise
  )
end

## #######################  g.Tec HDF5 files ############################## ##

# Parse one-string XML files.
# If `verbose` is true (default) the file is shown in the REPL
function _parseXML(xmlStringVector::String; verbose::Bool=true)
      doc = EzXML._parseXML(xmlStringVector)
      verbose && print(doc)
      return doc
end

"""
```julia
    function readgTec(fileName::AbstractString;
        dataType::Type = Float32,
        writeMetaDataFiles::Bool = true,
        verbose::Bool = true,
        skipFirstSamples::Int = 0,
        chRange::Union{UnitRange, Symbol} = :All)

```
Read an EEG data file saved in HDF5 format by the [g.Tec g.Recorder software](https://www.gtec.at/product/g-recorder/?srsltid=AfmBOorZgVDJBTE81uhRRZNpSFaL8xjYWgBHteW3M2Yb60YKu54jZ_lu).

**Arguments**
- `fileName`: the complete path of the *.hdf5* file to be read.

**Optional Keyword Arguments**
- `dataType`: Float32 by default. Can be Float64.
- `writeMetaDataFiles`: true by default. All metadata files will be
    saved as *.xml* or *.txt* files, in the same director where `filename` is
    with the same name to which a suffix indicating the type of metadata
    will be appended.
    If `writeMetaDataFiles` is true and `verbose` is true (default),
    the metadata will be shown in the REPL.
- `skipFirstSamples`: if greater than 0 (default), this number of samples
    at the beginning of the file will not be read. 
- `chRange`: if a unit range is provided (e.g., 1:10), only this range of channels
    will be read. All channels are read by default.

**Return**

The EEG data as a ``T×N`` matrix, where ``T`` and ``N`` denotes the number of 
samples and channels, respectively.

**See Also** [`readASCII`](@ref), [`readNY`](@ref)

**Examples**

xxx
"""
function readgTec(fileName::AbstractString;
                    dataType::Type=Float32,
                    writeMetaDataFiles::Bool=true,
                    verbose::Bool=true,
                    skipFirstSamples::Int=0,
                    chRange::Union{UnitRange, Symbol}=:All)

    fid = h5open(fileName, "r")
        if writeMetaDataFiles
              write(splitext(fileName)[1]*"_acqXML.xml", _parseXML(read(fid["RawData/AcquisitionTaskDescription"])[1], verbose=verbose))
              write(splitext(fileName)[1]*"_chProp.xml", _parseXML(read(fid["RawData/DAQDeviceCapabilities"])[1], verbose=verbose))
              write(splitext(fileName)[1]*"_chUnits.xml", _parseXML(read(fid["RawData/DAQDeviceDescription"])[1], verbose=verbose))
              write(splitext(fileName)[1]*"_sessDescr.xml", _parseXML(read(fid["RawData/SessionDescription"])[1], verbose=verbose))
              write(splitext(fileName)[1]*"_subjDescr.xml", _parseXML(read(fid["RawData/SubjectDescription"])[1], verbose=verbose))
              write(splitext(fileName)[1]*"_triggers.xml", _parseXML(read(fid["AsynchronData/AsynchronSignalTypes"])[1], verbose=verbose))
              verbose && println("features: ", read(fid["SavedFeatues/NumberOfFeatures"]))
              writeVector(read(fid["SavedFeatues/NumberOfFeatures"]), splitext(fileName)[1]*"_features.txt"; overwrite=true)
              verbose && println("version: ", read(fid["Version/Version"])[1])
              writeVector(read(fid["Version/Version"]), splitext(fileName)[1]*"_version.txt"; overwrite=true)
        end
        # convert data to Float64 and transpose
        data=Matrix(Array{dataType, 2}(read(fid["RawData/Samples"]))')
        println("\nHere we go...")
        println("# Channels: ", chRange==:All ? size(data, 2) : length(chRange))
        println("# Samples: ", size(data, 1)-skipFirstSamples)
    close(fid)

    return chRange==:All ? data[1+skipFirstSamples:end, :] : data[1+skipFirstSamples:end, chRange]
end


"""
```julia
(1) function readASCII(fileName::AbstractString; 
        msg::String="")

(2) readASCII(  fileNames::Vector{String}, 
                skip::Vector{Int}=[])        
```
Read EEG data from one file (method 1) or several files (method 2) in [LORETA-Key](https://www.uzh.ch/keyinst/NewLORETA/Software/Software.htm) 
format. The format is a space- or tab-delimited ASCII file, usually with extension *.txt*, holding a matrix of data with ``N`` columns and ``T`` rows, 
denoting the number of channels and samples, respectively. 

(1) `fileName` is the full path to the ASCII file. 

- If [kwarg](@ref "Acronyms") `msg` is not empty, print `msg` on exit.

(2) `fileNames` is a vector of the full paths to the ASCII files. 

- If kwarg `skip` is a vector of indices (integers), skip the files with these indices (empty by default).

**Return**

(1) The EEG data as a ``T×N`` matrix, where ``T`` and ``N`` denote the number of 
samples and channels, respectively.

(2) A vector of matrices as in (1).

**See Also** [`writeASCII`](@ref), [`readgTec`](@ref), [`readNY`](@ref)

"""
function readASCII(fileName::AbstractString; msg::String="")
    if !isfile(fileName)
        @error "function `readASCII`: file not found" fileName
        return nothing
    end

    S = readlines(fileName) # read the lines of the file as a vector of strings
    filter!(!isempty, S)
    t = length(S) # number of samples
    n = length(split(S[1])) # get the number of electrodes
    X = Matrix{Float64}(undef, t, n) # declare the X Matrix
    for j=1:t
        x=split(S[j]) # this get the n potentials from a string
        for i=1:n
            X[j, i]=parse(Float64, replace(x[i], "," => "."))
        end
    end
    if !isempty(msg) println(msg) end
    return X
end

# Read several EEG data from .txt files in LORETA format given in `filenames`
# (a Vector of strings) and put them in a vector of matrices object.
# `skip` is an optional vector of serial numbers of files in `filenames` to skip.
# print: "read file "*[filenumber]*": "*[filename] after each file has been read.
function readASCII(fileNames::Vector{String}, skip::Vector{Int}=[])
        X = [readASCII(fileNames[f]; msg="read file $f: "*basename(fileNames[f])) for f in eachindex(fileNames) if f ∉ skip]
        !isempty(skip) && println("skypped files: ", skip)
        return X
end

"""
```julia
    function readSensors(fileName::String; 
        hasHeader::Bool=true)
```
Read a list of EEG sensor labels from ASCII file `fileName`.
The file has one label per line.

If `hasHeader` is true (default), the first line is the number of labels.

An example file looks like the trasnpose of this:

3
Fz
Pz
Cz

**Examples**
```julia
sensors = readSensors(fileName)
```
"""
function readSensors(fileName::String; hasHeader::Bool=true)
    ℹ = ": Eegle.InOut, function `readSensors`: "
    !isfile(fileName) && throw(ArgumentError(ℹ*"`fileName` file not found: "*fileName))
    sensors=readlines(fileName)
    hasHeader && popfirst!(sensors) ## sensor number in first line
    return sensors
end
   

"""
```julia
(1) function writeASCII(X::Matrix{T}, 
                        fileName::String;
        samplesRange::UnitRange = 1:size(X, 1),
        overwrite::Bool = false,
        digits = 6,
        msg::String = "") 
    where T <: Real

(2) function writeASCII(X::Matrix{S}, 
                        fileName::S;
        overwrite::Bool = false,
        msg::S = "") 
    where S <: String

(3) function writeASCII(v::Vector{S}, 
                        fileName::S;
        samplesRange::UnitRange = 1:size(v, 1),
        overwrite::Bool = false,
        oneline::Bool = false,
        msg::S = "")
    where S <: String
```    
(1)

Write a data matrix `X` into an ASCII text file that can be read by [`readASCII`](@ref).

**Arguments**
- `X`: a Julia matrix of real numbers.
- `fileName`: the full path of the file to be saved, usually with extension *.txt*.

**Optional Keyword Arguments**
- `samplesRange`: the unit range of rows of `X` (samples for ASCII EEG data files) to be written. Default: `1:T`
- `overwrite`: if false (default), return an error if `fileName` is an existing file
- `digits`: the number of decimal digits written for each value. Default: 6
- `msg`: print string `msg` on exit if it is not empty (empty by default).

If you need to remove columns of `X` before writing, see [`Eegle.Miscellaneous.remove`](@ref) or [`removeChannels`](@ref).

(2)

Write a matrix of strings into an ASCII file.

**Arguments**
- `X`: the matrix of string to be written
- `fileName`: as in (1).

**Optional Keyword Arguments**
- `overwrite` and `msg`: as in (1).

(3)

Write a vector of strings into an ASCII text file.

**Arguments**
- `v`: the vector of string to be written
- `fileName`: as in (1).

**Optional Keyword Arguments**

- `samplesRange`: a unit range of elements of `v` to be written (all elements by default)
- `overwrite` and `msg`: as in (1)
- `oneline`: 
    - if true, write all elements in the first line delimiting them by a space
    - if false (default), write one element per line.

!!! tip "End of line"
    All methods include character "\\r\\n" (ASCII end of line and carriage return) at the end of each line.
    Visualizing these files properly with a standard text editor may require some care on Linux.

**Examples**

xxx
"""
function writeASCII(X::Matrix{T}, fileName::String;
    samplesRange::UnitRange = 1:size(X, 1),
    overwrite::Bool=false,
    digits = 6,
    msg::String = "") where T <: Real

    if isfile(fileName) && !overwrite
        @error "writeASCII function: `filename` already exists. Use argument `overwrite` if you want to overwrite it."
    else
        io = open(fileName, "w")
        write(io, replace(chop(string(round.(X[samplesRange, :]; digits=digits)); head=1, tail=1), ";" =>"\r\n" ))
        close(io)
        if !isempty(msg) println(msg) end
    end
end


function writeASCII(X::Matrix{S}, fileName::S;
    overwrite::Bool = false,
    msg::S = "") where S <: String

    if isfile(fileName) && !overwrite
        @error "writeASCII function: `filename` already exists. Use argument `overwrite` if you want to overwrite it."
    else
        io = open(fileName, "w")
        for i=1:size(X, 1)
            for j=1:size(X, 2)
                write(io, X[i, j])
                write(io, " ")
            end
            write(io, "\r\n")
        end
        close(io)
        if !isempty(msg) println(msg) end
    end
end

function writeASCII(v::Vector{S}, fileName::S;
    samplesRange::UnitRange = 1:size(v, 1),
    overwrite::Bool = false,
    oneline::Bool = false,
    msg::S = "") where S <: String

    if isfile(fileName) && !overwrite
        @error "writeASCII function: `filename` already exists. Use argument `overwrite` if you want to overwrite it."
    else
        delimiter = oneline ? " " : "\r\n"
        io = open(fileName, "w")
        for str in v[samplesRange]
            write(io, str, delimiter) 
        end
        close(io)
        if !isempty(msg) println(msg) end
    end
end


######################################

mean(o::EEG;
    overlapping :: Bool = false,
    offset      :: S = 0,
    weights     :: Union{Vector{Vector{R}}, Symbol} = :none,
    mark        :: Union{Vector{Vector{S}}, Nothing} = nothing) where {R<:Real, S<:Int} =
        mean(o.X, o.wl, isnothing(mark) ? o.mark : mark;
            overlapping = overlapping, offset = offset, weights = weights)



# overwrite the Base.show function to nicely print information
# about the sturcure in the REPL
# ++++++++++++++++++++  Show override  +++++++++++++++++++ # (REPL output)
function Base.show(io::IO, ::MIME{Symbol("text/plain")}, o::EEG)
    r, c=size(o.X)
    type=eltype(o.X)
    l=length(o.stim)
    println(io, titleFont, "∿ EEG Data type; $r x $c ")
    println(io, separatorFont, "∼∽∿∽∽∽∿∼∿∽∿∽∿∿∿∼∼∽∿∼∽∽∿∼∽∽∼∿∼∿∿∽∿∽∼∽∽∿∽∽", greyFont)
    println(io, "NY format version (.formatversion): $(o.formatversion)")
    println(io, separatorFont, "∼∽∿∽∽∽∿∼∿∽∿∽∿∿∿∼∼∽∿∼∽∽∿∼∽∽∼∿∼∿∿∽∿∽∼∽∽∿∽∽", defaultFont)
    println(io, ".db (database)   : $(o.db)")
    println(io, ".paradigm        : $(":"*String(o.paradigm))")    
    println(io, ".subject         : $(o.subject)")
    println(io, ".session         : $(o.session)")
    println(io, ".run             : $(o.run)")
    println(io, ".sensors         : $(length(o.sensors))-Vector{String}")
    println(io, ".sr(samp. rate)  : $(o.sr)")
    println(io, ".ne(# electrodes): $(o.ne)")
    println(io, ".ns(# samples)   : $(o.ns)")
    println(io, ".wl(win. length) : $(o.wl)")
    println(io, ".offset          : $(o.offset)")
    println(io, ".nc(# classes)   : $(o.nc)")
    println(io, ".clabels(c=class): $(length(o.clabels))-Vector{String}")
    println(io, ".stim(ulations)  : $(length(o.stim))-Vector{Int}")
    println(io, ".mark(ers) : $([length(o.mark[i]) for i=1:length(o.mark)])-Vectors{Int}")
    println(io, ".y (all c labels): $(length(o.y))-Vector{Int}")
    println(io, ".X (EEG data)    : $(r)x$(c)-Matrix{$(type)}")
    isnothing(o.trials) ? println("                : nothing") :
                        println(io, ".trials          : $(length(o.trials))-Vector{Matrix{$(type)}}")
    println(io, "Dict: .id, .acquisition, .documentation")
    r≠l && @warn "number of class labels in y does not match the data size in X" l r
end


end # module

# Example
# dir="C:\\Users\\congedom\\Documents\\My Data\\EEG data\\NTE 84 Norms"

# Gat all file names with complete path
# S=getFilesInDir(dir) # in FileSystem.jl

# Gat all file names with complete path with extension ".txt"
# S=getFilesInDir(@__DIR__; ext=(".txt", ))

# read one file of NTE database and put it in a Matrix object
# X=readASCII(S[1])

# read all files of NTE database and put them in a vector of matrix
# 𝐗=readASCII(S)
