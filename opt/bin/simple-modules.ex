#!/usr/bin/env lua
do
local _ENV = _ENV
package.preload[ "F" ] = function( ... ) local arg = _G.arg;
local F = {}

local load = load

if _VERSION == "Lua 5.1" then
   load = function(code, name, _, env)
      local fn, err = loadstring(code, name)
      if fn then
         setfenv(fn, env)
         return fn
      end
      return nil, err
   end
end

local function scan_using(scanner, arg, searched)
   local i = 1
   repeat
      local name, value = scanner(arg, i)
      if name == searched then
         return true, value
      end
      i = i + 1
   until name == nil
   return false
end

local function snd(_, b) return b end

local function format(_, str)
   local outer_env = _ENV and (snd(scan_using(debug.getlocal, 3, "_ENV")) or snd(scan_using(debug.getupvalue, debug.getinfo(2, "f").func, "_ENV")) or _ENV) or getfenv(2)
   return (str:gsub("%b{}", function(block)
      local code, fmt = block:match("{(.*):(%%.*)}")
      code = code or block:match("{(.*)}")
      local exp_env = {}
      setmetatable(exp_env, { __index = function(_, k)
         local level = 6
         while true do
            local funcInfo = debug.getinfo(level, "f")
            if not funcInfo then break end
            local ok, value = scan_using(debug.getupvalue, funcInfo.func, k)
            if ok then return value end
            ok, value = scan_using(debug.getlocal, level + 1, k)
            if ok then return value end
            level = level + 1
         end
         return rawget(outer_env, k)
      end })
      local fn, err = load("return "..code, "expression `"..code.."`", "t", exp_env)
      if fn then
         return fmt and string.format(fmt, fn()) or tostring(fn())
      else
         error(err, 0)
      end         
   end))
end

setmetatable(F, {
   __call = format
})

return F
end
end

do
local _ENV = _ENV
package.preload[ "argparse" ] = function( ... ) local arg = _G.arg;
-- The MIT License (MIT)

-- Copyright (c) 2013 - 2018 Peter Melnichenko

-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
-- the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
-- FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
-- COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
-- IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
-- CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local function deep_update(t1, t2)
   for k, v in pairs(t2) do
      if type(v) == "table" then
         v = deep_update({}, v)
      end

      t1[k] = v
   end

   return t1
end

-- A property is a tuple {name, callback}.
-- properties.args is number of properties that can be set as arguments
-- when calling an object.
local function class(prototype, properties, parent)
   -- Class is the metatable of its instances.
   local cl = {}
   cl.__index = cl

   if parent then
      cl.__prototype = deep_update(deep_update({}, parent.__prototype), prototype)
   else
      cl.__prototype = prototype
   end

   if properties then
      local names = {}

      -- Create setter methods and fill set of property names.
      for _, property in ipairs(properties) do
         local name, callback = property[1], property[2]

         cl[name] = function(self, value)
            if not callback(self, value) then
               self["_" .. name] = value
            end

            return self
         end

         names[name] = true
      end

      function cl.__call(self, ...)
         -- When calling an object, if the first argument is a table,
         -- interpret keys as property names, else delegate arguments
         -- to corresponding setters in order.
         if type((...)) == "table" then
            for name, value in pairs((...)) do
               if names[name] then
                  self[name](self, value)
               end
            end
         else
            local nargs = select("#", ...)

            for i, property in ipairs(properties) do
               if i > nargs or i > properties.args then
                  break
               end

               local arg = select(i, ...)

               if arg ~= nil then
                  self[property[1]](self, arg)
               end
            end
         end

         return self
      end
   end

   -- If indexing class fails, fallback to its parent.
   local class_metatable = {}
   class_metatable.__index = parent

   function class_metatable.__call(self, ...)
      -- Calling a class returns its instance.
      -- Arguments are delegated to the instance.
      local object = deep_update({}, self.__prototype)
      setmetatable(object, self)
      return object(...)
   end

   return setmetatable(cl, class_metatable)
end

local function typecheck(name, types, value)
   for _, type_ in ipairs(types) do
      if type(value) == type_ then
         return true
      end
   end

   error(("bad property '%s' (%s expected, got %s)"):format(name, table.concat(types, " or "), type(value)))
end

local function typechecked(name, ...)
   local types = {...}
   return {name, function(_, value) typecheck(name, types, value) end}
end

local multiname = {"name", function(self, value)
   typecheck("name", {"string"}, value)

   for alias in value:gmatch("%S+") do
      self._name = self._name or alias
      table.insert(self._aliases, alias)
   end

   -- Do not set _name as with other properties.
   return true
end}

local function parse_boundaries(str)
   if tonumber(str) then
      return tonumber(str), tonumber(str)
   end

   if str == "*" then
      return 0, math.huge
   end

   if str == "+" then
      return 1, math.huge
   end

   if str == "?" then
      return 0, 1
   end

   if str:match "^%d+%-%d+$" then
      local min, max = str:match "^(%d+)%-(%d+)$"
      return tonumber(min), tonumber(max)
   end

   if str:match "^%d+%+$" then
      local min = str:match "^(%d+)%+$"
      return tonumber(min), math.huge
   end
end

local function boundaries(name)
   return {name, function(self, value)
      typecheck(name, {"number", "string"}, value)

      local min, max = parse_boundaries(value)

      if not min then
         error(("bad property '%s'"):format(name))
      end

      self["_min" .. name], self["_max" .. name] = min, max
   end}
end

local actions = {}

local option_action = {"action", function(_, value)
   typecheck("action", {"function", "string"}, value)

   if type(value) == "string" and not actions[value] then
      error(("unknown action '%s'"):format(value))
   end
end}

local option_init = {"init", function(self)
   self._has_init = true
end}

local option_default = {"default", function(self, value)
   if type(value) ~= "string" then
      self._init = value
      self._has_init = true
      return true
   end
end}

local add_help = {"add_help", function(self, value)
   typecheck("add_help", {"boolean", "string", "table"}, value)

   if self._has_help then
      table.remove(self._options)
      self._has_help = false
   end

   if value then
      local help = self:flag()
         :description "Show this help message and exit."
         :action(function()
            print(self:get_help())
            os.exit(0)
         end)

      if value ~= true then
         help = help(value)
      end

      if not help._name then
         help "-h" "--help"
      end

      self._has_help = true
   end
end}

local Parser = class({
   _arguments = {},
   _options = {},
   _commands = {},
   _mutexes = {},
   _groups = {},
   _require_command = true,
   _handle_options = true
}, {
   args = 3,
   typechecked("name", "string"),
   typechecked("description", "string"),
   typechecked("epilog", "string"),
   typechecked("usage", "string"),
   typechecked("help", "string"),
   typechecked("require_command", "boolean"),
   typechecked("handle_options", "boolean"),
   typechecked("action", "function"),
   typechecked("command_target", "string"),
   typechecked("help_vertical_space", "number"),
   typechecked("usage_margin", "number"),
   typechecked("usage_max_width", "number"),
   typechecked("help_usage_margin", "number"),
   typechecked("help_description_margin", "number"),
   typechecked("help_max_width", "number"),
   add_help
})

local Command = class({
   _aliases = {}
}, {
   args = 3,
   multiname,
   typechecked("description", "string"),
   typechecked("epilog", "string"),
   typechecked("target", "string"),
   typechecked("usage", "string"),
   typechecked("help", "string"),
   typechecked("require_command", "boolean"),
   typechecked("handle_options", "boolean"),
   typechecked("action", "function"),
   typechecked("command_target", "string"),
   typechecked("help_vertical_space", "number"),
   typechecked("usage_margin", "number"),
   typechecked("usage_max_width", "number"),
   typechecked("help_usage_margin", "number"),
   typechecked("help_description_margin", "number"),
   typechecked("help_max_width", "number"),
   typechecked("hidden", "boolean"),
   add_help
}, Parser)

local Argument = class({
   _minargs = 1,
   _maxargs = 1,
   _mincount = 1,
   _maxcount = 1,
   _defmode = "unused",
   _show_default = true
}, {
   args = 5,
   typechecked("name", "string"),
   typechecked("description", "string"),
   option_default,
   typechecked("convert", "function", "table"),
   boundaries("args"),
   typechecked("target", "string"),
   typechecked("defmode", "string"),
   typechecked("show_default", "boolean"),
   typechecked("argname", "string", "table"),
   typechecked("hidden", "boolean"),
   option_action,
   option_init
})

local Option = class({
   _aliases = {},
   _mincount = 0,
   _overwrite = true
}, {
   args = 6,
   multiname,
   typechecked("description", "string"),
   option_default,
   typechecked("convert", "function", "table"),
   boundaries("args"),
   boundaries("count"),
   typechecked("target", "string"),
   typechecked("defmode", "string"),
   typechecked("show_default", "boolean"),
   typechecked("overwrite", "boolean"),
   typechecked("argname", "string", "table"),
   typechecked("hidden", "boolean"),
   option_action,
   option_init
}, Argument)

function Parser:_inherit_property(name, default)
   local element = self

   while true do
      local value = element["_" .. name]

      if value ~= nil then
         return value
      end

      if not element._parent then
         return default
      end

      element = element._parent
   end
end

function Argument:_get_argument_list()
   local buf = {}
   local i = 1

   while i <= math.min(self._minargs, 3) do
      local argname = self:_get_argname(i)

      if self._default and self._defmode:find "a" then
         argname = "[" .. argname .. "]"
      end

      table.insert(buf, argname)
      i = i+1
   end

   while i <= math.min(self._maxargs, 3) do
      table.insert(buf, "[" .. self:_get_argname(i) .. "]")
      i = i+1

      if self._maxargs == math.huge then
         break
      end
   end

   if i < self._maxargs then
      table.insert(buf, "...")
   end

   return buf
end

function Argument:_get_usage()
   local usage = table.concat(self:_get_argument_list(), " ")

   if self._default and self._defmode:find "u" then
      if self._maxargs > 1 or (self._minargs == 1 and not self._defmode:find "a") then
         usage = "[" .. usage .. "]"
      end
   end

   return usage
end

function actions.store_true(result, target)
   result[target] = true
end

function actions.store_false(result, target)
   result[target] = false
end

function actions.store(result, target, argument)
   result[target] = argument
end

function actions.count(result, target, _, overwrite)
   if not overwrite then
      result[target] = result[target] + 1
   end
end

function actions.append(result, target, argument, overwrite)
   result[target] = result[target] or {}
   table.insert(result[target], argument)

   if overwrite then
      table.remove(result[target], 1)
   end
end

function actions.concat(result, target, arguments, overwrite)
   if overwrite then
      error("'concat' action can't handle too many invocations")
   end

   result[target] = result[target] or {}

   for _, argument in ipairs(arguments) do
      table.insert(result[target], argument)
   end
end

function Argument:_get_action()
   local action, init

   if self._maxcount == 1 then
      if self._maxargs == 0 then
         action, init = "store_true", nil
      else
         action, init = "store", nil
      end
   else
      if self._maxargs == 0 then
         action, init = "count", 0
      else
         action, init = "append", {}
      end
   end

   if self._action then
      action = self._action
   end

   if self._has_init then
      init = self._init
   end

   if type(action) == "string" then
      action = actions[action]
   end

   return action, init
end

-- Returns placeholder for `narg`-th argument.
function Argument:_get_argname(narg)
   local argname = self._argname or self:_get_default_argname()

   if type(argname) == "table" then
      return argname[narg]
   else
      return argname
   end
end

function Argument:_get_default_argname()
   return "<" .. self._name .. ">"
end

function Option:_get_default_argname()
   return "<" .. self:_get_default_target() .. ">"
end

-- Returns labels to be shown in the help message.
function Argument:_get_label_lines()
   return {self._name}
end

function Option:_get_label_lines()
   local argument_list = self:_get_argument_list()

   if #argument_list == 0 then
      -- Don't put aliases for simple flags like `-h` on different lines.
      return {table.concat(self._aliases, ", ")}
   end

   local longest_alias_length = -1

   for _, alias in ipairs(self._aliases) do
      longest_alias_length = math.max(longest_alias_length, #alias)
   end

   local argument_list_repr = table.concat(argument_list, " ")
   local lines = {}

   for i, alias in ipairs(self._aliases) do
      local line = (" "):rep(longest_alias_length - #alias) .. alias .. " " .. argument_list_repr

      if i ~= #self._aliases then
         line = line .. ","
      end

      table.insert(lines, line)
   end

   return lines
end

function Command:_get_label_lines()
   return {table.concat(self._aliases, ", ")}
end

function Argument:_get_description()
   if self._default and self._show_default then
      if self._description then
         return ("%s (default: %s)"):format(self._description, self._default)
      else
         return ("default: %s"):format(self._default)
      end
   else
      return self._description or ""
   end
end

function Command:_get_description()
   return self._description or ""
end

function Option:_get_usage()
   local usage = self:_get_argument_list()
   table.insert(usage, 1, self._name)
   usage = table.concat(usage, " ")

   if self._mincount == 0 or self._default then
      usage = "[" .. usage .. "]"
   end

   return usage
end

function Argument:_get_default_target()
   return self._name
end

function Option:_get_default_target()
   local res

   for _, alias in ipairs(self._aliases) do
      if alias:sub(1, 1) == alias:sub(2, 2) then
         res = alias:sub(3)
         break
      end
   end

   res = res or self._name:sub(2)
   return (res:gsub("-", "_"))
end

function Option:_is_vararg()
   return self._maxargs ~= self._minargs
end

function Parser:_get_fullname()
   local parent = self._parent
   local buf = {self._name}

   while parent do
      table.insert(buf, 1, parent._name)
      parent = parent._parent
   end

   return table.concat(buf, " ")
end

function Parser:_update_charset(charset)
   charset = charset or {}

   for _, command in ipairs(self._commands) do
      command:_update_charset(charset)
   end

   for _, option in ipairs(self._options) do
      for _, alias in ipairs(option._aliases) do
         charset[alias:sub(1, 1)] = true
      end
   end

   return charset
end

function Parser:argument(...)
   local argument = Argument(...)
   table.insert(self._arguments, argument)
   return argument
end

function Parser:option(...)
   local option = Option(...)

   if self._has_help then
      table.insert(self._options, #self._options, option)
   else
      table.insert(self._options, option)
   end

   return option
end

function Parser:flag(...)
   return self:option():args(0)(...)
end

function Parser:command(...)
   local command = Command():add_help(true)(...)
   command._parent = self
   table.insert(self._commands, command)
   return command
end

function Parser:mutex(...)
   local elements = {...}

   for i, element in ipairs(elements) do
      local mt = getmetatable(element)
      assert(mt == Option or mt == Argument, ("bad argument #%d to 'mutex' (Option or Argument expected)"):format(i))
   end

   table.insert(self._mutexes, elements)
   return self
end

function Parser:group(name, ...)
   assert(type(name) == "string", ("bad argument #1 to 'group' (string expected, got %s)"):format(type(name)))

   local group = {name = name, ...}

   for i, element in ipairs(group) do
      local mt = getmetatable(element)
      assert(mt == Option or mt == Argument or mt == Command,
         ("bad argument #%d to 'group' (Option or Argument or Command expected)"):format(i + 1))
   end

   table.insert(self._groups, group)
   return self
end

local usage_welcome = "Usage: "

function Parser:get_usage()
   if self._usage then
      return self._usage
   end

   local usage_margin = self:_inherit_property("usage_margin", #usage_welcome)
   local max_usage_width = self:_inherit_property("usage_max_width", 70)
   local lines = {usage_welcome .. self:_get_fullname()}

   local function add(s)
      if #lines[#lines]+1+#s <= max_usage_width then
         lines[#lines] = lines[#lines] .. " " .. s
      else
         lines[#lines+1] = (" "):rep(usage_margin) .. s
      end
   end

   -- Normally options are before positional arguments in usage messages.
   -- However, vararg options should be after, because they can't be reliable used
   -- before a positional argument.
   -- Mutexes come into play, too, and are shown as soon as possible.
   -- Overall, output usages in the following order:
   -- 1. Mutexes that don't have positional arguments or vararg options.
   -- 2. Options that are not in any mutexes and are not vararg.
   -- 3. Positional arguments - on their own or as a part of a mutex.
   -- 4. Remaining mutexes.
   -- 5. Remaining options.

   local elements_in_mutexes = {}
   local added_elements = {}
   local added_mutexes = {}
   local argument_to_mutexes = {}

   local function add_mutex(mutex, main_argument)
      if added_mutexes[mutex] then
         return
      end

      added_mutexes[mutex] = true
      local buf = {}

      for _, element in ipairs(mutex) do
         if not element._hidden and not added_elements[element] then
            if getmetatable(element) == Option or element == main_argument then
               table.insert(buf, element:_get_usage())
               added_elements[element] = true
            end
         end
      end

      if #buf == 1 then
         add(buf[1])
      elseif #buf > 1 then
         add("(" .. table.concat(buf, " | ") .. ")")
      end
   end

   local function add_element(element)
      if not element._hidden and not added_elements[element] then
         add(element:_get_usage())
         added_elements[element] = true
      end
   end

   for _, mutex in ipairs(self._mutexes) do
      local is_vararg = false
      local has_argument = false

      for _, element in ipairs(mutex) do
         if getmetatable(element) == Option then
            if element:_is_vararg() then
               is_vararg = true
            end
         else
            has_argument = true
            argument_to_mutexes[element] = argument_to_mutexes[element] or {}
            table.insert(argument_to_mutexes[element], mutex)
         end

         elements_in_mutexes[element] = true
      end

      if not is_vararg and not has_argument then
         add_mutex(mutex)
      end
   end

   for _, option in ipairs(self._options) do
      if not elements_in_mutexes[option] and not option:_is_vararg() then
         add_element(option)
      end
   end

   -- Add usages for positional arguments, together with one mutex containing them, if they are in a mutex.
   for _, argument in ipairs(self._arguments) do
      -- Pick a mutex as a part of which to show this argument, take the first one that's still available.
      local mutex

      if elements_in_mutexes[argument] then
         for _, argument_mutex in ipairs(argument_to_mutexes[argument]) do
            if not added_mutexes[argument_mutex] then
               mutex = argument_mutex
            end
         end
      end

      if mutex then
         add_mutex(mutex, argument)
      else
         add_element(argument)
      end
   end

   for _, mutex in ipairs(self._mutexes) do
      add_mutex(mutex)
   end

   for _, option in ipairs(self._options) do
      add_element(option)
   end

   if #self._commands > 0 then
      if self._require_command then
         add("<command>")
      else
         add("[<command>]")
      end

      add("...")
   end

   return table.concat(lines, "\n")
end

local function split_lines(s)
   if s == "" then
      return {}
   end

   local lines = {}

   if s:sub(-1) ~= "\n" then
      s = s .. "\n"
   end

   for line in s:gmatch("([^\n]*)\n") do
      table.insert(lines, line)
   end

   return lines
end

local function autowrap_line(line, max_length)
   -- Algorithm for splitting lines is simple and greedy.
   local result_lines = {}

   -- Preserve original indentation of the line, put this at the beginning of each result line.
   -- If the first word looks like a list marker ('*', '+', or '-'), add spaces so that starts
   -- of the second and the following lines vertically align with the start of the second word.
   local indentation = line:match("^ *")

   if line:find("^ *[%*%+%-]") then
      indentation = indentation .. " " .. line:match("^ *[%*%+%-]( *)")
   end

   -- Parts of the last line being assembled.
   local line_parts = {}

   -- Length of the current line.
   local line_length = 0

   -- Index of the next character to consider.
   local index = 1

   while true do
      local word_start, word_finish, word = line:find("([^ ]+)", index)

      if not word_start then
         -- Ignore trailing spaces, if any.
         break
      end

      local preceding_spaces = line:sub(index, word_start - 1)
      index = word_finish + 1

      if (#line_parts == 0) or (line_length + #preceding_spaces + #word <= max_length) then
         -- Either this is the very first word or it fits as an addition to the current line, add it.
         table.insert(line_parts, preceding_spaces) -- For the very first word this adds the indentation.
         table.insert(line_parts, word)
         line_length = line_length + #preceding_spaces + #word
      else
         -- Does not fit, finish current line and put the word into a new one.
         table.insert(result_lines, table.concat(line_parts))
         line_parts = {indentation, word}
         line_length = #indentation + #word
      end
   end

   if #line_parts > 0 then
      table.insert(result_lines, table.concat(line_parts))
   end

   if #result_lines == 0 then
      -- Preserve empty lines.
      result_lines[1] = ""
   end

   return result_lines
end

-- Automatically wraps lines within given array,
-- attempting to limit line length to `max_length`.
-- Existing line splits are preserved.
local function autowrap(lines, max_length)
   local result_lines = {}

   for _, line in ipairs(lines) do
      local autowrapped_lines = autowrap_line(line, max_length)

      for _, autowrapped_line in ipairs(autowrapped_lines) do
         table.insert(result_lines, autowrapped_line)
      end
   end

   return result_lines
end

function Parser:_get_element_help(element)
   local label_lines = element:_get_label_lines()
   local description_lines = split_lines(element:_get_description())

   local result_lines = {}

   -- All label lines should have the same length (except the last one, it has no comma).
   -- If too long, start description after all the label lines.
   -- Otherwise, combine label and description lines.

   local usage_margin_len = self:_inherit_property("help_usage_margin", 3)
   local usage_margin = (" "):rep(usage_margin_len)
   local description_margin_len = self:_inherit_property("help_description_margin", 25)
   local description_margin = (" "):rep(description_margin_len)

   local help_max_width = self:_inherit_property("help_max_width")

   if help_max_width then
      local description_max_width = math.max(help_max_width - description_margin_len, 10)
      description_lines = autowrap(description_lines, description_max_width)
   end

   if #label_lines[1] >= (description_margin_len - usage_margin_len) then
      for _, label_line in ipairs(label_lines) do
         table.insert(result_lines, usage_margin .. label_line)
      end

      for _, description_line in ipairs(description_lines) do
         table.insert(result_lines, description_margin .. description_line)
      end
   else
      for i = 1, math.max(#label_lines, #description_lines) do
         local label_line = label_lines[i]
         local description_line = description_lines[i]

         local line = ""

         if label_line then
            line = usage_margin .. label_line
         end

         if description_line and description_line ~= "" then
            line = line .. (" "):rep(description_margin_len - #line) .. description_line
         end

         table.insert(result_lines, line)
      end
   end

   return table.concat(result_lines, "\n")
end

local function get_group_types(group)
   local types = {}

   for _, element in ipairs(group) do
      types[getmetatable(element)] = true
   end

   return types
end

function Parser:_add_group_help(blocks, added_elements, label, elements)
   local buf = {label}

   for _, element in ipairs(elements) do
      if not element._hidden and not added_elements[element] then
         added_elements[element] = true
         table.insert(buf, self:_get_element_help(element))
      end
   end

   if #buf > 1 then
      table.insert(blocks, table.concat(buf, ("\n"):rep(self:_inherit_property("help_vertical_space", 0) + 1)))
   end
end

function Parser:get_help()
   if self._help then
      return self._help
   end

   local blocks = {self:get_usage()}

   local help_max_width = self:_inherit_property("help_max_width")

   if self._description then
      local description = self._description

      if help_max_width then
         description = table.concat(autowrap(split_lines(description), help_max_width), "\n")
      end

      table.insert(blocks, description)
   end

   -- 1. Put groups containing arguments first, then other arguments.
   -- 2. Put remaining groups containing options, then other options.
   -- 3. Put remaining groups containing commands, then other commands.
   -- Assume that an element can't be in several groups.
   local groups_by_type = {
      [Argument] = {},
      [Option] = {},
      [Command] = {}
   }

   for _, group in ipairs(self._groups) do
      local group_types = get_group_types(group)

      for _, mt in ipairs({Argument, Option, Command}) do
         if group_types[mt] then
            table.insert(groups_by_type[mt], group)
            break
         end
      end
   end

   local default_groups = {
      {name = "Arguments", type = Argument, elements = self._arguments},
      {name = "Options", type = Option, elements = self._options},
      {name = "Commands", type = Command, elements = self._commands}
   }

   local added_elements = {}

   for _, default_group in ipairs(default_groups) do
      local type_groups = groups_by_type[default_group.type]

      for _, group in ipairs(type_groups) do
         self:_add_group_help(blocks, added_elements, group.name .. ":", group)
      end

      local default_label = default_group.name .. ":"

      if #type_groups > 0 then
         default_label = "Other " .. default_label:gsub("^.", string.lower)
      end

      self:_add_group_help(blocks, added_elements, default_label, default_group.elements)
   end

   if self._epilog then
      local epilog = self._epilog

      if help_max_width then
         epilog = table.concat(autowrap(split_lines(epilog), help_max_width), "\n")
      end

      table.insert(blocks, epilog)
   end

   return table.concat(blocks, "\n\n")
end

local function get_tip(context, wrong_name)
   local context_pool = {}
   local possible_name
   local possible_names = {}

   for name in pairs(context) do
      if type(name) == "string" then
         for i = 1, #name do
            possible_name = name:sub(1, i - 1) .. name:sub(i + 1)

            if not context_pool[possible_name] then
               context_pool[possible_name] = {}
            end

            table.insert(context_pool[possible_name], name)
         end
      end
   end

   for i = 1, #wrong_name + 1 do
      possible_name = wrong_name:sub(1, i - 1) .. wrong_name:sub(i + 1)

      if context[possible_name] then
         possible_names[possible_name] = true
      elseif context_pool[possible_name] then
         for _, name in ipairs(context_pool[possible_name]) do
            possible_names[name] = true
         end
      end
   end

   local first = next(possible_names)

   if first then
      if next(possible_names, first) then
         local possible_names_arr = {}

         for name in pairs(possible_names) do
            table.insert(possible_names_arr, "'" .. name .. "'")
         end

         table.sort(possible_names_arr)
         return "\nDid you mean one of these: " .. table.concat(possible_names_arr, " ") .. "?"
      else
         return "\nDid you mean '" .. first .. "'?"
      end
   else
      return ""
   end
end

local ElementState = class({
   invocations = 0
})

function ElementState:__call(state, element)
   self.state = state
   self.result = state.result
   self.element = element
   self.target = element._target or element:_get_default_target()
   self.action, self.result[self.target] = element:_get_action()
   return self
end

function ElementState:error(fmt, ...)
   self.state:error(fmt, ...)
end

function ElementState:convert(argument, index)
   local converter = self.element._convert

   if converter then
      local ok, err

      if type(converter) == "function" then
         ok, err = converter(argument)
      elseif type(converter[index]) == "function" then
         ok, err = converter[index](argument)
      else
         ok = converter[argument]
      end

      if ok == nil then
         self:error(err and "%s" or "malformed argument '%s'", err or argument)
      end

      argument = ok
   end

   return argument
end

function ElementState:default(mode)
   return self.element._defmode:find(mode) and self.element._default
end

local function bound(noun, min, max, is_max)
   local res = ""

   if min ~= max then
      res = "at " .. (is_max and "most" or "least") .. " "
   end

   local number = is_max and max or min
   return res .. tostring(number) .. " " .. noun ..  (number == 1 and "" or "s")
end

function ElementState:set_name(alias)
   self.name = ("%s '%s'"):format(alias and "option" or "argument", alias or self.element._name)
end

function ElementState:invoke()
   self.open = true
   self.overwrite = false

   if self.invocations >= self.element._maxcount then
      if self.element._overwrite then
         self.overwrite = true
      else
         local num_times_repr = bound("time", self.element._mincount, self.element._maxcount, true)
         self:error("%s must be used %s", self.name, num_times_repr)
      end
   else
      self.invocations = self.invocations + 1
   end

   self.args = {}

   if self.element._maxargs <= 0 then
      self:close()
   end

   return self.open
end

function ElementState:pass(argument)
   argument = self:convert(argument, #self.args + 1)
   table.insert(self.args, argument)

   if #self.args >= self.element._maxargs then
      self:close()
   end

   return self.open
end

function ElementState:complete_invocation()
   while #self.args < self.element._minargs do
      self:pass(self.element._default)
   end
end

function ElementState:close()
   if self.open then
      self.open = false

      if #self.args < self.element._minargs then
         if self:default("a") then
            self:complete_invocation()
         else
            if #self.args == 0 then
               if getmetatable(self.element) == Argument then
                  self:error("missing %s", self.name)
               elseif self.element._maxargs == 1 then
                  self:error("%s requires an argument", self.name)
               end
            end

            self:error("%s requires %s", self.name, bound("argument", self.element._minargs, self.element._maxargs))
         end
      end

      local args

      if self.element._maxargs == 0 then
         args = self.args[1]
      elseif self.element._maxargs == 1 then
         if self.element._minargs == 0 and self.element._mincount ~= self.element._maxcount then
            args = self.args
         else
            args = self.args[1]
         end
      else
         args = self.args
      end

      self.action(self.result, self.target, args, self.overwrite)
   end
end

local ParseState = class({
   result = {},
   options = {},
   arguments = {},
   argument_i = 1,
   element_to_mutexes = {},
   mutex_to_element_state = {},
   command_actions = {}
})

function ParseState:__call(parser, error_handler)
   self.parser = parser
   self.error_handler = error_handler
   self.charset = parser:_update_charset()
   self:switch(parser)
   return self
end

function ParseState:error(fmt, ...)
   self.error_handler(self.parser, fmt:format(...))
end

function ParseState:switch(parser)
   self.parser = parser

   if parser._action then
      table.insert(self.command_actions, {action = parser._action, name = parser._name})
   end

   for _, option in ipairs(parser._options) do
      option = ElementState(self, option)
      table.insert(self.options, option)

      for _, alias in ipairs(option.element._aliases) do
         self.options[alias] = option
      end
   end

   for _, mutex in ipairs(parser._mutexes) do
      for _, element in ipairs(mutex) do
         if not self.element_to_mutexes[element] then
            self.element_to_mutexes[element] = {}
         end

         table.insert(self.element_to_mutexes[element], mutex)
      end
   end

   for _, argument in ipairs(parser._arguments) do
      argument = ElementState(self, argument)
      table.insert(self.arguments, argument)
      argument:set_name()
      argument:invoke()
   end

   self.handle_options = parser._handle_options
   self.argument = self.arguments[self.argument_i]
   self.commands = parser._commands

   for _, command in ipairs(self.commands) do
      for _, alias in ipairs(command._aliases) do
         self.commands[alias] = command
      end
   end
end

function ParseState:get_option(name)
   local option = self.options[name]

   if not option then
      self:error("unknown option '%s'%s", name, get_tip(self.options, name))
   else
      return option
   end
end

function ParseState:get_command(name)
   local command = self.commands[name]

   if not command then
      if #self.commands > 0 then
         self:error("unknown command '%s'%s", name, get_tip(self.commands, name))
      else
         self:error("too many arguments")
      end
   else
      return command
   end
end

function ParseState:check_mutexes(element_state)
   if self.element_to_mutexes[element_state.element] then
      for _, mutex in ipairs(self.element_to_mutexes[element_state.element]) do
         local used_element_state = self.mutex_to_element_state[mutex]

         if used_element_state and used_element_state ~= element_state then
            self:error("%s can not be used together with %s", element_state.name, used_element_state.name)
         else
            self.mutex_to_element_state[mutex] = element_state
         end
      end
   end
end

function ParseState:invoke(option, name)
   self:close()
   option:set_name(name)
   self:check_mutexes(option, name)

   if option:invoke() then
      self.option = option
   end
end

function ParseState:pass(arg)
   if self.option then
      if not self.option:pass(arg) then
         self.option = nil
      end
   elseif self.argument then
      self:check_mutexes(self.argument)

      if not self.argument:pass(arg) then
         self.argument_i = self.argument_i + 1
         self.argument = self.arguments[self.argument_i]
      end
   else
      local command = self:get_command(arg)
      self.result[command._target or command._name] = true

      if self.parser._command_target then
         self.result[self.parser._command_target] = command._name
      end

      self:switch(command)
   end
end

function ParseState:close()
   if self.option then
      self.option:close()
      self.option = nil
   end
end

function ParseState:finalize()
   self:close()

   for i = self.argument_i, #self.arguments do
      local argument = self.arguments[i]
      if #argument.args == 0 and argument:default("u") then
         argument:complete_invocation()
      else
         argument:close()
      end
   end

   if self.parser._require_command and #self.commands > 0 then
      self:error("a command is required")
   end

   for _, option in ipairs(self.options) do
      option.name = option.name or ("option '%s'"):format(option.element._name)

      if option.invocations == 0 then
         if option:default("u") then
            option:invoke()
            option:complete_invocation()
            option:close()
         end
      end

      local mincount = option.element._mincount

      if option.invocations < mincount then
         if option:default("a") then
            while option.invocations < mincount do
               option:invoke()
               option:close()
            end
         elseif option.invocations == 0 then
            self:error("missing %s", option.name)
         else
            self:error("%s must be used %s", option.name, bound("time", mincount, option.element._maxcount))
         end
      end
   end

   for i = #self.command_actions, 1, -1 do
      self.command_actions[i].action(self.result, self.command_actions[i].name)
   end
end

function ParseState:parse(args)
   for _, arg in ipairs(args) do
      local plain = true

      if self.handle_options then
         local first = arg:sub(1, 1)

         if self.charset[first] then
            if #arg > 1 then
               plain = false

               if arg:sub(2, 2) == first then
                  if #arg == 2 then
                     if self.options[arg] then
                        local option = self:get_option(arg)
                        self:invoke(option, arg)
                     else
                        self:close()
                     end

                     self.handle_options = false
                  else
                     local equals = arg:find "="
                     if equals then
                        local name = arg:sub(1, equals - 1)
                        local option = self:get_option(name)

                        if option.element._maxargs <= 0 then
                           self:error("option '%s' does not take arguments", name)
                        end

                        self:invoke(option, name)
                        self:pass(arg:sub(equals + 1))
                     else
                        local option = self:get_option(arg)
                        self:invoke(option, arg)
                     end
                  end
               else
                  for i = 2, #arg do
                     local name = first .. arg:sub(i, i)
                     local option = self:get_option(name)
                     self:invoke(option, name)

                     if i ~= #arg and option.element._maxargs > 0 then
                        self:pass(arg:sub(i + 1))
                        break
                     end
                  end
               end
            end
         end
      end

      if plain then
         self:pass(arg)
      end
   end

   self:finalize()
   return self.result
end

function Parser:error(msg)
   io.stderr:write(("%s\n\nError: %s\n"):format(self:get_usage(), msg))
   os.exit(1)
end

-- Compatibility with strict.lua and other checkers:
local default_cmdline = rawget(_G, "arg") or {}

function Parser:_parse(args, error_handler)
   return ParseState(self, error_handler):parse(args or default_cmdline)
end

function Parser:parse(args)
   return self:_parse(args, self.error)
end

local function xpcall_error_handler(err)
   return tostring(err) .. "\noriginal " .. debug.traceback("", 2):sub(2)
end

function Parser:pparse(args)
   local parse_error

   local ok, result = xpcall(function()
      return self:_parse(args, function(_, err)
         parse_error = err
         error(err, 0)
      end)
   end, xpcall_error_handler)

   if ok then
      return true, result
   elseif not parse_error then
      error(result, 0)
   else
      return false, parse_error
   end
end

local argparse = {}

argparse.version = "0.6.0"

setmetatable(argparse, {__call = function(_, ...)
   return Parser(default_cmdline[0]):add_help(true)(...)
end})

return argparse
end
end

do
local _ENV = _ENV
package.preload[ "gears" ] = function( ... ) local arg = _G.arg;


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
    -- on some operating systems io.iopen on directories does not return nil
    if M.isdir(name) then return false end

    local f = io.open(name, "r")
    if nil == f then return false end
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
end
end

do
local _ENV = _ENV
package.preload[ "inspect" ] = function( ... ) local arg = _G.arg;
local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local math = _tl_compat and _tl_compat.math or math; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table
local inspect = {Options = {}, }

















inspect._VERSION = 'inspect.lua 3.1.0'
inspect._URL = 'http://github.com/kikito/inspect.lua'
inspect._DESCRIPTION = 'human-readable representations of tables'
inspect._LICENSE = [[
  MIT LICENSE
  Copyright (c) 2022 Enrique García Cota
  Permission is hereby granted, free of charge, to any person obtaining a
  copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:
  The above copyright notice and this permission notice shall be included
  in all copies or substantial portions of the Software.
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
inspect.KEY = setmetatable({}, { __tostring = function() return 'inspect.KEY' end })
inspect.METATABLE = setmetatable({}, { __tostring = function() return 'inspect.METATABLE' end })

local tostring = tostring
local rep = string.rep
local match = string.match
local char = string.char
local gsub = string.gsub
local fmt = string.format

local function rawpairs(t)
   return next, t, nil
end



local function smartQuote(str)
   if match(str, '"') and not match(str, "'") then
      return "'" .. str .. "'"
   end
   return '"' .. gsub(str, '"', '\\"') .. '"'
end


local shortControlCharEscapes = {
   ["\a"] = "\\a", ["\b"] = "\\b", ["\f"] = "\\f", ["\n"] = "\\n",
   ["\r"] = "\\r", ["\t"] = "\\t", ["\v"] = "\\v", ["\127"] = "\\127",
}
local longControlCharEscapes = { ["\127"] = "\127" }
for i = 0, 31 do
   local ch = char(i)
   if not shortControlCharEscapes[ch] then
      shortControlCharEscapes[ch] = "\\" .. i
      longControlCharEscapes[ch] = fmt("\\%03d", i)
   end
end

local function escape(str)
   return (gsub(gsub(gsub(str, "\\", "\\\\"),
   "(%c)%f[0-9]", longControlCharEscapes),
   "%c", shortControlCharEscapes))
end

local function isIdentifier(str)
   return type(str) == "string" and not not str:match("^[_%a][_%a%d]*$")
end

local flr = math.floor
local function isSequenceKey(k, sequenceLength)
   return type(k) == "number" and
   flr(k) == k and
   1 <= (k) and
   k <= sequenceLength
end

local defaultTypeOrders = {
   ['number'] = 1, ['boolean'] = 2, ['string'] = 3, ['table'] = 4,
   ['function'] = 5, ['userdata'] = 6, ['thread'] = 7,
}

local function sortKeys(a, b)
   local ta, tb = type(a), type(b)


   if ta == tb and (ta == 'string' or ta == 'number') then
      return (a) < (b)
   end

   local dta = defaultTypeOrders[ta] or 100
   local dtb = defaultTypeOrders[tb] or 100


   return dta == dtb and ta < tb or dta < dtb
end

local function getKeys(t)

   local seqLen = 1
   while rawget(t, seqLen) ~= nil do
      seqLen = seqLen + 1
   end
   seqLen = seqLen - 1

   local keys, keysLen = {}, 0
   for k in rawpairs(t) do
      if not isSequenceKey(k, seqLen) then
         keysLen = keysLen + 1
         keys[keysLen] = k
      end
   end
   table.sort(keys, sortKeys)
   return keys, keysLen, seqLen
end

local function countCycles(x, cycles)
   if type(x) == "table" then
      if cycles[x] then
         cycles[x] = cycles[x] + 1
      else
         cycles[x] = 1
         for k, v in rawpairs(x) do
            countCycles(k, cycles)
            countCycles(v, cycles)
         end
         countCycles(getmetatable(x), cycles)
      end
   end
end

local function makePath(path, a, b)
   local newPath = {}
   local len = #path
   for i = 1, len do newPath[i] = path[i] end

   newPath[len + 1] = a
   newPath[len + 2] = b

   return newPath
end


local function processRecursive(process,
   item,
   path,
   visited)
   if item == nil then return nil end
   if visited[item] then return visited[item] end

   local processed = process(item, path)
   if type(processed) == "table" then
      local processedCopy = {}
      visited[item] = processedCopy
      local processedKey

      for k, v in rawpairs(processed) do
         processedKey = processRecursive(process, k, makePath(path, k, inspect.KEY), visited)
         if processedKey ~= nil then
            processedCopy[processedKey] = processRecursive(process, v, makePath(path, processedKey), visited)
         end
      end

      local mt = processRecursive(process, getmetatable(processed), makePath(path, inspect.METATABLE), visited)
      if type(mt) ~= 'table' then mt = nil end
      setmetatable(processedCopy, mt)
      processed = processedCopy
   end
   return processed
end

local function puts(buf, str)
   buf.n = buf.n + 1
   buf[buf.n] = str
end



local Inspector = {}










local Inspector_mt = { __index = Inspector }

local function tabify(inspector)
   puts(inspector.buf, inspector.newline .. rep(inspector.indent, inspector.level))
end

function Inspector:getId(v)
   local id = self.ids[v]
   local ids = self.ids
   if not id then
      local tv = type(v)
      id = (ids[tv] or 0) + 1
      ids[v], ids[tv] = id, id
   end
   return tostring(id)
end

function Inspector:putValue(v)
   local buf = self.buf
   local tv = type(v)
   if tv == 'string' then
      puts(buf, smartQuote(escape(v)))
   elseif tv == 'number' or tv == 'boolean' or tv == 'nil' or
      tv == 'cdata' or tv == 'ctype' then
      puts(buf, tostring(v))
   elseif tv == 'table' and not self.ids[v] then
      local t = v

      if t == inspect.KEY or t == inspect.METATABLE then
         puts(buf, tostring(t))
      elseif self.level >= self.depth then
         puts(buf, '{...}')
      else
         if self.cycles[t] > 1 then puts(buf, fmt('<%d>', self:getId(t))) end

         local keys, keysLen, seqLen = getKeys(t)

         puts(buf, '{')
         self.level = self.level + 1

         for i = 1, seqLen + keysLen do
            if i > 1 then puts(buf, ',') end
            if i <= seqLen then
               puts(buf, ' ')
               self:putValue(t[i])
            else
               local k = keys[i - seqLen]
               tabify(self)
               if isIdentifier(k) then
                  puts(buf, k)
               else
                  puts(buf, "[")
                  self:putValue(k)
                  puts(buf, "]")
               end
               puts(buf, ' = ')
               self:putValue(t[k])
            end
         end

         local mt = getmetatable(t)
         if type(mt) == 'table' then
            if seqLen + keysLen > 0 then puts(buf, ',') end
            tabify(self)
            puts(buf, '<metatable> = ')
            self:putValue(mt)
         end

         self.level = self.level - 1

         if keysLen > 0 or type(mt) == 'table' then
            tabify(self)
         elseif seqLen > 0 then
            puts(buf, ' ')
         end

         puts(buf, '}')
      end

   else
      puts(buf, fmt('<%s %d>', tv, self:getId(v)))
   end
end




function inspect.inspect(root, options)
   options = options or {}

   local depth = options.depth or (math.huge)
   local newline = options.newline or '\n'
   local indent = options.indent or '  '
   local process = options.process

   if process then
      root = processRecursive(process, root, {}, {})
   end

   local cycles = {}
   countCycles(root, cycles)

   local inspector = setmetatable({
      buf = { n = 0 },
      ids = {},
      cycles = cycles,
      depth = depth,
      level = 0,
      newline = newline,
      indent = indent,
   }, Inspector_mt)

   inspector:putValue(root)

   return table.concat(inspector.buf)
end

setmetatable(inspect, {
   __call = function(_, root, options)
      return inspect.inspect(root, options)
   end,
})

return inspect
end
end

do
local _ENV = _ENV
package.preload[ "log" ] = function( ... ) local arg = _G.arg;
--
-- log.lua
--
-- Copyright (c) 2016 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local log = { _version = "0.1.0" }

log.usecolor = true
log.outfile = nil
log.level = "trace"


local modes = {
  { name = "trace", color = "\27[34m", },
  { name = "debug", color = "\27[36m", },
  { name = "info",  color = "\27[32m", },
  { name = "warn",  color = "\27[33m", },
  { name = "error", color = "\27[31m", },
  { name = "fatal", color = "\27[35m", },
}


local levels = {}
for i, v in ipairs(modes) do
  levels[v.name] = i
end


local round = function(x, increment)
  increment = increment or 1
  x = x / increment
  return (x > 0 and math.floor(x + .5) or math.ceil(x - .5)) * increment
end


local _tostring = tostring

local tostring = function(...)
  local t = {}
  for i = 1, select('#', ...) do
    local x = select(i, ...)
    if type(x) == "number" then
      x = round(x, .01)
    end
    t[#t + 1] = _tostring(x)
  end
  return table.concat(t, " ")
end


for i, x in ipairs(modes) do
  local nameupper = x.name:upper()
  log[x.name] = function(...)
    
    -- Return early if we're below the log level
    if i < levels[log.level] then
      return
    end

    local msg = tostring(...)
    local info = debug.getinfo(2, "Sl")
    local lineinfo = info.short_src .. ":" .. info.currentline

    -- Output to console
    print(string.format("%s[%-6s%s]%s %s: %s",
                        log.usecolor and x.color or "",
                        nameupper,
                        os.date("%H:%M:%S"),
                        log.usecolor and "\27[0m" or "",
                        lineinfo,
                        msg))

    -- Output to log file
    if log.outfile then
      local fp = io.open(log.outfile, "a")
      local str = string.format("[%-6s%s] %s: %s\n",
                                nameupper, os.date(), lineinfo, msg)
      fp:write(str)
      fp:close()
    end

  end
end


return log
end
end

do
local _ENV = _ENV
package.preload[ "lustache" ] = function( ... ) local arg = _G.arg;
-- lustache: Lua mustache template parsing.
-- Copyright 2013 Olivine Labs, LLC <projects@olivinelabs.com>
-- MIT Licensed.

local string_gmatch = string.gmatch

function string.split(str, sep)
  local out = {}
  for m in string_gmatch(str, "[^"..sep.."]+") do out[#out+1] = m end
  return out
end

local lustache = {
  name     = "lustache",
  version  = "1.3.1-0",
  renderer = require("lustache.renderer"):new(),
}

return setmetatable(lustache, {
  __index = function(self, idx)
    if self.renderer[idx] then return self.renderer[idx] end
  end,
  __newindex = function(self, idx, val)
    if idx == "partials" then self.renderer.partials = val end
    if idx == "tags" then self.renderer.tags = val end
  end
})
end
end

do
local _ENV = _ENV
package.preload[ "lustache.context" ] = function( ... ) local arg = _G.arg;
local string_find, string_split, tostring, type =
      string.find, string.split, tostring, type

local context = {}
context.__index = context

function context:clear_cache()
  self.cache = {}
end

function context:push(view)
  return self:new(view, self)
end

function context:lookup(name)
  local value = self.cache[name]

  if not value then
    if name == "." then
      value = self.view
    else
      local context = self

      while context do
        if string_find(name, ".") > 0 then
          local names = string_split(name, ".")
          local i = 0

          value = context.view

          if(type(value)) == "number" then
            value = tostring(value)
          end

          while value and i < #names do
            i = i + 1
            value = value[names[i]]
          end
        else
          value = context.view[name]
        end

        if value then
          break
        end

        context = context.parent
      end
    end

    self.cache[name] = value
  end

  return value
end

function context:new(view, parent)
  local out = {
    view   = view,
    parent = parent,
    cache  = {},
  }
  return setmetatable(out, context)
end

return context
end
end

do
local _ENV = _ENV
package.preload[ "lustache.renderer" ] = function( ... ) local arg = _G.arg;
local Scanner  = require "lustache.scanner"
local Context  = require "lustache.context"

local error, ipairs, pairs, setmetatable, tostring, type = 
      error, ipairs, pairs, setmetatable, tostring, type 
local math_floor, math_max, string_find, string_gsub, string_split, string_sub, table_concat, table_insert, table_remove =
      math.floor, math.max, string.find, string.gsub, string.split, string.sub, table.concat, table.insert, table.remove

local patterns = {
  white = "%s*",
  space = "%s+",
  nonSpace = "%S",
  eq = "%s*=",
  curly = "%s*}",
  tag = "[#\\^/>{&=!?]"
}

local html_escape_characters = {
  ["&"] = "&amp;",
  ["<"] = "&lt;",
  [">"] = "&gt;",
  ['"'] = "&quot;",
  ["'"] = "&#39;",
  ["/"] = "&#x2F;"
}

local block_tags = {
  ["#"] = true,
  ["^"] = true,
  ["?"] = true,
}

local function is_array(array)
  if type(array) ~= "table" then return false end
  local max, n = 0, 0
  for k, _ in pairs(array) do
    if not (type(k) == "number" and k > 0 and math_floor(k) == k) then
      return false 
    end
    max = math_max(max, k)
    n = n + 1
  end
  return n == max
end

-- Low-level function that compiles the given `tokens` into a
-- function that accepts two arguments: a Context and a
-- Renderer.

local function compile_tokens(tokens, originalTemplate)
  local subs = {}

  local function subrender(i, tokens)
    if not subs[i] then
      local fn = compile_tokens(tokens, originalTemplate)
      subs[i] = function(ctx, rnd) return fn(ctx, rnd) end
    end
    return subs[i]
  end

  local function render(ctx, rnd)
    local buf = {}
    local token, section
    for i, token in ipairs(tokens) do
      local t = token.type
      buf[#buf+1] = 
        t == "?" and rnd:_conditional(
          token, ctx, subrender(i, token.tokens)
        ) or
        t == "#" and rnd:_section(
          token, ctx, subrender(i, token.tokens), originalTemplate
        ) or
        t == "^" and rnd:_inverted(
          token.value, ctx, subrender(i, token.tokens)
        ) or
        t == ">" and rnd:_partial(token.value, ctx, originalTemplate) or
        (t == "{" or t == "&") and rnd:_name(token.value, ctx, false) or
        t == "name" and rnd:_name(token.value, ctx, true) or
        t == "text" and token.value or ""
    end
    return table_concat(buf)
  end
  return render
end

local function escape_tags(tags)

  return {
    string_gsub(tags[1], "%%", "%%%%").."%s*",
    "%s*"..string_gsub(tags[2], "%%", "%%%%"),
  }
end

local function nest_tokens(tokens)
  local tree = {}
  local collector = tree 
  local sections = {}
  local token, section

  for i,token in ipairs(tokens) do
    if block_tags[token.type] then
      token.tokens = {}
      sections[#sections+1] = token
      collector[#collector+1] = token
      collector = token.tokens
    elseif token.type == "/" then
      if #sections == 0 then
        error("Unopened section: "..token.value)
      end

      -- Make sure there are no open sections when we're done
      section = table_remove(sections, #sections)

      if not section.value == token.value then
        error("Unclosed section: "..section.value)
      end

      section.closingTagIndex = token.startIndex

      if #sections > 0 then
        collector = sections[#sections].tokens
      else
        collector = tree
      end
    else
      collector[#collector+1] = token
    end
  end

  section = table_remove(sections, #sections)

  if section then
    error("Unclosed section: "..section.value)
  end

  return tree
end

-- Combines the values of consecutive text tokens in the given `tokens` array
-- to a single token.
local function squash_tokens(tokens)
  local out, txt = {}, {}
  local txtStartIndex, txtEndIndex
  for _, v in ipairs(tokens) do
    if v.type == "text" then
      if #txt == 0 then
        txtStartIndex = v.startIndex
      end
      txt[#txt+1] = v.value
      txtEndIndex = v.endIndex
    else
      if #txt > 0 then
        out[#out+1] = { type = "text", value = table_concat(txt), startIndex = txtStartIndex, endIndex = txtEndIndex }
        txt = {}
      end
      out[#out+1] = v
    end
  end
  if #txt > 0 then
    out[#out+1] = { type = "text", value = table_concat(txt), startIndex = txtStartIndex, endIndex = txtEndIndex  }
  end
  return out
end

local function make_context(view)
  if not view then return view end
  return getmetatable(view) == Context and view or Context:new(view)
end

local renderer = { }

function renderer:clear_cache()
  self.cache = {}
  self.partial_cache = {}
end

function renderer:compile(tokens, tags, originalTemplate)
  tags = tags or self.tags
  if type(tokens) == "string" then
    tokens = self:parse(tokens, tags)
  end

  local fn = compile_tokens(tokens, originalTemplate)

  return function(view)
    return fn(make_context(view), self)
  end
end

function renderer:render(template, view, partials)
  if type(self) == "string" then
    error("Call mustache:render, not mustache.render!")
  end

  if partials then
    -- remember partial table
    -- used for runtime lookup & compile later on
    self.partials = partials
  end

  if not template then
    return ""
  end

  local fn = self.cache[template]

  if not fn then
    fn = self:compile(template, self.tags, template)
    self.cache[template] = fn
  end

  return fn(view)
end

function renderer:_conditional(token, context, callback)
  local value = context:lookup(token.value)

  if value then
    return callback(context, self)
  end

  return ""
end

function renderer:_section(token, context, callback, originalTemplate)
  local value = context:lookup(token.value)

  if type(value) == "table" then
    if is_array(value) then
      local buffer = ""

      for i,v in ipairs(value) do
        buffer = buffer .. callback(context:push(v), self)
      end

      return buffer
    end

    return callback(context:push(value), self)
  elseif type(value) == "function" then
    local section_text = string_sub(originalTemplate, token.endIndex+1, token.closingTagIndex - 1)

    local scoped_render = function(template)
      return self:render(template, context)
    end

    return value(section_text, scoped_render) or ""
  else
    if value then
      return callback(context, self)
    end
  end

  return ""
end

function renderer:_inverted(name, context, callback)
  local value = context:lookup(name)

  -- From the spec: inverted sections may render text once based on the
  -- inverse value of the key. That is, they will be rendered if the key
  -- doesn't exist, is false, or is an empty list.

  if value == nil or value == false or (type(value) == "table" and is_array(value) and #value == 0) then
    return callback(context, self)
  end

  return ""
end

function renderer:_partial(name, context, originalTemplate)
  local fn = self.partial_cache[name]

  -- check if partial cache exists
  if (not fn and self.partials) then

    local partial = self.partials[name]
    if (not partial) then
      return ""
    end
    
    -- compile partial and store result in cache
    fn = self:compile(partial, nil, partial)
    self.partial_cache[name] = fn
  end
  return fn and fn(context, self) or ""
end

function renderer:_name(name, context, escape)
  local value = context:lookup(name)

  if type(value) == "function" then
    value = value(context.view)
  end

  local str = value == nil and "" or value
  str = tostring(str)

  if escape then
    return string_gsub(str, '[&<>"\'/]', function(s) return html_escape_characters[s] end)
  end

  return str
end

-- Breaks up the given `template` string into a tree of token objects. If
-- `tags` is given here it must be an array with two string values: the
-- opening and closing tags used in the template (e.g. ["<%", "%>"]). Of
-- course, the default is to use mustaches (i.e. Mustache.tags).
function renderer:parse(template, tags)
  tags = tags or self.tags
  local tag_patterns = escape_tags(tags)
  local scanner = Scanner:new(template)
  local tokens = {} -- token buffer
  local spaces = {} -- indices of whitespace tokens on the current line
  local has_tag = false -- is there a {{tag} on the current line?
  local non_space = false -- is there a non-space char on the current line?

  -- Strips all whitespace tokens array for the current line if there was
  -- a {{#tag}} on it and otherwise only space
  local function strip_space()
    if has_tag and not non_space then
      while #spaces > 0 do
        table_remove(tokens, table_remove(spaces))
      end
    else
      spaces = {}
    end
    has_tag = false
    non_space = false
  end

  local type, value, chr

  while not scanner:eos() do
    local start = scanner.pos

    value = scanner:scan_until(tag_patterns[1])

    if value then
      for i = 1, #value do
        chr = string_sub(value,i,i)

        if string_find(chr, "%s+") then
          spaces[#spaces+1] = #tokens + 1
        else
          non_space = true
        end

        tokens[#tokens+1] = { type = "text", value = chr, startIndex = start, endIndex = start }
        start = start + 1
        if chr == "\n" then
          strip_space()
        end
      end
    end

    if not scanner:scan(tag_patterns[1]) then
      break
    end

    has_tag = true
    type = scanner:scan(patterns.tag) or "name"

    scanner:scan(patterns.white)

    if type == "=" then
      value = scanner:scan_until(patterns.eq)
      scanner:scan(patterns.eq)
      scanner:scan_until(tag_patterns[2])
    elseif type == "{" then
      local close_pattern = "%s*}"..tags[2]
      value = scanner:scan_until(close_pattern)
      scanner:scan(patterns.curly)
      scanner:scan_until(tag_patterns[2])
    else
      value = scanner:scan_until(tag_patterns[2])
    end

    if not scanner:scan(tag_patterns[2]) then
      error("Unclosed tag " .. value .. " of type " .. type .. " at position " .. scanner.pos)
    end

    tokens[#tokens+1] = { type = type, value = value, startIndex = start, endIndex = scanner.pos - 1 }
    if type == "name" or type == "{" or type == "&" then
      non_space = true --> what does this do?
    end

    if type == "=" then
      tags = string_split(value, patterns.space)
      tag_patterns = escape_tags(tags)
    end
  end

  return nest_tokens(squash_tokens(tokens))
end

function renderer:new()
  local out = { 
    cache         = {},
    partial_cache = {},
    tags          = {"{{", "}}"}
  }
  return setmetatable(out, { __index = self })
end

return renderer
end
end

do
local _ENV = _ENV
package.preload[ "lustache.scanner" ] = function( ... ) local arg = _G.arg;
local string_find, string_match, string_sub =
      string.find, string.match, string.sub

local scanner = {}

-- Returns `true` if the tail is empty (end of string).
function scanner:eos()
  return self.tail == ""
end

-- Tries to match the given regular expression at the current position.
-- Returns the matched text if it can match, `null` otherwise.
function scanner:scan(pattern)
  local match = string_match(self.tail, pattern)

  if match and string_find(self.tail, pattern) == 1 then
    self.tail = string_sub(self.tail, #match + 1)
    self.pos = self.pos + #match

    return match
  end

end

-- Skips all text until the given regular expression can be matched. Returns
-- the skipped string, which is the entire tail of this scanner if no match
-- can be made.
function scanner:scan_until(pattern)

  local match
  local pos = string_find(self.tail, pattern)

  if pos == nil then
    match = self.tail
    self.pos = self.pos + #self.tail
    self.tail = ""
  elseif pos == 1 then
    match = nil
  else
    match = string_sub(self.tail, 1, pos - 1)
    self.tail = string_sub(self.tail, pos)
    self.pos = self.pos + #match
  end

  return match
end

function scanner:new(str)
  local out = {
    str  = str,
    tail = str,
    pos  = 1
  }
  return setmetatable(out, { __index = self } )
end

return scanner
end
end

do
local _ENV = _ENV
package.preload[ "safer" ] = function( ... ) local arg = _G.arg;
local safer = {}

function safer.readonly(t)
   local st = {}
   setmetatable(st, {
      __index = t,
      __newindex = function(_, k, _)
         error("Attempting to set field '"..tostring(k).."' in read-only table.")
      end,
   })
   return st
end

function safer.table(t)
   local st = {}
   setmetatable(st, {
      __index = t,
      __newindex = function(_, k, v)
         if rawget(t,k) ~= nil then
            rawset(t,k,v)
         else
            error("Attempting to create field '"..tostring(k).."' in a safe table.")
         end
      end,
   })
   return st
end

function safer.globals(exception_globals, exception_nils)
   exception_globals = exception_globals or {}
   exception_nils = exception_nils or {}
   -- used in typical portability tests
   local allowed_nils = {
      module = true,
      loadstring = true,
      unpack = true,
      jit = true,
      PROXY = true, -- luasocket
   }
   -- legacy modules that set globals
   local allowed_globals = {
      lfs = true, -- luafilesystem
      copcall = true,
      coxpcall = true,
      logging = true, -- lualogging
      TIMEOUT = true, -- luasocket
   }
   setmetatable(_G, {
      __index = function(_, k)
         if allowed_nils[k] or exception_nils[k] then
            return nil
         end
         error("Attempting to access an undeclared global '"..k.."'\n"..debug.traceback())
      end,
      __newindex = function(t, k, v)
         if allowed_globals[k] or exception_globals[k] then
            rawset(t, k, v)
            return
         end
         error("Attempting to assign a new global '"..k.."'\n"..debug.traceback())
      end,
   })
end

return safer
end
end

do
local _ENV = _ENV
package.preload[ "sh" ] = function( ... ) local arg = _G.arg;
local posix = require("posix")

--
-- We'll be overwriding the lua `tostring` function, so keep a reference to the
-- original lua version here:
---
local _lua_tostring = tostring


--
-- Create a Table with stack functions, used by popd/pushd based on:
-- http://lua-users.org/wiki/SimpleStack
--
local Stack = {}
function Stack:Create()

    -- stack table
    local t = {}
    -- entry table
    t._et = {}

    -- push a value on to the stack
    function t:push(...)
        if ... then
            local targs = {...}
            -- add values
            for _,v in ipairs(targs) do
                table.insert(self._et, v)
            end
        end
    end

    -- pop a value from the stack
    function t:pop(num)
        -- get num values from stack
        num = num or 1

        -- return table
        local entries = {}

        -- get values into entries
        for _ = 1, num do
            -- get last entry
            if #self._et ~= 0 then
                table.insert(entries, self._et[#self._et])
                -- remove last value
                table.remove(self._et)
            else
                break
            end
        end
        -- return unpacked entries
        return table.unpack(entries)
    end

    -- get entries
    function t:getn()
        return #self._et
    end

    -- list values
    function t:list()
        for i,v in pairs(self._et) do
            print(i, v)
        end
    end
    return t
end

---@class sh.lua : sh.Shell
local M = {}

M.version = "Automatic Shell Bindings for Lua / LuaSH 1.2.0"

--
-- Simple popen3() implementation
--
local function popen3(path, ...)
    local r1, w1 = posix.pipe()
    local r2, w2 = posix.pipe()
    local r3, w3 = posix.pipe()

    assert((r1 ~= nil or r2 ~= nil or r3 ~= nil), "pipe() failed")

    local pid, _ = posix.fork()
    assert(pid ~= nil, "fork() failed")
    if pid == 0 then
        posix.close(w1)
        posix.close(r2)
        posix.close(r3)
        posix.dup2(r1, posix.fileno(io.stdin))
        posix.dup2(w2, posix.fileno(io.stdout))
        posix.dup2(w3, posix.fileno(io.stderr))
        posix.close(r1)
        posix.close(w2)
        posix.close(w3)

        local ret, _, _ = posix.execp(path, table.unpack({...}))
        assert(ret ~= nil, "execp() failed")

        posix._exit(1)
        return
    end

    posix.close(r1)
    posix.close(w2)
    posix.close(w3)

    return pid, w1, r2, r3
end

--
-- Async posix.read function. Yields:
--   {poll status, pipe ended, pipe data, poll code}
--     * poll status: 0 (timeout), 1 (ready), nil (failure)
--     * pipe ended: false (pipe has more data), true (pipe has no more data)
--     * pipe data: data chunk
--     * poll code: full return code from posix.rpoll
--
local function read_async(p, bufsize, timeout)
    while true do
        local poll_code = {posix.rpoll(p, timeout)}
        if poll_code[1] == 0 then
            -- timeout => pipe not ready
            coroutine.yield(0, nil, nil, poll_code)
        elseif poll_code[1] == 1 then
            -- pipe ready => read data
            local buf = posix.read(p, bufsize)
            local ended = (buf == nil or #buf == 0)
            coroutine.yield(1, ended, buf, poll_code)
            -- stop if pipe has ended ended
            if ended then break end
        else
            -- poll failed
            coroutine.yield(nil, nil, nil, poll_code)
            break
        end
    end
end

M.__verbose = false

--
-- Pipe input into cmd + optional arguments and wait for completion and then
-- return status code, stdout and stderr from cmd.
--
local function pipe_simple(input, cmd, ...)
    --
    -- Launch child process
    --
    local pid, w, r, e = popen3(cmd, table.unpack({...}))
    assert(pid ~= nil, "pipe_simple() unable to popen3()")

    --
    -- Write to popen3's stdin, important to close it as some (most?) proccess
    -- block until the stdin pipe is closed
    --
    posix.write(w, input)
    posix.close(w)

    local bufsize = 4096
    local timeout = 100

    --
    -- Read popen3's stdout and stderr simultanously via Posix file handle
    --
    local stdout = {}
    local stderr = {}
    local stdout_ended = false
    local stderr_ended = false
    local read_stdout = coroutine.create(function () read_async(r, bufsize, timeout) end)
    local read_stderr = coroutine.create(function () read_async(e, bufsize, timeout) end)
    while true do
        if not stdout_ended then
            local _, pstatus, ended, buf, _ = coroutine.resume(read_stdout)
            if pstatus == 1 then
                stdout_ended = ended
                if not stdout_ended then
                    stdout[#stdout + 1] = buf
                    if M.__verbose then print(buf:sub(1, -2)) end
                end
            end
        end

        if not stderr_ended then
            local _, pstatus, ended, buf, _ = coroutine.resume(read_stderr)
            if pstatus == 1 then
                stderr_ended = ended
                if not stderr_ended then
                    stderr[#stderr + 1] = buf
                    if M.__verbose then print(buf:sub(1, -2)) end
                end
            end
        end

        if stdout_ended and stderr_ended then break end
    end

    --
    -- Clean-up child (no zombies) and get return status
    --
    local _, wait_cause, wait_status = posix.wait(pid)
    posix.close(r)
    posix.close(e)

    return wait_status, wait_cause, table.concat(stdout), table.concat(stderr)
end


M.PIPES = {}

local function launch_pipe_simple(input, cmd, ...)
    --
    -- Launch child process
    --
    local pid, w, r, e = popen3(cmd, table.unpack({...}))
    assert(pid ~= nil, "pipe_simple() unable to popen3()")

    --
    -- Write to popen3's stdin, important to close it as some (most?) proccess
    -- block until the stdin pipe is closed
    --
    posix.write(w, input)
    posix.close(w)

    local bufsize = 4096
    local timeout = 100

    M.PIPES[#M.PIPES+1] = {
        cmd = cmd,
        out = coroutine.create(function () read_async(r, bufsize, timeout) end),
        err = coroutine.create(function () read_async(e, bufsize, timeout) end),
        out_pipe = r,
        err_pipe = e,
        pid = pid,
        out_active = true,
        err_active = true
    }
end

M.launch_pipe_simple = launch_pipe_simple


local function collect_pipes()
    --
    -- Read popen3's stdout and stderr simultanously via Posix file handle
    --
    local stdout = {}
    local stderr = {}
    local stdout_ended = false
    local stderr_ended = false

    local outputs = {}

    while true do
        for k, v in pairs (M.PIPES) do
            local pipe = M.PIPES[k]
            if not pipe.stdout_active then
                local _, pstatus, ended, buf, _ = coroutine.resume(pipe.out)
                if pstatus == 1 then
                    stdout_ended = ended
                    if not stdout_ended then
                        stdout[#stdout + 1] = buf
                    end
                end
            end
        end
        if not stdout_ended then
            local _, pstatus, ended, buf, _ = coroutine.resume(read_stdout)
            if pstatus == 1 then
                stdout_ended = ended
                if not stdout_ended then
                    stdout[#stdout + 1] = buf
                end
            end
        end

        if not stderr_ended then
            local _, pstatus, ended, buf, _ = coroutine.resume(read_stderr)
            if pstatus == 1 then
                stderr_ended = ended
                if not stderr_ended then
                    stderr[#stderr + 1] = buf
                end
            end
        end

        if stdout_ended and stderr_ended then break end
    end

    --
    -- Clean-up child (no zombies) and get return status
    --
    local _, wait_cause, wait_status = posix.wait(pid)
    posix.close(r)
    posix.close(e)

    return wait_status, wait_cause, table.concat(stdout), table.concat(stderr)
end

M.collect_pipes = collect_pipes


--
-- converts key and it's argument to "-k" or "-k=v" or just ""
--
local function arg(k, a)
    if not a then return k end
    if type(a) == "string" and #a > 0 then return k .. "=" .. a end
    if type(a) == "number" then return k .. "=" .. _lua_tostring(a) end
    if type(a) == "boolean" and a == true then return k end
    error("invalid argument type: " .. type(a), a)
end

--
-- converts nested tables into a flat list of arguments and concatenated input
--
local function flatten(t)
    local result = {
        args = {}, input = "", __stdout = "", __stderr = "",
        __exitcode = nil, __signal = nil
    }

    local function f(t)
        local keys = {}
        for k = 1, #t do
            keys[k] = true
            local v = t[k]
            if type(v) == "table" then
                f(v)
            else
                table.insert(result.args, _lua_tostring(v))
            end
        end
        for k, v in pairs(t) do
            if k == "__input" then
                result.input = result.input .. v
            elseif k == "__stdout" then
                result.__stdout = result.__stdout .. v
            elseif k == "__stderr" then
                result.__stderr = result.__stderr .. v
            elseif k == "__exitcode" then
                result.__exitcode = v
            elseif k == "__signal" then
                result.__signal = v
            elseif not keys[k] and k:sub(1, 1) ~= "_" then
                local key = '-' .. k
                if #k > 1 then key = "-" .. key end
                table.insert(result.args, arg(key, v))
            end
        end
    end

    f(t)
    return result
end

--
-- return a string representation of a shell command output
--
local function strip(str)
    -- capture repeated charaters (.-) startign with the first non-space ^%s,
    -- and not captuing any trailing spaces %s*
    return str:match("^%s*(.-)%s*$")
end

local function tostring(self)
    -- return trimmed command output as a string
    local out = strip(self.__stdout)
    local err = strip(self.__stderr)
    if #err == 0 then
        return out
    end
    -- if there is an error, print the output and error string
    return "O: " .. out .. "\nE: " .. err .. "\n" .. self.__exitcode
end

---the concatenation (..) operator must be overloaded so you don't have to keep calling `tostring`
local function concat(self, rhs)
    local out, err = self, ""
    if type(out) ~= "string" then out, err = strip(self.__stdout), strip(self.__stderr) end

    if #err ~= 0 then out = "O: " .. out .. "\nE: " .. err .. "\n" .. self.__exitcode end

    --Errors when type(rhs) == "string" for some reason
    return out..(type(rhs) == "string" and rhs or tostring(rhs))
end

--
-- Configurable flag that will raise errors and/or halt program on error
--
M.__raise_errors  = true

--
-- returns a function that executes the command with given args and returns its
-- output, exit status etc
--
---@param cmd sh.CommandName | string
---@param ... string
---@return fun(...: string | sh.ReturnType): sh.ReturnType
local function command(cmd, ...)
    local prearg = {...}
    return function(...)
        local args = flatten({...})
        local all_args = {}
        for _, x in pairs(prearg) do
            table.insert(all_args, _lua_tostring(x))
        end
        for _, x in pairs(args.args) do
            table.insert(all_args, _lua_tostring(x))
        end

        local status, cause, stdout, stderr = pipe_simple(
            args.input, cmd, table.unpack(all_args)
        )

        if M.__raise_errors and status ~= 0 then
            error(stderr)
        end

        local t = {
            __input = stdout, -- set input = output for pipelines
            __stdout = stdout,
            __stderr = stderr,
            __exitcode = cause == "exited" and status or 127,
            __signal = cause == "killed" and status or 0,
        }
        local mt = {
            __index = function(self, k, ...)
                return M[k]
            end,
            __tostring = tostring,
            __concat = concat
        }
        return setmetatable(t, mt)
    end
end

--
-- get global metatable
--
local mt = getmetatable(_G)
if mt == nil then
    mt = {}
    setmetatable(_G, mt)
end

--
-- String comparison functions: strcmp (returns true only if two strings are
-- identical), prefcmp (returns true only if the second string starts with the
-- first string).
--
local function strcmp(a, b)
    return a == b
end

local function prefcmp(a, b)
    return a == b:sub(1, #a)
end

local function list_contains(v, t, comp)
    for _, kv in pairs(v) do
        if comp(kv, t) then
            return true
        end
    end
    return false
end

--
-- Define patterns that the __index function should ignore
--
M.__index_ignore_prefix   = {"_G", "_PROMPT"}
M.__index_ignore_exact    = {}
M.__index_ignore_function = {"cd", "pushd", "popd", "stdout", "stderr", "print"}

--
-- set hook for undefined variables
--
---Adds the shell functions into the global table
local function install()
    mt.__index = function(t, cmd)
        if list_contains(M.__index_ignore_prefix, cmd, prefcmp) then
            return rawget(t, cmd)
        end
        if list_contains(M.__index_ignore_exact, cmd, strcmp) then
            return rawget(t, cmd)
        end
        if list_contains(M.__index_ignore_function, cmd, strcmp) then
            return M.FUNCTIONS[cmd]
        end
        return command(cmd)
    end
end

--
-- manually defined functions
--
M.FUNCTIONS = {}

local function cd(...)
    local args = flatten({...})
    local dir = args.args[1]
    local pt = posix.chdir(dir)
    local t = {
        __input = args.input, -- set input = output from previous pipelines
        __stdout = args.__stdout,
        __stderr = args.__stderr,
        __exitcode = args.__exitcode,
        __signal = args.__signal
    }
    if pt == nil then
        t.__stderr = "cd: The directory \'" .. dir .. "\' does not exist"
        t.__exitcode = 1
    end
    local mt = {
        __index = function(self, k, ...)
            return M[k]
        end,
        __tostring = tostring,
        __concat = concat
    }
    return setmetatable(t, mt)
end

local function stdout(t)
    return t.__stdout
end

local function stderr(t)
    return t.__stderr
end

M.PUSHD_STACK = Stack:Create()

local function pushd(...)
    local args = flatten({...})
    local dir = args.args[1]
    local old_dir = strip(stdout(M.pwd()))
    local pt = posix.chdir(dir)
    if pt ~= nil then
        M.PUSHD_STACK:push(old_dir)
    end
    local t = {
        __input = args.input, -- set input = output from previous pipelines
        __stdout = args.__stdout,
        __stderr = args.__stderr,
        __exitcode = args.__exitcode,
        __signal = args.__signal
    }
    if pt == nil then
        t.__stderr = "pushd: The directory \'" .. dir .. "\' does not exist"
        t.__exitcode = 1
    end
    local mt = {
        __index = function(self, k, ...)
            return M[k]
        end,
        __tostring = tostring,
        __concat = concat
    }
    return setmetatable(t, mt)
end

local function popd(...)
    local args = flatten({...})
    local ndir = M.PUSHD_STACK:getn()
    local dir = M.PUSHD_STACK:pop(1)
    local pt
    if ndir > 0 then
        pt = posix.chdir(dir)
    else
        pt = nil
        dir = "EMPTY"
    end
    local t = {
        __input = args.input, -- set input = output from previous pipelines
        __stdout = args.__stdout,
        __stderr = args.__stderr,
        __exitcode = args.__exitcode,
        __signal = args.__signal
    }
    if pt == nil then
        t.__stderr = "popd: The directory \'" .. dir .. "\' does not exist"
        t.__exitcode = 1
    end
    local mt = {
        __index = function(self, k, ...)
            return M[k]
        end,
        __tostring = tostring,
        __concat = concat
    }
    return setmetatable(t, mt)
end

local _lua_print = print
local function print(...)
    local args = flatten({...})
    _lua_print(tostring(args))
    local t = {
        __input = args.input, -- set input = output from previous pipelines
        __stdout = args.__stdout,
        __stderr = args.__stderr,
        __exitcode = args.__exitcode,
        __signal = args.__signal
    }
    local mt = {
        __index = function(self, k, ...)
            return M[k]
        end,
        __tostring = tostring,
        __concat = concat
    }
    return setmetatable(t, mt)
end

M.FUNCTIONS.cd = cd
M.FUNCTIONS.stdout = stdout
M.FUNCTIONS.stderr = stderr
M.FUNCTIONS.pushd = pushd
M.FUNCTIONS.popd  = popd
M.FUNCTIONS.print = print

--
-- export command() and install() functions
--
M.command = command
M.install = install

--
-- allow to call sh to run shell commands
--
setmetatable(M, {
    __call = function(_, cmd, ...)
        return command(cmd, ...)
    end,
    __index = function(t, cmd)
        if list_contains(M.__index_ignore_function, cmd, strcmp) then
            return M.FUNCTIONS[cmd]
        end
        return command(cmd)
    end
})

return M
end
end

do
local _ENV = _ENV
package.preload[ "toml" ] = function( ... ) local arg = _G.arg;
local TOML = {
	-- denotes the current supported TOML version
	version = 0.40,

	-- sets whether the parser should follow the TOML spec strictly
	-- currently, no errors are thrown for the following rules if strictness is turned off:
	--   tables having mixed keys
	--   redefining a table
	--   redefining a key within a table
	strict = true,
}

-- converts TOML data into a lua table
TOML.parse = function(toml, options)
	options = options or {}
	local strict = (options.strict ~= nil and options.strict or TOML.strict)

	-- the official TOML definition of whitespace
	local ws = "[\009\032]"

	-- the official TOML definition of newline
	local nl = "[\10"
	do
		local crlf = "\13\10"
		nl = nl .. crlf
	end
	nl = nl .. "]"
	
	-- stores text data
	local buffer = ""

	-- the current location within the string to parse
	local cursor = 1

	-- the output table
	local out = {}

	-- the current table to write to
	local obj = out

	-- returns the next n characters from the current position
	local function char(n)
		n = n or 0
		return toml:sub(cursor + n, cursor + n)
	end

	-- moves the current position forward n (default: 1) characters
	local function step(n)
		n = n or 1
		cursor = cursor + n
	end

	-- move forward until the next non-whitespace character
	local function skipWhitespace()
		while(char():match(ws)) do
			step()
		end
	end

	-- remove the (Lua) whitespace at the beginning and end of a string
	local function trim(str)
		return str:gsub("^%s*(.-)%s*$", "%1")
	end

	-- divide a string into a table around a delimiter
	local function split(str, delim)
		if str == "" then return {} end
		local result = {}
		local append = delim
		if delim:match("%%") then
			append = delim:gsub("%%", "")
		end
		for match in (str .. append):gmatch("(.-)" .. delim) do
			table.insert(result, match)
		end
		return result
	end

	-- produce a parsing error message
	-- the error contains the line number of the current position
	local function err(message, strictOnly)
		if not strictOnly or (strictOnly and strict) then
			local line = 1
			local c = 0
			for l in toml:gmatch("(.-)" .. nl) do
				c = c + l:len()
				if c >= cursor then
					break
				end
				line = line + 1
			end
			error("TOML: " .. message .. " on line " .. line .. ".", 4)
		end
	end

	-- prevent infinite loops by checking whether the cursor is
	-- at the end of the document or not
	local function bounds()
		return cursor <= toml:len()
	end

	local function parseString()
		local quoteType = char() -- should be single or double quote

		-- this is a multiline string if the next 2 characters match
		local multiline = (char(1) == char(2) and char(1) == char())

		-- buffer to hold the string
		local str = ""

		-- skip the quotes
		step(multiline and 3 or 1)

		while(bounds()) do
			if multiline and char():match(nl) and str == "" then
				-- skip line break line at the beginning of multiline string
				step()
			end

			-- keep going until we encounter the quote character again
			if char() == quoteType then
				if multiline then
					if char(1) == char(2) and char(1) == quoteType then
						step(3)
						break
					end
				else
					step()
					break
				end
			end

			if char():match(nl) and not multiline then
				err("Single-line string cannot contain line break")
			end

			-- if we're in a double-quoted string, watch for escape characters!
			if quoteType == '"' and char() == "\\" then
				if multiline and char(1):match(nl) then
					-- skip until first non-whitespace character
					step(1) -- go past the line break
					while(bounds()) do
						if not char():match(ws) and not char():match(nl) then
							break
						end
						step()
					end
				else
					-- all available escape characters
					local escape = {
						b = "\b",
						t = "\t",
						n = "\n",
						f = "\f",
						r = "\r",
						['"'] = '"',
						["\\"] = "\\",
					}
					-- utf function from http://stackoverflow.com/a/26071044
					-- converts \uXXX into actual unicode
					local function utf(char)
						local bytemarkers = {{0x7ff, 192}, {0xffff, 224}, {0x1fffff, 240}}
						if char < 128 then return string.char(char) end
						local charbytes = {}
						for bytes, vals in pairs(bytemarkers) do
							if char <= vals[1] then
								for b = bytes + 1, 2, -1 do
									local mod = char % 64
									char = (char - mod) / 64
									charbytes[b] = string.char(128 + mod)
								end
								charbytes[1] = string.char(vals[2] + char)
								break
							end
						end
						return table.concat(charbytes)
					end

					if escape[char(1)] then
						-- normal escape
						str = str .. escape[char(1)]
						step(2) -- go past backslash and the character
					elseif char(1) == "u" then
						-- utf-16
						step()
						local uni = char(1) .. char(2) .. char(3) .. char(4)
						step(5)
						uni = tonumber(uni, 16)
						if (uni >= 0 and uni <= 0xd7ff) and not (uni >= 0xe000 and uni <= 0x10ffff) then
							str = str .. utf(uni)
						else
							err("Unicode escape is not a Unicode scalar")
						end
					elseif char(1) == "U" then
						-- utf-32
						step()
						local uni = char(1) .. char(2) .. char(3) .. char(4) .. char(5) .. char(6) .. char(7) .. char(8)
						step(9)
						uni = tonumber(uni, 16)
						if (uni >= 0 and uni <= 0xd7ff) and not (uni >= 0xe000 and uni <= 0x10ffff) then
							str = str .. utf(uni)
						else
							err("Unicode escape is not a Unicode scalar")
						end
					else
						err("Invalid escape")
					end
				end
			else
				-- if we're not in a double-quoted string, just append it to our buffer raw and keep going
				str = str .. char()
				step()
			end
		end

		return {value = str, type = "string"}
	end

	local function parseNumber()
		local num = ""
		local exp
		local date = false
		while(bounds()) do
			if char():match("[%+%-%.eE_0-9]") then
				if not exp then
					if char():lower() == "e" then
						-- as soon as we reach e or E, start appending to exponent buffer instead of
						-- number buffer
						exp = ""
					elseif char() ~= "_" then
						num = num .. char()
					end
				elseif char():match("[%+%-0-9]") then
					exp = exp .. char()
				else
					err("Invalid exponent")
				end
			elseif char():match(ws) or char() == "#" or char():match(nl) or char() == "," or char() == "]" or char() == "}" then
				break
			elseif char() == "T" or char() == "Z" then
				-- parse the date (as a string, since lua has no date object)
				date = true
				while(bounds()) do
					if char() == "," or char() == "]" or char() == "#" or char():match(nl) or char():match(ws) then
						break
					end
					num = num .. char()
					step()
				end
			else
				err("Invalid number")
			end
			step()
		end

		if date then
			return {value = num, type = "date"}
		end

		local float = false
		if num:match("%.") then float = true end

		exp = exp and tonumber(exp) or 0
		num = tonumber(num)

		if not float then
			return {
				-- lua will automatically convert the result
				-- of a power operation to a float, so we have
				-- to convert it back to an int with math.floor
				value = math.floor(num * 10^exp),
				type = "int",
			}
		end

		return {value = num * 10^exp, type = "float"}
	end

	local parseArray, getValue
	
	function parseArray()
		step() -- skip [
		skipWhitespace()

		local arrayType
		local array = {}

		while(bounds()) do
			if char() == "]" then
				break
			elseif char():match(nl) then
				-- skip
				step()
				skipWhitespace()
			elseif char() == "#" then
				while(bounds() and not char():match(nl)) do
					step()
				end
			else
				-- get the next object in the array
				local v = getValue()
				if not v then break end

				-- set the type if it hasn't been set before
				if arrayType == nil then
					arrayType = v.type
				elseif arrayType ~= v.type then
					err("Mixed types in array", true)
				end

				array = array or {}
				table.insert(array, v.value)
				
				if char() == "," then
					step()
				end
				skipWhitespace()
			end
		end
		step()

		return {value = array, type = "array"}
	end

	local function parseInlineTable()
		step() -- skip opening brace

		local buffer = ""
		local quoted = false
		local tbl = {}

		while bounds() do
			if char() == "}" then
				break
			elseif char() == "'" or char() == '"' then
				buffer = parseString().value
				quoted = true
			elseif char() == "=" then
				if not quoted then
					buffer = trim(buffer)
				end

				step() -- skip =
				skipWhitespace()

				if char():match(nl) then
					err("Newline in inline table")
				end

				local v = getValue().value
				tbl[buffer] = v

				skipWhitespace()

				if char() == "," then
					step()
				elseif char():match(nl) then
					err("Newline in inline table")
				end

				quoted = false
				buffer = ""
			else
				buffer = buffer .. char()
				step()
			end
		end
		step() -- skip closing brace

		return {value = tbl, type = "array"}
	end

	local function parseBoolean()
		local v
		if toml:sub(cursor, cursor + 3) == "true" then
			step(4)
			v = {value = true, type = "boolean"}
		elseif toml:sub(cursor, cursor + 4) == "false" then
			step(5)
			v = {value = false, type = "boolean"}
		else
			err("Invalid primitive")
		end

		skipWhitespace()
		if char() == "#" then
			while(not char():match(nl)) do
				step()
			end
		end

		return v
	end

	-- figure out the type and get the next value in the document
	function getValue()
		if char() == '"' or char() == "'" then
			return parseString()
		elseif char():match("[%+%-0-9]") then
			return parseNumber()
		elseif char() == "[" then
			return parseArray()
		elseif char() == "{" then
			return parseInlineTable()
		else
			return parseBoolean()
		end
		-- date regex (for possible future support):
		-- %d%d%d%d%-[0-1][0-9]%-[0-3][0-9]T[0-2][0-9]%:[0-6][0-9]%:[0-6][0-9][Z%:%+%-%.0-9]*
	end

	-- track whether the current key was quoted or not
	local quotedKey = false
	
	-- parse the document!
	while(cursor <= toml:len()) do

		-- skip comments and whitespace
		if char() == "#" then
			while(not char():match(nl)) do
				step()
			end
		end

		if char():match(nl) then
			-- skip
		end

		if char() == "=" then
			step()
			skipWhitespace()
			
			-- trim key name
			buffer = trim(buffer)

			if buffer:match("^[0-9]*$") and not quotedKey then
				buffer = tonumber(buffer)
			end

			if buffer == "" and not quotedKey then
				err("Empty key name")
			end

			local v = getValue()
			if v then
				-- if the key already exists in the current object, throw an error
				if obj[buffer] then
					err('Cannot redefine key "' .. buffer .. '"', true)
				end
				obj[buffer] = v.value
			end

			-- clear the buffer
			buffer = ""
			quotedKey = false

			-- skip whitespace and comments
			skipWhitespace()
			if char() == "#" then
				while(bounds() and not char():match(nl)) do
					step()
				end
			end

			-- if there is anything left on this line after parsing a key and its value,
			-- throw an error
			if not char():match(nl) and cursor < toml:len() then
				err("Invalid primitive")
			end
		elseif char() == "[" then
			buffer = ""
			step()
			local tableArray = false

			-- if there are two brackets in a row, it's a table array!
			if char() == "[" then
				tableArray = true
				step()
			end

			obj = out

			local function processKey(isLast)
				isLast = isLast or false
				buffer = trim(buffer)

				if not quotedKey and buffer == "" then
					err("Empty table name")
				end

				if isLast and obj[buffer] and not tableArray and #obj[buffer] > 0 then
					err("Cannot redefine table", true)
				end

				-- set obj to the appropriate table so we can start
				-- filling it with values!
				if tableArray then
					-- push onto cache
					if obj[buffer] then
						obj = obj[buffer]
						if isLast then
							table.insert(obj, {})
						end
						obj = obj[#obj]
					else
						obj[buffer] = {}
						obj = obj[buffer]
						if isLast then
							table.insert(obj, {})
							obj = obj[1]
						end
					end
				else
					obj[buffer] = obj[buffer] or {}
					obj = obj[buffer]
				end
			end

			while(bounds()) do
				if char() == "]" then
					if tableArray then
						if char(1) ~= "]" then
							err("Mismatching brackets")
						else
							step() -- skip inside bracket
						end
					end
					step() -- skip outside bracket

					processKey(true)
					buffer = ""
					break
				elseif char() == '"' or char() == "'" then
					buffer = parseString().value
					quotedKey = true
				elseif char() == "." then
					step() -- skip period
					processKey()
					buffer = ""
				else
					buffer = buffer .. char()
					step()
				end
			end

			buffer = ""
			quotedKey = false
		elseif (char() == '"' or char() == "'") then
			-- quoted key
			buffer = parseString().value
			quotedKey = true
		end

		buffer = buffer .. (char():match(nl) and "" or char())
		step()
	end

	return out
end

TOML.encode = function(tbl)
	local toml = ""

	local cache = {}

	local function parse(tbl)
		for k, v in pairs(tbl) do
			if type(v) == "boolean" then
				toml = toml .. k .. " = " .. tostring(v) .. "\n"
			elseif type(v) == "number" then
				toml = toml .. k .. " = " .. tostring(v) .. "\n"
			elseif type(v) == "string" then
				local quote = '"'
				v = v:gsub("\\", "\\\\")

				-- if the string has any line breaks, make it multiline
				if v:match("^\n(.*)$") then
					quote = quote:rep(3)
					v = "\\n" .. v
				elseif v:match("\n") then
					quote = quote:rep(3)
				end

				v = v:gsub("\b", "\\b")
				v = v:gsub("\t", "\\t")
				v = v:gsub("\f", "\\f")
				v = v:gsub("\r", "\\r")
				v = v:gsub('"', '\\"')
				v = v:gsub("/", "\\/")
				toml = toml .. k .. " = " .. quote .. v .. quote .. "\n"
			elseif type(v) == "table" then
				local array, arrayTable = true, true
				local first = {}
				for kk, vv in pairs(v) do
					if type(kk) ~= "number" then array = false end
					if type(vv) ~= "table" then
						v[kk] = nil
						first[kk] = vv
						arrayTable = false
					end
				end

				if array then
					if arrayTable then
						-- double bracket syntax go!
						table.insert(cache, k)
						for kk, vv in pairs(v) do
							toml = toml .. "[[" .. table.concat(cache, ".") .. "]]\n"
							for k3, v3 in pairs(vv) do
								if type(v3) ~= "table" then
									vv[k3] = nil
									first[k3] = v3
								end
							end
							parse(first)
							parse(vv)
						end
						table.remove(cache)
					else
						-- plain ol boring array
						toml = toml .. k .. " = [\n"
						for kk, vv in pairs(first) do
							toml = toml .. tostring(vv) .. ",\n"
						end
						toml = toml .. "]\n"
					end
				else
					-- just a key/value table, folks
					table.insert(cache, k)
					toml = toml .. "[" .. table.concat(cache, ".") .. "]\n"
					parse(first)
					parse(v)
					table.remove(cache)
				end
			end
		end
	end
	
	parse(tbl)
	
	return toml:sub(1, -2)
end

return TOML
end
end

--------------------------------------------------------------------------------
-- sets up environment and defines common helper functions
--------------------------------------------------------------------------------
local gears = require "gears"

-- dependencies
local argparse = require "argparse"
local lustache = require "lustache"
-- local inspect  = require "inspect"
local f        = require "F"
local sh       = require "sh"
local log      = require "log"
local toml     = require "toml"
local posix    = require "posix"

--------------------------------------------------------------------------------
-- manage environment for install and produced artifacts
--------------------------------------------------------------------------------

local SM_PRE_INSTALL_VERSION = "SM-PRE-INSTALL"

local subsitutions = {
    SITE_DESTINATION = {
        check = function(_, _)
            -- config.site.destination will ALWAYS exist
            return true
        end,
        get = function(config, _)
            return config.site.destination
        end
    },
    SITE_NAME = {
        check = function()
            -- config.site.name will ALWAYS exist
            return true
        end,
        get = function(config, _)
            return config.site.name
        end
    },
    SITE_VARIANT = {
        check = function(config, _)
            return (nil ~= config.site.variant)
        end,
        get = function(config, _)
            return config.site.variant
        end
    },
    SITE_CONFIG_DIR = {
        check = function()
            -- state.config_dir will ALWAYS exist
            return true
        end,
        get = function(_, state)
            return state.config_dir
        end
    },
    INSTALL_VERSION = {
        check = function(_, state)
            return (nil ~= state.version)
        end,
        get = function(_, state)
            return state.version
        end
    },
    INSTALL_VERSION_VARIANT = {
        check = function(config, state)
            return (nil ~= config.site.variant) or (nil ~= state.version)
        end,
        get = function(config, state)
            if (nil ~= config.site.variant) and (nil ~= state.version) then
                return state.version .. "-" .. config.site.variant
            elseif (nil == config.site.variant) and (nil ~= state.version) then
                return state.version
            elseif (nil ~= config.site.variant) and (nil == state.version) then
                return config.site.variant
            end
        end
    },
    INSTALL_DIR = {
        check = function(_, state)
            return (nil ~= state.install_dir)
        end,
        get = function(_, state)
            return state.install_dir
        end
    },
    STAGE_DIR = {
        check = function(config, _)
            return (true == config.install.stage)
        end,
        get = function(config, state)
            local name = config.site.name
            local version = state.version
            if nil ~= config.site.variant then
                local variant = config.site.variant
                -- NOTE: deliberately not using f-string => doesn't seem to
                -- work properly here, don't know why though
                return name .. "-" .. variant .. "-" .. version
            else
                -- NOTE: deliberately not using f-string => doesn't seem to
                -- work properly here, don't know why though
                return name .. "-" .. version
            end
        end
    },
    PRE_STAGE_DIR = {
        check = function(config, _)
            return (true == config.install.stage)
        end,
        get = function(config, state)
            local name = config.site.name
            local version = SM_PRE_INSTALL_VERSION
            if nil ~= config.site.variant then
                local variant = config.site.variant
                -- NOTE: deliberately not using f-string => doesn't seem to
                -- work properly here, don't know why though
                return name .. "-" .. variant .. "-" .. version
            else
                -- NOTE: deliberately not using f-string => doesn't seem to
                -- work properly here, don't know why though
                return name .. "-" .. version
            end
        end
    }
}

local function replace(str, var, val)
    local new_str, _ = str:gsub("{"..var.."}", val)
    return new_str
end

local function replace_all(str, map, config, state, escape)
    if nil == escape then escape = false end
    -- ensure that we're operating on a string
    if "string" ~= type(str) then
        log.trace(f"Skipping: '{str}' => not a string")
        return str
    end
    -- make a copy of the string (this is probably paranoid, but we care about
    -- stafety over performance here anyway)
    local env = str
    -- substitute all occurances of `{NAME}` in the `map`
    log.trace(f"Applying replace_all to candidate: {str}")
    for k, v in pairs(map) do
        if v.check(config, state) then
            if escape then
                -- escape any "-" characters in the substitution map
                -- Note: adding additional escape sequence `%%` because it's
                -- being used in another `gsub`
                env = replace(env, k, v.get(config, state):gsub("-", "%%%%-"))
            else
                env = replace(env, k, v.get(config, state))
            end
        elseif env:find("{"..k.."}") then
            log.fatal(f"String {env} requires undefined {k}")
            error("Failed substitution.")
        end
    end
    return env
end

local function setenv(map, config, state)
    for k, v in pairs(config.env) do
        -- substitute `{NAME}`. Converting non-string types to string (required
        -- by posix.setenv)
        local env = tostring(replace_all(v, map, config, state))
        -- set environment
        log.info(f"Setting environment: {k}={env}")
        posix.setenv(k, env)
    end
end

local function stage_dir_name(name, variant, version)
    local dn
    if nil ~= variant then
        dn = f"{name}-{variant}-{version}"
    else
        dn = f"{name}-{version}"
    end
    return dn
end

local function find_installed_artifacts(map, config, state)
    local installed_artifacts = {}

    for _, version in pairs(config.install.versions) do
        local prefix = replace_all(config.install.prefix, map, config, {
                config_dir=state.config_dir,
                version=version
            }
        )

        local target = replace_all(config.install.format, map, config, {
                config_dir=state.config_dir,
                version=version
            }, true -- ensure that any "-" characters in var substitutions are escacped
        )

        log.trace(f"Looking for {target} in {prefix} ...")

        if not gears.isdir(prefix) then
            log.warn("Prefix: " .. prefix .. " is not a valid location")
            goto outer_continue
        end

        for file in string.gmatch(tostring(sh.ls(prefix)), "[^\n]+") do
            log.trace(f"Analyzing {file} in {prefix}")
            if not gears.isdir(prefix .. "/" .. file) then
                log.trace(f"{file} is not a dir => skipping")
                goto continue
            end
            -- select the target folder that matches the format
            if string.match(file, target) then
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
        ::outer_continue::
    end

    --check if any artifacts have been found, if not raise error:
    if nil == next(installed_artifacts) then
        log.fatal("Did not find any artifacts!")
        log.fatal(f"Prefix: {config.install.prefix}")
        log.fatal(f"Format: {config.install.format}")
        log.fatal(
            f"ls {config.site.destination}:\n" ..
            sh.ls(config.site.destination) .. "\n"
        )
        error("Artificat discovery error.")
    end
    return installed_artifacts
end

-------------------------------------------------------------------------------
-- parse settings
--------------------------------------------------------------------------------

-- set up CLI parser
local parser = argparse(
    "simple-modules",
    "Install software and generate module files with no fuss."
)
parser:argument("config_dir", "Directory containing settings files")
parser:option("--name", "Name to use in module file")
parser:option("--variant", "Variant name to use in module file")
parser:option("--relocate", "Relocate the output of the install.sh script")
parser:option("--destination", "Location where to install software to")
parser:option("--modules", "Location of the environment modules folder")
parser:option("--sm-root", "Optional variable to use in place of {SM_ROOT}")

local args = parser:parse()
local config_dir = gears.realdir(args.config_dir)
local sm_root = args.sm_root
if nil ~= sm_root then
    -- ensure that <sm_root> is not a file
    if gears.file_exists(sm_root) then
        log.fatal(f"SM_ROOT={sm_root} is a file, but needs to be a directory!")
        os.exit(1)
    end
    if not gears.dir_exists(sm_root) then
        log.warn(f"SM_ROOT={sm_root} does not exist, creating...")
        -- ensure that the <sm_root> directory exists
        sh.mkdir("-p", sm_root) -- ensure order => don't use table
    end
    sm_root = gears.realdir(sm_root)
end

-- module settings
local settings_file = table.concat(
    gears.read_lines(config_dir .. "/settings.toml"), "\n"
)
-- deployment settings
local local_settings_file = ""
if gears.file_exists(config_dir .. "/local_settings.toml") then
    local_settings_file = table.concat(
        gears.read_lines(config_dir .. "/local_settings.toml"), "\n"
    )
end
-- print the settings file (for debug purposes)
log.info("Installing with settings:\n" .. settings_file)
log.info("Local settings:\n" .. local_settings_file)
-- print the content of SM_ROOT and other CLI settings it they are specfied
log.info("CLI settings:")
if nil ~= sm_root then log.info("SM_ROOT = " .. sm_root) end
if nil ~= args.name then log.info("name = " .. args.name) end
if nil ~= args.variant then log.info("variant = " .. args.variant) end
if nil ~= args.recocate then log.info("recocate = " .. args.recocate) end
if nil ~= args.destination then log.info("destination = " .. args.destination) end
if nil ~= args.modules then log.info("modules = " .. args.modules) end
-- these settings will be used later
local settings = toml.parse(settings_file)
-- ensure that arg[2] is present if the local_settings_file depends on it
if (nil ~= string.find(local_settings_file, "{SM_ROOT}")) and (nil == sm_root) then
    log.fatal("Cannot proceed: SM_ROOT required but not set")
    error("Failed subsitution")
end
-- append local settings, and substituting SM_ROOT for arg[2] if it exists
if nil ~= sm_root then
    settings.site = toml.parse(replace(local_settings_file, "SM_ROOT", sm_root))
else
    settings.site = toml.parse(local_settings_file)
end
-- apply CLI settings to local (site) settings file
for k, v in pairs(args) do
    if k == "config_dir" then goto continue end
    if k == "sm_root" then goto continue end
    -- SM_ROOT also applis to the CLI
    local sub_v = v
    if nil ~= sm_root then
        sub_v = replace(v, "SM_ROOT", sm_root)
    end
    -- Warn user if local_settings.toml is being overwritten
    if nil ~= settings.site[k] then
        log.warn(f"Overwriting {k} in local_settings.toml with: {sub_v}")
    end
    -- relocate is special
    if k == "relocate" then
        if v == "keep" then goto continue end
        if v == "true" or v == 1 then sub_v = true
        elseif v == "false" or v == 0 then sub_v = false
        else
            log.fatal(f"{k} must be boolish")
            error("Parse error.")
        end
    end
    -- apply overwrite
    settings.site[k] = sub_v
    ::continue::
end

--------------------------------------------------------------------------------
-- sanity check
--------------------------------------------------------------------------------

if (true == settings.install.relocate) and (true ~= setting.site.relocate) then
    log.warn("Overwriting `site.relocate == true` to match `install.relocate`")
    settings.site.relocate = true
end

if (false == settings.install.relocate) and (false ~= setting.site.relocate) then
    log.warn("Overwriting `site.relocate == false` to match `install.relocate`")
    settings.site.relocate = false
end

if (true == settings.install.stage) and (true == settings.post.clean) then
    if (true == settings.post.safe) and (false == settings.site.relocate) then
        log.warn(table.concat({
            "Setting `install.stage` and `post.clean` to true in settings.toml",
            "requires `relocate` to be set to true also. Ignoring the value in",
            "`relocate`."
        }, " "))
        log.info("Overwriting: `settings.site.relocate = true`")
        settings.site.relocate = true
    end
end

--------------------------------------------------------------------------------
-- run {pre,post}-installer
--------------------------------------------------------------------------------

-- ensure that the destination exists, and switch to that directory: this will
-- be the working directory for any extract/build/install
sh.mkdir("-p", settings.site.destination) -- ensure order => don't use table
sh.cd(settings.site.destination)

local function ensure_stage_dir(name, variant, version)
    local dn = stage_dir_name(name, variant, version)

    log.info(f"Using staging dir: {dn} exists")
    sh.mkdir("-p", dn) -- ensure order => don't use table

    -- stage dir must be empty
    for file in string.gmatch(tostring(sh.ls(dn)), "[^\n]+") do
        log.trace(f"Deleting: {dn}/{file}")
        sh.rm("-r", "-f", f"{dn}/{file}") -- ensure order => don't use table
    end
end

-- run pre_install script
if gears.file_exists(config_dir .. "/pre_install.sh") then
    log.info("pre_install.sh exists! Running now ...")

    setenv(
        subsitutions, settings,
        {config_dir=config_dir, version=SM_PRE_INSTALL_VERSION}
    )
    sh.__verbose = true
    sh("bash"){config_dir .. "/pre_install.sh"}
    sh.__verbose = false
else
    log.info("pre_install.sh does not exist!")
end

-- run install script for each version
if gears.file_exists(config_dir .. "/install.sh") then
    log.info("install.sh exists! Running now ...")

    for _, version in pairs(settings.install.versions) do
        log.info(f"Running installer for version {version}")

        -- create clean staging directory
        if true == settings.install.stage then
            ensure_stage_dir(settings.site.name, settings.site.variant, version)
            sh.pushd(stage_dir_name(
                settings.site.name, settings.site.variant, version
            ))
        end

        setenv(subsitutions, settings, {config_dir=config_dir, version=version})
        sh.__verbose = true
        sh("bash"){config_dir .. "/install.sh"}
        sh.__verbose = false

        -- if using a stagign directory, then remember to leave it after running
        -- the installer, and __before__ starting the installer for the next
        -- version
        if true == settings.install.stage then sh.popd() end
    end
else
    log.warn("install.sh does not exist!")
end

--------------------------------------------------------------------------------
-- find installation targets for each version, and possibly relocate
-- installed artifacts to settings.install.destination
--------------------------------------------------------------------------------

local installed_artifacts = find_installed_artifacts(
    subsitutions, settings, {
        config_dir=config_dir
    }
)

-- relocate any installed artifacts (if site.relocate is true)
local installed_versions = {}
if settings.site.relocate then
    -- if relocate = true, then relocate artifacts to the destination directory
    log.info("Relocating artfacts")
    for v, loc in pairs(installed_artifacts) do
        local dest = replace_all(
            settings.install.destination, subsitutions, settings, {
                config_dir=config_dir,
                version=v
            }
        )
        if loc == dest then
            log.warn(f"not relocating {loc} to {dest} (they are the same)")
        elseif gears.realdir(loc) == gears.realdir(dest) then
            log.warn(f"not relocating {loc} to {dest} (they are the same location in the filesystem)")
        else
            log.info(f"Relocating: {loc} to {dest}")
            if gears.file_exists(dest) then
                log.warn(f"{dest} not free => deleting before `mv {loc} {dest}`")
                sh.rm("-r", "-f", dest) -- ensure order => don't use table
            end
            sh.mv(loc, dest)
        end
        -- module files will use the new destination
        installed_versions[v] = dest
    end
else
    -- if relocate = false, then leave artifacts in place. Modulefiles will use
    -- the location as-is
    installed_versions = installed_artifacts
end

-- summarize installed versions
log.info("Instaled the following versions:")
for k,v in pairs(installed_versions) do
    log.info(k, v)
end

-------------------------------------------------------------------------------
-- clean up
-------------------------------------------------------------------------------

local function delete_stage_dir(name, variant, version)
    local dn = stage_dir_name(name, variant, version)
    log.trace(f"Cleaning up: {dn}")
    sh.rm("-r", "-f", dn) -- ensure order => don't use table
end

-- remove staging directory (if post.clean is enabled)
if true == settings.post.clean then
    log.info("Cleaning up staging directories")
    for _, version in pairs(settings.install.versions) do
        delete_stage_dir(settings.site.name, settings.site.variant, version)
    end
    -- Also delete any stage dir used by pre_install.sh
    delete_stage_dir(
        settings.site.name, settings.site.variant, SM_PRE_INSTALL_VERSION
    )
end

-------------------------------------------------------------------------------
-- generate modules
--------------------------------------------------------------------------------

local tmpl = config_dir .. "/module_template.lua"
if not gears.file_exists(tmpl) then
    log.fatal(f"Requested module template {tmpl} does not exist")
    error("Missing configuration file")
end

-- read template file
local template_file = io.open(tmpl, "r")
if nil == template_file then
    log.fatal(f"Failed to load {tmpl}")
    error("Failed to load configuration file")
end
-- we only need to read the template file in once, and re-used it for everything
-- installed version
local template = template_file:read("*all")
template_file:close()

-- iterate over versions and generate module based on template file
log.info("Generating modules ...")

local module_dir = settings.site.modules .. "/" .. settings.site.name
sh.mkdir("-p", module_dir) -- ensure order => don't use table
-- fill in module template for each version
for version, _ in pairs(installed_versions) do
    log.info(f"Generating module for version {version}")

    -- build module parameter file
    local module_params = {}
    for var, val in pairs(settings.module) do
        module_params[var] = replace_all(val, subsitutions, settings, {
                config_dir=config_dir,
                install_dir=installed_versions[version],
                version=version
            }
        )
    end
    -- print for debug purposes
    for k,v in pairs(module_params) do
        log.info(k, v)
    end
    -- generate module file
    local mod = lustache:render(template, module_params)

    local module_path = module_dir .. f"/{version}.lua"
    if nil ~= settings.site.variant then
        module_path = module_dir .. f"/{version}-{settings.site.variant}.lua"
    end
    local module_file = io.open(module_path, "w")
    if nil == module_file then
        log.fatal("Could not create module file")
        error("Install file creation failed.")
    end
    module_file:write(mod)
    module_file:close()

    sh.__verbose = true
    sh.chmod(      "o+rX", module_dir)
    sh.chmod("-R", "o+rX", module_path)
    sh.__verbose = false
end

-------------------------------------------------------------------------------
-- update file permissions
--------------------------------------------------------------------------------

local function check_find_is_gnu()
    log.trace("Checking if GNU find...")

    local find_loc = tostring(sh.which("find"))
    local find_strings = sh.strings(find_loc)
    for s in string.gmatch(tostring(find_strings), "[^\n]+") do
        if s == "GNU findutils" then
            log.trace("GNU find detected")
            return true
        end
    end

    log.trace("GNU find not detected")
    return false
end

log.info("Updating file permissions")

-- find input args are different depending on the BSD or GNU version...
local find_cmd
if check_find_is_gnu() then
    find_cmd = "find . -type f -executable -exec chmod o+x {} \\;"
else
    find_cmd = "find . -type f -perm +111 -exec chmod o+x {} \\;"
end

sh.pushd(settings.site.destination)
sh.__verbose = true

sh.chmod("-R", "o+rX", ".")
-- make all files that are executable by the user executable by everyone
sh.bash("-c", find_cmd)

sh.__verbose = false
sh.popd()

--------------------------------------------------------------------------------
-- DONE! (the end)
--------------------------------------------------------------------------------

log.info(">>> DONE DONE DONE DONE DONE DONE <<<")
