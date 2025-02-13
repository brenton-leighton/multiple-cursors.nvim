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

-- Put
local function visual_mode_put_and_feedkeys(cmd)
  local register = vim.v.register
  local count = vim.v.count
  virtual_cursors.visual_mode_put(register, count, cmd)
  common.feedkeys(register, count, cmd, nil)
end

function M.p() visual_mode_put_and_feedkeys("p") end
function M.P() visual_mode_put_and_feedkeys("P") end

return M
