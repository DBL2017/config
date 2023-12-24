local installStatus = pcall(require, "null-ls")
if installStatus == false then
    vim.notify("没有找到null-ls")
    return
end

local null_ls = require("null-ls")

null_ls.setup({
    debug = true,
    sources = {
        -- shell diagnostic
        null_ls.builtins.diagnostics.markdownlint.with({
            method = null_ls.methods.DIAGNOSTICS_ON_SAVE,
            diagnostic_config = {
                -- see :help vim.diagnostic.config()
                underline = true,
                virtual_text = true,
                signs = true,
                update_in_insert = false,
                severity_sort = true,
            },
            extra_args = { "--disable", "MD013" },
        }),

        null_ls.builtins.diagnostics.jsonlint,
        null_ls.builtins.diagnostics.cmake_lint,
        -- null_ls.builtins.diagnostics.eslint,

        null_ls.builtins.code_actions.shellcheck,
        -- null_ls.builtins.completion.spell,
    },
})
