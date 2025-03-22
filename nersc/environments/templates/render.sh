#!/usr/bin/env bash
set -eu
pushd ${__DIR__}

prg_envs=("aocc" "cray" "gnu" "intel" "nvidia" "llvm" "openmpi")

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

popd
