return {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        require("treesitter-context").setup({
            enable = true, -- 启用插件，可通过命令动态启用或禁用
            multiwindow = false, -- 启用多窗口支持
            max_lines = 0, -- 上下文窗口显示的行数，小于等于 0 表示不限制
            min_window_height = 0, -- 启用上下文显示所需的最小窗口高度，小于等于 0 表示不限制
            line_numbers = true, -- 显示上下文行号
            multiline_threshold = 20, -- 单个上下文最多显示的行数
            trim_scope = "outer", -- 超出 max_lines 时丢弃的上下文范围，可选 inner 或 outer
            mode = "cursor", -- 计算上下文的基准行，可选 cursor 或 topline
            -- 上下文与正文之间的分隔符，通常应设置为单个字符，例如 "-"
            -- 设置分隔符后，只有光标行上方至少有两行时才显示上下文
            separator = "-",
            zindex = 20, -- 上下文窗口的 z-index
            on_attach = nil, -- 附加到缓冲区时调用，返回 false 可禁用该缓冲区的上下文
        })
    end,
}
