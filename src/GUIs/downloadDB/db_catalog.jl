using Eegle
using Downloads

# Metadata describing each database in the corpus (type, classes, URL, etc.).
struct DBMeta
    name :: String
    paradigm :: Symbol
    classes :: Union{Vector{String}, Nothing} 
    minTrials :: Union{Int, Nothing} 
    url :: String
end

# Local paths to Eegle’s internal folder and to the file storing the corpus location.
# DEPOT_PATH[1] is where the .julia flder is on the PC
#const EegleDir = joinpath(homedir(), ".julia", "packages", "Eegle")
const EegleDir = joinpath(DEPOT_PATH[1], "packages", "Eegle")
const FII_BCI_CORPUS_PATHFILE = joinpath(EegleDir, "FII_BCI_Corpus.txt")
const CORPUS_DIR = "FII_BCI_Corpus"


# Zenodo API URLs for MI and P300 files.
const MIpath = "https://zenodo.org/api/records/17801878/files/" 
const P300path = "https://zenodo.org/api/records/21024698/files/"


# Available MI and P300 class labels in the corpus.
const MI_CLASSES = ["lefthand", "righthand", "feet", "tongue", "rest", "bothhands"]
const P300_CLASSES = ["target", "nontarget"]

# Complete catalog of MI / P300 databases with their properties and URLs.
const DB_CATALOG = [
    # ==== MOTOR IMAGERY DATABASES ====
    DBMeta("AlexMI", :MI, ["righthand", "feet", "rest"], 20,
        string(MIpath, "AlexMI.zip/content")),
    
    DBMeta("BNCI2014001", :MI, ["lefthand", "righthand", "feet", "tongue"], 72,
        string(MIpath, "BNCI2014001.zip/content")),
    
    DBMeta("BNCI2014002-Train", :MI, ["righthand", "feet"], 50,
        string(MIpath, "BNCI2014002-Train.zip/content")),
    
    DBMeta("BNCI2014002-Test", :MI, ["righthand", "feet"], 30,
        string(MIpath, "BNCI2014002-Test.zip/content")),
    
    DBMeta("BNCI2014004-Train", :MI, ["lefthand", "righthand"], 60,
        string(MIpath, "BNCI2014004-Train.zip/content")),
    
    DBMeta("BNCI2014004-Test", :MI, ["lefthand", "righthand"], 60,
        string(MIpath, "BNCI2014004-Test.zip/content")),
    
    DBMeta("BNCI2015001", :MI, ["righthand", "feet"], 100,
        string(MIpath, "BNCI2015001.zip/content")),
    
    DBMeta("Cho2017", :MI, ["lefthand", "righthand"], 100,
        string(MIpath, "Cho2017.zip/content")),
    
    DBMeta("GrosseWentrup2009", :MI, ["lefthand", "righthand"], 150,
        string(MIpath, "GrosseWentrup2009.zip/content")),
    
    DBMeta("Lee2019MI", :MI, ["lefthand", "righthand"], 50,
        string(MIpath, "Lee2019MI.zip/content")),
    
    DBMeta("PhysionetMI-T2", :MI, ["lefthand", "righthand"], 18,
        string(MIpath, "PhysionetMI-T2.zip/content")),
    
    DBMeta("PhysionetMI-T4", :MI, ["bothhands", "feet"], 18,
        string(MIpath, "PhysionetMI-T4.zip/content")),
    
    DBMeta("Schirrmeister2017", :MI, ["lefthand", "righthand", "feet", "rest"], 120,
        string(MIpath, "Schirrmeister2017.zip/content")),
    
    DBMeta("Shin2017A", :MI, ["lefthand", "righthand"], 10,
        string(MIpath, "Shin2017A.zip/content")),
    
    DBMeta("Weibo2014", :MI, ["lefthand", "righthand", "bothhands", "feet", "rest"], 70,
        string(MIpath, "Weibo2014.zip/content")),
    
    DBMeta("Zhou2016", :MI, ["lefthand", "righthand", "feet"], 45,
        string(MIpath, "Zhou2016.zip/content")),

    # ==== P300 DATABASES ====
    DBMeta("bi2012-T", :P300, ["target", "nontarget"], 126,
        string(P300path, "bi2012-T.zip/content")),
    
    DBMeta("bi2012-O", :P300, ["target", "nontarget"], 49,
        string(P300path, "bi2012-O.zip/content")),
    
    DBMeta("bi2013a-NAT", :P300, ["target", "nontarget"], 80,
        string(P300path, "bi2013a-NAT.zip/content")),
    
    DBMeta("bi2013a-NAO", :P300, ["target", "nontarget"], 26,
        string(P300path, "bi2013a-NAO.zip/content")),
    
    DBMeta("bi2013a-AT", :P300, ["target", "nontarget"], 80,
        string(P300path, "bi2013a-AT.zip/content")),
    
    DBMeta("bi2013a-AO", :P300, ["target", "nontarget"], 24,
        string(P300path, "bi2013a-AO.zip/content")),
    
    DBMeta("bi2014a", :P300, ["target", "nontarget"], 74,
        string(P300path, "bi2014a.zip/content")),
    
    DBMeta("bi2014b", :P300, ["target", "nontarget"], 24,
        string(P300path, "bi2014b.zip/content")),
    
    DBMeta("bi2015a-1", :P300, ["target", "nontarget"], 54,
        string(P300path, "bi2015a-1.zip/content")),
    
    DBMeta("bi2015a-2", :P300, ["target", "nontarget"], 54,
        string(P300path, "bi2015a-2.zip/content")),
    
    DBMeta("bi2015a-3", :P300, ["target", "nontarget"], 54,
        string(P300path, "bi2015a-3.zip/content")),
    
    DBMeta("BNCI2014009", :P300, ["target", "nontarget"], 96,
        string(P300path, "BNCI2014009.zip/content")),
    
    DBMeta("BNCI2015003-Train", :P300, ["target", "nontarget"], 75,
        string(P300path, "BNCI2015003-Train.zip/content")),
    
    DBMeta("BNCI2015003-Test", :P300, ["target", "nontarget"], 75,
        string(P300path, "BNCI2015003-Test.zip/content")),
    
    DBMeta("Cattan-PC", :P300, ["target", "nontarget"], 120,
        string(P300path, "Cattan-PC.zip/content")),
    
    DBMeta("Cattan-VR", :P300, ["target", "nontarget"], 120,
        string(P300path, "Cattan-VR.zip/content")),
    
    DBMeta("EPFLP300-1", :P300, ["target", "nontarget"], 20,
        string(P300path, "EPFLP300-1.zip/content")),
    
    DBMeta("EPFLP300-2", :P300, ["target", "nontarget"], 20,
        string(P300path, "EPFLP300-2.zip/content")),
    
    DBMeta("EPFLP300-3", :P300, ["target", "nontarget"], 21,
        string(P300path, "EPFLP300-3.zip/content")),
    
    DBMeta("EPFLP300-4", :P300, ["target", "nontarget"], 20,
        string(P300path, "EPFLP300-4.zip/content")),
    
    DBMeta("EPFLP300-5", :P300, ["target", "nontarget"], 21,
        string(P300path, "EPFLP300-5.zip/content")),
    
    DBMeta("EPFLP300-6", :P300, ["target", "nontarget"], 20,
        string(P300path, "EPFLP300-6.zip/content")),
    
    DBMeta("Lee2019_ERP-Train", :P300, ["target", "nontarget"], 330,
        string(P300path, "Lee2019_ERP-Train.zip/content")),
    
    DBMeta("Lee2019_ERP-Test", :P300, ["target", "nontarget"], 360,
        string(P300path, "Lee2019_ERP-Test.zip/content")),
]

# Filters the database catalog according to paradigm, classes and/or minimum number of trials.
function filterDB(
    paradigm::Union{Symbol, Nothing}=nothing;
    classes::Union{Vector{String}, Nothing}=nothing,
    minTrials::Union{Int64, Nothing}=nothing
)
    return filter(DB_CATALOG) do db
        (paradigm === nothing || db.paradigm == paradigm) &&
        (classes === nothing || all(c -> c in db.classes, classes)) &&
        (minTrials === nothing || db.minTrials ≥ minTrials)
    end
end


#=
function safe_download(url, localpath)
    open(localpath, "w") do io
        download(url, io)
    end
end
=#

# Downloads, extracts and organizes a list of databases into a local folder, with a progress bar.
function _download(dbs, basepath_root, delete_zip, write_path_in_Eegle)

    write_path = true # will be set to false once the path for the corpus has been written in Eegle's directory

    # delete zip files with the same name as databases (possible incomplete downloads)
    for db in dbs
        basepath = joinpath(basepath_root, CORPUS_DIR, string(db.paradigm))
        zipfile = joinpath(basepath, ".zip")
        isfile(zipfile) && rm(zipfile)
    end

    # check if a folder with the same same as the database exists in destination directory.
    # notify the user about the databased for which the download is to be skipped
    n = 0
    skipped = String[]
    for db in dbs
        basepath = joinpath(basepath_root, CORPUS_DIR, string(db.paradigm))
        dbexists = isdir(joinpath(basepath, db.name))
        dbexists && push!(skipped, db.name)
        n += Int(dbexists)
        n == 1 && println() 
    end
    if length(skipped)>0
        sleep(0.5)
        println()
        println(titleFont, "The download of the following databases has been skipped as a folder with the same name exists already in the destination directory: ", defaultFont)
        for d in eachindex(skipped)
            print(greyFont, d,  defaultFont)
            d < length(skipped) && print(", ")
        end
        # println()
    end

    ndl = length(dbs) - n # number of downloads to be done

    println()
    sleep(0.5)
    if ndl>0
        println(titleFont, "\nEegle is downloading the FII BCI corpus", defaultFont)
        println(greyFont, "You can keep using julia in the meanwhile,", defaultFont)
        println(greyFont, "while killing the REPL will interrupt the process.", defaultFont)
        print("\rDownload progress: [", "#"^0, " "^ndl, "] terminated 0 of $(ndl)…")
        flush(stdout)
    else
        println(titleFont, "No database has been downloaded.", defaultFont)
        return nothing
    end

    # download, unzip and delete zip
    j = 0 # make the index globally visible, otherwise it catches an UndefVarError.
    for db in dbs
        basepath = joinpath(basepath_root, CORPUS_DIR, string(db.paradigm))
        isdir(joinpath(basepath, db.name)) && continue # skip download

        # Actual downloading
        j += 1
        mkpath(basepath) 

        try
            zippath = joinpath(basepath, string(db.name * ".zip"))
            #outdir  = joinpath(basepath, string(db.name))

            # --- Download ---
            #@info "Downloading $(db.name) ..."
            if !isurl(db.url)
                error("downloadDB: Invalid URL format: $(db.url)")
            end

            Downloads.download(db.url, zippath; timeout = 10800)

            print("\rExtracting $(j) of $(ndl)…                                                  ")
            flush(stdout)

            # --- ZIP Extraction ---
            reader = ZipFile.Reader(zippath)
            try
                for f in reader.files
                    dest = joinpath(basepath, f.name)
                    if endswith(f.name, "/")
                        mkpath(dest)
                        continue
                    end
                    mkpath(dirname(dest))
                    write(dest, read(f))
                end
            finally
                close(reader)
            end

            delete_zip && rm(zippath; force=true)

            print("\rDownload progress: [", "#"^j, " "^(ndl-j), "] terminated $(j) of $(ndl)…")
            flush(stdout)

            # write the path where the DBs are downloaded in the Eegle package .julia folder
            # if at least one DB has been downloaded
            if write_path && write_path_in_Eegle 
                write_in_Eegle_package(basepath_root, true)
                write_path = false
            end
        catch e
            println(" \n ")
            @error "Error downloading $(db.name): $e"
            if j<ndl 
                println();
                println("Trying to download next database…")
                print("\rDownload progress: [", "#"^j, " "^(ndl-j), "] terminated $(j) of $(ndl)…")
                flush(stdout)
                continue
            end
        end
    end

    println(titleFont, "\rDownload process terminated.                                               ", defaultFont)
end

# Saves in Eegle’s folder the path where the corpus was downloaded.
function write_in_Eegle_package(download_path, overwrite)
    
    if isdir(EegleDir)
        path = joinpath(download_path, CORPUS_DIR)
        path = replace(path, '\\' => '/')
        writeASCII([path], FII_BCI_CORPUS_PATHFILE; overwrite = overwrite)
        #println()
        # @info "The path to the FII BCI Corpus has been written in the Eegle installation directory. You can now call function `Eegle.Database.selectDB` without providing a directory for the databases" path
    else
        @error "Eegle package not found."
    end
end

# Returns the stored corpus path from Eegle’s internal configuration file.
function _dirFII() 
    file = FII_BCI_CORPUS_PATHFILE
    isfile(file) || (return nothing)
    path = normpath(readlines(FII_BCI_CORPUS_PATHFILE)[1])
    isdir(path) || (return nothing)
    return path
end
