local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")

local enable_split_paste = nil
local original_paste_function = nil

function M.setup(_enable_split_paste)
  enable_split_paste = _enable_split_paste
end

-- Override the paste handler
function M.override_handler()

  -- Save the original paste handler
  original_paste_function = vim.paste

  -- Override
  vim.paste = (function(overridden)
      return function(lines, phase)
        if enable_split_paste and
            #lines == virtual_cursors.get_num_editable_cursors() + 1 then
          local line = split_paste(lines)
          return overridden({line}, phase)
        else
          paste(lines)
          return overridden(lines, phase)
        end
      end
  end)(vim.paste)
end

-- Revert the paste handler
function M.revert_handler()
  vim.paste = original_paste_function
end

-- Paste line(s) at a virtual cursor in insert mode
local function virtual_cursor_insert_paste(lines, vc)
  -- Put the line(s) before the cursor
  vim.api.nvim_put(lines, "c", false, true)
end

-- Paste line(s) at a virtual cursor in replace mode
local function virtual_cursor_replace_paste(lines, vc)

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

-- Paste
function paste(lines)
  if common.is_mode("R") then
    virtual_cursors.edit(function(vc)
      virtual_cursor_replace_paste(lines, vc)
    end, false)
  else
    virtual_cursors.edit(function(vc)
      virtual_cursor_insert_paste(lines, vc)
    end, true)
  end
end

-- Split the paste lines so that one is put to each cursor
-- The final line for the real cursor is returned
function split_paste(lines)
  if common.is_mode("R") then
    return virtual_cursors.split_paste(lines, virtual_cursor_replace_paste, false)
  end
    return virtual_cursors.split_paste(lines, virtual_cursor_insert_paste, true)
end

return M
