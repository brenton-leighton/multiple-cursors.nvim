local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local insert_mode_completion = require("multiple-cursors.insert_mode.completion")


-- Backspace -------------------------------------------------------------------

-- Get the character at lnum, col
-- This is only used to check for a space or tab characters, and doesn't get an
-- extended character properly
local function get_char(lnum, col)
  local l = vim.fn.getline(lnum)
  local c = string.sub(l, col - 1, col - 1)
  return c
end

-- Is the character at lnum, col a space?
local function is_space(lnum, col)
  return get_char(lnum, col) == " "
end

-- Is the character at lnum, col a tab?
local function is_tab(lnum, col)
  return get_char(lnum, col) == "\t"
end

-- Count number of spaces back to a multiple of shiftwidth
local function count_spaces_back(lnum, col)

  -- Indentation
  local stop = vim.opt.shiftwidth._value

  if not common.is_before_first_non_whitespace_char(lnum, col) then
    -- Tabbing
    if vim.opt.softtabstop._value == 0 then
      return 1
    else
      stop = vim.opt.softtabstop._value
    end
  end

  local count = 0

  -- While col isn't the first column and the character is a spce
  while col >= 1 and is_space(lnum, col) do
    count = count + 1
    col = col - 1

    -- Stop counting when col is a multiple of stop
    if (col - 1) % stop == 0 then
      break
    end
  end

  return count

end

-- Insert mode backspace command for a virtual cursor
local function virtual_cursor_insert_mode_backspace(vc)

  if vc.col == 1 then -- Start of the line
    if vc.lnum ~= 1 then -- But not the first line
      -- If the line is empty
      if common.get_length_of_line(vc.lnum) == 0 then
        -- Delete line
        vim.cmd("normal! dd")

        -- Move up and to end
        vc.lnum = vc.lnum - 1
        vc.col = common.get_max_col(vc.lnum)
        vc.curswant = vim.v.maxcol
      else
        vim.cmd("normal! k$gJ") -- Join with previous line
        vc:save_cursor_position()
      end

    end
  else

    -- Number of times to execute command, this is to backspace over tab spaces
    local count = vim.fn.max({1, count_spaces_back(vc.lnum, vc.col)})

    for i = 1, count do vim.cmd("normal! \"_X") end

    vc.col = vc.col - count
    vc.curswant = -1
  end

end

-- Replace mode backspace command for a virtual cursor
-- This only moves back a character, it doesn't undo
local function virtual_cursor_replace_mode_backspace(vc)

  -- First column but not first line
  if vc.col == 1 and vc.lnum ~= 1 then
    -- Move to end of previous line
    vc.lnum = vc.lnum - 1
    vc.col = common.get_max_col(vc.lnum)
    vc.curswant = -1
    return
  end

  -- For handling tab spaces
  local count = vim.fn.max({1, count_spaces_back(vc.lnum, vc.col)})

  -- Move left
  vc.col = vc.col - count
  vc.curswant = -1

end

-- Backspace command for all virtual cursors
local function all_virtual_cursors_backspace()
  -- Replace mode
  if common.is_mode("R") then
    virtual_cursors.edit_with_cursor_no_save(function(vc)
      virtual_cursor_replace_mode_backspace(vc)
    end)
  else
    virtual_cursors.edit_with_cursor_no_save(function(vc)
      virtual_cursor_insert_mode_backspace(vc)
    end)
  end
end

-- Backspace command
function M.bs()

  local completed = insert_mode_completion.complete_if_selected()

  all_virtual_cursors_backspace()

  -- If a completion word was inserted
  if completed then
    -- Use escape to end completion, then return to insert mode and backspace
    -- This is because backspace on the completion word is problematic
    common.feedkeys(nil, 0, "<Esc>a<BS>", nil)
  else
    -- Just pass the backspace
    common.feedkeys(nil, 0, "<BS>", nil)
  end

end


-- Delete ----------------------------------------------------------------------

-- Delete command for a virtual cursor
local function virtual_cursor_delete(vc)

  if vc.col == common.get_max_col(vc.lnum) then -- End of the line
    -- Join next line
    vim.cmd("normal! gJ")
  else -- Anywhere else on the line
    vim.cmd("normal! \"_x")
  end

  -- Cursor doesn't change
end

-- Delete command for all virtual cursors
local function all_virtual_cursors_delete()
  virtual_cursors.edit_with_cursor_no_save(function(vc)
    virtual_cursor_delete(vc)
  end)
end

-- Delete command
function M.del()
  insert_mode_completion.complete_if_selected()
  all_virtual_cursors_delete()
  common.feedkeys(nil, 0, "<Del>", nil)
end


-- Carriage return -------------------------------------------------------------

-- Carriage return command for a virtual cursor
-- This isn't local because it's used by normal_mode/mode_change.lua
function M.virtual_cursor_carriage_return(vc)
  if vc.col <= common.get_length_of_line(vc.lnum) then
    vim.api.nvim_put({"", ""}, "c", false, true)
    vim.cmd("normal! ==^")
    vc:save_cursor_position()
  else
    -- Special case for EOL: add a character to auto indent, then delete it
    vim.api.nvim_put({"", "x"}, "c", false, true)
    vim.cmd("normal! ==^\"_x")
    vc:save_cursor_position()
    vc.col = common.limit_col(vc.lnum, vc.col + 1) -- Shift cursor 1 right limited to max col
    vc.curswant = -1
  end
end

-- Carriage return command for all virtual cursors
-- This isn't local because it's used by normal_mode/mode_change.lua
function M.all_virtual_cursors_carriage_return()
  virtual_cursors.edit_with_cursor_no_save(function(vc)
    M.virtual_cursor_carriage_return(vc)
  end)
end

-- Carriage return command
-- Also for <kEnter>
function M.cr()
  insert_mode_completion.complete_if_selected()
  M.all_virtual_cursors_carriage_return()
  common.feedkeys(nil, 0, "<CR>", nil)
end


-- Tab -------------------------------------------------------------------------

-- Get the number of spaces to put for a tab character
local function get_num_spaces_to_put(stop, col)
  return stop - ((col-1) % stop)
end

-- Put a character multiple times
local function put_multiple(char, num)
  for i = 1, num do
    vim.api.nvim_put({char}, "c", false, true)
  end
end

-- Tab command for a virtual cursor
local function virtual_cursor_tab(vc)

  local expandtab = vim.opt.expandtab._value
  local tabstop = vim.opt.tabstop._value
  local softtabstop = vim.opt.softtabstop._value
  local shiftwidth = vim.opt.shiftwidth._value

  if expandtab then
    -- Spaces
    if common.is_before_first_non_whitespace_char(vc.lnum, vc.col) then
      -- Indenting
      put_multiple(" ", get_num_spaces_to_put(shiftwidth, vc.col))
    else
      -- Tabbing
      if softtabstop == 0 then
        put_multiple(" ", get_num_spaces_to_put(tabstop, vc.col))
      else
        put_multiple(" ", get_num_spaces_to_put(softtabstop, vc.col))
      end
    end
  else -- noexpandtab
    vim.api.nvim_put({"\t"}, "c", false, true)
  end

end

-- Tab command for all virtual cursors
function M.all_virtual_cursors_tab()
  virtual_cursors.edit_with_cursor(function(vc)
    -- Delete a character if in replace mode
    if common.is_mode("R") then
      vim.cmd("normal! \"_x")
    end

    -- Put a tab
    virtual_cursor_tab(vc)
  end)
end

-- Tab command
function M.tab()
  insert_mode_completion.complete_if_selected()
  M.all_virtual_cursors_tab()
  common.feedkeys(nil, 0, "<Tab>", nil)
end


return M
