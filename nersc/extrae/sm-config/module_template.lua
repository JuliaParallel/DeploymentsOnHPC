help([[
Extrae: Extrae is the package devoted to generate Paraver trace-files for a
post-mortem analysis.
https://tools.bsc.es/extrae
]])

whatis("Name: extrae")
whatis("Version: {{{INSTALL_VERSION}}}")
whatis("URL: https://tools.bsc.es/extrae")

{{#use_dependencies}}
depends_on("PrgEnv-{{{INSTALL_VARIANT}}}")
depends_on("cudatoolkit")
{{/use_dependencies}}
{{^use_dependencies}}
-- Skipping module dependencies (disabled by `use_dependencies = false`)
{{/use_dependencies}}

prepend_path("PATH", "{{{EXTRAE_PATH}}}")
prepend_path("LD_LIBRARY_PATH", "{{{EXTRAE_PATH}}}/lib")

{{#use_shared_artifacts}}
prepend_path("PATH", "{{{EXTRAE_ROOT}}}/opt/bin")
prepend_path("LD_LIBRARY_PATH", "{{{EXTRAE_ROOT}}}/opt/lib")
{{/use_shared_artifacts}}
{{^use_shared_artifacts}}
prepend_path("PATH", "{{{EXTRAE_ROOT}}}/opt-{{{INSTALL_VARIANT}}}/bin")
prepend_path("LD_LIBRARY_PATH", "{{{EXTRAE_ROOT}}}/opt-{{{INSTALL_VARIANT}}}/lib")
{{/use_shared_artifacts}}
