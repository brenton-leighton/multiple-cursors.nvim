local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")

-- Indicate that the completion word has already been inserted before complete_done_pre
local completed = false

-- Get the number of characters to delete before the cursor, and after for
-- replace mode
-- Returns num_before, num_after
local function get_lengths(line, col, word)

  local word_length = word:len()

  -- Start from the longest possible length
  local num_before = vim.fn.min({col - 1, word_length})

  while num_before > 0 do
    local l = line:sub(col-num_before, col-1)
    local w = word:sub(1, num_before)

    -- Case insensitive comparison
    if l:lower() == w:lower() then
      break
    end

    num_before = num_before - 1
  end

  return num_before, (word_length - num_before)

end

-- Insert the completion word if selected
-- Used directly by insert mode mappings or by complete_done_pre
-- Returns true if a completion item was inserted, and false if not
function M.complete_if_selected()

  local complete_info = vim.fn.complete_info()

  -- If an item has been selected
  if complete_info.selected >= 0 then

    -- Get the word
    local word = complete_info.items[complete_info.selected + 1].word

    virtual_cursors.edit_with_cursor(function(vc)

      -- Remove the part of the word that triggered the completion
      local line = vim.fn.getline(vc.lnum)

      local num_before, num_after = get_lengths(line, vc.col, word)

      -- Delete any characters before the cursor that belong to the completion word
      if num_before > 0 then
        vim.cmd("normal! \"_" .. num_before .. "X")
      end

      -- Delete characters after the cursor for replace mode
      if common.is_mode("R") or common.is_mode("Rc") then
        if num_after > 0 then
          vim.cmd("normal! \"_" .. num_after .. "x")
        end
      end

      -- Put the completion word
      vim.api.nvim_put({word}, "c", false, true)

    end)

    completed = true

    return true

  end

  return false

end

-- Callback for the CompleteDonePre event
function M.complete_done_pre(event)

  if not completed then
    M.complete_if_selected()
  end

  completed = false

end

return M
