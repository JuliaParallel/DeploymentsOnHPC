#!/usr/bin/env bash
set -eu

pushd ${__DIR__}

# prg_envs=("aocc" "cray" "gnu" "intel" "nvidia" "llvm" "openmpi")
prg_envs=("gnu" "nvidia") # make gnu go first
for prg_env in ${prg_envs[@]}
do
    mkdir -p ${__PREFIX__}/tmp
    ${__PREFIX__}/opt/bin/simple-modules.ex    \
        sm-config/                             \
        --variant=${prg_env}                   \
        --destination=${__PREFIX__}/tmp/extrae \
        --modules=${__PREFIX__}/tmp/modules
done

popd
