local M = {}

local key_maps = require("multiple-cursors.key_maps")
local common = require("multiple-cursors.common")
local extmarks = require("multiple-cursors.extmarks")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local move = require("multiple-cursors.move")
local move_special = require("multiple-cursors.move_special")
local normal_edit = require("multiple-cursors.normal_edit")
local normal_mode_change = require("multiple-cursors.normal_mode_change")
local insert_mode = require("multiple-cursors.insert_mode")
local visual_mode = require("multiple-cursors.visual_mode")
local paste = require("multiple-cursors.paste")
local search = require("multiple-cursors.search")

local initialised = false
local autocmd_group_id = nil

local pre_hook = nil
local post_hook = nil

default_key_maps = {
  -- Left/right motion in normal/visual modes
  {{"n", "x"}, {"h", "<Left>"}, move.normal_h},
  {{"n", "x"}, "<BS>", move_special.normal_bs},
  {{"n", "x"}, {"l", "<Right>", "<Space>"}, move.normal_l},
  {{"n", "x"}, "0", move.normal_0},
  {{"n", "x"}, "^", move.normal_caret},
  {{"n", "x"}, "$", move.normal_dollar},
  {{"n", "x"}, "|", move.normal_bar},
  {{"n", "x"}, "f", move.normal_f},
  {{"n", "x"}, "F", move.normal_F},
  {{"n", "x"}, "t", move.normal_t},
  {{"n", "x"}, "T", move.normal_T},

  -- Left/right motion in insert/replace modes
  {"i", "<Left>", move.insert_left},
  {"i", "<Right>", move.insert_right},

  -- Left/right motion in all modes
  {{"n", "i", "x"}, "<Home>", move.home},
  {{"n", "i", "x"}, "<End>", move.eol},

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
  {{"n", "x"}, "ge", move.normal_ge},
  {{"n", "x"}, "gE", move.normal_gE},

  -- Text object motion in insert/replace modes
  {"i", "<C-Left>", move.insert_word_left},
  {"i", "<C-Right>", move.insert_word_right},

  -- Various motions in normal/visual modes
  {{"n", "x"}, "%", move.normal_percent},

  -- Inserting text (from normal mode)
  {"n", "a", normal_mode_change.a},
  {"n", "A", normal_mode_change.A},
  {"n", {"i", "<Insert>"}, normal_mode_change.i},
  {"n", "I", normal_mode_change.I},
  {"n", "o", normal_mode_change.o},
  {"n", "O", normal_mode_change.O},

  -- Delete in normal mode
  {"n", {"x", "<Del>"}, normal_edit.x},
  {"n", "X", normal_edit.X},
  {"n", "d", normal_edit.d},
  {"n", "dd", normal_edit.dd},
  {"n", "D", normal_edit.D},

  -- Change in normal mode
  {"n", "c", normal_mode_change.c},
  {"n", "cc", normal_mode_change.cc},
  {"n", "C", normal_mode_change.C},
  {"n", "s", normal_mode_change.s},

  -- Change case in normal mode
  {"n", "gu", normal_edit.gu},
  {"n", "gU", normal_edit.gU},
  {"n", "g~", normal_edit.g_tilde},

  -- Yank and put in normal mode
  {"n", "y", normal_edit.y},
  {"n", "yy", normal_edit.yy},
  {"n", "p", normal_edit.p},
  {"n", "P", normal_edit.P},

  -- Replace char in normal mode
  {"n", "r", normal_edit.r},

  -- Indentation in normal mode
  {"n", ">>", normal_edit.indent},
  {"n", "<<", normal_edit.deindent},

  -- Join lines in normal mode
  {"n", "J", normal_edit.J},
  {"n", "gJ", normal_edit.gJ},

  -- Insert mode
  {"i", "<BS>", insert_mode.bs},
  {"i", "<Del>", insert_mode.del},
  {"i", {"<CR>", "<kEnter>"}, insert_mode.cr},
  {"i", "<Tab>", insert_mode.tab},

  -- Visual mode
  {"n", "v", normal_mode_change.v},
  {"x", "o", visual_mode.o},

  -- Modify visual area
  {"x", "a", visual_mode.a},
  {"x", "i", visual_mode.i},

  -- Join lines in visual mode
  {"x", "J", visual_mode.J},
  {"x", "gJ", visual_mode.gJ},

  -- Indentation in visual mode
  {"x", "<", visual_mode.less_than},
  {"x", ">", visual_mode.greater_than},

  -- Change case in visual mode
  {"x", "~", visual_mode.tilde},
  {"x", "u", visual_mode.u},
  {"x", "U", visual_mode.U},
  {"x", "g~", visual_mode.g_tilde},
  {"x", "gu", visual_mode.gu},
  {"x", "gU", visual_mode.gU},

  -- Yank and delete in visual mode
  {"x", "y", visual_mode.y},
  {"x", {"d", "<Del>"}, visual_mode.d},
  {"x", "c", visual_mode.c},

  -- Undo in normal mode
  {"n", "u", function() M.undo() end},

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

    -- Mode changed from normal to insert or visual
    vim.api.nvim_create_autocmd({"ModeChanged"}, {
      group = autocmd_group_id,
      pattern = "n:{i,v}",
      callback = normal_mode_change.mode_changed,
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

-- Initialise
local function init()
  if not initialised then
    if pre_hook then pre_hook() end
    key_maps.save_existing()
    key_maps.set()
    create_autocmds()
    paste.override_handler()

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
    paste.revert_handler()
    if post_hook then post_hook() end

    initialised = false
  end
end

-- Normal mode undo will exit because cursor positions can't be restored
function M.undo()
  deinit()
  common.feedkeys(nil, vim.v.count, "u", nil)
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

  common.feedkeys(nil, 0, "<Esc>", nil)
end

-- Add a virtual cursor then move the real cursor up or down
local function add_virtual_cursor_at_real_cursor(down)
  -- Initialise if this is the first cursor
  init()

  -- Add virtual cursor at the real cursor position
  local pos = vim.fn.getcurpos()
  virtual_cursors.add(pos[2], pos[3], pos[5])

  -- Move the real cursor
  if down then
    common.feedkeys(nil, vim.v.count, "<Down>", nil)
  else
    common.feedkeys(nil, vim.v.count, "<Up>", nil)
  end

end

-- Add a virtual cursor at the real cursor position, then move the real cursor up
function M.add_cursor_up()
  return add_virtual_cursor_at_real_cursor(false)
end

-- Add a virtual cursor at the real cursor position, then move the real cursor down
function M.add_cursor_down()
  return add_virtual_cursor_at_real_cursor(true)
end

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

-- Add a new cursor at given position
function M.add_cursor(lnum, col, curswant)

  -- Initialise if this is the first cursor
  init()

  -- Add a virtual cursor
  virtual_cursors.add(lnum, col, curswant)

end

-- Add cursors to each instance of the word under the real cursor
function M.add_cursors_to_word_under_cursor()

  -- If visual mode
  if common.is_mode("v") then
    -- Just exit visual mode and save the area
    vim.cmd("normal!:")
    search.save_previous_visual_area()
    return
  end

  local word = vim.fn.expand("<cword>")

  -- No word under cursor
  if word == "" then
    return
  end

  -- Find matches (without the one for the cursor) and move the cursor to its match
  local matches = search.get_matches_and_move_cursor(word)

  if matches == nil then
    return
  end

  -- Initialise if not already initialised
  init()

  -- Clear any existing cursors
  virtual_cursors.clear()

  -- Create a virtual cursor at every match
  for idx = 1, #matches do
    local match = matches[idx]
    virtual_cursors.add(match[1], match[2], match[2])
  end

  vim.print(#matches .. " cursors added")

end

function M.setup(opts)

  -- Options
  opts = opts or {}

  local disabled_default_key_maps = opts.disabled_default_key_maps or {}
  local custom_key_maps = opts.custom_key_maps or {}

  local enable_split_paste = opts.enable_split_paste or true

  local match_visible_only = opts.match_visible_only or true

  pre_hook = opts.pre_hook or nil
  post_hook = opts.post_hook or nil

  -- Set up extmarks
  extmarks.setup()

  -- Set up key maps
  key_maps.setup(default_key_maps, disabled_default_key_maps, custom_key_maps)

  -- Set up paste
  paste.setup(enable_split_paste)

  -- Set up search
  search.setup(match_visible_only)

  -- Autocmds
  autocmd_group_id = vim.api.nvim_create_augroup("MultipleCursors", {})

  vim.api.nvim_create_user_command("MultipleCursorsAddDown", M.add_cursor_down, {})
  vim.api.nvim_create_user_command("MultipleCursorsAddUp", M.add_cursor_up, {})
  vim.api.nvim_create_user_command("MultipleCursorsMouseAddDelete", M.mouse_add_delete_cursor, {})
  vim.api.nvim_create_user_command("MultipleCursorsAddToWordUnderCursor", M.add_cursors_to_word_under_cursor, {})

end

return M
