#!/usr/bin/lua

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
-- RUN PROJECT
--------------------------------------------------------------------------------
require "module"
