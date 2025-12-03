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
    severity_sort = true,
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
