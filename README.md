# multiple-cursors.nvim

A multiple cursors plugin for Neovim.

Most of the basic Neovim functions are working. See the [Usage](#usage) section for more information.

The plugin doesn't initially bind any keys, but creates three commands:
| Command | Description |
| --- | --- |
| `MultipleCursorsAddDown` | Add a new virtual cursor, then move the real cursor down |
| `MultipleCursorsAddUp` | Add a new virtual cursor, then move the real cursor up |
| `MultipleCursorsMouseAddDelete` | Add a new virtual cursor to the mouse click position, unless there is already a virtual cursor at the mouse click position, in which case it is removed |

These commands can be bound to keys, e.g.:
```
vim.keymap.set({"n", "i"}, "<C-Down>", "<Cmd>MultipleCursorsAddDown<CR>")
```
to bind the `MultipleCursorsAddDown` command to `Ctrl+Down` in normal and insert modes.

## Demo videos

### Basic usage

https://github.com/brenton-leighton/multiple-cursors.nvim/assets/12228142/4d8ee172-3c32-4ad7-ac0f-f180c6890e64

### Pasting

https://github.com/brenton-leighton/multiple-cursors.nvim/assets/12228142/3af9bfcd-78c0-4f03-8e84-665e10749398

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

Add a section to the Lazy plugins table, e.g.:
```
"brenton-leighton/multiple-cursors.nvim",
config = true,
keys = {
  {"<C-Down>", "<Cmd>MultipleCursorsAddDown<CR>", mode = {"n", "i"}},
  {"<C-j>", "<Cmd>MultipleCursorsAddDown<CR>"},
  {"<C-Up>", "<Cmd>MultipleCursorsAddUp<CR>", mode = {"n", "i"}},
  {"<C-k>", "<Cmd>MultipleCursorsAddUp<CR>"},
  {"<C-LeftMouse>", "<Cmd>MultipleCursorsMouseAddDelete<CR>", mode = {"n", "i"}},
},
```

This configures the plugin with the default options, and sets the following key maps:

- `Ctrl+Down` in normal and insert modes: `MultipleCursorsAddDown`
- `Ctrl+j` in normal mode: `MultipleCursorsAddDown`
- `Ctrl+Up` in normal and insert modes: `MultipleCursorsAddUp`
- `Ctrl+k` in normal mode: `MultipleCursorsAddUp`
- `Ctrl+LeftClick` in normal and insert modes: `MultipleCursorsMouseAddDelete`

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
| Normal | Change | `c` `cc` `C` | `c` doesn't indicate that it's waiting for a motion, and using a `w` or `W` motion may not behave exactly correctly <br/> The `cc` command won't auto indent |
| Normal | Yank | `y` `yy` | `y` doesn't indicate that it's waiting for a motion |
| Normal | Put | `p` `P` | |
| Normal | Indentation | `>>` `<<` | |
| Normal | Join | `J` `gJ` | |
| Normal | Change to insert/replace mode | `a` `A` `i` `I` `o` `O` `R` | Count is ignored |
| Insert/repalce | Character insertion | | |
| Insert/replace | Other edits | `<BS>` `<Del>` `<CR>` `<Tab>` | These commands are implemented manually, and may not behave correctly <br/> In replace mode `<BS>` will only move any virtual cursors back, and not undo edits |
| Insert/replace | Paste | | By default if the number of lines in the paste text matches the number of cursors, each line of the text will be inserted at each cursor |
| Insert | Change to replace mode | `<Insert>` | |
| Normal | Change to visual mode | `v` | |
| Visual | Swap cursor to other end of visual area | `o` | |
| Visual | Modify visual area | `aw` `iw` `aW` `iW` `ab` `ib` `aB` `iB` `a>` `i>` `at` `it` `a'` `i'` `a"` `i"` `` a` `` `` i` `` | |
| Visual | Join lines | `J` `gJ` | |
| Visual | Indentation | `<` `>` | |
| Visual | Change case | `~` `u` `U` `g~` `gu` `gU` | |
| Visual | Yank/delete | `y` `d` `<Del>` | |
| Insert/replace/visual | Exit to normal mode | `<Esc>` | |
| Normal | Undo | `u` | Also exits multiple cursors, because cursor positions can't be restored by undo |
| Normal | Exit multiple cursors | `<Esc>` | Clears virtual cursors, virtual cursor registers will be lost |

Notable missing functionality:

- Named registers
- `.` (repeat) command

## Options

Options can be configured by providing an options table to the setup function, e.g. with Lazy:

```
"brenton-leighton/multiple-cursors.nvim",
opts = {
  enable_split_paste = false,
  disabled_default_key_maps = {
    {{"n", "x"}, {"<S-Left>", "<S-Right>"}},
  },
  custom_key_maps = {
    {{"n", "i"}, "<C-/>", function() vim.cmd("ExampleCommand") end},
  },
  pre_hook = function() vim.print("Hello") end,
  post_hook = function() vim.print("Goodbye") end,
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

### `disabled_default_key_maps`

Default value: `{}`

This option can be used to disabled any of the default key maps. Each element in the `disabled_default_key_maps` table must have two elements:

- Mode (string|table): Mode short-name string (`"n"`, `"i"`, or `"v"`), or a table of mode short-name strings
- Mapping lhs (string|table): [Left-hand side](https://neovim.io/doc/user/map.html#%7Blhs%7D) of a mapping string, e.g. `">>"`, `"<Tab>"`, or `"<C-/>"`, or a table of lhs strings

### `custom_key_maps`

Default value: `{}`

This option allows for mapping keys to custom functions for use with multiple cursors. Each element in the `custom_key_maps` table must have three elements:

- Mode (string|table): Mode short-name string (`"n"`, `"i"`, or `"v"`), or a table of mode short-name strings
- Mapping lhs (string|table): [Left-hand side](https://neovim.io/doc/user/map.html#%7Blhs%7D) of a mapping string, e.g. `">>"`, `"<Tab>"`, or `"<C-/>"`, or a table of lhs strings
- Function: Lua function, e.g. `function() vim.cmd("ExampleCommand") end`

When a mapping is executed the given function will be called at each cursor.

### `pre_hook` and `post_hook`

Default values: `nil`

These options are to provide functions that are called a the start of initialisation and at the end of de-initialisation respectively.

## API

### `add_cursor(lnum, col, curswant)`
In addition to the provided commands there is a function to add a cursor to a given position, which can be called like so:

```
require("multiple-cursors").add_cursor(lnum, col, curswant)
```

where `lnum` is the line number of the new cursor, `col` is the column, and `curswant` is the desired column. Typically `curswant` will be the value same as `col`, although it can be larger if the cursor position is limited by the line length. If the cursor is to be positioned at the end of a line, `curswant` would be equal to `vim.v.maxcol`.

## Notes and known issues

- Anything other than the functionality listed above probably won't work correctly
- This plugin has been developed and tested with Neovim 0.9.1 and there may be issues with other versions
- This plugin hasn't been tested with completion and it will probably not behave correctly
- In insert or replace mode, if a line has been auto-indented after a carriage return and nothing has been added to the line, the indentation will not be removed when exiting back to normal mode
- In insert or replace mode, anything to do with tabs may not behave correctly, in particular if you are using less common options
- Please use the [Issues](https://github.com/brenton-leighton/multiple-cursors.nvim/issues) page to report issues, and please include any relevant Neovim options

## Planned features

- Create virtual cursors from a search
- `.` (repeat) command
