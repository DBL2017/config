-- diagnostic
vim.diagnostic.config({
    float = {
        scope = "line",
        severity_sort = true,
        header = "Diagnostics",
        source = "if_many",
        format = function(diag)
            local severity_map = { [1] = "ERROR", [2] = "WARN", [3] = "INFO", [4] = "HINT" }
            return string.format("[%s] %s", severity_map[diag.severity], diag.message)
        end,
        border = "rounded", -- 使用内置圆角边框（直接生效）
    },
})
-- lsp全局配置
vim.lsp.set_log_level("debug")
local capabilities = require("cmp_nvim_lsp").default_capabilities()
local lsp_flags = {
    -- This is the default in Nvim 0.7+
    debounce_text_changes = 150,
}
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
    -- vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
    -- if client.server_capabilities.implementationProvider then
    --     vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
    -- end

    -- vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
    -- vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, bufopts)
    -- vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
    -- vim.keymap.set("n", "<space>wl", function()
    -- print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    -- end, bufopts)
    -- vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, bufopts)
    -- vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, bufopts)
    -- vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, bufopts)
    -- vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)

    -- vim.keymap.set("n", "<space>f", function()
    --     vim.lsp.buf.format({ async = true })
    -- end, bufopts)
end
vim.lsp.config("*", {
    capabilities = capabilities,
    flags = lsp_flags,
    on_attach = on_attach,
})

-- lua
vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            runtime = "LuaJIT",
            diagnostics = {
                globals = { "vim" },
            },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = {
                enable = false,
            },
        },
    },
})
vim.lsp.enable("lua_ls", true)

-- clangd
local clangd_capabilities = require("cmp_nvim_lsp").default_capabilities()
clangd_capabilities.offsetEncoding = "utf-8"
vim.lsp.config("clangd", {
    single_file_support = true,
    capabilities = clangd_capabilities,
    settings = {
        C = {
            diagnostics = false,
        },
    },
})
vim.lsp.enable("clangd", true)

-- vim.lsp.enable({ "pyright", "tsserver", "marksman", "jsonls", "eslint", "bashls", "cmake" }, true)
vim.lsp.enable({ "pyright", "cmake", "jsonls", "bashls" })
