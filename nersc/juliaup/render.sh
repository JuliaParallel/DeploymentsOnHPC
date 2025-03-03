#!/usr/bin/env bash
set -eu


pushd ${__DIR__}
    ${__PREFIX__}/opt/bin/simple-modules.ex sm-config/
popd
