local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local input = require("multiple-cursors.input")

-- Delete and yank
local function normal_mode_delete_yank_and_feedkeys(cmd)
  local register = vim.v.register
  local count = vim.v.count
  virtual_cursors.normal_mode_delete_yank(register, count, cmd, nil)
  common.feedkeys(register, count, cmd, nil)
end

function M.x() normal_mode_delete_yank_and_feedkeys("x") end
function M.X() normal_mode_delete_yank_and_feedkeys("X") end
function M.dd() normal_mode_delete_yank_and_feedkeys("dd") end
function M.D() normal_mode_delete_yank_and_feedkeys("D") end
function M.yy() normal_mode_delete_yank_and_feedkeys("yy") end

-- For d and y
local function normal_mode_delete_yank_and_feedkeys_with_motion(cmd)

  local register = vim.v.register
  local count = vim.v.count

  local motion_cmd = input.get_motion_cmd()

  if motion_cmd ~= nil then
    virtual_cursors.normal_mode_delete_yank(register, count, cmd, motion_cmd)
    common.feedkeys(register, count, cmd, motion_cmd)
  end

end

function M.d() normal_mode_delete_yank_and_feedkeys_with_motion("d") end
function M.y() normal_mode_delete_yank_and_feedkeys_with_motion("y") end

-- Put
local function normal_mode_put_and_feedkeys(cmd)
  local register = vim.v.register
  local count = vim.v.count
  virtual_cursors.normal_mode_put(register, count, cmd)
  common.feedkeys(register, count, cmd, nil)
end

function M.p() normal_mode_put_and_feedkeys("p") end
function M.P() normal_mode_put_and_feedkeys("P") end

return M
