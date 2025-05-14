help([[
Add the latest versions of Julia to the MODULEPATH
https://docs.nersc.gov/development/languages/julia/
]])

whatis("Name: {{{module_name}}}")
whatis("Version: latest")
whatis("URL: https://docs.nersc.gov/development/languages/julia/")

prepend_path("MODULEPATH", "{{{julia_module_path}}}")
