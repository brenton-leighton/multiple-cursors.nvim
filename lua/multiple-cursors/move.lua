local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local input = require("multiple-cursors.input")

-- Up/down motion in normal/visual modes
function M.normal_j()
  common.feedkeys(nil, vim.v.count, "j", nil)
  virtual_cursors.move_with_normal_command(vim.v.count, "j")
end

function M.normal_k()
  common.feedkeys(nil, vim.v.count, "k", nil)
  virtual_cursors.move_with_normal_command(vim.v.count, "k")
end

function M.normal_minus()
  common.feedkeys(nil, vim.v.count, "-", nil)
  virtual_cursors.move_with_normal_command(vim.v.count, "-")
end

function M.normal_plus()
  common.feedkeys(nil, vim.v.count, "+", nil)
  virtual_cursors.move_with_normal_command(vim.v.count, "+")
end

function M.normal_underscore()
  common.feedkeys(nil, vim.v.count, "_", nil)
  virtual_cursors.move_with_normal_command(vim.v.count, "_")
end

-- Left/right motion in normal/visual modes
function M.normal_h()
  common.feedkeys(nil, vim.v.count, "h", nil)
  virtual_cursors.move_with_normal_command(vim.v.count, "h")
end

function M.normal_l()
  common.feedkeys(nil, vim.v.count, "l", nil)
  virtual_cursors.move_with_normal_command(vim.v.count, "l")
end

function M.normal_0()
  common.feedkeys(nil, 0, "0", nil)
  virtual_cursors.move_with_normal_command(0, "0")
end

function M.normal_dollar()
  common.feedkeys(nil, 0, "$", nil)
  virtual_cursors.move_with_normal_command(0, "$")
end

function M.normal_caret()
  common.feedkeys(nil, 0, "^", nil)
  virtual_cursors.move_with_normal_command(0, "^")
end

function M.normal_bar()
  common.feedkeys(nil, vim.v.count, "|", nil)
  virtual_cursors.move_with_normal_command(vim.v.count, "|")
end

-- Handle f, F, t, or T command
local function normal_fFtT(cmd)
  local count = vim.v.count
  local char = input.get_char()

  if char ~= nil then
    common.feedkeys(nil, count, cmd .. char, nil)
    virtual_cursors.move_with_normal_command(count, cmd .. char)
  end

end

function M.normal_f()
  normal_fFtT("f")
end

function M.normal_F()
  normal_fFtT("F")
end

function M.normal_t()
  normal_fFtT("t")
end

function M.normal_T()
  normal_fFtT("T")
end

-- Text object movement in normal/visual mode
function M.normal_b()
  common.feedkeys(nil, vim.v.count, "b", nil)
  virtual_cursors.move_with_normal_command(vim.v.count, "b")
end

function M.normal_B()
  common.feedkeys(nil, vim.v.count, "B", nil)
  virtual_cursors.move_with_normal_command(vim.v.count, "B")
end

function M.normal_w()
  common.feedkeys(nil, vim.v.count, "w", nil)
  virtual_cursors.move_with_normal_command(vim.v.count, "w")
end

function M.normal_W()
  common.feedkeys(nil, vim.v.count, "W", nil)
  virtual_cursors.move_with_normal_command(vim.v.count, "W")
end

function M.normal_e()
  common.feedkeys(nil, vim.v.count, "e", nil)
  virtual_cursors.move_with_normal_command(vim.v.count, "e")
end

function M.normal_E()
  common.feedkeys(nil, vim.v.count, "E", nil)
  virtual_cursors.move_with_normal_command(vim.v.count, "E")
end

function M.normal_ge()
  common.feedkeys(nil, vim.v.count, "ge", nil)
  virtual_cursors.move_with_normal_command(vim.v.count, "ge")
end

function M.normal_gE()
  common.feedkeys(nil, vim.v.count, "gE", nil)
  virtual_cursors.move_with_normal_command(vim.v.count, "gE")
end

-- Various motions in normal/visual modes
function M.normal_percent()
  -- Count is ignored, match command only
  common.feedkeys(nil, 0, "%", nil)
  virtual_cursors.move_with_normal_command(0, "%")
end

return M
