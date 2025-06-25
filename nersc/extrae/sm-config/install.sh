set -eu

#______________________________________________________________________________
# Location of any pre-install generated build dependencies
#
ARTIFACTS=${INSTALL_DIR}/opt
# If rebuilding, then create seperate directories for artifacts
[[ ${REBUILD} == true ]] && ARTIFACTS="${ARTIFACTS}-${INSTALL_VARIANT}"
# these will have been installed by pre_install.sh
#------------------------------------------------------------------------------

#______________________________________________________________________________
# Extrae install
#

wget ${EXTRAE_SOURCE}/${EXTRAE_NAME}-src.tar.bz2
tar -xvf ${EXTRAE_NAME}-src.tar.bz2
pushd ${EXTRAE_NAME}

./configure \
    --prefix=${INSTALL_DIR}/${INSTALL_VERSION_VARIANT} \
    --with-mpi=${CRAY_MPICH_DIR}                       \
    --with-binutils=${ARTIFACTS}                       \
    --with-papi=${ARTIFACTS}                           \
    --with-unwind=${ARTIFACTS}                         \
    --with-xml-prefix=${ARTIFACTS}                     \
    --without-dyninst

make -j ${N_PROCS}
make install
