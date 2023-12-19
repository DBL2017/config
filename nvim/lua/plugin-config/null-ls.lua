local installStatus = pcall(require, "null-ls")
if installStatus == false then
    vim.notify("没有找到null-ls")
    return
end

local null_ls = require("null-ls")
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

null_ls.setup({
    debug = true,
    sources = {
        -- format lua
        null_ls.builtins.formatting.stylua.with({
            filetypes = { "lua" },
        }),
        -- c,object c,c++ format
        null_ls.builtins.formatting.clang_format.with({
            filetypes = { "c", "cpp", "cs", "java", "cuda" },
        }),
        -- cmake format
        null_ls.builtins.formatting.cmake_format.with({
            filetypes = { "cmake" },
        }),
        -- Filetypes:
        null_ls.builtins.formatting.prettierd.with({
            filetypes = {
                "javascript",
                "javascriptreact",
                "typescript",
                "typescriptreact",
                "vue",
                "css",
                "scss",
                "less",
                "html",
                "yaml",
                "markdown",
                "markdown.mdx",
                "graphql",
                "handlebars",
            },
        }),
        null_ls.builtins.formatting.jq.with({
            filetypes = { "json" },
        }),
        -- python format
        null_ls.builtins.formatting.black.with({
            filetypes = { "python" },
        }),
        -- Filetypes: { "bash", "csh", "ksh", "sh", "zsh" }
        null_ls.builtins.formatting.beautysh.with({
            filetypes = { "bash", "csh", "ksh", "sh", "zsh" },
        }),

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
        -- null_ls.builtins.diagnostics.eslint,

        null_ls.builtins.code_actions.shellcheck,
        -- null_ls.builtins.completion.spell,
    },
    -- you can reuse a shared lspconfig on_attach callback here
    on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = augroup,
                buffer = bufnr,
                callback = function()
                    -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
                    vim.lsp.buf.format({ bufnr = bufnr })
                end,
            })
        end
    end,
})
