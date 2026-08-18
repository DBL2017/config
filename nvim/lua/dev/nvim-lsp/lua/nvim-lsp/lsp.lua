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
                "--clang-tidy",
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
            root_markers = { "stylua.toml", ".git", ".luarc.json" },
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
    copilot = {
        config = {
            name = "copilot",
            -- empty filetypes => treat as global/completion provider for all filetypes
            filetypes = {},
            root_markers = { ".git" },
            -- executable name: ensure 'copilot' (or the right binary) is in PATH
            cmd = { "copilot-language-server", "--stdio" }, -- 注意只保留一个 --stdio
            settings = {
                ["github-enterprise"] = {
                    uri = nil,
                },
                http = {
                    proxy = nil,
                    proxyStrictSSL = nil,
                },
                copilot = {
                    enable = true,
                    suggestion = { enable = false},
                    panel = { enable = true },
                },
            },
            init_options = {
                editorInfo = {
                    name = "neovim",
                    version = vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
                },
                editorPluginInfo = {
                    name = "copilot.nvim",
                    version = "1.0.0", -- 可以根据实际插件版本调整
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
-- 获取适合当前文件的 LSP
function M.get_lsp_for_filetype(filetype)
    local ft = filetype or vim.bo.filetype
    -- 首先查找显式声明支持该 filetype 的服务器
    for server_name, server_config in pairs(M.lsp_servers) do
        local fts = server_config.config.filetypes or {}
        if #fts > 0 and vim.tbl_contains(fts, ft) then
            return server_name
        end
    end
    -- 回退：查找那些未指定 filetypes 的服务器（例如 Copilot），作为通用/补全提供者
    for server_name, server_config in pairs(M.lsp_servers) do
        local fts = server_config.config.filetypes or {}
        if #fts == 0 then
            return server_name
        end
    end
    return nil
end

function M.start_lsp()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
        local buf_name = vim.api.nvim_buf_get_name(bufnr)
        local filetype = vim.bo[bufnr].filetype

        if buf_name ~= "" and filetype ~= "" then
            M.attach_buffer(bufnr)
        end
    end
end

-- 安全关闭当前buffer关联的所有client
function M.stop_lsp()
    local bufnr = vim.api.nvim_get_current_buf()

    local clients = vim.lsp.get_clients({
        bufnr = bufnr,
    })

    for _, client in ipairs(clients) do
        vim.lsp.stop_client(client.id)
    end

    vim.notify(
        string.format("Current buffer attached %d client(s), stopped %d", #clients, #clients),
        vim.log.levels.INFO
    )
end

function M.attach_buffer(bufnr)
    local bufnr = bufnr or vim.api.nvim_get_current_buf()

    -- 检查buffer是否有效
    if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
        vim.notify("Buffer is not valid or loaded", vim.log.levels.WARN)
        return false
    end

    -- 检查是否已经附加到client（忽略 Copilot 类型的客户端）
    local existing_clients = vim.lsp.get_clients({ bufnr = bufnr })
    local real_clients = {}
    for _, c in ipairs(existing_clients) do
        local lname = (c.name or ""):lower()
        if not lname:match("copilot") then
            table.insert(real_clients, c)
        end
    end
    if #real_clients > 0 then
        vim.notify("Buffer already has LSP attached", vim.log.levels.INFO)
        return true
    end

    local filetype = vim.bo[bufnr].filetype
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
    local buf_path = vim.api.nvim_buf_get_name(bufnr)
    if buf_path == "" then
        vim.notify("Buffer has no file path", vim.log.levels.WARN)
        return false
    end

    local root_marker = vim.fs.find(server_config.config.root_markers, {
        upward = true,
        path = vim.fs.dirname(buf_path),
    })[1]

    local root_dir = root_marker and vim.fs.dirname(root_marker) or vim.fn.getcwd()

    -- 检查是否已存在可复用的客户端（跳过 Copilot 客户端）
    for _, client in ipairs(vim.lsp.get_clients()) do
        local lname = (client.name or ""):lower()
        if lname:match("copilot") then
            -- skip copilot-like clients
        else
            if client.name == server_config.config.name and client.config.root_dir == root_dir then
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
                    vim.notify("Attached to existing LSP client", vim.log.levels.INFO)
                end
                return true
            end
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
        -- 这里增加快捷键的作用在于buffer内部跳转
        local bufopts = { noremap = true, silent = true, buffer = attached_bufnr }
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
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
            local filetype = vim.bo[bufnr].filetype

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

    local clients = vim.lsp.get_clients({
        bufnr = bufnr,
    })

    local detached = 0

    for _, client in ipairs(clients) do
        vim.lsp.buf_detach_client(bufnr, client.id)

        detached = detached + 1

        vim.schedule(function()
            local current = vim.lsp.get_client_by_id(client.id)

            if current and current.attached_buffers and vim.tbl_isempty(current.attached_buffers) then
                vim.lsp.stop_client(client.id, true)
            end
        end)
    end

    return detached
end

function M.detach_current(bufnr)
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

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
            local detached = M.detach_buffer(bufnr)

            if detached > 0 then
                total_detached = total_detached + detached
                table.insert(affected_buffers, bufnr)
            end
        end
    end

    vim.notify(
        string.format("Detached LSP from %d buffer(s), total %d client(s)", #affected_buffers, total_detached),
        vim.log.levels.INFO
    )

    return total_detached, affected_buffers
end

-- 分离除当前buffer外的所有buffer
function M.detach_others()
    local current_buf = vim.api.nvim_get_current_buf()

    local total_detached = 0
    local affected_buffers = {}

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
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
