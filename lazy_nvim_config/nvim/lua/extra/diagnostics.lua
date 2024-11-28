-- Configure lsp information display style
local M = {}

M.setup = function()
    -- replace the lsp info symbol
    -- local signs = {
    --     { name = "DiagnosticSignError", text = "E" },
    --     { name = "DiagnosticSignWarn",  text = "W" },
    --     { name = "DiagnosticSignHint",  text = "H" },
    --     { name = "DiagnosticSignInfo",  text = "I" },
    -- }

    -- for _, sign in ipairs(signs) do
    --     vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
    -- end

    -- set the style of lsp info
    local config = {
        -- disable virtual text
        -- the message show after the current line.
        virtual_text = false,
        -- show signs
        signs = {
            -- active = signs,
            text = {
                [vim.diagnostic.severity.ERROR] = "E",
                [vim.diagnostic.severity.WARN] = "W",
                [vim.diagnostic.severity.HINT] = "H",
                [vim.diagnostic.severity.INFO] = "I"
            }
        },
        update_in_insert = true,
        underline = false,
        severity_sort = true,
        float = {
            focusable = false,
            style = "minimal",
            border = "rounded",
            source = "always",
            header = "",
            prefix = "",
        },
    }

    vim.diagnostic.config(config)

    -- set the popup window border
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
        border = "rounded",
    })

    vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
        border = "rounded",
    })
end

return M
