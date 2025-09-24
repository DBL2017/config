return {
    "mason-org/mason-lspconfig.nvim",
    opts = {
        -- A list of servers to automatically install if they're not already installed. Example: { "rust_analyzer@nightly", "lua_ls" }
        ---@type string[]
        ensure_installed = { "clangd", "cmake", "pyright", "lua_ls", "bashls", "ts_ls", "vale_ls", "yamlls" },
        -- Whether installed servers should automatically be enabled via `:h vim.lsp.enable()`.
        --
        -- To exclude certain servers from being automatically enabled:
        -- ```lua
        --   automatic_enable = {
        --     exclude = { "rust_analyzer", "ts_ls" }
        --   }
        -- ```
        --
        -- To only enable certain servers to be automatically enabled:
        -- ```lua
        --   automatic_enable = {
        --     "lua_ls",
        --     "vimls"
        --   }
        -- ```
        ---@type boolean | string[] | { exclude: string[] }
        ---@是否自动启动自动安装的lsp server
        automatic_enable = {
            exclude = { "stylua" },
        },
    },
    dependencies = {
        { "mason-org/mason.nvim", opts = {} },
        "neovim/nvim-lspconfig",
    },
}
