# A Collection of Julia Deployments on HPC Systems

A collection of module-centric Julia deployments on HPC systems.

## How to use this Repository

Resuirements:
1. [Lua](https://www.lua.org/download.html) and
   [luaposix](https://github.com/luaposix/luaposix)
2. [Lmod](https://lmod.readthedocs.io/en/latest/030_installing.html) or
   [Environment Modules](https://modules.readthedocs.io/en/latest/INSTALL.html)

### Use the Entrypoint

[entrypoint.sh](./entrypoint.sh)

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

#### Why not somethig like Jinja?

With the exception of Lua and LMod, the objective of this approach is to be as
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

### Use Modules (lmod) As Much As Possible

## NERSC

[Description here](./nersc/README.md)
