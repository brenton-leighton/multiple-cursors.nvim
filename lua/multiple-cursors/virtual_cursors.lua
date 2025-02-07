local M = {}

local common = require("multiple-cursors.common")
local extmarks = require("multiple-cursors.extmarks")

local VirtualCursor = require("multiple-cursors.virtual_cursor")

-- A table of the virtual cursors
local virtual_cursors = {}

local next_seq = 1

-- Set to true when the cursor is being moved to suppress M.cursor_moved()
local ignore_cursor_movement = false

-- For locking the virtual cursors
local locked = false

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

-- Return the index of the virtual cursor that is positioned after the real cursor
-- Return 0 if the real cursor is after all virtual cursors
local function get_real_cursor_index()

  -- Ensure virtual_cursors is sorted
  M.sort()

  -- Position of the real cursor
  local real_cursor_pos = vim.fn.getcurpos() -- [0, lnum, col, off, curswant]
  local lnum = real_cursor_pos[2]
  local col = real_cursor_pos[3]

  -- Find the first virtual cursor after the real cursor
  for idx, vc in ipairs(virtual_cursors) do

    if vc.lnum > lnum then
      return idx
    elseif vc.lnum == lnum and vc.col > col then
      return idx
    end

  end

  -- Real cursor is after all virtual cursors
  return 0

end

-- Get the number of virtual cursors
function M.get_num_virtual_cursors()
  return #virtual_cursors
end

-- Is the locked variable true
function M.is_locked()
  return locked
end

-- Sort virtual cursors by position
function M.sort()
  table.sort(virtual_cursors)
end

-- Add a new virtual cursor with a visual area
-- add_seq indicates that a sequence number should be added to store the order that cursors have being added
function M.add_with_visual_area(lnum, col, curswant, visual_start_lnum, visual_start_col, add_seq)

  -- Check for existing virtual cursor
  for _, vc in ipairs(virtual_cursors) do
    if vc.col == col and vc.lnum == lnum then
      return
    end
  end

  local first = set_first and #virtual_cursors == 0

  local seq = 0  -- 0 is ignored for restoring position

  if add_seq then
    seq = next_seq
    next_seq = next_seq + 1
  end

  table.insert(virtual_cursors,
               VirtualCursor.new(lnum, col, curswant, visual_start_lnum, visual_start_col, seq))

  -- Create an extmark
  extmarks.update_virtual_cursor_extmarks(virtual_cursors[#virtual_cursors])

end

-- Add a new virtual cursor
-- add_seq indicates that a sequence number should be added to store the order that cursors have being added
function M.add(lnum, col, curswant, add_seq)
  M.add_with_visual_area(lnum, col, curswant, 0, 0, add_seq)
end

function M.remove_by_lnum(lnum)

  local delete = false

  for _, vc in ipairs(virtual_cursors) do
    if vc.lnum == lnum then
      vc.delete = true
      delete = true
    end
  end

  if delete then
    clean_up()
  end

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
    M.add(lnum, col, col, false)
  end
end

-- Get the position that the real cursor should take on exit, i.e. the position
-- of the virtual cursor with the lowest non-zero seq
function M.get_exit_pos()

  local seq = 999999
  local lnum = 0
  local col = 0
  local curswant = 0

  for _, vc in ipairs(virtual_cursors) do
    if vc.seq ~= 0 and vc.seq < seq then
      seq = vc.seq
      lnum = vc.lnum
      col = vc.col
      curswant = vc.curswant
    end
  end

  if seq ~= 999999 then
    return {lnum, col, curswant}
  else
    return nil
  end

end

-- Clear all virtual cursors
function M.clear()
  virtual_cursors = {}
  next_seq = 1
  locked = false
  extmarks.set_locked(false)
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

    -- First update the virtual cursor position from the extmark in case there
    -- was a change due to editing
    extmarks.update_virtual_cursor_position(vc)

    -- Mark editable to false if coincident with the real cursor
    vc.editable = not (vc.lnum == pos[2] and vc.col == pos[3])

    -- Update the extmark (extmark is invisible if editable == false)
    extmarks.update_virtual_cursor_extmarks(vc)
  end
end

function M.toggle_lock()

  locked = not locked

  -- Update extmarks
  extmarks.set_locked(locked)

  for idx, vc in ipairs(virtual_cursors) do
    extmarks.update_virtual_cursor_extmarks(vc)
  end

end


-- Visitors --------------------------------------------------------------------

-- Visit all virtual cursors
function M.visit_all(func)

  if locked then
    return
  end

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

    -- Set virtual cursor position from extmark in case there were any changes
    extmarks.update_virtual_cursor_position(vc)

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

-- Visit virtual cursors within the buffer with the real cursor
function M.visit_with_cursor(func)

  ignore_cursor_movement = true

  M.visit_all(function(vc, idx)
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

  M.visit_all(function(vc, idx)
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
function M.edit_with_cursor_no_save(func)

  M.edit(function(vc, idx)
    vc:set_cursor_position()
    func(vc, idx)
  end)

end

-- Call func to perform an edit at each virtual cursor using the real cursor
function M.edit_with_cursor(func)

  M.edit_with_cursor_no_save(function(vc, idx)
    func(vc, idx)
    vc:save_cursor_position()
  end)

end

-- Execute a normal command to perform an edit at each virtual cursor
-- The virtual cursor position is set after calling func
function M.edit_with_normal_command(count, cmd, motion_cmd)

  M.edit_with_cursor(function(vc)
    common.normal_bang(nil, count, cmd, motion_cmd)
  end)

end

-- Execute a normal command to perform a delete or yank at each virtual cursor
-- The virtual cursor position is set after calling func
function M.normal_mode_delete_yank(register, count, cmd, motion_cmd)

  -- Delete or yank command
  M.edit_with_cursor(function(vc, idx)
    common.normal_bang(register, count, cmd, motion_cmd)
    vc:save_register(register)
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

  M.visit_all(function(vc, idx)
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


-- Go to commands ("G" and "gg") -----------------------------------------------

local function set_real_cursor_lnum(lnum)
  local pos = vim.fn.getcurpos()

  pos[2] = lnum

  if not vim.o.startofline then
    pos[3] = common.curswant2col(lnum, pos[5])
  else
    pos[3] = vim.fn.match(vim.fn.getline(lnum), "\\S") + 1
    pos[5] = pos[3]
  end

  vim.fn.cursor({pos[2], pos[3], 0, pos[5]})
end

-- Move the highest cursor to lnum and subsequent cursors to subsequent lines
-- This function does nothing if locked is true so real cursor still needs to be
-- moved
function M.go_to(lnum)

  if locked then
    return
  end

  local num_lines = vim.fn.line("$")
  local num_cursors = #virtual_cursors + 1

  -- Do nothing if the number of cursors is greater than the number of lines
  if num_cursors > num_lines then
    return
  end

  -- Modify lnum if cursors will go past the buffer
  if (lnum + num_cursors - 1) > num_lines then
    lnum = num_lines - num_cursors + 1
  end

  -- Index of the real cursor if it were in virtual cursors
  local real_cursor_idx = get_real_cursor_index()

  ignore_cursor_movement = true

  for idx, vc in ipairs(virtual_cursors) do

    if real_cursor_idx == idx then
      -- Set the real cursor first
      set_real_cursor_lnum(lnum)
      lnum = lnum + 1
    end

    -- Set virtual cursor lnum
    extmarks.update_virtual_cursor_position(vc)

    vc.lnum = lnum

    if not vim.o.startofline then
      vc.col = common.curswant2col(lnum, vc.curswant)
    else
      vc.col = vim.fn.match(vim.fn.getline(lnum), "\\S") + 1
      vc.curswant = -1
    end

    extmarks.update_virtual_cursor_extmarks(vc)

    lnum = lnum + 1
  end

  -- Real cursor is after the virtual cursors
  if real_cursor_idx == 0 then
    set_real_cursor_lnum(lnum)
  end

  ignore_cursor_movement = false

end


-- Split pasting ---------------------------------------------------------------

-- Does the number of lines match the number of editable cursors + 1 (for the
-- real cursor)
function M.can_split_paste(num_lines)
  -- Get the number of editable virtual cursors
  local count = 0

  for _, vc in ipairs(virtual_cursors) do
    if vc.editable then
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

  -- Index of the real cursor if it were in virtual cursors
  local real_cursor_idx = get_real_cursor_index()

  if real_cursor_idx ~= 0 then
    -- Move the line for the real cursor to the end
    local real_cursor_line = table.remove(lines, real_cursor_idx)
    table.insert(lines, real_cursor_line)
  end

end


-- Merge registers on exit -----------------------------------------------------

-- Insert each line of from into to
local function concatenate_regcontents(from, to)
  for _, line in ipairs(from) do
    table.insert(to, line)
  end
end

-- Return the names of any registers stored by the virtual cursors
function M.get_registers()

  local tmp = {}

  for _, vc in ipairs(virtual_cursors) do
    for key, value in pairs(vc.registers) do
      tmp[key] = true
    end
  end

  local registers = {}

  for key, _ in pairs(tmp) do
    table.insert(registers, key)
  end

  return registers

end

-- Merge registers of all cursors
function M.merge_register_info(register)

  -- Index of the real cursor if it were in virtual cursors
  local real_cursor_idx = get_real_cursor_index()

  -- Real cursor register info
  local register_info = vim.fn.getreginfo(register)

  -- To store concatenated lines
  local regcontents = {}

  for idx, vc in ipairs(virtual_cursors) do
    if real_cursor_idx == idx then
      -- Insert the real cursor lines first
      concatenate_regcontents(register_info.regcontents, regcontents)
    end

    -- Insert virtual cursor register lines
    concatenate_regcontents(vc.registers[register].regcontents, regcontents)
  end

  -- Real cursor is after all virtual cursors
  if real_cursor_idx == 0 then
    concatenate_regcontents(register_info.regcontents, regcontents)
  end

  -- Update register info
  register_info.regcontents = regcontents
  vim.fn.setreg(register, register_info)

end

return M
