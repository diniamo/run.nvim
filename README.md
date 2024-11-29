# run.nvim

A minimalistic code runner for fast iteration.

Instead of having to configure per-project or per-extension run commands, run.nvim simply caches the last command you ran in the project, and uses that until you override it.

## Setup / Configuration

Install the plugin with your favorite plugin manager, and call the setup function with your configuration (the values below are the defaults):
```lua
require("run").setup({
    -- Automatically save the current buffer before running the command.
    auto_save = false,
    -- The format used for sending a notification before running a command,
    -- where %s represents the command (see lua's string.format). Set to nil
    -- to disable notifications. Eg. "$ %s"
    notification_format = nil,
    -- Disable number and relativenumber.
    disable_number = true,
    -- The percentage to darken the window by, eg. 0.2 makes the terminal 20%
    -- darker, whereas -0.2 makes it 20% lighter. Set to false to disable.
    darken = 0.2,
    -- This is passed directly to `nvim_open_win` (see `:help nvim_open_win`),
    -- with the exception of row, column, width and height, which are used as
    -- percentages if between 0 and 1. Eg. 0.25 takes up 25% of Neovim's.
    -- width/height.
    winopts = {
        split = "below",
        height = 0.25
    }
})
```

## Usage

The plugin consists of only one command called `Run` (and it's lua counterpart - `run.run(command, override)`). Here is how they work (only the command is explained below, but the lua function is the same, with the argument passed to the command being `command` and the bang being `override`):

1. If the command is *not* executed with a bang
    - If an argument *was* passed, use that as the command without overriding the cached one
    - If an argument was *not* passed, use the command from the cache, or prompt for one if there isn't one cached
2. If the command *is* executed with a bang
    - If an argument *was* passed, use that as the command, and override the cached one with it
    - If an argument was *not* passed, prompt for one, and override the cached command with it

It's also recommended to create mappings:

```lua
local run = require("run")

-- Runs the cached command
vim.keymap.set('n', "<leader>ri", run.run)
-- Prompts for a command, and overrides the cached one with it
vim.keymap.set('n', "<leader>ro", function() run.run(nil, true) end)
-- Prompts for a command to run, without overriding
vim.keymap.set('n', "<leader>rc", function()
    local input = vim.fn.input("Run command: ")
    if input ~= "" then run.run(input, false) end
end)
```

## API

The plugin exposes the following fields:
- `setup()` - initialization
- `run(command, override)` - main functionality, explained above
- `cache` - this is simply a table mapping paths to commands. Note that setting a field in the table will overwrite it in the cache on the disk as well.
- `config` - the configuration table in use
