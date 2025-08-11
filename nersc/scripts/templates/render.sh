#!/usr/bin/env bash
set -eu
pushd ${__DIR__}

#-------------------------------------------------------------------------------
# Set path of the scripts
#-------------------------------------------------------------------------------
case ${__MODE__} in
    global) RESOURCE_DIR="/global/common/software/nersc9/julia"
            ;;
    local)  RESOURCE_DIR=${__LOCAL_PATH__}
            ;;
    *)      echo "__MODE__=${__MODE__} is not a valid setting"
            popd
            exit 1
            ;;
esac
SCRIPT_DIR=${RESOURCE_DIR}/scripts
mkdir -p ${SCRIPT_DIR}

#-------------------------------------------------------------------------------
# Helper scripts for the NERSC Julia install
#-------------------------------------------------------------------------------

case ${__MODE__} in
global)
    ${__PREFIX__}/opt/bin/simple-templates.ex              \
        --chmod "g+rx,o+rx,g-w,o-w" --chmod-basename --dir \
        bin                                                \
        settings.toml                                      \
        "${SCRIPT_DIR}"
    ;;

local)
    ${__PREFIX__}/opt/bin/simple-templates.ex                       \
        --overwrite "{\"nersc_resource_dir\": \"${RESOURCE_DIR}\"}" \
        --chmod "g+rx,o+rx,g-w,o-w" --chmod-basename --dir          \
        bin                                                         \
        settings.toml                                               \
        "${SCRIPT_DIR}"
    ;;

    *) echo "__MODE__=${__MODE__} is not a valid setting"
       popd
       exit 1
       ;;
esac
popd
