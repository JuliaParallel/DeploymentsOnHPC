#!/usr/bin/env bash
set -eu
pushd ${__DIR__}

prg_envs=("aocc" "cray" "gnu" "nvidia" "llvm" "openmpi")

#-------------------------------------------------------------------------------
# Julia Environments
#-------------------------------------------------------------------------------

for prg_env in ${prg_envs[@]}
do
    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        environment/LocalPreferences.toml                                      \
        "${prg_env}_settings.toml"                                             \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/LocalPreferences.toml"
    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        environment/Project.toml                                               \
        "${prg_env}_settings.toml"                                             \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/Project.toml"
done

#-------------------------------------------------------------------------------
# Jupyter NERSC-JULIA Kernels
#-------------------------------------------------------------------------------

# WARNING: this requires the jupyter_settings.toml/nersc_resource_dir to be
# set correctly. TODO: automate in the future.
${__PREFIX__}/opt/bin/simple-templates.ex                                  \
    jupyter/kernel.json                                                    \
    jupyter_settings.toml                                                  \
    "../kernels/rendered/nersc-julia-{{julia_thread_ct}}-{{julia_version}}{{#use_cudnn}}-cudnn{{/use_cudnn}}{{#use_latest}}-beta{{/use_latest}}/kernel.json"
${__PREFIX__}/opt/bin/simple-templates.ex                                  \
    jupyter/kernel-helper.sh                                               \
    jupyter_settings.toml                                                  \
    "../kernels/rendered/nersc-julia-{{julia_thread_ct}}-{{julia_version}}{{#use_cudnn}}-cudnn{{/use_cudnn}}{{#use_latest}}-beta{{/use_latest}}/kernel-helper.sh"
for target in $(/bin/ls ../kernels/rendered/)
do 
    chmod u+x ../kernels/rendered/$target/kernel-helper.sh
    cp jupyter/logo-32x32.png ../kernels/rendered/$target/
    cp jupyter/logo-64x64.png ../kernels/rendered/$target/
done

popd
