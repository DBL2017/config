return {
    -- dir = "~/projects/nvim-lsp", -- 本地插件路径
    dir = vim.fn.stdpath("config") .. "/lua/dev/nvim-diagnostic", -- 本地自研插件路径
    event = { "BufWritePost", "TextChanged", "InsertEnter", "BufEnter" },
    config = function()
        require("nvim-diagnostic").setup({})
    end,
}
