local M = {}

local virtual_cursors = require("multiple-cursors.virtual_cursors")
local insert_mode = require("multiple-cursors.insert_mode")

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
          local line = insert_mode.split_paste(lines)
          return overridden({line}, phase)
        else
          insert_mode.paste(lines)
          return overridden(lines, phase)
        end
      end
  end)(vim.paste)
end

-- Revert the paste handler
function M.revert_handler()
  vim.paste = original_paste_function
end

return M
