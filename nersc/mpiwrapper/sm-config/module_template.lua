help([[
A wrapper for MPI libraries, implementing an MPI ABI
https://github.com/eschnett/MPIwrapper
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


whatis("Name: MPIwrapper")
whatis("Version: {{{INSTALL_VERSION}}}")
whatis("URL: https://github.com/eschnett/MPIwrapper")


local mpi_settings = {
    aocc    = {pe="aocc",   dep={}},
    cray    = {pe="cray",   dep={}},
    gnu     = {pe="gnu",    dep={}},
    intel   = {pe="intel",  dep={}},
    nvidia  = {pe="nvidia", dep={}},
    llvm    = {pe="llvm",   dep={"mpich"}},
    openmpi = {pe="gnu",    dep={"openmpi"}}
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


prepend_path("PATH", "{{{MPIWRAPPER_PATH}}}/bin")
prepend_path("LD_LIBRARY_PATH", "{{{MPIWRAPPER_PATH}}}/lib")
setenv("MPITRAMPOLINE_LIB", "{{{MPIWRAPPER_PATH}}}/lib/libmpiwrapper.so")
