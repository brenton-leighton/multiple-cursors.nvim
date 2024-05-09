local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")

function M.escape()

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
