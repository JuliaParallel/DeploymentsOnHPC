#!/usr/bin/env bash
set -eu
pushd ${__DIR__}

#-------------------------------------------------------------------------------
# Helper scripts for the NERSC Julia install
#-------------------------------------------------------------------------------

RESOURCE_DIR="/global/common/software/nersc9/julia"
SCRIPT_DIR=${RESOURCE_DIR}/scripts

mkdir -p ${SCRIPT_DIR}

${__PREFIX__}/opt/bin/simple-templates.ex                                  \
    bin/activate_beta.sh                                                   \
    settings.toml                                                          \
    "${SCRIPT_DIR}/activate_beta.sh"

${__PREFIX__}/opt/bin/simple-templates.ex                                  \
    bin/deactivate_beta.sh                                                 \
    settings.toml                                                          \
    "${SCRIPT_DIR}/deactivate_beta.sh"

${__PREFIX__}/opt/bin/simple-templates.ex                                  \
    bin/install_beta.sh                                                    \
    settings.toml                                                          \
    "${SCRIPT_DIR}/install_jupyter_beta_{{{julia_version}}}.sh"

chmod u+x ${SCRIPT_DIR}/install_jupyter_beta_*.sh
chmod g+x ${SCRIPT_DIR}/install_jupyter_beta_*.sh
chmod o+x ${SCRIPT_DIR}/install_jupyter_beta_*.sh

chmod o+rX -R ${SCRIPT_DIR}

popd
