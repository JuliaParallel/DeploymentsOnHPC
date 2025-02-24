set -u

# Uses Juliaup to install a specific version
${INSTALL_DIR}/bin/juliaup add ${INSTALL_VERSION} || true

# creates an environment for each install
mkdir -p ${INSTALL_DIR}/environments/${INSTALL_VERSION}
cp -r \
    ${SITE_CONFIG_DIR}/environment/* \
    ${INSTALL_DIR}/environments/${INSTALL_VERSION}
