#!/usr/bin/env bash
set -eu
pushd ${__DIR__}

#-------------------------------------------------------------------------------
# Jupyter PSC-JULIA Kernels: TMP version
#-------------------------------------------------------------------------------

KERNEL_DIR=${__PREFIX__}/tmp/kernels
mkdir -p ${KERNEL_DIR}

${__PREFIX__}/opt/bin/simple-templates.ex                                      \
    --overwrite "{\"kernel_resource_dir\": \"${KERNEL_DIR}\"}"                 \
    --dir --resource "^jupyter/.*.png$"                                        \
    --chmod "g+rX,o+rX,g-w,o-w" --chmod-basename                               \
    jupyter                                                                    \
    settings.toml                                                              \
    "${KERNEL_DIR}/rendered/psc-julia-{{julia_thread_ct}}-{{julia_version}}{{#use_latest}}-beta{{/use_latest}}"

cp ${__DIR__}/../bootstrap.jl ${KERNEL_DIR}/
chmod -R o+rX ${KERNEL_DIR}

popd
