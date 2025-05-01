# The Julia Deployment at NERSC

Here we show how Julia is deployed at NERSC. This repo makes very heavy use of
templates, and is split up across several folders, each with their own purpose:
```
nersc
├── data
├── environments
├── julia
├── juliaup
├── kernels
├── mpitrampoline
├── mpiwrapper
├── scripts
└── util
```

The objective of this structure is to be as modular as possible: rather than
having one monster script that will reinstall everything every at once, we
install the different aspects of the Julia deployment at NERSC in 4 separate
phases (see below).

Note that this modular structure follows a very important principle: we decouple
the Julia configuration (managed by the [Juliaup](#Juliaup) module) from the
preferred Julia binaries modules. This way crucial global preferences (e.g.
where to find `libmpi.so`) can be combined with a users own Julia deployment. 

In addition to the Julia deployment, we also include deployment scripts for
[MPItrampoline](https://github.com/eschnett/MPItrampoline) -- which can be used
in conjunction with Julia (i.e. many packages in Julia's ecosystem are built
against [MPIwrapper](https://github.com/eschnett/MPIwrapper) as an MPI
provider.)

## Installing Julia using this Repo

Installing Julia therefore has the following phases:
1. Render the templated global preferences. This is only necessary if a system
   maintenance has changed the names, or versions of the MPI and CUDA system
   libraries. See the sections on [Juliaup](#juliaup) and [Helper
   Scripts](#helper-scripts) for more details.
2. [Install Juliaup](#juliaup). This will also copy the preferences to a global
   location.
3. [Install the preferred Julia Binaries](#preferred-julia-binaries). Note that
   these depend on the `juliaup` module being in the `MODULEPATH`
4. Install the default [Jupyter "NERSC-Julia"](#jupyter-kernels) kernels and
   helper scripts.

### Why even do things this way?

Why not ask the user to download and configure their own install? Or better
still: use [JUHPC](https://github.com/JuliaParallel/JUHPC)? The main challenge
we face at NERSC is two-fold: a) there is a combinatorial explosion of different
system dependencies (mainly MPI implementations and CUDA versions) which may
change at every maintenance; and b) NERSC hosts a central Jupyter install
(Really? You where going to ssh tunnel a webserver with the ability to execute
arbitrary code?! Let's see what security has to say about that!).

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
Lmod-based module system.

### Render Scripts: `render.sh` vs `render_tmp.sh`

Often you'll see a `render.sh` and a `render_tmp.sh` side by side. These
scripts will execute the steps necessary to install a module and/or render a
template. The only difference between these scripts is that the `_tmp` version
will deploy the rendered contents to `$__PREFIX__/tmp` whereas the "regular"
version deploys to the `/global/common/software/nersc9`.

We implement this behaviour using the following conventions:
* If using Simple Modules, then the `local_settings.toml` file defines
`destination`; if using Simple Templates, then the template `settings.toml`
file defines `nersc_resource_dir` -- both of these "point" to
`/global/common/software/nersc9/julia`.
* `render.sh` does not touch these settings.
* `redner_tmp.sh` overwrites these settings via CLI flags.
* **Note:** When using Simple Templates, the rendering script does manually
direct the output to the right location -- don't forget to change these when
you're developing your own site's render scripts.


Use `render_tmp.sh` for local (userspace) testing -- once you're happy with
your recipe, then use `render.sh` to deploy to the global NERSC software
directory. You'll need to be a member of NERSC staff to use the later.

## Juliaup

Installing [Juliaup](https://github.com/JuliaLang/juliaup) is handled by Simple
Modules, and is configured via the `sm-config` folder.

```
nersc/juliaup/
├── render.sh
├── render_tmp.sh
└── sm-config
    ├── install.sh
    ├── local_settings.toml
    ├── module_template.lua
    └── settings.toml
```

To install, either run: `./entrypoint.sh ./nersc/juliaup/render.sh` [or the `_tmp` equivalent]()


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
