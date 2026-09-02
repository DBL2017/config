return {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
    ft = { "codecompanion", "markdown", "dap-view-help" },
    config = function()
        require("render-markdown").setup({
            -- The level of logs to write to file: vim.fn.stdpath('state') .. '/render-markdown.log'.
            -- Only intended to be used for plugin development / debugging.
            log_level = "error",
        })
    end,
}
