# v 0.1 Nov 2024
# v 0.2 June 2025
# Part of the Eegle.jl package.
# Copyright Marco Congedo, Fahim Doumi, CNRS, University Grenoble Alpes.

module Database

using NPZ, YAML, HDF5, EzXML, DataFrames

using Eegle.FileSystem

#=
# ? ¤ CONTENT ¤ ? #

infoDB          | immutable structure holding the information summarizing an EEG database
loadNYdb        | return a list of .npz files in a directory (this is considered a 'database')
infoNYdb        | print and return information about a database (infoDB structure)
selectDB        | select database folders based on paradigm and class requirements
weightsdb       | get weights for each session of a database for statistical analysis

=#

# Module REPL text colors
const titleFont     = "\x1b[95m"
const separatorFont = "\x1b[35m"
const defaultFont   = "\x1b[0m"
const greyFont      = "\x1b[90m"


import Eegle

export
    infoDB,
    loadNYdb, 
    infoNYdb,
    selectDB,
    weightsDB


"""
```julia
struct infoDB
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

It is created by functions [infoNYdb](@ref) and [`selectDB`](@ref).

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
struct infoDB
    dbName              :: String                           # database name
    condition           :: String                           # experimental condition
    paradigm            :: String                           # experimental paradigm (MI, P300, etc.)
    files               :: Vector{String}                   # database's files 
    nSessions           :: Vector{Int}                      # sessions per subject 
    nTrials             :: Dict{String, Vector{Int}}        # trials per class per session (class_name => [trials_per_session])
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
    function loadNYdb(dbDir=AbstractString, isin::String="")
```
Return a list of the complete paths of all *.npz* files found in a directory given as argument `dbDir`.
For each *NPZ* file, there must be a corresponding *YAML* metadata file with the same name and extension *.yml*, otherwise
the file is not included in the list.

If a string is provided as kwarg `isin`, only the files whose name
contains the string will be included. 

**See Also** 

[`infoNYdb`](@ref), [`FileSystem.getFilesInDir`](@ref)

**Examples**
xxx
"""
function loadNYdb(dbDir=AbstractString, isin::String="")
  # create a list of all .npz files found in dbDir (complete path)
  npzFiles=Eegle.FileSystem.getFilesInDir(dbDir; ext=(".npz", ), isin=isin)

  # check if for each .npz file there is a corresponding .yml file
  missingYML=[i for i ∈ eachindex(npzFiles) if !isfile(splitext(npzFiles[i])[1]*".yml")]
  if !isempty(missingYML)
    @warn "Eegle.Database, function `loadNYdb`: the following .yml files have not been found:\n"
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
    function infoNYdb(dbDir)
```
Create a [infoDB](@ref) structure and show it in Julia's REPL.

The only argument (`dbDir`) is the directory holding all files of a database — see [NY format](@ref).

This function carry out a sanity checks on the database and prints warnings if the checks fail.

**Examples**
```julia
db = infoNYdb(dbDir)
```
"""
function infoNYdb(dbDir)

    files = loadNYdb(dbDir)

    # make sure only .npz files have been passed in the list `files`
    for (i, f) ∈ enumerate(files)
        splitext(f)[2]≠".npz" && deleteat!(files, i)
    end
    length(files)==0 && error("Eegle.Database, function `infoNYdb`: there are no .npz files in the list of files passed as argument")

    # read one YAML file to find out the type of dictionary values
    filename = files[1]
    isfile(splitext(filename)[1]*".yml") || error("Eegle.Database, function `infoNYdb`: no .yml (recording info) file has been found for npz file \n:", filename)
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
    nTrials             = typeof(info["stim"]["trials_per_class"])[]

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

        isfile(splitext(filename)[1]*".yml") || error("Eegle.Database, function `infoNYdb`: no .yml (recording meta-data) file has been found for npz file \n:", filename)
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
        push!(nTrials, stim["trials_per_class"])

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
        @warn "Eegle.Database, function `infoNYdb`: $text"
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
    length(unique(ssr)) < length(subject) && error("Eegle.Database, function `infoNYdb`:: there are duplicated triplets (subject, session, run)")

    # CRITICAL ERROR CHECK: session count consistency
    usub = unique(subject)
    sess = [sum(ss==s for ss∈subject) for s∈usub] # sessions per subject
    sum(sess) ≠ length(files) && error("Eegle.Database, function `infoNYdb`: the number of sessions does not match the number of files in database")

    # Warning about run field inconsistency
    length(unique(run)) > 1 && mywarn("field `run` should be considered the number of runs and should be the same in all recordings. In any case this field is not used")

    if nwarnings > 0
        println(separatorFont, "\n⚠ Be careful, $nwarnings warnings have been found", defaultFont)
    else
        println(greyFont, "\n✓ All sanity checks passed", defaultFont)
    end

    # Create infoDB structure
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

    # Create and return infoDB structure (will be displayed automatically via Base.show)
    return infoDB(
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

"""
```julia
function selectDB(rootDir       :: String,
                  paradigm      :: Symbol;
        classes     :: Union{Vector{String}, Nothing} = 
                        paradigm == :P300 ? ["target", "nontarget"] : nothing,
        minTrials   :: Union{Int, Nothing} = nothing,
        summarize   :: Bool = true)
```
Select BCI databases pertaining to the given BCI paradigm. Optionally, each [session](@ref) of the selected databases 
is scrutinized to meet the provided inclusion criteria. 

Return the selected databases as a list of [`infoDB`](@ref) structures, wherein, if inclusion criteria are provided, 
the `infoDB.files` field lists the included sessions only.

**Arguments**
- `rootDir`: the directory on the local computer where to start the search. Any folder in this directory is a candidate [database](@ref) to be selected.
- `paradigm`: the BCI paradigm to be used. Supported paradigms at this time are: `:P300`, `:ERP` or `:MI`.

!!! tip 
    If a folder with the same name of the paradigm (for example: "MI") is found in `rootDir`, the search starts therein
    and not in `rootDir`. 

**Optional Keyword Arguments**
- `classes`: the labels of the classes the databases must include:
    - for the **P300** paradigm the default classes are `["target", "nontarget"]`, as in the FII corpus.
    - for the **MI** and **ERP** paradigm there is no inclusion criterion based on class labels by default.

!!! tip 
    In the FII corpus, available **MI** class labels are: "left_hand", "right_hand", "feet", "rest", "both_hands", and "tongue".

- `minTrials`: the minimum number of trials for all classes in the sessions to be included. 
- `summarize`: if true (default) a summary table of the selected databases is printed in the REPL.

**Examples**
```julia
selectedDB = selectDB(.../directory_to_start_searching/, :P300)

selectedDB = selectDB(.../directory_to_start_searching/, :MI;
                      classes = ["left_hand", "right_hand"])

selectedDB = selectDB(.../directory_to_start_searching/, :MI;
                      classes = ["rest", "both_hands", "feet"],
                      minTrials = 50,
                      summarize = false)
```
"""
function selectDB(rootDir       :: String,
                  paradigm      :: Symbol;
                  classes       :: Union{Vector{String}, Nothing} = paradigm == :P300 ? ["target", "nontarget"] : nothing,
                  minTrials     :: Union{Int, Nothing} = nothing,
                  summarize     :: Bool = true)
    
    paradigm ∉ (:MI, :P300, :ERP) && error("Eegle.Database, function `selectDB`: Unsupported paradigm. Use :MI, :P300 or :ERP")
    
    # Check if there's a paradigm subfolder and move to it if it exists
    paradigmDir = joinpath(rootDir, string(paradigm))
    isdir(paradigmDir) && (rootDir = paradigmDir)

    dbDirs = getFoldersInDir(rootDir)
    isempty(dbDirs) && error("Eegle.Database, function `selectDB`: No database found in the directory: $rootDir")

    # Check paradigm and classes requirements - no error for MI/ERP without classes
    if (paradigm == :MI || paradigm == :ERP) && isnothing(classes)
        println("Eegle.Database, function `selectDB`: No class filter specified for $paradigm paradigm. All databases will be returned.")
        @warn "If you plan to perform classification with these databases, it is strongly recommended to specify the 'classes' argument to ensure consistent class selection across databases."
    end

    selectedDB = infoDB[]  # List of infoDB structures
    all_cLabels = Set{String}()  # To collect all available classes for ERP/MI paradigm
    excluded_files_info = Tuple{String, Vector{String}}[]  # (database_name, excluded_files)
   
    # Normalize classes to lowercase for comparison
    norm_classes = isnothing(classes) ? nothing : lowercase.(classes)
   
    println("Searching for $(paradigm) databases" * 
        (isnothing(classes) ? " (no class filter)" : " containing: $(join(classes, ", "))"))
    
    @inbounds for dbDir in dbDirs
        info = infoNYdb(dbDir)
        
        # Skip if paradigm doesn't match
        uppercase(info.paradigm) != string(paradigm) && continue
        
        # Collect classes and check validity (only if classes are specified)
        union!(all_cLabels, info.cLabels)
        if !isnothing(classes)
            all(required_class ∈ lowercase.(info.cLabels) for required_class ∈ norm_classes) || continue
        end

        # Handle minTrials filtering
        if !isnothing(minTrials)
            excluded_files, valid_indices = String[], Int[]
            classes_to_check = isnothing(classes) ? info.cLabels : classes
            
            @inbounds for (file_idx, file_path) ∈ enumerate(info.files)
                session_valid = true
                @inbounds for class_name ∈ classes_to_check
                    # Find the actual class name in the database (case-sensitive)
                    actual_class_idx = isnothing(classes) ? 
                                    findfirst(==(class_name), info.cLabels) :
                                    findfirst(db_class -> lowercase(db_class) == lowercase(class_name), info.cLabels)
                    actual_class = info.cLabels[actual_class_idx]
                
                    if haskey(info.nTrials, actual_class) &&
                    info.nTrials[actual_class][file_idx] < minTrials
                        session_valid = false
                        break
                    end
                end
                session_valid ? push!(valid_indices, file_idx) : push!(excluded_files, file_path)
            end
            
            # Skip database if no valid files
            if isempty(valid_indices)
                !isempty(excluded_files) && push!(excluded_files_info, (info.dbName, excluded_files))
                continue
            end
            
             # Create filtered infoDB if files were excluded
            if !isempty(excluded_files)
                push!(excluded_files_info, (info.dbName, excluded_files))
                
                # Modify existing vectors to exclude files not respecting minTrials
                valid_files = info.files[valid_indices]
                empty!(info.files)
                append!(info.files, valid_files)
                
            end
        end
        push!(selectedDB, info)
    end

    isempty(selectedDB) && error("Eegle.Database, function `selectDB`: No $(paradigm) database " *
        "contains all selected classes: $(join(classes, ", "))" *
        (!isempty(all_cLabels) ? ".\nAll available classes: " * join(sort(collect(all_cLabels)), ", ") : ""))

    # Print excluded files information
    !isempty(excluded_files_info) && println("\n$(repeat("─", 65))\n⚠️  Files excluded due to insufficient trials per class (< $minTrials):", 
    join(["\n  Database: $dbName" * join(["\n    • $(basename(file))" for file in files], "") 
          for (dbName, files) in excluded_files_info], ""))
   
    println("\n$(repeat("═", 50))")
    println("✓ $(length(selectedDB)) database(s) selected (Database - Condition):")
    for db in selectedDB
        println("  • $(db.dbName) - $(db.condition)")
    end
    println(repeat("═", 50))

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
                os = db.os
            ))
        end
        
        summary_df = DataFrame(summary_data)
        println("SUMMARY TABLE OF SELECTED DATABASES")
        println(repeat("═", 150))
        show(summary_df, allrows=true, allcols=true)
        println("\n$(repeat("═", 150))")
        println("\n💡 For detailed trial counts per class, please inspect individual database structures")
    end
    return selectedDB  # selectedDB is a list of infoDB struct respecting the conditions
end


function _weightsDB(subject, n)
    usub = unique(subject)
    sess = [sum(ss==s for ss∈subject) for s∈usub]
    sum(sess) ≠ n && error("Eegle.Database, function `_weightsdb` called by `weightsdb`: the number of sessions does not match the number of files in the database")

    w=[sqrt(length(usub))*(sqrt(s)) for s ∈ sess] # weights for each unique subject
    weights = [w[findfirst(el -> el == s, usub)] for s ∈ subject] # weights for each input file
    #m = mean(weights)
    #(weights./=sum(weights)).*=m
    return (weights./=length(weights), [usub sess])
end

"""
```julia
    function weightsDB(files)
```
Given a database provided by argument `files` as a list of *.npz* files, 
compute a weight for each session to be used in statistical analysis when merging the classification performance 
or any other relevant index across databases. 

The goal of the weighting is to balance the contribution of different databases 
and the different [subjects](@ref subject) therein, considering both the number of unique subjects in each database
and the fact that the number of [session](@ref) for each subject may be different.

The weight assigned to each session is inversely proportional to the square root of the number of unique subjects 
in the database and to the square root of the number of sessions available for the same subject.

Let ``s_m`` be one of the ``S_m`` sessions for each unique subject ``m``, the weight ``w_{m,s_m}`` for session ``s_m`` is given by:

```math
    w_{m,s_m} = \\frac{\\sqrt{M} \\cdot \\sqrt{S_m}}{N}
```

where ``M`` is the number of unique subjects in the database and ``N`` is the total number of sessions (i.e., `length(files)`).

This weighting ensures that the **sum of the weights for each subject** is proportional to

```math
\\sqrt{M} \\cdot \\sqrt{S_m}
```

For example,

- if the database has ``M = 100`` subjects and each has 1 session, the 
  total weight for each subject is ``\\sqrt{100} \\cdot \\sum_{m=1}^{100} \\frac{\\sqrt{1}}{N} = 10``
- if each of the 100 subjects has 4 sessions, the
  total weight for each subject is ``\\sqrt{100} \\cdot \\sum_{m=1}^{100} \\frac{\\sqrt{4}}{N} = 20``.

This is a compromise between two extreme strategies commonly used when merging indices
across databases, which are both inadequate:

- **Uniform per-session weights** (i.e., all sessions contribute equally), which favors larger databases or those with many sessions
- **Uniform per-database weights** (i.e., all databases contribute equally), which overemphasizes small databases.

Once obtained the weights for several databases, they can be globally normalized in any desired way.

**Return**
- `weights`: a vector of length ``N``, containing the weight for each session in `files`
- `schedule`: an ``N × 2`` matrix of integers where:
  - the first column contains the index of the subject to which the session belongs
  - the second column contains the number of sessions for that subject.

**Examples**
```julia
w, schedule = weightsDB(files)
```

**Tutorials**
xxx
"""
function weightsDB(files)
    # make sure only .npz files have been passed in the list `files`
    for (i, f) ∈ enumerate(files)
        splitext(f)[2]≠".npz" && deleteat!(files, i)
    end
    length(files)==0 && error("Eegle.Database, function `weightsdb`: no .npz file is present in the list of files passed as argument")

    # read one YAML file to find out the type of dictionary values
    filename=files[1]
    isfile(splitext(filename)[1]*".yml") || error("Eegle.Database, function `weightsdb`: no .yml (recording info) file has been found for npz file \n:", filename)

    # get memory for all entry of the YAML dictionary for all files
    # knowing the type of the values is much more memory-efficient
    subject			= typeof( YAML.load(open(splitext(filename)[1]*".yml"))["id"]["subject"])[]
    #run				= typeof(info["id"]["run"])[]

    for (f, filename) ∈ enumerate(files)

        isfile(splitext(filename)[1]*".yml") || error("Eegle.Database, function `weightsdb`: no .yml (recording info) file has been found for npz file \n:", filename)
        push!(subject, YAML.load(open(splitext(filename)[1]*".yml"))["id"]["subject"])
    end

    subject = subject isa Vector{String} ? [parse(Int, s) for s ∈ subject] : subject
    subject = subject isa Vector{Float64} ? Int.(subjects) : subject

    return _weightsDB(subject, length(files))
end


# overwrite the Base.show function to nicely print information
# about the infoDB structure in the REPL
# ++++++++++++++++++++  Show override  +++++++++++++++++++ # (REPL output)
function Base.show(io::IO, ::MIME{Symbol("text/plain")}, db::infoDB)
    # Format ntrials_per_class - show mean ± std + min,max 
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

