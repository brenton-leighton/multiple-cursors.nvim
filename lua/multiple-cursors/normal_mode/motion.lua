local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local input = require("multiple-cursors.input")

local function normal_command_and_feedkeys(cmd)
  local count = vim.v.count
  virtual_cursors.move_with_normal_command(count, cmd)
  common.feedkeys(nil, count, cmd, nil)
end

function M.k() normal_command_and_feedkeys("k") end
function M.j() normal_command_and_feedkeys("j") end
function M.minus() normal_command_and_feedkeys("-") end
function M.plus() normal_command_and_feedkeys("+") end
function M.underscore() normal_command_and_feedkeys("_") end

function M.h() normal_command_and_feedkeys("h") end
function M.l() normal_command_and_feedkeys("l") end
function M.zero() normal_command_and_feedkeys("0") end
function M.caret() normal_command_and_feedkeys("^") end
function M.dollar() normal_command_and_feedkeys("$") end
function M.bar() normal_command_and_feedkeys("|") end

-- For f, F, t, or T commands
local function fFtT(cmd)

  local count = vim.v.count
  local char = input.get_char()

  if char ~= nil then
    virtual_cursors.move_with_normal_command(count, cmd .. char)
    common.feedkeys(nil, count, cmd .. char, nil)
  end

end

function M.f() fFtT("f") end
function M.F() fFtT("F") end
function M.t() fFtT("t") end
function M.T() fFtT("T") end

function M.w() normal_command_and_feedkeys("w") end
function M.W() normal_command_and_feedkeys("W") end
function M.e() normal_command_and_feedkeys("e") end
function M.E() normal_command_and_feedkeys("E") end
function M.b() normal_command_and_feedkeys("b") end
function M.B() normal_command_and_feedkeys("B") end
function M.ge() normal_command_and_feedkeys("ge") end
function M.gE() normal_command_and_feedkeys("gE") end

-- Percent
function M.percent()
  -- Count is ignored, match command only
  virtual_cursors.move_with_normal_command(0, "%")
  common.feedkeys(nil, 0, "%", nil)
end

-- Go to
function M.gg()
  if not virtual_cursors.is_locked() then
    virtual_cursors.go_to(vim.v.count1)
  else
    -- Just move the real cursor
    common.feedkeys(nil, vim.v.count, "gg", nil)
  end
end

function M.G()
  if not virtual_cursors.is_locked() then
    if vim.v.count == 0 then
      -- Move cursors to end of buffer
      virtual_cursors.go_to(vim.fn.line("$"))
    else
      virtual_cursors.go_to(vim.v.count1)
    end
  else
    -- Just move the real cursor
    common.feedkeys(nil, vim.v.count, "G", nil)
  end
end

return M
