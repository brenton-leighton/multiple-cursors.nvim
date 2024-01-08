local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local input = require("multiple-cursors.input")
local move = require("multiple-cursors.move")
local normal_mode_change = require("multiple-cursors.normal_mode_change")

-- Indentation
function M.indent()
  common.feedkeys(nil, vim.v.count, ">>", nil)
  virtual_cursors.edit_with_normal_command(vim.v.count, ">>", nil)
end

function M.deindent()
  common.feedkeys(nil, vim.v.count, "<<", nil)
  virtual_cursors.edit_with_normal_command(vim.v.count, "<<", nil)
end

-- Join lines
function M.J()
  common.feedkeys(nil, vim.v.count, "J", nil)
  virtual_cursors.edit_with_normal_command(vim.v.count, "J", nil)
end

function M.gJ()
  common.feedkeys(nil, vim.v.count, "gJ", nil)
  virtual_cursors.edit_with_normal_command(vim.v.count, "gJ", nil)
end

-- Replace char
function M.r()
  local count = vim.v.count
  local char = input.get_char()

  if char ~= nil then
    common.feedkeys(nil, count, "r" .. char, nil)
    virtual_cursors.edit_with_normal_command(count, "r" .. char, nil)
  end
end

-- Delete in normal mode
function M.x() -- Also <Del>
  common.feedkeys(vim.v.register, vim.v.count, "x", nil)
  virtual_cursors.normal_mode_delete_yank(vim.v.register, vim.v.count, "x", nil)
end

function M.X()
  common.feedkeys(vim.v.register, vim.v.count, "X", nil)
  virtual_cursors.normal_mode_delete_yank(vim.v.register, vim.v.count, "X", nil)
end

function M.d()
  local count = vim.v.count
  local motion_cmd = input.get_motion_cmd()

  if motion_cmd ~= nil then
    common.feedkeys(vim.v.register, count, "d", motion_cmd)
    virtual_cursors.normal_mode_delete_yank(vim.v.register, count, "d", motion_cmd)
  end
end

function M.dd()
  common.feedkeys(vim.v.register, vim.v.count, "dd", nil)
  virtual_cursors.normal_mode_delete_yank(vim.v.register, vim.v.count, "dd", nil)
end

function M.D()
  common.feedkeys(vim.v.register, vim.v.count, "D", nil)
  virtual_cursors.normal_mode_delete_yank(vim.v.register, vim.v.count, "D", nil)
end

-- Switch case in normal mode
function M.gu()
  local count = vim.v.count
  local motion_cmd = input.get_motion_cmd()

  if motion_cmd ~= nil then
    common.feedkeys(nil, count, "gu", motion_cmd)
    virtual_cursors.edit_with_normal_command(count, "gu", motion_cmd)
  end
end

function M.gU()
  local count = vim.v.count
  local motion_cmd = input.get_motion_cmd()

  if motion_cmd ~= nil then
    common.feedkeys(nil, count, "gU", motion_cmd)
    virtual_cursors.edit_with_normal_command(count, "gU", motion_cmd)
  end
end

function M.g_tilde()
  local count = vim.v.count
  local motion_cmd = input.get_motion_cmd()

  if motion_cmd ~= nil then
    common.feedkeys(nil, count, "g~", motion_cmd)
    virtual_cursors.edit_with_normal_command(count, "g~", motion_cmd)
  end
end

-- Yank in normal mode
function M.y()
  local count = vim.v.count
  local motion_cmd = input.get_motion_cmd()

  if motion_cmd ~= nil then
    common.feedkeys(vim.v.register, count, "y", motion_cmd)
    virtual_cursors.normal_mode_delete_yank(vim.v.register, count, "y", motion_cmd)
  end
end

function M.yy()
  common.feedkeys(vim.v.register, vim.v.count, "yy", nil)
  virtual_cursors.normal_mode_delete_yank(vim.v.register, vim.v.count, "yy", nil)
end

-- Put in normal mode
function M.p()
  common.feedkeys(vim.v.register, vim.v.count, "p", nil)
  virtual_cursors.normal_mode_put(vim.v.register, vim.v.count, "p")
end

function M.P()
  common.feedkeys(vim.v.register, vim.v.count, "P", nil)
  virtual_cursors.normal_mode_put(vim.v.register, vim.v.count, "P")
end

return M
