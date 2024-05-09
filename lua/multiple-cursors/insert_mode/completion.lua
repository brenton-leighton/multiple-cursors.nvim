local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")

-- Delete a charater if in replace mode
local function delete_if_replace_mode(vc, num)
  if common.is_mode("R") or common.is_mode("Rc") then
    vim.cmd("normal! \"_" .. num .. "x")
  end
end

-- Return the completion word without the part that triggered the completion
local function crop_completion_word(line, col, word)

  -- Start from the longest possible length
  local length = vim.fn.min({col - 1, word:len()})

  while length > 0 do
    local l = line:sub(col-length, col-1)
    local w = word:sub(1, length)

    if l == w then
      return word:sub(length + 1)
    end

    length = length - 1
  end

  return word

end

-- Callback for the CompleteDonePre event
function M.complete_done_pre(event)

  local complete_info = vim.fn.complete_info()

  -- If an item has been selected
  if complete_info.selected >= 0 then

    -- Get the word
    local word = complete_info.items[complete_info.selected + 1].word

    virtual_cursors.edit_with_cursor(function(vc)

      -- Remove the part of the word that triggered the completion
      local line = vim.fn.getline(vc.lnum)
      local cropped_word = crop_completion_word(line, vc.col, word)

      -- Delete characters for replace mode
      delete_if_replace_mode(vc, cropped_word:len())

      vim.api.nvim_put({cropped_word}, "c", false, true)

    end)

  end

end

return M
