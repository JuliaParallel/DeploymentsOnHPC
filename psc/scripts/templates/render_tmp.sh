/env bash
set -eu
pushd ${__DIR__}

#-------------------------------------------------------------------------------
# Helper scripts for the PSC Julia install
#-------------------------------------------------------------------------------

RESOURCE_DIR=${__PREFIX__}/tmp
SCRIPT_DIR=${RESOURCE_DIR}/scripts

mkdir -p ${SCRIPT_DIR}

${__PREFIX__}/opt/bin/simple-templates.ex                       \
    --overwrite "{\"julia_resource_dir\": \"${RESOURCE_DIR}\"}" \
    --chmod "g+rx,o+rx,g-w,o-w" --chmod-basename --dir          \
    bin                                                         \
    settings.toml                                               \
    "${SCRIPT_DIR}"

popd
