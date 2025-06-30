#!/usr/bin/env bash
set -eu


source {{{julia_resource_dir}}}/scripts/activate_beta.sh


mkdir -p ~/.local/share/jupyter/kernels
pushd ~/.local/share/jupyter/kernels
    cp -r {{{julia_resource_dir}}}/kernels/rendered/psc-julia-*-{{{julia_version}}}*-beta .
popd

ml load julia/{{{julia_version}}}
julia {{{julia_resource_dir}}}/kernels/bootstrap.jl
