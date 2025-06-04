# Common Components for Julia HPC Deployments

## Juliaup-HPC

The Julia multiplexing features of Juliaup don't work well on HPC systems.
Juliaup-HPC wraps `juliaup` generating module files whenever a new julia
version is added by `juliaup`. This allows Julia version installed by
`juliaup-hpc` to be used by environment module system. [More details
here](./juliaup-hpc/README.md)

## Rust

This is a barebones deployment script for Rust. In case the rust compiler is
not avaialbe on your target sytem. [More details here](./rust/README.md)

