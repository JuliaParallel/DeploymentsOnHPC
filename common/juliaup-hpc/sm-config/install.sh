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

cargo build --release --no-default-features
mkdir -p ${STAGE_DIR}/dist
cargo install --path . --root ../dist

cd ${INSTALL_ROOT}
mkdir -p scripts
cp ${INSTALL_SRC}/dist/juliaup-hpc scripts/
