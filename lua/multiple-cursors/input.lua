local M = {}

-- For checking if a character is a digit
local digits = {

  ["0"] = true,
  ["1"] = true,
  ["2"] = true,
  ["3"] = true,
  ["4"] = true,
  ["5"] = true,
  ["6"] = true,
  ["7"] = true,
  ["8"] = true,
  ["9"] = true,

}

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
  ["\13"] = "+",     -- Enter
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

-- Motion commands that need a following standard character
local search_motions = {
  ["f"] = true,
  ["F"] = true,
  ["t"] = true,
  ["T"] = true,
}

-- The second character in a text object selection
local text_object_selections = {

  ["w"] = true,
  ["W"] = true,
  ["s"] = true,
  ["p"] = true,
  ["]"] = true,
  ["["] = true,
  [")"] = true,
  ["("] = true,
  ["b"] = true,
  ["B"] = true,
  [">"] = true,
  ["<"] = true,
  ["t"] = true,
  ["}"] = true,
  ["{"] = true,
  ["\'"] = true,
  ["\""] = true,
  ["`"] = true,

}

-- Get a standard character and returns nil for anything else
function M.get_char()

  local dec = vim.fn.getchar()

  -- Check for non ASCII special characters
  if type(dec) ~= "number" then
    return nil
  end

  -- Check for ASCII special characters
  if dec < 32 or dec == 127 then
    return nil
  end

  -- Convert decimal to char and return
  return vim.fn.nr2char(dec)

end

-- Get two standard characters
function M.get_two_chars()

  local char1 = M.get_char()

  if char1 == nil then
    return nil, nil
  end

  local char2 = M.get_char()

  if char2 == nil then
    return nil, nil
  end

  return char1, char2

end

-- Get the second character of a text object selection
function M.get_text_object_sel_second_char()
  local char = vim.fn.getcharstr()

  -- If the character is a valid text object selection second character
  if text_object_selections[char] then
    return char
  end

  return nil
end

-- Wait for a motion command
-- Returns a normal motion command (which may include a count) or nil if no
-- valid motion was given
function M.get_motion_cmd()

  -- Wait for a character
  local motion_char = vim.fn.getcharstr()

  local count = ""

  -- If the character is a digit
  while digits[motion_char] do
      -- Concatenate
      count = count .. motion_char

      -- Get another character
      motion_char = vim.fn.getcharstr()
  end

  -- If the character is a character search motion
  if search_motions[motion_char] then
    -- Wait for a printable character
    local char = M.get_char()

    if char then -- Valid character
      return count .. motion_char .. char
    end

    return nil
  end

  -- If the character is a text object selection first character
  if motion_char == "a" or motion_char == "i" then
    -- Get a text object selection second character
    local char2 = M.get_text_object_sel_second_char()

    if char2 then
      return count .. motion_char .. char2
    end

    return nil
  end

  -- If the character is a valid motion
  if motions[motion_char] then
    return count .. motions[motion_char]
  end

  return nil

end

return M
