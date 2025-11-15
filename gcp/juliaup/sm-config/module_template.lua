help([[
Julia installer and version multiplexer
https://github.com/JuliaLang/juliaup
]])

whatis("Name: juliaup")
whatis("Version: {{{INSTALL_VERSION}}}")
whatis("URL: https://github.com/JuliaLang/juliaup")

{{#use_dependencies}}
-------------------------------------------------------------------------------
--- Requirements on External Dependencies
-------------------------------------------------------------------------------

-- ensure that cudatoolkit is loaded -- even if the user loads the `cpu`
-- module, as some Julia packages will depend on CUDA (and we can't control
-- that these don't get loaded from the module)
depends_on("openmpi")
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

local PE_ENV = "builtin"
local FAMILY_MPI = "openmpi"
local FAMILY_CUDATOOLKIT = "12.4"
-- Julia environment name: {PE}.{MPI}.{CUDA}
local ENV_NAME = PE_ENV .. "." .. FAMILY_MPI .. ".cuda" .. FAMILY_CUDATOOLKIT
-- The `JULIA_LOAD_PATH` depends on the PE and cudatoolkit modules loaded. If
-- the user loads `juliaup`, and then changes one of these, the value that
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
--- NERSC-Specific Helper and Utility Scripts
--
-- NERSC has a couple utility scripts (often in response of tickets), e.g.
-- generate custom Jupyter kernels.
-------------------------------------------------------------------------------

append_path("PATH", "{{{SCRIPT_PATH}}}")
