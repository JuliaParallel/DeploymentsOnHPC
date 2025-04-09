help([[
Julia installer and version multiplexer
https://github.com/JuliaLang/juliaup
]])

whatis("Name: juliaup")
whatis("Version: {{{INSTALL_VERSION}}}")
whatis("URL: https://github.com/JuliaLang/juliaup")

-------------------------------------------------------------------------------
--- JULIAUP Binary
-------------------------------------------------------------------------------

append_path("PATH", "{{{BIN_PATH}}}")

-------------------------------------------------------------------------------
--- Site-Wide Julia Settings
--
-- Julia has a mechanism by which settings can be injectect into the
-- Preferences.jl stack. This is done by creating a system-wide Julia project
-- contianing a LocalPreferences.toml file and ensurign that this project is on
-- the user's JULIA_LOAD_PATH.
--
-- At NERSC there are several different versions of these site-wide settings in
-- order to account for different MPI, and CUDA versions.
-------------------------------------------------------------------------------

-- PE_ENV, FAMILY_MPI, and FAMILY_CUDATOOLKIT are environment variables set by
-- Lmod. We use these to discriminate between different site-wide settings (see
-- below), which depend on the PrgEnv, MPI version, and CUDA toolkit versions
-- respectively.
local PE_ENV = os.getenv("PE_ENV"):lower()
local FAMILY_MPI = os.getenv("LMOD_FAMILY_MPI"):lower()
local FAMILY_CUDATOOLKIT = os.getenv("LMOD_FAMILY_CUDATOOLKIT_VERSION"):lower()
-- Julia environment name: {PE}.{MPI}.{CUDA}
local ENV_NAME = PE_ENV .. "." .. FAMILY_MPI .. ".cuda" .. FAMILY_CUDATOOLKIT
-- The JULIA_LOAD_PATH depends on the PE and cudatoolkit modules loaded. If the
-- user loads juliaup, and then changes one of these, the value that
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
-- NERSC has a couple utlity scripts (often in response of tickets), eg.
-- generate custom Jupyter kernels.
-------------------------------------------------------------------------------

append_path("PATH", "{{{SCRIPT_PATH}}}")


-------------------------------------------------------------------------------
--- NERSC-Specific Workarounds
--
-- Here we keep any hacks/workarounds for NERSC.
-------------------------------------------------------------------------------

-- https://github.com/JuliaLang/julia/issues/53339
setenv("JULIA_SSL_CA_ROOTS_PATH", "/etc/ssl/ca-bundle.pem")
