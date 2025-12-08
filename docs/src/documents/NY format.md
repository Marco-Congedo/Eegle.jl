# NY format

The NY (New York) format is specifically conceived for BCI data. It holds data and metadata and allow convenient handling of BCI data in any programming language.

When converted to NY format, the EEG data is stored in microvolts (*µ*V), as it is the standard in the EEG community.

The NY format consists of two files with same name and different extension:

- **`.npz file`**: contains the raw data and [stimulation vector](@ref). The *.npz* file is the standard [NumPy](https://numpy.org/) compressed archive format, which can store multiple arrays in a single file using ZIP compression. The file contains two arrays:
  - `X`: the``N×T`` EEG data matrix, where ``N`` and ``T`` denotes the number of samples and channels, respectively, in Float32 *µ*V format.
  - `stim`: the stimulation vector holding the ``T`` tags for the samples.

  This format is natively supported in Python through NumPy and easily readable in Julia via the [NPZ.jl](https://github.com/fhs/NPZ.jl) package.

- **`.yml file`**: stores metadata offering a comprehensive description of the dataset's characteristics — see [YAML Structure](yamlstruct.md). 

NY files in **Eegle** are read using function [`readNY`](@ref), which creates an [`EEG`](@ref) structure holding both the data and the metadata.

## Converters

All scripts for data conversion between formats (Base repository/MOABB to CSV and CSV to NY), tailored to each dataset's requirements, are available in the 'Converters' folder and in a [GitHub repository](https://github.com/FhmDmi/Eegle-Tools/tree/master/Converters).

The following scripts facilitate the data pre-processing workflow:

- **MOABB/BASE to CSV**: Python scripts with extensive comments, which guide the user through the conversion process from the downloaded raw data (MOABB or original repositories) to the defined *CSV* format.
- **CSV to NY**: Python scripts with extensive comments, which guide the user through the conversion process from CSV to NY format.
