local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local input = require("multiple-cursors.input")
local move = require("multiple-cursors.move")
local normal_mode_change = require("multiple-cursors.normal_mode_change")

-- Indentation
function M.indent()
  common.feedkeys(">>", vim.v.count)
  virtual_cursors.edit_with_normal_command(vim.v.count, ">>", nil)
end

function M.deindent()
  common.feedkeys("<<", vim.v.count)
  virtual_cursors.edit_with_normal_command(vim.v.count, "<<", nil)
end

-- Join lines
function M.J()
  common.feedkeys("J", vim.v.count)
  virtual_cursors.edit_with_normal_command(vim.v.count, "J", nil)
end

function M.gJ()
  common.feedkeys("gJ", vim.v.count)
  virtual_cursors.edit_with_normal_command(vim.v.count, "gJ", nil)
end

-- Replace char
function M.r()
  local count = vim.v.count
  local char = input.get_char()

  if char ~= nil then
    common.feedkeys("r" .. char, count)
    virtual_cursors.edit_with_normal_command(vim.v.count, "r" .. char, nil)
  end
end

-- Delete in normal mode
function M.x() -- Also <Del>
  common.feedkeys_with_register(vim.v.register, "x", vim.v.count)
  virtual_cursors.normal_mode_delete_yank(vim.v.register, "x", vim.v.count)
end

function M.X()
  common.feedkeys_with_register(vim.v.register, "X", vim.v.count)
  virtual_cursors.normal_mode_delete_yank(vim.v.register, "X", vim.v.count)
end

function M.d()
  local count = vim.v.count
  local motion_cmd = input.get_motion_cmd()

  if motion_cmd ~= nil then
    common.feedkeys_with_register(vim.v.register, "d" .. motion_cmd, count)
    virtual_cursors.normal_mode_delete_yank(vim.v.register, "d" .. motion_cmd, count)
  end
end

function M.dd()
  common.feedkeys_with_register(vim.v.register, "dd", vim.v.count)
  virtual_cursors.normal_mode_delete_yank(vim.v.register, "dd", vim.v.count)
end

function M.D()
  common.feedkeys_with_register(vim.v.register, "D", vim.v.count)
  virtual_cursors.normal_mode_delete_yank(vim.v.register, "D", vim.v.count)
end

-- Switch case in normal mode
function M.gu()
  local count = vim.v.count
  local motion_cmd = input.get_motion_cmd()

  if motion_cmd ~= nil then
    common.feedkeys("gu" .. motion_cmd, count)
    virtual_cursors.edit_with_normal_command(count, "gu", motion_cmd)
  end
end

function M.gU()
  local count = vim.v.count
  local motion_cmd = input.get_motion_cmd()

  if motion_cmd ~= nil then
    common.feedkeys("gU" .. motion_cmd, count)
    virtual_cursors.edit_with_normal_command(count, "gU", motion_cmd)
  end
end

function M.g_tilde()
  local count = vim.v.count
  local motion_cmd = input.get_motion_cmd()

  if motion_cmd ~= nil then
    common.feedkeys("g~" .. motion_cmd, count)
    virtual_cursors.edit_with_normal_command(count, "g~", motion_cmd)
  end
end

-- Yank in normal mode
function M.y()
  local count = vim.v.count
  local motion_cmd = input.get_motion_cmd()

  if motion_cmd ~= nil then
    common.feedkeys_with_register(vim.v.register, "y" .. motion_cmd, count)
    virtual_cursors.normal_mode_delete_yank(vim.v.register, "y" .. motion_cmd, count)
  end
end

function M.yy()
  common.feedkeys_with_register(vim.v.register, "yy", vim.v.count)
  virtual_cursors.normal_mode_delete_yank(vim.v.register, "yy", vim.v.count)
end

-- Put in normal mode
function M.p()
  common.feedkeys_with_register(vim.v.register, "p", vim.v.count)
  virtual_cursors.normal_mode_put(vim.v.register, "p", vim.v.count)
end

function M.P()
  common.feedkeys_with_register(vim.v.register, "P", vim.v.count)
  virtual_cursors.normal_mode_put(vim.v.register, "P", vim.v.count)
end

return M
