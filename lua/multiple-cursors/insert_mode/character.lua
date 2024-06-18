local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local insert_mode_completion = require("multiple-cursors.insert_mode.completion")

-- Character(s) to insert
local char = nil

-- Callback for InsertCharPre event, stores vim.v.char
function M.insert_char_pre(event)

  -- If there's already a char
  if char then
    -- Append
    char = char .. vim.v.char
  else
    char = vim.v.char
  end

end

-- Callback for the TextChangedI event
function M.text_changed_i(event)

  -- If there's a saved character
  if char then

    -- If there's only a single character
    if char:len() == 1 then
      -- Put it to virtual cursors
      virtual_cursors.edit_with_cursor(function(vc)

        -- Delete a character if in replace mode
        if common.is_mode("R") then
          vim.cmd("normal! \"_x")
        end

        -- Put the character
        vim.api.nvim_put({char}, "c", false, true)
      end)
    else -- Multiple characters
      -- Assume nvim-cmp
      insert_mode_completion.complete(char)
    end

    char = nil

  end

end

return M
