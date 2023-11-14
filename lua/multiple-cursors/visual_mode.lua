local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")

function M.escape()
  virtual_cursors.visit_in_buffer(
  function(vc)
    -- Move cursor back if it's at the end of a non empty line
    vc.col = vim.fn.min({vc.col, common.get_max_col(vc.lnum) - 1})
    vc.col = vim.fn.max({vc.col, 1})
  end)
end

function M.o()
  common.feedkeys("o", 0)
  virtual_cursors.visual_other()
end

function M.y()
  common.feedkeys("y", 0)
  virtual_cursors.visual_yank()
end

function M.d()
  common.feedkeys("d", 0)
  virtual_cursors.visual_delete()
end

return M
