-- 定义语言服务器
M.lsp_servers = {
    clangd = {
        config = {
            name = "clangd",
            filetypes = { "c", "cpp", "objc", "objcpp", "h", "hpp" },
            root_markers = { "compile_commands.json", ".git", "CMakeLists.txt" },
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
        config = {
            name = "lua-language-server",
            filetypes = { "lua" },
            root_markers = { "stylua.toml", ".git" },
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
    bashls = {
        config = {
            name = "bash-language-server",
            filetypes = { "bash", "sh" },
            root_markers = { ".git" },
            cmd = {
                "bash-language-server",
                "start",
            },
            settings = {
                bashIde = {
                    globPattern = "*@(.sh|.inc|.bash|.command)",
                },
            },
        },
    },
    pyright = {
        config = {
            name = "pyright-langserver",
            filetypes = {
                "python",
                "py",
            },
            root_markers = {
                "pyproject.toml",
                "setup.py",
                "setup.cfg",
                "requirements.txt",
                "Pipfile",
                "pyrightconfig.json",
                ".git",
            },
            cmd = { "pyright-langserver", "--stdio" },
            settings = {
                python = {
                    analysis = {
                        autoSearchPaths = true,
                        diagnosticMode = "openFilesOnly",
                        useLibraryCodeForTypes = true,
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
function M.get_lsp_for_filetype(filetype)
    local ft = filetype or vim.bo.filetype
    for server_name, server_config in pairs(M.lsp_servers) do
        if vim.tbl_contains(server_config.config.filetypes, ft) then
            return server_name
        end
    end
end

function M.start_lsp()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
        local buf_name = vim.api.nvim_buf_get_name(bufnr)
        local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

        if buf_name ~= "" and filetype ~= "" then
            local success = M.attach_buffer(bufnr)
        end
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

function M.attach_buffer(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    -- 检查buffer是否有效
    if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
        vim.notify("Buffer is not valid or loaded", vim.log.levels.WARN)
        return false
    end

    -- 检查是否已经有LSP附加
    local existing_clients = vim.lsp.get_clients({ bufnr = bufnr })
    if #existing_clients > 0 then
        vim.notify("Buffer already has LSP attached", vim.log.levels.INFO)
        return true
    end

    local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
    if filetype == "" then
        vim.notify("Buffer has no filetype", vim.log.levels.WARN)
        return false
    end

    local server_name = M.get_lsp_for_filetype(filetype)
    if not server_name then
        vim.notify(string.format("No LSP server configured for filetype: " .. filetype), vim.log.levels.WARN)
        return false
    end

    local server_config = M.lsp_servers[server_name]
    if not server_config then
        vim.notify(string.format("LSP server not configured: " .. server_name), vim.log.levels.WARN)
        return false
    end

    -- 检查是否已安装
    if vim.fn.executable(server_config.config.name or server_name) == 0 then
        vim.notify(string.format(server_name .. " is not installed"), vim.log.levels.WARN)
        return false
    end

    -- 获取当前文件的合理根目录
    local root_markers = M.lsp_servers[server_name].config.root_markers
    local root_dir = vim.fs.dirname(
        vim.fs.find(root_markers, { upward = true, path = vim.fn.expand("%:p:h") })[1] or vim.fn.getcwd()
    )
    local buf_path = vim.api.nvim_buf_get_name(bufnr)
    if buf_path == "" then
        vim.notify("Buffer has no file path", vim.log.levels.WARN)
        return false
    end
    local root_dir = vim.fs.dirname(
        vim.fs.find(root_markers, { upward = true, path = vim.fs.dirname(buf_path) })[1] or vim.fn.getcwd()
    )

    -- 检查是否已存在可复用的客户端
    for _, client in ipairs(vim.lsp.get_clients({ name = server_name })) do
        if client.config.root_dir == root_dir then
            -- 检查客户端是否支持当前buffer的文件类型
            local supported_filetypes = server_config.config.filetypes or {}
            local is_supported = false

            -- 如果客户端没有指定filetypes，假设它支持所有
            if #supported_filetypes == 0 then
                is_supported = true
            else
                for _, ft in ipairs(supported_filetypes) do
                    if ft == filetype then
                        is_supported = true
                        break
                    end
                end
            end
            if is_supported then
                vim.lsp.buf_attach_client(bufnr, client.id)
                M.tracker:register(client, bufnr)
                vim.notify("Attached to existing LSP client", vim.log.levels.INFO)
            end
            return true
        end
    end

    -- 启动新的LSP客户端
    local config = vim.deepcopy(server_config.config)
    config.root_dir = root_dir

    -- 设置capabilities
    local has_cmp, cmp = pcall(require, "cmp_nvim_lsp")
    local has_blink, blink = pcall(require, "blink.cmp")

    if has_blink then
        config.capabilities = blink.get_lsp_capabilities()
    elseif has_cmp then
        config.capabilities = cmp.default_capabilities()
    else
        config.capabilities = vim.lsp.protocol.make_client_capabilities()
    end

    -- 设置回调
    config.on_attach = function(client, attached_bufnr)
        M.tracker:register(client, attached_bufnr)
	-- 这里增加快捷键的作用在于buffer内部跳转
        local bufopts = { noremap = true, silent = true, buffer = attached_bufnr}
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
    end

    config.on_exit = function(client, exited_bufnr)
        M.tracker:unregister(client, exited_bufnr)
    end

    -- 启动LSP
    -- 解决多个不同文件类型的buffer，最后一次启动的lsp client会附加所有buffer的问题
    local client_id = vim.lsp.start(config, { bufnr = bufnr })
    if client_id then
        -- 将新客户端附加到当前buffer
        -- vim.lsp.buf_attach_client(bufnr, client_id)
        vim.notify("Started new LSP client and attached", vim.log.levels.INFO)
        return true
    else
        vim.notify("Failed to start LSP client", vim.log.levels.WARN)
        return false
    end
end
-- 为所有buffer附加LSP
function M.attach_all()
    local buffers = vim.api.nvim_list_bufs()
    local results = {
        success = 0,
        failed = 0,
        skipped = 0,
        details = {},
    }

    for _, bufnr in ipairs(buffers) do
        if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
            local buf_name = vim.api.nvim_buf_get_name(bufnr)
            local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

            -- 跳过特殊buffer
            if buf_name == "" or filetype == "" then
                results.skipped = results.skipped + 1
            else
                local success = M.attach_buffer(bufnr)

                if success then
                    results.success = results.success + 1
                else
                    results.failed = results.failed + 1
                end
            end
        else
            results.skipped = results.skipped + 1
        end
    end

    -- 生成报告
    local message = string.format(
        "Attached LSP to %d buffer(s): %d success, %d failed, %d skipped",
        results.success,
        results.success,
        results.failed,
        results.skipped
    )
    vim.notify(message, vim.log.levels.INFO)
    return results
end

function M.detach_buffer(bufnr)
    local bufnr = bufnr or vim.api.nvim_get_current_buf()
    local clients = M.tracker:get_clients(bufnr)
    local detached = 0

    for _, client in ipairs(clients) do
        -- 将当前buffer和所有关联的client分离
        vim.lsp.buf_detach_client(bufnr, client.id)
        M.tracker:unregister(client.id, bufnr)
        detached = detached + 1

        -- 当client没有关联的buffer时则停止
        if #M.tracker:get_buffers(client.id) == 0 then
            vim.lsp.stop_client(client.id, false)
        end
    end
    return detached
end

function M.detach_current()
    local bufnr = bufnr or vim.api.nvim_get_current_buf()
    local detached = M.detach_buffer(bufnr)

    if detached > 0 then
        vim.notify(string.format("Detached %d LSP client(s) from current buffer", detached), vim.log.levels.INFO)
    else
        vim.notify("No LSP clients attached to current buffer", vim.log.levels.INFO)
    end

    return detached
end

function M.detach_all()
    local total_detached = 0
    local affected_buffers = {}

    -- 获取所有buffer列表
    local buffers = vim.api.nvim_list_bufs()

    for _, bufnr in ipairs(buffers) do
        -- 只处理可用的buffer
        if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
            local detached = M.detach_buffer(bufnr)

            if detached > 0 then
                total_detached = total_detached + detached
                table.insert(affected_buffers, bufnr)

                -- 获取buffer名称用于显示
                local buf_name = vim.api.nvim_buf_get_name(bufnr)
                if buf_name == "" then
                    buf_name = "[No Name]"
                else
                    buf_name = vim.fn.fnamemodify(buf_name, ":t")
                end
            end
        end
    end

    -- 生成详细报告
    local message =
        string.format("Detached LSP from %d buffer(s), total %d client(s)", #affected_buffers, total_detached)
    vim.notify(message, vim.log.levels.INFO)
    return total_detached, affected_buffers
end

-- 分离除当前buffer外的所有buffer
function M.detach_others()
    local current_buf = vim.api.nvim_get_current_buf()
    local total_detached = 0
    local affected_buffers = {}

    local buffers = vim.api.nvim_list_bufs()

    for _, bufnr in ipairs(buffers) do
        if bufnr ~= current_buf and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
            local detached = M.detach_buffer(bufnr)
            if detached > 0 then
                total_detached = total_detached + detached
                table.insert(affected_buffers, bufnr)
            end
        end
    end
    vim.notify(string.format("Detached LSP from %d other buffer(s)", #affected_buffers), vim.log.levels.INFO)

    return total_detached, affected_buffers
end

return M
