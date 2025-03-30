help([[
A wrapper for MPI libraries, implementing an MPI ABI
https://github.com/eschnett/MPIwrapper
]])

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

depends_on("PrgEnv-" .. mpi_settings.{{{INSTALL_VARIANT}}}.pe)

prepend_path("PATH", "{{{MPIWRAPPER_PATH}}}/bin")
prepend_path("LD_LIBRARY_PATH", "{{{MPIWRAPPER_PATH}}}/lib")
