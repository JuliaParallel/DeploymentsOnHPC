set -eu

if [[ ${INSTALL_VERSION} == "main" ]]
then
    git clone --depth 1 --single-branch --branch ${INSTALL_VERSION} \
        ${GH_PROJECT}/juliaup gh
else
    git clone --depth 1 --single-branch --branch v${INSTALL_VERSION} \
        ${GH_PROJECT}/juliaup gh
fi

cd gh

${CARGO_HOME}/bin/cargo build -j ${NPROC} --release --no-default-features
mkdir -p ${STAGE_DIR}/dist
${CARGO_HOME}/bin/cargo install --path . --root ../dist

cd ${INSTALL_ROOT}
mkdir -p scripts
cp ${INSTALL_SRC}/../dist/juliaup-hpc scripts/

if [[ ${COPY_JULIA_ENVS} == true ]]
then
    echo "ATTENTION: Using pre-defined Julia environments"
    if [[ -d ${SITE_CONFIG_DIR}/${JULIA_ENVS_SRC} ]]
    then
        mkdir -p ${INSTALL_DIR}/${JULIA_ENVS_DST}
        cp -r \
            ${SITE_CONFIG_DIR}/${JULIA_ENVS_SRC}/* \
            ${INSTALL_DIR}/${JULIA_ENVS_DST}
    else
        echo "WARNING: JULIA_ENVS_SRC=${SITE_CONFIG_DIR}/${JULIA_ENVS_SRC} does not exist!"
    fi
fi

