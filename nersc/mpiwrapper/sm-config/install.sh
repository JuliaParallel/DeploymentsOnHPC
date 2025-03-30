set -eu

wget ${DL_SOURCE}/v${INSTALL_VERSION}.tar.gz
tar -xf v${INSTALL_VERSION}.tar.gz

cd MPIwrapper-${INSTALL_VERSION}


if [[ "${INSTALL_VARIANT}" == "openmpi" ]]
then
    prgenv="gnu"
elif [[ "${INSTALL_VARIANT}" == "llvm" ]]
then
    prgenv="llvm"
    module load mpich # hack! this is necessary to get mpifort
else
    prgenv="${INSTALL_VARIANT}"
fi

module load PrgEnv-${prgenv}

if [[ "${INSTALL_VARIANT}" == "openmpi" ]]
then
    mpi_runtime="srun --mpi=pmix"
    mpi_c_compiler=$(which mpicc)
    mpi_cxx_compiler=$(which mpicxx)
    mpi_fortran_compiler=$(which mpifort)
elif [[ "${INSTALL_VARIANT}" == "llvm" ]]
then
    prgenv="llvm"
    mpi_runtime="srun"
    mpi_c_compiler=$(which mpicc)
    mpi_cxx_compiler=$(which mpicxx)
    mpi_fortran_compiler=$(which mpifort)
else
    mpi_runtime="srun"
    mpi_c_compiler=$(which cc)
    mpi_cxx_compiler=$(which CC)
    mpi_fortran_compiler=$(which ftn)
fi

cmake -S . -B build                                   \
    -DCMAKE_C_COMPILER=${mpi_c_compiler}              \
    -DCMAKE_CXX_COMPILER=${mpi_cxx_compiler}          \
    -DCMAKE_Fortran_COMPILER=${mpi_fortran_compiler}  \
    -DMPIEXEC_EXECUTABLE="${mpi_runtime}"             \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo                 \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}/${INSTALL_VERSION_VARIANT}

cmake --build build -j ${N_PROCS}
cmake --install build
