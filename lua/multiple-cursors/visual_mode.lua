local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")

-- Visual mode entered while multiple cursors is active
function M.mode_changed_to_visual()

  local count = vim.v.count - 1

  virtual_cursors.visit_in_buffer(function(vc)

    -- Save cursor position as visual area start
    vc.visual_start_lnum = vc.lnum
    vc.visual_start_col = vc.col

    -- Move cursor forward if there's a count
    if count > 0 then
      vc.col = common.get_col(vc.lnum, vc.col + count)
      vc.curswant = vc.col
    end

  end)

end

-- Visual mode exited while multiple cursors is active
function M.mode_changed_from_visual()

  -- Clear visual areas
  virtual_cursors.visit_all(function(vc)
    vc.visual_start_lnum = 0
    vc.visual_start_col = 0
  end)

end

-- Move cursor to other end of visual area
function M.o()

  common.feedkeys("o", 0)

  virtual_cursors.visit_in_buffer(function(vc)

    if vc.visual_start_lnum ~= 0 then

      local lnum = vc.lnum
      local col = vc.col

      vc.lnum = vc.visual_start_lnum
      vc.col = vc.visual_start_col
      vc.curswant = vc.col

      vc.visual_start_lnum = lnum
      vc.visual_start_col = col

    end

  end)

end

function M.y()
  common.feedkeys("y", 0)
  virtual_cursors.visual_yank()
end

function M.d()
  common.feedkeys("d", 0)
  virtual_cursors.visual_delete()
end

function M.escape()
  virtual_cursors.visit_in_buffer(function(vc)
    -- Move cursor back if it's at the end of a non empty line
    vc.col = vim.fn.min({vc.col, common.get_max_col(vc.lnum) - 1})
    vc.col = vim.fn.max({vc.col, 1})
  end)
end

return M
