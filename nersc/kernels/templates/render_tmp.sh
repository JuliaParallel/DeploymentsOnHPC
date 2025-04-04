#!/usr/bin/env bash
set -eu
pushd ${__DIR__}

#-------------------------------------------------------------------------------
# Jupyter NERSC-JULIA Kernels: TMP version
#-------------------------------------------------------------------------------

KERNEL_DIR=${__PREFIX__}/tmp/kernels
mkdir -p ${KERNEL_DIR}

${__PREFIX__}/opt/bin/simple-templates.ex                                          \
    --overwrite "{\"nersc_resource_dir\": \"${KERNEL_DIR}\"}"                      \
    --dir --resource "^jupyter/.*.png$"                                            \
    jupyter                                                                        \
    settings.toml                                                                  \
    "${KERNEL_DIR}/rendered/nersc-julia-{{julia_thread_ct}}-{{julia_version}}{{#use_latest}}-beta{{/use_latest}}"

for target in $(/bin/ls ${KERNEL_DIR}/rendered/)
do 
    chmod u+x ${KERNEL_DIR}/rendered/$target/kernel-helper.sh
done

cp    ${__DIR__}/../bootstrap.jl ${KERNEL_DIR}/
cp -r ${__DIR__}/../user         ${KERNEL_DIR}/
cp -r ${__DIR__}/../julia-user   ${KERNEL_DIR}/

chmod -R o+rX ${KERNEL_DIR}

popd
