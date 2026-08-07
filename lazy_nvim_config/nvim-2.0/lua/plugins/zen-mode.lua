-- Lua
return {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    config = function()
        require("zen-mode").setup({
            window = {
                backdrop = 0.2,
                width = 1, -- 或者 0（表示占满）
            },

            plugins = {
                options = {
                    enabled = true,
                    ruler = false,
                    showcmd = false,
                    laststatus = 0,
                },
            },
        })
    end,
}
