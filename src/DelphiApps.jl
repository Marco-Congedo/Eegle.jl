# v 0.1 Nov 2020
# Part of the Eegle.jl package.
# Copyright Marco Congedo, CNRS, University Grenoble Alpes.

module DelphiApps

using LinearAlgebra
using Eegle.InOut

# ? ¤ CONTENT ¤ ? #

# FUNCTIONS:
# eegPlot  | open en EEG file in ICoN.exe
# erpPlot  | open en EEG file with stimulations (e.g., ERPs) in CSTP.exe
# topoPlot | Draw topographic maps using TopoMpas.exe

Delphi5path=ispath(homedir()*"\\Delphi5\\") ? homedir()*"\\Delphi5\\" :
            homedir()*"\\Borland\\Delphi5\\"
#Delphi5path=joinpath(@__DIR__, "DelphiApps")

const TopoMapsDir = Delphi5path*"Projects\\@Julia\\TopoMaps"
const ICoNmaxDataSize=100000000000000 # 3573518 tested: OK
const ICoNdir=Delphi5path*"\\Projects\\@julia\\WavesEditor"
const CSTPdir=Delphi5path*"\\Projects\\@julia\\CSTP"

export eegPlot,
       erpPlot,
       topoPlot


# Open EEG data with ICoN. This Write an EEG data matrix into a text file.
# The data is written as ICoNdir*"\\EEG files\\@julia.txt"
# A file "@julia.dim" is written in the same directory with the # of samples and
# # of electrodes for allowing ICoN to read the file more efficently (optional).
# A vector of Strings must be passed as argument `sensors`. The correspodning
# Sensor Array File will be written as ICoNdir*"\\Electrodes\\@julia.txt.
# `SamplesRange` is an optional UnitRange delimiting the samples to be written.
# A title can be given to the plot using keyword "title".
# If optional keyword argument `msg` is not empty, print `msg` on exit
# If you change location of the ICoN executable, update the `ICoNdir` directory
# at the top of this module.
function eegPlot(X::Matrix{T}, sensors::Vector{String};
                 samplesRange::UnitRange=1:size(X, 1),
                 title::String="",
                 msg::String="") where T <: Real

    if !isfile(ICoNdir*"\\ICoN.exe")
       @error "Eegle.DelphiApps, function `eegPlot`: application ICoN.exe not found at " ICoNdir
       return nothing
    end

    dataFile=ICoNdir*"\\EEG files\\@julia.txt"
    sensorsFile=ICoNdir*"\\Electrodes\\@julia.txt"
    titleFile=ICoNdir*"\\ICoN Settings\\Title.txt"

    r, ne=samplesRange, size(X, 2)
    length(r)*ne<ICoNmaxDataSize ? range=r : range=r[1]:r[1]+ICoNmaxDataSize÷ne-1

    # write `dim` file
    writeDims(splitext(dataFile)[1]*".dim", (length(range), ne))

    # write EEG data for ICoN
    writeASCII(X, dataFile; samplesRange=range, overwrite=true)

    # write Sensor Array File
    writeSensorArray(sensorsFile, sensors)

    # write title file is `title` is non-empty, otherwise delete the
    # old title file if there is one
    isempty(title) && isfile(titleFile) && (rm(titleFile))
    !isempty(title) && writeTitle(titleFile, title)

    # IcON needs to have the working directory in its folder
    currentDir=pwd()
    cd(ICoNdir)
    run(`$(ICoNdir*"\\ICoN.exe")`, wait=false)
    cd(currentDir) #reset the old working directory
end


# Open EEG data `X` with CSTP. The following arguments must be provided:
# `sr`: sampling rate
# `wl`: window length, i.e., the duraction of ERP windows (see below)
# `offset`: starting point of ERP is at the stimulations + offset (see below)
# `lowPass`: the low-pass filter applied to the data, as an integer.
# `sensors`: the vector of electrode leads as strings, as in `eegPlot`.
# `stim`: the vector of stimulations for each sample (0, 1, 2...).
#     0 means no stimulation and 1, 2... are the ERP classes
# `clabels`: the labels (strings) associated with the positive elements in `stim`
# `mask`: if ≠ `()`, this is a 2-tuple with the following elements:
#     - a vector of electrode leads defining the mask (strings). They must exist in `sensors`
#     - a 2-tuple of integers with the starting and ending sample defining the mask
function erpPlot(X       :: Matrix{T},
                 sr      :: S,
                 wl      :: S,
                 offset  :: S,
                 lowPass :: S,
                 sensors :: Vector{String},
                 stim    :: Vector{S},
                 clabels :: Vector{String};
                 mask    :: Tuple = (),
                 msg::String="") where {T<:Real, S<:Int}

  if !isfile(CSTPdir*"\\CSTP.exe")
     @error "DelphiApplication.erpPlot function: application CSTP.exe not found at " CSTPdir
     return nothing
  end

  dataFile=CSTPdir*"\\@juliaData.txt"
  sensorsFile=CSTPdir*"\\@juliaEle.txt"
  stimFile=CSTPdir*"\\@juliaStim.txt"

  # write EEG data for CSTP
  writeASCII(X, dataFile; overwrite=true)

  # write Sensor Array File
  writeSensorArray(sensorsFile, sensors)

  # write stimulation file
  clab=[join(split(l)) for l ∈ clabels]
  io = open(stimFile, "w")
  for i=1:length(stim) if stim[i]≠0 write(io, string(i)*" "*string(offset)*" "*clab[stim[i]]*"\r\n") end end
  close(io)

  # write the LastSettings.txt file
  io = open(CSTPdir*"\\LastSettings.txt", "w")
  write(io, "CSTP v0.1 @julia"*"\r\n")
  write(io, dataFile*"\r\n")
  write(io, "1"*"\r\n")
  write(io, "$(size(X, 1))"*"\r\n")
  write(io, stimFile*"\r\n")
  write(io, sensorsFile*"\r\n")
  write(io, string(sr)*"\r\n")
  write(io, string(wl)*"\r\n")
  write(io, string(lowPass)*"\r\n")
  if !isempty(mask)
     write(io, "True"*"\r\n")
     write(io, "$(length(mask[1]))"*"\r\n")
     for e in mask[1] write(io, e*"\r\n") end
     write(io, "$(first(mask[2]))"*"\r\n")
     write(io, "$(last(mask[2]))"*"\r\n")
  else
     write(io, "False"*"\r\n")
  end
  close(io)

 run(`$(CSTPdir*"\\CSTP.exe")`, wait=false)
end


# Open topographic maps with the "TopoMaps.exe" application.
# Up to 128 maps can be passed in several ways. `X` can be:
#   a vector of real numbers: a single map will be created
#   a matrix or real numbers: each row will make a map
#   a real `Hermitian` matrix: a single map will be created from the diagonal
#   a vector of real `Hermitian` matrix: each diagonal part will make a map.
# Optional keyword arguments:
# `title` title for the topographic plot to be produced
# `mapLabels` is a vector of labels for each map
# `monopolar` if true positive and negative values are plotted with the same
#    color, otherwise they are plotted using two different colors.
# `scaleMode` if it is equal to `local`, each map will be scaled
# to its own maximum. If it equal to `:global`(default) all maps are scaled
# to the global maximum across all.
function topoPlot(X::Union{Vector{T}, Matrix{T}, Hermitian, Vector{Hermitian}},
                  sensors::Vector{String};
                  title::String=" ",
                  mapLabels::Vector{String}=[],
                  monopolar::Bool=true,
                  scaleMode::Symbol=:global) where T<:Real

    if !isfile(TopoMapsDir*"\\TopoMaps.exe")
       @error "Eegle.DelphiApps, function `topoPlot`: Application TopoMaps.exe not found at " TopoMapsDir
       return nothing
    end

    if     X isa Hermitian           Y=Matrix{eltype(real(X))}(diag(real(X))')
    elseif X isa Array{Hermitian, 1} Y=[real(X[i][j, j]) for i=1:length(X), j=1:size(X[1], 1)]
    elseif X isa Vector              Y=Matrix{eltype(X)}(X')
    else                             Y=X
    end

    # write Sensor Array File
    writeSensorArray(TopoMapsDir*"\\TopoElectrodes.txt", sensors)

    # write data File for TopoMaps.exe
    writeASCII(Y, TopoMapsDir*"\\TopoData.txt"; overwrite=true)

    # write data dimension File for TopoMaps.exe
    writeDims(TopoMapsDir*"\\TopoDataDim.txt", size(Y))

    # write Labels File for TopoMaps.exe
    io = open(TopoMapsDir*"\\TopoLabels.txt", "w")
       for s in mapLabels write(io, s*"\r\n") end
    close(io)

    # write Settings File for TopoMaps.exe
    io = open(TopoMapsDir*"\\TopoSettings.txt", "w")
       write(io, "$(string(monopolar))"*"\r\n")
       write(io, "$(title)"*"\r\n")
       write(io, "$(string(scaleMode))"*"\r\n")
    close(io)

    run(`$(TopoMapsDir*"\\TopoMaps.exe")`, wait=false)
    # try also run(`cmd /c start $(TopoMapsDir*"\\TopoMaps.exe")`)
end


##### INTERNAL FUNCTIONS ######

# write Sensor Array File to be read by executable applications.
# if the file exists it will be overwritten.
function writeSensorArray(fileName::String, sensors::Vector{String})
    io = open(fileName, "w")
    write(io, "$(length(sensors))"*"\r\n")
    for s in sensors write(io, s*"\r\n") end
    close(io)
end

# write Data Dimension File to be read by executable applications.
function writeDims(fileName::String, t::Tuple)
   io = open(fileName, "w")
      for i in t write(io, "$(i)"*"\r\n") end
   close(io)
end


function writeTitle(fileName::String, title::String)
   io = open(fileName, "w")
      write(io, title)
   close(io)
end


end
