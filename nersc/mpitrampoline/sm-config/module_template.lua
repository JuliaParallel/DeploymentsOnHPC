help([[
A forwarding MPI implementation that can use any other MPI implementation via an
MPI ABI.
https://github.com/eschnett/MPItrampoline
]])

whatis("Name: MPItrampoline")
whatis("Version: {{{INSTALL_VERSION}}}")
whatis("URL: https://github.com/eschnett/MPItrampoline")

prepend_path("PATH", "{{{MPITRAMPOLINE_PATH}}}/bin")
prepend_path("LD_LIBRARY_PATH", "{{{MPITRAMPOLINE_PATH}}}/lib")
