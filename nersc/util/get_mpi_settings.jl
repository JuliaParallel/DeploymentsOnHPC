#!/usr/bin/env julia

using Pkg
Pkg.activate(joinpath(@__DIR__, "mpi_proj"))
Pkg.instantiate()


using MPIPreferences


lmod_family_key = "LMOD_FAMILY_MPI"
if lmod_family_key in keys(ENV)
    mpich_family = ENV[lmod_family_key]
else
    @error "'$(lmod_family_key)' not found in environment, ensure it is set"
    exit(1)
end


if mpich_family == "cray-mpich"
    @info "Identified the `cray-mpich` MPI Lmod Family"
    MPIPreferences.use_system_binary(mpiexec="srun", vendor="cray") 
elseif mpich_family == "mpich"
    @info "Identified the `mpich` MPI Lmod Family"
    MPIPreferences.use_system_binary(mpiexec="srun") 
elseif mpich_family == "openmpi"
    @info "Identified the `openmpi` MPI Lmod Family"
    MPIPreferences.use_system_binary(mpiexec="srun --mpi=pmix") 
else
    @error "Unknown value '$(mpich_family)' for '$(lmod_family_key)'"
end
