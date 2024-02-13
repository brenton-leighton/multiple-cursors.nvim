local M = {}

local virtual_cursors = require("multiple-cursors.virtual_cursors")

-- Returns a new table without the cursor match, and ordered so that the matches start after the
-- cursor
local function reorder_matches(matches, cursor_idx)

  local reordered_matches = {}

  for idx = cursor_idx + 1, #matches do
    table.insert(reordered_matches, matches[idx])
  end

  for idx = 1, cursor_idx - 1 do
    table.insert(reordered_matches, matches[idx])
  end

  return reordered_matches

end

-- Set the cursor for the search
-- limit:
--   0: no limit, whole buffer
--   1: limit search to visible buffer
--   2: limit search previous visual area
-- visual_area_end is returned if limit == 2, otherwise nil is returned
local function set_cursor(limit)

  if limit == 0 then
    -- Move the cursor to the start of the buffer
    vim.fn.cursor({1, 1, 0, 1})

    return nil

  elseif limit == 1 then
    -- Move cursor to start of the visible buffer
    local start_lnum = vim.fn.line("w0")
    vim.fn.cursor({start_lnum, 1, 0, 1})

    return nil

  else -- limit == 2
    -- Get the previous visual area
    local visual_area_start = vim.api.nvim_buf_get_mark(0, "<")
    local visual_area_end = vim.api.nvim_buf_get_mark(0, ">")

    if visual_area_start[1] == 0 or visual_area_end[1] == 0 then
      vim.print("No previous visual area")
      return
    end

    -- Move the cursor to the start of the visual area
    vim.fn.cursor({visual_area_start[1], visual_area_start[2] + 1, 0, visual_area_start[2] + 1})

    return visual_area_end

  end

end

local function is_past_end(limit, visual_area_end, match)

  if limit == 0 then
    return false
  end

  if limit == 1 then
    if match[1] > vim.fn.line("w$") then
      return true
    end

  else -- limit == 2
    if match[1] > visual_area_end[1] or
        (match[1] == visual_area_end[1] and match[2] > visual_area_end[2] + 1) then
      return true
    end

  end

  return false

end

-- Returns positions for matches to the given word
function M.get_matches_and_move_cursor(word, limit_to_visible, limit_to_prev_visual_area)

  local limit = 0 -- whole buffer

  if limit_to_prev_visual_area then
    limit = 2
  elseif limit_to_visible then
    limit = 1
  end

  -- Save real cursor position
  local cursor_pos = vim.fn.getcurpos()

  virtual_cursors.set_ignore_cursor_movement(true)

  -- Set the cursor position for the search, saving visual_area_end if limit == 2
  -- Handle the use_prev_visual_area argument
  local visual_area_end = set_cursor(limit)

  -- Find matches
  local matches = {}

  local first = true
  local visible_end_lnum = vim.fn.line("w$")

  local ignorecase = vim.o.ignorecase
  vim.o.ignorecase = false

  while true do
    local match  = {0, 0}

    -- First match can include the cursor position
    if first then
      match = vim.fn.searchpos(word, "cW")
      first = false
    else
      match = vim.fn.searchpos(word, "W")
    end

    if match[1] == 0 or match[2] == 0 then
      break
    end

    if is_past_end(limit, visual_area_end, match) then
      break
    end

    -- Add the match
    table.insert(matches, match)
  end

  vim.o.ignorecase = ignorecase

  -- If there is one or no matches
  if #matches <= 1 then
    -- Restore the cursor and return nil
    vim.fn.cursor({cursor_pos[2], cursor_pos[3], cursor_pos[4], cursor_pos[5]})
    virtual_cursors.set_ignore_cursor_movement(false)
    vim.print("No matches found")
    return nil
  end

  -- Find the match for the real cursor
  for idx, match in ipairs(matches) do

    -- If match is on the same line as the cursor
    if match[1] == cursor_pos[2] then

      -- If the cursor is within match or this first match before the cursor
      if cursor_pos[3] >= match[2] and cursor_pos[3] < match[2] + #word or
          cursor_pos[3] < match[2] then

        -- Move the cursor to the match
        vim.fn.cursor({match[1], match[2], 0, match[2]})

        -- Remove the cursor match and reorder matches so that they start after the cursor
        matches = reorder_matches(matches, idx)

        break
      end

    end

  end

  virtual_cursors.set_ignore_cursor_movement(false)
  return matches

end

-- Get a single match after the cursor, optionally moving the cursor to the match before the cursor
function M.get_next_match(word, move_cursor)

  local ignorecase = vim.o.ignorecase
  vim.o.ignorecase = false

  -- Get the next match without moving the cursor
  local match = vim.fn.searchpos(word, "nw")

  if match[1] == 0 or match[2] == 0 then
    vim.o.ignorecase = ignorecase
    return nil
  end

  if move_cursor then
    -- Move cursor to the previous match
    vim.fn.searchpos(word, "bc")
  end

  vim.o.ignorecase = ignorecase

  virtual_cursors.set_ignore_cursor_movement(false)

  return match

end

return M
