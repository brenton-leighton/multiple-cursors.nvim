local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")

-- Character to insert
local char = nil

-- Callback for InsertCharPre event
function M.insert_char_pre(event)
  -- Save the inserted character
  char = vim.v.char
end

-- Callback for the TextChangedI event
function M.text_changed_i(event)

  -- If there's a saved character
  if char then
    -- Put it to virtual cursors
    virtual_cursors.edit_with_cursor(function(vc)

      -- Delete a character if in replace mode
      if common.is_mode("R") then
        vim.cmd("normal! \"_x")
      end

      -- Put the character
      vim.api.nvim_put({char}, "c", false, true)
    end)
    char = nil
  end

end

return M
