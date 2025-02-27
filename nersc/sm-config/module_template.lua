help([[
Julia: A flexible dynamic language, appropriate for scientific and numerical
computing, with performance comparable to traditional statically-typed
languages For information about using Python at NERSC, please see our
documentation:
https://docs.nersc.gov/development/languages/julia/
]])

whatis("Name: julia")
whatis("Version: {{{INSTALL_VERSION}}}")
whatis("URL: https://docs.nersc.gov/development/languages/julia/")

prepend_path("PATH", "{{{JULIA_PATH_2}}}")
prepend_path("PATH", "{{{JULIA_PATH_1}}}")

local mpi_type = os.getenv("JULIA_MPI")
if nil~=mpi_type then mpi_type = mpi_type:lower() end

if "mpich" == mpi_type then
    local JULIA_LOAD_PATH = ":{{{JULIA_LOAD_PATH_PREFIX}}}/" .. mpi_type
    append_path("JULIA_LOAD_PATH", JULIA_LOAD_PATH)
end

-- workaround: https://github.com/JuliaLang/julia/issues/53339
setenv("JULIA_SSL_CA_ROOTS_PATH", "/etc/ssl/ca-bundle.pem")
