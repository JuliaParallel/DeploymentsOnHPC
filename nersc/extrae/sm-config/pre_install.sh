set -eu

#______________________________________________________________________________
# Location of any pre-install generated build dependencies
#
ARTIFACTS=${INSTALL_DIR}/deps/
if [[ -d ${ARTIFACTS} ]]
then
    # These dependencies are slow as to install (mainly binutils) -- so skip
    # this entirely if the ARTIFACTS directory already exists
    exit 0
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
#------------------------------------------------------------------------------

#______________________________________________________________________________
# Libunwind install
#
wget ${LIBUNWIND_SOURCE}/${LIBUNWIND_NAME}.tar.gz
tar -xvf ${LIBUNWIND_NAME}.tar.gz
pushd ${LIBUNWIND_NAME}

./configure               \
    --prefix=${ARTIFACTS}

make -j ${N_PROCS}
make install

popd
#------------------------------------------------------------------------------

#______________________________________________________________________________
# PAPI install
#
wget ${PAPI_SOURCE}/${PAPI_NAME}.tar.gz
tar -xvf ${PAPI_NAME}.tar.gz
pushd ${PAPI_NAME}/src

export PAPI_CUDA_ROOT=${CUDA_HOME}
export CC=$(which gcc) # only seems to work with gcc
export F77=$(which gfortran) # only seems to work with gfortran

./configure               \
    --prefix=${ARTIFACTS}

make -j ${N_PROCS}
make install

popd
#------------------------------------------------------------------------------

#______________________________________________________________________________
# Libxml2 install
#
wget ${LIBXML2_SOURCE}/${LIBXML2_NAME}.tar.xz
tar -xvf ${LIBXML2_NAME}.tar.xz
pushd ${LIBXML2_NAME}

./configure               \
    --prefix=${ARTIFACTS} \
    --without-python

make -j ${N_PROCS}
make install

popd
#------------------------------------------------------------------------------

popd
