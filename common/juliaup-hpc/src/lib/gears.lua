#!/usr/bin/env lua

local M = {}

local F     = require "F"
local posix = require "posix"
local sh    = require "sh"
local safer = require "safer"


-- Distable globals from hereon out
if not _GEARS_UNSAFE then safer.globals() end


--[[ function to retun the path of the current file --]]
function M.thisdir(level)
    level = level or 2
    local pth = debug.getinfo(level).source:match("@?(.*/)")
    -- if this program is called within the current directory then the path
    -- won't contain '/', returning (nil)
    if pth == nil then
        return tostring(sh.pwd())
    end
    -- remember to remove the traling slash
    return tostring(sh.pushd(pth):pwd():popd())
end


function M.realdir(pth)
    return tostring(sh.pushd(pth):pwd():popd())
end


function M.read_dir(dir)
    local directory = {}
    for s in tostring(sh.ls(dir)):gmatch("[^\n]+") do
        directory[#directory+1] = {
            name = s,
            is_dir = M.isdir(dir .. "/" .. s)
        }
    end
    return directory
end


function M.parse_version(version_str)
    local t = {}
    for i in string.gmatch(version_str, '(%d+)') do
        t[#t+1] = i
    end
    return t
end


function M.file_exists(name)
   local f = io.open(name, "r")
   if f == nil then
       return false
   end
   io.close(f)
   return true
end


-- get all lines from a file, returns an empty list/table if the file does not
-- exist
function M.read_lines(file)
    if not M.file_exists(file) then return {} end

    local lines = {}
    for line in io.lines(file) do
        lines[#lines + 1] = line
    end

    return lines
end


function M.isdir(fn)
    return (posix.stat(fn, "type") == "directory")
end


function M.dir_exists(name)
    return M.isdir(name)
end


function M.ensure_dir(name)
    sh.mkdir("-p", name) -- ensure order => don't use table
end


function M.banner(message, marker, length)
    local first = marker
    local second = marker

    local first_length = math.floor(length/2 - 1 - string.len(message)/2)
    local second_length = length - string.len(message) - first_length - 1

    for _ = 1 , first_length do
        first = first .. marker
    end

    for _ = 1 , second_length do
        second = second .. marker
    end

    local delim = " "
    if string.len(message) == 0 then delim = marker end

    return first .. delim .. message .. delim .. second
end


---@diagnostic disable-next-line: unused-local
function M.mk_log_dir(self, dir)
    local rs
    rs = F"{dir}/logs"

    -- Find highest-numbered log dir
    local files = tostring(sh.ls(rs))
    local highest_log_dir = 0
    for f in string.gmatch(files, "(%d+)") do
        highest_log_dir = math.max(highest_log_dir, tonumber(f))
    end

    -- Target log dir is one higher than the currently highest-numbered log dir
    ---@diagnostic disable-next-line: unused-local
    local target = highest_log_dir + 1
    rs = F"{rs}/{target}"
    -- Create directory
    self.ensure_dir(rs)
    -- Set the internal `LOG_DIR` value to this path
    self.LOG_DIR = rs
    return rs
end


---@diagnostic disable-next-line: unused-local
function M.log_sh(self, name, cmd)
    local file_stdout = io.open(F"{self.LOG_DIR}/{name}.out", "a")
    if file_stdout ~= nil then
        file_stdout:write(sh.stdout(cmd))
        file_stdout:close()
    end

    local file_stderr = io.open(F"{self.LOG_DIR}/{name}.err", "a")
    if file_stderr ~= nil then
        file_stderr:write(sh.stderr(cmd))
        file_stderr:close()
    end
end

-- 
-- Extract parent directiory, file name, and extension (order of returns) from a
-- path. Example usage:
--
-- > require("gears").basename([[/mnt/tmp/myfile.txt]])
-- "/mnt/tmp/" "myfile.txt"    "txt"
--
function M.basename(path)
    -- ChatGPT Explanation of the regex (seems legit...)
    --
    -- ### 1\. **`(.-)`**
    --  * `.` matches any character except a newline.
    --  * `-` makes it _lazy_ (matches the shortest possible sequence).
    --  * This part captures everything up to the last part of the path (i.e.,
    --    the directory portion).
    --
    -- ### 2\. **`([^\\/]-%.?([^%.\\/]*))`**
    -- * `[^\\/]` matches any character except `\` or `/` (to avoid matching
    --   directory separators).
    -- * `-` makes it _lazy_ again. * `%` is used to escape `.` because `.`
    --   normally matches any character.
    -- * `.?` means that the `.` (dot) is optional (i.e., to account for
    --   filenames that might not have an extension).
    -- * `([^%.\\/]*)` captures the file extension (anything after the last `.`
    --   in the filename).
    --
    -- ### 3\. **`$`**
    --  * Ensures the regex matches only at the end of the string.
    --
    return string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
end

return M
