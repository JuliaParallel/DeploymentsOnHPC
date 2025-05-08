# Developing the Juliaup-HPC Wrapper Scripts

The source code for Juliaup-HPC lives in
`common/juliaup-hpc/src/bin/module.lua` and all of its dependencies are stored
under `common/juliaup-hpc/src/lib` -- the overall project structure is as
follows:

```
common/juliaup-hpc/
├── dist
│   ├── juliaup-hpc     # gerenated by amalg using common/juliaup-hpc/src/Makefile
│   └── juliaup-hpc.lua # gerenated by amalg using common/juliaup-hpc/src/Makefile
└── src
    ├── Makefile        # gerenates common/juliaup-hpc/dist
    ├── bin
    │   ├── build       # build-time dependencies (amalg)
    │   ├── build.lua   # run amalg to gereate common/juliaup-hpc/dist
    │   ├── launch.lua  # add ../lib to LUA_PATH and run module.lua
    │   └── module.lua  # source code for Juliaup-HPC
    └── lib             # dependencies for build.lua, launch.lua, and module.lua
```

The development frameworks is as follows:
1. Add any dependencies to `common/juliaup-hpc/src/lib` -- this will make
   `build.lua` and `launch.lua` automatically find this dependency and all it
   to lua's `package.path` (also `LUA_PATH`), when running 
2. Most of the source code lives in `common/juliaup-hpc/src/bin/module.lua`,
   but you can also add sources to `common/juliaup-hpc/src/lib` (for example
   `gears.lua` -- which is a collection of helper scripts that we just want out
   the the way).
3. For testing, run `launch.lua` -- this will ensure that `LUA_PATH` is
   correctly set before running `module.lua`
4. To build a single-source script, run `build.lua` (or simply the `Makefile`),
   this will run `amalg` which combines all the sources including any
   dependencies in `common/juliaup-hpc/src/lib` into a single lua file (in
   `common/juliaup-hpc/dist`)
