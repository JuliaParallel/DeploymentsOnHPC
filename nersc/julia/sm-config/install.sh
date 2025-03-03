set -u

# Uses Juliaup to install a specific version
juliaup add ${INSTALL_VERSION} || true
