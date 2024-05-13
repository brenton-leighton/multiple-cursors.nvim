# multiple-cursors.nvim

A multi-cursor plugin for Neovim that works in normal, insert/replace, or visual modes, and with almost every command.
Multiple cursors is a way of making multiple similar edits that can be easier, faster, or more flexible than other available methods.

Cursors can be added with an up or down movement, a mouse click, or by searching for a pattern.

![Basic usage](https://github.com/brenton-leighton/multiple-cursors.nvim/assets/12228142/4ea42343-6784-458c-aedb-f16b958551e3)

This plugin also has the ability to do "split pasting": When pasting text, if the number of lines of text matches the number of cursors, each line will be inserted at each cursor.

## Basic usage

For [lazy.nvim](https://github.com/folke/lazy.nvim), add a section to the plugins table, e.g.:

```lua
{
  "brenton-leighton/multiple-cursors.nvim",
  version = "*",  -- Use the latest tagged version
  opts = {},  -- This causes the plugin setup function to be called
  keys = {
    {"<C-j>", "<Cmd>MultipleCursorsAddDown<CR>", mode = {"n", "x"}, desc = "Add a cursor then move down"},
    {"<C-Down>", "<Cmd>MultipleCursorsAddDown<CR>", mode = {"n", "i", "x"}, desc = "Add a cursor then move down"},
    {"<C-k>", "<Cmd>MultipleCursorsAddUp<CR>", mode = {"n", "x"}, desc = "Add a cursor then move up"},
    {"<C-Up>", "<Cmd>MultipleCursorsAddUp<CR>", mode = {"n", "i", "x"}, desc = "Add a cursor then move up"},
    {"<C-LeftMouse>", "<Cmd>MultipleCursorsMouseAddDelete<CR>", mode = {"n", "i"}, desc = "Add or remove a cursor"},
    {"<Leader>a", "<Cmd>MultipleCursorsAddMatches<CR>", mode = {"n", "x"}, desc = "Add cursors to the word under the cursor"},
  },
},
```

This creates a number of key mappings:

- `Ctrl+j` and `Ctrl+Down`: Add a new cursor then move the real cursor down
- `Ctrl+k` and `Ctrl+Up`: Add a new cursor then move the real cursor up
- `Ctrl+LeftClick`: Add a new cursor (or remove an existing cursor) at the clicked position
- `Leader+a`: Add new cursors to matches to the pattern under the cursor

After cursors have been added, Neovim can be used mostly as normal.
See [Supported commands](#Supported-commands) for more information.

This plugin works by overriding key mappings while multiple cursors are in use.
Any user defined key mappings will need to be added to the [custom_key_maps](#custom_key_maps) table to be used with multiple cursors.

See the [Plugin compatibility](#plugin-compatibility) section for examples of how to work with specific plugins.

## User commands

The plugin creates a number of user commands:

| Command | Description |
| --- | --- |
| `MultipleCursorsAddDown` | Add a new virtual cursor, then move the real cursor down. </br> In normal or visual modes multiple new virtual cursors can be added with a `count`. |
| `MultipleCursorsAddUp` | Add a new virtual cursor, then move the real cursor up. </br> In normal or visual modes multiple new virtual cursors can be added with a `count`. |
| `MultipleCursorsMouseAddDelete` | Add a new virtual cursor to the mouse click position, or remove an existing cursor |
| `MultipleCursorsAddMatches` | Search for the word under the cursor (in normal mode) or the visual area (in visual mode) and add a new cursor to each match. By default cursors are only added to matches in the visible buffer. |
| `MultipleCursorsAddMatchesV` | As above, but limit matches to the previous visual area |
| `MultipleCursorsAddJumpNextMatch` | Add a virtual cursor to the word under the cursor (in normal mode) or the visual area (in visual mode), then move the real cursor to the next match |
| `MultipleCursorsJumpNextMatch` | Move the real cursor to the next match of the word under the cursor (in normal mode) or the visual area (in visual mode) |
| `MultipleCursorsLock` | Toggle locking the virtual cursors |

The additional commands can be mapped by adding them to the `keys` table, e.g.:

```lua
{"<Leader>A", "<Cmd>MultipleCursorsAddMatchesV<CR>", mode = {"n", "x"}, desc = "Add cursors to the word under the cursor, limited to the previous visual area"},
{"<Leader>d", "<Cmd>MultipleCursorsAddJumpNextMatch<CR>", mode = {"n", "x"}, desc = "Add a cursor then jump to the next match of the word under the cursor"},
{"<Leader>D", "<Cmd>MultipleCursorsJumpNextMatch<CR>", mode = {"n", "x"}, desc = "Jump to the next match of the word under the cursor"},
{"<Leader>l", "<Cmd>MultipleCursorsLockToggle<CR>", mode = {"n", "x"}, desc = "Toggle locking virtual cursors"},
```

## Supported commands

The following commands are supported while using multiple cursors:

| Mode | Description | Commands | Notes |
| --- | --- | --- | --- |
| All | Left/right motion | `<Left>` `<Right>` `<Home>` `<End>` | |
| Normal/visual | Left/right motion | `h` `<BS>` `l` `<Space>` `0` `^` `$` `\|` | |
| Normal/visual | Left/right motion | `f` `F` `t` `T` | These don't indicate that they're waiting for a character |
| All | Up/down motion | `<Up>` `<Down>` | |
| Normal/visual | Up/down motion | `j` `k` `-` `+` `<CR>` `kEnter` `_` | |
| All | Text object motion | `<C-Left>` `<C-Right>` | |
| Normal/visual | Text object motion | `w` `W` `e` `E` `b` `B` `ge` `gE` | |
| Normal/visual | Percent symbol | `%` | Count is ignored, i.e. [jump to match of item under cursor](https://neovim.io/doc/user/motion.html#%25) only |
| Normal | Delete | `x` `<Del>` `X` `d` `dd` `D` | `d` doesn't indicate that it's waiting for a motion. <br/> See [Registers](#registers) for information on how registers work. |
| Normal | Change | `c` `cc` `C` `s` | These commands are implemented as a delete then switch to insert mode. <br/> `c` doesn't indicate that it's waiting for a motion, and using a `w` or `W` motion may not behave exactly correctly. <br/> The `cc` command won't auto indent. <br/> See [Registers](#registers) for information on how registers work. |
| Normal | Replace | `r` | |
| Normal | Yank | `y` `yy` | `y` doesn't indicate that it's waiting for a motion. <br/> See [Registers](#registers) for information on how registers work. |
| Normal | Put | `p` `P` | See [Registers](#registers) for information on how registers work |
| Normal | Indentation | `>>` `<<` | |
| Normal | Join | `J` `gJ` | |
| Normal | Repeat | `.` | |
| Normal | Change to insert/replace mode | `a` `A` `i` `I` `o` `O` `R` | Count is ignored |
| Normal | Change to visual mode | `v` | |
| Insert/replace | Character insertion | | |
| Insert/replace | Non-printing characters | `<BS>` `<Del>` `<CR>` `<Tab>` | These commands are implemented manually, and may not behave correctly <br/> In replace mode `<BS>` will only move any virtual cursors back, and not undo edits |
| Insert/replace | Delete word before | `<C-w>` | |
| Insert/replace | Indentation | `<C-t>` `<C-d>` | |
| Insert/replace | [Completion](https://neovim.io/doc/user/usr_24.html#24.3) | `<C-n>` `<C-p>` <br/> [`<C-x> ...`](https://neovim.io/doc/user/usr_24.html#_completing-specific-items) | Using backspace while completing a word will accept the word |
| Insert | Change to replace mode | `<Insert>` | |
| Visual | Swap cursor to other end of visual area | `o` | |
| Visual | Modify visual area | `aw` `iw` `aW` `iW` `ab` `ib` `aB` `iB` `a>` `i>` `at` `it` `a'` `i'` `a"` `i"` `` a` `` `` i` `` | |
| Visual | Join lines | `J` `gJ` | |
| Visual | Indentation | `<` `>` | |
| Visual | Change case | `~` `u` `U` `g~` `gu` `gU` | |
| Visual | Yank/delete | `y` `d` `<Del>` | |
| Visual | Change | `c` | This command is implemented as a delete then switch to insert mode |
| All | Paste | | [Split pasting](#enable_split_paste) is enabled by default |
| Insert/replace/visual | Exit to normal mode | `<Esc>` | |
| Normal | Exit multiple cursors | `<Esc>` | Clears all virtual cursors. <br/> Registers for the virtual cursors will be lost. |
| Normal | Undo | `u` | Also exits multiple cursors, because cursor positions can't be restored by undo |

### Registers

The delete, yank, and put commands support named registers in addition to the unnamed register, and each virtual cursor has its own registers.

If the put command is used and a virtual cursor doesn't have a register available, the register for the real cursor will be used.
This means that if you use delete/yank before creating multiple cursors, add cursors, and then use the put command, the same text will be put to each cursor.

### Notable unsupported functionality

- Scrolling
- Jumping to marks (`` ` `` or `'` commands)

## Options

Options can be configured by providing an options table to the setup function, e.g. to define the `pre_hook` and `post_hook` functions:

```lua
{
  "brenton-leighton/multiple-cursors.nvim",
  version = "*",
  opts = {
    pre_hook = function()
      vim.opt.cursorline = false
      vim.cmd("NoMatchParen")
    end,
    post_hook = function()
      vim.opt.cursorline = true
      vim.cmd("DoMatchParen")
    end,
  },
  keys = {
    {"<C-j>", "<Cmd>MultipleCursorsAddDown<CR>", mode = {"n", "x"}, desc = "Add a cursor then move down"},
    {"<C-Down>", "<Cmd>MultipleCursorsAddDown<CR>", mode = {"n", "i", "x"}, desc = "Add a cursor then move down"},
    {"<C-k>", "<Cmd>MultipleCursorsAddUp<CR>", mode = {"n", "x"}, desc = "Add a cursor then move up"},
    {"<C-Up>", "<Cmd>MultipleCursorsAddUp<CR>", mode = {"n", "i", "x"}, desc = "Add a cursor then move up"},
    {"<C-LeftMouse>", "<Cmd>MultipleCursorsMouseAddDelete<CR>", mode = {"n", "i"}, desc = "Add or remove a cursor"},
    {"<Leader>a", "<Cmd>MultipleCursorsAddMatches<CR>", mode = {"n", "x"}, desc = "Add cursors to the word under the cursor"},
  },
},
```

### `enable_split_paste`

Default value: `true`

This option allows for disabling the "split pasting" function, where if the number of lines in the paste text matches the number of cursors, each line of the text will be inserted at each cursor.

### `match_visible_only`

Default value: `true`

When adding cursors to the word under the cursor (i.e. using the `MultipleCursorsAddMatches` command), if `match_visible_only = true` then new cursors will only be added to matches that are in the visible buffer.

### `pre_hook` and `post_hook`

Default values: `nil`

These options are to provide functions that are called when the first virtual cursor is added (`pre_hook`) and when the last virtual cursor is removed (`post_hook`).

E.g. to disable [`cursorline`](https://neovim.io/doc/user/options.html#'cursorline') and [highlighting matching parentheses](https://neovim.io/doc/user/pi_paren.html) while multiple cursors is active:

```lua
opts = {
  pre_hook = function()
    vim.opt.cursorline = false
    vim.cmd("NoMatchParen")
  end,
  post_hook = function()
    vim.opt.cursorline = true
    vim.cmd("DoMatchParen")
  end,
},
```

### `custom_key_maps`

Default value: `{}`

This option allows for mapping keys to custom functions for use with multiple cursors.
This can also be used to disable a [default key mapping](#supported-commands).

Each element in the `custom_key_maps` table must have three or four elements:

- Mode (string|table): Mode short-name string (`"n"`, `"i"` or `"x"`), or a table of mode short-name strings (for visual mode it's currently only possible to move the cursor)
- Mapping lhs (string|table): [Left-hand side](https://neovim.io/doc/user/map.html#%7Blhs%7D) of a mapping string, e.g. `">>"`, `"<Tab>"`, or `"<C-/>"`, or a table of lhs strings
- Function: A Lua function that will be called at each cursor, which receives [`register`](https://neovim.io/doc/user/vvars.html#v%3Aregister) (note: working with virtual cursor registers is not currently implemented), [`count`](https://neovim.io/doc/user/vvars.html#v%3Acount), and optionally more, as arguments. Setting this to `nil` will disable a [default key mapping](#supported-commands).
- Option: A optional string containing "m", "c", or "mc". These enable getting input from the user, which is then forwarded to the function:
	- "m" indicates that a motion command is requested (i.e. operator pending mode). The motion command can can include a count in addition to the `count` variable.
	- "c" indicates that a printable character is requested (e.g. for character search)
	- "mc" indicates that a motion command and a printable character is requested (e.g. for a surround action)
	- If valid input isn't given by the user the function will not be called
	- There will be no indication that Neovim is waiting for a motion command or character

E.g. to map `j` and `k` to `gj` and `gk` when `count` is 0 (as well as Up and Down in insert mode):

```lua
opts = {
  custom_key_maps = {
    -- Normal/visual j: use gj when count is 0
    {{"n", "x"}, {"j", "<Down>"}, function(_, count)
      if count == 0 then
        vim.cmd("normal! gj")
      else
        vim.cmd("normal! " .. count .. "j")
      end
    end},

    -- Normal/visual k: use gj when count is 0
    {{"n", "x"}, {"k", "<Up>"}, function(_, count)
      if count == 0 then
        vim.cmd("normal! gk")
      else
        vim.cmd("normal! " .. count .. "k")
      end
    end},

    -- Insert mode <Down>: Use gj
    {"i", "<Down>", function() vim.cmd("normal! gj") end},

    -- Insert mode <Up>: Use gk
    {"i", "<Up>", function() vim.cmd("normal! gk") end},
  },
},
```

The following example shows how to use various options for user input:

```lua
opts = {
  custom_key_maps = {
    -- No option
    {"n", "<Leader>a", function(register, count)
      vim.print(register .. count)
    end}

    -- Motion command
    {"n", "<Leader>b", function(register, count, motion_cmd)
      vim.print(register .. count .. motion_cmd)
    end, "m"}

    -- Character
    {"n", "<Leader>c", function(register, count, char)
      vim.print(register .. count .. char)
    end, "c"}

    -- Motion command then character
    {"n", "<Leader>d", function(register, count, motion_cmd, char)
      vim.print(register .. count .. motion_cmd .. char)
    end, "mc"}
  },
},
```

## Plugin compatibility

Plugin functions can be used from [custom key maps](#custom_key_maps).
Plugins should work even if they are lazy loaded after adding multiple cursors, because this plugin will reapply custom key mappings on the `LazyLoad` event to handle the mappings being overridden.

If it's necessary to load a plugin before using multiple cursors, you can do so in the [`pre_hook`](#pre_hook-and-post_hook) function, e.g.

```lua
pre_hook = function()
  vim.cmd(":Lazy load PLUGIN_NAME")
end,
```

Some plugins may need to be disabled while using multiple cursors.
Use the `pre_hook` function to disable the plugin, then the `post_hook` function to re-enable it.

### Examples

- [mini.move](#mini.move)
- [mini.pairs](#mini.pairs)
- [mini.surround and nvim-surround](#mini.surround-and-nvim-surround)
- [nvim-autopairs](#nvim-autopairs)
- [nvim-cmp](#nvim-cmp)
- [nvim-spider](#nvim-spider)
- [stay-in-place.nvim](#stay-in-place.nvim)
- [which-key.nvim](#which-key.nvim)

#### [mini.move](https://github.com/echasnovski/mini.move)

The plugin functions can be used as custom key maps, e.g.:

```lua
custom_key_maps = {
  {"n", {"<A-k>", "<A-Up>"}, function() MiniMove.move_line("up") end},
  {"n", {"<A-j>", "<A-Down>"}, function() MiniMove.move_line("down") end},
  {"n", {"<A-h>", "<A-Left>"}, function() MiniMove.move_line("left") end},
  {"n", {"<A-l>", "<A-Right>"}, function() MiniMove.move_line("right") end},

  {"x", {"<A-k>", "<A-Up>"}, function() MiniMove.move_selection("up") end},
  {"x", {"<A-j>", "<A-Down>"}, function() MiniMove.move_selection("down") end},
  {"x", {"<A-h>", "<A-Left>"}, function() MiniMove.move_selection("left") end},
  {"x", {"<A-l>", "<A-Right>"}, function() MiniMove.move_selection("right") end},
},
```

The plugin needs to be loaded for the `MiniMove` global variable to be available:

```lua
pre_hook = function()
  vim.cmd(":Lazy load mini.move")
end,
```

Note: moving lines up or down may not work as expected when the cursors are on sequential lines.
Use mini.move with visual line mode instead.

#### [mini.pairs](https://github.com/echasnovski/mini.pairs)

Automatically inserts and deletes paired characters.
The plugin needs to be disabled while using multiple cursors:

```lua
pre_hook = function()
  vim.g.minipairs_disable = true
end,
post_hook = function()
  vim.g.minipairs_disable = false
end,
```

#### [mini.surround](https://github.com/echasnovski/mini.surround) and [nvim-surround](https://github.com/kylechui/nvim-surround)

Adds characters to surround text.
The issue with both of these plugins is that they don't have functions that can be given the motion and character as arguments.

One workaround would be to use a different key sequence to execute the command while using multiple cursors, e.g. for mini.surround `sa` command:

```lua
custom_key_maps = {
  {"n", "<Leader>sa", function(_, count, motion_cmd, char)
    vim.cmd("normal " .. count .. "sa" .. motion_cmd .. char)
  end, "mc"},
},
```

This would map `<Leader>sa` to work like `sa`.

#### [nvim-autopairs](https://github.com/windwp/nvim-autopairs)

Automatically inserts and deletes paired characters.
The plugin needs to be disabled while using multiple cursors:

```lua
pre_hook = function()
  require('nvim-autopairs').disable()
end,
post_hook = function()
  require('nvim-autopairs').enable()
end,
```

#### [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

Text completion.
The plugin needs to be disabled while using multiple cursors:

```lua
pre_hook = function()
  require("cmp").setup({enabled=false})
end,
post_hook = function()
  require("cmp").setup({enabled=true})
end,
```

#### [nvim-spider](https://github.com/chrisgrieser/nvim-spider)

Improves `w`, `e`, and `b` motions.
For normal mode `count` must be set before nvim-spider's motion function is called:

```lua
custom_key_maps = {
  -- w
  {{"n", "x"}, "w", function(_, count)
    if  count ~=0 and vim.api.nvim_get_mode().mode == "n" then
      vim.cmd("normal! " .. count)
    end
    require('spider').motion('w')
  end},

  -- e
  {{"n", "x"}, "e", function(_, count)
    if  count ~=0 and vim.api.nvim_get_mode().mode == "n" then
      vim.cmd("normal! " .. count)
    end
    require('spider').motion('e')
  end},

  -- b
  {{"n", "x"}, "b", function(_, count)
    if  count ~=0 and vim.api.nvim_get_mode().mode == "n" then
      vim.cmd("normal! " .. count)
    end
    require('spider').motion('b')
  end},
},
```

#### [stay-in-place.nvim](https://github.com/gbprod/stay-in-place.nvim)

Maintains cursor position when indenting and unindenting.
This plugin can be used with multiple cursors by adding key maps, e.g.

```lua
custom_key_maps = {
  {"n", {">>", "<Tab>"}, function() require("stay-in-place").shift_right_line() end},
  {"n", "<<", function() require("stay-in-place").shift_left_line() end},
  {{"n", "i"}, "<S-Tab>", function() require("stay-in-place").shift_left_line() end},
},
```

#### [which-key.nvim](https://github.com/folke/which-key.nvim)

Shows a pop up of possible key bindings for a given command.
There's an issue with the normal `v` command that, if a movement command is used before `timeoutlen`, the position of the start of the visual area will be incorrect.

The best solution seems to be [disabling the command](https://github.com/folke/which-key.nvim/blob/4433e5ec9a507e5097571ed55c02ea9658fb268a/doc/which-key.nvim.txt#L321-L328), e.g. by using a plugin spec for which-key like this:

```lua
{
  "folke/which-key.nvim",
  opts = {},
  config = function(opts)
    require("which-key.plugins.presets").operators["v"] = nil
    require("which-key").setup(opts)
  end,
},
```

## Appearance

This plugin uses the following highlight groups:

- `MultipleCursorsCursor`: The cursor part of a virtual cursor (links to `Cursor` by default)
- `MultipleCursorsVisual`: The visual area part of a virtual cursor (links to `Visual` by default)

For example, colours can be defined in the `config` function of the [plugin spec](https://github.com/folke/lazy.nvim#-plugin-spec):

```lua
config = function(opts)
  vim.api.nvim_set_hl(0, "MultipleCursorsCursor", {bg="#FFFFFF", fg="#000000"})
  vim.api.nvim_set_hl(0, "MultipleCursorsVisual", {bg="#CCCCCC", fg="#000000"})

  require("multiple-cursors").setup(opts)
end,
```

Alternatively, colours could be defined in the `pre_hook` function (which runs every time multiple cursors mode is entered):

```lua
pre_hook = function()
  -- Set MultipleCursorsCursor to be slightly darker than Cursor
  local cursor = vim.api.nvim_get_hl(0, {name="Cursor"})
  cursor.bg = cursor.bg - 3355443  -- -#333333
  vim.api.nvim_set_hl(0, "MultipleCursorsCursor", cursor)

  -- Set MultipleCursorsVisual to be slightly darker than Visual
  local visual = vim.api.nvim_get_hl(0, {name="Visual"})
  visual.bg = visual.bg - 1118481  -- -#111111
  vim.api.nvim_set_hl(0, "MultipleCursorsVisual", visual)
end,
```

## API

### `add_cursor(lnum, col, curswant)`

In addition to the provided commands there is a function to add a cursor to a given position, which can be called like so:

```lua
require("multiple-cursors").add_cursor(lnum, col, curswant)
```

where `lnum` is the line number of the new cursor, `col` is the column, and `curswant` is the desired column. Typically `curswant` will be the value same as `col`, although it can be larger if the cursor position is limited by the line length. If the cursor is to be positioned at the end of a line, `curswant` would be equal to `vim.v.maxcol`.

## Notes and known issues

- In insert/replace mode, `Backspace`, `Delete`, `Enter`, or `Tab` may behave incorrectly, in particular with less common indentation options. Please use the [Issues](https://github.com/brenton-leighton/multiple-cursors.nvim/issues) page to report issues.
- Cursors may not be positioned correctly when moving up or down over extended characters, or when using the mouse to add a cursor to an extended character
- When virtual cursors are locked, switching to or from visual mode won't update the virtual cursors and should be avoided
