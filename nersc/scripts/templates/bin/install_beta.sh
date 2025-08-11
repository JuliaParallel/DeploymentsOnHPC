#!/usr/bin/env bash
set -eu


source {{{nersc_resource_dir}}}/scripts/activate_beta.sh


mkdir -p ~/.local/share/jupyter/kernels
pushd ~/.local/share/jupyter/kernels
    cp -r {{{nersc_resource_dir}}}/kernels/rendered/{{{kernel_prefix_name}}}-*-{{{julia_version}}}*-beta .
popd

ml load julia/{{{julia_version}}}
julia {{{nersc_resource_dir}}}/kernels/bootstrap.jl
