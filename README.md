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
| Normal/visual | Left/right motion | `h` `<BS>` `l` `<Space>` `0` `^` `$` `|` | |
| All | Up/down motion | `<Up>` `<Down>` | |
| Normal/visual | Up/down motion | `j` `k` `-` `+` `<CR>` `kEnter` `_` | |
| All | Text object motion | `<C-Left>` `<C-Right>` | |
| Normal/visual | Text object motion | `w` `W` `e` `E` `b` `B` | |
| Normal/visual | Percent symbol | `%` | Count is ignored i.e. [jump to match of item under cursor](https://neovim.io/doc/user/motion.html#%25) only |
| Normal | Change to insert/replace mode | `a` `A` `i` `I` `o` `O` `R` | Count is ignored |
| Normal | Change to visual mode | `v` | |
| Normal | Delete | `x` `<Del>` `X` `dd` `D` | |
| Normal | Yank | `yy` | |
| Normal | Put | `p` `P` | |
| Normal | Indentation | `>>` `<<` | |
| Normal | Join | `J` `gJ` | |
| Insert/repalce | Character insertion | | |
| Insert/replace | Other edits | `<BS>` `<Del>` `<CR>` `<Tab>` | These commands are implemented manually, and may not behave correctly <br/> In replace mode `<BS>` will only move any virtual cursors back, and not undo edits |
| Insert/replace | Paste | | By default if the number of lines in the paste text matches the number of cursors, each line of the text will be inserted at each cursor |
| Insert | Change to replace mode | `<Insert>` | |
| Visual | Swap cursor to other end of visual area | `o` | |
| Visual | Yank/delete | `y` `d` | |
| Visual | Join | `J` `gJ` | |
| Insert/replace/visual | Exit to normal mode | `<Esc>` | |
| Normal | Undo | `u` | Also exits multiple cursors, because cursor positions can't be restored by undo |
| Normal | Exit multiple cursors | `<Esc>` | Clears virtual cursors, virtual cursor registers will be lost |

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

## Notes and known issues

- Anything other than the functionality listed above probably won't work correctly
- This plugin has been developed and tested with Neovim 0.9.1 and there may be issues with other versions
- `d` and `y` in normal mode are not implemented, visual mode can be used instead
-  Using named registers is not implemented
- This plugin hasn't been tested with completion and it will probably not behave correctly
- In insert or replace mode, anything to do with tabs may not behave correctly, in particular if you are using less common options
- Please use the [Issues](https://github.com/brenton-leighton/multiple-cursors.nvim/issues) page to report issues, and please include any relevant Neovim options

## Planned features

- Create virtual cursors from search terms
