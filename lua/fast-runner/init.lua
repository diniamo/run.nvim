local M = {}

local function effective_cwd()
    local git = vim.fs.find(".git", {upward = true, type = "directory"})
    return git[1] or vim.uv.cwd()
end

local function prompt_command()
    return vim.fn.input("Run command: ")
end

local function run_handler(cmd)
    M.run(cmd.args, cmd.bang)
end

function M.run(command, override)
    if command == "" then
        command = nil
    end

    local cwd = effective_cwd()
    if override then
        command = command or prompt_command()
        M.cache[cwd] = command
    else
        command = command or M.cache[cwd]
        if not command then
            command = prompt_command()
            M.cache[cwd] = command
        end
    end

    print("Running `" .. command .. "`")
    -- TODO: run comand
end

function M.setup()
    M.cache = require("fast-runner.cache")

    vim.api.nvim_create_user_command("Run", run_handler, {bang = true, nargs = "?"})
end

return M
