local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local input = require("multiple-cursors.input")

-- Escape command
function M.escape()
  virtual_cursors.visit_in_buffer(function(vc)
    -- Move cursor back if it's at the end of a non empty line
    vc.col = vim.fn.min({vc.col, common.get_max_col(vc.lnum) - 1})
    vc.col = vim.fn.max({vc.col, 1})

    -- Clear visual area
    vc.visual_start_lnum = 0
    vc.visual_start_col = 0
  end)
end


-- Modify visual area ----------------------------------------------------------

local function modify_area(cmd)
  local count = vim.v.count

  virtual_cursors.visual_mode(function()
    common.normal_bang(nil, count, cmd, nil)
  end)

  common.feedkeys(nil, count, cmd, nil)
end

-- o command
function M.o()
  modify_area("o")
end

-- "a" text object selection commands
function M.a()
  local char2 = input.get_text_object_sel_second_char()

  if char2 then
    modify_area("a" .. char2)
  end

  return
end

-- "i" text object selection commands
function M.i()
  local char2 = input.get_text_object_sel_second_char()

  if char2 then
    modify_area("i" .. char2)
  end

  return
end


-- Edit ------------------------------------------------------------------------

local function edit(cmd)
  local count = vim.v.count

  virtual_cursors.visual_mode(function()
    common.normal_bang(nil, count, cmd, nil)
  end)

  common.feedkeys(nil, count, cmd, nil)
end

function M.J() edit("J") end
function M.gJ() edit("gJ") end

function M.less_than() edit("<") end
function M.greater_than() edit(">") end

function M.tilde() edit("~") end
function M.u() edit("u") end
function M.U() edit("U") end
function M.g_tilde() edit("g~") end
function M.gu() edit("gu") end
function M.gU() edit("gU") end


-- Yank/delete -----------------------------------------------------------------

function M.y()
  common.feedkeys(vim.v.register, 0, "y", nil)
  virtual_cursors.visual_mode_delete_yank(vim.v.register, "y")
end

function M.d()
  common.feedkeys(vim.v.register, 0, "d", nil)
  virtual_cursors.visual_mode_delete_yank(vim.v.register, "d")
end

function M.c()
  common.feedkeys(vim.v.register, 0, "d", nil)
  common.feedkeys(nil, 0, "i", nil)
  virtual_cursors.visual_mode_delete_yank(vim.v.register, "d")
end

return M
