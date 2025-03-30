help([[
A forwarding MPI implementation that can use any other MPI implementation via
an MPI ABI.
https://github.com/eschnett/MPItrampoline
]])


local function remove_by_value(list, value)
    local idx = nil
    for i, v in ipairs(list) do
         if v == value then
             idx = i
             break  -- Stop iterating once the value is found
         end
    end
    table.remove(list, idx)
end


whatis("Name: MPItrampoline")
whatis("Version: {{{INSTALL_VERSION}}}")
whatis("URL: https://github.com/eschnett/MPItrampoline")

local mpi_settings = {
    aocc    = {pe="aocc",   dep={},          cc="cc",    mpirun="srun"},
    cray    = {pe="cray",   dep={},          cc="cc",    mpirun="srun"},
    gnu     = {pe="gnu",    dep={},          cc="cc",    mpirun="srun"},
    intel   = {pe="intel",  dep={},          cc="cc",    mpirun="srun"},
    nvidia  = {pe="nvidia", dep={},          cc="cc",    mpirun="srun"},
    llvm    = {pe="llvm",   dep={"mpich"},   cc="mpicc", mpirun="srun"},
    openmpi = {pe="gnu",    dep={"openmpi"}, cc="mpicc", mpirun="srun --mpi=pmix"}
}

local all_pes = {
    "PrgEnv-aocc", "PrgEnv-cray", "PrgEnv-gnu", "PrgEnv-intel",
    "PrgEnv-nvidia", "PrgEnv-llvm"
}
-- remove the dependent PrgEnv => now `all_pes` is a list if conflicting PrgEnvs
remove_by_value(all_pes, "PrgEnv-" .. mpi_settings.{{{INSTALL_VARIANT}}}.pe)
conflict(table.unpack(all_pes))

local all_mpis = {"mpich", "openmpi"}
if #(mpi_settings.{{{INSTALL_VARIANT}}}.dep) > 0 then
    remove_by_value(all_mpis, mpi_settings.{{{INSTALL_VARIANT}}}.dep)
end
conflict(table.unpack(all_mpis))

-- be sure to specify dependencies after conflicts
depends_on("PrgEnv-" .. mpi_settings.{{{INSTALL_VARIANT}}}.pe)

mpi_wrapper_ver = {}
mpi_wrapper_ver["5.5.0"] = "2.11.0"
-- mpiwrapper dependency
depends_on(
    "mpiwrapper/" ..
    mpi_wrapper_ver["{{{INSTALL_VERSION}}}"] .. "-{{{INSTALL_VARIANT}}}"
)


prepend_path("PATH", "{{{MPITRAMPOLINE_PATH}}}/bin")
prepend_path("LD_LIBRARY_PATH", "{{{MPITRAMPOLINE_PATH}}}/lib")
prepend_path("LD_LIBRARY_PATH", "{{{MPITRAMPOLINE_PATH}}}/lib64")
setenv("MPITRAMPOLINE_CC", mpi_settings.{{{INSTALL_VARIANT}}}.cc)
setenv("MPITRAMPOLINE_MPIEXEC", mpi_settings.{{{INSTALL_VARIANT}}}.mpirun)
