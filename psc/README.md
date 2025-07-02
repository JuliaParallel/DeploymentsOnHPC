# The Julia Deployment at PSC

Here we show how Julia is deployed at PSC. This repo makes very heavy use of
templates, and is split up across several folders, each with their own purpose:
```
psc
├── data
├── environments
├── julia-env
├── julia
├── juliaup
├── kernels
├── scripts
└── util
```

The overall dependency layout is summarized as follows:
```
┌─────────────────┐                                                            
│┌────────────────┴┐              ┌─────────────────┐       ┌─────────────────┐
││       PSC       │              │  User-Defined   │       │  User-Defined   │
││ Jupyter Kernels │              │      Julia      │◄──┬──►│     Jupyter     │
└┤   in OnDemand   │              │     Modules     │   │   │     Kernels     │
 └─────────────────┘              └─────────────────┘   │   └─────────────────┘
         ▲▲                                             │                      
         ││                                             │                      
┌────────┴┼───────┐                                     │                      
│┌────────┴───────┴┐    ┌─────────────────┐    ┌────────┴────────┐             
││                 │    │                 │    │                 │             
││  Julia Modules  │◄───┤  Juliaup Module ├───►│   Juliaup-HPC   │             
└┤                 │    │                 │    │                 │             
 └─────────────────┘    └─────────────────┘    └─────────────────┘             
                                 ▲     ┌─────────────────┐                     
                                 │     │┌────────────────┴┐                    
                                 ├─────┤│      PSC        │                    
                                 ├─────┼┤Julia Environment│                    
                                 │     └┤   Preferences   │                    
                                 │      └─────────────────┘                    
                                 │     ┌─────────────────┐                     
                                 │     │    julia-env    │                     
                                 └─────┤     Module      │                     
                                       │                 │                     
                                       └─────────────────┘                     
                                               ▲     ┌─────────────────┐       
                                               │     │┌────────────────┴┐      
                                               ├─────┤│      PSC        │      
                                               └─────┼┤   MPI and CUDA  │      
                                                     └┤     Modules     │      
                                                      └─────────────────┘      
```
(arrows indicate dependencies)

The objective of this structure is to be as modular as possible: rather than
having one monster script that will reinstall everything every at once, we
install the different aspects of the Julia deployment at PSC in 5 separate
phases (see below).

Note that this modular structure follows a very important principle: we
decouple the Julia configuration (managed by the [Juliaup](#Juliaup) and
`julia-env` modules) from the preferred Julia binaries modules. This way
crucial global preferences (e.g. where to find `libmpi.so`) can be combined
with a users own Julia deployment. 

## Installing Julia using this Repo

Installing Julia therefore has the following steps:
1. [Render the templated global preferences](#render-global-preferences). This
   is only necessary if a system maintenance has changed the names, or versions
   of the MPI and CUDA system libraries. See the sections on
   [Juliaup](#install-juliaup) and [Helper Scripts](#render-helper-scripts) for
   more details.
2. [Render the `julia-env` module](#render-julia-env-module). This module is a
   dependency of `juliaup` and ensures that the `juliaup` module can detect the
   correct MPI and CUDA versions
3. [Install Juliaup](#install-juliaup). This will also copy the preferences to
   a global location.
4. Ensure that the `juliaup` and `julia-env` modules are in the `MODULEPATH` --
   eg. using `module use /path/to/juliaup/module`.
5. [Install the preferred Julia Binaries](#install-preferred-julia-binaries).
   Note that these depend on the `juliaup` module being in the `MODULEPATH`
6. [Install the default Jupyter "PSC-Julia"](#install-jupyter-kernels) kernels
   and helper scripts.

(Note: These are broken up this way, so to make it easier to install a quick
update, rather than needing to reinstall everything)


### Render Global Preferences

Run:
```bash
$ ./entrypoint.sh ./psc/environments/templates/render.sh
```
(there is no `_tmp` version -- Global preferences are rendered locally and then
copied by the Juliaup installer)

### Render Julia-Env Module

* For the _global version_ run:
```bash
./entrypoint.sh ./psc/julia-env/render.sh
```
* For the _local version_ run:
```bash
./entrypoint.sh ./psc/julia-env/render_tmp.sh
```

### Install Juliaup

* For the _global version_ run:
```bash
./entrypoint.sh ./psc/juliaup/render.sh
```
* For the _local version_ run:
```bash
./entrypoint.sh ./psc/juliaup/render_tmp.sh
```

### Install Preferred Julia Binaries

* For the _global version_ run:
```bash
./entrypoint.sh ./psc/julia/render.sh
```
* For the _local version_ run:
```bash
./entrypoint.sh ./psc/julia/render_tmp.sh
```

### Install Jupyter Kernels

* For the _global version_ run:
```bash
./entrypoint.sh ./psc/kernels/templates/render.sh
```
* For the _local version_ run:
```bash
./entrypoint.sh ./psc/kernels/templates/render_tmp.sh
```

### Render Helper Scripts

* For the _global version_ run:
```bash
./entrypoint.sh ./psc/scripts/templates/render.sh
```
* For the _local version_ run:
```bash
./entrypoint.sh ./psc/scripts/templates/render_tmp.sh
```
