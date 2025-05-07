# Juliaup on HPC

[Juliaup](https://github.com/JuliaLang/juliaup) is the official installer and
version multiplexer for the [Julia language](https://julialang.org/). It is
optimized for managing Julia versions in user directories (which are mostly XDG
compliant) -- and it does an incredible job at that, so we want to make it as
useful for HPC as possible (surely beats `wget`).

Unfortunately the design trade offs that make Juliaup great for small-scale and
single-user environments run into the following problems on large-scale HPC:
1. Juliaup makes assumptions about the file systems to which it is deployed: i)
   that is has write access; ii) that it can set file locks. Both of these
   assumptions break down on many-user shared file systems.
2. Most HPC systems have perfectly good module systems to manage settings and
   versions -- interacting with these is the preferred approach, as it meshes
   better with institutional procedures such as job startup, file system
   optimization, and how shared software is managed (e.g during maintenances).
3. Software that is meant to run at scale shouldn't live in your `$HOME`
   directory (this way HPC deviates from the defaults in the XDG Base Directory
   Specification).

Essentially what works well in HPC is a tool that downloads software to a
specific location (one that can be configured by the user), and bundles it with
the appropriate module file, so that the center's module system can configure
the runtime environment in a way that works well at scale.

## How Juliaup-HPC Helps Deploy a Shared Juliaup Instance on HPC

Juliaup-HPC builds a Juliaup version without the `selfupdate` feature enabled
in cargo, this allows commands like `juliaup add 1.12` to run from read-only
file systems (e.g. shared software installs). We use [Simple
Modules](https://gitlab.blaschke.science/nersc/simple-modules) to bootstrap a
Rust install (using [Rustup](https://rustup.rs/)), so that we can compile
Juliaup.

The rest of Juliaup-HPC is a Lua wrapper script that does two things:
1. It invokes Juliaup with the `JULIAUP_DEPOT_PATH` passed as the `--dest`
   argument (this makes it easier to specify _where_ you want Julia installed).
2. After every time that Juliaup is run, it checks the `JULIAUP_DEPOT_PATH` for
   any newly installed Julia versions, and generates module files which:
    1. set `JULIAUP_DEPOT_PATH` -- this makes it possible to use Juliaup's
       `julia` multiplexer without picking up the "wrong" Juliaup Depot. 
    2. _prepend_ `PATH` -- this is set to point to the location of the `julia`
       binary (not the Julia multiplexer), allowing the user to bypass the
       Juliaup `julia` multiplexer (which can have problems on large-scale
       shared HPC file systems).

## Future Work

In many ways wrapper scripts make HPC unintuitive to use and lead to brittle
workflows (looking at you HPE Cray!), so we will be exploring ways to make
Juliaup support this kind of use case by:
1. [ ] Provide a download script for versions without `selfupdate`
2. [ ] Something like an "HPC mode" which uses
   [Mustache](https://github.com/nickel-org/rust-mustache) to generate
   modulefiles for the system its deployed on.

Crucial is that any of these changes don't break the Juliaup workflow for the
vast majority of users.
