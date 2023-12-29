local VirtualCursor = {}

function VirtualCursor.new(lnum, col, curswant)
  local self = setmetatable({}, VirtualCursor)

  self.lnum = lnum
  self.col = col
  self.curswant = curswant

  self.visual_start_lnum = 0            -- lnum for the start of the visual area
  self.visual_start_col = 0             -- col for the start of the visual area

  self.mark_id = 0                      -- extmark ID
  self.visual_start_mark_id = 0         -- ID of the hidden extmark that stores the start of the visual area
  self.visual_multiline_mark_id = 0     -- ID of the visual area extmark then spans multiple lines
  self.visual_empty_line_mark_ids = {}  -- IDs of the visual area extmarks for empty lines

  self.within_buffer = true             -- lnum is within the buffer
  self.editable = true                  -- To disable editing the virtual cursor when
                                        -- in collision with the real cursor
  self.delete = false                   -- To mark the virtual cursor for deletion

  self.registers = {}

  return self
end

VirtualCursor.__index = function(self, key)
  return VirtualCursor[key]
end

-- Are cursors coincident?
VirtualCursor.__eq = function(a, b)
  return a.lnum == b.lnum and a.col == b.col
end

-- Is the visual area valid?
function VirtualCursor:is_visual_area_valid()

  if self.visual_start_lnum == 0 or self.visual_start_col == 0 then
    return false
  end

  if self.visual_start_lnum > vim.fn.line("$") then
    return false
  end

  return true

end

-- Is the visual area defined in a forward direction?
function VirtualCursor:is_visual_area_forward()
  if self.visual_start_lnum == self.lnum then
    return self.visual_start_col <= self.col
  else
    return self.visual_start_lnum <= self.lnum
  end
end

-- Get the positions of the visual area in a forward direction
function VirtualCursor:get_normalised_visual_area()
  -- Get start and end positions for the extmarks representing the visual area
  local lnum1 = self.visual_start_lnum
  local col1 = self.visual_start_col
  local lnum2 = self.lnum
  local col2 = self.col

  if not self:is_visual_area_forward() then
    lnum1 = self.lnum
    col1 = self.col
    lnum2 = self.visual_start_lnum
    col2 = self.visual_start_col
  end

  return lnum1, col1, lnum2, col2
end

-- Less than for sorting
VirtualCursor.__lt = function(a, b)

  -- If either visual area isn't valid
  if not a:is_visual_area_valid() or not b:is_visual_area_valid() then

    -- Compare cursor position
    if a.lnum == b.lnum then
      return a.col < b.col
    else
      return a.lnum < b.lnum
    end

  else -- Visual mode

    -- Normalise first
    local a_lnum, a_col = a:get_normalised_visual_area()
    local b_lnum, b_col = b:get_normalised_visual_area()

    -- Compare the normalised start
    if a_lnum == b_lnum then
      return a_col < b_col
    else
      return a_lnum < b_lnum
    end

  end

end

-- Save the real cursor position to the virtual cursor
function VirtualCursor:save_cursor_position()

  local pos = vim.fn.getcurpos()

  self.lnum = pos[2]
  self.col = pos[3]
  self.curswant = pos[5]

end

-- Set the real cursor position from the virtual cursor
function VirtualCursor:set_cursor_position()
  vim.fn.cursor({self.lnum, self.col, 0, self.curswant})
end

-- Save the current visual area to the virtual cursor
function VirtualCursor:save_visual_area()

  -- Save the current visual area start position
  local visual_start_pos = vim.fn.getpos("v")
  self.visual_start_lnum = visual_start_pos[2]
  self.visual_start_col = visual_start_pos[3]

  -- Save the cursor position
  self:save_cursor_position()

end

-- Set the visual area from the virtual cursor
function VirtualCursor:set_visual_area()

  -- Exit visual mode
  vim.cmd("normal!:")

  -- Set start mark
  vim.api.nvim_buf_set_mark(0, "<", self.visual_start_lnum, self.visual_start_col - 1, {})

  -- Set end mark
  vim.api.nvim_buf_set_mark(0, ">", self.lnum, self.col - 1, {})

  -- Return to visual mode
  vim.cmd("normal! gv")

end

-- Save the register to the virtual cursor
-- returns the number of lines saved
function VirtualCursor:save_register(register)
  local register_info = vim.fn.getreginfo(register)
  self.registers[register] = register_info
  return #register_info.regcontents

end

-- Does the virtual cursor have the register?
function VirtualCursor:has_register(register)
  return self.registers[register] ~= nil
end

-- Set the register from the virtual cursor
function VirtualCursor:set_register(register)

  local register_info = self.registers[register]

  if register_info then
    vim.fn.setreg(register, register_info)
  end

end

return VirtualCursor
