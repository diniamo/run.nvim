# fast-runner.nvim

A minimalistic code runner for fast iteration.

Instead of configuring how to run projects per-language or per-project, fast-runner simply caches the last command you ran with it, and uses that until you override it.

## Setup

Install the plugin with your favorite plugin manager, and call the setup function:
```lua
require("fast-runner").setup()
```

## Usage

The plugin consists of only one command called `Run` (and it's lua counterpart - `fast-runner.run(command, override)`). Here is how they work (only the command is explained below, but the lua function is the same, with the argument passed to the command being `command` and the bang being `override`):

1. If the command is *not* executed with a bang
    - If an argument *was* passed, use that as the command without overriding the cached one
    - If an argument was *not* passed, use the command from the cache, or prompt for one if there isn't one cached
2. If the command *is* executed with a bang
    - If an argument *was* passed, use that as the command, and override the cached one with it
    - If an argument was *not* passed, prompt for one, and override the cached command with it

It's also recommended to add mappings:

```lua
local fast_runner = require("fast-runner")

-- Runs the cached command
vim.keymap.set('n', "<leader>rn", fast_runner.run)
-- Prompts for a command, and overrides the cached one with it
vim.keymap.set('n', "<leader>ro", function() fast_runner.run(nil, true) end)
-- Prompts for a command to run, without overriding
vim.keymap.set('n', "<leader>rc", function() fast_runner.run(vim.fn.input("Run command: "), false) end)
```
