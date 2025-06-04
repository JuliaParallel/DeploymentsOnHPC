#!/usr/bin/env bash
set -eu

pushd ${__DIR__}
    mkdir -p ${__PREFIX__}/tmp
    ${__PREFIX__}/opt/bin/simple-modules.ex  \
        sm-config/                           \
        --sm-root=${__PREFIX__}
popd
