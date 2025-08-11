#!/usr/bin/env bash
set -eu
pushd ${__DIR__}

SITE_NAME="nersc-julia"

#-------------------------------------------------------------------------------
# Set path of the kernels
#-------------------------------------------------------------------------------
case ${__MODE__} in
    global) KERNEL_DIR="/global/common/software/nersc9/julia/kernels"
            ;;
    local)  KERNEL_DIR=${__LOCAL_PATH__}/kernels
            ;;
    *)      echo "__MODE__=${__MODE__} is not a valid setting"
            popd
            exit 1
            ;;
esac
mkdir -p ${KERNEL_DIR}

#-------------------------------------------------------------------------------
# Render Kernels
#-------------------------------------------------------------------------------

case ${__MODE__} in
global)
    ${__PREFIX__}/opt/bin/simple-templates.ex                         \
        --dir --resource "^jupyter/.*.png$"                           \
        --chmod "g+rX,o+rX,g-w,o-w" --chmod-basename                  \
        jupyter                                                       \
        settings.toml                                                 \
        "${KERNEL_DIR}/rendered/${SITE_NAME}-{{julia_thread_ct}}-{{}}{{#use_latest}}-beta{{/use_latest}}"
    ;;
local)
    ${__PREFIX__}/opt/bin/simple-templates.ex                         \
        --overwrite "{\"nersc_resource_dir\": \"${KERNEL_DIR}\"}"     \
        --dir --resource "^jupyter/.*.png$"                           \
        --chmod "g+rX,o+rX,g-w,o-w" --chmod-basename                  \
        jupyter                                                       \
        settings.toml                                                 \
        "${KERNEL_DIR}/rendered/nersc-julia-{{julia_thread_ct}}-{{julia_version}}{{#use_latest}}-beta{{/use_latest}}"
    ;;

    *) echo "__MODE__=${__MODE__} is not a valid setting"
       popd
       exit 1
       ;;
esac

#-------------------------------------------------------------------------------
# Copy some helper resources/scripts
#-------------------------------------------------------------------------------

cp    ${__DIR__}/../bootstrap.jl ${KERNEL_DIR}/
cp -r ${__DIR__}/../user         ${KERNEL_DIR}/
cp -r ${__DIR__}/../julia-user   ${KERNEL_DIR}/

chmod -R o+rX ${KERNEL_DIR}

popd
