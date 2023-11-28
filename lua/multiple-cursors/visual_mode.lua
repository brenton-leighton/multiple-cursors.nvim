local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local normal_to_insert = require("multiple-cursors.normal_to_insert")

local delete_on_exit = false

local split_paste = false
local paste_lines = nil

local join_on_exit = nil
local change_case_on_exit = nil

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

-- Delete line lnum from col1 to col2
local function delete_line(lnum, col1, col2)

  -- Move cursor to start
  vim.fn.setcursorcharpos({lnum, col1, 0, col1})

  -- If col2 is at EoL
  if col2 > common.get_max_col(lnum) then
    -- Delete to EoL and join
    vim.cmd("normal! \"_DgJ")
  else
    -- Delete to col2
    local count = col2 - col1 + 1
    vim.cmd("normal! \"_d" .. tostring(count) .. "l")
  end

end

-- Delete lines lnum1 to lnum2 inclusive
local function delete_lines(lnum1, lnum2)

  if lnum1 > lnum2 then
    return
  end

  -- Move cursor to lnum1
  vim.fn.setcursorcharpos({lnum1, 1, 0, 1})

  local count = lnum2 - lnum1

  -- If there's a single in-between line
  if count == 0 then
    vim.cmd("normal! \"_dd")
  else -- Multiple in-between lines
    vim.cmd("normal! \"_d" .. tostring(count) .. "j")
  end

end

-- Delete the visual area for a virtual cursor
local function virtual_cursor_delete(vc)

  local lnum1, col1, lnum2, col2 = common.get_normalised_visual_area(vc)

  -- If the visual area is a single line
  if lnum1 == lnum2 then
    delete_line(lnum1, col1, col2)

  else -- Multiple lines

    -- Delete the last line
    delete_line(lnum2, 1, col2)

    -- Delete any in-between lines
    delete_lines(lnum1 + 1, lnum2 - 1)

    -- Delete the first line
    delete_line(lnum1, col1, vim.v.maxcol)

  end
end

-- Delete visual areas for all virtual cursors
local function all_virtual_cursors_delete()

  virtual_cursors.edit(function(vc)
    if common.is_visual_area_valid(vc) then

      virtual_cursor_delete(vc)

      common.set_virtual_cursor_from_cursor(vc)

      vc.visual_start_lnum = 0
      vc.visual_start_col = 0
    end
  end)

end

-- Paste for a virtual cursor
local function virtual_cursor_paste(vc, lines)
  -- Put lines before the cursor
  vim.api.nvim_put(lines, "c", false, true)

  -- Set virtual cursor position from the real cursor and then move it back
  common.set_virtual_cursor_from_cursor(vc)
  vc.col = vc.col - 1
  vc.curswant = vc.col
end

-- Paste for all virtual cursors
local function all_virtual_cursors_paste()

  -- First delete the visual areas
  all_virtual_cursors_delete()

  -- Perform the paste
  virtual_cursors.edit_with_cursor(function(vc, idx)
    if split_paste then
      virtual_cursor_paste(vc, {paste_lines[idx]})
    else
      virtual_cursor_paste(vc, paste_lines)
    end
  end)

end

local function virtual_cursor_join(vc, command)

  local lnum1, col1, lnum2, col2 = common.get_normalised_visual_area(vc)

  -- Set cursor to start of area
  vim.fn.setcursorcharpos({lnum1, col1, 0, col1})

  local count = lnum2 - lnum1

  if count == 0 then
    vim.cmd("normal! " .. command)
  else
    vim.cmd("normal! " .. tostring(count + 1) .. command)
  end

  common.set_virtual_cursor_from_cursor(vc)

  -- Clear visual area
  vc.visual_start_lnum = 0
  vc.visual_start_col = 0

end

local function all_virtual_cursors_join(command)

  virtual_cursors.edit(function(vc)
    virtual_cursor_join(vc, command)
  end)

end

local function all_virtual_cursors_change_case(command)

  virtual_cursors.edit(function(vc)
    if common.is_visual_area_valid(vc) then

			local lnum1, col1, lnum2, col2 = common.get_normalised_visual_area(vc)
			vim.fn.setcursorcharpos({ lnum1, col1, 0, col1 })

			local text = vim.api.nvim_buf_get_text(0, lnum1 - 1, col1 - 1, lnum2 - 1, col2, {})
			local dist = -1
			for _, line in ipairs(text) do
				dist = dist + vim.fn.strchars(line) + 1
			end
      if dist > 0 then
        vim.cmd('normal! g' .. command .. tostring(dist) .. 'l')
      end

      common.set_virtual_cursor_from_cursor(vc)

      vc.visual_start_lnum = 0
      vc.visual_start_col = 0

    end
  end)

end

-- Visual mode exited while multiple cursors is active
function M.mode_changed_from_visual()

  if delete_on_exit then  -- Delete
    all_virtual_cursors_delete()
    delete_on_exit = false
  elseif paste_lines then  -- Paste
    all_virtual_cursors_paste()
    split_paste = false
    paste_lines = nil
  elseif join_on_exit then  -- Join
    all_virtual_cursors_join(join_on_exit)
    join_on_exit = nil
  elseif change_case_on_exit then -- Change case
    all_virtual_cursors_change_case(change_case_on_exit)
    change_case_on_exit = nil
  else -- Just clear visual areas
    virtual_cursors.visit_all(function(vc)
      vc.visual_start_lnum = 0
      vc.visual_start_col = 0
    end)
  end

end

-- Move cursor to other end of visual area
function M.o()

  common.feedkeys("o", 0)

  virtual_cursors.visit_in_buffer(function(vc)

    if common.is_visual_area_valid(vc) then

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

-- Get visual area text to put into regcontents
local function visual_area_to_register_info(cmd, lnum1, col1, lnum2, col2)

  local lines = {}

  -- Single line
  if lnum1 == lnum2 then
    lines = vim.fn.getbufline("", lnum1)
  else
    lines = vim.fn.getbufline("", lnum1, lnum2)
  end

  -- If the end of the visual area is the end of the line
  if col2 >= common.get_max_col(lnum2) then
    -- Add a blank line
    table.insert(lines, "")
  -- Else if col2 is less than the length of the line
  elseif col2 < string.len(lines[#lines]) then
    -- Trim back of last line
    lines[#lines] = string.sub(lines[#lines], 1, col2)
  end

  -- Trim front of first line
  if col1 > 1 then
    lines[1] = string.sub(lines[1], col1)
  end

  local points_to = "0" -- yank

  if cmd == "d" or cmd == "c" then -- delete or change
    if lnum1 == lnum2 then -- Single line
      points_to = "-"
    else
      points_to = "1"
    end
  end

  return {
    points_to = points_to,
    regcontents = lines,
    regtype = "v",
  }

end

-- Perform yank for all virtual cursors
local function all_virtual_cursors_yank(cmd)
  virtual_cursors.visit_in_buffer(function(vc)

    local lnum1, col1, lnum2, col2 = common.get_normalised_visual_area(vc)

    vc.register_info = visual_area_to_register_info(cmd, lnum1, col1, lnum2, col2)

    -- Move cursor to start
    if common.is_visual_area_forward(vc) then
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

 -- y command
function M.y()
  common.feedkeys("y", 0)
  all_virtual_cursors_yank("y")
end

-- d command
function M.d()
  common.feedkeys("d", 0)
  all_virtual_cursors_yank("d")
  delete_on_exit = true
end

-- c command
function M.c()
  local orig_ve = vim.wo.ve
  vim.wo.ve = "onemore"

  M.d()
  normal_to_insert.i()

  vim.api.nvim_create_autocmd("InsertEnter",{
    once = true,
    callback = function ()
      vim.wo.ve = orig_ve
    end
  })
end

-- Lowercase command
function M.u()
  common.feedkeys("u", 0)
  change_case_on_exit = "u"
end

-- Lowercase command
function M.U()
  common.feedkeys("U", 0)
  change_case_on_exit = "U"
end

-- Lowercase command
function M.tilde()
  common.feedkeys("~", 0)
  change_case_on_exit = "~"
end

-- Join commands
function M.J()
  common.feedkeys("J", 0)
  join_on_exit = "J"
end

function M.gJ()
  common.feedkeys("gJ", 0)
  join_on_exit = "gJ"
end

-- Escape command
function M.escape()
  virtual_cursors.visit_in_buffer(function(vc)
    -- Move cursor back if it's at the end of a non empty line
    vc.col = vim.fn.min({vc.col, common.get_max_col(vc.lnum) - 1})
    vc.col = vim.fn.max({vc.col, 1})
  end)
end

-- Trigger paste when visual mode is exited
function M.paste_on_exit(_split_paste, lines)
  split_paste = _split_paste
  paste_lines = lines
end

return M
