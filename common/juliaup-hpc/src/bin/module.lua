-------------------------------------------------------------------------------
-- sets up environment and defines common helper functions
--------------------------------------------------------------------------------
local gears = require "gears"

-- dependencies
local argparse = require "argparse"
local lustache = require "lustache"
local f        = require "F"
local sh       = require "sh"
local log      = require "log"
local posix    = require "posix"

--------------------------------------------------------------------------------
-- manage environment for install and produced artifacts
--------------------------------------------------------------------------------

local function setenv(k, env)
    log.info(f"Setting environment: {k}={env}")
    posix.setenv(k, env)
end

local function find_installed_artifacts(prefix)
    local target = "^julia%-(.*)%+.*$"

    log.trace(f"Looking for {target} in {prefix} ...")

    local installed_artifacts = {}

    if not gears.isdir(prefix) then
        log.warn("Prefix: " .. prefix .. " is not a valid location")
        return installed_artifacts
    end

    for file in string.gmatch(tostring(sh.ls(prefix)), "[^\n]+") do
        log.trace(f"Analyzing {file} in {prefix}")
        if not gears.isdir(prefix .. "/" .. file) then
            log.trace(f"{file} is not a dir => skipping")
            goto continue
        end
        -- select the target folder that matches the format
        local version = string.match(file, target)
        if nil ~= version then
            log.trace(f"{file} matches {target} => considering valid artifact")
            if nil ~= installed_artifacts[version] then
                log.fatal(f"Multiple hits on target={target} in prefix={prefix}")
                error("Non-unique artifact.")
            end
            installed_artifacts[version] = gears.realdir(
                prefix .. "/" .. file
            )
        else
            log.trace(f"{file} does not match {target}")
        end

        ::continue::
    end

    --check if any artifacts have been found, if not raise error:
    if nil == next(installed_artifacts) then
        log.fatal("Did not find any artifacts!")
        log.debug(f"Prefix: {prefix}")
        log.debug(f"Format: {target}")
        log.debug(f"ls {prefix}:")
        for elt in string.gmatch(tostring(sh.ls(prefix)), "[^\n]+") do
            log.debug(f"    {elt}")
        end
        error("Artificat discovery error.")
    end
    return installed_artifacts
end

--------------------------------------------------------------------------------
-- helper functions for manipulating string and lists
--------------------------------------------------------------------------------

local function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end

    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end

    return t
end

local function depstr(deps)
    local esc = {}
    for i, v in ipairs(deps) do
        esc[i] = "\"" .. v .. "\""
    end
    return table.concat(esc, ", ")
end

-------------------------------------------------------------------------------
-- parse settings
--------------------------------------------------------------------------------

-- set up CLI parser
local parser = argparse(
    "juliaup-hpc",
    "Wrapper for juilaup to produce HPC-compatible modules"
)
parser:argument("op", "Juliaup Operation"):args(1)
parser:argument("op_args", "Juliaup Operation Argument"):args("*")
parser:option("--dest", "Location of the Juliaup depot and module dir"):args(1)
parser:option("--deps", "List of dependencies"):args("*")
-- parse
local args = parser:parse()
-- ensure that a destination arguments is given
if nil == args.dest then
    log.fatal("You must specify a destination path")
    error("CLI input error")
end
-- set "juliaup" as default dependency
if nil == args.deps then
    log.warn(table.concat({
        "The'--deps' CLI argument is ommited => autmatically adding 'juliaup'!",
        "This is default behavior, add '--deps=' (blank argument) to disable",
        "all module dependencies"
    }, " "))
    -- default dependency
    args.deps = {"juliaup"}
end
-- parse dependencies: dependencies are given as a comma-separated list => split
-- these into a table
local n_deps  = 0
local deps    = {}
if #args.deps > 0 then
    deps   = split(args.deps[1], ",")
    n_deps = #deps
    log.debug(f"n_deps={n_deps}; deps={" .. table.concat(deps, ", ") .."}")
else
    log.debug("No Lmod dependencies requested")
end
-- parse operator arguments: these will be given directly to juliaup =>
-- concatenate them into a space-delimited string
local n_op_args = 0
local op_arg_st = ""
if nil ~= args.op_args then
    n_op_args = #args.op_args
    op_arg_st = table.concat(args.op_args, " ")
    log.debug(f"n_op_args={n_op_args}; op_arg_st={op_arg_st}")
else
    log.debug("No operation arguments given")
end
-- concatenate operator with operator arguments
local operation = args.op
if n_op_args > 0 then
    operation = table.concat({args.op, op_arg_st}, " ")
end

--------------------------------------------------------------------------------
-- Run Juliaup and find installation targets for each version
--------------------------------------------------------------------------------

log.info("Running Juliaup")
local cmd = table.concat({
    "juliaup",
    table.concat({args.op, op_arg_st}, " ")
}, " ")

setenv("JULIAUP_DEPOT_PATH", args.dest)
log.info(f"Running: {cmd}")
os.execute(cmd)

-- don't do anything further if not installing anything
if "add" ~= args.op then
    log.trace("Operation does not install artifacts => don't generate modules")
    log.info(">>> DONE DONE DONE DONE DONE DONE <<<")
    os.exit(0)
end

-- install mode => look for installed artifacts
local installed_artifacts = find_installed_artifacts(args.dest .. "/juliaup")
-- summarize installed versions
log.info("Found following Julia versions installed by Juliaup:")
for k,v in pairs(installed_artifacts) do
    log.info(k, v)
end

-------------------------------------------------------------------------------
-- generate modules
--------------------------------------------------------------------------------

local template = [[
help("User-defined Julia module")

whatis("Name: julia")
whatis("Version: {{{INSTALL_VERSION}}}")
whatis("URL: https://https://julialang.org/")

{{#USE_DEPENDENCIES}}
depends_on({{{DEPENDENCIES}}})
{{/USE_DEPENDENCIES}}

setenv("JULIAUP_DEPOT_PATH", "{{{JULIAUP_DEPOT_PATH}}}")
prepend_path("PATH", "{{{JULIA_PATH}}}")
]]

-- iterate over versions and generate module based on template file
log.info("Generating modules ...")

local module_dir = args.dest .. "/modules/julia"
sh.mkdir("-p", module_dir) -- ensure order => don't use table
-- fill in module template for each version
for version, artifact in pairs(installed_artifacts) do
    log.info(f"Generating module for version {version}")

    -- build module parameter file
    local module_params = {
        INSTALL_VERSION = version,
        USE_DEPENDENCIES = n_deps > 0,
        DEPENDENCIES = depstr(deps),
        JULIAUP_DEPOT_PATH = args.dest,
        JULIA_PATH = artifact .. "/bin"
    }
    -- print for debug purposes
    for k,v in pairs(module_params) do
        log.info(k, v)
    end

    -- generate module file
    local mod = lustache:render(template, module_params)
    -- save rendered module file
    local module_path = module_dir .. f"/{version}.lua"
    local module_file = io.open(module_path, "w")
    if nil == module_file then
        log.fatal("Could not create module file")
        error("Install file creation failed.")
    end
    module_file:write(mod)
    module_file:close()
end

--------------------------------------------------------------------------------
-- DONE! (the end)
--------------------------------------------------------------------------------

log.info(">>> DONE DONE DONE DONE DONE DONE <<<")
