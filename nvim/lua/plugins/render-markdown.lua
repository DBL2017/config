return {
    "DBL2017/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
    ft = { "codecompanion", "markdown", "dap-view-help" },
    config = function()
        require("render-markdown").setup({
            debounce = 200, -- 默认 100ms，合并更密集的渲染更新
            preset = "obsidian",
            pipe_table = {
                row_separator = true,
            },
            -- The level of logs to write to file: vim.fn.stdpath('state') .. '/render-markdown.log'.
            -- Only intended to be used for plugin development / debugging.
            log_level = "error",
        })
    end,
}
