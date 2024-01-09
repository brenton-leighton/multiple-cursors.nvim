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
  for _, vc in ipairs(virtual_cursors) do
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

  for _, vc in ipairs(virtual_cursors) do
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
  virtual_cursors = {}
end

function M.update_extmarks()
  for _, vc in ipairs(virtual_cursors) do
    extmarks.update_virtual_cursor_extmarks(vc)
  end
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

  for idx, vc in ipairs(virtual_cursors) do

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
function M.move_with_normal_command(count, cmd)

  M.visit_with_cursor(function(vc)
    common.normal_bang(nil, count, cmd, nil)
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
function M.edit_with_normal_command(count, cmd, motion_cmd)

  M.edit_with_cursor(function(vc)
    common.normal_bang(nil, count, cmd, motion_cmd)
    vc:save_cursor_position()
  end)

end

-- Execute a normal command to perform a delete or yank at each virtual cursor
-- The virtual cursor position is set after calling func
function M.normal_mode_delete_yank(register, count, cmd, motion_cmd)

  -- Delete or yank command
  M.edit_with_cursor(function(vc, idx)
    common.normal_bang(register, count, cmd, motion_cmd)
    vc:save_register(register)
    vc:save_cursor_position()
  end)

end

-- Execute a normal command to perform a put at each virtual cursor
-- The register is first saved, the replaced by the virtual cursor register
-- After executing the command the unnamed register is restored
function M.normal_mode_put(register, count, cmd)

  local use_own_register = true

  for _, vc in ipairs(virtual_cursors) do
    if vc.editable and not vc:has_register(register) then
      use_own_register = false
      break
    end
  end

  -- If not using each virtual cursor's register
  if not use_own_register then
    -- Return if the main register doesn't have data
    local register_info = vim.fn.getreginfo(register)
    if next(register_info) == nil then
      return
    end
  end

  M.edit_with_cursor(function(vc, idx)

    local register_info = nil

    -- If the virtual cursor has data for the register
    if use_own_register then
      -- Save the register
      register_info = vim.fn.getreginfo(register)
      -- Set the register from the virtual cursor
      vc:set_register(register)
    end

    -- Put the register
    common.normal_bang(register, count, cmd, nil)

    vc:save_cursor_position()

    -- Restore the register
    if register_info then
      vim.fn.setreg(register, register_info)
    end

  end)

end


-- Visual mode -----------------------------------------------------------------

-- Call func on the visual area of each virtual cursor
function M.visual_mode(func)

  ignore_cursor_movement = true

  -- Save the visual area to extmarks
  extmarks.save_visual_area()

  M.visit_in_buffer(function(vc, idx)
    -- Set visual area
    vc:set_visual_area()

    -- Call func
    func(vc, idx)

    -- Did func exit visual mode?
    if common.is_mode("v") then
      -- Save visual area to virtual cursor
      vc:save_visual_area()
    else  -- Edit commands will exit visual mode
      -- Save cursor
      vc:save_cursor_position()

      -- Clear the visual area
      vc.visual_start_lnum = 0
      vc.visual_start_col = 0
    end
  end)

  -- Restore the visual area from extmarks
  extmarks.restore_visual_area()

  ignore_cursor_movement = false

end

function M.visual_mode_delete_yank(register, cmd)

  M.visual_mode(function(vc, idx)
    common.normal_bang(register, 0, cmd, nil)
    vc:save_register(register)
  end)

end


-- Split pasting ---------------------------------------------------------------

-- Does the number of lines match the number of editable cursors + 1 (for the
-- real cursor)
function M.can_split_paste(num_lines)
  -- Get the number of editable virtual cursors
  local count = 0

  for _, vc in ipairs(virtual_cursors) do
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

  for idx, vc in ipairs(virtual_cursors) do

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
