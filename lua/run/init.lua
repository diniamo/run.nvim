local M = {}

local terminal = require("run.terminal")

local function effective_cwd()
    local git = vim.fs.find(".git", { upward = true, type = "directory" })
    return git[1] or vim.uv.cwd()
end

local function prompt_command()
    return vim.fn.input("Run command: ")
end

function M.run(command, override)
    if command == "" then command = nil end

    local cwd = effective_cwd()
    -- An empty string from input() means the user didn't enter anything OR cancelled the input,
    -- so we just ignore it if that's the case.
    if override then
        command = command or prompt_command()
        if command == "" then return end

        M.cache[cwd] = command
    else
        command = command or M.cache[cwd]
        if not command then
            command = prompt_command()
            if command == "" then return end

            M.cache[cwd] = command
        end
    end

    if M.config.autosave and vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(0), "modified") then vim.cmd("silent! write") end
    if M.config.notification_format then vim.notify(string.format(M.config.notification_format, command)) end
    terminal.run_command(command, cwd)
end

function M.setup(config)
    M.config = require("run.config")(config)
    M.cache = require("run.cache")

    vim.api.nvim_create_user_command("Run", function(cmd) M.run(cmd.args, cmd.bang) end, { bang = true, nargs = "?" })
end

return M
