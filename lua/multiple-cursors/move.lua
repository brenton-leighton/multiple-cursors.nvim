local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")

-- Left/right motion in normal/visual modes
function M.normal_h()
  common.feedkeys("h", vim.v.count)
  virtual_cursors.move_with_normal_command("h", vim.v.count)
end

function M.normal_0()
  common.feedkeys("0", 0)
  virtual_cursors.move_with_normal_command("0", 0)
end

function M.normal_caret()
  common.feedkeys("^", 0)
  virtual_cursors.move_with_normal_command("^", 0)
end

function M.normal_bar()
  common.feedkeys("|", vim.v.count)
  virtual_cursors.move_with_normal_command("|", vim.v.count)
end

-- Left motion in insert/replace modes
function M.insert_left()
  virtual_cursors.move_with_normal_command("h", 0)
  common.feedkeys("<Left>", 0)
end

-- Home motion in all modes
function M.home()
  common.feedkeys("<Home>", 0)
  virtual_cursors.move_with_normal_command("0", 0)
end

-- Text object movement in normal/visual mode
function M.normal_b()
  common.feedkeys("b", vim.v.count)
  virtual_cursors.move_with_normal_command("b", vim.v.count)
end

function M.normal_B()
  common.feedkeys("B", vim.v.count)
  virtual_cursors.move_with_normal_command("B", vim.v.count)
end

function M.normal_w()
  common.feedkeys("w", vim.v.count)
  virtual_cursors.move_with_normal_command("w", vim.v.count)
end

function M.normal_W()
  common.feedkeys("W", vim.v.count)
  virtual_cursors.move_with_normal_command("W", vim.v.count)
end

function M.normal_e()
  common.feedkeys("e", vim.v.count)
  virtual_cursors.move_with_normal_command("e", vim.v.count)
end

function M.normal_E()
  common.feedkeys("E", vim.v.count)
  virtual_cursors.move_with_normal_command("E", vim.v.count)
end

-- Text object motion in insert/replace modes
function M.insert_word_left()
  common.feedkeys("<C-Left>", 0)
  virtual_cursors.move_with_normal_command("b", 0)
end

function M.insert_word_right()
  common.feedkeys("<C-Right>", 0)
  virtual_cursors.move_with_normal_command("w", 0)
end

-- Various motions in normal/visual modes
function M.normal_percent()
  -- Count is ignored, match command only
  common.feedkeys("%", 0)
  virtual_cursors.move_with_normal_command("%", 0)
end

return M
