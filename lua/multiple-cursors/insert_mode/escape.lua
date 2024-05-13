local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local insert_mode_completion = require("multiple-cursors.insert_mode.completion")

function M.escape()

  insert_mode_completion.complete_if_selected()

  -- Move the cursor back
  virtual_cursors.visit_with_cursor(function(vc)
    if vc.col ~= 1 then
      common.normal_bang(nil, 0, "h", nil)
      vc:save_cursor_position()
    end
  end)

  common.feedkeys(nil, 0, "<Esc>", nil)

end

return M
