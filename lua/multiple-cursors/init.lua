local M = {}

local key_maps = require("multiple-cursors.key_maps")
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

default_key_maps = {
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
  {{"n", "i", "x"}, "<Esc>", function() M.escape() end},
}

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
    if key_maps.has_custom_keys_maps() then
      vim.api.nvim_create_autocmd({"User"}, {
        group = autocmd_group_id,
        pattern = "LazyLoad",
        callback = key_maps.set_custom,
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
    key_maps.save_existing()
    key_maps.set()
    create_autocmds()
    override_paste_handler()

    initialised = true
  end
end

-- Deinitialise
local function deinit()
  if initialised then
    virtual_cursors.clear()
    key_maps.delete()
    key_maps.restore_existing()
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

  -- Options
  opts = opts or {}

  enable_split_paste = opts.enable_split_paste or true
  local disabled_default_key_maps = opts.disabled_default_key_maps or {}
  local custom_key_maps = opts.custom_key_maps or {}

  -- Set up extmarks
  extmarks.setup()

  -- Set up key maps
  key_maps.setup(default_key_maps, disabled_default_key_maps, custom_key_maps)

  -- Autocmds
  autocmd_group_id = vim.api.nvim_create_augroup("MultipleCursors", {})

  vim.api.nvim_create_user_command("MultipleCursorsAddDown", M.add_cursor_down, {})
  vim.api.nvim_create_user_command("MultipleCursorsAddUp", M.add_cursor_up, {})
  vim.api.nvim_create_user_command("MultipleCursorsMouseAddDelete", M.mouse_add_delete_cursor, {})

end

return M
