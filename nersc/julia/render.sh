#!/usr/bin/env bash
set -eu

pushd ${__DIR__}
    ${__PREFIX__}/opt/bin/simple-modules.ex sm-config

    ${__PREFIX__}/opt/bin/simple-templates.ex                   \
        templates/latest.lua                                    \
        templates/settings.toml                                 \
        "{{{julia_module_path}}}/{{module_name}}/latest.lua"

    chmod -R o+r /global/common/software/nersc9/julia/modules
popd

