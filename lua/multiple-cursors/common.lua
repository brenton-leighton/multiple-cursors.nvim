local M = {}

function M.feedkeys(cmd, count)

  if count ~= 0 then
    vim.api.nvim_feedkeys(tostring(count), "n", false)
  end

  local key = vim.api.nvim_replace_termcodes(cmd, true, false, true)
  vim.api.nvim_feedkeys(key, "n", false)

end

-- Check if mode is given mode
function M.is_mode(mode)
  return vim.api.nvim_get_mode().mode == mode
end

-- Check if mode is insert or replace
function M.is_mode_insert_replace()
  local mode = vim.api.nvim_get_mode().mode
  return mode == "i" or mode == "R"
end

-- Number of characters in a line
function M.get_length_of_line(lnum)
  return vim.fn.charcol({lnum, "$"}) - 1
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

-- Get a column position for a given curswant
function M.get_col(lnum, curswant)
  return vim.fn.min({M.get_max_col(lnum), curswant})
end

-- Set the real cursor position to the virtual cursor
function M.set_cursor_to_virtual_cursor(vc)
  vim.fn.setcursorcharpos({vc.lnum, vc.col, 0, vc.curswant})
end

-- Set a virtual cursor position from the real cursor
function M.set_virtual_cursor_from_cursor(vc)
  local pos = vim.fn.getcursorcharpos()

  vc.lnum = pos[2]
  vc.col = pos[3]
  vc.curswant = pos[5]
end

function M.is_visual_area_valid(vc)

  if vc.visual_start_lnum == 0 or vc.visual_start_col == 0 then
    return false
  end

  if vc.visual_start_lnum > vim.fn.line("$") then
    return false
  end

  return true

end

-- Is the visual area defined in a forward direction?
function M.is_visual_area_forward(vc)
  if vc.visual_start_lnum == vc.lnum then
    return vc.visual_start_col < vc.col
  else
    return vc.visual_start_lnum < vc.lnum
  end
end

-- Get the positions of the visual area in a forward direction
function M.get_normalised_visual_area(vc)
  -- Get start and end positions for the extmarks representing the visual area
  local lnum1 = vc.visual_start_lnum
  local col1 = vc.visual_start_col
  local lnum2 = vc.lnum
  local col2 = vc.col

  if not M.is_visual_area_forward(vc) then
    lnum1 = vc.lnum
    col1 = vc.col
    lnum2 = vc.visual_start_lnum
    col2 = vc.visual_start_col
  end

  return lnum1, col1, lnum2, col2
end

return M
