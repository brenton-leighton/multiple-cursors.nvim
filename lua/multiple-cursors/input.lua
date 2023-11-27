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

local motions_waiting_for_char = {
  ["f"] = "f",
  ["F"] = "F",
  ["t"] = "t",
  ["T"] = "T",
}

-- Wait for a motion character
-- Returns a normal motion command or nil if the character isn't a valid motion
function M.get_motion_char()

  -- Wait for a character
  local count = ""
  local motion
  while true do
    motion = vim.fn.getcharstr()
    if not motion or not motion:match('%d') then break end
    count = count .. motion
  end

  local char = motions_waiting_for_char[motion]
  if char then
    return count .. char .. vim.fn.getcharstr()
  end

  return count .. motions[motion]

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
