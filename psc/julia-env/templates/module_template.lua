help([[
Environment settings for the Julia language at PSC
]])

whatis("Name: {{{module_name}}}")
whatis("Version: cuda{{{cuda_version}}}-ompi{{{mpi_version}}}")

depends_on("cuda/{{{cuda_version}}}")
depends_on("openmpi/{{mpi_version}}-{{{toolchain}}}")

setenv("__JULIA_COMPILER", "{{{toolchain}}}")
setenv("__JULIA_CUDA_VERSION", "{{{cuda_version}}}")
setenv("__JULIA_MPI_VERSION",  "{{{mpi_version}}}")
