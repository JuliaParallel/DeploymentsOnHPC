#!/usr/bin/env bash
set -eu

pushd ${__DIR__}
    ${__PREFIX__}/opt/bin/simple-modules.ex sm-config

    ${__PREFIX__}/opt/bin/simple-templates.ex              \
        --chmod "g+rX,o+rX,g-w,o-w"                        \
        templates/1.0.lua                                  \
        templates/settings.toml                            \
        "{{{julia_module_path}}}/{{module_name}}/1.0.lua"
popd

