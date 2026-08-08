return {
    -- dir = "~/projects/nvim-lsp", -- 本地插件路径
    dir = vim.fn.stdpath("config") .. "/lua/dev/nvim-lsp", -- 本地自研插件路径
    dependencies = {
        "saghen/blink.cmp", -- 自动依赖 blink.cmp
    },
    cmd = { "LspAttachAll", "LspAttachBuffer", "LspDetachAll", "LspDetachBuffer", "LspDetachOthers" },
    lazy = false,
    config = function()
        require("nvim-lsp").setup({
            auto_attach = false, -- 自动附加 LSP
        })
    end,
}
