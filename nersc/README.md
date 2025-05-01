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

The overall dependency layout is summarized as follows:
```
┌─────────────────┐                                         
│┌────────────────┴┐                                        
││      NERSC      │                                        
││ Jupyter Kernels │                                        
└┤                 │                                        
 └─────────────────┘                                        
         ▲▲                                                 
         ││                                                 
┌────────┴┼───────┐                                         
│┌────────┴───────┴┐    ┌─────────────────┐                 
││                 │    │                 │                 
││  Julia Modules  │◄───┤  Juliaup Module │                 
└┤                 │    │                 │                 
 └─────────────────┘    └─────────────────┘                 
                                 ▲     ┌─────────────────┐  
                                 │     │┌────────────────┴┐ 
                                 ├─────┤│      NERSC      │ 
                                 ├─────┼┤Julia Environment│ 
                                 │     └┤   Preferences   │ 
                                 │      └─────────────────┘ 
                                 │     ┌─────────────────┐  
                                 │     │      NERSC      │  
                                 └─────┤   Cudatoolkit   │  
                                       │      Module     │  
                                       └─────────────────┘ 
```
(arrows indicate dependencies)

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
3. Ensure that the `juliaup` module is in the `MODULEPATH` -- eg. using `module
   use /path/to/juliaup/module`.
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

We implement this behavior using the following conventions:
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

To install, either run: `./entrypoint.sh ./nersc/juliaup/render.sh` [or the
`_tmp` equivalent](#render-scripts-rendersh-vs-render_tmpsh).

Please refer to the [Simple Modules
Documentation](https://gitlab.blaschke.science/nersc/simple-modules) on how the
Juliaup module is built. In summary the process involves downloading the
`juliaup` binary and generating a module file. 

**Important:** The Juliaup module file also configures the `JULIA_LOAD_PATH` to
include NERSC-specific preferences. The idea is that a Julia user might prefer
to install their own Julia versions via Juliaup -- however we (NERSC) still
want to ensure that these local Julia versions "pick up" the correct settings
for NERSC's systems.

### The Juliaup Module File

Please refer to the [juliaup module file
template](./juliaup/sm-config/module_template.lua) for the detailed
implementation. This module manages both the `juliaup` binary, and also the
[global preferences](#management-of-global-preferences) for NERSC.

The module file is specifically designed to ensure that reloading the module
works correctly after the software environment changes. Since many Julia
packages depend on CUDA -- and which Julia packages will be used won't be known
when the module is loaded -- the `juliaup` module has a dependency on
`cudatoolkit`.

### Management of Global Preferences

The Julia environments handled by the `juliaup` module are located in the
`environments` to-level directory. They are machine generated whenever the
NERSC programming environment changes (e.g. a new MPI or CUDA version is
installed) -- therefore for the most part the following environments 
```
nersc/environments
├── rendered
│   ├── aocc.cray-mpich.cuda11.7
│   ├── aocc.cray-mpich.cuda12.0
│   ├── aocc.cray-mpich.cuda12.2
│   ├── aocc.cray-mpich.cuda12.4
│   ├── cray.cray-mpich.cuda11.7
│   ├── cray.cray-mpich.cuda12.0
│   ├── cray.cray-mpich.cuda12.2
│   ├── cray.cray-mpich.cuda12.4
│   ├── gnu.cray-mpich.cuda11.7
│   ├── gnu.cray-mpich.cuda12.0
│   ├── gnu.cray-mpich.cuda12.2
│   ├── gnu.cray-mpich.cuda12.4
│   ├── gnu.openmpi.cuda11.7
│   ├── gnu.openmpi.cuda12.0
│   ├── gnu.openmpi.cuda12.2
│   ├── gnu.openmpi.cuda12.4
│   ├── intel.cray-mpich.cuda11.7
│   ├── intel.cray-mpich.cuda12.0
│   ├── intel.cray-mpich.cuda12.2
│   ├── intel.cray-mpich.cuda12.4
│   ├── llvm.mpich.cuda11.7
│   ├── llvm.mpich.cuda12.0
│   ├── llvm.mpich.cuda12.2
│   ├── llvm.mpich.cuda12.4
│   ├── nvidia.cray-mpich.cuda11.7
│   ├── nvidia.cray-mpich.cuda12.0
│   ├── nvidia.cray-mpich.cuda12.2
│   └── nvidia.cray-mpich.cuda12.4
└── templates
    └── environment
```
simply need to be copied the Julia location whenever the module is updated.
Each folder contain a bare bones Julia project with
[preferences](https://juliapackaging.github.io/Preferences.jl):
```
nersc/environments/rendered/gnu.cray-mpich.cuda12.4/
├── LocalPreferences.toml
└── Project.toml
```

To generate these, please run `./entrypoint.sh
./nersc/environments/templates/render.sh` (there is no `_tmp` equivalent).

#### How Environments are Generated

The Julia environments at NERSC are a outer product covering all combinations
of PrgEnv, MPI, and CUDA versions. Each PrgEnv is configured by its own
settings toml file, and all of them are rendered using the `render.sh`
```
nersc/environments/templates
├── aocc_settings.toml
├── cray_settings.toml
├── environment
│   ├── LocalPreferences.toml
│   └── Project.toml
├── gnu_settings.toml
├── intel_settings.toml
├── llvm_settings.toml
├── nvidia_settings.toml
├── openmpi_settings.toml
└── render.sh
```

Please take a look at the [Simple
Templates](https://gitlab.blaschke.science/nersc/simple-templates)
documentation for a detailed explanation of how templates are rendered. Here we
go through the `PrgEnv-gnu` as an example.

The `render.sh` script starts with the GNU settings file
`nersc/environments/templates/gnu_settings.toml`:
```toml
[constant]
template_version = 1
cray = true

prg_env = "gnu"
mpi_mod = "cray-mpich"

mpi_abi = "MPICH"
mpi_lib = "libmpi_gnu_123.so"
srun_cmd = "srun"

cclibs = '"cupti", "cudart", "cuda", "dsmml", "xpmem"'

[product]
cuda_version = ["11.7", "12.0", "12.2", "12.4"]
```
Which is used to render into a `LocalPreferences.toml` using the template file
`nersc/environments/templates/environment/LocalPreferences.toml`:
```jinja
[MPIPreferences]
{{#cray}}
_format = "1.1"
{{/cray}}
{{^cray}}
__clear__ = ["preloads_env_switch"]
_format = "1.0"
{{/cray}}
abi = "{{mpi_abi}}"
binary = "system"
cclibs = [{{{cclibs}}}]
libmpi = "{{mpi_lib}}"
mpiexec = "{{srun_cmd}}"
{{#cray}}
preloads = ["libmpi_gtl_cuda.so"]
preloads_env_switch = "MPICH_GPU_SUPPORT_ENABLED"
{{/cray}}
{{^cray}}
preloads = []
{{/cray}}

[CUDA_Runtime_jll]
local = "true"
version = "{{cuda_version}}"
```
Using the [Mustache template
format](https://mustache.github.io/mustache.5.html), resulting in the concrete
Julia preference file
`nersc/environments/rendered/gnu.cray-mpich.cuda12.4/LocalPreferences.toml`
```toml
[MPIPreferences]
_format = "1.1"
abi = "MPICH"
binary = "system"
cclibs = ["cupti", "cudart", "cuda", "dsmml", "xpmem"]
libmpi = "libmpi_gnu_123.so"
mpiexec = "srun"
preloads = ["libmpi_gtl_cuda.so"]
preloads_env_switch = "MPICH_GPU_SUPPORT_ENABLED"

[CUDA_Runtime_jll]
local = "true"
version = "12.4"
```
for this combination of MPI and CUDA.

## Preferred Julia Binaries

Julia binaries are downloaded using the Juliaup module -- so you need to
install this module first. If that module hasn't been deployed to production
yet, you can run `module use /path/to/juliaup/module/folder`. Install is
handled by Simple Modules, and is configured via the `sm-config` folder.

```
nersc/julia
├── render.sh
├── render_tmp.sh
└── sm-config
    ├── install.sh
    ├── local_settings.toml
    ├── module_template.lua
    └── settings.toml
```

To install, either run: `./entrypoint.sh ./nersc/julia/render.sh` [or the
`_tmp` equivalent](#render-scripts-rendersh-vs-render_tmpsh). If you're using
`render.sh` the `juliaup` module will be located in
`/global/common/software/nersc9/julia/module` -- and if you're using
`render_tmp.sh` this will be located in `tmp/modules`.

## Jupyter Kernels

Jupyter kernels are generated using Simple Templates located under
`nersc/kernels/templates`. We also include several helper scripts (some of
which are work-in-progress).
```
nersc/kernels/
├── bootstrap.jl
├── julia-user
├── templates
│   ├── jupyter
│   │   ├── kernel-helper.sh
│   │   ├── kernel.json
│   │   ├── logo-32x32.png
│   │   └── logo-64x64.png
│   ├── render.sh
│   ├── render_tmp.sh
│   └── settings.toml
└── user
    └── install_env_kernel.jl
```
To generate the NERSC Julia Jupyter kernels, either run: `./entrypoint.sh
./nersc/kernels/templates/render.sh` [or the `_tmp`
equivalent](#render-scripts-rendersh-vs-render_tmpsh). This will render a
single-threaded and a multi-threaded version.

The [NERSC Julia Jupyter Kernel](./kernels/templates/jupyter/kernel.json) uses
a [Kernel Helper](./kernels/templates/jupyter/kernel-helper.sh) script in order
to do 3 things:
1. Load any dependent modules
2. Set environment variables (e.g. `JULIA_NUM_THREADS`)
3. Ensure that `IJulia` works and return its path.

For the final step above, we use the following Bash code:
```bash
readarray -t ijulia_boostrap < <(julia {{{nersc_resource_dir}}}/bootstrap.jl)

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
```
Which runs the `bootstrap.jl` script, prints every line of output (helpful for
logging) and assumes that the last line of output is the path of the `IJulia`
kernel.

### Julia Kernel Bootstrapping

The Jupyter kernel requires [IJulia](https://github.com/JuliaLang/IJulia.jl),
and we want to allow users to control as much about their default Julia
environments. Therefore the strategy adopted here is to automatically add
`IJulia` to their default Julia environment (it not added already), and to
ensure that it works. To streamline this process the [NERSC Julia Jupyter
Bootstrap Script](./kernels/bootstrap.jl) does 3 things:
1. Checks if `IJulia` is installed. If not, runs `Pkg.add("IJulia")`.
2. Checks if `IJulia` can be imported. If not, runs `Pkg.build("IJulia")`.
3. Prints the path of the `IJulia` Jupyter kernel.

## Helper Scripts

These are templates of simple helper scripts that make all of our lives just a
little bit easier. They are not crucial for the site deployment, but improve
the ergonomics around working with cutting edge modules.

```
nersc/scripts/
└── templates
    ├── bin
    │   ├── activate_beta.sh
    │   ├── deactivate_beta.sh
    │   └── install_beta.sh
    ├── render.sh
    ├── render_tmp.sh
    └── settings.toml
```

To generate the helper scripts, either run: `./entrypoint.sh
./nersc/scripts/templates/render.sh` [or the `_tmp`
equivalent](#render-scripts-rendersh-vs-render_tmpsh). This will render all the
helper scripts in `nersc/scripts/templates/bin`:
1. `activate_beta.sh`: when sourced, this script puts the `julia/modules`
   folder into the `MODULEPATH` -- allows users to try out newer versions of
   julia before the new module files have passed review.
2. `deactivate_beta.sh`: undoes `source activate_beta.sh`
3. `install_beta.sh`: installs beta versions of the Jupyter kernels to
   `~/.local/share/jupyter/kernels`

### Preferences Fact Finding

```
nersc/util
├── get_mpi_settings.jl
└── mpi_proj
    └── Project.toml
```
