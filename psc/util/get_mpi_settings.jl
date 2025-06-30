#!/usr/bin/env julia

using Pkg
Pkg.activate(joinpath(@__DIR__, "mpi_proj"))
Pkg.instantiate()


# Ensure that any pre-existing LocalPreferences.toml files are removed from the
# environment first:
local_prefs_file = joinpath(@__DIR__, "mpi_proj", "LocalPreferences.toml")
if isfile(local_prefs_file)
    @info("$(local_prefs_file) exists from previous run => deleting ")
    rm(local_prefs_file)
end


using MPIPreferences


@info "Identified the `openmpi` MPI Lmod Family"
MPIPreferences.use_system_binary(mpiexec="mpirun") 
