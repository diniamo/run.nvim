local config = {
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

local proxy = {}
return setmetatable(proxy, {
    __call = function(_, merge)
        config = vim.tbl_deep_extend("force", config, merge)
        return proxy
    end,
    __index = function(_, k) return config[k] end,
    __newindex = nil
})
