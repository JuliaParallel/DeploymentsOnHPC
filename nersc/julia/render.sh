#!/usr/bin/env bash
set -eu

pushd ${__DIR__}
case ${__MODE__} in
global)

    ${__PREFIX__}/opt/bin/simple-modules.ex sm-config/

    ${__PREFIX__}/opt/bin/simple-templates.ex              \
        --chmod "g+rX,o+rX,g-w,o-w" --chmod-basename       \
        templates/1.0.lua                                  \
        templates/settings.toml                            \
        "{{{julia_module_path}}}/{{module_name}}/1.0.lua"
    ;;

local)
    DESTINATION=${__LOCAL_PATH__}
    LOC_MODULE_DIR=${DESTINATION}/modules

    mkdir -p ${DESTINATION}

    ${__PREFIX__}/opt/bin/simple-modules.ex sm-config/    \
        --destination=${DESTINATION}                      \
        --modules=${LOC_MODULE_DIR}

    ${__PREFIX__}/opt/bin/simple-templates.ex                        \
        --overwrite "{\"julia_module_path\": \"${LOC_MODULE_DIR}\"}" \
        --chmod "g+rX,o+rX,g-w,o-w" --chmod-basename                 \
        templates/1.0.lua                                            \
        templates/settings.toml                                      \
        "{{{julia_module_path}}}/{{module_name}}/1.0.lua"
    ;;

*)
    echo "__MODE__=${__MODE__} is not a valid setting"
    popd
    exit 1
    ;;
esac
popd
