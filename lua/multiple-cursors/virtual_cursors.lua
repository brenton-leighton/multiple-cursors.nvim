local M = {}

local common = require("multiple-cursors.common")
local extmarks = require("multiple-cursors.extmarks")

local VirtualCursor = require("multiple-cursors.virtual_cursor")

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
    for idx2 = idx1 + 1, #virtual_cursors do
      if virtual_cursors[idx1] == virtual_cursors[idx2] then
        virtual_cursors[idx2].delete = true
      end
    end
  end

  clean_up()

end

-- Get the number of virtual cursors
function M.get_num_virtual_cursors()
  return #virtual_cursors
end

-- Sort virtual cursors by position
function M.sort()
  table.sort(virtual_cursors)
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

  table.insert(virtual_cursors, VirtualCursor.new(lnum, col, curswant))

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

function M.set_ignore_cursor_movement(_ignore_cursor_movement)
  ignore_cursor_movement = _ignore_cursor_movement
end

-- Callback for the CursorMoved event
-- Set editable to false for any virtual cursors that collide with the real
-- cursor
function M.cursor_moved()

  if ignore_cursor_movement then
    return
  end

  -- Get real cursor position
  local pos = vim.fn.getcurpos() -- [0, lnum, col, off, curswant]

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


-- Visitors --------------------------------------------------------------------

-- Visit all virtual cursors
function M.visit_all(func)

  -- Save cursor position
  -- This is because changing virtualedit causes curswant to be reset
  local cursor_pos = vim.fn.getcurpos()

  -- Save virtualedit
  local ve = vim.wo.ve

  -- Set virtualedit to onemore in insert or replace modes
  if common.is_mode_insert_replace() then
    vim.wo.ve = "onemore"
  end

  for idx = 1, #virtual_cursors do
    local vc = virtual_cursors[idx]

    if vc.within_buffer then
      -- Set virtual cursor position from extmark in case there were any changes
      extmarks.update_virtual_cursor_position(vc)
    end

    if not vc.delete then
      -- Call the function
      func(vc, idx)

      -- Update extmarks
      extmarks.update_virtual_cursor_extmarks(vc)
    end

  end

  -- Revert virtualedit in insert or replace modes
  if common.is_mode_insert_replace() then
    vim.wo.ve = ve
  end

  -- Restore cursor
  vim.fn.cursor({cursor_pos[2], cursor_pos[3], cursor_pos[4], cursor_pos[5]})

  clean_up()
  check_for_collisions()

end

-- Visit virtual cursors within buffer
function M.visit_in_buffer(func)

  M.visit_all(function(vc, idx)
    if vc.within_buffer then
      func(vc, idx)
    end
  end)

end

-- Visit virtual cursors within the buffer with the real cursor
function M.visit_with_cursor(func)

  ignore_cursor_movement = true

  M.visit_in_buffer(function(vc, idx)
    vc:set_cursor_position()
    func(vc, idx)
  end)

  ignore_cursor_movement = false

end

-- Visit virtual cursors and execute a normal command to move them
function M.move_with_normal_command(cmd, count)

  M.visit_with_cursor(function(vc)
    common.normal_bang(cmd, count)
    vc:save_cursor_position()

    -- Fix for $ not setting col correctly in insert mode even with onemore
    if common.is_mode_insert_replace() then
      if vc.curswant == vim.v.maxcol then
        vc.col = common.get_max_col(vc.lnum)
      end
    end
  end)

end

-- Call func to perform an edit at each virtual cursor
-- The virtual cursor position is not set after calling func
function M.edit(func)

  -- Save cursor position with extmark
  ignore_cursor_movement = true
  extmarks.save_cursor()

  M.visit_in_buffer(function(vc, idx)
    if vc.editable then
      func(vc, idx)
    end
  end)

  -- Restore cursor from extmark
  extmarks.restore_cursor()
  ignore_cursor_movement = false

end

-- Call func to perform an edit at each virtual cursor using the real cursor
-- The virtual cursor position is not set after calling func
function M.edit_with_cursor(func)

  M.edit(function(vc, idx)
    vc:set_cursor_position()
    func(vc, idx)
  end)

end

-- Execute a normal command to perform an edit at each virtual cursor
-- The virtual cursor position is set after calling func
function M.edit_with_normal_command(cmd, count)

  M.edit_with_cursor(function(vc)
    common.normal_bang(cmd, count)
    vc:save_cursor_position()
  end)

end

-- Execute a normal command to perform a delete or yank at each virtual cursor
-- The virtual cursor position is set after calling func
function M.normal_mode_delete_yank(cmd, count)

  -- Delete or yank command
  M.edit_with_cursor(function(vc, idx)
    common.normal_bang(cmd, count)
    vc.register_info = vim.fn.getreginfo('"')
    vc:save_cursor_position()
  end)

end

-- Execute a normal command to perform a put at each virtual cursor
-- The unnamed register is first saved, the replaced by the virtual cursor
-- register
-- After executing the command the unnamed register is restored
function M.normal_mode_put(cmd, count)

  M.edit_with_cursor(function(vc, idx)

    local tmp_register_info = nil

    -- If the virtual cursor has register info
    if vc.register_info then
      -- Save the unnamed register
      tmp_register_info = vim.fn.getreginfo('"')
      -- Set the virtual cursor register info to the unnamed register
      vim.fn.setreg('"', vc.register_info)
    end

    -- Put the unnamed register
    common.normal_bang(cmd, count)

    vc:save_cursor_position()

    -- If the virtual cursor has register info
    if vc.register_info then
      -- Restore the unnamed register
      vim.fn.setreg('"', tmp_register_info)
    end

  end)

end


-- Visual mode -----------------------------------------------------------------

-- Restore a saved visual area
local function restore_visual_area(prev_visual_area)
  vim.cmd("normal!:") -- Exit to normal mode
  vim.api.nvim_buf_set_mark(0, "<", prev_visual_area[1], prev_visual_area[2] - 1, {})
  vim.api.nvim_buf_set_mark(0, ">", prev_visual_area[3], prev_visual_area[4] - 1, {})
  vim.cmd("normal! gv") -- Return to visual mode
end

-- Modify visual areas without changing the buffer
function M.visual_mode_modify_area(func)

  ignore_cursor_movement = true

  -- Save the visual area
  local visual_area = common.get_visual_area()

  M.visit_in_buffer(function(vc, idx)
    -- Set visual area
    vc:set_visual_area()

    -- Call func
    func(vc, idx)

    -- Save visual area to virtual cursor
    vc:save_visual_area()
  end)

  -- Restore the visual area
  restore_visual_area(visual_area)

  ignore_cursor_movement = false

end

-- Perform edit on each visual area
function M.visual_mode_edit(func)

  ignore_cursor_movement = true

  -- Save the visual area to extmarks
  extmarks.save_visual_area()

  M.visit_in_buffer(function(vc, idx)
    -- Set visual area
    vc:set_visual_area()

    -- Call func
    func(vc, idx)
    -- Edit commands will exit

    vc:save_cursor_position()

    -- Clear the visual area
    vc.visual_start_lnum = 0
    vc.visual_start_col = 0
  end)

  -- Restore the visual area from extmarks
  extmarks.restore_visual_area()

  ignore_cursor_movement = false

end

function M.visual_mode_delete_yank(cmd)

  M.visual_mode_edit(function(vc, idx)
    common.normal_bang(cmd, 0)
    vc.register_info = vim.fn.getreginfo('"')
  end)

end


-- Split pasting ---------------------------------------------------------------------

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

-- Move the line for the real cursor to the end of lines
-- Modifies the lines variable
function M.reorder_lines_for_split_pasting(lines)

  -- Ensure virtual_cursors is sorted
  M.sort()

  -- Move real cursor line to the end
  local real_cursor_pos = vim.fn.getcurpos() -- [0, lnum, col, off, curswant]

  local cursor_line_idx = 0

  for idx = 1, #virtual_cursors do
    local vc = virtual_cursors[idx]

    if vc.lnum == real_cursor_pos[2] then
      if vc.col > real_cursor_pos[3] then
        cursor_line_idx = idx
        break
      end
    else
      if vc.lnum > real_cursor_pos[2] then
        cursor_line_idx = idx
        break
      end
    end

  end

  if cursor_line_idx ~= 0 then
    -- Move the line for the real cursor to the end
    local real_cursor_line = table.remove(lines, cursor_line_idx)
    table.insert(lines, real_cursor_line)
  end

end

return M
