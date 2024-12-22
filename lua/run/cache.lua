local cache_directory = vim.fs.joinpath(vim.fn.stdpath("data"), "run")
local cache = {}
local ensured = false

local function file_path(key)
    -- djb2
    local hash = 5381
    for i = 1, #key do
       hash = (hash * 33 + key:byte(i)) % 2147483648
    end

    return vim.fs.joinpath(cache_directory, tostring(hash))
end

local function starts_with(str, prefix)
    return str:sub(1, #prefix) == prefix
end

return setmetatable({}, {
    __index = function(_, k)
        local value = cache[k]

        if value then
            return value
        else
            local path = file_path(k)

            local stat = vim.uv.fs_stat(path)
            if not stat then return nil end

            local fd = vim.uv.fs_open(path, "r", 384)
            if not fd then return nil end

            local data = vim.uv.fs_read(fd, stat.size, 0)

            if data then cache[k] = data end
            return data
        end
    end,

    -- A check to see if we are setting the same value as what the table has
    -- would normally make sense, but that should never happen with this plugin
    __newindex = function(_, k, v)
        cache[k] = v

        local write = function()
            vim.uv.fs_open(file_path(k), "w+", 384, function(err, fd)
                if err then
                    vim.notify("Failed to open file: " .. err, vim.log.levels.ERROR)
                    return
                end

                vim.uv.fs_write(fd, v, function(err)
                    if err then
                        vim.notify("Failed to write to file: " .. err, vim.log.levels.ERROR)
                    end

                    vim.uv.fs_close(fd, function(err)
                        if err then
                            vim.notify("Failed to close file: " .. err, vim.log.levels.ERROR)
                        end
                    end)
                end)
            end)
        end

        if ensured then
            write()
        else
            vim.uv.fs_stat(cache_directory, function(err)
                if err then
                    if starts_with(err, "ENOENT") then
                        vim.uv.fs_mkdir(cache_directory, 448, function(err, ok)
                            if ok then
                                ensured = true
                                write()
                            else
                                vim.notify("Failed to create directory: " .. err)
                            end
                        end)
                    else
                        vim.notify("Failed to stat directory: " .. err, vim.log.levels.ERROR)
                    end
                else
                    ensured = true
                    write()
                end
            end)
        end
    end
})
