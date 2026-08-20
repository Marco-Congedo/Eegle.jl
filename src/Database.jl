module Database

using NPZ
using YAML
using HDF5
using EzXML
using DataFrames

import Eegle

# code for the GUI to download the FII BCI Corpus (called by `DownloadDB`)
include(joinpath("GUIs", "downloadDB", "DB_download_interface.jl"))

# Module REPL text colors
const titleFont     = "\x1b[95m"
const separatorFont = "\x1b[35m"
const defaultFont   = "\x1b[0m"
const greyFont      = "\x1b[90m"

export
    InfoDB,
    loadDB, 
    infoDB,
    selectDB,
    weightsDB,
    downloadDB


"""
```julia
struct InfoDB
    dbName              :: String
    condition           :: String
    paradigm            :: String
    files               :: Vector{String}
    nSessions           :: Vector{Int}
    nTrials             :: Dict{String, Vector{Int}}
    nSubjects           :: Int
    nSensors            :: Int
    sensors             :: Vector{String}
    sensorType          :: String
    nClasses            :: Int
    cLabels             :: Vector{String}
    sr                  :: Int
    wl                  :: Int
    offset              :: Int
    filter              :: String
    doi                 :: String
    hardware            :: String
    software            :: String
    reference           :: String
    ground              :: String
    place               :: String
    investigators       :: String
    repository          :: String
    description         :: String
    timestamp           :: Int
    formatVersion       :: String
end
```
Immutable structure holding the summary information and metadata of an EEG database (DB) in [NY format](@ref).

It is created by functions [infoDB](@ref) and [`selectDB`](@ref).

**Fields**

- `.files` returns a list of *.npz* files, each corresponding to a [session](@ref) in the database. The length of `.files` is equal to the total number of sessions
- `.nSessions`: vector holding the number of sessions per subject
- `.nTrials`: a dictionary mapping each class label to a vector containing the number of trials per session for that class. For example, `nTrials["left_hand"]` returns a vector with the number of trials for `"left_hand"` across all sessions.

The following fields are assumed constant across all sessions of the database.
This is checked by **Eegle** when a database is read.

- `.dbName`: name or identifier of the [database](@ref)
- `.condition`: experimental condition under which the DB has been recorded
- `.paradigm`: for BCI data, this may be :P300, :ERP or :MI — see [BCI paradigm](@ref)
- `.nSubjects`: total number of subjects composing the DB — see [subject](@ref)
- `.nSensors`: number of sensors composing the recordings (e.g., EEG electrodes)
- `.sensors`: list of sensor labels (e.g., [Fz, Cz, ...,Oz])
- `.sensorType`: type of sensors (wet, dry, Ag/Cl, ...)
- `.nClasses`: number of classes for which labels are available
- `.cLabels`: list of class labels
- `.sr`: sampling rate of the recordings (in samples)
- `.wl`: for BCI, this is the duration of trials (in samples)
- `.offset`: shift to be applied to markers in order to determine the trial onset (in samples)
- `.filter`: temporal filter that has been applied to the data
- `.hardware`: equipment used to obtain the recordings (typically, the EEG amplifier)
- `.software`: software used to obtain the recordings
- `.reference`: label of the reference electrode for EEG differential amplifiers
- `.ground`: label of the electrical ground electrode
- `.doi`: digital object identifier (DOI) of the database
- `.place`: place where the recordings have been obtained
- `.investigators`: investigator(s) that have obtained the recordings
- `.repository`: public repository where the DB has made accessible
- `.description`: general description of the DB
- `.timestamp`: date of the publication of the DB
- `.formatVersion`: version of the [NY format](@ref) in which the recordings have been stored.
"""
struct InfoDB
    dbName              :: String                           # database name
    condition           :: String                           # experimental condition
    paradigm            :: String                           # experimental paradigm (MI, P300, etc.)
    files               :: Vector{String}                   # database's files 
    nSessions           :: Vector{Int}                      # sessions per subject 
    nTrials             :: Dict{String, Vector{Int}}        # trials per class per session (class_name => [trialspersession])
    nSubjects           :: Int                              # total number of subjects
    nSensors            :: Int                              # number of electrodes
    sensors             :: Vector{String}                   # name of sensors (Fz, Cz, etc.)
    sensorType          :: String                           # type of sensors (EEG, etc.)
    nClasses            :: Int                              # number of classes
    cLabels             :: Vector{String}                   # class labels
    sr                  :: Int                              # sampling rate
    wl                  :: Int                              # trial duration (in samples)
    offset              :: Int                              # trial offset (in samples)
    filter              :: String                           # filter applied on data
    hardware            :: String                           # hardware used for the experiment
    software            :: String                           # software used for the experiment
    reference           :: String                           # reference electrode
    ground              :: String                           # ground electrode
    doi                 :: String                           # doi
    place               :: String                           # place of experiment
    investigators       :: String                           # investigators of experiment
    repository          :: String                           # database repository
    description         :: String                           # database description
    timestamp           :: Int                              # date of publication
    formatVersion       :: String                           # formatversion
end

"""
```julia
function loadDB(dbDir=AbstractString, isin::String="")
```
Return a list of the complete paths of all *.npz* files found in a directory given as argument `dbDir`.
Such a directory is a [database](@ref) in [NY format](@ref), thus, for each *NPZ* file 
there must be a corresponding *YAML* metadata file with the same name and extension *.yml*, otherwise
the file is not included in the list.

If a string is provided as kwarg `isin`, only the files whose name
contains the string will be included. 

**See Also** 

[`selectDB`](@ref), [`infoDB`](@ref), [`FileSystem.getFilesInDir`](@ref)

**Examples**
See the first example of [`weightsDB`](@ref)
"""
function loadDB(dbDir=AbstractString, isin::String="")
  # create a list of all .npz files found in dbDir (complete path)
  npzFiles=Eegle.FileSystem.getFilesInDir(dbDir; ext=(".npz", ), isin=isin)

  # check if for each .npz file there is a corresponding .yml file
  missingYML=[i for i ∈ eachindex(npzFiles) if !isfile(splitext(npzFiles[i])[1]*".yml")]
  if !isempty(missingYML)
    @warn "Eegle.Database, function `loadDB`: the following .yml files have not been found:\n"
    for i ∈ missingYML 
        println(splitext(npzFiles[i])[1]*".yml") 
    end
    deleteat!(npzFiles, missingYML)
    println("\n $(length(npzFiles)) files have been retained.")
  end
  return npzFiles
end

"""
```julia
function infoDB(dbDir)
```
Create a [InfoDB](@ref) structure and show it in Julia's REPL.

The only argument (`dbDir`) is the directory holding all files of a [database](@ref) in [NY format](@ref).

This function carry out a sanity checks on the database and prints warnings if the checks fail.

**See Also** 

[`selectDB`](@ref), [`loadDB`](@ref)

**Examples**
```julia
db = infoDB(dbDir)
```
"""
function infoDB(dbDir)

    files = loadDB(dbDir)

    # make sure only .npz files have been passed in the list `files`
    for (i, f) ∈ enumerate(files)
        splitext(f)[2]≠".npz" && deleteat!(files, i)
    end
    length(files)==0 && error("Eegle.Database, function `infoDB`: there are no .npz files in the list of files passed as argument")

    # read one YAML file to find out the type of dictionary values
    filename = files[1]
    isfile(splitext(filename)[1]*".yml") || error("Eegle.Database, function `infoDB`: no .yml (recording info) file has been found for npz file \n:", filename)
    info = YAML.load(open(splitext(filename)[1]*".yml")) # read info file

    # get memory for all entries of the YAML dictionary for all files
    # knowing the type of the values is much more memory-efficient
    sensors             = typeof(info["acquisition"]["sensors"])[]
    sensorType          = typeof(info["acquisition"]["sensortype"])[]
    ground              = typeof(info["acquisition"]["ground"])[]
    reference           = typeof(info["acquisition"]["reference"])[]
    filter              = typeof(info["acquisition"]["filter"])[]
    sr                  = typeof(info["acquisition"]["samplingrate"])[]
    hardware            = typeof(info["acquisition"]["hardware"])[]
    software            = typeof(info["acquisition"]["software"])[]

    wl                  = typeof(info["stim"]["windowlength"])[]
    labels              = typeof(info["stim"]["labels"])[]
    offset              = typeof(info["stim"]["offset"])[]
    nClasses            = typeof(info["stim"]["nclasses"])[]
    nTrials             = typeof(info["stim"]["trialsperclass"])[]

    timestamp           = typeof(info["id"]["timestamp"])[]
    run                 = typeof(info["id"]["run"])[]
    condition           = typeof(info["id"]["condition"])[]
    dbName              = typeof(info["id"]["database"])[]
    paradigm            = typeof(info["id"]["paradigm"])[]
    subject             = typeof(info["id"]["subject"])[]
    session             = typeof(info["id"]["session"])[]

    place               = typeof(info["documentation"]["place"])[]
    investigators       = typeof(info["documentation"]["investigators"])[]
    doi                 = typeof(info["documentation"]["doi"])[]
    repository          = typeof(info["documentation"]["repository"])[]
    description         = typeof(info["documentation"]["description"])[]

    formatversion       = typeof(info["formatversion"])[]

    for (f, filename) ∈ enumerate(files)

        isfile(splitext(filename)[1]*".yml") || error("Eegle.Database, function `infoDB`: no .yml (recording meta-data) file has been found for npz file \n:", filename)
        info = YAML.load(open(splitext(filename)[1]*".yml"))

        acq = info["acquisition"]
        push!(sensors, acq["sensors"])
        push!(ground, acq["ground"])
        push!(reference, acq["reference"])
        push!(filter, acq["filter"])
        push!(sensorType, acq["sensortype"])
        push!(sr, acq["samplingrate"])
        push!(hardware, acq["hardware"])
        push!(software, acq["software"])

        stim = info["stim"]
        push!(wl, stim["windowlength"])
        push!(labels, stim["labels"])
        push!(offset, stim["offset"])
        push!(nClasses, stim["nclasses"])
        push!(nTrials, stim["trialsperclass"])

        id = info["id"]
        push!(timestamp, id["timestamp"])
        push!(run, id["run"])
        push!(condition, id["condition"])
        push!(dbName, id["database"])
        push!(paradigm, id["paradigm"])
        push!(subject, id["subject"])
        push!(session, id["session"])

        doc = info["documentation"]
        push!(place, doc["place"])
        push!(investigators, doc["investigators"])
        push!(doi, doc["doi"])
        push!(repository, doc["repository"])
        push!(description, doc["description"])

        push!(formatversion, info["formatversion"])
    end

    nwarnings = 0
    function mywarn(text::String)
        nwarnings += 1
        @warn "Eegle.Database, function `infoDB`: $text"
    end
   
    # Check critical field consistency (warn if not unique)
    length(unique(paradigm)) > 1 && mywarn("Paradigm is not unique across the database")
    length(unique(nClasses)) > 1 && mywarn("Number of classes is not unique across the database")
    length(unique(labels)) > 1 && mywarn("Class labels are not unique across the database")
    length(unique(sr)) > 1 && mywarn("Sampling rate is not unique across the database")
    length(unique(wl)) > 1 && mywarn("Trial duration (windowlength) is not unique across the database")
    length(unique(offset)) > 1 && mywarn("Trial offset is not unique across the database")

    # CRITICAL ERROR CHECK: unicity of triplets (subject, session, run)
    ssr = Tuple[]
    for (i, j, l) ∈ zip(subject, session, run) push!(ssr, (i, j, l)) end
    length(unique(ssr)) < length(subject) && error("Eegle.Database, function `infoDB`:: there are duplicated triplets (subject, session, run)")

    # CRITICAL ERROR CHECK: session count consistency
    usub = unique(subject)
    sess = [sum(ss==s for ss∈subject) for s∈usub] # sessions per subject
    sum(sess) ≠ length(files) && error("Eegle.Database, function `infoDB`: the number of sessions does not match the number of files in database")

    # Warning about run field inconsistency
    length(unique(run)) > 1 && mywarn("field `run` should be considered the number of runs and should be the same in all recordings. In any case this field is not used")

    if nwarnings > 0
        println(separatorFont, "\n⚠ Be careful, $nwarnings warnings have been found", defaultFont)
    end

    # Create InfoDB structure
    # Extract main information
    db_dbName = unique(dbName)[1]
    db_condition = unique(condition)[1]
    db_paradigm = unique(paradigm)[1]
    db_files = files
    db_nSubjects = length(unique(subject))
    db_nSessions = sess
    db_nSensors = length(unique(sensors)[1])
    db_sensors = unique(sensors)[1]
    db_sensorType = unique(sensorType)[1]  
    db_nClasses = unique(nClasses)[1]
    db_sr = unique(sr)[1]
    db_wl = unique(wl)[1]
    db_offset = unique(offset)[1]
    db_filter = unique(filter)[1]
    db_doi = unique(doi)[1]
    db_hardware = unique(hardware)[1]
    db_software = unique(software)[1]
    db_reference = unique(reference)[1]
    db_ground = unique(ground)[1]
    db_place = unique(place)[1]
    db_investigators = unique(investigators)[1]
    db_repository = unique(repository)[1]
    db_description = unique(description)[1]
    db_timestamp = unique(timestamp)[1]
    db_formatVersion = unique(formatversion)[1]

    # Extract class labels in correct order (sorted by stim values)
    all_labels = unique(labels)[1]
    sorted_labels = sort(collect(all_labels), by = x -> x[2])  # sort by values
    db_cLabels = [label[1] for label in sorted_labels]  # extract keys in sorted order
   
    # extract trials per class per session 
    db_nTrials = Dict{String, Vector{Int}}() 

    # For each class, collect trials per session
    for class_name in db_cLabels
        trials = Int[]
        for trial_dict in nTrials
            if haskey(trial_dict, class_name)
                push!(trials, trial_dict[class_name])
            else
                push!(trials, 0)  # no trials for this class in this session
            end
        end
        db_nTrials[class_name] = trials
    end

    # Create and return InfoDB structure (will be displayed automatically via Base.show)
    return InfoDB(
        db_dbName,
        db_condition,  
        db_paradigm,
        db_files,
        db_nSessions,
        db_nTrials,
        db_nSubjects,
        db_nSensors,
        db_sensors,
        db_sensorType,    
        db_nClasses,
        db_cLabels,
        db_sr,
        db_wl,
        db_offset,
        db_filter,
        db_hardware,
        db_software,
        db_reference,
        db_ground,
        db_doi,
        db_place,
        db_investigators,
        db_repository,
        db_description,
        db_timestamp,
        db_formatVersion
    )
end

#=
_getNestedValue(data::Dict, path::String)

Extract value from nested dictionary using dot-separated path.
Supports shortcuts for common paths and automatic nested search.

**Shortcuts:**
- `sr` → `acquisition.samplingrate`
- `ref` → `acquisition.reference`
- `tpc` → `stim.trialsperclass`
- `perfLHRH` → `perf.left_hand-right_hand`
- `perfRHF` → `perf.right_hand-feet`
=#
function _getNestedValue(data::Dict, path::String)
    # Define shortcuts mapping
    shortcuts = Dict(
        "sr"        => "acquisition.samplingrate",
        "ref"       => "acquisition.reference",
        "tpc"       => "stim.trialsperclass",
        "perfLHRH"  => "perf.left_hand-right_hand",
        "perfRHF"   => "perf.right_hand-feet"
    )
    
    # Replace shortcuts if applicable
    resolved_path = get(shortcuts, path, path)
    
    # Check if path contains shortcut at start (e.g., "perfLHRH.MDM")
    for (shortcut, full_path) in shortcuts
        if startswith(path, shortcut * ".")
            resolved_path = replace(path, shortcut => full_path, count=1)
            break
        end
    end
    
    keys_path = split(resolved_path, '.')
    
    # Single key: direct access or recursive search
    if length(keys_path) == 1
        key = keys_path[1]
        haskey(data, key) && return data[key]
        
        # Recursive search in nested dictionaries
        for v in values(data)
            v isa Dict && haskey(v, key) && return v[key]
        end
        
        throw(ErrorException("Key '$key' not found in YAML (searched at root and nested levels)"))
    end
    
    # Navigate nested structure with dot notation
    current = data
    for key in keys_path
        haskey(current, key) || throw(ErrorException("Key '$key' not found in path '$resolved_path'"))
        current = current[key]
    end
    
    return current
end

# Helper function to extract all numeric values from nested perf dictionary
function _getAllPerfValues(perf_dict::Dict)
    return vcat([v isa Number ? Float64(v) : v isa Dict ? _getAllPerfValues(v) : Float64[] 
                 for v in values(perf_dict)]...)
end

# make string case insensitive
struct CIVec; data::Vector{String}; end
Base.length(v::CIVec)           = length(v.data)
Base.iterate(v::CIVec, s...)    = iterate(v.data, s...)
Base.in(x::String, v::CIVec)   = any(s -> lowercase(s) == lowercase(x), v.data)

#=
_filter(files::Vector{String}, 
        inclusion::Union{Tuple, Nothing};
        verbose::Bool=false)

Internal function to filter session files based on YAML metadata criteria.

This function allows filtering on virtually any field present in the YAML files,
as long as it's not a unique identifier for a single session.

**Arguments**
- `files`: Vector of .npz file paths (each has corresponding .yml)
- `inclusion`: Tuple of (field_path, predicate) conditions
- `verbose`: If true, print detailed filtering info

**Returns**
- `valid_indices`: Indices of files passing all filters
- `excluded_files_info`: Vector of (filename, reason) tuples

**Filter Syntax Extensive Examples**

**Path Notation**
```julia
# Shortcut notation (recommended for common paths)
inclusion = (("sr", ==(256)),)                    # acquisition.samplingrate
inclusion = (("ref", ==("Fz")),)                  # acquisition.reference
inclusion = (("perfLHRH.MDM", x -> x >= 0.7),)   # perf.left_hand-right_hand.MDM
# Short form (automatic nested search)
inclusion = (("samplingrate", ==(256)),)          # Searches nested dicts
# Explicit dot notation
inclusion = (("acquisition.samplingrate", ==(256)),)  # Direct path
# Deep nesting
inclusion = (("perf.left_hand-right_hand.MDM", x -> x >= 0.7),)
```

# Available Shortcuts:
- `sr` → `acquisition.samplingrate`
- `ref` → `acquisition.reference`
- `tpc` → `stim.trialsperclass`
- `perfLHRH` → `perf.left_hand-right_hand`
- `perfRHF` → `perf.right_hand-feet`

**Basic Filters (Exact Match)**
```julia
# Sampling rate exactly 256 Hz (using shortcut)
inclusion = (("sr", ==(256)),)
# Specific reference (using shortcut)
inclusion = (("ref", ==("Fz")),)  
# Specific hardware
inclusion = (("hardware", ==("g.tec EEG - g.USBamp")),)
```

**Comparison Filters (>, <, >=, <=)**

# Sampling rate at least 128 Hz
inclusion = (("sr", x -> x >= 128),)
# Balanced accuracy at least 60% (using shortcut)
inclusion = (("perfLHRH.MDM", x -> x >= 0.6),)
# Window length greater than 500 samples
inclusion = (("windowlength", x -> x > 500),)


**Range Filters (Interval)**

# Sampling rate between 128 and 512 Hz
inclusion = (("sr", x -> 128 <= x <= 512),)
# Balanced accuracy between 60% and 80%
inclusion = (("perfLHRH.MDM", x -> 0.6 <= x <= 0.8),)
# Window length between 100 and 800 samples
inclusion = (("windowlength", x -> 100 <= x <= 800),)

**Array/Vector Filters**

# Must contain electrode Fz
inclusion = (("acquisition.sensors", x -> "Fz" ∈ x),)
# Must contain multiple electrodes
inclusion = (("acquisition.sensors", x -> all(e ∈ x for e in ["Fz", "Cz", "Pz"])),)
# At least 16 electrodes
inclusion = (("acquisition.sensors", x -> length(x) >= 16),)
# Specific number of electrodes
inclusion = (("acquisition.sensors", x -> length(x) == 64),)

**Dictionary Filters (trialsperclass, labels, perf)**

# Minimum trials across all classes > 30
inclusion = (("trialsperclass", x -> minimum(values(x)) > 30),)
# Specific class has enough trials
inclusion = (("trialsperclass", x -> haskey(x, "left_hand") && x["left_hand"] >= 50),)
# Total trials across all classes >= 200
inclusion = (("trialsperclass", x -> sum(values(x)) >= 200),)
# Performance metrics for specific task and classifier (using shortcuts)
inclusion = (("perfLHRH.MDM", x -> x >= 0.7),)    # MI
inclusion = (("perf.ENLR", x -> x >= 0.7),)       # P300

**String Filters**

# Specific reference (using shortcut)
inclusion = (("ref", ==("Fz")),)
# Reference is not N/A
inclusion = (("ref", !=("N/A")),)
# Filter contains keyword (case-sensitive)
inclusion = (("filter", x -> occursin("Butterworth", x)),)
# Specific sensor type
inclusion = (("sensortype", x -> occursin("Wet", x)),)

**Combined Filters (Multiple Conditions - AND Logic)**

# Sampling rate + specific electrodes + good performance
inclusion = (
    ("sr", x -> x >= 256),
    ("acquisition.sensors", x -> "Fz" ∈ x),
    ("perfLHRH.MDM", x -> 0.6 <= x <= 0.85)
)
# Sufficient trials + specific reference
inclusion = (
    ("trialsperclass", x -> minimum(values(x)) >= 40),
    ("ref", !=("N/A"))
)
# Sampling rate + electrode count + trial count
inclusion = (
    ("sr", x -> 128 <= x <= 512),
    ("acquisition.sensors", x -> length(x) >= 16),
    ("trialsperclass", x -> sum(values(x)) >= 150)
)
=#
function _filter(files::Vector{String}, 
                 inclusion::Union{Tuple, Nothing};
                 verbose::Bool=false,
                 show_progress::Bool=false)  
    
    # Early return if no filters
    (isnothing(inclusion) || isempty(inclusion)) && return collect(1:length(files)), Tuple{String, String, Bool}[]
    
    # Pre-allocate with estimated capacity
    n_files = length(files)
    valid_indices = sizehint!(Int[], n_files)
    files_info = sizehint!(Tuple{String, String, Bool}[], n_files)
    
    # Define shortcuts once outside loop
    shortcuts = Dict("sr" => "acquisition.samplingrate", "ref" => "acquisition.reference", 
                     "perfLHRH" => "perf.left_hand-right_hand", "perfRHF" => "perf.right_hand-feet")
    
    # Detect perf filters once
    perf_filters_present = any(fp -> startswith(fp, "perf") || startswith(get(shortcuts, fp, ""), "perf"), 
                               (fp for (fp, _) in inclusion))
    
    show_progress && println("\n$(repeat("─", 65))\n🔍 Applying $(length(inclusion)) filter(s) to $n_files session(s)...")
    
    @inbounds for (file_idx, file_path) in enumerate(files)
        yml_path = splitext(file_path)[1] * ".yml"
        
        # Check YAML existence
        if !isfile(yml_path)
            push!(files_info, (file_path, "Missing YAML file", false))
            show_progress && println("  ✗ $(basename(file_path)): Missing YAML file")
            continue
        end
        
        yaml_data = YAML.load(open(yml_path))
        
        # Auto-reject files without perf section or with perf ∈ [0, 0.2] when perf filter is used
        if perf_filters_present
            if !haskey(yaml_data, "perf")
                push!(files_info, (file_path, "Auto-rejected: no 'perf' section in YAML", false))
                show_progress && println("  ✗ $(basename(file_path)): Auto-rejected: no 'perf' section")
                continue
            end
            
            perf_values = _getAllPerfValues(yaml_data["perf"])
            if all(v -> 0 ≤ v ≤ 0.2, perf_values)
                push!(files_info, (file_path, "Auto-rejected: all perf values ∈ [0, 0.2]", false))
                show_progress && println("  ✗ $(basename(file_path)): Auto-rejected: all perf values ∈ [0, 0.2]")
                continue
            end
        end
        
        session_valid, status_msg = true, ""
        
        # Apply all filters with early exit on failure
        @inbounds for (filter_idx, (field_path, predicate)) in enumerate(inclusion)
            try
                value = _getNestedValue(yaml_data, field_path)
                value isa Vector{String} && (value = CIVec(value)) # strings are case insensitive
                session_valid, status_msg = predicate(value) ? 
                    (filter_idx == length(inclusion) ? (true, "Passed all $(length(inclusion)) filter(s)") : (true, "")) :
                    (false, "Filter #$filter_idx failed: '$field_path' = $value")
                !session_valid && break
            catch e
                session_valid, status_msg = false, "Error in filter #$filter_idx on '$field_path': $(e.msg)"
                break
            end
        end
        
        push!(files_info, (file_path, status_msg, session_valid))
        show_progress && println("  $(session_valid ? "✓" : "✗") $(basename(file_path)): $status_msg")
        session_valid && push!(valid_indices, file_idx)
    end
    
    show_progress && println("$(repeat("─", 65))\n✓ Result: $(length(valid_indices))/$n_files session(s) passed all filters\n")
    
    return valid_indices, files_info
end

"""
```julia
function selectDB([corpusDir    :: String,] 
                  paradigm      :: Symbol;
                  classes       :: Union{Vector{String}, Nothing} = paradigm == :P300 ? ["target", "nontarget"] : nothing,
                  inclusion     :: Union{Tuple, Nothing} = nothing,
                  summarize     :: Bool = true,
                  verbose       :: Bool = false)
```
Select BCI databases pertaining to the given BCI `paradigm` and all [sessions](@ref "session") therein 
meeting the provided inclusion criteria. 

Return the selected databases as a list of [`InfoDB`](@ref) structures, 
wherein the `InfoDB.files` field lists the included sessions only.

**Arguments**
- `corpusDir`: the directory on the local computer where to start the search. Any folder in this directory is a candidate [database](@ref) to be selected.

!!! tip "Smart Search"
    If a folder with the same name of the paradigm (for example: "MI") is found in `corpusDir`, the search starts therein
    and not in `corpusDir`. This way you can use the same `corpusDir` for all paradigms.

    If you want to use the [FII BCI corpus](@ref "FII BCI Corpus Overview") and you have downloaded it using the provided GUI — see [`downloadDB`](@ref) —, you can simply
    omit this argument; **Eegle** will automatically search within the FII BCI Corpus directory.

- `paradigm`: the BCI paradigm to be used. Supported paradigms at this time are `:P300` and `:MI`.

**Optional Keyword Arguments**
- `classes`: the labels of the classes the databases must include:
    - for the **P300** paradigm the default classes are `["target", "nontarget"]`, as in the FII BCI corpus.
    - for the **MI** and **ERP** paradigm there is no inclusion criterion based on class labels by default.

!!! note "Class labels for MI" 
    In the FII BCI corpus, available **MI** class labels are: *left_hand*, *right_hand*, *feet*, *rest*, *both_hands*, and *tongue*.

- `summarize`: if true (default), a summary table of the selected databases is printed in the REPL.

!!! tip "Nice printing" 
    End the `selectDB` line with a semicolon to easily visualize the summary table (see the examples).

- `verbose` : if true, print some feedback (in addition to the summary table).

- `inclusion`: tuple of custom filter conditions for advanced session filtering based on metadata fields present in the [metadata files](@ref "NY Metadata (YAML)").
   This argument is effective only when working with the FII BCI corpus. Each filter is a tuple with form `(field_path, predicate_function)`.
   String fields are matched case-insensitively (e.g. "Fz", "FZ" and "fz" are all equivalent).

Shortcuts are available for some fields:

**Available Shortcuts:**
- `sr` → `acquisition.samplingrate`
- `ref` → `acquisition.reference`
- `tpc` → `stim.trialsperclass`
- `perfLHRH` → `perf.left_hand-right_hand`
- `perfRHF` → `perf.right_hand-feet`


**Examples**

## Basic Filter Examples
```julia
# Exact sampling rate
inclusion = (("sr", ==(256)),)

# Minimum sampling rate
inclusion = (("sr", x -> x >= 128),)

# Sampling rate range
inclusion = (("sr", x -> 128 <= x <= 512),)

# Reference is Fz
inclusion = (("ref", ==("Fz")),)                  # acquisition.reference

# MDM performance for left_hand vs. right_hand is above 0.7
inclusion = (("perfLHRH.MDM", x -> x >= 0.7),)    # perf.left_hand-right_hand.MDM

# Must contain electrode Fz
inclusion = (("acquisition.sensors", x -> "Fz" ∈ x),)

# At least 16 electrodes
inclusion = (("sensors", x -> length(x) >= 16),)

# Minimum trials per class
inclusion = (("tpc", x -> minimum(values(x)) > 30),)

# Performance threshold using shortcut
inclusion = (("perfLHRH.MDM", x -> x >= 0.6),)

# Performance range
inclusion = (("perfLHRH.ENLR", x -> 0.6 <= x <= 0.85),)
```

## Combined Filters (AND Logic)
```julia
# SR ≥ 256 Hz + uses Fz electrode + good accuracy
inclusion = (
    ("sr", x -> x >= 256),
    ("acquisition.sensors", x -> "Fz" ∈ x),
    ("perfLHRH.MDM", x -> 0.6 <= x <= 0.85)
)
```

## Select DB Complete Usage Examples
```julia
# Basic selection with class filtering
DB_MI = selectDB(:MI; classes = ["left_hand", "right_hand"]);

# Advanced selection with custom filters
DB_MI = selectDB(:MI;
                 classes = ["left_hand", "right_hand"],
                 inclusion = (
                     ("sr", x -> x >= 256),
                     ("acquisition.sensors", x -> length(x) >= 16),
                     ("perfLHRH.MDM", x -> 0.6 <= x <= 0.85)
                 ),
                 verbose = true);

# P300 with performance filtering
DB_P300 = selectDB(:P300;
                   inclusion = (
                       ("sr", ==(128)),
                       ("perf.ENLR", x -> x >= 0.75)
                   ));
```

**See Also** 

[`infoDB`](@ref), [`loadDB`](@ref), [`weightsDB`](@ref)

"""
function selectDB(corpusDir     :: String,
                  paradigm      :: Symbol;
                  classes       :: Union{Vector{String}, Nothing} = paradigm == :P300 ? ["target", "nontarget"] : nothing,
                  inclusion     :: Union{Tuple, Nothing} = nothing,
                  summarize     :: Bool = true,
                  verbose       :: Bool = false)
    paradigm ∉ (:MI, :P300, :ERP) && error("Eegle.Database, function `selectDB`: Unsupported paradigm. Use :MI, :P300 or :ERP")
    
    # Auto-correct flat tuple format: ("field", pred) → (("field", pred),)
    if !isnothing(inclusion) && !isempty(inclusion) && inclusion[1] isa String
        @warn "Eegle.Database, function `selectDB`: `inclusion` was passed as a flat tuple — automatically wrapped. Add a trailing comma to avoid this: ((...),)"
        inclusion = (inclusion,)
    end

    # Check if there's a paradigm subfolder and move to it if it exists
    paradigmDir = joinpath(corpusDir, string(paradigm))
    isdir(paradigmDir) && (corpusDir = paradigmDir)
    !isdir(corpusDir) && error("Eegle.Database, function `selectDB`: the provided directory `corpusDir` is not valid. Please check: $corpusDir") 

    dbDirs = getFoldersInDir(corpusDir)
    isempty(dbDirs) && error("Eegle.Database, function `selectDB`: No database found in the directory: $corpusDir")

    # Check paradigm and classes requirements - no error for MI/ERP without classes
    if (paradigm == :MI || paradigm == :ERP) && isnothing(classes)
        println("Eegle.Database, function `selectDB`: No class filter specified for $paradigm paradigm. All databases will be returned.")
        @info "If you plan to train machine learning models, specify the `classes` argument to ensure consistent class selection across databases."
    end

    selectedDB = InfoDB[]
    all_cLabels = Set{String}()
    n_class_match = 0
    # Database-level filtering information collection structure
    db_filtering_info = Vector{Tuple{String, Vector{Tuple{String, String, Bool}}}}()
   
    # Normalize classes to lowercase for comparison
    norm_classes = isnothing(classes) ? nothing : lowercase.(classes)
   
    verbose && println("Searching for $(paradigm) databases" * 
        (isnothing(classes) ? " (no class filter)" : " containing: $(join(classes, ", "))"))
    
    @inbounds for dbDir in dbDirs
        info = infoDB(dbDir)
        
        # Skip if paradigm doesn't match
        uppercase(info.paradigm) != string(paradigm) && continue
        
        # Collect classes and check validity (only if classes are specified)
        union!(all_cLabels, info.cLabels)
        if !isnothing(classes)
            all(required_class ∈ lowercase.(info.cLabels) for required_class ∈ norm_classes) || continue
        end

        n_class_match += 1

        # Apply custom filters if provided
        if !isnothing(inclusion)

            # Remove paradigm and classes filters from inclusion if present
            forbidden = [f for (f, _) in inclusion if f ∈ ("paradigm", "classes")]
            if !isempty(forbidden)
                @warn "Eegle.Database, function `selectDB`: Filters automatically removed (conflict with function arguments): $(join(forbidden, ", "))"
                inclusion = Tuple(filter(x -> x[1] ∉ ("paradigm", "classes"), collect(inclusion)))
                isempty(inclusion) && (inclusion = nothing)
            end

            # Skip progress display; defer until verbose=true
            valid_indices, files_info = _filter(info.files, inclusion; verbose=false, show_progress=false)
            
            # Store info for later output
            !isempty(files_info) && push!(db_filtering_info, (info.dbName, files_info))
            
            # Skip database if no valid files
            isempty(valid_indices) && continue
            
            # Filter info.files to keep only valid ones
            valid_files = info.files[valid_indices]
            empty!(info.files)
            append!(info.files, valid_files)
        end
        
        push!(selectedDB, info)
    end

    if isempty(selectedDB)
        if !isnothing(inclusion) && n_class_match > 0
            error("Eegle.Database, function `selectDB`: $n_class_match $(paradigm) database(s) matched paradigm/classes criteria but no session passed the `inclusion` filters.")
        else
            error("Eegle.Database, function `selectDB`: No $(paradigm) database contains all selected classes: $(join(classes, ", "))" *
                (!isempty(all_cLabels) ? ".\nAll available classes: " * join(sort(collect(all_cLabels)), ", ") : ""))
        end
    end

    # Show filtering results
    if !isempty(db_filtering_info)
        if verbose
            # Verbose output mode
            println("\n$(repeat("═", 65))")
            println("⚠️  FILTERING RESULTS BY DATABASE")
            println(repeat("═", 65))
            
            for (dbName, files_info) in db_filtering_info
                # Track pass/fail counts
                n_passed = count(x -> x[3], files_info)
                n_total = length(files_info)
                
                println("\nDatabase: $dbName")
                println(repeat("─", 65))
                
                for (file_path, status, passed) in files_info
                    symbol = passed ? "✓" : "✗"
                    println("  $symbol $(basename(file_path)): $status")
                end
                
                println(repeat("─", 65))
                println("✓ Result: $n_passed/$n_total session(s) passed all filters")
            end
        else
            # Compact output when verbose=false (legacy style, simplified)
            println("\n$(repeat("─", 65))")
            println("⚠️  Files excluded by custom filters:")
            
            for (dbName, files_info) in db_filtering_info
                excluded_files = [basename(f) for (f, _, passed) in files_info if !passed]
                if !isempty(excluded_files)
                    println("  Database: $dbName")
                    for file in excluded_files
                        println("    • $file")
                    end
                end
            end
            println(repeat("─", 65), "\n")
        end
    end
   
    println()

    if verbose
        println("$(repeat("═", 50))")
        println("✓ $(length(selectedDB)) database(s) selected (Database - Condition):")
        for db in selectedDB
            println("  • $(db.dbName) - $(db.condition)")
        end
        println(repeat("═", 50))
    end
    
    # Create summary table if requested
    if summarize
        summary_data = []
        for db in selectedDB
            # Format nSessions
            min_sessions = minimum(db.nSessions)
            max_sessions = maximum(db.nSessions)
            nsessions_str = min_sessions == max_sessions ? "$(min_sessions)" : "($(min_sessions),$(max_sessions))"
            
            push!(summary_data, (
                dbName = db.dbName,
                condition = db.condition,
                nSubjects = db.nSubjects,
                nSessions = nsessions_str,
                nSensors = db.nSensors,
                sensorType = db.sensorType,
                nClasses = db.nClasses,
                sr = db.sr,
                wl = db.wl,
                os = db.offset
            ))
        end
        
        summary_df = DataFrame(summary_data)
        println("SUMMARY TABLE OF SELECTED DATABASES")
        println(repeat("═", 150))
        show(summary_df, allrows=true, allcols=true)
        println("\n$(repeat("═", 150))")
        println("\n💡 For detailed trial counts per class, please inspect individual database structures")
    end
    return selectedDB;  # selectedDB is a list of InfoDB struct respecting the conditions
end

function selectDB(paradigm      :: Symbol;
                  classes       :: Union{Vector{String}, Nothing} = paradigm == :P300 ? ["target", "nontarget"] : nothing,
                  inclusion     :: Union{Tuple, Nothing} = nothing,
                  summarize     :: Bool = true,
                  verbose       :: Bool = false)

    corpusDir = _dirFII() # see GUIs\downloadDB\db_catalog.jl
    if isnothing(corpusDir)
        throw(ArgumentError("Eegle.Database.selectDB: the default directory of the FII BCI Corpus has not been found. Please install the corpus running `downloadDB()`. Looking into $corpusDir"))
    else
        selectDB(corpusDir, paradigm; classes, inclusion, summarize, verbose)
    end
end

# Helper function to compute weights for statistics in Benchmark studies
function _weightsDB(subject, n)
    usub = unique(subject)
    sess = [count(==(s), subject) for s in usub]

    sum(sess) ≠ n && error(
        "Eegle.Database, function `_weightsDB` called by `weightsDB`: " *
        "the number of sessions does not match the number of files in the database"
    )

    M = length(usub)
    N = n

    # per-subject numerator: √M · √S_m
    w_sub = sqrt(M) .* sqrt.(sess)

    # map subject identifier → index in usub
    sub2idx = Dict(s => i for (i, s) in enumerate(usub))

    weights = Vector{Float64}(undef, N)
    for (i, s) in enumerate(subject)
        k = sub2idx[s]
        weights[i] = w_sub[k] / sess[k]
    end

    # M × 2 schedule: [subject_id  number_of_sessions]
    schedule = hcat(usub, sess)

    return weights, schedule
end


"""
```julia
function weightsDB(files)
```

**Tutorials**

[Tutorial ML 2](@ref)

Given a [database](@ref) in [NY format](@ref), provided by argument `files` as a list of *.npz* files,
where each file holds a BCI [session](@ref), 
compute a weight for each session to be used in statistical analysis when merging 
any session-based relevant index such as the classification performance, within and across databases. 

The goal of the weighting is to balance the contribution of all unique [subjects](@ref subject), considering 
that the number of sessions for each subject may be different.
Specifically, this weighting assigns each subject a total contribution that grows with the 
square root of the number of sessions provided and with the square root of the number of subjects 
in the database, thereby rewarding richer subject-level information, while preventing databases 
with many sessions or many subjects from dominating the analysis.

Let ``s_m`` denote one of the ``S_m`` sessions for each unique subject ``m``, 
the weight ``w_{m,s_m}`` for session ``s_m`` is given by:

```math
    w_{m,s_m} = \\frac{\\sqrt{M} \\cdot \\sqrt{S_m}}{S_m}
```

where ``M`` is the number of unique subjects in the database and ``N`` is the total number of sessions (i.e., `length(files)`).

This weighting ensures that the **sum of the weights for each subject in the database** is proportional to

```math
\\sqrt{M} \\cdot \\sqrt{S_m}
```

For example,

- if database *A* has ``M = 64`` unique subjects and each provides 1 session, ``N = 64`` and the 
  total weight for each session is ``\\frac{\\sqrt{64}\\cdot\\sqrt{1}}{1} = 8``;

- if database *B* also has ``M = 64`` unique subjects, but each provides 4 sessions, 
  the weight for each session is ``\\frac{\\sqrt{64}\\cdot\\sqrt{4}}{4} = 4`` 
  and the sum of the weights for each unique subject is ``4 \\cdot 4 = 16``, 
  reflecting he fact that the subjects in database *B* provide more sessions than the 
  subject in database *A*, thus they should be weighted more; 

- if database *C* has ``M = 16`` unique subjects providing 4 sessions each as in database *B*,
  the weight for each session is ``\\frac{\\sqrt{16}\\cdot\\sqrt{4}}{4} = 2`` and the sum of 
  the weights for each unique subject is ``4 \\cdot 2 = 8``,
  reflecting the fact that database *C* provides fewer subjects than database *B*;

- if database *D* has ``M = 4`` unique subjects, two of which providing 1 session and two 
  of which providing 4 sessions, the weight for each session of the subjects providing
  4 sessions is ``\\frac{\\sqrt{4}\\cdot\\sqrt{4}}{4} = 1`` and the weight for each session 
  of the subjects providing 1 session is ``\\frac{\\sqrt{4}\\cdot\\sqrt{1}}{1} = 2``, 
  thus the total weight for the subjects providing 4 session is ``4 \\cdot 1 = 4``, 
  which is larger than that of subjects providing a single session (``2``), 
  reflecting the fact that these subjects provide more session.

This is a compromise between two extreme strategies commonly used when merging indices
across subjects and/or databases, which are both inadequate:

- **Uniform per-session weights** (i.e., all sessions contribute equally), 
  which overemphasizes larger databases and subjects providing many sessions
- **Uniform per-database weights** (i.e., all databases contribute equally), 
  which overemphasizes small databases and subjects providing many sessions.

Once obtained the weights for one or more databases, 
they can be globally normalized in any desired way
(e.g., to unit mean or unit sum),
within databases, or, concatenating them, across databases.

**Return**
- `weights`: a vector of length ``N``, containing the weight corresponding to each session in `files`
- `schedule`: an ``M × 2`` matrix of integers where:
  - the first column contains the index of the unique subjects
  - the second column contains the number of sessions for those subjects.

**Examples**

*Example 1* uses the [loadDB](@ref) function to create weights for all *.npz* files 
found in directory `dir` which name contains the string "condition1".

The following two examples select motor imagery databases featuring classes
"left_hand" and "right_hand" from the 
[FII BCI Corpus](@ref "FII BCI Corpus Overview") using the [selectDB](@ref) function and
compute the weights for all files (i.e., sessions) in all selected databases. In particular:

- *Example 2* computes and normalize to unit mean the weights separately for each database. 
  Once this is done, computing the mean of any index (e.g., balanced accuracy) weighted by `w` 
  within each database will result in the
  weighted average index across all sessions within each database, as defined above.

- *Example 3* stacks the weights for all databases in a single vector and normalize 
  all weights to unit mean. 
  Once this is done, computing the mean of any index (e.g., balanced accuracy) 
  stacked in the same way across databases and weighted by `w` will result in the
  weighted average index across all sessions and all databases as defined above.

```julia
using Eegle

# Example 1
w, schedule = weightsDB(loadDB(dir, "condition1"))

# Example 2
DB_MI = selectDB(:MI; classes = ["left_hand", "right_hand"])
w = [weightsDB(db.files)[1] for db ∈ DB_MI]
w = [v ./= mean(v) for v ∈ w]

# Example 3
DB_MI = selectDB(:MI; classes = ["left_hand", "right_hand"])
w = vcat([weightsDB(db.files)[1] for db ∈ DB_MI]...)
w ./= mean(w)
```

"""
function weightsDB(files)
    # make sure only .npz files have been passed in the list `files`
    for (i, f) ∈ enumerate(files)
        splitext(f)[2]≠".npz" && deleteat!(files, i)
    end
    length(files)==0 && error("Eegle.Database, function `weightsDB`: no .npz file is present in the list of files passed as argument")

    # read one YAML file to find out the type of dictionary values
    filename=files[1]
    isfile(splitext(filename)[1]*".yml") || error("Eegle.Database, function `weightsDB`: no .yml (recording info) file has been found for npz file \n:", filename)

    # get memory for all entry of the YAML dictionary for all files
    # knowing the type of the values is much more memory-efficient
    subject			= typeof( YAML.load(open(splitext(filename)[1]*".yml"))["id"]["subject"])[]
    #run				= typeof(info["id"]["run"])[]

    for (f, filename) ∈ enumerate(files)

        isfile(splitext(filename)[1]*".yml") || error("Eegle.Database, function `weightsDB`: no .yml (recording info) file has been found for npz file \n:", filename)
        push!(subject, YAML.load(open(splitext(filename)[1]*".yml"))["id"]["subject"])
    end

    subject = subject isa Vector{String} ? [parse(Int, s) for s ∈ subject] : subject
    subject = subject isa Vector{Float64} ? Int.(subject) : subject

    return _weightsDB(subject, length(files))
end


"""
```julia

(1) 
function downloadDB()

(2) 
function downloadDB(url::String, dest::String = homedir())

(3) 
function downloadDB(urls::Vector{String}, dest::String = homedir())
```
(1) **Interactive GUI mode**

Open an interactive GUI to select and download databases from the FII BCI Corpus.

!!! warning "Make sure you have enough space of disk"
    The size of the corpus on disk is **36.6 GB** for MI and **14.2 GB** for P300.
    
The GUI will open in the primary HTML display found in the Julia display stack, which typically
is VS Code if you use it or the default web-browser. It looks like this:

![Figure GUI_downloadDB](assets/GUI_downloadDB.png)

Once a BCI paradigm is chosen (MI or P300), the following inclusion criteria can be enforced:
- the minimum number of trials per class
- the motor imagery classes (for MI paradigm only) 

The table on the right lists the available databases given the current inclusion criteria.

The **Choose path** button invokes a folder selection window to choose the folder where the corpus is to be downloaded (default: *homedir*).

!!! warning "Folder selection window"
    The folder selection window may open minimized. Check the task bar if you don't see it.

If the **Overwrite existing data** check box is not checked (default), the databases will be downloaded only if a folder with the same name
does not exist already. If you have previously downloaded the corpus and you want to update to a new version, check this box.

As soon as the **Download Now** button is pressed, the GUI automatically downloads the databases, extracts their contents, and removes the ZIP archives.

A progress indicator is displayed in the REPL throughout the download and extraction process and a notification
is printed when the download has ended. 

!!! warning "Paradigms"
    The databases pertaining to the MI and P300 paradigm must be downloaded separately.

!!! tip "Using the FII BCI Corpus"
    Once the corpus is downloaded, **Eegle** knows automatically where to find it. Therefore, omitting the argument `corpusDir` while using function [`Eegle.Database.selectDB`](@ref)
    will automatically point to the FII BCI corpus. 

(2) **Direct download of a single [Zenodo](https://zenodo.org/) record**

Argument `url` must point to a Zenodo record page (e.g. "https://zenodo.org/records/17670014").

All files associated with the record are downloaded into folder `dest` (the *homedir* by default).

A progress indicator is displayed in the REPL throughout the download and extraction process.

(3) **Direct download of several Zenodo records**

This is the same as (2), but for a vector of Zenodo record URLs.

!!! warning "Time out"
    A time out of three hours is enforced for the download of each database. If your connection requires more than that
    for a large database, consider downloading and unzipping such a database from Zenodo.

**Examples**
```julia
downloadDB() # run the GUI

downloadDB("https://zenodo.org/records/17670014")

downloadDB(["url1", "url2"], "/path/to/folder")
```
"""
function downloadDB()
    _downloadDB()
end


function downloadDB(url::String, dest::String = DEFAULT_DOWNLOAD_DIR)
    _downloadDB(url, dest)
end


function downloadDB(urls::Vector{String}, dest::String = DEFAULT_DOWNLOAD_DIR)
    _downloadDB(urls, dest)
end




# overwrite the Base.show function to nicely print information
# about the InfoDB structure in the REPL
# ++++++++++++++++++++  Show override  +++++++++++++++++++ # (REPL output)
function Base.show(io::IO, ::MIME{Symbol("text/plain")}, db::InfoDB)
    # Format ntrialsperclass - show mean ± std + min,max 
    trials_parts = String[]
    for class_name in db.cLabels  # use clabels to maintain order
        trials_vec = db.nTrials[class_name]
        if length(unique(trials_vec)) == 1 # All trials are the same for this class
            trial_str = "$(trials_vec[1]) ± 0"
            minmax_str = ""
        else # Calculate mean, std, min, max
            mean_trials = round(sum(trials_vec) / length(trials_vec), digits=1)
            std_trials = round(sqrt(sum((x - mean_trials)^2 for x in trials_vec) / (length(trials_vec) - 1)), digits=1)
            min_trials = minimum(trials_vec)
            max_trials = maximum(trials_vec)
            trial_str = "$(mean_trials) ± $(std_trials)"
            minmax_str = "($(min_trials),$(max_trials))"
        end
        push!(trials_parts, "$class_name: $trial_str $minmax_str")
    end

    # Format the display with proper spacing
    first_line = "nTrials per class              : $(trials_parts[1])"
    remaining_classes = length(trials_parts) > 1 ? 
        "     " * join(trials_parts[2:end], "\n                                 ") : ""
    second_line = "└▶mean ± std (min,max)      $remaining_classes"

    nTrials_str = "$first_line\n$second_line"

    # Format sensors - show first 3 + total count if more than 3
    sensors_str = if length(db.sensors) <= 3
        join(db.sensors, ", ")
    else
        join(db.sensors[1:3], ", ") * "..."
    end

    # Format nsessions - show single value if min == max
    min_sessions = minimum(db.nSessions)
    max_sessions = maximum(db.nSessions)
    nsessions_str = min_sessions == max_sessions ? "$(min_sessions)" : "($(min_sessions),$(max_sessions))"

    println(io, titleFont, "🗄️  Database Summary: $(db.dbName) | $(db.nSubjects) subjects, $(db.nClasses) classes")
    println(io, separatorFont, "∼∽∿∽∽∽∿∼∿∽∿∽∿∿∿∼∼∽∿∼∽∽∿∼∽∽∼∿∼∿∿∽∿∽∼∽∼∿∼∿∿∽∿∽∼∽∼∽∽∼∿∼∿∿∽∿∼∿∿∽∿∼∿∿∽∿", greyFont)
    println(io, "NY format database main characteristics and metadata")
    println(io, separatorFont, "∼∽∿∽∽∽∿∼∿∽∿∽∿∿∿∼∼∽∿∼∽∽∿∼∽∽∼∿∼∿∿∽∿∽∼∽∼∿∼∿∿∽∿∽∼∽∼∽∽∼∿∼∿∿∽∿∼∿∿∽∿∼∿∿∽∿", defaultFont)
    println(io, "condition                      : $(db.condition)")
    println(io, "paradigm                       : $(db.paradigm)")
    println(io, "nSessions (min,max)            : $(nsessions_str)")
    println(io, "nSensors                       : $(db.nSensors)")
    println(io, "sensors                        : $sensors_str")    
    println(io, "sensorType                     : $(db.sensorType)")
    println(io, "sr (Hz)                        : $(db.sr)")
    println(io, "wl (samples)                   : $(db.wl)")
    println(io, "offset (samples)               : $(db.offset)")
    println(io, nTrials_str)
    println(io, separatorFont, "∼∽∿∽∽∽∿∼∿∽∿∽∿∿∿∼∼∽∿∼∽∽∿∼∽∽∼∿∼∿∿∽∿∽∼∽∼∿∼∿∿∽∿∽∼∽∼∽∽∼∿∼∿∿∽∿∼∿∿∽∿∼∿∿∽∿", defaultFont)
    println(io, "Fourteen Additional fields:")
    println(io, ".files, .cLabels, .filter, .hardware, .software,")
    println(io, ".doi, .reference, .ground, .place, .investigators,")  
    println(io, ".description, .repository, .timestamp, .formatVersion")
end


end # module

