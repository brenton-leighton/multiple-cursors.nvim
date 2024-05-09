local M = {}

local key_maps = require("multiple-cursors.key_maps")
local common = require("multiple-cursors.common")
local extmarks = require("multiple-cursors.extmarks")
local virtual_cursors = require("multiple-cursors.virtual_cursors")

local move = require("multiple-cursors.move")
local move_special = require("multiple-cursors.move_special")
local normal_edit = require("multiple-cursors.normal_edit")
local normal_mode_change = require("multiple-cursors.normal_mode_change")

local insert_mode_motion = require("multiple-cursors.insert_mode.motion")
local insert_mode_character = require("multiple-cursors.insert_mode.character")
local insert_mode_nonprinting = require("multiple-cursors.insert_mode.nonprinting")
local insert_mode_completion = require("multiple-cursors.insert_mode.completion")
local insert_mode_escape = require("multiple-cursors.insert_mode.escape")

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

default_key_maps = {

  -- Normal and visual mode motion ---------------------------------------------

  -- Up/down
  {{"n", "x"}, {"k", "<Up>"}, move.normal_k},
  {{"n", "x"}, {"j", "<Down>"}, move.normal_j},
  {{"n", "x"}, "-", move.normal_minus},
  {{"n", "x"}, {"+", "<CR>", "<kEnter>"}, move.normal_plus},
  {{"n", "x"}, "_", move.normal_underscore},

  -- Left/right
  {{"n", "x"}, {"h", "<Left>"}, move.normal_h},
  {{"n", "x"}, "<BS>", move_special.normal_bs},
  {{"n", "x"}, {"l", "<Right>", "<Space>"}, move.normal_l},
  {{"n", "x"}, {"0", "<Home>"}, move.normal_0},
  {{"n", "x"}, "^", move.normal_caret},
  {{"n", "x"}, {"$", "<End>"}, move.normal_dollar},
  {{"n", "x"}, "|", move.normal_bar},
  {{"n", "x"}, "f", move.normal_f},
  {{"n", "x"}, "F", move.normal_F},
  {{"n", "x"}, "t", move.normal_t},
  {{"n", "x"}, "T", move.normal_T},

  -- Text object motion
  {{"n", "x"}, {"w", "<S-Right>", "<C-Right>"}, move.normal_w},
  {{"n", "x"}, "W", move.normal_W},
  {{"n", "x"}, "e", move.normal_e},
  {{"n", "x"}, "E", move.normal_E},
  {{"n", "x"}, {"b", "<S-Left>", "<C-Left>"}, move.normal_b},
  {{"n", "x"}, "B", move.normal_B},
  {{"n", "x"}, "ge", move.normal_ge},
  {{"n", "x"}, "gE", move.normal_gE},

  -- Other
  {{"n", "x"}, "%", move.normal_percent},


  -- Normal mode edit ----------------------------------------------------------

  -- Delete, yank, put
  {"n", {"x", "<Del>"}, normal_edit.x},
  {"n", "X", normal_edit.X},
  {"n", "d", normal_edit.d},
  {"n", "dd", normal_edit.dd},
  {"n", "D", normal_edit.D},
  {"n", "y", normal_edit.y},
  {"n", "yy", normal_edit.yy},
  {"n", "p", normal_edit.p},
  {"n", "P", normal_edit.P},

  -- Replace characters
  {"n", "r", normal_edit.r},

  -- Indentation
  {"n", ">>", normal_edit.indent},
  {"n", "<<", normal_edit.deindent},

  -- Join lines
  {"n", "J", normal_edit.J},
  {"n", "gJ", normal_edit.gJ},

  -- Change case
  {"n", "gu", normal_edit.gu},
  {"n", "gU", normal_edit.gU},
  {"n", "g~", normal_edit.g_tilde},

  -- Repeat
  {"n", ".", normal_edit.dot},


  -- Normal mode mode change ---------------------------------------------------

  -- To insert mode
  {"n", "a", normal_mode_change.a},
  {"n", "A", normal_mode_change.A},
  {"n", {"i", "<Insert>"}, normal_mode_change.i},
  {"n", "I", normal_mode_change.I},
  {"n", "o", normal_mode_change.o},
  {"n", "O", normal_mode_change.O},
  {"n", "c", normal_mode_change.c},
  {"n", "cc", normal_mode_change.cc},
  {"n", "C", normal_mode_change.C},
  {"n", "s", normal_mode_change.s},

  -- To visual mode
  {"n", "v", normal_mode_change.v},


  -- Normal mode exit ----------------------------------------------------------
  {"n", "u", function() M.normal_undo() end},
  {"n", "<Esc>", function() M.normal_escape() end},


  -- Insert (and replace) mode -------------------------------------------------

  -- Motion
  {"i", "<Up>", insert_mode_motion.up},
  {"i", "<Down>", insert_mode_motion.down},
  {"i", "<Left>", insert_mode_motion.left},
  {"i", "<Right>", insert_mode_motion.right},
  {"i", "<Home>", insert_mode_motion.home},
  {"i", "<End>", insert_mode_motion.eol},
  {"i", "<C-Left>", insert_mode_motion.word_left},
  {"i", "<C-Right>", insert_mode_motion.word_right},

  -- Non-printing characters
  {"i", {"<BS>", "<C-h>"}, insert_mode_nonprinting.bs},
  {"i", "<Del>", insert_mode_nonprinting.del},
  {"i", {"<CR>", "<kEnter>"}, insert_mode_nonprinting.cr},
  {"i", "<Tab>", insert_mode_nonprinting.tab},

  -- Exit
  {"i", "<Esc>", insert_mode_escape.escape},


  -- Visual mode ---------------------------------------------------------------

  -- Modify area
  {"x", "o", visual_mode.o},
  {"x", "a", visual_mode.a},
  {"x", "i", visual_mode.i},

  -- Delete, yank, change
  {"x", {"d", "<Del>"}, visual_mode.d},
  {"x", "y", visual_mode.y},
  {"x", "c", visual_mode.c},

  -- Indentation
  {"x", ">", visual_mode.greater_than},
  {"x", "<", visual_mode.less_than},

  -- Join lines
  {"x", "J", visual_mode.J},
  {"x", "gJ", visual_mode.gJ},

  -- Change case
  {"x", "u", visual_mode.u},
  {"x", "U", visual_mode.U},
  {"x", "~", visual_mode.tilde},
  {"x", "gu", visual_mode.gu},
  {"x", "gU", visual_mode.gU},
  {"x", "g~", visual_mode.g_tilde},

  -- Exit
  {"x", {"<Esc>", "v"}, visual_mode.escape},

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
      { group = autocmd_group_id, callback = insert_mode_character.insert_char_pre }
    )

    vim.api.nvim_create_autocmd({"TextChangedI"},
      { group = autocmd_group_id, callback = insert_mode_character.text_changed_i }
    )

    vim.api.nvim_create_autocmd({"CompleteDonePre"},
      { group = autocmd_group_id, callback = insert_mode_completion.complete_done_pre }
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
function M.normal_undo()
  M.deinit(true)
  common.feedkeys(nil, vim.v.count, "u", nil)
end

-- Escape key
function M.normal_escape()
  M.deinit(true)
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
-- Returns cword in normal mode and the visual area text in visual mode
local function get_search_pattern()

  local pattern = nil

  if common.is_mode("v") then
    pattern = get_visual_area_text()
  else -- Normal mode
    pattern = vim.fn.expand("<cword>")
  end

  if pattern == "" then
    return nil
  else
    return pattern
  end

end

-- Get the normalise visual area if in visual mode
-- returns is_v, lnum1, col1, lnum2, col2
local function maybe_get_normalised_visual_area()

  if not common.is_mode("v") then
    return false
  end

  local lnum1, col1, lnum2, col2 = common.get_normalised_visual_area()

  return true, lnum1, col1, lnum2, col2

end

-- Add cursors by searching for the word under the cursor or visual area
local function _add_cursors_to_matches(use_prev_visual_area)

  -- Get the visual area if in visual mode
  local is_v, lnum1, col1, lnum2, col2 = maybe_get_normalised_visual_area()

  -- Get the search pattern: either the cursor under the word in normal mode or the visual area in
  -- visual mode
  local pattern = get_search_pattern()

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
    local match_lnum1 = match[1]
    local match_col1 = match[2]

    -- If normal mode
    if not is_v then
      virtual_cursors.add(match_lnum1, match_col1, match_col1, false)

    else  -- Visual mode
      local match_col2 = match_col1 + string.len(pattern) - 1
      virtual_cursors.add_with_visual_area(match_lnum1, match_col2, match_col2, match_lnum1, match_col1, false)

    end
  end

  vim.print(#matches .. " cursors added")

  -- Restore visual area
  if is_v then
    common.set_visual_area(lnum1, col1, lnum2, col2)
  end

end

-- Add cursors to each match of cword or visual area
function M.add_cursors_to_matches() _add_cursors_to_matches(false) end

-- Add cursors to each match of cword or visual area, but only within the previous visual area
function M.add_cursors_to_matches_v() _add_cursors_to_matches(true) end

-- Add a virtual cursor to the start of the word under the cursor (or visual area), then move the
-- cursor to to the next match
function M.add_cursor_and_jump_to_next_match()

  -- Get the visual area if in visual mode
  local is_v, lnum1, col1, lnum2, col2 = maybe_get_normalised_visual_area()

  -- Get the search pattern
  local pattern = get_search_pattern()

  -- Get a match without moving the cursor if there are already virtual cursors
  local match = search.get_next_match(pattern, not initialised)

  if match == nil then
    return
  end

  -- Initialise if not already initialised
  M.init()

  local match_lnum1 = match[1]
  local match_col1 = match[2]

  -- Normal mode
  if not is_v then
    -- Add virtual cursor to cursor position
    local pos = vim.fn.getcurpos()
    virtual_cursors.add(pos[2], pos[3], pos[5], true)

    -- Move cursor to match
    vim.fn.cursor({match_lnum1, match_col1, 0, match_col1})

  else  -- Visual mode
    -- Add virtual cursor to cursor position
    virtual_cursors.add_with_visual_area(lnum2, col2, col2, lnum1, col1, true)

    -- Move cursor to match
    local match_col2 = match_col1 + string.len(pattern) - 1
    common.set_visual_area(match_lnum1, match_col1, match_lnum1, match_col2)

  end

end

-- Move the cursor to the next match of the word under the cursor (or saved visual area, if any)
function M.jump_to_next_match()

  -- Get the search pattern
  local pattern = get_search_pattern()

  -- Get a match without moving the cursor
  local match = search.get_next_match(pattern, false)

  if match == nil then
    return
  end

  local match_lnum1 = match[1]
  local match_col1 = match[2]

  -- Move cursor to match
  if not common.is_mode("v") then
    vim.fn.cursor({match[1], match[2], 0, match[2]})
  else
    local match_col2 = match_col1 + string.len(pattern) - 1
    common.set_visual_area(match_lnum1, match_col1, match_lnum1, match_col2)
  end

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
