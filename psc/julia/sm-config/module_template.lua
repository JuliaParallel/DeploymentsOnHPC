help([[
Julia: A flexible dynamic language, appropriate for scientific and numerical
computing, with performance comparable to traditional statically-typed
languages. For more information see: https://julialang.org/
]])

whatis("Name: julia")
whatis("Version: {{{INSTALL_VERSION}}}")
whatis("URL: https://julialang.org/")

depends_on("juliaup")
prepend_path("PATH", "{{{JULIA_PATH}}}")
