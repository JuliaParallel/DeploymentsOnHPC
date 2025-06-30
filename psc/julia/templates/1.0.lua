help([[
Add the latest versions of Julia to the MODULEPATH
]])

whatis("Name: {{{module_name}}}")
whatis("Version: latest")

prepend_path("MODULEPATH", "{{{julia_module_path}}}")
