local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local insert_mode_completion = require("multiple-cursors.insert_mode.completion")
local extmarks = require("multiple-cursors.extmarks")

-- Delete word
function M.c_w()
  insert_mode_completion.complete_if_selected()
  virtual_cursors.edit_with_normal_command(0, "db", nil)
  common.feedkeys(nil, 0, "<C-w>", nil)
end

-- Indent
function M.c_t()
  insert_mode_completion.complete_if_selected()

  -- Update the cursor position from the extmark so that the cursor stays in place
  virtual_cursors.edit_with_cursor_no_save(function(vc)
    common.normal_bang(nil, 0, ">>", nil)
    extmarks.update_virtual_cursor_position(vc)
  end)

  common.feedkeys(nil, 0, "<C-t>", nil)
end

-- Deindent
function M.c_d()
  insert_mode_completion.complete_if_selected()

  -- Update the cursor position from the extmark so that the cursor stays in place
  virtual_cursors.edit_with_cursor_no_save(function(vc)
    common.normal_bang(nil, 0, "<<", nil)
    extmarks.update_virtual_cursor_position(vc)
  end)

  common.feedkeys(nil, 0, "<C-d>", nil)
end

return M
