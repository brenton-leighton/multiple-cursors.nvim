local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local input = require("multiple-cursors.input")

-- Indentation
function M.indent()
  common.feedkeys(">>", vim.v.count)
  virtual_cursors.edit_with_normal_command(">>", vim.v.count)
end

function M.deindent()
  common.feedkeys("<<", vim.v.count)
  virtual_cursors.edit_with_normal_command("<<", vim.v.count)
end

-- Join lines
function M.J()
  common.feedkeys("J", vim.v.count)
  virtual_cursors.edit_with_normal_command("J", vim.v.count)
end

function M.gJ()
  common.feedkeys("gJ", vim.v.count)
  virtual_cursors.edit_with_normal_command("gJ", vim.v.count)
end

-- Delete in normal mode
function M.x() -- Also <Del>
  common.feedkeys("x", vim.v.count)
  virtual_cursors.normal_mode_delete_yank("x", vim.v.count)
end

function M.X()
  common.feedkeys("X", vim.v.count)
  virtual_cursors.normal_mode_delete_yank("X", vim.v.count)
end

function M.d()
  local count = vim.v.count
  local motion_cmd = input.get_motion_char()

  if motion_cmd ~= nil then
    virtual_cursors.normal_mode_delete_yank("d" .. motion_cmd, count)
    common.feedkeys("d" .. motion_cmd, count)
  end
end

function M.dd()
  common.feedkeys("dd", vim.v.count)
  virtual_cursors.normal_mode_delete_yank("dd", vim.v.count)
end

function M.D()
  common.feedkeys("D", vim.v.count)
  virtual_cursors.normal_mode_delete_yank("D", vim.v.count)
end

-- Yank in normal mode
function M.y()
  local count = vim.v.count
  local motion_cmd = input.get_motion_char()

  if motion_cmd ~= nil then
    virtual_cursors.normal_mode_delete_yank("y" .. motion_cmd, count)
    common.feedkeys("y" .. motion_cmd, count)
  end
end

function M.yy()
  common.feedkeys("yy", vim.v.count)
  virtual_cursors.normal_mode_delete_yank("yy", vim.v.count)
end

-- Put in normal mode
function M.p()
  common.feedkeys("p", vim.v.count)
  virtual_cursors.normal_mode_put("p", vim.v.count)
end

function M.P()
  common.feedkeys("P", vim.v.count)
  virtual_cursors.normal_mode_put("P", vim.v.count)
end

return M
