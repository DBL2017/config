return {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        require("treesitter-context").setup({
            enable = true,
            max_lines = 5, -- 显示的行数
            trim_scope = "outer", -- 显示外层结构
            patterns = {
                default = {
                    "class",
                    "function",
                    "method",
                    "for",
                    "while",
                    "if",
                    "switch",
                    "case",
                },
            },
        })
    end,
}
