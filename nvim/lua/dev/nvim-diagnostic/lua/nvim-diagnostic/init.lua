local M = {}

function M.setup(opts)
    -- diagnostic配置
    vim.diagnostic.config({
        -- virtual_lines = {
        --     severity = { min = vim.diagnostic.severity.WARN },
        --     current_line = true,
        --     format = function(diag)
        --         local severity_map = { [1] = "ERROR", [2] = "WARN", [3] = "INFO", [4] = "HINT" }
        --         return string.format("%s [%s] %s", diag.source, severity_map[diag.severity], diag.message)
        --     end,
        -- },
        virtual_lines = false,
        virtual_text = {
            -- 只显示WARN和ERROR
            severity = { min = vim.diagnostic.severity.WARN },

            -- 幽灵文本样式
            format = function(diagnostic)
                local icons_bak = {
                    [vim.diagnostic.severity.ERROR] = "E",
                    [vim.diagnostic.severity.WARN] = "W",
                    [vim.diagnostic.severity.INFO] = "I",
                    [vim.diagnostic.severity.HINT] = "H",
                }

                local icons = {
                    [vim.diagnostic.severity.ERROR] = "",
                    [vim.diagnostic.severity.WARN] = "",
                    [vim.diagnostic.severity.INFO] = "",
                    [vim.diagnostic.severity.HINT] = "",
                }
                return string.format(
                    "%s  [%s] %s",
                    icons[diagnostic.severity] or icons_bak[diagnostic.severity],
                    diagnostic.source,
                    diagnostic.message
                )
            end,
            -- 移除前面的黑框
            prefix = "",
            -- 位置和样式
            virt_text_pos = "eol", -- 右对齐（看起来像行尾）
            spacing = 0,
            hl_mode = "combine",
        },
        severity_sort = true,
        -- 该符号列会和gitsigns的符号列冲突
        signs = false,
        -- signs = {
        --     severity = { min = vim.diagnostic.severity.HINT },
        -- },
        float = {
            scope = "line",
            severity_sort = true,
            header = "Diagnostics",
            source = true,
            format = function(diag)
                local severity_map = { [1] = "ERROR", [2] = "WARN", [3] = "INFO", [4] = "HINT" }
                return string.format("[%s] %s", severity_map[diag.severity], diag.message)
            end,
            border = "rounded", -- 使用内置圆角边框（直接生效）
        },
    })
end

return M
