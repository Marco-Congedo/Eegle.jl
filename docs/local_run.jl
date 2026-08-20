# This script allows to visualize the documentation once make.jl has executed.
# LiveServer.jl must be installed in julia default environment.


println("Done.\n")
@info "To see the documentation using LiveServer, CTRL+click on the link here below:"
println("")
cd(joinpath(@__DIR__, "build")); 
using LiveServer; 
LiveServer.serve();
