set -eu

#______________________________________________________________________________
# This is a pretty involved pre-install, with many components. In order to make
# debugging easier, we provide the following environment vars to toggle
# different components:
#   - REBUILD: rebuild artifacts even if they already exist
#   - BINUTILS: builds binutils
#   - LIBUNWID: builds libundind
#   - PAPI: builds PAPI
#   - LIBXML2: builds libxml2

check_bool() {
    echo "Checking that $1 is set ..."
    [[ ${!1} == true || ${!1} == false ]] || {
        echo "Error: $1 must be 'true' or 'false', got '${!1}'" >&2
        exit 1
    }
}

check_bool REBUILD
check_bool BINUTILS
check_bool LIBUNWIND
check_bool PAPI
check_bool LIBXML2

#______________________________________________________________________________
# Location of any pre-install generated build dependencies
#
ARTIFACTS=${INSTALL_DIR}/opt
# If rebuilding, then create seperate directories for artifacts
[[ ${REBUILD} == true ]] && ARTIFACTS="${ARTIFACTS}-${INSTALL_VARIANT}"
if [[ -d ${ARTIFACTS} ]]
then
    # These dependencies are slow to install (mainly binutils) -- so skip this
    # entirely if the ARTIFACTS directory already exists and `REBUILD=false`
    [[ ${REBUILD} == false ]] && exit 0
else
    mkdir -p ${ARTIFACTS}
fi
#------------------------------------------------------------------------------

#______________________________________________________________________________
# Current working directory
#
mkdir -p ${PRE_STAGE_DIR}
pushd ${PRE_STAGE_DIR}
#------------------------------------------------------------------------------


#______________________________________________________________________________
# Binutils install
#
if [[ ${BINUTILS} == true ]]
then
    wget ${BINUTILS_SOURCE}/${BINUTILS_NAME}.tar.gz
    tar -xvf ${BINUTILS_NAME}.tar.gz
    pushd ${BINUTILS_NAME}

    export CFLAGS="-g -O3 -Wno-error"
    export CXXFLAGS="-g -O3 -Wno-error"
    ./configure               \
        --prefix=${ARTIFACTS} \
        --enable-shared

    make -j ${N_PROCS}
    make install

    # remember to move libiberty
    cp libiberty/pic/libiberty.a ${ARTIFACTS}/lib

    popd
fi
#------------------------------------------------------------------------------

#______________________________________________________________________________
# Libunwind install
#
if [[ ${LIBUNWIND} == true ]]
then
    wget ${LIBUNWIND_SOURCE}/${LIBUNWIND_NAME}.tar.gz
    tar -xvf ${LIBUNWIND_NAME}.tar.gz
    pushd ${LIBUNWIND_NAME}

    ./configure               \
        --prefix=${ARTIFACTS}

    make -j ${N_PROCS}
    make install

    popd
fi
#------------------------------------------------------------------------------

#______________________________________________________________________________
# PAPI install
#
if [[ ${PAPI} == true ]]
then
    wget ${PAPI_SOURCE}/${PAPI_NAME}.tar.gz
    tar -xvf ${PAPI_NAME}.tar.gz
    pushd ${PAPI_NAME}/src

    export PAPI_CUDA_ROOT=${CUDA_HOME}
    export CC=$(which gcc) # only seems to work with gcc
    export F77=$(which gfortran) # only seems to work with gfortran

    ./configure               \
        --prefix=${ARTIFACTS} \
        --with-components="cuda lustre"

    make -j ${N_PROCS}
    make install

    popd
fi
#------------------------------------------------------------------------------

#______________________________________________________________________________
# Libxml2 install
#
if [[ ${LIBXML2} == true ]]
then
    wget ${LIBXML2_SOURCE}/${LIBXML2_NAME}.tar.xz
    tar -xvf ${LIBXML2_NAME}.tar.xz
    pushd ${LIBXML2_NAME}

    ./configure               \
        --prefix=${ARTIFACTS} \
        --without-python

    make -j ${N_PROCS}
    make install

    popd
fi
#------------------------------------------------------------------------------

popd
