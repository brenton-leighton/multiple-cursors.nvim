local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")

local enable_split_paste = nil
local original_paste_function = nil

function M.setup(_enable_split_paste)
  enable_split_paste = _enable_split_paste
end

-- Paste in normal mode for a virtual cursor
local function virtual_cursor_normal_mode_paste(lines, vc)
  local move_afterwards = vc.col < common.get_max_col(vc.lnum)

  -- Put the line(s) after the cursor
  vim.api.nvim_put(lines, "c", true, true)

  if move_afterwards then
    vim.cmd("normal! h")
  end
end

-- Paste in insert mode for a virtual cursor
local function virtual_cursor_insert_mode_paste(lines, vc)
  -- Put the line(s) before the cursor
  vim.api.nvim_put(lines, "c", false, true)
end

-- Paste in replace mode for a virtual cursor
local function virtual_cursor_replace_mode_paste(lines, vc)

  -- If the cursor is at the end of the line
  if vc.col == common.get_max_col(vc.lnum) then
    -- Put paste lines before the cursor
    vim.api.nvim_put(lines, "c", false, false)
  else -- Cursor not at the end of the line
    -- If there are multiple paste lines
    if #lines ~= 1 then
      -- Delete to the end of the line and put paste lines after the cursor
      vim.cmd("normal! \"_D")
      vim.api.nvim_put(lines, "c", true, false)
    else -- Single paste line
      local paste_line_length = #lines[1]
      local overwrite_length = common.get_length_of_line(vc.lnum) - vc.col + 1

      -- The length of the paste line is less than being overwritten
      if paste_line_length < overwrite_length then
        -- Delete the paste line length and put the paste line before the cursor
        vim.cmd("normal! \"_" .. tostring(paste_line_length) .. "dl")
        vim.api.nvim_put(lines, "c", false, false)
      else
        -- Delete to the end of the line and put paste line after the cursor
        vim.cmd("normal! \"_D")
        vim.api.nvim_put(lines, "c", true, false)
      end
    end
  end

end

local function virtual_cursor_visual_mode_paste(lines, vc)

end

-- For split pasting, reorder the given lines to match the postional order of
-- the cursors
-- The line for the real cursor is last
-- This function should only be used when the number of lines is one less than
-- the number of editable virtual cursors within the buffer
local function reorder_lines_for_split_pasting(lines)

  local indices = virtual_cursors.get_cursor_order()

  local real_cursor_line = nil

  local new_lines = {}

  for lines_idx = 1, #indices do
    local cursor_idx = indices[lines_idx]

    if cursor_idx == 0 then
      real_cursor_line = lines[lines_idx]
    else
      table.insert(new_lines, lines[lines_idx])
    end
  end

  table.insert(new_lines, real_cursor_line)

  return new_lines

end

-- Paste handler
local function paste(lines)

  local split_paste = enable_split_paste and virtual_cursors.can_split_paste(#lines)

  if split_paste then
    -- Reorder lines
    lines = reorder_lines_for_split_pasting(lines)
  end

  if common.is_mode("n") then

    virtual_cursors.paste(lines, function(lines, vc)
      virtual_cursor_normal_mode_paste(lines, vc)
    end, split_paste, true)

  elseif common.is_mode("i") then

    virtual_cursors.paste(lines, function(lines, vc)
      virtual_cursor_insert_mode_paste(lines, vc)
    end, split_paste, true)

  elseif common.is_mode("R") then

    virtual_cursors.paste(lines, function(lines, vc)
      virtual_cursor_replace_mode_paste(lines, vc)
    end, split_paste, false)

  elseif common.is_mode("x") then
    vim.print("visual")
  else
    vim.print("Error: unknown mode")
  end

  if split_paste then
    -- Return the last line for pasting to the real cursor
    return {lines[#lines]}
  else
    -- Return the original lines for pasting to the real cursor
    return lines
  end

end

-- Override the paste handler
function M.override_handler()

  -- Save the original paste handler
  original_paste_function = vim.paste

  -- Override
  vim.paste = (function(overridden)
      return function(lines, phase)
        return overridden(paste(lines), phase)
      end
  end)(vim.paste)
end

-- Revert the paste handler
function M.revert_handler()
  vim.paste = original_paste_function
end

return M
