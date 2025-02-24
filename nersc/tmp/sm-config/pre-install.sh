set -u


# This script relies on simple-modules setting the JULIA{UP}_DEPOT_PATH
# environment variable

# Erase previous juliup database (this will run a fresh install every time)
if [[ -e ${JULIAUP_DEPOT_PATH}/juliaup/juliaup.json ]]
then
    rm ${JULIAUP_DEPOT_PATH}/juliaup/juliaup.json
fi
if [[ -e ${INSTALL_DIR}/bin/julia ]]
then
    rm ${INSTALL_DIR}/bin/julia
fi


# Installs Juliaup to $INSTALL_DIR/bin
curl -fsSL https://install.julialang.org | sh -s -- --add-to-path=0 --yes --path ${INSTALL_DIR}
