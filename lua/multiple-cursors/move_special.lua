local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")

-- Normal mode backspace command for a vritual cursor
local function virtual_cursor_normal_backspace(vc, count)

  while count > 0 do

    -- No line change
    if vc.col > count then
      vc.col = vc.col - count
      vc.curswant = vc.col
      return
    end

    -- First line, go to first column
    if vc.lnum == 1 then
      vc.col = 1
      vc.curswant = vc.col
      return
    end

    count = count - vc.col
    vc.lnum = vc.lnum - 1
    vc.col = common.get_max_col(vc.lnum)
  end

  vc.curswant = vc.col

end

-- Normal mode backspace command for all virtual cursors
local function all_virtual_cursors_normal_backspace(count)
  count = vim.fn.max({count, 1})
  virtual_cursors.visit_in_buffer(function(vc) virtual_cursor_normal_backspace(vc, count) end)
end

-- Normal mode backspace command
function M.normal_bs()
  common.feedkeys(nil, vim.v.count, "<BS>", nil)
  all_virtual_cursors_normal_backspace(vim.v.count)
end

return M
