help([[
Julia installer and version multiplexer
https://github.com/JuliaLang/juliaup
]])

whatis("Name: juliaup")
whatis("Version: {{{INSTALL_VERSION}}}")
whatis("URL: https://github.com/JuliaLang/juliaup")

-- -------------------------------------------------------------------------------
-- --- Helper function to check the $CUDA_HOME directory for the CUDA version
-- -------------------------------------------------------------------------------
-- local function cuda_version()
--     -- the `cuda` module might not be loaded yet (don't worry, it will be as
--     -- it's a module dependency)
--     local chome = os.getenv("CUDA_HOME")
--     if nil == chome then return "0.0" end
--     -- a bit of a hack: read the version.json to get the cuda version
--     local proc  = assert(io.popen(
--         "cat "..chome.."/version.json | jq -r .cuda.version | cut -d '.' -f 1-2"
--     ))
--     local result = proc:read("*all"):gsub("[\n,\r]", "")
--     proc:close()
--     return result
-- end

{{#use_dependencies}}
-------------------------------------------------------------------------------
--- Requirements on External Dependencies
-------------------------------------------------------------------------------

-- ensure that cuda and mpi are loaded as some Julia packages will depend on
-- CUDA and MPI (and we can't control that these don't get loaded from the
-- module). MPI and CUDA are both loaded by `julia-env`.
depends_on("julia-env")
{{/use_dependencies}}

-------------------------------------------------------------------------------
--- JULIAUP Binary
-------------------------------------------------------------------------------

append_path("PATH", "{{{BIN_PATH}}}")

-------------------------------------------------------------------------------
--- Site-Wide Julia Settings
--
-- Julia has a mechanism by which settings can be injected into the
-- Preferences.jl stack. This is done by creating a system-wide Julia project
-- containing a LocalPreferences.toml file and ensuring that this project is on
-- the user's JULIA_LOAD_PATH.
-------------------------------------------------------------------------------

-- At PSC there are several different versions of these site-wide settings in
-- order to account for different MPI (detected using the `__JULIA_COMPILER`,
-- `__JULIA_MPI_VERSION` env vars), and CUDA versions (detected using the
-- `__JULIA_CUDA_VERSION` env var).
local COMPILER = os.getenv("__JULIA_COMPILER")
local MPI_VERSION = os.getenv("__JULIA_MPI_VERSION")
local CUDA_VERSION = os.getenv("__JULIA_CUDA_VERSION")
local BAD = (nil == COMPILER) or (nil == MPI_VERSION) or (nil == CUDA_VERSION)
if (BAD and (mode() == "load")) then
    -- workaround for PSC: we need to detect which MPI, and CUDA version are
    -- loaded. Doing this automatically is brittle and complicated involving
    -- string parsing. That would probably be too hard to reliably maintain. So
    -- instead, we pint an error message, including a suggested module load
    -- command which loads the default `julia-env` modules.
    LmodError([[
Could not detect `__JULIA_COMPILER`, `__JULIA_MPI_VERSION`, and
`__JULIA_CUDA_VERSION` in the environment. These are set up the `julia-env`
module. Please run (or specify a cuda and open-mpi version):
```
module load julia-env
```
    ]])
elseif BAD then
    COMPILER = ""
    MPI_VERSION = ""
    CUDA_VERSION = ""
end
COMPILER = COMPILER:lower()
MPI_VERSION = MPI_VERSION:lower()
CUDA_VERSION = CUDA_VERSION:lower()
-- Julia environment name: {COMPILER}.{MPI}.{CUDA}
local ENV_NAME = COMPILER .. ".ompi" .. MPI_VERSION .. ".cuda" .. CUDA_VERSION
-- The `JULIA_LOAD_PATH` depends on the compiler, MPI, and CUDA modules loaded.
-- If the user loads `juliaup`, and then changes one of these, the value that
-- `JULIA_LOAD_PATH` is set to will change. This potentially causes Lmod to
-- loose track of what changes it has made to the env => we "remember" what
-- `JULIA_LOAD_PATH` was set to by using the `__JULIAUP_MODULE_JULIA_LOAD_PATH`
-- env var as as follows:
--  * When `JULIA_LOAD_PATH` is set, also add the same value to:
--    `__JULIAUP_MODULE_JULIA_LOAD_PATH`
--  * When `JULIA_LOAD_PATH` is unset (during module unload), do _not_ compute
--    the value of `JULIA_LOAD_PATH`, instead retrieve the value from
--    `__JULIAUP_MODULE_JULIA_LOAD_PATH`.
local JULIA_LOAD_PATH
if ("unload" == mode()) then
    -- This the value of `JULIA_LOAD_PATH` before any other changes to the
    -- environment
    JULIA_LOAD_PATH = os.getenv("__JULIAUP_MODULE_JULIA_LOAD_PATH")
else
    -- In Julia `:` represents the Julia standard library. A Julia quirk is
    -- that if `JULIA_LOAD_PATH` is empty, it's assumed to be equal to `:` only
    -- prepend ":" to `JULIA_LOAD_PATH` if it's empty => If you're appending to
    -- and "empty" `JULIA_LOAD_PATH`, you MUST make sure that it starts with
    -- `:`, otherwise you'll loose part of the stdlib :(
    if (nil == os.getenv("JULIA_LOAD_PATH")) then
        JULIA_LOAD_PATH = ":{{{JULIA_LOAD_PATH_PREFIX}}}/" .. ENV_NAME
    else
        JULIA_LOAD_PATH = "{{{JULIA_LOAD_PATH_PREFIX}}}/" .. ENV_NAME
    end
end
-- Used to keep track of the JULIA_LOAD_PATH, even if the environment changed
-- between load and unload
setenv("__JULIAUP_MODULE_JULIA_LOAD_PATH", JULIA_LOAD_PATH)
-- Add site-wide settings
append_path("JULIA_LOAD_PATH", JULIA_LOAD_PATH)

-------------------------------------------------------------------------------
--- PSC-Specific Helper and Utility Scripts
--
-- PSC has a couple utility scripts (often in response of tickets), e.g.
-- generate custom Jupyter kernels.
-------------------------------------------------------------------------------

append_path("PATH", "{{{SCRIPT_PATH}}}")
