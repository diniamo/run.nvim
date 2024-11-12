local function load_json(path)
    local file = io.open(path, "r")
    return vim.json.decode(file:read("*all"))
end

local cache_path = vim.fs.joinpath(vim.fn.stdpath("data"), "runit_cache.json")

local ok, cache = pcall(load_json, cache_path)
if not ok then
    cache = {}
end

local cache_proxy = setmetatable({}, {
    __index = cache,
    __newindex = function(_, k, v)
        if cache[k] ~= v then
            cache[k] = v

            vim.uv.fs_open(cache_path, "w+", 384, function(err, fd)
                if err then
                    vim.notify("Failed to open file: " .. err, vim.log.levels.ERROR)
                    return
                end

                vim.uv.fs_write(fd, vim.json.encode(cache), function(err)
                    if err then
                        vim.notify("Failed to write to file: " .. err, vim.log.levels.ERROR)
                        return
                    end

                    vim.uv.fs_close(fd, function(err)
                        if err then
                            vim.notify("Failed to close file: " .. err, vim.log.levels.ERROR)
                        end
                    end)
                end)
            end)
        end
    end
})

return cache_proxy
