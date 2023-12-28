local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local input = require("multiple-cursors.input")

-- Left/right motion in normal/visual modes
function M.normal_h()
  common.feedkeys("h", vim.v.count)
  virtual_cursors.move_with_normal_command(vim.v.count, "h")
end

function M.normal_l()
  common.feedkeys("l", vim.v.count)
  virtual_cursors.move_with_normal_command(vim.v.count, "l")
end

function M.normal_0()
  common.feedkeys("0", 0)
  virtual_cursors.move_with_normal_command(0, "0")
end

function M.normal_dollar()
  common.feedkeys("$", 0)
  virtual_cursors.move_with_normal_command(0, "$")
end

function M.normal_caret()
  common.feedkeys("^", 0)
  virtual_cursors.move_with_normal_command(0, "^")
end

function M.normal_bar()
  common.feedkeys("|", vim.v.count)
  virtual_cursors.move_with_normal_command(vim.v.count, "|")
end

-- Handle f, F, t, or T command
local function normal_fFtT(cmd)
  local count = vim.v.count
  local char = input.get_char()

  if char ~= nil then
    common.feedkeys(cmd .. char, count)
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

-- Left/right motion in insert/replace modes
function M.insert_left()
  common.feedkeys("<Left>", 0)
  virtual_cursors.move_with_normal_command(0, "h")
end

function M.insert_right()
  common.feedkeys("<Right>", 0)
  virtual_cursors.move_with_normal_command(0, "l")
end

-- Home/End motion in all modes
function M.home()
  common.feedkeys("<Home>", 0)
  virtual_cursors.move_with_normal_command(0, "0")
end

function M.eol()
  common.feedkeys("<End>", 0)
  virtual_cursors.move_with_normal_command(0, "$")
end

-- Text object movement in normal/visual mode
function M.normal_b()
  common.feedkeys("b", vim.v.count)
  virtual_cursors.move_with_normal_command(vim.v.count, "b")
end

function M.normal_B()
  common.feedkeys("B", vim.v.count)
  virtual_cursors.move_with_normal_command(vim.v.count, "B")
end

function M.normal_w()
  common.feedkeys("w", vim.v.count)
  virtual_cursors.move_with_normal_command(vim.v.count, "w")
end

function M.normal_W()
  common.feedkeys("W", vim.v.count)
  virtual_cursors.move_with_normal_command(vim.v.count, "W")
end

function M.normal_e()
  common.feedkeys("e", vim.v.count)
  virtual_cursors.move_with_normal_command(vim.v.count, "e")
end

function M.normal_E()
  common.feedkeys("E", vim.v.count)
  virtual_cursors.move_with_normal_command(vim.v.count, "E")
end

function M.normal_ge()
  common.feedkeys("ge", vim.v.count)
  virtual_cursors.move_with_normal_command(vim.v.count, "ge")
end

function M.normal_gE()
  common.feedkeys("gE", vim.v.count)
  virtual_cursors.move_with_normal_command(vim.v.count, "gE")
end

-- Text object motion in insert/replace modes
function M.insert_word_left()
  common.feedkeys("<C-Left>", 0)
  virtual_cursors.move_with_normal_command(0, "b")
end

function M.insert_word_right()
  common.feedkeys("<C-Right>", 0)
  virtual_cursors.move_with_normal_command(0, "w")
end

-- Various motions in normal/visual modes
function M.normal_percent()
  -- Count is ignored, match command only
  common.feedkeys("%", 0)
  virtual_cursors.move_with_normal_command(0, "%")
end

return M
