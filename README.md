# runit.nvim

A minimalistic code runner for fast iteration.

Instead of configuring how to run projects per-language or per-project, runit simply caches the last command you ran with it, and uses that until you override it.

## Setup

Install the plugin with your favorite plugin manager, and call the setup function:
```lua
require("runit").setup()
```

## Usage

The plugin consists of only one command called `Run` (and it's lua counterpart - `runit.run(command, override)`). Here is how they work (only the command is explained below, but the lua function is the same, with the argument passed to the command being `command` and the bang being `override`):

1. If the command is *not* executed with a bang
    - If an argument *was* passed, use that as the command without overriding the cached one
    - If an argument was *not* passed, use the command from the cache, or prompt for one if there isn't one cached
2. If the command *is* executed with a bang
    - If an argument *was* passed, use that as the command, and override the cached one with it
    - If an argument was *not* passed, prompt for one, and override the cached command with it

It's also recommended to add mappings:

```lua
local runit = require("runit")

-- Runs the cached command
vim.keymap.set('n', "<leader>rn", runit.run)
-- Prompts for a command, and overrides the cached one with it
vim.keymap.set('n', "<leader>ro", function() runit.run(nil, true) end)
-- Prompts for a command to run, without overriding
vim.keymap.set('n', "<leader>rc", function() runit.run(vim.fn.input("Run command: "), false) end)
```

## API

The plugin exposes the following fields:
- `setup()` - initialization
- `run(command, override)` - main functionality, explained above
- `cache` - this is simply a table mapping paths to commands. Note that setting a field in the table will overwrite it in the cache on the disk as well.
