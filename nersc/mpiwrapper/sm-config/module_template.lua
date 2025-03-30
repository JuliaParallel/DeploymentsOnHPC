help([[
A wrapper for MPI libraries, implementing an MPI ABI
https://github.com/eschnett/MPIwrapper
]])

whatis("Name: MPIwrapper")
whatis("Version: {{{INSTALL_VERSION}}}")
whatis("URL: https://github.com/eschnett/MPIwrapper")

prepend_path("PATH", "{{{MPIWRAPPER_PATH}}}/bin")
prepend_path("LD_LIBRARY_PATH", "{{{MPIWRAPPER_PATH}}}/lib")
