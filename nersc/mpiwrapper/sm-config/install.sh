set -eu

wget ${DL_SOURCE}/v${INSTALL_VERSION}.tar.gz
tar -xf v${INSTALL_VERSION}.tar.gz

cd MPIwrapper-${INSTALL_VERSION}
cmake -S . -B build                           \
    -DMPIEXEC_EXECUTABLE=mpiexec              \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo         \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}/${INSTALL_VERSION_VARIANT}

cmake --build build -j ${N_PROCS}
cmake --install build
