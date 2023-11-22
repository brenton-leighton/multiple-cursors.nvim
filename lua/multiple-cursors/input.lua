local M = {}

-- Valid motion keys and their normal commands
local motions = {

  ["h"] = "h",
  ["\128kl"] = "h",  -- Left
  ["\128kb"] = "h",  -- Backspace
  ["j"] = "j",
  ["\128kd"] = "j",  -- Down
  ["k"] = "k",
  ["\128ku"] = "k",  -- Up
  ["l"] = "l",
  ["\128kr"] = "l",  -- Right
  [" "] = " ",       -- Space
  ["0"] = "0",
  ["\128kh"] = "0",  -- Home
  ["^"] = "^",
  ["$"] = "$",
  ["\128@7"] = "$",  -- End
  ["|"] = "|",
  ["-"] = "-",
  ["+"] = "+",
  ["\13"] = "+",
  ["_"] = "_",
  ["w"] = "w",
  ["\128%i"] = "w",     -- Shift+Right
  ["\128\253V"] = "w",  -- Ctrl+Right
  ["W"] = "W",
  ["e"] = "e",
  ["E"] = "E",
  ["b"] = "b",
  ["\128#4"] = "b",     -- Shift+Left
  ["\128\253U"] = "b",  -- Ctrl+Left
  ["B"] = "B",

}

-- Wait for a motion character
-- Returns a normal motion command or nil if the character isn't a valid motion
function M.get_motion_char()

  -- Wait for a character
  local char = vim.fn.getcharstr()
  return motions[char]

end

-- Get a standard character
-- Returns nil for anything else
function M.get_char()

  local char = vim.fn.getcharstr()
  if #char == 1 then
    return char
  else
    return nil
  end

end

return M
