#!/usr/bin/env bash
set -eu
pushd ${__DIR__}

#-------------------------------------------------------------------------------
# Jupyter PSC-JULIA Kernels
#-------------------------------------------------------------------------------

KERNEL_DIR="<TODO: add location of PSC jupyter kernels (OnDemand config?)>"
mkdir -p ${KERNEL_DIR}

${__PREFIX__}/opt/bin/simple-templates.ex                                      \
    --dir --resource "^jupyter/.*.png$"                                        \
    --chmod "g+rX,o+rX,g-w,o-w" --chmod-basename                               \
    jupyter                                                                    \
    settings.toml                                                              \
    "${KERNEL_DIR}/rendered/psc-julia-{{julia_thread_ct}}-{{julia_version}}{{#use_latest}}-beta{{/use_latest}}"

cp ${__DIR__}/../bootstrap.jl ${KERNEL_DIR}/
chmod -R o+rX ${KERNEL_DIR}

popd
