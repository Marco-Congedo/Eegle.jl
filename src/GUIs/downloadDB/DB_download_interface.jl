using Bonito
using ZipFile
using NativeFileDialog
using IsURL 
using JSON
using HTTP
import Bonito.TailwindDashboard as D

# Default folder where downloaded databases are stored if none is specified.
DEFAULT_DOWNLOAD_DIR = homedir()

include("db_catalog.jl")
include("styles.jl")


# Launches the interactive GUI to browse, filter and download databases from the FII BCI corpus.
function _downloadDB()

    app = App() do session

        ### Paradigm
        dropdown = D.Dropdown("Paradigm", [:MI, :P300])

        ### minTrials
        numberinput = D.TextField("0")

        mintrials = DOM.div(
            numberinput,
            DOM.span("Minimum Trials per class (enter an Integer)"; style= number_inuput_style);
        )

        # Create checkboxes for current paradigm
        function create_checks(options)
            [ (cb=D.Checkbox("", false), label=opt) for opt in options ]
        end

        # Initial checks
        checks = create_checks(MI_CLASSES)

        checkbox_widgets = [ D.FlexRow(c.cb, DOM.span(c.label; style=Styles("font-weight"=>"600", "font-size"=>"16px")); style=Styles("align-items"=>"center", "gap"=>"6px")) for c in checks]

        # Observable values for checkboxes
        values = map(c -> c.cb.value, checks)

        # Combined observable to track all checkbox states
        combined = map(values...) do vs...
            vs
        end

        # Observable of selected classes
        selected_classes = map(combined) do vals
            [checks[i].label for i in eachindex(vals) if vals[i]]
        end

        # Update checks when dropdown changes
        on(dropdown.value) do paradigm
            opts = paradigm == :MI ? MI_CLASSES : P300_CLASSES
            checks_new = create_checks(opts)
            # Replace old checks with new ones
            for (i, c) in enumerate(checks_new)
                checks[i] = c
            end
            # Update values observable
            for (i, c) in enumerate(checks)
                values[i][] = c.cb.value[]
            end
        end    

        # Filter DBs based on UI inputs
        filtered = map(dropdown.widget.value, numberinput.value, selected_classes) do p, t , cls
            t_int = 0
            try
                t_int = parse(Int64,t)
            catch e
                @error "Erreur d'entrée: veuillez entrer un entier"
            end
            filterDB(p; classes=(cls == [] ? nothing : cls), minTrials=t_int)
        end

        # Lets the user choose the destination folder via native OS file dialog.
        path_button = Button("Choose path "; 
                        style = path_button_style)

        path_chosen_by_user = Observable(DEFAULT_DOWNLOAD_DIR)

        on(path_button.value) do click::Bool
            if click
                folder = pick_folder()
                if folder !== nothing
                    path_chosen_by_user[] = folder
                    @info "$(folder) was chosen for data download"
                else
                    @warn "No folder was selected"
                end
            end
        end

        # Button to start the download
        download_button = Button("Download Now "; 
                        style = download_button_style)

        # Handles deletion of existing downloaded folders when enabled.
        overwrite_checkbox = D.Checkbox("Overwrite existing data ", true)

        on(download_button.value) do click::Bool
            if click
                dbs = filtered[]
                overwrite_existing_data = overwrite_checkbox.value[]
                if overwrite_existing_data
                    @info "Overwrite enabled — removing existing folders first..."
                    for db in dbs
                        floder_to_remove = joinpath(path_chosen_by_user[], "BCI_FII_Corpus", string(db.paradigm))
                        if isdir(floder_to_remove)
                            @info "Removing existing folder: $(floder_to_remove)"
                            rm(floder_to_remove; force=true, recursive=true)
                        else
                            @info "No existing data for $(db.name)"
                        end
                    end
                else
                    @info "Overwrite disabled — keeping existing data."
                end

                _download(dbs, path_chosen_by_user[], true, true)
            end
        end

        # Formats the filtered database list into a styled Bonito dashboard table.
        displayList = map(filtered) do dbs
            # Header
            header = D.FlexRow(
                DOM.div(D.Text("Name"),     style= header_style_2),
                DOM.div(D.Text("Paradigm"), style= header_style_1),
                DOM.div(D.Text("Trials"),   style= header_style_1),
                DOM.div(D.Text("Classes"),  style= header_style_2),
                style= table_header_style
            )
            
            # Rows
            rows = [ D.FlexRow(
                        DOM.div(D.Text(db.name),                  style= rows_style_2),
                        DOM.div(D.Text(db.paradigm),              style= rows_style_1),
                        DOM.div(D.Text(string(db.minTrials)),     style= rows_style_1),
                        DOM.div(D.Text(join(db.classes, ", ")),   style= rows_style_2),
                        style= table_rows_style
                    ) for db in dbs ]

            # Combine header + rows with spacing
            D.FlexCol(header, rows...; style= table_style)
        end


        return DOM.div( D.FlexCol(
            DOM.br(),
            D.Title(" 📥 Eegle GUI: download the FII BCI Corpus", style = title_style),
            DOM.br(),
            D.FlexRow(
                D.Card(D.FlexCol(D.Title("Database options"), dropdown, mintrials, (c.cb for c in checkbox_widgets)..., "Current location on PC: ", path_chosen_by_user, path_button, overwrite_checkbox, download_button)),
                D.Card(D.FlexCol(D.Title("Selected Databases "), displayList)),
        )))
    end
end

# Downloads and extracts all files associated with a Zenodo record URL into a local destination.
function _downloadDB(url::String, dest::String = DEFAULT_DOWNLOAD_DIR)

    if !isurl(url)
        error("Eegle.Database.jl, function `downloadDB`: Invalid URL format: $url")
    end

    ## Transform the Zenodo url to JSON format
    if occursin("https://zenodo.org", url)
        url = replace(url, "https://zenodo.org" => "https://zenodo.org/api")
    else
        error("Eegle.Database.jl, function `downloadDB`: URL must be a Zenodo record")
    end

    ## Check the directory
    if !isdir(dest)
        error("Eegle.Database.jl, function `downloadDB`: invalid directory")
    end

    ## Check if the url is reachable
    resp = HTTP.get(url)
    if resp.status != 200
        error("Eegle.Database.jl, function `downloadDB`: URL not reachable (status $(resp.status))")
    end

    meta = JSON.parse(String(resp.body))

    n = length(meta["files"])
    print("\rProgress: [", "#"^0, " "^n, "] 0/$(n)")
    flush(stdout)

    for (i, file) in enumerate(meta["files"])

        filename = file["key"]
        zippath = joinpath(dest, filename)
        outdir  = joinpath(dest, replace(filename, r"\.zip$" => ""))

        download( file["links"]["self"], zippath)

        # Extraction
        mkpath(outdir)
        reader = ZipFile.Reader(zippath)
        try
            for f in reader.files
                extract_dest = joinpath(outdir, f.name)
                mkpath(dirname(extract_dest))
                write(extract_dest, read(f))
            end
        finally
            close(reader)
        end

        print("\rProgress: [", "#"^i, " "^(n-i), "] $(i)/$(n)")
        flush(stdout)
    end
    println("\nAll downloads completed successfully.")
    
end

# Sequentially downloads multiple Zenodo URLs, skipping those that fail.
function _downloadDB(urls::Vector{String}, dest::String = DEFAULT_DOWNLOAD_DIR)
    for url in urls
        try
            downloadDB(url, dest)
        catch e
            @warn "Eegle.Database.jl, function `downloadDB`: download failed for $url — skipping. Error: $e"
        end
    end
end
