local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local insert_mode_completion = require("multiple-cursors.insert_mode.completion")

local function normal_command_and_feedkeys(cmd, key)
  insert_mode_completion.complete_if_selected()
  virtual_cursors.move_with_normal_command(0, cmd)
  common.feedkeys(nil, 0, key, nil)
end

function M.up()
  normal_command_and_feedkeys("k", "<Up>")
end

function M.down()
  normal_command_and_feedkeys("j", "<Down>")
end

function M.left()
  normal_command_and_feedkeys("h", "<Left>")
end

function M.right()
  normal_command_and_feedkeys("l", "<Right>")
end

function M.home()
  normal_command_and_feedkeys("0", "<Home>")
end

function M.eol()
  normal_command_and_feedkeys("$", "<End>")
end

function M.word_left()
  normal_command_and_feedkeys("b", "<C-Left>")
end

function M.word_right()
  normal_command_and_feedkeys("w", "<C-Right>")
end

return M
