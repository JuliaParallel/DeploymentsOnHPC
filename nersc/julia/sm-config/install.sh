set -eu

# Erase previous juliup database (this will run a fresh install every time)
if [[ -e ${JULIAUP_DEPOT_PATH}/juliaup/juliaup.json ]]
then
    rm ${JULIAUP_DEPOT_PATH}/juliaup/juliaup.json
fi

# Depends on the juliaup module already being loaded:
module load juliaup

# Uses Juliaup to install a specific version
juliaup add ${INSTALL_VERSION} || true
