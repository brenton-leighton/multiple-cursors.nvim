local M = {}

-- Execute a command with normal!
function M.normal_bang(cmd, count)
  if count == 0 then
    vim.cmd("normal! " .. cmd)
  else
    vim.cmd("normal! " .. tostring(count) .. cmd)
  end
end

function M.normal_bang_with_register(register, cmd, count)
  if count == 0 then
    vim.cmd("normal! \"" .. register .. cmd)
  else
    vim.cmd("normal! \"" .. register .. tostring(count) .. cmd)
  end
end

-- Wrapper around nvim_feedkeys
function M.feedkeys(cmd, count)

  if count ~= 0 then
    vim.api.nvim_feedkeys(tostring(count), "n", false)
  end

  local key = vim.api.nvim_replace_termcodes(cmd, true, false, true)
  vim.api.nvim_feedkeys(key, "n", false)

end

function M.feedkeys_with_register(register, cmd, count)
  local key = vim.api.nvim_replace_termcodes("\"" .. register, true, false, true)
  vim.api.nvim_feedkeys(key, "n", false)

  M.feedkeys(cmd, count)
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

-- Get a column position for a given curswant
function M.get_col(lnum, curswant)
  return vim.fn.min({M.get_max_col(lnum), curswant})
end

-- Get current visual area
-- Returns {lnum1, col1, lnum2, col2}
function M.get_visual_area()
  local cursor_pos = vim.fn.getcurpos()
  local visual_start_pos = vim.fn.getpos("v")
  return {visual_start_pos[2], visual_start_pos[3], cursor_pos[2], cursor_pos[3]}
end

return M
