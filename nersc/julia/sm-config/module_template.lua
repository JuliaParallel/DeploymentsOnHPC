help([[
Julia: A flexible dynamic language, appropriate for scientific and numerical
computing, with performance comparable to traditional statically-typed
languages. For information about using Julia at NERSC, please see our
documentation: https://docs.nersc.gov/development/languages/julia/
]])

whatis("Name: julia")
whatis("Version: {{{INSTALL_VERSION}}}")
whatis("URL: https://docs.nersc.gov/development/languages/julia/")

depends_on("juliaup")
prepend_path("PATH", "{{{JULIA_PATH}}}")
