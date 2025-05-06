#!/usr/bin/env lua

--------------------------------------------------------------------------------
-- INITIALIZE PROJECT
--------------------------------------------------------------------------------

local function init()
    -- function to prepend `pth` the the package search path, using `pth` as a
    -- key to prevent duplicates

    local function prepend_path(pth)
        ---@diagnostic disable-next-line: undefined-field
        if package.user_modules and (true == package.user_modules[pth]) then
            return
        end
        -- prepend to path
        package.path = pth .. ";" .. package.path
        -- add key to user modules
        if not package.user_modules then package.user_modules = {} end
        package.user_modules[pth] = true
    end

    local pth = debug.getinfo(2).source:match("@?(.*/)")
    -- if this program is called within the current directory then the path
    -- won't contain '/', returning (nil)
    if pth == nil then
        prepend_path("./build/?.lua")
        prepend_path("../lib/?.lua")
        prepend_path("./?.lua")
        return
    end
    -- remember to remove the traling slash
    prepend_path(pth:sub(1, -2) .. "/build/?.lua")
    prepend_path(pth:sub(1, -2) .. "/../lib/?.lua")
    prepend_path(pth:sub(1, -2) .. "/?.lua")
end

init()


--------------------------------------------------------------------------------
-- sets up environment and defines common helper functions
--------------------------------------------------------------------------------
local gears = require "gears"
local log   = require "log"
local f     = require "F"


local dir = gears.thisdir()


--------------------------------------------------------------------------------
-- find all dependency names in lib folder
--------------------------------------------------------------------------------
local function basename(filename)
    -- find the last dot in the filename
    local last_dot_index = string.find(filename, "%.[^%.]*$")
    if last_dot_index then return string.sub(filename, 1, last_dot_index - 1)
    else return filename -- no extension found
    end
end

local function libs(pth, name)
    local lib_names = {}
    log.debug(f"Scanning: Path = {pth}, Module = {name}")
    for _, d in pairs(gears.read_dir(pth)) do
        log.debug(f"Found: {d.name}, is_dir={d.is_dir}")
        if d.is_dir then
            log.trace(f"Entering: {d.name}")
            local s_libs = libs(pth .. "/" .. d.name, d.name)
            for _, v in pairs(s_libs) do lib_names[#lib_names+1] = v end
        end
        if string.find(d.name, "%.lua$") then
            local fq_module_name = basename(d.name)
            if name ~= nil then
                fq_module_name = name .. "." .. fq_module_name
            end
            lib_names[#lib_names+1] = fq_module_name
        end
    end

    return lib_names
end

log.info("Start scanning for dependencies...")
local deps = libs(dir .. "/../lib")
log.info("... Done! Detected the following dependencies:")
log.info(table.concat(deps, ", "))

--------------------------------------------------------------------------------
-- command-line utilitiy (simple form)
--------------------------------------------------------------------------------
---@diagnostic disable-next-line: unused-local
local main_source = arg[1]

local env   = setmetatable({}, { __index = _G })
local amalg = assert(
    loadfile(f"{dir}/build/amalg.lua", "t", env),
    f"Failed to load: {dir}/build/amalg.lua"
)

log.info(
    f"Amalgamating {main_source} and dependencies into: {dir}/../../{arg[2]}"
)

amalg(
    "-o", f"{dir}/../{arg[2]}",
    "-s", f"{dir}/{main_source}",
    table.unpack(deps)
)

log.info("SUCCESS!")
