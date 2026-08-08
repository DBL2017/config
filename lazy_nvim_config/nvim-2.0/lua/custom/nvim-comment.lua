return {
    -- dir = "~/projects/nvim-lsp", -- 本地插件路径
    dir = vim.fn.stdpath("config") .. "/lua/dev/nvim-comment", -- 本地自研插件路径
    cmd = { "NvimComment", "NvimCommentGenerate" },
    config = function()
        require("nvim-comment").setup({
            -- only enable for c and lua (nil means all filetypes enabled)
            enabled_filetypes = { "c", "cpp", "lua" },

            -- optional: override or add templates per filetype and kind
            templates = {
                -- c = {
                --     ["function"] = {
                --         "/*",
                --         " * ${function_state} -- auto-generated",
                --         " * Brief: ",
                --         " */",
                --     },
                -- },
                -- lua can use the default templates (omit to use default)
            },
        })
    end,
}
