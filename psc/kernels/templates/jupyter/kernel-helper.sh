#!/bin/bash
{{#use_latest}}
module use {{{kernel_resource_dir}}}
{{/use_latest}}
module load python
module load julia/{{{julia_version}}}
module load cudnn

export JULIA_NUM_THREADS={{julia_thread_ct}}

readarray -t ijulia_boostrap < <(julia {{{kernel_resource_dir}}}/bootstrap.jl)

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
