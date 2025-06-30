#!/usr/bin/env bash
set -eu
pushd ${__DIR__}

#-------------------------------------------------------------------------------
# Julia Environments
#-------------------------------------------------------------------------------

${__PREFIX__}/opt/bin/simple-templates.ex --dir                 \
    --chmod "g+rX,o+rX,g-w,o-w" --chmod-basename                \
    environment                                                 \
    settings.toml                                               \
    "../rendered/{{toolchain}}.{{mpi_mod}}{{mpi_version}}.cuda{{cuda_version}}"

popd
