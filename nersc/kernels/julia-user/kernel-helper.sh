#!/usr/bin/env bash

module use /global/common/software/nersc/n9/julia/modules/

module load julia/1.8.5

echo "Checking if IJulia is installed in this project -- installing if not..."
readarray -t ijulia_boostrap < <(julia -e "
import Pkg

# Check if package is already installed
isinstalled(pkg) = isnothing(Base.identify_package(pkg)) ? false :
                   haskey(Pkg.dependencies(), Base.identify_package(pkg).uuid)

# If IJulia is not installed, install it
if ! isinstalled(\"IJulia\")
    Pkg.add(\"IJulia\")
end

import IJulia
println(joinpath(splitpath(pathof(IJulia))[1:end-1]..., \"kernel.jl\"))
")

echo "Check-and-install returned following output:"
_IFS=$IFS
IFS=$'\n'
for each in ${ijulia_boostrap[*]}
do
    echo $each
done
IFS=$_IFS

JULIA_EXEC=$(which julia)
KERNEL="${ijulia_boostrap[-1]}"
echo "Connecting using JULIA_EXEC=$JULIA_EXEC and KERNEL=$KERNEL"
exec $JULIA_EXEC -i --startup-file=yes --color=yes $KERNEL "$@"
