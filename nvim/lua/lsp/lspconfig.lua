local installStatus = pcall(require, "lspconfig")
local cmplspStatus = pcall(require, "cmp_nvim_lsp")

if installStatus == false then
    vim.notify("没有找到lspconfig")
    return
end

if cmplspStatus == false then
    vim.notify("没有找到cmp_nvim_lsp")
    return
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
    -- 是否启用手动触发代码完成
    -- vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

    -- disable formatting
    client.server_capabilities.document_formatting = false
    client.server_capabilities.document_range_formatting = false

    -- 自定义绑定到vim.lsp.buf的键映射
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local bufopts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
    if client.server_capabilities.implementationProvider then
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
    end

    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, bufopts)
    vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
    vim.keymap.set("n", "<space>wl", function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)
    vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, bufopts)
    vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, bufopts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)

    vim.keymap.set("n", "<space>f", function()
        vim.lsp.buf.format({ async = true })
    end, bufopts)
end

-- 增加nvim-cmp支持的额外的capabilities
-- 为了增强nvim默认的omnifunc的候选菜单

local capabilities = require("cmp_nvim_lsp").default_capabilities()
local clangd_capabilities = require("cmp_nvim_lsp").default_capabilities()
clangd_capabilities.offsetEncoding = "utf-8"

local lsp_flags = {
    -- This is the default in Nvim 0.7+
    debounce_text_changes = 150,
}
require("lspconfig")["clangd"].setup({
    single_file_support = true,
    on_attach = on_attach,
    capabilities = clangd_capabilities,
    flags = lsp_flags,
})
require("lspconfig")["pyright"].setup({
    on_attach = on_attach,
    capabilities = capabilities,
    flags = lsp_flags,
})
require("lspconfig")["sumneko_lua"].setup({
    on_attach = on_attach,
    capabilities = capabilities,
    flags = lsp_flags,
    settings = {
        Lua = {
            diagnostics = {
                globals = { "vim" },
            },
        },
    },
})
require("lspconfig")["tsserver"].setup({
    on_attach = on_attach,
    flags = lsp_flags,
})

-- require("lspconfig")["marksman"].setup({
--     on_attach = on_attach,
--     flags = lsp_flags,
-- })

-- require("lspconfig")["jsonls"].setup({
--     on_attach = on_attach,
--     flags = lsp_flags,
-- })

-- require("lspconfig")["eslint"].setup({
--     on_attach = on_attach,
--     flags = lsp_flags,
-- })

require("lspconfig")["bashls"].setup({
    on_attach = on_attach,
    flags = lsp_flags,
})
