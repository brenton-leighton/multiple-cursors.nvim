local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")

local function normal_command_and_feedkeys(cmd)
  local count = vim.v.count

  virtual_cursors.visual_mode(function()
    common.normal_bang(nil, count, cmd, nil)
  end)

  common.feedkeys(nil, count, cmd, nil)
end

-- Indentation
function M.indent() normal_command_and_feedkeys("<") end
function M.deindent() normal_command_and_feedkeys(">") end

-- Join lines
function M.J() normal_command_and_feedkeys("J") end
function M.gJ() normal_command_and_feedkeys("gJ") end

-- Change case
function M.u() normal_command_and_feedkeys("u") end
function M.U() normal_command_and_feedkeys("U") end
function M.tilde() normal_command_and_feedkeys("~") end
function M.gu() normal_command_and_feedkeys("gu") end
function M.gU() normal_command_and_feedkeys("gU") end
function M.g_tilde() normal_command_and_feedkeys("g~") end

return M
