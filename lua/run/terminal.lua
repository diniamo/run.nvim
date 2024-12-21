local M = {}

local bit = require("bit")
local config = require("run.config")

local terminal = {}

local function round(n)
    local f = math.floor(n)
    return (n - f) < 0.5 and f or math.ceil(n)
end

local function darken(color, amount)
    local r = bit.band(bit.rshift(color, 16), 0xFF)
    local g = bit.band(bit.rshift(color, 8), 0xFF)
    local b = bit.band(color, 0xFF)

    local multiplier = 1 - amount
    r = round(r * multiplier)
    g = round(g * multiplier)
    b = round(b * multiplier)

    return string.format("#%02x%02x%02x", r, g, b)
end

local function normalize(val, max)
    if val < 0 then
        return 0
    elseif val <= 1 then
        return round(max * val)
    else
        return val
    end
end

local function normalize_table(t)
    local new = {}

    for k, v in pairs(t) do
        if k == "row" or k == "height" then
            new[k] = normalize(v, vim.o.lines)
        elseif k == "column" or k == "width" then
            new[k] = normalize(v, vim.o.columns)
        else
            new[k] = v
        end
    end

    return new
end

local function prepare()
    if terminal.jobid then
        vim.fn.jobstop(terminal.jobid)
    end


    -- Resetting the buffer state is more trouble then worth, so we just create a new one
    local previous_buffer = terminal.buffer
    terminal.buffer = vim.api.nvim_create_buf(false, false)

    vim.keymap.set('t', "<Esc>", "<C-\\><C-n>", { buffer = terminal.buffer })


    if not terminal.window or not vim.api.nvim_win_is_valid(terminal.window) then
        terminal.window = vim.api.nvim_open_win(terminal.buffer, false, normalize_table(config.winopts))

        local wo = vim.wo[terminal.window]

        wo.cursorline = false

        local split = config.winopts.split
        if split == "left" or split == "right" then
            wo.winfixwidth = true
        elseif split == "above" or split == "below" then
            wo.winfixheight = true
        end

        if config.disable_number then
            wo.number = false
            wo.relativenumber = false
        end

        if config.darken then
            local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
            if normal.bg then
                normal.bg = darken(normal.bg, config.darken)
                vim.api.nvim_set_hl(0, "RunNormal", normal)

                wo.winhighlight = "Normal:RunNormal"
            end
        end
    else
        vim.api.nvim_win_set_buf(terminal.window, terminal.buffer)
    end


    if previous_buffer then
        vim.api.nvim_buf_delete(previous_buffer, {})
    end
end

function M.run_command(command, directory)
    prepare()

    local id = vim.api.nvim_buf_call(terminal.buffer, function()
        local opts = { cwd = directory }

        if config.auto_scroll then
            local scroll = function()
                if vim.api.nvim_buf_is_valid(terminal.buffer) and vim.api.nvim_buf_is_loaded(terminal.buffer) then
                    vim.api.nvim_buf_call(terminal.buffer, function()
                        local mode = vim.api.nvim_get_mode().mode
                        if mode == "n" or mode == "nt" then vim.cmd("normal! G") end
                    end)
                end
            end

            opts.on_stdout = scroll
            opts.on_stderr = scroll
        end

        return vim.fn.termopen(command, opts)
    end)

    if id == -1 then
        if type(command) == "string" then
            vim.notify("Shell (" .. vim.o.shell .. ") is not executable.", vim.log.levels.ERROR)
        else
            vim.notify(command[0] .. " is not executable.", vim.log.levels.ERROR)
        end
    else
        terminal.jobid = id
    end
end

return M
