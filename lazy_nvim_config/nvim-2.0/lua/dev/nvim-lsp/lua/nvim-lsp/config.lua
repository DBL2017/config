local M = {}

-- 默认配置
M.options = {
    auto_attach = false, -- 是否自动附加 LSP
    log_level = "warn", -- 默认日志等级
    disabled_servers = {
        "clangd",
        "lua_ls",
        "pyright",
        "tsserver",
        "marksman",
        "jsonls",
        "eslint",
        "bashls",
        "cmake",
        "ts_ls",
        "vale_ls",
        "yamlls",
    }, -- 默认禁用的语言服务器
}

function M.setup(opts)
    -- Ensure opts is a table and merge using deep extend
    opts = opts or {}
    if type(opts) ~= "table" then
        vim.notify("nvim-lsp: setup expects a table, got " .. type(opts), vim.log.levels.WARN)
        return
    end
    M.options = vim.tbl_extend("force", M.options, opts or {})

    -- 设置日志等级
    vim.lsp.set_log_level(M.options.log_level)

    -- 解决插件缺失导致的配置错误问题
    local blink_ok = pcall(require, "blink.cmp")
    local cmp_ok = pcall(require, "cmp_nvim_lsp")

    local global_capabilities = nil
    if blink_ok then
        global_capabilities = require("blink.cmp").get_lsp_capabilities()
    elseif cmp_ok then
        global_capabilities = require("cmp_nvim_lsp").default_capabilities()
    else
        global_capabilities = vim.lsp.protocol.make_client_capabilities()
    end

    -- 全局配置应用
    vim.lsp.config("*", {
        capabilities = global_capabilities,
        flags = { debounce_text_changes = 150 },
        on_attach = function(client, bufnr)
            client.server_capabilities.document_formatting = false
            client.server_capabilities.document_range_formatting = false
            local bufopts = { noremap = true, silent = true, buffer = bufnr }
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
        end,
    })

    -- lua_ls 配置
    vim.lsp.config("lua_ls", {
        settings = {
            Lua = {
                hint = { enable = true },
                runtime = "LuaJIT",
                diagnostics = { globals = { "vim" } },
                workspace = { library = vim.api.nvim_get_runtime_file("", true) },
                telemetry = { enable = false },
            },
        },
    })

    -- clangd 配置
    local clangd_capabilities = vim.deepcopy(global_capabilities)
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
            C = { diagnostics = false },
        },
    })

    -- 默认禁用所有 LSP
    vim.lsp.enable(M.options.disabled_servers, false)
end

return M
