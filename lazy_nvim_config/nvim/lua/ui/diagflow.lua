return {
    -- Lazy
    {
        "dgagn/diagflow.nvim",
        enabled = false,
        opts = {},
        config = function()
            require("diagflow").setup({
                placement = "top", -- 悬浮窗位置（右/上）
                max_width = 80, -- 最大宽度
                padding_right = 5,
                inline_padding_left = 2,
                format = function(diagnostic)
                    return string.format("[%s] %s", diagnostic.source, diagnostic.message) -- 自定义格式
                end,
            })
        end,
    },
}
