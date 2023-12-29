local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local insert_mode = require("multiple-cursors.insert_mode")
local input = require("multiple-cursors.input")

local mode_cmd = nil

-- For c and v commands
local count = nil

-- For c command
local c_motion_cmd = nil


local function _a()
  -- Shift cursors right
  virtual_cursors.move_with_normal_command(0, "l")
end

local function _A()
  -- Cursors to end of line
  virtual_cursors.move_with_normal_command(0, "$")
end

local function _i()
  -- curswant is lost
  virtual_cursors.visit_in_buffer(function(vc)
    vc.curswant = vc.col
  end)
end

local function _I()
  -- Cursor to start of line
  virtual_cursors.move_with_normal_command(0, "^")
end

local function _o()
  -- New line after current line
  virtual_cursors.move_with_normal_command(0, "$")
  insert_mode.all_virtual_cursors_carriage_return()
end

local function _O()

  -- New line before current line
  virtual_cursors.visit_in_buffer(function(vc)
    if vc.lnum == 1 then -- First line, move to start of line
      vc.col = 1
      vc.curswant = 1
    else -- Move to end of previous line
      vc.lnum = vc.lnum - 1
      vc.col = common.get_col(vc.lnum, vim.v.maxcol)
      vc.curswant = vim.v.maxcol
    end
  end)

  -- Carriage return
  virtual_cursors.edit_with_cursor(function(vc)
    -- If first line and first character
    if vc.lnum == 1 and vc.col == 1 then
      insert_mode.virtual_cursor_carriage_return(vc)
      vc.lnum = 1 -- Move the cursor back
    else
      insert_mode.virtual_cursor_carriage_return(vc)
    end
  end)

end

local function _v()

  virtual_cursors.visit_in_buffer(function(vc)

    -- Save cursor position as visual area start
    vc.visual_start_lnum = vc.lnum
    vc.visual_start_col = vc.col

    -- Move cursor forward if there's a count
    if count > 0 then
      vc.col = common.get_col(vc.lnum, vc.col + count)
      vc.curswant = vc.col
    end

  end)

end

local up_down_motions = {
  ["j"] = true,
  ["k"] = true,
  ["+"] = true,
  ["-"] = true,
}

local function open_new_line_above(actual_motion_cmd, num_register_lines)

  if actual_motion_cmd == "_" then
    common.normal_bang(nil, 0, "O", nil)
    return
  end

  -- If it's an up/down motion and more than one line has been deleted
  if up_down_motions[actual_motion_cmd] and num_register_lines > 1 then
    common.normal_bang(nil, 0, "O", nil)
  end

end

local function _c()

  local actual_motion_cmd = c_motion_cmd:sub(#c_motion_cmd, #c_motion_cmd)
  local motion_cmd_count = ""

  if #c_motion_cmd > 1 then
    motion_cmd_count = c_motion_cmd:sub(1, #c_motion_cmd - 1)
  end

  -- For _ command
  if actual_motion_cmd == "_" then
    if motion_cmd_count ~= "" then
      count = count + tonumber(motion_cmd_count)
      c_motion_cmd = "_" -- Clear the count in the motion command
    end
    -- The delete command needs to be at least 1
    count = vim.fn.max({1, count})
  end

  local register = vim.v.register

  -- Real cursor
  local ve = vim.wo.ve
  vim.wo.ve = "onemore"
  common.normal_bang(register, count, "d", c_motion_cmd)
  open_new_line_above(actual_motion_cmd, vim.fn.getreginfo(register))
  vim.wo.ve = ve

  -- Virtual cursors
  virtual_cursors.edit_with_cursor(function(vc, idx)
    common.normal_bang(register, count, "d", c_motion_cmd)
    local num_register_lines = vc:save_register(register)
    open_new_line_above(actual_motion_cmd, num_register_lines)
    vc:save_cursor_position()
  end)

  c_motion_cmd = nil

end

-- ToDo fix auto indent?
local function _cc()

  local register = vim.v.register

  -- Virtual cursors
  virtual_cursors.move_with_normal_command(0, "0")
  insert_mode.all_virtual_cursors_carriage_return()
  virtual_cursors.normal_mode_delete_yank(register, count, "dd", nil)
  virtual_cursors.move_with_normal_command(0, "k")

  -- Real cursor
  common.normal_bang(register, count, "dd", nil)
  common.normal_bang(nil, 0, "O", nil)

end

local function _C()

  local register = vim.v.register

  -- Real cursor
  -- If the cursor is at the start of the line and count > 1
  if vim.fn.getcurpos()[3] == 1 and count > 1 then
    -- Delete and open a new line
    common.normal_bang(register, count, "D", nil)
    common.normal_bang(nil, 0, "O", nil)
  else
    -- Delete and move the cursor right
    common.normal_bang(register, count, "D", nil)
    common.feedkeys(nil, 0, "<Right>", nil)
  end

  -- Virtual cursors
  virtual_cursors.edit_with_cursor(function(vc, idx)
    if vc.col == 1 and count > 1 then
      common.normal_bang(register, count, "D", nil)
      common.normal_bang(nil, 0, "O", nil)
    else
      common.normal_bang(register, count, "D", nil)
    end
    vc:save_register(register)
    vc:save_cursor_position()
  end)

end

local function _s()

  local register = vim.v.register

  -- Virtual cursors
  virtual_cursors.normal_mode_delete_yank(register, count, "d", "l")

  -- Real cursor
  local ve = vim.wo.ve
  vim.wo.ve = "onemore"
  common.normal_bang(register, count, "dl", nil)
  vim.wo.ve = ve

end

-- Callback for the mode changed event
function M.mode_changed()

  -- Move the cursor after the mode has changed
  if mode_cmd == nil then
    return
  -- Normal to insert mode
  elseif mode_cmd == "a" then _a()
  elseif mode_cmd == "A" then _A()
  elseif mode_cmd == "i" then _i()
  elseif mode_cmd == "I" then _I()
  elseif mode_cmd == "o" then _o()
  elseif mode_cmd == "O" then _O()
  -- Normal to visual
  elseif mode_cmd == "v" then _v()
  -- Normal change commands
  elseif mode_cmd == "c" then _c()
  elseif mode_cmd == "cc" then _cc()
  elseif mode_cmd == "C" then _C()
  elseif mode_cmd == "s" then _s()
  end

  count = nil
  mode_cmd = nil

end

function M.a()
  common.feedkeys(nil, 0, "a", nil)
  mode_cmd = "a"
end

function M.A()
  common.feedkeys(nil, 0, "A", nil)
  mode_cmd = "A"
end

function M.i() -- Also <Insert>
  common.feedkeys(nil, 0, "i", nil)
  mode_cmd = "i"
end

function M.I()
  common.feedkeys(nil, 0, "I", nil)
  mode_cmd = "I"
end

function M.o()
  common.feedkeys(nil, 0, "o", nil)
  mode_cmd = "o"
end

function M.O()
  common.feedkeys(nil, 0, "O", nil)
  mode_cmd = "O"
end

function M.v()
  common.feedkeys(nil, vim.v.count, "v", nil)
  count = vim.v.count - 1
  mode_cmd = "v"
end

function M.c()

  count = vim.v.count
  c_motion_cmd = input.get_motion_cmd()

  if c_motion_cmd == nil then
    count = nil
  else
    mode_cmd = "c"
    common.feedkeys(nil, 0, "i", nil)
  end

end

function M.cc()

  count = vim.v.count
  mode_cmd = "cc"
  common.feedkeys(nil, 0, "i", nil)

end

function M.C()

  count = vim.v.count
  mode_cmd = "C"
  common.feedkeys(nil, 0, "i", nil)

end

function M.s()

  count = vim.v.count
  mode_cmd = "s"
  common.feedkeys(nil, 0, "i", nil)

end

return M
