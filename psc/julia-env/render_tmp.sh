#!/usr/bin/env bash
set -eu

TMP_MODULE_DIR=${__PREFIX__}/tmp/modules

pushd ${__DIR__}
    mkdir -p ${TMP_MODULE_DIR}

    ${__PREFIX__}/opt/bin/simple-templates.ex                        \
        --overwrite "{\"julia_module_path\": \"${TMP_MODULE_DIR}\"}" \
        --chmod "g+rX,o+rX,g-w,o-w" --chmod-basename                 \
        templates/module_template.lua                                \
        templates/settings.toml                                      \
        "{{{julia_module_path}}}/{{module_name}}/cuda{{{cuda_version}}}-opmi{{{mpi_version}}}.lua"
popd
