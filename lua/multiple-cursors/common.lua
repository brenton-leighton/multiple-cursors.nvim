local M = {}

-- Execute a command with normal!
-- register and motion_cmd may be nil
-- count may be 0
-- motion_cmd may also contain a count
function M.normal_bang(register, count, cmd, motion_cmd)

  -- Command string
  local str = ""

  if register then
    str = str .. "\"" .. register
  end

  if count ~= 0 then
    str = str .. count
  end

  str = str .. cmd

  if motion_cmd then
    str = str .. motion_cmd
  end

  vim.cmd("normal! " .. str)

end

-- Abstraction of nvim_feedkeys
-- register and motion_cmd may be nil
-- count may be 0
-- motion_cmd may also contain a count
function M.feedkeys(register, count, cmd, motion_cmd)

  -- Command string
  local str = ""

  if register then
    str = str .. "\"" .. register
  end

  if count ~= 0 then
    str = str .. count
  end

  str = str .. cmd

  if motion_cmd then
    str = str .. motion_cmd
  end

  local tmp = vim.api.nvim_replace_termcodes(str, true, false, true)
  vim.api.nvim_feedkeys(tmp, "n", false)

end

-- Check if mode is given mode
function M.is_mode(mode)
  return vim.api.nvim_get_mode().mode == mode
end

-- Check if mode is insert or replace
function M.is_mode_insert_replace()
  local mode = vim.api.nvim_get_mode().mode
  return mode == "i" or mode == "ic"  or mode == "R" or mode == "Rc"
end

-- Number of characters in a line
function M.get_length_of_line(lnum)
  return vim.fn.col({lnum, "$"}) - 1
end

-- Maximum column position for a line
function M.get_max_col(lnum)
  -- In normal mode the maximum column position is one less than other modes,
  -- except if the line is empty
  if M.is_mode("n") then
    return vim.fn.max({M.get_length_of_line(lnum), 1})
  else
    return M.get_length_of_line(lnum) + 1
  end
end

-- Limit col to line length
function M.limit_col(lnum, col)
  return vim.fn.min({M.get_max_col(lnum), col})
end

-- Get a column position for a given curswant
function M.curswant2col(lnum, curswant)
  local col = vim.fn.virtcol2col(0, lnum, curswant)
  return M.limit_col(lnum, col)
end

-- Is lnum, col before the first non-whitespace character
function M.is_before_first_non_whitespace_char(lnum, col)
  local idx = vim.fn.match(vim.fn.getline(lnum), "\\S")
  if idx < 0 then
    return true
  else
    return col <= idx + 1
  end
end

-- Get current visual area
-- Returns v_lnum, v_col, lnum, col, curswant
function M.get_visual_area()
  local vpos = vim.fn.getpos("v")
  local cpos = vim.fn.getcurpos()
  return vpos[2], vpos[3], cpos[2], cpos[3], cpos[5]
end

-- Get current visual area in a forward direction
-- returns lnum1, col1, lnum2, col2
function M.get_normalised_visual_area()

  local v_lnum, v_col, lnum, col = M.get_visual_area()

  -- Normalise
  if v_lnum < lnum then
    return v_lnum, v_col, lnum, col
  elseif lnum < v_lnum then
    return lnum, col, v_lnum, v_col
  else -- v_lnum == lnum
    if v_col <= col then
      return v_lnum, v_col, lnum, col
    else -- col < v_col
      return lnum, col, v_lnum, v_col
    end
  end

end

-- Set visual area marks and apply
function M.set_visual_area(v_lnum, v_col, lnum, col)
  vim.api.nvim_buf_set_mark(0, "<", v_lnum, v_col - 1, {})
  vim.api.nvim_buf_set_mark(0, ">", lnum, col - 1, {})
  vim.cmd("normal! gv")
end

return M
