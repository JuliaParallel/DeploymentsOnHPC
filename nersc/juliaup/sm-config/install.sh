set -u


# This script relies on simple-modules setting the JULIA{UP}_DEPOT_PATH
# environment variable

# Erase previous juliup database (this will run a fresh install every time)
if [[ -e ${JULIAUP_DEPOT_PATH}/juliaup/juliaup.json ]]
then
    rm ${JULIAUP_DEPOT_PATH}/juliaup/juliaup.json
fi

# Installs Juliaup to $INSTALL_DIR/bin
curl -fsSL https://install.julialang.org | sh -s -- --add-to-path=0 --background-selfupdate=0 --startup-selfupdate=0 --yes --path ${INSTALL_DIR}

# creates an environment for each install
mkdir -p ${INSTALL_DIR}/../environments
cp -r \
    ${SITE_CONFIG_DIR}/../../environments/rendered/* \
    ${INSTALL_DIR}/../environments/
