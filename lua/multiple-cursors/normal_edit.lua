local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local input = require("multiple-cursors.input")
local normal_to_insert = require("multiple-cursors.normal_to_insert")
local move = require("multiple-cursors.move")

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

-- Replace char
function M.r()
  local count = vim.v.count
  local char = input.get_char()

  if char ~= nil then
    common.feedkeys("r" .. char, count)
    virtual_cursors.edit_with_normal_command("r" .. char, vim.v.count)
  end
end

-- Delete in normal mode
function M.x() -- Also <Del>
  common.feedkeys("x", vim.v.count)
  virtual_cursors.edit_normal_delete_yank("x", vim.v.count)
end

function M.X()
  common.feedkeys("X", vim.v.count)
  virtual_cursors.edit_normal_delete_yank("X", vim.v.count)
end

function M.d()
  local count = vim.v.count
  local motion_cmd = input.get_motion_char()

  if motion_cmd ~= nil then
    virtual_cursors.edit_normal_delete_yank("d" .. motion_cmd, count)
    common.feedkeys("d" .. motion_cmd, count)
  end
end

function M.dd()
  common.feedkeys("dd", vim.v.count)
  virtual_cursors.edit_normal_delete_yank("dd", vim.v.count)
end

function M.D()
  common.feedkeys("D", vim.v.count)
  virtual_cursors.edit_normal_delete_yank("D", vim.v.count)
end

-- Change in normal mode
function M.s()
  -- When set virtualedit to onemore,
  -- the cursor will be placed one character after the end of the line
  -- if it delete all content right 
  local orig_ve = vim.wo.ve
  vim.wo.ve = "onemore"

	M.x()
  normal_to_insert.i()

  -- feedkeys are consumed asynchronously,
  -- with option x will case exit insert mode
  vim.api.nvim_create_autocmd("InsertEnter",{
    once = true,
    callback = function ()
      vim.wo.ve = orig_ve
    end
  })
end

function M.c()
  local orig_ve = vim.wo.ve
  vim.wo.ve = "onemore"

  M.d()
  normal_to_insert.i()

  vim.api.nvim_create_autocmd("InsertEnter",{
    once = true,
    callback = function ()
      vim.wo.ve = orig_ve
    end
  })
end

function M.cc()
  move.normal_0()
  M.D()
  normal_to_insert.i()
end

function M.C()
  -- use to solve cursor blinking
  local orig_ve = vim.wo.ve
  vim.wo.ve = "onemore"

  M.D()
  normal_to_insert.a()

  vim.api.nvim_create_autocmd("InsertEnter",{
    once = true,
    callback = function ()
      vim.wo.ve = orig_ve
    end
  })
end

-- Switch case in normal mode
function M.gu()
  local count = vim.v.count
  local motion_cmd = input.get_motion_char()

  if motion_cmd ~= nil then
    virtual_cursors.edit_with_normal_command("gu" .. motion_cmd, count)
    common.feedkeys("gu" .. motion_cmd, count)
  end
end

function M.gU()
  local count = vim.v.count
  local motion_cmd = input.get_motion_char()

  if motion_cmd ~= nil then
    virtual_cursors.edit_with_normal_command("gU" .. motion_cmd, count)
    common.feedkeys("gU" .. motion_cmd, count)
  end
end

function M.g_tilde()
  local count = vim.v.count
  local motion_cmd = input.get_motion_char()

  if motion_cmd ~= nil then
    virtual_cursors.edit_with_normal_command("g~" .. motion_cmd, count)
    common.feedkeys("g~" .. motion_cmd, count)
  end
end

-- Yank in normal mode
function M.y()
  local count = vim.v.count
  local motion_cmd = input.get_motion_char()

  if motion_cmd ~= nil then
    virtual_cursors.edit_normal_delete_yank("y" .. motion_cmd, count)
    common.feedkeys("y" .. motion_cmd, count)
  end
end

function M.yy()
  common.feedkeys("yy", vim.v.count)
  virtual_cursors.edit_normal_delete_yank("yy", vim.v.count)
end

-- Put in normal mode
function M.p()
  common.feedkeys("p", vim.v.count)
  virtual_cursors.edit_normal_put("p", vim.v.count)
end

function M.P()
  common.feedkeys("P", vim.v.count)
  virtual_cursors.edit_normal_put("P", vim.v.count)
end

return M
