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
    ${__PREFIX__}/opt/bin/simple-templates.ex                               \
        --dir --resource "^jupyter/.*.png$"                                 \
        --chmod "u+rX,g+rX,o+rX,g-w,o-w" --chmod-basename                   \
        --chmod-overwrite "{\".*/kernel%-helper.sh$\": \"u+rx,g+rx,o+rx\"}" \
        jupyter                                                             \
        settings.toml                                                       \
        "${KERNEL_DIR}/rendered/${SITE_NAME}-{{julia_thread_ct}}-{{}}{{#use_latest}}-beta{{/use_latest}}"
    ;;
local)
    ${__PREFIX__}/opt/bin/simple-templates.ex                               \
        --overwrite "{\"nersc_resource_dir\": \"${KERNEL_DIR}\"}"           \
        --dir --resource "^jupyter/.*.png$"                                 \
        --chmod "u+rX,g+rX,o+rX,g-w,o-w" --chmod-basename                   \
        --chmod-overwrite "{\".*/kernel%-helper.sh$\": \"u+rx,g+rx,o+rx\"}" \
        jupyter                                                             \
        settings.toml                                                       \
        "${KERNEL_DIR}/rendered/nersc-julia-{{julia_thread_ct}}-{{julia_version}}{{#use_latest}}-beta{{/use_latest}}"
    # # Make kernel-helper script executable
    # chmod u+x,g+x,o+x ${KERNEL_DIR}/rendered/nersc-julia-*/kernel-helper.sh
    ;;

    *) echo "__MODE__=${__MODE__} is not a valid setting"
       popd
       exit 1
       ;;
esac

#-------------------------------------------------------------------------------
# Copy some helper resources/scripts
#-------------------------------------------------------------------------------

cp    ${__DIR__}/../bootstrap.jl  ${KERNEL_DIR}/
cp    ${__DIR__}/../run_kernel.jl ${KERNEL_DIR}/
cp -r ${__DIR__}/../user          ${KERNEL_DIR}/
cp -r ${__DIR__}/../julia-user    ${KERNEL_DIR}/

chmod -R o+rX ${KERNEL_DIR}

popd
