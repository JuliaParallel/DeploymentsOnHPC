#!/usr/bin/env bash
set -eu

pushd ${__DIR__}
    mkdir -p ${__PREFIX__}/tmp
    ${__PREFIX__}/opt/bin/simple-modules.ex           \
        sm-config/                                    \
        --destination=${__PREFIX__}/tmp/mpitrampoline \
        --modules=${__PREFIX__}/tmp/modules
popd

