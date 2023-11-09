local M = {}

local common = require("multiple-cursors.common")
local extmarks = require("multiple-cursors.extmarks")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local move = require("multiple-cursors.move")
local move_special = require("multiple-cursors.move_special")
local normal_edit = require("multiple-cursors.normal_edit")
local normal_to_insert = require("multiple-cursors.normal_to_insert")
local insert_mode = require("multiple-cursors.insert_mode")
local visual_mode = require("multiple-cursors.visual_mode")

local initialised = false
local autocmd_group_id = nil
local original_paste_function = nil

local enable_split_paste = true

-- A table of key maps
-- mode(s), key(s), function
local key_maps = {

  -- Left/right motion in normal/visual modes
  {{"n", "x"}, {"h", "<Left>"}, move.normal_h},
  {{"n", "x"}, "<BS>", move_special.normal_bs},
  {{"n", "x"}, {"l", "<Right>", "<Space>"}, move_special.normal_l},
  {{"n", "x"}, "0", move.normal_0},
  {{"n", "x"}, "^", move.normal_caret},
  {{"n", "x"}, "$", move_special.normal_dollar},
  {{"n", "x"}, "|", move.normal_bar},

  -- Left/right motion in insert/replace modes
  {"i", "<Left>", move.insert_left},
  {"i", "<Right>", move_special.insert_right},

  -- Left/right motion in all modes
  {{"n", "i", "x"}, "<Home>", move.home},
  {{"n", "i", "x"}, "<End>", move_special.eol},

  -- Up/down motion in normal/visual modes
  {{"n", "x"}, {"j", "<Down>"}, move_special.normal_j},
  {{"n", "x"}, {"k", "<Up>"}, move_special.normal_k},
  {{"n", "x"}, "-", move_special.normal_minus},
  {{"n", "x"}, {"+", "<CR>", "<kEnter>"}, move_special.normal_plus},
  {{"n", "x"}, "_", move_special.normal_underscore},

  -- Up/down motion in insert/replace modes
  {"i", "<Up>", move_special.insert_up},
  {"i", "<Down>", move_special.insert_down},

  -- Text object motion in normal/visual modes
  {{"n", "x"}, {"w", "<S-Right>", "<C-Right>"}, move.normal_w},
  {{"n", "x"}, "W", move.normal_W},
  {{"n", "x"}, "e", move.normal_e},
  {{"n", "x"}, "E", move.normal_E},
  {{"n", "x"}, {"b", "<S-Left>", "<C-Left>"}, move.normal_b},
  {{"n", "x"}, "B", move.normal_B},

  -- Text object motion in insert/replace modes
  {"i", "<C-Left>", move.insert_word_left},
  {"i", "<C-Right>", move.insert_word_right},

  -- Various motions in normal/visual modes
  {{"n", "x"}, "%", move.normal_percent},

  -- Inserting text (from normal mode)
  {"n", "a", normal_to_insert.a},
  {"n", "A", normal_to_insert.A},
  {"n", "I", normal_to_insert.I},
  {"n", "o", normal_to_insert.o},
  {"n", "O", normal_to_insert.O},

  -- Delete in normal mode
  {"n", {"x", "<Del>"}, normal_edit.x},
  {"n", "X", normal_edit.X},
  {"n", "dd", normal_edit.dd},
  {"n", "D", normal_edit.D},

  -- Yank and put in normal mode
  {"n", "yy", normal_edit.yy},
  {"n", "p", normal_edit.p},
  {"n", "P", normal_edit.P},

  -- Indentation in normal mode
  {"n", ">>", normal_edit.indent},
  {"n", "<<", normal_edit.deindent},

  -- Insert mode
  {"i", "<BS>", insert_mode.bs},
  {"i", "<Del>", insert_mode.del},
  {"i", {"<CR>", "<kEnter>"}, insert_mode.cr},
  {"i", "<Tab>", insert_mode.tab},

  -- Visual mode
  {"x", "o", visual_mode.o},
  {"x", "y", visual_mode.y},
  {"x", "d", visual_mode.d},

  -- Escape in all modes
  {{"n", "i", "x"}, "<Esc>", function() return M.escape() end},
}

-- Custom key maps
-- mode(s), key(s), function
local custom_key_maps = {}

-- A table to store any existing key maps so that they can be restored afterwards
-- mode, dict
local existing_key_maps = {}

local disabled_default_key_maps = {}

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
local function save_existing_key_maps()

  -- Standard key maps
  for i=1, #key_maps do
    local modes = wrap_in_table(key_maps[i][1])
    local keys = wrap_in_table(key_maps[i][2])

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

-- Restore existing key maps
local function restore_existing_key_maps()

  for i=1, #existing_key_maps do
    local mode = existing_key_maps[i][1]
    local dict = existing_key_maps[i][2]

    vim.fn.mapset(mode, false, dict)
  end

end

-- Set any custom key maps
-- This is a separate function because it's also used by the LazyLoad autocmd
local function set_custom_key_maps()
  for i=1, #custom_key_maps do
    local custom_modes = wrap_in_table(custom_key_maps[i][1])
    local custom_keys = wrap_in_table(custom_key_maps[i][2])
    local func = custom_key_maps[i][3]

    for j=1, #custom_modes do
      for k=1, #custom_keys do
        vim.keymap.set(custom_modes[j], custom_keys[k], function() normal_edit.custom_function(func) end)
      end
    end
  end
end

-- Set key maps used by this plug-in
local function set_key_maps()

  -- Standard key maps
  for i=1, #key_maps do
    local modes = wrap_in_table(key_maps[i][1])
    local keys = wrap_in_table(key_maps[i][2])
    local func = key_maps[i][3]

    for j=1, #modes do
      for k=1, #keys do
        if is_default_key_map_allowed(modes[j], keys[k]) then
          vim.keymap.set(modes[j], keys[k], func)
        end
      end
    end
  end

  -- Custom key maps
  set_custom_key_maps()

end

-- Delete key maps used by this plug-in
local function delete_key_maps()

  -- Standard key maps
  for i=1, #key_maps do
    local modes = wrap_in_table(key_maps[i][1])
    local keys = wrap_in_table(key_maps[i][2])

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

-- Create autocmds used by this plug-in
local function create_autocmds()

  -- Monitor cursor movement to check for virtual cursors colliding with the real cursor
    vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"},
      { group = autocmd_group_id, callback = virtual_cursors.cursor_moved }
    )

    -- Insert characters
    vim.api.nvim_create_autocmd({"InsertCharPre"},
      { group = autocmd_group_id, callback = insert_mode.insert_char_pre }
    )

    vim.api.nvim_create_autocmd({"TextChangedI"},
      { group = autocmd_group_id, callback = insert_mode.text_changed_i }
    )

    -- Mode changed from normal to insert
    vim.api.nvim_create_autocmd({"ModeChanged"}, {
      group = autocmd_group_id,
      pattern = "n:i",
      callback = normal_to_insert.mode_changed,
    })

    -- Mode changed from any to visual
    vim.api.nvim_create_autocmd({"ModeChanged"}, {
      group = autocmd_group_id,
      pattern = "*:v",
      callback = virtual_cursors.mode_changed_to_visual,
    })

    -- Mode changed from visual to any
    vim.api.nvim_create_autocmd({"ModeChanged"}, {
      group = autocmd_group_id,
      pattern = "v:*",
      callback = virtual_cursors.mode_changed_from_visual,
    })

    -- If there are custom key maps, reset the custom key maps on the LazyLoad
    -- event (when a plugin has been loaded)
    -- This is to fix an issue with using a command from a plugin that was lazy
    -- loaded while multi-cursors is active
    if next(custom_key_maps) ~= nil then
      vim.api.nvim_create_autocmd({"User"}, {
        group = autocmd_group_id,
        pattern = "LazyLoad",
        callback = set_custom_key_maps,
      })
    end

end

-- Override the paste handler
local function override_paste_handler()
  original_paste_function = vim.paste

  vim.paste = (function(overridden)
      return function(lines, phase)
        if enable_split_paste and
            #lines == virtual_cursors.get_num_editable_cursors() + 1 then
          local line = insert_mode.split_paste(lines)
          return overridden({line}, phase)
        else
          insert_mode.paste(lines)
          return overridden(lines, phase)
        end
      end
  end)(vim.paste)
end

-- Initialise
local function init()
  if not initialised then
    save_existing_key_maps()
    set_key_maps()
    create_autocmds()
    override_paste_handler()

    initialised = true
  end
end

-- Deinitialise
local function deinit()
  if initialised then
    virtual_cursors.clear()
    delete_key_maps()
    restore_existing_key_maps()
    vim.api.nvim_clear_autocmds({group = autocmd_group_id}) -- Clear autocmds
    vim.paste = original_paste_function -- Revert the paste handler

    initialised = false
  end
end

-- Escape key
function M.escape()
  if common.is_mode("n") then
    deinit()
  elseif common.is_mode_insert_replace() then
    insert_mode.escape()
  elseif common.is_mode("v") then
    visual_mode.escape()
  end

  common.feedkeys("<Esc>", 0)
end

-- Add a virtual cursor then move the real cursor up or down
local function add_cursor(down)
  -- Initialise if this is the first cursor
  init()

  -- Add virtual cursor at the real cursor position
  local pos = vim.fn.getcursorcharpos()
  virtual_cursors.add(pos[2], pos[3], pos[5])

  -- Move the real cursor
  if down then
    common.feedkeys("<Down>", vim.v.count)
  else
    common.feedkeys("<Up>", vim.v.count)
  end

end

function M.add_cursor_up() return add_cursor(false) end
function M.add_cursor_down() return add_cursor(true) end

-- Add or delete a virtual cursor at the mouse position
function M.mouse_add_delete_cursor()
  init() -- Initialise if this is the first cursor

  local mouse_pos = vim.fn.getmousepos()

  -- Add a virtual cursor to the mouse click position, or delete an existing one
  virtual_cursors.add_or_delete(mouse_pos.line, mouse_pos.column)

  if virtual_cursors.get_num_virtual_cursors() == 0 then
    deinit() -- Deinitialise if there are no more cursors
  end
end

function M.setup(opts)

  opts = opts or {}

  if opts.enable_split_paste ~= nil then
    enable_split_paste = opts.enable_split_paste
  end

  if opts.disabled_default_key_maps ~= nil then
    disabled_default_key_maps = opts.disabled_default_key_maps
  end

  if opts.custom_key_maps ~= nil then
    custom_key_maps = opts.custom_key_maps
  end

  extmarks.setup()

  autocmd_group_id = vim.api.nvim_create_augroup("MultipleCursors", {})

  -- Create commands
  vim.api.nvim_create_user_command("MultipleCursorsAddDown", M.add_cursor_down, {})
  vim.api.nvim_create_user_command("MultipleCursorsAddUp", M.add_cursor_up, {})
  vim.api.nvim_create_user_command("MultipleCursorsMouseAddDelete", M.mouse_add_delete_cursor, {})

end

return M
