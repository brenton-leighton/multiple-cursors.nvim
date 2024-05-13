local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local input = require("multiple-cursors.input")

-- Replace char
function M.r()
  local count = vim.v.count
  local char = input.get_char()

  if char ~= nil then
    virtual_cursors.edit_with_normal_command(count, "r" .. char, nil)
    common.feedkeys(nil, count, "r" .. char, nil)
  end
end

local function normal_command_and_feedkeys(cmd)
  local count = vim.v.count
  virtual_cursors.edit_with_normal_command(count, cmd, nil)
  common.feedkeys(nil, count, cmd, nil)
end

function M.indent() normal_command_and_feedkeys(">>") end
function M.deindent() normal_command_and_feedkeys("<<") end
function M.J() normal_command_and_feedkeys("J") end
function M.gJ() normal_command_and_feedkeys("gJ") end
function M.dot() normal_command_and_feedkeys(".") end

local function normal_command_and_feedkeys_with_motion(cmd)

  local count = vim.v.count

  local motion_cmd = input.get_motion_cmd()

  if motion_cmd ~= nil then
    virtual_cursors.edit_with_normal_command(count, cmd, motion_cmd)
    common.feedkeys(nil, count, cmd, motion_cmd)
  end

end

function M.gu() normal_command_and_feedkeys_with_motion("gu") end
function M.gU() normal_command_and_feedkeys_with_motion("gU") end
function M.g_tilde() normal_command_and_feedkeys_with_motion("g~") end

return M
