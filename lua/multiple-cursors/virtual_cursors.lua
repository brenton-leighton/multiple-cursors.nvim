local M = {}

local common = require("multiple-cursors.common")
local extmarks = require("multiple-cursors.extmarks")

-- A table of the virtual cursors
local virtual_cursors = {}

-- Set to true when the cursor is being moved to suppress M.cursor_moved()
local ignore_cursor_movement = false

-- Remove any virtual cursors marked for deletion
local function clean_up()
  for idx = #virtual_cursors, 1, -1 do
    if virtual_cursors[idx].delete then
      extmarks.delete_virtual_cursor_extmarks(virtual_cursors[idx])
      table.remove(virtual_cursors, idx)
    end
  end
end

-- Check for and solve any collisions between virtual cursors
-- The virtual cursor with the higher mark ID is removed
local function check_for_collisions()

  if #virtual_cursors < 2 then
    return
  end

  for idx1 = 1, #virtual_cursors - 1 do
    vc1 = virtual_cursors[idx1]

    for idx2 = idx1 + 1, #virtual_cursors do
      vc2 = virtual_cursors[idx2]

      if vc1.lnum == vc2.lnum and vc1.col == vc2.col then
        vc2.delete = true
      end
    end -- idx2
  end -- idx1

  clean_up()

end

-- Get the number of virtual cursors
function M.get_num_virtual_cursors()
  return #virtual_cursors
end

-- Add a new virtual cursor
function M.add(lnum, col, curswant)

  -- Check for existing virtual cursor
  for idx = 1, #virtual_cursors do
    local vc = virtual_cursors[idx]
    if vc.col == col and vc.lnum == lnum then
      return
    end
  end

  table.insert(virtual_cursors,
    {
      lnum = lnum,
      col = col,
      curswant = curswant,
      within_buffer = true,  -- lnum is within the buffer
      mark_id = 0,           -- extmark ID

      visual_start_lnum = 0,            -- lnum for the start of the visual area
      visual_start_col = 0,             -- col for the start of the visual area
      visual_start_mark_id = 0,         -- ID of the hidden extmark that stores the start of the visual area
      visual_multiline_mark_id = 0,     -- ID of the visual area extmark then spans multiple lines
      visual_empty_line_mark_ids = {},  -- IDs of the visual area extmarks for empty lines

      editable = true,      -- To disable editing the virtual cursor when
                            -- in collision with the real cursor
      delete = false,       -- To mark the virtual cursor for deletion
      register_info = nil,  -- Output from getreginfo()
    }
  )

  -- Create an extmark
  extmarks.update_virtual_cursor_extmarks(virtual_cursors[#virtual_cursors])
end

-- Add a new virtual cursor, or delete if there's already an existing virtual
-- cursor
function M.add_or_delete(lnum, col)
  -- Find any existing virtual cursor
  local delete = false

  for idx = 1, #virtual_cursors do
    local vc = virtual_cursors[idx]
    if vc.col == col and vc.lnum == lnum then
      vc.delete = true
      delete = true
    end
  end

  if delete then
    clean_up()
  else
    M.add(lnum, col, col)
  end
end

-- Clear all virtual cursors
function M.clear()
  extmarks.clear()
  virtual_cursors = {}
end

-- Callback for the CursorMoved event
-- Set editable to false for any virtual cursors that collide with the real
-- cursor
function M.cursor_moved()

  if ignore_cursor_movement then
    return
  end

  -- Get real cursor position
  local pos = vim.fn.getcursorcharpos() -- [0, lnum, col, off, curswant]

  for idx = #virtual_cursors, 1, -1 do
    local vc = virtual_cursors[idx]

    if vc.within_buffer then
      -- First update the virtual cursor position from the extmark in case there
      -- was a change due to editing
      extmarks.update_virtual_cursor_position(vc)

      -- Mark editable to false if coincident with the real cursor
      vc.editable = not (vc.lnum == pos[2] and vc.col == pos[3])

      -- Update the extmark (extmark is invisible if editable == false)
      extmarks.update_virtual_cursor_extmarks(vc)
    end
  end
end

-- Visit each virtual cursor with the real cursor and call func(vc)
-- use_extmark: Use an extmark to save the cursor position
-- editable_only: only call func on editable cursors
-- set_position: set the virtual cursor position from the cursor after calling
-- func: Function to call with the virtual cursor
local function visit(use_extmark, editable_only, set_position, func)

  -- Disable cursor_moved
  ignore_cursor_movement = true

  -- Save cursor position
  local cursor_pos = nil

  if not use_extmark then
    cursor_pos = vim.fn.getcursorcharpos() -- [0, lnum, col, off, curswant]
  else
    extmarks.save_cursor()
  end

  -- For each virtual cursor
  for idx = 1, #virtual_cursors do

    local vc = virtual_cursors[idx]

    if vc.within_buffer and (not editable_only or vc.editable) then

      -- Set virtual cursor position from extmark in case there were any changes
      extmarks.update_virtual_cursor_position(vc)

      if not vc.delete then
        -- Set real cursor to virtual cursor position
        common.set_cursor_to_virtual_cursor(vc)

        -- Call the function
        func(vc)

        if set_position then
          -- Set virtual cursor position from real cursor
          common.set_virtual_cursor_from_cursor(vc)
        end

        -- Update the extmark
        extmarks.update_virtual_cursor_extmarks(vc)
      end
    end
  end

  clean_up()
  check_for_collisions()

  -- Restore cursor position
  if not use_extmark then
    vim.fn.setcursorcharpos({cursor_pos[2], cursor_pos[3], cursor_pos[4], cursor_pos[5]})
  else
    extmarks.restore_cursor()
  end

  ignore_cursor_movement = false

end

-- Move ------------------------------------------------------------------------

function M.move_manually(func)

  for idx = 1, #virtual_cursors do
    local vc = virtual_cursors[idx]

    if vc.within_buffer then
      -- Set virtual cursor position from extmark in case there were any changes
      extmarks.update_virtual_cursor_position(vc)
    end

    if not vc.delete then
      -- Call the function
      func(vc)

      -- Update the extmark
      extmarks.update_virtual_cursor_extmarks(vc)
    end
  end

  clean_up()
  check_for_collisions()

end

function M.move_normal(cmd, count)
  visit(false, false, true, function()
    if count == 0 then
      vim.cmd("normal! " .. cmd)
    else
      vim.cmd("normal! " .. tostring(count) .. cmd)
    end
  end)
end

-- Edit ------------------------------------------------------------------------

-- Perform an edit at the virtual cursors using a function
-- if set_position is true the virtual cursor position will be set from the
-- cursor after the function is called
-- The virtual cursor postion must be updated by the function
function M.edit(func, set_position)
  visit(true, true, set_position, function(vc)
    func(vc)
  end)
end

-- Perform an edit at the virtual cursors using a normal command
function M.normal_edit(cmd, count)
  visit(true, true, true, function(vc)
    if count == 0 then
      vim.cmd("normal! " .. cmd)
    else
      vim.cmd("normal! " .. tostring(count) .. cmd)
    end
  end)
end

-- Perform a delete or yank command at the virtual cursors
function M.normal_delete_yank(cmd, count)
  visit(true, true, true, function(vc)
    if count == 0 then
      vim.cmd("normal! " .. cmd)
    else
      vim.cmd("normal! " .. tostring(count) .. cmd)
    end

    -- Save register info to the virtual cursor
    vc.register_info = vim.fn.getreginfo('"')
  end)
end

-- Perform a put command at the virtual cursors
function M.put(cmd, count)
  visit(true, true, true, function(vc)
    local tmp_register_info = nil

    -- If the virtual cursor has register info
    if vc.register_info then
      -- Save the unnamed register
      tmp_register_info = vim.fn.getreginfo('"')
      -- Set the virtual cursor register info to the unnamed register
      vim.fn.setreg('"', vc.register_info)
    end

    -- Put the unnamed register
    if count == 0 then
      vim.cmd("normal! " .. cmd)
    else
      vim.cmd("normal! " .. tostring(count) .. cmd)
    end

    if vc.register_info then
      -- Restore the unnamed register
      vim.fn.setreg('"', tmp_register_info)
    end
  end)
end

-- Visual mode -----------------------------------------------------------------

-- Visual mode entered while multiple cursors is active
function M.mode_changed_to_visual()

  -- Save cursor position as visual area start
  for idx = 1, #virtual_cursors do
    local vc = virtual_cursors[idx]
    vc.visual_start_lnum = vc.lnum
    vc.visual_start_col = vc.col
  end

  -- Move cursor if there's a count
  if vim.v.count > 1 then
    local count = vim.v.count - 1
    M.move_manually(
    function(vc)
      local col = vc.col + count
      vc.col = common.get_col(vc.lnum, col)
      vc.curswant = vc.col
    end)
  end

end

-- Visual mode exited while multiple cursors is active
function M.mode_changed_from_visual()
  for idx = 1, #virtual_cursors do
    local vc = virtual_cursors[idx]
    extmarks.update_virtual_cursor_position(vc)

    vc.visual_start_lnum = 0
    vc.visual_start_col = 0

    extmarks.update_virtual_cursor_extmarks(vc)
  end
end

-- Move cursor to other end of visual area
function M.visual_other()
  for idx = 1, #virtual_cursors do
    local vc = virtual_cursors[idx]

    local lnum = vc.lnum
    local col = vc.col

    vc.lnum = vc.visual_start_lnum
    vc.col = vc.visual_start_col
    vc.curswant = vc.col

    vc.visual_start_lnum = lnum
    vc.visual_start_col = col

    extmarks.update_virtual_cursor_extmarks(vc)
  end
end

-- Get the positions of the visual area in a forward direction
local function get_normalised_visual_area(vc)
  -- Get start and end positions for the extmarks representing the visual area
  local lnum1 = vc.visual_start_lnum
  local col1 = vc.visual_start_col
  local lnum2 = vc.lnum
  local col2 = vc.col

  if not common.is_visual_area_forward(vc) then
    lnum1 = vc.lnum
    col1 = vc.col
    lnum2 = vc.visual_start_lnum
    col2 = vc.visual_start_col
  end

  return lnum1, col1, lnum2, col2
end

-- Get visual area text to put into regcontents
local function visual_area_to_register_info(lnum1, col1, lnum2, col2, cmd)

  local lines = {}

  -- Single line
  if lnum1 == lnum2 then
    lines = vim.fn.getbufline("", lnum1)
  else
    lines = vim.fn.getbufline("", lnum1, lnum2)
  end

  -- Trim back of last line
  if col2 < string.len(lines[#lines]) then
    lines[#lines] = string.sub(lines[1], 1, col2)
  end

  -- Trim front of first line
  if col1 > 1 then
    lines[1] = string.sub(lines[1], col1)
  end

  local points_to = "0" -- yank

  if cmd == "d" then -- delete
    if lnum1 == lnum2 then -- Single line
      points_to = "-"
    else
      points_to = "1"
    end
  end

  return {
    points_to = points_to,
    regcontents = lines,
    regtype = "v",
  }

end

function M.visual_yank()

  for idx = 1, #virtual_cursors do
    local vc = virtual_cursors[idx]

    if vc.within_buffer then
      -- Yank the area
      local lnum1, col1, lnum2, col2 = get_normalised_visual_area(vc)
      vc.register_info = visual_area_to_register_info(lnum1, col1, lnum2, col2, "y")

      -- Move cursor to start
      if common.is_visual_area_forward(vc) then
        vc.lnum = vc.visual_start_lnum
        vc.col = vc.visual_start_col
        vc.curswant = vc.col
        extmarks.update_virtual_cursor_extmarks(vc)
      end
    end
  end

end

local function get_text_adjacent_to_visual_area(lnum1, col1, lnum2, col2)

  -- Get the text before col1
  local text1 = ""

  if col1 > 1 then
    text1 = vim.fn.getbufoneline("", lnum1)
    text1 = string.sub(text1, 1, col1 - 1)
  end

  -- Get the text after col2
  local text2 = ""

  if col2 < common.get_length_of_line(lnum2) then
    text2 = vim.fn.getbufoneline("", lnum2)
    text2 = string.sub(text2, col2 + 1)
  end

  return text1 .. text2

end

function M.visual_delete()

  -- Disable cursor_moved
  ignore_cursor_movement = true

  -- Save cursor position
  extmarks.save_cursor()

  -- For each virtual cursor
  for idx = 1, #virtual_cursors do
    local vc = virtual_cursors[idx]

    if vc.within_buffer then

      -- Set virtual cursor position from extmark in case there were any changes
      extmarks.update_virtual_cursor_position(vc)

      -- Yank the area
      local lnum1, col1, lnum2, col2 = get_normalised_visual_area(vc)
      vc.register_info = visual_area_to_register_info(lnum1, col1, lnum2, col2, "d")

      -- Handle the end of the visual area being past the end of the line
      if col2 >= common.get_max_col(lnum2) then
        lnum2 = lnum2 + 1
        col2 = 0
      end

      -- Get the text before and after the visual area
      local remaining_text = get_text_adjacent_to_visual_area(lnum1, col1, lnum2, col2)

      -- Delete all lines of the area
      vim.fn.deletebufline("", lnum1, lnum2)

      -- Put the remaining text
      vim.fn.append(lnum1 - 1, remaining_text)

      -- Move cursor to start
      vc.lnum = lnum1
      vc.col = vim.fn.min({col1, common.get_max_col(lnum1) - 1})
      -- col is limited to what it can be in normal mode, because visual mode will exit afterwards
      vc.curswant = col1

      -- Clear the visual area
      vc.visual_start_lnum = 0
      vc.visual_start_col = 0

      -- Update the extmark
      extmarks.update_virtual_cursor_extmarks(vc)

    end -- If within buffer

  end -- For each virtual cursor

  clean_up()
  check_for_collisions()

  -- Restore cursor position
  extmarks.restore_cursor()

  ignore_cursor_movement = false

end

-- Pasting ---------------------------------------------------------------------

-- Does the number of lines match the number of editable cursors + 1 (for the
-- real cursor)
function M.can_split_paste(num_lines)
  -- Get the number of editable virtual cursors
  local count = 0

  for idx = 1, #virtual_cursors do
    local vc = virtual_cursors[idx]
    if vc.within_buffer and vc.editable then
      count = count + 1
    end
  end

  return count + 1 == num_lines
end

-- Get indices of virtual cursors and the real cursor (represented by 0) ordered
-- by position
function M.get_cursor_order()

  -- Table to store {index, lnum, col} for each cursor
  local tmp = {}

  -- Real cursor
  local cursor_pos = vim.fn.getcursorcharpos()
  table.insert(tmp, {0, cursor_pos[2], cursor_pos[3]})

  for idx = 1, #virtual_cursors do
    local vc = virtual_cursors[idx]
    if vc.within_buffer and vc.editable then
      table.insert(tmp, {idx, vc.lnum, vc.col})
    end
  end

  table.sort(tmp, function(vc1, vc2)
    if vc1[2] == vc2[2] then -- Same lnum
      return vc1[3] < vc2[3] -- vc1.col < vc2.col
    else
      return vc1[2] < vc2[2] -- vc1.lnum < vc2.lnum
    end
  end)

  local indices = {}

  for idx = 1, #tmp do
    table.insert(indices, tmp[idx][1])
  end

  return indices

end

-- Call func to paste at each cursor
function M.paste(lines, func, split_paste, set_position)

  ignore_cursor_movement = true

  extmarks.save_cursor()

  for idx = 1, #virtual_cursors do

    local vc = virtual_cursors[idx]

    if vc.within_buffer and vc.editable then

      -- Set virtual cursor position from extmark in case there were any changes
      extmarks.update_virtual_cursor_position(vc)

      if not vc.delete then
        -- Set real cursor to virtual cursor position
        common.set_cursor_to_virtual_cursor(vc)

        if split_paste then
          func({lines[idx]}, vc)
        else
          func(lines, vc)
        end

        if set_position then
          -- Set virtual cursor position from real cursor
          common.set_virtual_cursor_from_cursor(vc)
        end

        -- Update extmark
        extmarks.update_virtual_cursor_extmarks(vc)
      end
    end
  end

  clean_up()
  check_for_collisions()

  extmarks.restore_cursor()

  ignore_cursor_movement = false

end

return M
