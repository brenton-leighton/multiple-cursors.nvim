local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")

function M.d()
  virtual_cursors.visual_mode_delete_yank(vim.v.register, "d")
  common.feedkeys(vim.v.register, 0, "d", nil)
end

function M.y()
  virtual_cursors.visual_mode_delete_yank(vim.v.register, "y")
  common.feedkeys(vim.v.register, 0, "y", nil)
end

-- Delete and switch to insert mode
function M.c()
  virtual_cursors.visual_mode_delete_yank(vim.v.register, "d")
  common.feedkeys(vim.v.register, 0, "d", nil)
  common.feedkeys(nil, 0, "i", nil)
end

return M
