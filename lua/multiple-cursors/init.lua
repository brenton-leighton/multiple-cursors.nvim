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
local buf_enter_autocmd_id = nil

local pre_hook = nil
local post_hook = nil

local bufnr = nil

local match_visiable_only = nil
local saved_pattern = nil

default_key_maps = {
  -- Up/down motion in normal/visual modes
  {{"n", "x"}, {"j", "<Down>"}, move.normal_j},
  {{"n", "x"}, {"k", "<Up>"}, move.normal_k},
  {{"n", "x"}, "-", move.normal_minus},
  {{"n", "x"}, {"+", "<CR>", "<kEnter>"}, move.normal_plus},
  {{"n", "x"}, "_", move.normal_underscore},

  -- Up/down motion in insert/replace modes
  {"i", "<Up>", move.insert_up},
  {"i", "<Down>", move.insert_down},

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

  -- v in visual mode is also escape
  {"x", "v", function() M.escape() end},
}

local function buf_delete()
  M.deinit(true)
end

local function buf_leave()
  -- Deinitialise without clearing virtual cursors
  M.deinit(false)
end

local function buf_enter()
  -- Returning to buffer with multiple cursors
  if vim.fn.bufnr() == bufnr then
    M.init()
    virtual_cursors.update_extmarks()
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

    vim.api.nvim_create_autocmd({"BufLeave"},
      { group = autocmd_group_id, callback = buf_leave }
    )

    vim.api.nvim_create_autocmd({"BufDelete"},
      { group = autocmd_group_id, callback = buf_delete }
    )

end

-- Initialise
function M.init()
  if not initialised then

    if pre_hook then pre_hook() end

    key_maps.save_existing()
    key_maps.set()

    create_autocmds()

    paste.override_handler()

    -- Initialising in a new buffer
    if not bufnr or vim.fn.bufnr() ~= bufnr then
      extmarks.clear()
      virtual_cursors.clear()
      bufnr = vim.fn.bufnr()
      buf_enter_autocmd_id = vim.api.nvim_create_autocmd({"BufEnter"}, {callback=buf_enter})
    end

    initialised = true
  end
end

-- Deinitialise
function M.deinit(clear_virtual_cursors)
  if initialised then

    if clear_virtual_cursors then

      -- Restore cursor to the position of the oldest virtual cursor
      local pos = virtual_cursors.get_exit_pos()

      if pos then
        vim.fn.cursor({pos[1], pos[2], 0, pos[3]})
      end

      virtual_cursors.clear()
      bufnr = nil
      saved_pattern = nil
      vim.api.nvim_del_autocmd(buf_enter_autocmd_id)
      buf_enter_autocmd_id = nil
    end

    extmarks.clear()

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
  M.deinit(true)
  common.feedkeys(nil, vim.v.count, "u", nil)
end

-- Escape key
function M.escape()
  if common.is_mode("n") then
    M.deinit(true)
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
  M.init()

  -- If visual mode
  if common.is_mode("v") then

    -- Add count1 virtual cursors
    local count1 = vim.v.count1

    for i = 1, count1 do
      -- Get the current visual area
      local v_lnum, v_col, lnum, col, curswant = common.get_visual_area()

      -- Add a virtual cursor with the visual area
      virtual_cursors.add_with_visual_area(lnum, col, curswant, v_lnum, v_col, true)

      -- Move the real cursor visual area
      if down then
        common.set_visual_area(v_lnum + 1, v_col, lnum + 1, col)
      else
        common.set_visual_area(v_lnum - 1, v_col, lnum - 1, col)
      end
    end

  elseif common.is_mode("n") then  -- If normal mode

    -- Add count1 virtual cursors
    for i = 1, vim.v.count1 do
      -- Add virtual cursor at the real cursor position
      local pos = vim.fn.getcurpos()
      virtual_cursors.add(pos[2], pos[3], pos[5], true)

      -- Move the real cursor
      if down then
        vim.cmd("normal! j")
      else
        vim.cmd("normal! k")
      end
    end

  else -- Insert or replace mode

    -- Add one virtual cursor at the real cursor position
    local pos = vim.fn.getcurpos()
    virtual_cursors.add(pos[2], pos[3], pos[5], true)

    -- Move the real cursor
    if down then
      common.feedkeys(nil, 0, "<Down>", nil)
    else
      common.feedkeys(nil, 0, "<Up>", nil)
    end

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
  M.init() -- Initialise if this is the first cursor

  local mouse_pos = vim.fn.getmousepos()

  -- Add a virtual cursor to the mouse click position, or delete an existing one
  virtual_cursors.add_or_delete(mouse_pos.line, mouse_pos.column)

  if virtual_cursors.get_num_virtual_cursors() == 0 then
    M.deinit(true) -- Deinitialise if there are no more cursors
  end
end

local function get_visual_area_text()

  local lnum1, col1, lnum2, col2 = common.get_normalised_visual_area()

  if lnum1 ~= lnum2 then
    vim.print("Search pattern must be a single line")
    return nil
  end

  local line = vim.fn.getline(lnum1)
  return line:sub(col1, col2)

end

-- Get a search pattern
-- In normal mode, returns cword or saved_pattern if use_saved_pattern is true and saved_pattern is
-- valid
-- In visual mode, returns the visual area and also saves it to saved_pattern if use_saved_pattern
-- is true
local function get_search_pattern(use_saved_pattern)

  local pattern = nil

  if common.is_mode("v") then
    pattern = get_visual_area_text()
    if use_saved_pattern then
      saved_pattern = pattern
    end
  else -- Normal mode
    if use_saved_pattern and saved_pattern then
      pattern = saved_pattern
    else
      -- Use the word under the cursor
      pattern = vim.fn.expand("<cword>")
    end
  end

  if pattern == "" then
    return nil
  else
    return pattern
  end

end

-- Add cursors by searching for the word under the cursor or visual area
local function _add_cursors_to_matches(use_prev_visual_area)

  -- Save data to restore visual area
  local v = common.is_mode("v")
  local v_lnum, v_col, lnum, col = 0
  local length = 0

  if v then
    v_lnum, v_col, lnum, col = common.get_normalised_visual_area()
    length = col - v_col
  end

  -- Get the search pattern: either the cursor under the word in normal mode or the visual area in
  -- visual mode
  local pattern = get_search_pattern(false)

  if pattern == nil then
    return
  end

  -- Find matches (without the one for the cursor) and move the cursor to its match
  local matches = search.get_matches_and_move_cursor(pattern, match_visible_only, use_prev_visual_area)

  if matches == nil then
    return
  end

  -- Initialise if not already initialised
  M.init()

  -- Create a virtual cursor at every match
  for _, match in ipairs(matches) do
    if not v then
     -- Normal mode
      virtual_cursors.add(match[1], match[2], match[2], false)
    else
      -- Visual mode
      virtual_cursors.add_with_visual_area(match[1], match[2] + length, match[2] + length, match[1], match[2], false)
    end
  end

  vim.print(#matches .. " cursors added")

  -- Restore visual area
  if v then
    common.set_visual_area(v_lnum, v_col, lnum, col)
  end

end

-- Add cursors to each match of cword or visual area
function M.add_cursors_to_matches() _add_cursors_to_matches(false) end

-- Add cursors to each match of cword or visual area, but only within the previous visual area
function M.add_cursors_to_matches_v() _add_cursors_to_matches(true) end

-- Add a virtual cursor to the start of the word under the cursor (or visual area), then move the
-- cursor to to the next match
function M.add_cursor_and_jump_to_next_match()

  -- Get the search pattern
  local pattern = get_search_pattern(true)

  -- Exit visual mode
  if common.is_mode("v") then
    vim.cmd("normal!:")
  end

  -- Get a match without moving the cursor if there are already virtual cursors
  local match = search.get_next_match(pattern, not initialised)

  if match == nil then
    return
  end

  -- Initialise if not already initialised
  M.init()

  -- Add virtual cursor to cursor position
  local pos = vim.fn.getcurpos()
  virtual_cursors.add(pos[2], pos[3], pos[5], true)

  -- Move cursor to match
  vim.fn.cursor({match[1], match[2], 0, match[2]})

end

-- Move the cursor to the next match of the word under the cursor (or saved visual area, if any)
function M.jump_to_next_match()

  -- Get the search pattern
  local pattern = get_search_pattern(true)

  -- Get a match without moving the cursor
  local match = search.get_next_match(pattern, false)

  if match == nil then
    return
  end

  -- Move cursor to match
  vim.fn.cursor({match[1], match[2], 0, match[2]})

end

-- Add a new cursor at given position
function M.add_cursor(lnum, col, curswant)

  -- Initialise if this is the first cursor
  M.init()

  -- Add a virtual cursor
  virtual_cursors.add(lnum, col, curswant, false)

end

-- Toggle locking the virtual cursors if initialised
function M.lock()
  if initialised then
    virtual_cursors.toggle_lock()
  end
end

function M.setup(opts)

  -- Options
  opts = opts or {}

  local custom_key_maps = opts.custom_key_maps or {}

  local enable_split_paste = opts.enable_split_paste or true

  match_visible_only = opts.match_visible_only or true

  pre_hook = opts.pre_hook or nil
  post_hook = opts.post_hook or nil

  -- Set up extmarks
  extmarks.setup()

  -- Set up key maps
  key_maps.setup(default_key_maps, custom_key_maps)

  -- Set up paste
  paste.setup(enable_split_paste)

  -- Autocmds
  autocmd_group_id = vim.api.nvim_create_augroup("MultipleCursors", {})

  vim.api.nvim_create_user_command("MultipleCursorsAddDown", M.add_cursor_down, {})
  vim.api.nvim_create_user_command("MultipleCursorsAddUp", M.add_cursor_up, {})

  vim.api.nvim_create_user_command("MultipleCursorsMouseAddDelete", M.mouse_add_delete_cursor, {})

  vim.api.nvim_create_user_command("MultipleCursorsAddMatches", M.add_cursors_to_matches, {})
  vim.api.nvim_create_user_command("MultipleCursorsAddMatchesV", M.add_cursors_to_matches_v, {})

  vim.api.nvim_create_user_command("MultipleCursorsAddJumpNextMatch", M.add_cursor_and_jump_to_next_match, {})
  vim.api.nvim_create_user_command("MultipleCursorsJumpNextMatch", M.jump_to_next_match, {})

  vim.api.nvim_create_user_command("MultipleCursorsLock", M.lock, {})
end

return M
