local M = {}

local virtual_cursors = require("multiple-cursors.virtual_cursors")

local visual_area_start = nil
local visual_area_end = nil

function M.save_previous_visual_area()
  visual_area_start = vim.api.nvim_buf_get_mark(0, "<")
  visual_area_end = vim.api.nvim_buf_get_mark(0, ">")
end

function M.get_matches_and_move_cursor(word)

  -- Save real cursor
  local cursor_pos = vim.fn.getcurpos()

  virtual_cursors.set_ignore_cursor_movement(true)

  -- If there's a saved visual area
  if visual_area_start then
    -- Move the cursor to the start of the visual area
    vim.fn.cursor({visual_area_start[1], visual_area_start[2] + 1, 0, visual_area_start[2] + 1})
  else
    -- Move cursor to start of the visible buffer
    local start_lnum = vim.fn.line("w0")
    vim.fn.cursor({start_lnum, 1, 0, 1})
  end

  -- Find matches
  local matches = {}

  local first = true
  local end_lnum = vim.fn.line("w$")

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

    -- If there's a visual area
    if visual_area_start then
      -- End if the match is past the visual area
      if match[1] >= visual_area_end[1] and match[2] > visual_area_end[2] + 1 then
        break
      end
    else
      -- No visual area
      if match[1] > end_lnum then
        -- Past the visible buffer
        break
      end
    end

    -- Add the match
    table.insert(matches, match)
  end

  -- Clear any saved visual area
  visual_area_start = nil
  visual_area_end = nil

  -- If there is one or no matches
  if #matches <= 1 then
    -- Restore the cursor and return nil
    vim.fn.cursor({cursor_pos[2], cursor_pos[3], cursor_pos[4], cursor_pos[5]})
    virtual_cursors.set_ignore_cursor_movement(false)
    return nil
  end

  -- Find the match for the real cursor
  for idx = 1, #matches do
    local match = matches[idx]

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
