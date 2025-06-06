#!/usr/bin/env bash
set -eu

TMP_MODULE_DIR=${__PREFIX__}/tmp/modules

pushd ${__DIR__}
    mkdir -p ${__PREFIX__}/tmp

    ${__PREFIX__}/opt/bin/simple-modules.ex \
        sm-config/                          \
        --destination=${__PREFIX__}/tmp     \
        --modules=${TMP_MODULE_DIR}

    ${__PREFIX__}/opt/bin/simple-templates.ex                        \
        --overwrite "{\"julia_module_path\": \"${TMP_MODULE_DIR}\"}" \
        --chmod "g+rX,o+rX,g-w,o-w"                                  \
        templates/1.0.lua                                            \
        templates/settings.toml                                      \
        "{{{julia_module_path}}}/{{module_name}}/1.0.lua"
popd
