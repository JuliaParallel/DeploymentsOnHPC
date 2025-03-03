set -eu

# Depends on the juliaup module already being loaded:
module load juliaup/stable

# Uses Juliaup to install a specific version
juliaup add ${INSTALL_VERSION} || true
