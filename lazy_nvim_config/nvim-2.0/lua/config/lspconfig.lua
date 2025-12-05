-- lsp全局配置
vim.lsp.set_log_level("warn")

-- 解决插件缺失导致的配置错误问题
local blink_ok, blink_err = pcall(require, "blink.cmp")
local nvim_cmp_ok, nvim_cmp_err = pcall(require, "cmp")
local global_capabilities = nil

if blink_ok then
    global_capabilities = require("blink.cmp").get_lsp_capabilities()
elseif nvim_cmp_ok then
    global_capabilities = require("cmp_nvim_lsp").default_capabilities()
end

local global_flags = {
    -- This is the default in Nvim 0.7+
    debounce_text_changes = 150,
}
local global_on_attach = function(client, bufnr)
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

if global_capabilities then
    vim.lsp.config("*", {
        capabilities = global_capabilities,
        flags = global_flags,
        on_attach = global_on_attach,
    })
    -- 自动启动时的相关配置
    -- lua
    vim.lsp.config("lua_ls", {
        settings = {
            Lua = {
                hint = {
                    enable = true, -- necessary
                },
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

    -- clangd
    -- 自动启动
    local clangd_capabilities = global_capabilities
    clangd_capabilities.offsetEncoding = "utf-8"
    vim.lsp.config("clangd", {
        single_file_support = true,
        capabilities = clangd_capabilities,
        settings = {
            clangd = {
                InlayHints = {
                    Designators = true,
                    Enabled = true,
                    ParameterNames = true,
                    DeducedTypes = true,
                },
                fallbackFlags = { "-std=c++20" },
            },
            C = {
                diagnostics = false,
            },
        },
        -- on_attach = function(client, bufnr)
        --     require("nvim-navic").attach(client, bufnr)
        -- end,
    })
    -- 默认禁用所有LSP功能，手动控制开关，用以避免占用CPU和内存过高导致系统卡死
end
vim.lsp.enable({ "clangd", "lua_ls", "pyright", "tsserver", "marksman", "jsonls", "eslint", "bashls", "cmake", "ts_ls", "vale_ls", "yamlls" }, false)
