# fold-cycle.nvim

This neovim plugin allows you to cycle folds open or closed.

[![asciicast](https://asciinema.org/a/476184.svg)](https://asciinema.org/a/476184)

This plugin is inspired by and borrows (heavily!) from [vim-fold-cycle](https://github.com/arecarn/vim-fold-cycle).

## Installation

With lazy:

```lua
{
  'neeshy/fold-cycle.nvim',
  keys = {
    { '<CR>', function() require('fold-cycle').open() end, desc = 'Open folds recursively' },
    { '<BS>', function() require('fold-cycle').close() end, desc = 'Close folds recursively' },
    { 'zO', function() require('fold-cycle').open_all() end, desc = 'Open all folds under cursor recursively' },
    { 'zC', function() require('fold-cycle').close_all() end, desc = 'Close all folds under cursor recursively' },
    { 'zA', function() require('fold-cycle').toggle_all() end, desc = 'Toggle all folds under cursor recursively' },
  },
},
```
