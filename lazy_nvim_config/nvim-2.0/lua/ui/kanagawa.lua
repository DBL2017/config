return {
    "rebelot/kanagawa.nvim",
    name = "kanagawa",
    event = "VimEnter",
    priority = 1000, -- 提高优先级，避免被其他主题覆盖
    config = function()
        require("kanagawa").setup({
            compile = true, -- 是否编译成字节码
            undercurl = true, -- 启用 undercurl
            commentStyle = { italic = true },
            keywordStyle = { italic = true },
            statementStyle = { bold = true },
            transparent = true, -- 是否透明背景
            dimInactive = true, -- 是否暗化非活动窗口
            terminalColors = true,
            theme = "wave", -- 默认主题，可选 "wave", "dragon", "lotus"
            background = {
                dark = "wave",
                light = "lotus",
            },
        })
        -- 设置 colorscheme
        vim.cmd("colorscheme kanagawa-wave")
    end,
}
