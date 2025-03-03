help([[
Julia installer and version multiplexer
https://github.com/JuliaLang/juliaup
]])

whatis("Name: juliaup")
whatis("Version: {{{INSTALL_VERSION}}}")
whatis("URL: https://github.com/JuliaLang/juliaup")

prepend_path("PATH", "{{{BIN_PATH}}}")

local PE_ENV = os.getenv("PE_ENV"):lower()
local FAMILY_MPI = os.getenv("LMOD_FAMILY_MPI"):lower()
local FAMILY_CUDATOOLKIT = os.getenv("LMOD_FAMILY_CUDATOOLKIT_VERSION"):lower()

local ENV_NAME = PE_ENV .. "." .. FAMILY_MPI .. ".cuda" .. FAMILY_CUDATOOLKIT
local JULIA_LOAD_PATH = ":{{{JULIA_LOAD_PATH_PREFIX}}}/" .. ENV_NAME
append_path("JULIA_LOAD_PATH", JULIA_LOAD_PATH)

-- workaround: https://github.com/JuliaLang/julia/issues/53339
setenv("JULIA_SSL_CA_ROOTS_PATH", "/etc/ssl/ca-bundle.pem")
