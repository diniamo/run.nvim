local M = {
    config = {
        auto_save = false,
        notification_format = nil,
        disable_number = true,
        darken = 0.2,
        winopts = {
            split = "below",
            height = 0.25
        },
        auto_scroll = true
    }
}

local terminal = nil

local function effective_cwd()
    local git = vim.fs.find(".git", { upward = true, type = "directory" })
    return git[1] or vim.uv.cwd()
end

local function highlight(input)
    local ok, parser = pcall(vim.treesitter.get_string_parser, input, vim.fs.basename(vim.o.shell))
    if not ok then
        ok, parser = pcall(vim.treesitter.get_string_parser, input, "bash")
        if not ok then
            return {}
        end
    end

    local tree = parser:parse()[1]
    local query = vim.treesitter.query.get(parser:lang(), "highlights")

    local highlights = {}
    for id, node in query:iter_captures(tree:root(), input) do
        local _, cstart, _, cend = node:range()
        table.insert(highlights, { cstart, cend, "@" .. query.captures[id] })
    end
    return highlights
end

local function run_command(command, cwd)
    if M.config.auto_save and vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(0), "modified") then
        vim.cmd("write")
    end
    if M.config.notification_format then
        vim.notify(string.format(M.config.notification_format, command))
    end

    terminal.run_command(M.config, command, cwd)
end

local function prompt(default, callback)
    vim.ui.input({
        prompt = "Run command: ",
        default = default,
        completion = "shellcmd",
        highlight = highlight
    }, function(input)
        if input then
            callback(input)
        end
    end)
end

local function prompt_new(previous, cwd)
    prompt(previous, function(command)
        M.cache[cwd] = command
        run_command(command, cwd)
    end)
end

function M.run(command, override)
    local cwd = effective_cwd()

    if override then
        if command then
            M.cache[cwd] = command
            run_command(command, cwd)
        else
            prompt_new(M.cache[cwd], cwd)
        end
    else
        command = command or M.cache[cwd]

        if command then
            run_command(command, cwd)
        else
            prompt_new(nil, cwd)
        end
    end
end

function M.run_prompt()
    prompt(nil, run_command)
end

function M.setup(user_config)
    if user_config then
        M.config = vim.tbl_deep_extend("force", M.config, user_config)
    end

    M.cache = require("run.cache")
    terminal = require("run.terminal")

    vim.api.nvim_create_user_command("Run", function(cmd)
        if cmd.args == "" then
            M.run(nil, cmd.bang)
        else
            M.run(cmd.args, cmd.bang)
        end
    end, { bang = true, nargs = "?" })
end

return M
