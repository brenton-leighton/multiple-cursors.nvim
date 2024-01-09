local M = {}

local virtual_cursors = require("multiple-cursors.virtual_cursors")
local common = require("multiple-cursors.common")
local input = require("multiple-cursors.input")

-- A table of key maps
-- mode(s), key(s), function
default_key_maps = {}

-- To disable the default key maps
-- {mode(s), key(s)}
disabled_default_key_maps = {}

-- Custom key maps
-- {mode(s), key(s), function}
custom_key_maps = {}

-- A table to store any existing key maps so that they can be restored
-- mode, dict
local existing_key_maps = {}

function M.setup(_default_key_maps, _disabled_default_key_maps, _custom_key_maps)
  default_key_maps = _default_key_maps
  disabled_default_key_maps = _disabled_default_key_maps
  custom_key_maps = _custom_key_maps
end

function M.has_custom_keys_maps()
  return next(custom_key_maps) ~= nil
end

-- Return x in a table if it isn't already a table
local function wrap_in_table(x)
  if type(x) == "table" then
    return x
  else
    return {x}
  end
end

-- Is the mode and key in custom_key_maps or disabled_default_key_maps?
local function is_in_table(t, mode, key)

  if next(t) == nil then
    return false
  end

  for i=1, #t do
    local t_modes = wrap_in_table(t[i][1])
    local t_keys = wrap_in_table(t[i][2])

    for _, t_mode in ipairs(t_modes) do
      for _, t_key in ipairs(t_keys) do
        if mode == t_mode and key == t_key then
          return true
        end
      end
    end

  end

  return false

end

local function is_default_key_map_allowed(mode, key)
  return (not is_in_table(custom_key_maps, mode, key)) and
      (not is_in_table(disabled_default_key_maps, mode, key))
end

-- Save a single key map
local function save_existing_key_map(mode, key)

  local dict = vim.fn.maparg(key, mode, false, true)

  -- If the there's a key map
  if dict["buffer"] ~= nil then
    -- Add to existing_key_maps
    table.insert(existing_key_maps, {mode, dict})
  end

end

-- Save any existing key maps
function M.save_existing()

  -- Default key maps
  for _, default_key_map in ipairs(default_key_maps) do
    local modes = wrap_in_table(default_key_map[1])
    local keys = wrap_in_table(default_key_map[2])

    for _, mode in ipairs(modes) do
      for _, key in ipairs(keys) do
        if is_default_key_map_allowed(mode, key) then
          save_existing_key_map(mode, key)
        end
      end
    end
  end

  -- Custom key maps
  for _, custom_key_map in ipairs(custom_key_maps) do
    local custom_modes = wrap_in_table(custom_key_map[1])
    local custom_keys = wrap_in_table(custom_key_map[2])

    for _, custom_mode in ipairs(custom_modes) do
      for _, custom_key in ipairs(custom_keys) do
        save_existing_key_map(custom_mode, custom_key)
      end
    end
  end

end

-- Restore key maps
function M.restore_existing()

  for _, existing_key_map in ipairs(existing_key_maps) do
    local mode = existing_key_map[1]
    local dict = existing_key_map[2]

    vim.fn.mapset(mode, false, dict)
  end

  existing_key_maps = {}

end

-- Function to execute a custom key map
local function custom_function(func)

  -- Save register and count because they may be lost
  local register = vim.v.register
  local count = vim.v.count

  -- Call func for the real cursor
  func(register, count)

  -- Call func for each virtual cursor and set the virtual cursor position
  virtual_cursors.edit_with_cursor(function(vc)
    func(register, count)
    vc:save_cursor_position()
  end)
end

local function custom_function_with_motion(func)

  -- Save register and count because they may be lost
  local register = vim.v.register
  local count = vim.v.count

  -- Get a motion command
  local motion_cmd = input.get_motion_cmd()

  if motion_cmd == nil then
    return
  end

  -- Call func for the real cursor
  func(register, count, motion_cmd)

  -- Call func for each virtual cursor and set the virtual cursor position
  virtual_cursors.edit_with_cursor(function(vc)
    func(register, count, motion_cmd)
    vc:save_cursor_position()
  end)

end

local function custom_function_with_char(func)

  -- Save register and count because they may be lost
  local register = vim.v.register
  local count = vim.v.count

  -- Get a printable character
  local char = input.get_char()

  if char == nil then
    return
  end

  -- Call func for the real cursor
  func(register, count, char)

  -- Call func for each virtual cursor and set the virtual cursor position
  virtual_cursors.edit_with_cursor(function(vc)
    func(register, count, char)
    vc:save_cursor_position()
  end)

end

local function custom_function_with_motion_then_char(func)

  -- Save register and count because they may be lost
  local register = vim.v.register
  local count = vim.v.count

  -- Get a motion command
  local motion_cmd = input.get_motion_cmd()

  if motion_cmd == nil then
    return
  end

  -- Get a printable character
  local char = input.get_char()

  if char == nil then
    return
  end

  -- Call func for the real cursor
  func(register, count, motion_cmd, char)

  -- Call func for each virtual cursor and set the virtual cursor position
  virtual_cursors.edit_with_cursor(function(vc)
    func(register, count, motion_cmd, char)
    vc:save_cursor_position()
  end)

end

-- Set any custom key maps
-- This is a separate function because it's also used by the LazyLoad autocmd
function M.set_custom()

  for _, custom_key_map in ipairs(custom_key_maps) do

    local custom_modes = wrap_in_table(custom_key_map[1])
    local custom_keys = wrap_in_table(custom_key_map[2])
    local func = custom_key_map[3]

    local wrapped_func = function() custom_function(func) end

    -- Change wrapped_func if there's a valid option
    if #custom_key_map >= 4 then
      local opt = custom_key_map[4]

      if opt == "m" then -- Motion character
        wrapped_func = function() custom_function_with_motion(func) end
      elseif opt == "c" then -- Standard character
        wrapped_func = function() custom_function_with_char(func) end
      elseif opt == "mc" then -- Standard character
        wrapped_func = function() custom_function_with_motion_then_char(func) end
      end
    end

    for j=1, #custom_modes do
      for k=1, #custom_keys do
        vim.keymap.set(custom_modes[j], custom_keys[k], wrapped_func)
      end
    end

  end -- for each custom key map

end

-- Set key maps used by this plug-in
function M.set()

  -- Default key maps
  for _, default_key_map in ipairs(default_key_maps) do
    local modes = wrap_in_table(default_key_map[1])
    local keys = wrap_in_table(default_key_map[2])
    local func = default_key_map[3]

    for _, mode in ipairs(modes) do
      for _, key in ipairs(keys) do
        if is_default_key_map_allowed(mode, key) then
          vim.keymap.set(mode, key, func)
        end
      end
    end
  end

  -- Custom key maps
  M.set_custom()

end

-- Delete key maps used by this plug-in
function M.delete()

  -- Default key maps
  for _, default_key_map in ipairs(default_key_maps) do
    local modes = wrap_in_table(default_key_map[1])
    local keys = wrap_in_table(default_key_map[2])

    for _, mode in ipairs(modes) do
      for _, key in ipairs(keys) do
        if is_default_key_map_allowed(mode, key) then
          vim.keymap.del(mode, key)
        end
      end
    end
  end

  -- Custom key maps
  for _, custom_key_map in ipairs(custom_key_maps) do
    local custom_modes = wrap_in_table(custom_key_map[1])
    local custom_keys = wrap_in_table(custom_key_map[2])
    local func = custom_key_map[3]

    for _, custom_mode in ipairs(custom_modes) do
      for _, custom_key in ipairs(custom_keys) do
        vim.keymap.del(custom_mode, custom_key)
      end
    end
  end

end

return M
