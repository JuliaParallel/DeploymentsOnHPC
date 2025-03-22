# The Julia Deployment at NERSC

Here we show how Julia is deployed at NERSC. This repo makes very heavy use of
templates, and is split up accross several folders, each with their own purpose:
```
nersc
├── data
├── environments
├── julia
├── juliaup
├── kernels
├── scripts
└── util
```

The objective of this structure is to be as modular as possible: rather than
having one monster script that will reinstall everything every at once, we
install the different aspects of the Julia deployment at NERSC in 4 seperate
phases (see below).

Note that this modular structure follows a very important principle: we decouple
the Julia configuration (managed by the [Juliaup](#Juliaup) module) from the
preferred Julia binaries modules. This way cruicial global preferences (e.g.
where to find `libmpi.so`) can be combined with a users own Julia deployment. 

## Installing Julia using this Repo

Installing Julia therefore has the following phases:
1. Render the templated global preferences. This is only necessary if a system
   maintenance has changed the names, or versions of the MPI and CUDA system
   libraries. See the sections on [Juliaup](#juliaup) and [Helper
   Scripts](#helper-scripts) for more details.
2. Install Juliaup
3. Install the preferred Julia Binaries
4. Install the default Jupyter "NERSC-Julia" kernels and helper scripts

### Why even do things this way?

Why not ask the user to download and configure their own install? Or better
still: use [JUHPC](https://github.com/JuliaParallel/JUHPC)? The main challenge
we face at NERSC is two-fold: a) there is a combinatorial explosion of different
system dependencies (mainly MPI implementations and CUDA versions) which may
change at every maintenance; and b) NERSC hosts a central Jupyter install
(Really? You where going to ssh tunnel a webserver with the ability to execute
arbirary code?! Let's see what security has to say about that!).

While possible to simply install and configure your own version of Julia in
userspace, and then hook it up with the NERSC Jupyter Hub, such a configuration
is time consuming and brittle: if the CUDA version changes during a maintenance
then the userspace configurations need to be refreshed, possibly requiring
Jupyter kernels to be reinstalled, etc. In the aggregate, such a situation costs
considerable time and effort among staff and users, often leading to frustration
-- we know, as we've been here before.

This is compounded in part because NERSC also manages multiple systems (the Data
Transfer Nodes, Spin, and Testbed systems) in addition to at least one
production supercomputer. Each of these systems have different default versions,
but the _same_ home folder.

Hence the solution presented here is to "tie" the Julia configuration into the
lmod-based module system.

## Juliaup

```
├── juliaup
│   └── sm-config
```


### Management of Global Preferences

```
├── environments
│   ├── rendered
│   │   ├── aocc.cray-mpich.cuda11.7
│   │   ├── aocc.cray-mpich.cuda12.0
│   │   ├── aocc.cray-mpich.cuda12.2
│   │   ├── aocc.cray-mpich.cuda12.4
│   │   ├── cray.cray-mpich.cuda11.7
│   │   ├── cray.cray-mpich.cuda12.0
│   │   ├── cray.cray-mpich.cuda12.2
│   │   ├── cray.cray-mpich.cuda12.4
│   │   ├── gnu.cray-mpich.cuda11.7
│   │   ├── gnu.cray-mpich.cuda12.0
│   │   ├── gnu.cray-mpich.cuda12.2
│   │   ├── gnu.cray-mpich.cuda12.4
│   │   ├── gnu.openmpi.cuda11.7
│   │   ├── gnu.openmpi.cuda12.0
│   │   ├── gnu.openmpi.cuda12.2
│   │   ├── gnu.openmpi.cuda12.4
│   │   ├── intel.cray-mpich.cuda11.7
│   │   ├── intel.cray-mpich.cuda12.0
│   │   ├── intel.cray-mpich.cuda12.2
│   │   ├── intel.cray-mpich.cuda12.4
│   │   ├── llvm.mpich.cuda11.7
│   │   ├── llvm.mpich.cuda12.0
│   │   ├── llvm.mpich.cuda12.2
│   │   ├── llvm.mpich.cuda12.4
│   │   ├── nvidia.cray-mpich.cuda11.7
│   │   ├── nvidia.cray-mpich.cuda12.0
│   │   ├── nvidia.cray-mpich.cuda12.2
│   │   └── nvidia.cray-mpich.cuda12.4
│   └── templates
│       └── environment
```


## Preferred Julia Binaries

```
├── julia
│   └── sm-config
```

## Jupyter Kernels

```
├── kernels
│   ├── julia-user
│   ├── templates
│   │   └── jupyter
│   └── user
```

## Helper Scripts

```
├── scripts
│   └── templates
│       └── bin
└── util
    └── mpi_proj
```
