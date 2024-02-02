# multiple-cursors.nvim

A multiple cursors plugin for Neovim that works the way multiple cursors work in other editors (such as Visual Studio Code or JetBrains IDEs).
I.e. create extra cursors and then use Neovim as you normally would.
Cursors can be added with an up/down movement, with a mouse click, or by searching for a pattern.

This plugin also has the ability to do "split pasting": if the number of lines of paste text matches the number of cursors, each line will be inserted at each cursor (this is only implemented for pasting, and not the put commands).

The plugin works by overriding key mappings while multiple cursors are active.
Any user defined key mappings will need to be added to the [custom_key_maps](#custom_key_maps) table to be used with multiple cursors.
See the [Plugin compatibility](#plugin-compatibility) section for examples of how to work with specific plugins.

![Basic usage](https://github.com/brenton-leighton/multiple-cursors.nvim/assets/12228142/4ea42343-6784-458c-aedb-f16b958551e3)

## Overview

The plugin doesn't initially bind any keys, but creates three commands:

| Command | Description |
| --- | --- |
| `MultipleCursorsAddDown` | Add a new virtual cursor, then move the real cursor down |
| `MultipleCursorsAddUp` | Add a new virtual cursor, then move the real cursor up |
| `MultipleCursorsMouseAddDelete` | Add a new virtual cursor to the mouse click position, unless there is already a virtual cursor at the mouse click position, in which case it is removed |
| `MultipleCursorsAddBySearch` | Search for the word under the cursor (in normal mode) or the visual area (in visual mode) and add cursors to each match |
| `MultipleCursorsAddBySearchV` | As above, but limit matches to the previous visual area |

These commands can be bound to keys, e.g.:
```lua
vim.keymap.set({"n", "i"}, "<C-Down>", "<Cmd>MultipleCursorsAddDown<CR>")
```
to bind the `MultipleCursorsAddDown` command to `Ctrl+Down` in normal and insert modes.

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

Add a section to the Lazy plugins table, e.g.:
```lua
"brenton-leighton/multiple-cursors.nvim",
version = "*",  -- Use the latest tagged version
opts = {},  -- This causes the plugin setup function to be called
keys = {
  {"<C-Down>", "<Cmd>MultipleCursorsAddDown<CR>", mode = {"n", "i"}},
  {"<C-j>", "<Cmd>MultipleCursorsAddDown<CR>"},
  {"<C-Up>", "<Cmd>MultipleCursorsAddUp<CR>", mode = {"n", "i"}},
  {"<C-k>", "<Cmd>MultipleCursorsAddUp<CR>"},
  {"<C-LeftMouse>", "<Cmd>MultipleCursorsMouseAddDelete<CR>", mode = {"n", "i"}},
  {"<Leader>a", "<Cmd>MultipleCursorsAddBySearch<CR>", mode = {"n", "x"}},
  {"<Leader>A", "<Cmd>MultipleCursorsAddBySearchV<CR>", mode = {"n", "x"}},
},
```

This configures the plugin with the default options, and sets the following key maps:

- `Ctrl+Down` in normal and insert modes: `MultipleCursorsAddDown`
- `Ctrl+j` in normal mode: `MultipleCursorsAddDown`
- `Ctrl+Up` in normal and insert modes: `MultipleCursorsAddUp`
- `Ctrl+k` in normal mode: `MultipleCursorsAddUp`
- `Ctrl+LeftClick` in normal and insert modes: `MultipleCursorsMouseAddDelete`
- `Leader+a` in normal and visual modes: `MultipleCursorsAddBySearch` (note: `<Leader>` must have been set previously)
- `Leader+A` in normal and visual modes: `MultipleCursorsAddBySearchV`

## Usage

After adding a new cursor the following functions are available:

| Mode | Description | Commands | Notes |
| --- | --- | --- | --- |
| All | Left/right motion | `<Left>` `<Right>` `<Home>` `<End>` | |
| Normal/visual | Left/right motion | `h` `<BS>` `l` `<Space>` `0` `^` `$` `\|` | |
| Normal/visual | Left/right motion | `f` `F` `t` `T` | These don't indicate that they're waiting for a character |
| All | Up/down motion | `<Up>` `<Down>` | |
| Normal/visual | Up/down motion | `j` `k` `-` `+` `<CR>` `kEnter` `_` | |
| All | Text object motion | `<C-Left>` `<C-Right>` | |
| Normal/visual | Text object motion | `w` `W` `e` `E` `b` `B` `ge` `gE` | |
| Normal/visual | Percent symbol | `%` | Count is ignored i.e. [jump to match of item under cursor](https://neovim.io/doc/user/motion.html#%25) only |
| Normal | Delete | `x` `<Del>` `X` `d` `dd` `D` | `d` doesn't indicate that it's waiting for a motion |
| Normal | Change | `c` `cc` `C` `s` | These commands are implemented as a delete then switch to insert mode <br/> `c` doesn't indicate that it's waiting for a motion, and using a `w` or `W` motion may not behave exactly correctly <br/> The `cc` command won't auto indent |
| Normal | Replace | `r` | |
| Normal | Yank | `y` `yy` | `y` doesn't indicate that it's waiting for a motion |
| Normal | Put | `p` `P` | |
| Normal | Indentation | `>>` `<<` | |
| Normal | Join | `J` `gJ` | |
| Normal | Change to insert/replace mode | `a` `A` `i` `I` `o` `O` `R` | Count is ignored |
| Insert/replace | Character insertion | | |
| Insert/replace | Other edits | `<BS>` `<Del>` `<CR>` `<Tab>` | These commands are implemented manually, and may not behave correctly <br/> In replace mode `<BS>` will only move any virtual cursors back, and not undo edits |
| Insert/replace | Paste | | [Split pasting](#enable_split_paste) is enabled by default |
| Insert | Change to replace mode | `<Insert>` | |
| Normal | Change to visual mode | `v` | |
| Visual | Swap cursor to other end of visual area | `o` | |
| Visual | Modify visual area | `aw` `iw` `aW` `iW` `ab` `ib` `aB` `iB` `a>` `i>` `at` `it` `a'` `i'` `a"` `i"` `` a` `` `` i` `` | |
| Visual | Join lines | `J` `gJ` | |
| Visual | Indentation | `<` `>` | |
| Visual | Change case | `~` `u` `U` `g~` `gu` `gU` | |
| Visual | Yank/delete | `y` `d` `<Del>` | |
| Visual | Change | `c` | This command is implemented as a delete then switch to insert mode |
| Insert/replace/visual | Exit to normal mode | `<Esc>` | |
| Normal | Undo | `u` | Also exits multiple cursors, because cursor positions can't be restored by undo |
| Normal | Exit multiple cursors | `<Esc>` | Clears virtual cursors, virtual cursor registers will be lost |

Notable missing functionality:

- Scrolling
- `.` (repeat) command
- Marks

## Options

Options can be configured by providing an options table to the setup function, e.g. with Lazy:

```lua
"brenton-leighton/multiple-cursors.nvim",
version = "*",
opts = {
  enable_split_paste = true,
  custom_key_maps = {
    -- j and k: use gj/gk when count is 0
    {{"n", "x"}, {"j", "<Down>"}, function(_, count)
      if count == 0 then
        vim.cmd("normal! gj")
      else
        vim.cmd("normal! " .. count .. "j")
      end
    end},
    {{"n", "x"}, {"k", "<Up>"}, function(_, count)
      if count == 0 then
        vim.cmd("normal! gk")
      else
        vim.cmd("normal! " .. count .. "k")
      end
    end},
  },
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
  {"<C-Down>", "<Cmd>MultipleCursorsAddDown<CR>", mode = {"n", "i"}},
  {"<C-j>", "<Cmd>MultipleCursorsAddDown<CR>"},
  {"<C-Up>", "<Cmd>MultipleCursorsAddUp<CR>", mode = {"n", "i"}},
  {"<C-k>", "<Cmd>MultipleCursorsAddUp<CR>"},
  {"<C-LeftMouse>", "<Cmd>MultipleCursorsMouseAddDelete<CR>", mode = {"n", "i"}},
},
```

### `enable_split_paste`

Default value: `true`

This option allows for disabling the "split pasting" function, where if the number of lines in the paste text matches the number of cursors, each line of the text will be inserted at each cursor.

### `match_visible_only`

Default value: `true`

When adding cursors to the word under the cursor (i.e. using the `MultipleCursorsAddToWordUnderCursor` command), if `match_visible_only = true` then cursors will only be added to matches that are visible. This option doesn't apply if a visual area has been set.

### `disabled_default_key_maps`

Default value: `{}`

This option can be used to disabled any of the default key maps.
Note that this is not required if replacing the function with [custom_key_maps](#custom_key_maps).

Each element in the `disabled_default_key_maps` table must have two elements:

- Mode (string|table): Mode short-name string (`"n"`, `"i"`, or `"v"`), or a table of mode short-name strings
- Mapping lhs (string|table): [Left-hand side](https://neovim.io/doc/user/map.html#%7Blhs%7D) of a mapping string, e.g. `">>"`, `"<Tab>"`, or `"<C-/>"`, or a table of lhs strings

### `custom_key_maps`

Default value: `{}`

This option allows for mapping keys to custom functions for use with multiple cursors. Each element in the `custom_key_maps` table must have three or four elements:

- Mode (string|table): Mode short-name string (`"n"`, `"i"` or `"x"`), or a table of mode short-name strings (for visual mode it's currently only possible to move the cursor)
- Mapping lhs (string|table): [Left-hand side](https://neovim.io/doc/user/map.html#%7Blhs%7D) of a mapping string, e.g. `">>"`, `"<Tab>"`, or `"<C-/>"`, or a table of lhs strings
- Function: A Lua function that will be called at each cursor, which receives [`register`](https://neovim.io/doc/user/vvars.html#v%3Aregister) and [`count`](https://neovim.io/doc/user/vvars.html#v%3Acount) (and optionally more) as arguments
- Option: A optional string containing "m", "c", or "mc". These enable getting input from the user, which is then forwarded to the function:
	- "m" indicates that a motion command is requested (i.e. operator pending mode). The motion command can can include a count in addition to the `count` variable.
	- "c" indicates that a printable character is requested (e.g. for character search)
	- "mc" indicates that a motion command and a printable character is requested (e.g. for a surround action)
	- If valid input isn't given by the user the function will not be called
	- There will be no indication that Neovim is waiting for a motion command or character

Example usage:

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

  }
}
```

See the [Plugin compatibility](#plugin-compatibility) section for more examples.

### `pre_hook` and `post_hook`

Default values: `nil`

These options are to provide functions that are called a the start of initialisation and at the end of de-initialisation respectively.

E.g. to disable [`cursorline`](https://neovim.io/doc/user/options.html#'cursorline') and [highlighting matching parentheses](https://neovim.io/doc/user/pi_paren.html) while multiple cursors are active:

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
}
```

## Plugin compatibility

### [windwp/nvim-autopairs](https://github.com/windwp/nvim-autopairs)

Automatically inserts and deletes paired characters.
There are a couple of issues with this plugin that mean it can't be installed along with multiple-cursors.nvim (the issues are that it creates mappings on the `InsertEnter` event, and that the mappings can't be overridden).
An alternative is the [mini.pairs](#mini.pairs) plugin.

### [mini.pairs](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-pairs.md)

Automatically inserts and deletes paired characters.
If it were possible to call the plugin functions directly they could be mapped in `custom_key_maps`, but that doesn't seem to work.
Therefore the plugin needs to be disabled while using multiple cursors:

```lua
opts = {
  pre_hook = function()
    vim.g.minipairs_disable = true
  end,
  post_hook = function()
    vim.g.minipairs_disable = false
  end,
}
```

### [chrisgrieser/nvim-spider](https://github.com/chrisgrieser/nvim-spider)

Improves `w`, `e`, and `b` motions. In normal mode `count` must be set before the motion function is called.

```lua
opts = {
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
  }
}
```

### [mini.surround](https://github.com/echasnovski/mini.surround) and [kylechui/nvim-surround](https://github.com/kylechui/nvim-surround)

Adds characters to surround text.
The issue with both of these plugins is that they don't have functions that can be given the motion and character as arguments.

One workaround would be to use a different key sequence to execute the command while using multiple cursors, e.g. for mini.pairs `sa` command:

```lua
custom_key_maps = {
  {"n", "<Leader>sa", function(_, count, motion_cmd, char)
    vim.cmd("normal " .. count .. "sa" .. motion_cmd .. char)
  end, "mc"},
},
```

This would map `<Leader>sa` to work like `sa`.

### [gbprod/stay-in-place.nvim](https://github.com/gbprod/stay-in-place.nvim)

Maintains cursor position when indenting and unindenting.
This plugin can be used with multiple cursors by adding key maps, e.g.

```lua
custom_key_maps = {
  {"n", {">>", "<Tab>"}, function() require("stay-in-place").shift_right_line() end},
  {"n", "<<", function() require("stay-in-place").shift_left_line() end},
  {{"n", "i"}, "<S-Tab>", function() require("stay-in-place").shift_left_line() end},
},
```

## API

### `add_cursor(lnum, col, curswant)`
In addition to the provided commands there is a function to add a cursor to a given position, which can be called like so:

```lua
require("multiple-cursors").add_cursor(lnum, col, curswant)
```

where `lnum` is the line number of the new cursor, `col` is the column, and `curswant` is the desired column. Typically `curswant` will be the value same as `col`, although it can be larger if the cursor position is limited by the line length. If the cursor is to be positioned at the end of a line, `curswant` would be equal to `vim.v.maxcol`.

## Notes and known issues

- Anything other than the functionality listed above probably won't work correctly
- This plugin has been developed and tested with Neovim 0.9.1 and there may be issues with other versions
- This plugin hasn't been tested with completion and it will probably not behave correctly
- In insert or replace mode, if a line has been auto-indented after a carriage return and nothing has been added to the line, the indentation will not be removed when exiting back to normal mode
- In insert or replace mode, anything to do with tabs may not behave correctly, in particular if you are using less common options
- Cursors may not be positioned correctly when moving up or down over extended characters
- When using the mouse to add a cursor to an extended character, the cursor may be added to the next character
- Please use the [Issues](https://github.com/brenton-leighton/multiple-cursors.nvim/issues) page to report issues, and please include any relevant Neovim options
