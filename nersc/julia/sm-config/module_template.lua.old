help([[
Julia: A flexible dynamic language, appropriate for scientific and numerical computing, with performance comparable to traditional statically-typed languages
For information about using Python at NERSC, please see our documentation:
https://docs.nersc.gov/development/languages/julia/
]])

whatis("Name: julia")
whatis("Version: {{{VERSION}}}")
whatis("URL: https://docs.nersc.gov/development/languages/julia/")

prepend_path("PATH", "{{{JULIA_PATH_2}}}")
prepend_path("PATH", "{{{JULIA_PATH_1}}}")

local JULIA_LOAD_PATH = ":{{{JULIA_LOAD_PATH_PREFIX}}}/" .. os.getenv("PE_ENV"):lower()
append_path("JULIA_LOAD_PATH", JULIA_LOAD_PATH)

-- workaround: https://github.com/JuliaLang/julia/issues/53339
setenv("JULIA_SSL_CA_ROOTS_PATH", "/etc/ssl/ca-bundle.pem")
