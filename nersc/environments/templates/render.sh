#!/usr/bin/env bash
set -eu
pushd ${__DIR__}

prg_envs=("aocc" "cray" "gnu" "intel" "nvidia" "llvm")

#-------------------------------------------------------------------------------
# Julia Environments
#-------------------------------------------------------------------------------

for prg_env in ${prg_envs[@]}
do
    ${__PREFIX__}/opt/bin/simple-templates.ex --dir                 \
        --chmod "g+rX,o+rX,g-w,o-w" --chmod-basename                \
        environment                                                 \
        "${prg_env}_settings.toml"                                  \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}"
done

popd
