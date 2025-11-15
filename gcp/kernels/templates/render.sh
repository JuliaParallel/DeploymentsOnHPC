#!/usr/bin/env bash
set -eu
pushd ${__DIR__}

SITE_NAME="gcp-julia"

#-------------------------------------------------------------------------------
# Set path of the kernels
#-------------------------------------------------------------------------------
case ${__MODE__} in
    global) KERNEL_DIR="/deploy/jupyter/venv/share/jupyter/kernels"
	    KERNEL_RUNTIME_DIR="/deploy/jupyter/kernel_runtime/julia"
            ;;
    local)  KERNEL_DIR=${__LOCAL_PATH__}/kernels
	    KERNEL_RUNTIME_DIR=${__LOCAL_PATH__}/kernels/kernel_runtime/julia
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
        "${KERNEL_DIR}/${SITE_NAME}-{{julia_thread_ct}}-{{julia_version}}{{#use_latest}}-beta{{/use_latest}}"
    ;;
local)
    ${__PREFIX__}/opt/bin/simple-templates.ex                               \
        --overwrite "{\"nersc_resource_dir\": \"${KERNEL_DIR}\"}"           \
        --dir --resource "^jupyter/.*.png$"                                 \
        --chmod "u+rX,g+rX,o+rX,g-w,o-w" --chmod-basename                   \
        --chmod-overwrite "{\".*/kernel%-helper.sh$\": \"u+rx,g+rx,o+rx\"}" \
        jupyter                                                             \
        settings.toml                                                       \
        "${KERNEL_DIR}/${SITE_NAME}-{{julia_thread_ct}}-{{julia_version}}{{#use_latest}}-beta{{/use_latest}}"
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

mkdir -p ${KERNEL_RUNTIME_DIR}
cp    ${__DIR__}/../bootstrap.jl  ${KERNEL_RUNTIME_DIR}/
cp    ${__DIR__}/../run_kernel.jl ${KERNEL_RUNTIME_DIR}/
cp -r ${__DIR__}/../user          ${KERNEL_RUNTIME_DIR}/

chmod -R o+rX ${KERNEL_RUNTIME_DIR}

popd
