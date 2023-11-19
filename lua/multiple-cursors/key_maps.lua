local M = {}

local virtual_cursors = require("multiple-cursors.virtual_cursors")
local common = require("multiple-cursors.common")

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

-- Is the mode and key in custom_key_maps or override default key maps?
local function is_in_table(t, mode, key)

  if next(t) == nil then
    return false
  end

  for i=1, #t do
    local modes = wrap_in_table(t[i][1])
    local keys = wrap_in_table(t[i][2])

    for j=1, #modes do
      for k=1, #keys do
        if mode == modes[j] and key == keys[k] then
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
  for i=1, #default_key_maps do
    local modes = wrap_in_table(default_key_maps[i][1])
    local keys = wrap_in_table(default_key_maps[i][2])

    for j=1, #modes do
      for k=1, #keys do
        if is_default_key_map_allowed(modes[j], keys[k]) then
          save_existing_key_map(modes[j], keys[k])
        end
      end
    end
  end

  -- Custom key maps
  for i=1, #custom_key_maps do
    local custom_modes = wrap_in_table(custom_key_maps[i][1])
    local custom_keys = wrap_in_table(custom_key_maps[i][2])

    for j=1, #custom_modes do
      for k=1, #custom_keys do
        save_existing_key_map(custom_modes[j], custom_keys[k])
      end
    end
  end

end

-- Restore key maps
function M.restore_existing()

  for i=1, #existing_key_maps do
    local mode = existing_key_maps[i][1]
    local dict = existing_key_maps[i][2]

    vim.fn.mapset(mode, false, dict)
  end

  existing_key_maps = {}

end

-- Function to execute a custom key map
local function custom_function(func)
  -- Call func for the real cursor
  func()

  -- Call func for each virtual cursor and set the virtual cursor position
  virtual_cursors.edit_with_cursor(function(vc)
    func()
    common.set_virtual_cursor_from_cursor(vc)
  end)
end

-- Set any custom key maps
-- This is a separate function because it's also used by the LazyLoad autocmd
function M.set_custom()
  for i=1, #custom_key_maps do
    local custom_modes = wrap_in_table(custom_key_maps[i][1])
    local custom_keys = wrap_in_table(custom_key_maps[i][2])
    local func = custom_key_maps[i][3]

    for j=1, #custom_modes do
      for k=1, #custom_keys do
        vim.keymap.set(custom_modes[j], custom_keys[k], function() custom_function(func) end)
      end
    end
  end
end

-- Set key maps used by this plug-in
function M.set()

  -- Default key maps
  for i=1, #default_key_maps do
    local modes = wrap_in_table(default_key_maps[i][1])
    local keys = wrap_in_table(default_key_maps[i][2])
    local func = default_key_maps[i][3]

    for j=1, #modes do
      for k=1, #keys do
        if is_default_key_map_allowed(modes[j], keys[k]) then
          vim.keymap.set(modes[j], keys[k], func)
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
  for i=1, #default_key_maps do
    local modes = wrap_in_table(default_key_maps[i][1])
    local keys = wrap_in_table(default_key_maps[i][2])

    for j=1, #modes do
      for k=1, #keys do
        if is_default_key_map_allowed(modes[j], keys[k]) then
          vim.keymap.del(modes[j], keys[k])
        end
      end
    end
  end

  -- Custom key maps
  for i=1, #custom_key_maps do
    local custom_modes = wrap_in_table(custom_key_maps[i][1])
    local custom_keys = wrap_in_table(custom_key_maps[i][2])
    local func = custom_key_maps[i][3]

    for j=1, #custom_modes do
      for k=1, #custom_keys do
        vim.keymap.del(custom_modes[j], custom_keys[k])
      end
    end
  end

end

return M
