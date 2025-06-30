#!/usr/bin/env bash
set -eu
pushd ${__DIR__}

#-------------------------------------------------------------------------------
# Helper scripts for the PSC Julia install
#-------------------------------------------------------------------------------

RESOURCE_DIR="<TODO: location of global Julia install at PSC>"
SCRIPT_DIR=${RESOURCE_DIR}/scripts

mkdir -p ${SCRIPT_DIR}

${__PREFIX__}/opt/bin/simple-templates.ex              \
    --chmod "g+rx,o+rx,g-w,o-w" --chmod-basename --dir \
    bin                                                \
    settings.toml                                      \
    "${SCRIPT_DIR}"

popd
