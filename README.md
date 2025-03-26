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
settings ([TOML](https://toml.io/en/) version 0.4) file.

#### Simple Templates Settings Files

Simple Templates settings TOML files can have 3 sections: `[constant]`,
`[product]`, and `[zip]`.
1. Settings under `[constant]` are rendered into the template verbatim -- that
   is a list in this section is rendered as a list.
2. If settings under `[product]` are a list, then Simple Templates will render
   the product space (i.e. every combination of items from every list) into the
   template. E.g. `x = [1,2]` and `y=["a", "b", "c"]` will render the template
   6 times with every combination of items from `x` and `y`. Any non-list
   setting under this section will be treated as a list of size 1.
3. If settings under `[zip]` are a list, then Simple Templates willr ender the
   "zip space" (i.e. the first item of each list, the the second of each, and
   so on). Lists under this section must be all of the same lenght. Any
   non-list setting under this section will be treated as a list of the same
   item with the same length as the other lists under this section.

For example, the settings file:
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
Will result in 4 rendered templates, each constaining a different setting for
`cuda_version`

#### Simple Templates Output

You can pass a mustache template in a string as an output file name to Simple
Templates. Simple Templates will fill these in before saving the file -- this
way you can direct different instances of the same template to different
locations. E.g. the file name string:
`"../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/LocalPreferences.toml"`
will result in each template invocation being saved to a different folder.
Simplate Templates creates any directories as needed.

#### Simple Templates Overwrites

You can overwrite any setting in a Simple Templates settings file using the
`--overwrite` command line flag. The input to this flag needs to be a
Json-formatted list of key-vaylue pairs (where the key is the setting to be
overwritten, and the value is its new value). Note that only constants can be
overwritten. Eg: `--overwrite "{\"nersc_resource_dir\": \"${RESOURCE_DIR}\"}"`
overwrites the `nersc_resource_dir` constant setting with the environment
varaible `RESOURCE_DIR`.

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
