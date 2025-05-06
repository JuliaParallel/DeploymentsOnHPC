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

## How Juliaup-HPC Helps



## Future Work

In many ways wrapper scripts make HPC unintuitive to use and lead to brittle
workflows (looking at you HPE Cray!), so we will be exploring ways to make
Juliaup support this kind of use case by:
1. [ ] Provide a download script for versions without `selfupdate`
2. [ ] Something like an "HPC mode" which uses
   [Mustache](https://github.com/nickel-org/rust-mustache) to generate
   modulefiles for the system its deployed on

Crucial is that any of these changes don't break the Juliaup workflow for the
vast majority of users.
