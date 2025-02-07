local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")

function M.escape()

  virtual_cursors.visit_all_ignore_lock(function(vc)
    -- Move cursor back if it's at the end of a non empty line
    vc.col = vim.fn.min({vc.col, common.get_max_col(vc.lnum) - 1})
    vc.col = vim.fn.max({vc.col, 1})

    -- Clear visual area
    vc.visual_start_lnum = 0
    vc.visual_start_col = 0
  end)

  common.feedkeys(nil, 0, "<Esc>", nil)

end

return M
