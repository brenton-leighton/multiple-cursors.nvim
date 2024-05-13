local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")

-- Normal mode backspace command for a virtual cursor
local function backspace_one_virtual_cursor(vc, count1)

  while count1 > 0 do

    -- No line change
    if vc.col > count1 then
      vc.col = vc.col - count1
      vc.curswant = vc.col
      return
    end

    -- First line, go to first column
    if vc.lnum == 1 then
      vc.col = 1
      vc.curswant = vc.col
      return
    end

    count1 = count1 - vc.col
    vc.lnum = vc.lnum - 1
    vc.col = common.get_max_col(vc.lnum)
  end

  vc.curswant = vc.col

end

-- Normal mode backspace command for all virtual cursors
local function backspace_all_virtual_cursors(count)
  local count1 = vim.fn.max({count, 1})

  virtual_cursors.visit_all(function(vc)
    backspace_one_virtual_cursor(vc, count1)
  end)

end

-- Backspace
function M.bs()
  local count = vim.v.count
  backspace_all_virtual_cursors(count)
  common.feedkeys(nil, count, "<BS>", nil)
end

return M
