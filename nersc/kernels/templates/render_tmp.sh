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
    jupyter/kernel.json                                                            \
    settings.toml                                                                  \
    "${KERNEL_DIR}/rendered/nersc-julia-{{julia_thread_ct}}-{{julia_version}}{{#use_latest}}-beta{{/use_latest}}/kernel.json"
${__PREFIX__}/opt/bin/simple-templates.ex                                          \
    --overwrite "{\"nersc_resource_dir\": \"${KERNEL_DIR}\"}"                      \
    jupyter/kernel-helper.sh                                                       \
    settings.toml                                                                  \
    "${KERNEL_DIR}/rendered/nersc-julia-{{julia_thread_ct}}-{{julia_version}}{{#use_latest}}-beta{{/use_latest}}/kernel-helper.sh"

for target in $(/bin/ls ${KERNEL_DIR}/rendered/)
do 
    chmod u+x ${KERNEL_DIR}/rendered/$target/kernel-helper.sh
    cp jupyter/logo-32x32.png ${KERNEL_DIR}/rendered/${target}/
    cp jupyter/logo-64x64.png ${KERNEL_DIR}/rendered/${target}/
done

cp    ${__DIR__}/../bootstrap.jl ${KERNEL_DIR}/
cp -r ${__DIR__}/../user         ${KERNEL_DIR}/
cp -r ${__DIR__}/../julia-user   ${KERNEL_DIR}/

chmod -R o+rX ${KERNEL_DIR}

popd
