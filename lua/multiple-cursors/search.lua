local M = {}

local virtual_cursors = require("multiple-cursors.virtual_cursors")

-- Only add cursors to matches that are visible
local match_visible_only = true

function M.setup(_match_visible_only)
  match_visible_only = _match_visible_only
end

-- Returns positions for matches to the given word
-- If use_prev_visual_area is true, only matches within the previous visual area
-- are returned
-- If match_visible_only is true, only matches within the visible buffer are
-- returned
function M.get_matches_and_move_cursor(word, use_prev_visual_area)

  -- Save real cursor position
  local cursor_pos = vim.fn.getcurpos()

  virtual_cursors.set_ignore_cursor_movement(true)

  -- Handle the use_prev_visual_area argument
  local visual_area_end = nil

  if use_prev_visual_area then
    -- Get the previous visual area
    local visual_area_start = vim.api.nvim_buf_get_mark(0, "<")
    visual_area_end = vim.api.nvim_buf_get_mark(0, ">")

    if visual_area_start[1] == 0 or visual_area_end[1] == 0 then
      vim.print("No previous visual area")
      return
    end

    -- Move the cursor to the start of the visual area
    vim.fn.cursor({visual_area_start[1], visual_area_start[2] + 1, 0, visual_area_start[2] + 1})

  elseif match_visible_only then
    -- Move cursor to start of the visible buffer
    local start_lnum = vim.fn.line("w0")
    vim.fn.cursor({start_lnum, 1, 0, 1})

  else
    -- Move the cursor to the start of the buffer
    vim.fn.cursor({1, 1, 0, 1})

  end

  -- Find matches
  local matches = {}

  local first = true
  local visible_end_lnum = vim.fn.line("w$")

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

    if use_prev_visual_area then
      -- End if the match is past the visual area
      if match[1] > visual_area_end[1] or
          (match[1] == visual_area_end[1] and match[2] > visual_area_end[2] + 1) then
        break
      end

    elseif match_visible_only then
      -- No visual area and matching visible only
      if match[1] > visible_end_lnum then
        -- Past the visible buffer
        break
      end

    end

    -- Add the match
    table.insert(matches, match)
  end

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

        -- Remove the match from matches
        table.remove(matches, idx)

        break
      end

    end

  end

  virtual_cursors.set_ignore_cursor_movement(false)
  return matches

end

return M
