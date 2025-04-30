# A Collection of Julia Deployments on HPC Systems

A collection of module-centric Julia deployments on HPC systems.

## How to use this Repository

Resuirements:
1. [Lua](https://www.lua.org/download.html) and
   [luaposix](https://github.com/luaposix/luaposix)
2. [Lmod](https://lmod.readthedocs.io/en/latest/030_installing.html) or
   [Environment Modules](https://modules.readthedocs.io/en/latest/INSTALL.html)

### Use the Entrypoint

Bash kinda sucks at finding related files -- an imperfect (but acceptable)
solution is to use a launcher script: [entrypoint.sh](./entrypoint.sh). For
example, if you want to render all Julia environment configuration files,
please run: 
```
$ ./entrypoint.sh nersc/environments/templates/render.sh 
```
This can be run from anywhere because `entrypoint.sh` sets two environment
variables `__PREFIX__`, and `__DIR__`:
* `__PREFIX__` contains the location of the project root (i.e. Where
`entrypoint.sh` is saved)
* `__DIR__` contains the location of he script being run

### Rendering Templates

This project uses [Simple
Templates](https://gitlab.blaschke.science/nersc/simple-templates) to render
templates. A standalone version of Simple Templates is located at:
`./opt/bin/simple-templates.ex` and only requires a reasonably modern version
of Lua to run (I didn't check how modern it needs to be though).

Simple Templates takes template files formatted in the [mustache templating
language](https://mustache.github.io/) and populates them with values from a
settings ([TOML](https://toml.io/en/) version 0.4) file. This allows us to
adapt Julia settings and modules whenever systems are reconfigured and
upgraded.

#### Why not something like Jinja?

With the exception of Lua and Lmod, the objective of this approach is to be as
self-contained as possible. More powerful templating engines need other
dependencies to be installed (e.g. a modern version of Python + a virtualenv),
which are often not present on bare-bones systems. The reason for going with
Lua is to not need a lengthy install procedure. Furthermore, more powerful
templating languages are just not needed to generate what are basically just a
bunch of settings and module files.

### Installing Modules

This project uses [Simple
Modules](https://gitlab.blaschke.science/nersc/simple-modules) to download and
install software, and to render the corresponding module files. A standalone
version of Simple Modules is located at: `./opt/bin/simple-modules.ex` and
requires a reasonably modern version of luaposix (which is used by Lmod also).

Simple Modules is a small utility that lets you easily download, build, and
deploy software modules.

### Use Modules (Lmod) As Much As Possible

We avoid activation and wrapper scripts as much as possible -- Lmod is the best
tool for modifying the runtime environment, and it is capable of unwinding
those changes when requested.

A consequence of this choice is that all configurations need to be defined when
modules are loaded, which can lead to some deployment quirks listed below.

#### Configuration Files

We use configuration files exclusively. Consequently, every conceivable
scenario needs its own set of configuration files. For example, every
combination of CUDA version and MPI toolchain needs to be accounted for. The
approach we take is to generate settings (using templates -- see above) for
every combination (the NERSC deployment is a [good example of
this](./nersc/environments/rendered/)). A module will then put the right
settings files into the `JULIA_LOAD_PATH` like so:
```lua
local PE_ENV = os.getenv("PE_ENV"):lower()
local FAMILY_MPI = os.getenv("LMOD_FAMILY_MPI"):lower()
local FAMILY_CUDATOOLKIT = os.getenv("LMOD_FAMILY_CUDATOOLKIT_VERSION"):lower()

local ENV_NAME = PE_ENV .. "." .. FAMILY_MPI .. ".cuda" .. FAMILY_CUDATOOLKIT
local JULIA_LOAD_PATH = ":{{{JULIA_LOAD_PATH_PREFIX}}}/" .. ENV_NAME

append_path("JULIA_LOAD_PATH", JULIA_LOAD_PATH)
```
(**Note:** the string `{{{JULIA_LOAD_PATH_PREFIX}}}` is a template parameter
which is filled out by Simple Modules)

#### Pitfalls Due to Interactions Between Modules

Out approach is not perfect -- one common issue is when Lmod changes dependent
modules, the values for the environment variables `PE_ENV`, `LMOD_FAMILY_MPI`,
and `LMOD_FAMILY_CUDATOOLKIT_VERSION` in the example above might change, making
Lmod "loose track" of `JULIA_LOAD_PATH`. Only imperfect (but simple) solution
is to keep track of the set value of `JULIA_LOAD_PATH` like so:
```lua
local JULIA_LOAD_PATH
if ("unload" == mode()) then
    JULIA_LOAD_PATH = os.getenv("__JULIAUP_MODULE_JULIA_LOAD_PATH")
else
    JULIA_LOAD_PATH = ":{{{JULIA_LOAD_PATH_PREFIX}}}/" .. ENV_NAME
end
setenv("__JULIAUP_MODULE_JULIA_LOAD_PATH", JULIA_LOAD_PATH)

append_path("JULIA_LOAD_PATH", JULIA_LOAD_PATH)
```
While not automagically updating `JULIA_LOAD_PATH` when `ENV_NAME` changes --
this approach allows a `module reload` to fix the `JULIA_LOAD_PATH`.

## NERSC

[Description here](./nersc/README.md)
