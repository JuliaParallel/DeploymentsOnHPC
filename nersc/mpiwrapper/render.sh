#!/usr/bin/env bash
set -eu

pushd ${__DIR__}

prg_envs=("aocc" "cray" "gnu" "intel" "nvidia" "llvm" "openmpi")

for prg_env in ${prg_envs[@]}
do
    ${__PREFIX__}/opt/bin/simple-modules.ex sm-config --variant=${prg_env}
done

popd

