-- 定义语言服务器
M.lsp_servers = {
    clangd = {
        filetypes = { "c", "cpp", "objc", "objcpp", "h", "hpp" },
        root_markers = { "compile_commands.json", ".git", "CMakeLists.txt" },
        config = {
            name = "clangd",
            cmd = {
                "clangd",
                "--background-index",
                "--completion-style=detailed",
                "--function-arg-placeholders",
                "--header-insertion=never",
            }, -- 添加常用参数
            init_options = {
                clangdFileStatus = true, -- 显示文件状态
                usePlaceholders = true,
                completeUnimported = true,
                semanticHighlighting = true,
                -- 重点：Inlay Hints 配置
                InlayHints = {
                    Enabled = true, -- 全局启用内联提示
                    Designators = true, -- 显示设计器提示（如结构体字段名）
                    ParameterNames = true, -- 显示函数参数名
                    DeducedTypes = true, -- 显示自动推导的类型
                    BlockEnd = false, -- 不显示代码块结束提示
                    DefaultArguments = false, -- 不显示默认参数提示
                    TypeNameLimit = 24, -- 类型名称最大长度限制
                },
            },
        },
    },
    lua_ls = {
        filetypes = { "lua" },
        root_markers = { "stylua.toml", ".git" },
        config = {
            name = "lua-language-server",
            cmd = {
                "lua-language-server",
            },
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
        },
    },
    -- 可扩展其他语言...
}
-- 全局状态跟踪器
M.tracker = {
    -- 结构: { [client_id] = { bufnr1, bufnr2, ... } }
    clients = {},

    -- 注册客户端-缓冲区关联
    register = function(self, client, bufnr)
        if not self.clients[client.id] then
            self.clients[client.id] = {
                client = client,
                buffers = {},
            }
        end
        table.insert(self.clients[client.id].buffers, bufnr)
    end,

    -- 注销关联
    unregister = function(self, client_id, bufnr)
        if not self.clients[client_id] then
            return
        end

        -- 移除特定缓冲区记录
        for i, b in ipairs(self.clients[client_id].buffers) do
            if b == bufnr then
                table.remove(self.clients[client_id].buffers, i)
                break
            end
        end

        -- 若无关联缓冲区则完全移除
        if #self.clients[client_id].buffers == 0 then
            self.clients[client_id] = nil
        end
    end,

    -- 获取客户端关联的所有缓冲区
    get_buffers = function(self, client_id)
        return self.clients[client_id] and self.clients[client_id].buffers or {}
    end,

    -- 获取缓冲区关联的所有客户端
    get_clients = function(self, bufnr)
        local result = {}
        for client_id, data in pairs(self.clients) do
            if vim.tbl_contains(data.buffers, bufnr) then
                table.insert(result, data.client)
            end
        end
        return result
    end,
}
-- 获取适合当前文件的 LSP
function M.get_lsp_for_filetype()
    local ft = vim.bo.filetype
    for server_name, server_config in pairs(M.lsp_servers) do
        if vim.tbl_contains(server_config.filetypes, ft) then
            return server_name
        end
    end
end

function M.start_lsp()
    local server_name = M.get_lsp_for_filetype()
    if not server_name then
        vim.notify("Not support filetype: " .. vim.bo.filetype, vim.log.levels.WARN)
        return
    end

    if vim.fn.executable(M.lsp_servers[server_name].config.name) == 0 then
        vim.notify(server_name .. " is not installed. Please install it first.", vim.log.levels.INFO)
        return
    end

    -- 获取当前文件的合理根目录
    local root_markers = M.lsp_servers[server_name].root_markers
    local root_dir = vim.fs.dirname(
        vim.fs.find(root_markers, { upward = true, path = vim.fn.expand("%:p:h") })[1] or vim.fn.getcwd()
    )

    -- 检查是否已存在可复用的客户端
    for _, client in ipairs(vim.lsp.get_clients({ name = server_name })) do
        if client.config.root_dir == root_dir then
            -- 将现有客户端附加到新缓冲区
            vim.lsp.buf_attach_client(0, client.id)
            return
        end
    end

    local blink_ok, blink_err = pcall(require, "blink.cmp")
    local nvim_cmp_ok, nvim_cmp_err = pcall(require, "cmp")
    if blink_ok then
        local config = vim.deepcopy(M.lsp_servers[server_name].config)
        config.root_dir = root_dir
        config.capabilities = require("blink.cmp").get_lsp_capabilities()
        config.on_attach = function(client, bufnr)
            M.tracker:register(client, bufnr)
        end
        config.on_exit = function(client, bufnr)
            M.tracker:unregister(client, bufnr)
        end
        -- 启动 clangd
        vim.lsp.start(config)
        vim.notify(server_name .. " started", vim.log.levels.INFO)
    elseif nvim_cmp_ok then
        local config = vim.deepcopy(M.lsp_servers[server_name].config)
        config.root_dir = root_dir
        config.capabilities = require("cmp_nvim_lsp").default_capabilities()
        config.on_attach = function(client, bufnr)
            M.tracker:register(client, bufnr)
        end
        config.on_exit = function(client, bufnr)
            M.tracker:unregister(client, bufnr)
        end
        -- 启动 clangd
        vim.lsp.start(config)
        vim.notify(server_name .. " started", vim.log.levels.INFO)
    end
end

-- 安全关闭当前buffer关联的所有client
function M.stop_lsp()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = M.tracker:get_clients(bufnr)
    local detached = 0

    for _, client in ipairs(clients) do
        vim.lsp.stop_client(client.id)
    end
    vim.notify(
        string.format("Current buffer attached %d clients, stopped %d instance(s)", #clients, #clients),
        vim.log.levels.INFO
    )
end
function M.detach_current()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = M.tracker:get_clients(bufnr)
    local detached = 0

    for _, client in ipairs(clients) do
        -- 将当前buffer和所有关联的client分离
        vim.lsp.buf_detach_client(bufnr, client.id)
        M.tracker:unregister(client.id, bufnr)
        detached = detached + 1

        -- 当client没有关联的buffer时则停止
        if #M.tracker:get_buffers(client.id) == 0 then
            vim.lsp.stop_client(client.id, true)
        end
    end
    vim.notify(string.format("Detached %d %s from buffer", detached, "LSP client(s)"), vim.log.levels.INFO)
end

return M
