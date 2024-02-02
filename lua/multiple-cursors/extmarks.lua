local M = {}

local cursor_hl_group = "Cursor"
local visual_hl_group = "Visual"

local common = require("multiple-cursors.common")

local highlight_namespace_id = nil

-- For saving and restoring the cursor position to an extmark
local cursor_mark_id = 0
local cursor_lnum = nil
local cursor_curswant = nil

local visual_area_start_mark_id = nil
local visual_area_end_mark_id = nil

function M.setup()
  highlight_namespace_id = vim.api.nvim_create_namespace("multiple-cursors")
end

-- Clear all extmarks
function M.clear()
  vim.api.nvim_buf_clear_namespace(0, highlight_namespace_id, 0, -1)
end

local function set_extmark(lnum, col, mark_id, hl_group, priority)

  local opts = {}

  if mark_id ~= 0 then
    opts.id = mark_id
  end

  local line_length = common.get_length_of_line(lnum)

  -- If the line is empty or col is past the end of the line
  if line_length == 0 or col > line_length then
    -- Use virtual text to add and highlight a space
    col = line_length + 1
    opts.virt_text = {{" ", hl_group}}
    opts.virt_text_pos = "overlay"
  else
    -- Otherwise highlight the character

    -- Convert col to char index
    local line = vim.fn.getline(lnum)
    local col_char = vim.fn.charidx(line, col - 1)

    -- end_col is the byte index of the next character
    opts.end_col = vim.fn.byteidx(line, col_char + 1)

    opts.hl_group = hl_group
  end

  if priority ~= 0 then
    opts.priority = priority
  end

  return vim.api.nvim_buf_set_extmark(0, highlight_namespace_id, lnum - 1, col - 1, opts)

end

-- Save and restore cursor -----------------------------------------------------

-- Save the cursor to a hidden extmark to track movement due to changes
function M.save_cursor()

  local pos = vim.fn.getcurpos()

  cursor_lnum = pos[2]  -- Save lnum in case the cursor is lost
  local col = pos[3]
  cursor_curswant = pos[5]  -- Save curswant

  -- Create an invisible extmark
  cursor_mark_id = set_extmark(cursor_lnum, col, cursor_mark_id, "", 0)

end

-- Restore the cursor from an extmark
function M.restore_cursor()

  if cursor_mark_id ~= nil and cursor_lnum ~= nil then

    -- Get the cursor extmark position
    local extmark_pos = vim.api.nvim_buf_get_extmark_by_id(
        0, highlight_namespace_id, cursor_mark_id, {})

    -- Delete the cursor extmark
    vim.api.nvim_buf_del_extmark(0, highlight_namespace_id, cursor_mark_id)

    -- If the extmark position is valid
    if next(extmark_pos) ~= nil then
      local lnum = extmark_pos[1] + 1
      local col = extmark_pos[2] + 1
      local curswant = cursor_curswant

      -- Maintain curswant = vim.v.maxcol if the cursor is still at the end of the line
      if curswant < vim.v.maxcol and col < common.get_max_col(lnum) then
        curswant = col
      end

      vim.fn.cursor({lnum, col, 0, curswant})
    else
      -- extmark gone, restore from lnum
      vim.fn.cursor({cursor_lnum, 1, 0, 1})
    end

    cursor_mark_id = nil
    cursor_lnum = nil
    cursor_curswant = nil
  end
end

-- Virtual cursor extmark ------------------------------------------------------

-- Create or update the extmark for a virtual cursor
local function update_virtual_cursor_extmark(vc)

  if vc.editable then
    vc.mark_id = set_extmark(vc.lnum, vc.col, vc.mark_id, cursor_hl_group, 9999)
  else
    -- Invisible mark when the virtual cursor isn't editable (in collision with the real cursor)
    vc.mark_id = set_extmark(vc.lnum, vc.col, vc.mark_id, "", 9999)
  end

end

-- Virtual cursor extmarks for visual mode -------------------------------------

-- Create (or delete) an extmark for the multi-line component of the visual virtual cursor
-- Returns new mark ID
local function update_visual_multi_line_extmark(mark_id, lnum1, col1, lnum2, col2)
  -- if lnum1 > lnum2 then there are only empty lines
  if lnum1 > lnum2 then
    -- Delete the existing extmark
    if mark_id > 0 then
      vim.api.nvim_buf_del_extmark(0, highlight_namespace_id, mark_id)
    end
    return 0

  else
    -- Create or update an extmark
    local opts = {}

    if mark_id > 0 then
      opts.id = mark_id
    end

    if lnum1 ~= lnum2 then
      opts.end_row = lnum2 - 1
    end

    opts.end_col = col2 - 1
    opts.hl_group = visual_hl_group
    opts.priority = 9998

    return vim.api.nvim_buf_set_extmark(0, highlight_namespace_id, lnum1 - 1, col1 - 1, opts)

  end

end

-- Create (or delete) extmarks for the empty lines of the visual virtual cursor
-- mark_ids is modified
local function update_visual_empty_line_extmarks(mark_ids, empty_lines)

  for idx = 1, #empty_lines do
    local opts = {}

    opts.virt_text = {{" ", visual_hl_group}}
    opts.virt_text_pos = "overlay"
    opts.priority = 9998

    if #mark_ids >= idx then
      opts.id = mark_ids[idx]
    end

    local new_mark_id = vim.api.nvim_buf_set_extmark(0, highlight_namespace_id, empty_lines[idx] - 1, 0, opts)

    if #mark_ids >= idx then
      mark_ids[idx] = new_mark_id
    else
      table.insert(mark_ids, new_mark_id)
    end

  end

  -- Remove any extra extmarks
  for idx = #mark_ids, 1, -1 do
    if idx <= #empty_lines then
      return
    end

    vim.api.nvim_buf_del_extmark(0, highlight_namespace_id, mark_ids[idx])
    table.remove(mark_ids, idx)
  end

end

-- Delete all visual mode extmarks for a virtual cursor
local function delete_virtual_cursor_visual_extmarks(vc)

  -- Hidden extmark for the start of the visual area
  if vc.visual_start_mark_id ~= 0 then
    vim.api.nvim_buf_del_extmark(0, highlight_namespace_id, vc.visual_start_mark_id)
    vc.visual_start_mark_id = 0
  end

  -- Multi-line visual area extmark
  if vc.visual_multiline_mark_id ~= 0 then
    vim.api.nvim_buf_del_extmark(0, highlight_namespace_id, vc.visual_multiline_mark_id)
    vc.visual_multiline_mark_id = 0
  end

  -- Empty line visual area extmarks
  if next(vc.visual_empty_line_mark_ids) ~= nil then
    for idx = 1, #vc.visual_empty_line_mark_ids do
      vim.api.nvim_buf_del_extmark(0, highlight_namespace_id, vc.visual_empty_line_mark_ids[idx])
    end

    vc.visual_empty_line_mark_ids = {}
  end

end

-- Get the positions of the visual area in a forward direction
local function get_normalised_visual_area(vc)
  local lnum1 = vc.visual_start_lnum
  local col1 = vc.visual_start_col
  local lnum2 = vc.lnum
  local col2 = vc.col

  if not vc:is_visual_area_forward() then
    lnum1 = vc.lnum
    col1 = vc.col
    lnum2 = vc.visual_start_lnum

    -- If backwards, add 1 to the end column because the cursor isn't there
    col2 = vim.fn.min({vc.visual_start_col + 1, common.get_max_col(lnum2)})
  end

  return lnum1, col1, lnum2, col2
end

-- Find any empty lines, and adjust lnum1 (and col1) to not start on an empty line
-- Returns a new lnum1, new col1, and empty lines
local function find_empty_lines_in_visual_area(lnum1, col1, lnum2, col2)
  local empty_lines = {}

  for lnum = lnum1, lnum2 do
    if common.get_length_of_line(lnum) == 0 then
      -- Empty line
      table.insert(empty_lines, lnum)

      if lnum1 == lnum then
        -- Shift start to a non-empty line
        lnum1 = lnum + 1
        col1 = 1
      end
    end
  end

  return lnum1, col1, empty_lines
end

-- Create or update the visual mode extmarks for a virtual cursor
local function update_virtual_cursor_visual_extmarks(vc)

  -- If there's no visual area
  if not vc:is_visual_area_valid() or
      (vc.visual_start_lnum == vc.lnum and vc.visual_start_col == vc.col) then

    -- Clear any visual marks
    delete_virtual_cursor_visual_extmarks(vc)
    return
  end

  -- Hidden visual area start extmark
  vc.visual_start_mark_id = set_extmark(vc.visual_start_lnum, vc.visual_start_col, vc.visual_start_mark_id, "", 0)

  -- Get the positions of the visual area in a forward direction
  local lnum1, col1, lnum2, col2 = get_normalised_visual_area(vc)

  -- Find any empty lines, and adjust lnum1 (and col1) to not start on an empty line
  local lnum1, col1, empty_lines = find_empty_lines_in_visual_area(lnum1, col1, lnum2, col2)

  -- Multi-line extmark
  vc.visual_multiline_mark_id = update_visual_multi_line_extmark(vc.visual_multiline_mark_id, lnum1, col1, lnum2, col2)

  -- Empty line extmarks
  update_visual_empty_line_extmarks(vc.visual_empty_line_mark_ids, empty_lines)

end

-- Virtual cursor --------------------------------------------------------------

-- Delete any extmarks for a virtual cursor
function M.delete_virtual_cursor_extmarks(vc)

  -- Main extmark
  if vc.mark_id ~= 0 then
    vim.api.nvim_buf_del_extmark(0, highlight_namespace_id, vc.mark_id)
    vc.mark_id = 0
  end

  -- Visual area extmarks
  delete_virtual_cursor_visual_extmarks(vc)

end

-- Update all extmarks for a virtual cursor
function M.update_virtual_cursor_extmarks(vc)
  if vc.within_buffer then
    update_virtual_cursor_extmark(vc)
    update_virtual_cursor_visual_extmarks(vc)
  else -- Cursor not within buffer
    M.delete_virtual_cursor_extmarks(vc)
  end
end

-- Set virtual cursor position from its extmark
function M.update_virtual_cursor_position(vc)

  -- Main extmark
  if vc.mark_id ~= 0 then
    -- Get position
    local extmark_pos = vim.api.nvim_buf_get_extmark_by_id(0, highlight_namespace_id, vc.mark_id, {})

    -- If the mark is valid
    if next(extmark_pos) ~= nil then
      -- Update the virtual cursor position
      vc.lnum = extmark_pos[1] + 1
      vc.col = extmark_pos[2] + 1

      -- Maintain curswant = vim.v.maxcol if the cursor is still at the end of the line
      if vc.curswant < vim.v.maxcol and vc.col < common.get_max_col(vc.lnum) then
        vc.curswant = vc.col
      end
    else
      -- The extmark is gone, mark the virtual cursor for removal
      vc.delete = true
    end
  end

  if vc.delete then
    return
  end

  -- Visual area start extmark
  if vc.visual_start_mark_id ~= 0 then
    -- Get position
    local extmark_pos = vim.api.nvim_buf_get_extmark_by_id(0, highlight_namespace_id, vc.visual_start_mark_id, {})

    -- If the mark is valid
    if next(extmark_pos) ~= nil then
      -- Update the virtual cursor visual start position
      vc.visual_start_lnum = extmark_pos[1] + 1
      vc.visual_start_col = extmark_pos[2] + 1
    else
      -- The extmark is gone, mark the virtual cursor for removal
      vc.delete = true
    end
  end

end

function M.save_visual_area()

  local visual_area = common.get_visual_area()

  visual_area_start_mark_id = set_extmark(visual_area[1], visual_area[2], visual_area_start_mark_id, "", 0)
  visual_area_end_mark_id = set_extmark(visual_area[3], visual_area[4], visual_area_end_mark_id, "", 0)

end

function M.restore_visual_area()

  if visual_area_start_mark_id ~= nil and visual_area_end_mark_id ~= nil then

    -- Get the extmark positions
    local start_pos = vim.api.nvim_buf_get_extmark_by_id(0, highlight_namespace_id, visual_area_start_mark_id, {})
    local end_pos = vim.api.nvim_buf_get_extmark_by_id(0, highlight_namespace_id, visual_area_end_mark_id, {})

    -- Delete the extmarks
    vim.api.nvim_buf_del_extmark(0, highlight_namespace_id, visual_area_start_mark_id)
    vim.api.nvim_buf_del_extmark(0, highlight_namespace_id, visual_area_end_mark_id)

    visual_area_start_mark_id = nil
    visual_area_end_mark_id = nil

    -- If the extmark positions are valid
    if next(start_pos) ~= nil and next(end_pos) ~= nil then
        vim.cmd("normal!:") -- Exit to normal mode
        vim.api.nvim_buf_set_mark(0, "<", start_pos[1] + 1, start_pos[2], {})
        vim.api.nvim_buf_set_mark(0, ">", end_pos[1] + 1, end_pos[2], {})
        vim.cmd("normal! gv") -- Return to visual mode
    end

  end

end

return M
