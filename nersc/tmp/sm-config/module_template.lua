help([[
Julia: A flexible dynamic language, appropriate for scientific and numerical computing, with performance comparable to traditional statically-typed languages
For information about using Python at NERSC, please see our documentation:
https://docs.nersc.gov/development/languages/julia/
]])

whatis("Name: julia")
whatis("Version: {{{VERSION}}}")
whatis("URL: https://docs.nersc.gov/development/languages/julia/")

prepend_path("PATH", "{{{JULIA_PATH}}}")

local JULIA_LOAD_PATH = ":{{{JULIA_LOAD_PATH_PREFIX}}}/" .. os.getenv("PE_ENV"):lower()
append_path("JULIA_LOAD_PATH", JULIA_LOAD_PATH)
