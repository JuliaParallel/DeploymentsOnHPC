help([[
Julia: Julia installer and version multiplexer

For information about using Julia at NERSC, please see our documentation:
https://docs.nersc.gov/development/languages/julia/
]])

whatis("Name: juliaup")
whatis("Version: {{{INSTALL_VERSION}}}")
whatis("URL: https://github.com/JuliaLang/juliaup")

prepend_path("PATH", "{{{BIN_PATH}}}")
append_path("PATH", "{{{SCRIPT_PATH}}}")
