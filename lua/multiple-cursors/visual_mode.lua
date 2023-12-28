local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")

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

  virtual_cursors.visual_mode_modify_area(function()
    common.normal_bang(nil, count, cmd, nil)
  end)

  common.feedkeys(cmd, count)
end

function M.o() modify_area("o") end
function M.aw() modify_area("aw") end
function M.iw() modify_area("iw") end
function M.aW() modify_area("aW") end
function M.iW() modify_area("iW") end
function M.ab() modify_area("ab") end
function M.ib() modify_area("ib") end
function M.aB() modify_area("aB") end
function M.iB() modify_area("iB") end
function M.a_greater_than() modify_area("a>") end
function M.i_greater_than() modify_area("i>") end
function M.at() modify_area("at") end
function M.it() modify_area("it") end
function M.a_quote() modify_area([[a']]) end
function M.i_quote() modify_area([[i']]) end
function M.a_double_quote() modify_area([[a"]]) end
function M.i_double_quote() modify_area([[i"]]) end
function M.a_backtick() modify_area("a`") end
function M.i_backtick() modify_area("i`") end


-- Edit ------------------------------------------------------------------------

local function edit(cmd)
  local count = vim.v.count

  virtual_cursors.visual_mode_edit(function()
    common.normal_bang(nil, count, cmd, nil)
  end)

  common.feedkeys(cmd, count)
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
  common.feedkeys_with_register(vim.v.register, "y", 0)
  virtual_cursors.visual_mode_delete_yank(vim.v.register, "y")
end

function M.d()
  common.feedkeys_with_register(vim.v.register, "d", 0)
  virtual_cursors.visual_mode_delete_yank(vim.v.register, "d")
end

function M.c()
  common.feedkeys_with_register(vim.v.register, "d", 0)
  common.feedkeys("i", 0)
  virtual_cursors.visual_mode_delete_yank(vim.v.register, "d")
end

return M
